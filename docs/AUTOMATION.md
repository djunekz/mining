# Otomasi (GitHub Actions)

Semua workflow ada di `.github/workflows/`. Tidak ada secret tambahan yang
diperlukan; semuanya memakai `GITHUB_TOKEN` bawaan.

## Daftar workflow

| Workflow | Pemicu | Fungsi |
|---|---|---|
| `ci.yml` | push, PR, mingguan | `bash -n`, ShellCheck, validasi koin, cek `VERSION`, smoke test di Ubuntu 22.04 & 24.04 |
| `coins.yml` | PR yang menyentuh `coins/` | Validasi + guard isi file koin, ringkasan perubahan, peringatan `coin_cmd()` |
| `changelog.yml` | push ke `main` | Memperbarui blok `[Unreleased]` di `CHANGELOG.md` dari pesan commit |
| `auto-release.yml` | push ke `main`, manual | **Auto release**: hitung versi, tulis `VERSION` + `CHANGELOG.md`, tag, GitHub Release + arsip + checksum |
| `coins-doc.yml` | push yang menyentuh `coins/` | Membuat ulang `docs/COINS.md` |
| `pr-title.yml` | PR dibuka / judul diubah | Judul PR harus Conventional Commits |
| `labeler.yml` | PR | Label otomatis dari file yang berubah (`.github/labeler-rules.yml`) |
| `pr-size.yml` | PR | Label `size/XS` sampai `size/XL` |
| `greetings.yml` | issue / PR pertama | Menyapa kontributor baru |
| `stale.yml` | harian | Menandai lalu menutup issue/PR tidak aktif |
| `markdown-lint.yml` | perubahan `*.md` | markdownlint |
| `pool-health.yml` | mingguan | Mengecek pool default; membuat / menutup issue `pool-health` otomatis |

## Format commit

Changelog dan versi dihitung dari pesan commit
([Conventional Commits](https://www.conventionalcommits.org/id/)):

```text
tipe(lingkup opsional): deskripsi singkat
```

| Tipe | Masuk ke bagian | Efek pada versi |
|---|---|---|
| `feat` | Added | minor (1.0.0 → 1.1.0) |
| `fix` | Fixed | patch (1.0.0 → 1.0.1) |
| `perf`, `refactor`, `revert` | Changed | patch |
| tanpa tipe (mis. `Update coins`) | Changed | patch |
| `docs` | Documentation | tidak ada rilis |
| `ci`, `build`, `chore`, `test`, `style` | Maintenance | tidak ada rilis |
| tipe apa pun + `!` (mis. `feat!:`) atau `BREAKING CHANGE:` | Breaking changes | major (1.0.0 → 2.0.0) |

Contoh: `feat(coins): tambah koin ABC (#12)` · `fix(miner): perbaiki thread default`.

## Alur rilis

1. Kamu push / merge ke `main`.
2. `changelog.yml` memperbarui `[Unreleased]`.
3. `auto-release.yml` menjalankan `tools/release.sh auto`:
   - rilis pertama memakai isi `VERSION` apa adanya;
   - rilis berikutnya menaikkan versi sesuai commit sejak tag terakhir;
   - bila hanya ada commit `docs`/`ci`/`chore`, **tidak ada rilis**.
4. `VERSION` dan `CHANGELOG.md` di-commit (`chore(release): vX.Y.Z [skip ci]`), tag `vX.Y.Z` dibuat,
   lalu GitHub Release terbit lengkap dengan catatan, `mining-X.Y.Z.tar.gz`, dan checksum.

Rilis manual: **Actions > Release > Run workflow**, pilih `auto`, `patch`, `minor`, atau `major`.

Mematikan rilis otomatis:

- tambahkan `[skip release]` di pesan commit, atau
- buat variable repo `AUTO_RELEASE` bernilai `false`
  (Settings > Secrets and variables > Actions > Variables).

Perintah yang sama bisa dijalankan lokal tanpa mengubah apa pun:

```bash
tools/release.sh auto --dry-run
```

## Pengaturan repo yang diperlukan (sekali saja)

1. **Settings > Actions > General > Workflow permissions** pilih **Read and write permissions**.
2. **Jika `main` dilindungi** (ruleset atau branch protection dengan "wajib Pull Request" atau
   "wajib status check"), workflow `changelog`, `auto-release`, dan `coins-doc` gagal dengan
   `GH013: Repository rule violations ... Changes must be made through a pull request`.
   `github-actions[bot]` (pemilik `GITHUB_TOKEN`) tidak bisa dimasukkan ke daftar bypass,
   jadi pakai token milik pemilik repo lewat secret `RELEASE_TOKEN` (lihat bagian di bawah).
3. (Opsional) Branch protection: wajibkan status check **CI OK**, **Validasi file koin**,
   dan **Periksa format judul**.
4. (Opsional) **Settings > Security**: aktifkan **Private vulnerability reporting** dan **Dependabot alerts**.
5. Commit yang diberi `[skip ci]` tidak memicu workflow lain, itulah yang mencegah perulangan tak berujung.

## Secret `RELEASE_TOKEN` (wajib jika `main` dilindungi)

Workflow yang commit ke `main` memakai `secrets.RELEASE_TOKEN` bila ada, dan `GITHUB_TOKEN`
bila tidak. Dengan token milik pemilik repo, push dilakukan atas nama pemilik, yang boleh
melewati aturan (log push biasa akan menampilkan `Bypassed rule violations`).

Cara membuatnya (bisa dari browser HP):

1. GitHub: foto profil, **Settings**, **Developer settings**, **Personal access tokens**,
   **Fine-grained tokens**, **Generate new token**.
2. Isi nama (mis. `mining-release`), **Expiration** (mis. 1 tahun), **Repository access**:
   *Only select repositories*, pilih repo ini.
3. **Repository permissions**: **Contents** = *Read and write* (Metadata otomatis *Read*). Klik **Generate token**
   dan salin tokennya (hanya tampil sekali).
4. Di repo ini: **Settings**, **Secrets and variables**, **Actions**, **New repository secret**.
   Nama: `RELEASE_TOKEN`, isi: token tadi.
5. Pastikan aturan `main` punya bypass untuk pemilik (**Settings**, **Rules**, **Rulesets**, ruleset
   `main`, **Bypass list**, tambahkan *Repository admin*).
6. Jalankan ulang: **Actions**, workflow **Release** atau **Changelog**, **Run workflow**.
   (Menekan *Re-run jobs* pada run lama memakai file workflow lama, jadi hasilnya sama-sama gagal.)

Catatan:

- Jaga token seperti password. Jika bocor, hapus di halaman tokenmu dan buat ulang.
- Setelah token kedaluwarsa, workflow gagal lagi dengan pesan yang sama; buat token baru dan
  perbarui secretnya.
- Alternatif yang lebih rapi untuk tim: buat GitHub App, masukkan ke bypass list, dan ambil tokennya
  dengan `actions/create-github-app-token`.
- Alternatif paling sederhana untuk proyek sendirian: hapus aturan "Require a pull request" dan
  "Require status checks" dari ruleset `main`. Konsekuensinya push langsung tidak diperiksa CI.

### Error 403 "Permission to ... denied to <nama-anda>"

Pesan ini berarti `RELEASE_TOKEN` sudah terbaca, tetapi tokennya tidak boleh menulis ke repo.
Buka token di **Settings > Developer settings > Fine-grained tokens**, lalu pastikan:

- **Repository access** memilih repo `mining` ini;
- **Repository permissions > Contents** bernilai *Read and write* (bukan *Read-only*);
- tokennya belum kedaluwarsa.

Mengubah izin token tidak mengubah isi token, jadi secret tidak perlu dibuat ulang.
Setelah itu jalankan **Actions > Release > Run workflow**.

### Workflow Changelog

Selama auto release aktif (bawaan), workflow Release sudah menulis `CHANGELOG.md` sendiri,
jadi workflow Changelog dilewati pada push ke `main`. Ia hanya jalan otomatis bila Repository
variable `AUTO_RELEASE` bernilai `false`, atau lewat tombol **Run workflow**.

## Keamanan workflow

- Semua workflow memakai izin minimum (`permissions:`).
- Workflow `pull_request_target` (judul, label, ukuran, sapaan) **tidak** me-checkout kode PR,
  sehingga aman untuk PR dari fork.
- Judul PR dan data dari pengguna tidak pernah disisipkan langsung ke perintah shell.
- PR dari fork dijalankan lewat event `pull_request` dengan izin baca saja dan tanpa akses secret,
  sehingga kode di PR tidak bisa menulis ke repo.
- `tools/gen-coins-md.sh` dan `tools/check-pools.sh` membaca file koin dengan `grep`, tanpa meng-`source`-nya.

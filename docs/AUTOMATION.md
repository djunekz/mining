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
2. Jika `main` dilindungi (branch protection), izinkan `github-actions[bot]` untuk push
   (bypass), atau workflow `changelog`, `auto-release`, dan `coins-doc` tidak bisa commit.
   Alternatifnya biarkan `main` tanpa proteksi push langsung.
3. (Opsional) Branch protection: wajibkan status check **CI OK**, **Validasi file koin**,
   dan **Periksa format judul**.
4. (Opsional) **Settings > Security**: aktifkan **Private vulnerability reporting** dan **Dependabot alerts**.
5. Commit yang diberi `[skip ci]` tidak memicu workflow lain, itulah yang mencegah perulangan tak berujung.

## Keamanan workflow

- Semua workflow memakai izin minimum (`permissions:`).
- Workflow `pull_request_target` (judul, label, ukuran, sapaan) **tidak** me-checkout kode PR,
  sehingga aman untuk PR dari fork.
- Judul PR dan data dari pengguna tidak pernah disisipkan langsung ke perintah shell.
- PR dari fork dijalankan lewat event `pull_request` dengan izin baca saja dan tanpa akses secret,
  sehingga kode di PR tidak bisa menulis ke repo.
- `tools/gen-coins-md.sh` dan `tools/check-pools.sh` membaca file koin dengan `grep`, tanpa meng-`source`-nya.

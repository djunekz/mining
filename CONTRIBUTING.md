# Panduan Kontribusi

Terima kasih sudah mau berkontribusi pada unMineable Termux Miner. Panduan ini menjelaskan cara melapor, mengusulkan fitur, dan mengirim perubahan kode.

Dengan berpartisipasi kamu setuju mengikuti [Kode Etik](CODE_OF_CONDUCT.md).

## Cara berkontribusi

- **Melaporkan bug**: buka issue memakai template Laporan bug. Untuk masalah koneksi ke pool atau data tidak muncul di website, pakai template Masalah koneksi.
- **Mengusulkan fitur**: buka issue memakai template Usulan fitur dan jelaskan masalah yang ingin diselesaikan, bukan hanya solusinya.
- **Memperbaiki dokumentasi**: kirim pull request langsung, perubahan kecil tidak perlu issue.
- **Mengirim kode**: untuk perubahan besar, buka issue dulu agar arahnya disepakati sebelum kamu menulis kode.
- **Kerentanan keamanan**: jangan buka issue publik. Ikuti [SECURITY.md](SECURITY.md).

Sebelum membuka issue, cari dulu apakah sudah ada yang membahas hal yang sama.

## Menyiapkan lingkungan

Kebutuhan: Python 3.8 atau lebih baru, `git`, dan `bash`. Proyek ini hanya memakai pustaka standar Python, jadi tidak ada `pip install`.

```bash
git clone https://github.com/djunekz/unmineable
cd unmineable
bash install.sh local
unmineable doctor
```

Untuk menguji tanpa memengaruhi pengaturan aslimu, jalankan dengan folder rumah sementara:

```bash
HOME=/tmp/unmineable-dev bash unmineable.sh doctor
```

## Struktur proyek

| Berkas | Fungsi |
|---|---|
| `unmineable.sh` | launcher yang memanggil `python3 -m unmineable` |
| `install.sh` | installer (lokal atau release) |
| `unmineable/cli.py` | perintah baris dan titik masuk |
| `unmineable/menu.py` | menu interaktif |
| `unmineable/ui.py` | tampilan layar penuh, kotak, input, panel |
| `unmineable/config.py` | profil akun dan pengaturan |
| `unmineable/connection.py` | tes login pool dan sinkron ke website |
| `unmineable/miner.py`, `guard.py` | menjalankan XMRig dan menjaganya |
| `unmineable/installer.py`, `updater.py` | pemasangan XMRig dan pembaruan tool |

Satu modul punya satu tanggung jawab. Tambahkan fitur baru sebagai modul baru bila perlu, jangan menumpuk di `cli.py` atau `menu.py`.

## Gaya kode

Aturan proyek ini sengaja ketat:

- **Tanpa komentar dan docstring.** Kode harus terbaca dari nama fungsi dan variabel yang jelas. Kalau butuh komentar untuk menjelaskan, ganti nama atau pecah fungsinya.
- **Hanya pustaka standar Python.** Jangan menambah dependensi pihak ketiga.
- **Teks untuk pengguna memakai bahasa Indonesia**, singkat dan langsung. Nama kode memakai bahasa Inggris.
- **Layar tidak boleh menumpuk ke bawah.** Menampilkan hasil harus lewat fungsi di `ui.py` (kotak, tabel, panel) agar pas dengan tinggi terminal. Proses yang mencetak banyak baris harus memakai `ui.run_command_panel`.
- **Mining tetap mensyaratkan login dan XMRig terdeteksi.** Jangan membuat jalur yang melewati pemeriksaan itu.
- **Rahasia tidak boleh tercetak atau tersimpan sembarangan.** Alamat dompet ditampilkan dalam bentuk disamarkan, dan berkas profil memakai izin `600`.
- Gunakan `from __future__ import annotations`, f-string, dan nama berbahasa Inggris dengan format `snake_case`.

## Memeriksa perubahan

Belum ada rangkaian tes otomatis, jadi periksa manual sebelum mengirim:

```bash
python3 -m compileall -q unmineable
bash -n unmineable.sh
bash -n install.sh
grep -rnE "^\s*#" --include="*.py" unmineable
```

Perintah `grep` terakhir tidak boleh menghasilkan apa pun, karena kode tidak boleh berisi komentar.

Lalu uji alur yang kamu ubah secara nyata, misalnya `unmineable doctor`, menu terkait, dan `unmineable sync`. Jika mengubah tampilan, coba di terminal kecil (sekitar 16 baris) dan besar. Jika mengubah login atau koneksi pool, jelaskan di pull request bagaimana kamu mengujinya.

## Alur pull request

1. Fork repo dan buat branch dari `main`, misalnya `fix/login-timeout` atau `feat/payout-alert`.
2. Buat perubahan kecil dan fokus. Satu pull request untuk satu tujuan.
3. Tambahkan catatan di bagian `## [Unreleased]` pada [CHANGELOG.md](CHANGELOG.md).
4. Pastikan pemeriksaan di bagian sebelumnya lolos.
5. Buka pull request dan isi template-nya.

Pesan commit mengikuti [Conventional Commits](https://www.conventionalcommits.org/id/v1.0.0/):

```
feat: tambah notifikasi saat payout diterima
fix: tolak login jika pool membalas error
docs: perjelas langkah login alias
refactor: pisahkan pembacaan log dari modul stats
```

## Cara merilis (untuk pemelihara)

1. Pindahkan isi `## [Unreleased]` di `CHANGELOG.md` ke bagian baru `## [X.Y.Z] - TANGGAL`, dan perbarui tautan di bagian bawah berkas.
2. Ubah `VERSION` di `unmineable/constants.py` agar sama dengan `X.Y.Z`.
3. Commit, lalu buat dan dorong tag:

```bash
git commit -am "release: v0.2.0"
git tag v0.2.0
git push origin main --tags
```

Workflow `auto-release.yml` akan memvalidasi sintaks, memastikan tag sama dengan `VERSION`, mengambil catatan dari `CHANGELOG.md`, membuat arsip beserta `SHA256SUMS`, dan membuat GitHub Release bernama `unMineable vX.Y.Z`. Rilis gagal jika catatan versi itu tidak ada di `CHANGELOG.md`.

Tag yang memuat tanda hubung (misalnya `v0.2.0-rc1`) dibuat sebagai pre-release.

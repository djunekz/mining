# unMineable Termux Miner

Tool mining untuk [unMineable](https://unmineable.com) di **Termux** memakai **XMRig** (RandomX, CPU).
Ketik `unmineable` dan semua fitur muncul sebagai menu pilihan.

## Struktur

```
unmineable/
├── .github/
│   ├── ISSUE_TEMPLATE/     template laporan bug, koneksi, fitur, dokumentasi
│   ├── workflows/
│   │   └── auto-release.yml    release otomatis saat tag dibuat
│   ├── CODEOWNERS
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── dependabot.yml
├── unmineable/
│   ├── __init__.py
│   ├── __main__.py
│   ├── constants.py        konstanta, URL, tautan resmi, VERSION
│   ├── paths.py            lokasi config, log, pid
│   ├── ui.py               kotak, menu, input, spinner, grafik teks
│   ├── system.py           baterai, suhu, clipboard, browser, proses
│   ├── coins.py            katalog koin dan validasi alamat
│   ├── config.py           profil dompet dan pengaturan
│   ├── api.py              API resmi unMineable dan XMRig lokal
│   ├── connection.py       tes login pool, diagnosa log, cek sinkron ke website
│   ├── installer.py        dependensi dan instalasi XMRig
│   ├── miner.py            perintah XMRig, start, stop
│   ├── guard.py            penjaga suhu dan baterai di background
│   ├── history.py          riwayat hashrate
│   ├── notify.py           notifikasi Android dan Telegram
│   ├── stats.py            dashboard dan statistik akun
│   ├── logs.py             pembaca log
│   ├── benchmark.py        benchmark CPU
│   ├── doctor.py           diagnosa dan saran
│   ├── updater.py          pembaruan dari release GitHub
│   ├── boot.py             autostart Termux:Boot
│   ├── web.py              login, daftar, dan tautan website
│   ├── profiles.py         wizard dan manajemen profil
│   ├── settings.py         performa, proteksi, pool, notifikasi
│   ├── actions.py          aksi bersama menu dan CLI
│   ├── menu.py             menu interaktif
│   └── cli.py              perintah baris
├── unmineable.sh           launcher utama
├── install.sh              installer (lokal atau release)
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── SECURITY.md
├── SUPPORT.md
├── LICENSE
└── README.md
```

## Instalasi

Gunakan Termux dari F-Droid. Pasang juga aplikasi **Termux:API** agar proteksi suhu dan baterai bekerja.

`install.sh` menawarkan dua pilihan:

| Pilihan | Cara kerja |
|---|---|
| 1. Install dari lokal | memakai folder proyek yang sedang kamu pegang, perintah `unmineable` menaut ke `unmineable.sh` di folder itu |
| 2. Install dari release | mengunduh rilis terbaru dari GitHub, memverifikasi SHA256, dan memasangnya di `~/.unmineable/app` |

```bash
git clone https://github.com/djunekz/unmineable
cd unmineable
bash install.sh
```

Tanpa argumen muncul pilihan interaktif. Bisa juga langsung:

```bash
bash install.sh local
bash install.sh release
bash install.sh release v0.1.5
```

Pemasangan satu baris dari release (otomatis memilih release):

```bash
curl -fsSL https://raw.githubusercontent.com/djunekz/unmineable/main/install.sh | bash
```

Hanya butuh Python bawaan Termux, tanpa paket pip tambahan.

## Update

```bash
unmineable update                 perbarui ke rilis terbaru (stabil)
unmineable update --check         hanya cek versi
unmineable update -c main         ikuti branch main (dev)
unmineable update -y              tanpa konfirmasi
unmineable check                  cek versi dan lihat catatan rilis
```

Update juga ada di menu **Instalasi & pembaruan**. Menu utama menampilkan peringatan otomatis kalau ada versi baru (dicek maksimal tiap 12 jam).

Cara update menyesuaikan jenis instalasi:

- **git clone**: `git fetch` lalu checkout tag rilis (atau pull untuk channel main)
- **arsip / release**: unduh arsip rilis, cocokkan SHA256, lalu ganti berkas proyek

Kalau mining sedang berjalan, jalankan `unmineable restart` setelah update.

## Release otomatis

Workflow `.github/workflows/auto-release.yml` berjalan setiap ada tag berawalan `v`:

1. validasi sintaks Python dan shell
2. memastikan tag sama dengan `VERSION` di `unmineable/constants.py` (gagal jika berbeda)
3. mengambil catatan di bawah judul versi tersebut dari `CHANGELOG.md` (gagal jika tidak ada)
4. membuat `unmineable-vX.Y.Z.tar.gz`, `.zip`, dan `SHA256SUMS`
5. membuat GitHub Release bernama **unMineable vX.Y.Z** dengan isi catatan dari CHANGELOG (tag berisi `-`, mis. `v0.2.0-rc1`, menjadi pre-release)

Cara merilis:

```bash
sed -i 's/^VERSION = .*/VERSION = "0.2.0"/' unmineable/constants.py
git add -A && git commit -m "release: v0.2.0"
git tag v0.2.0
git push origin main --tags
```

Sebelum tag dibuat, pindahkan isi `## [Unreleased]` di `CHANGELOG.md` ke bagian `## [0.2.0] - TANGGAL`. Detail lengkap ada di [CONTRIBUTING.md](CONTRIBUTING.md).

Pastikan di GitHub: Settings > Actions > General > Workflow permissions memakai **Read and write**, atau biarkan `permissions: contents: write` di workflow bekerja.

## Syarat mining

Mining hanya bisa dimulai kalau dua syarat ini terpenuhi:

1. **Sudah login.** Login = akun (alias atau alamat dompet) berhasil diverifikasi langsung ke pool unMineable. Jika pool menolak, login gagal dan mining tidak bisa jalan. Jalankan `unmineable login`, atau menu **Login ke unMineable**. `unmineable logout` menghentikan mining dan keluar dari akun.
2. **XMRig terdeteksi dan bisa dijalankan.** Kalau tidak ada atau rusak, mining ditolak dan tool menawarkan pemasangan.

Aturan ini dijaga di semua jalur: menu, `unmineable start`, mining foreground, autostart saat boot, dan guard di background (guard menghentikan mining jika salah satu syarat hilang).

## Tampilan layar penuh

Menu berjalan seperti aplikasi layar penuh, bukan teks yang menumpuk ke bawah:

- setiap menu dan hasil tampil di layar bersih, lalu terminal dikembalikan seperti semula saat keluar
- tinggi tampilan menyesuaikan ukuran terminal (header otomatis diringkas di layar kecil)
- hasil panjang (diagnosa, sinkron) dibagi per halaman: Enter lanjut, `b` mundur, `q` selesai
- proses panjang (pasang paket, build XMRig, benchmark, mining foreground, log live) tampil di panel berukuran tetap yang hanya menampilkan baris terbaru

## Menghubungkan ke website unMineable

Ada dua cara login ke pool. Pilih saat setup (`unmineable config`).

| Mode | Username ke pool | Hasil terlihat di |
|---|---|---|
| **Alias akun website** (disarankan unMineable) | `ALIAS.WORKER` | akun website setelah login |
| **Alamat dompet** (legacy) | `COIN:ALAMAT.WORKER#REFERRAL` | `unmineable.com/coins/KOIN/address/ALAMAT` |

Langkah mode alias: daftar atau login di <https://www.unmineable.com/account/signin>, buat Alias di akun, lalu isi nama Alias di wizard.
Koin yang butuh memo/tag (mis. XRP ke exchange) didukung lewat kolom memo: `XRP:ALAMAT:MEMO.WORKER`.

Pool: `rx.unmineable.com:3333`, algoritma `rx`. Tool otomatis menyiapkan pool cadangan (port 13333, SSL 443, port 80) supaya tetap jalan kalau ISP memblokir port 3333.

### Kalau hasil tidak muncul di website

Jalankan:

```bash
unmineable sync
```

Perintah ini menguji hal berikut dan memberi kesimpulan dalam bahasa sederhana:

1. login ke setiap endpoint pool memakai akun kamu (diterima atau ditolak, plus pesan dari pool)
2. status XMRig lokal dan jumlah share yang diterima pool
3. data di website lewat API resmi: alamat dikenal atau baru, saldo, status worker online/offline, aktivitas terakhir
4. tautan dashboard yang benar untuk akun kamu

Penyebab paling umum:

- memakai mode alamat tetapi mencari hasilnya di akun website (pakai mode alias, atau buka dashboard alamat)
- membuka dashboard koin yang berbeda dari koin yang dipilih di tool
- port 3333 diblokir ISP: ubah pool di Pengaturan > Pool ke SSL 443 atau port 80
- alamat tidak sesuai jaringan koin sehingga pool menolak login
- belum ada share diterima: hashrate HP kecil, butuh menit sampai jam, dan data website tertunda beberapa menit

## Guard suhu dan baterai

Guard berjalan di background dan mengatur XMRig otomatis:

- pause saat suhu baterai mencapai batas, lanjut setelah turun ke suhu pulih
- pause saat baterai rendah dan tidak charging
- opsi hanya mining saat charging
- restart otomatis bila XMRig berhenti, dengan jeda bertahap
- notifikasi Android dan Telegram saat pause, lanjut, atau bermasalah

Default: pause 42°C, lanjut 38°C, baterai minimum 20%.

## Catatan

- Hashrate HP kecil dan perangkat bisa panas. Cek profit di simulator unMineable sebelum lanjut.
- Fee dan minimum payout dicek langsung di website unMineable.
- Mining hanya di perangkat milikmu atau dengan izin pemilik.
- unMineable tidak punya channel Telegram atau Discord resmi menurut situs mereka, waspadai penipu.
- Build XMRig dari source di HP bisa 10-30 menit.
- Format login, port pool, dan endpoint API mengikuti dokumentasi resmi unMineable. Path `/simulator` belum diverifikasi.
- Tool ini tidak berafiliasi dengan unMineable maupun XMRig.

## Kontribusi dan dukungan

- [CONTRIBUTING.md](CONTRIBUTING.md): cara berkontribusi, gaya kode, dan alur pull request
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md): kode etik komunitas
- [SECURITY.md](SECURITY.md): cara melaporkan kerentanan secara privat
- [SUPPORT.md](SUPPORT.md): tempat meminta bantuan
- [CHANGELOG.md](CHANGELOG.md): riwayat perubahan

## Lisensi

MIT

# Kebijakan keamanan

## Versi yang didukung

Perbaikan keamanan hanya diberikan untuk **rilis terbaru**
([Releases](https://github.com/djunekz/mining/releases)). Gunakan menu
**Update** di aplikasi untuk selalu memakai versi terbaru.

## Melaporkan celah keamanan

**Jangan** membuat issue publik untuk celah keamanan.

Laporkan secara privat lewat
[GitHub Private Vulnerability Reporting](https://github.com/djunekz/mining/security/advisories/new)
(tab **Security** > **Report a vulnerability**).

Sertakan:

- penjelasan celah dan dampaknya,
- langkah untuk mengulang (versi MINING, versi Termux/Android),
- saran perbaikan jika ada.

Target respons: balasan awal dalam **7 hari**. Setelah perbaikan dirilis, kamu
akan dikreditkan di catatan rilis (kecuali kamu meminta sebaliknya).

## Yang termasuk ruang lingkup

- Injeksi perintah lewat input pengguna (username, wallet, pool, worker, dll.).
- Pembuatan atau penyimpanan data akun/wallet yang tidak aman (izin file, hash password).
- File koin atau skrip yang bisa menjalankan kode tidak diinginkan (lihat guard di `tools/check-coins.sh`).
- Workflow GitHub Actions yang bisa disalahgunakan (mis. injeksi lewat judul PR).
- Pengalihan hasil mining ke wallet/pool yang tidak dipilih pengguna.

## Di luar ruang lingkup

- Celah pada miner pihak ketiga (xmrig, cpuminer, ccminer): laporkan ke proyek masing-masing.
- Pool atau situs koin pihak ketiga.
- Perangkat yang sudah di-root atau dikompromikan.

## Catatan keamanan penggunaan

- Akun di MINING bersifat **lokal** (di `~/.mining`); password disimpan sebagai
  hash + salt, tetapi siapa pun yang punya akses ke perangkatmu tetap bisa membaca file wallet.
- Aplikasi ini **tidak** memiliki dev-fee atau wallet tersembunyi. Jika kamu menemukan
  perilaku yang bertentangan, anggap itu celah keamanan dan laporkan.
- Unduh hanya dari repositori resmi ini dan periksa checksum `.sha256` di halaman rilis.

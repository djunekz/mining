# Pertanyaan yang Sering Diajukan

## Umum

### Apa itu unMineable Termux Miner?
Tool baris perintah dan menu interaktif untuk Termux yang memudahkan mining ke pool unMineable memakai XMRig. Ia mengurus login, pemasangan XMRig, proteksi suhu dan baterai, serta memeriksa apakah mining benar-benar terhubung ke pool dan website.

### Apakah gratis?
Ya, tool ini open source (MIT) dan gratis. Namun mining sendiri punya biaya: fee pool unMineable, donate level XMRig (bawaan 1 persen), listrik, dan keausan perangkat. Cek fee terbaru di situs unMineable.

### Apakah resmi dari unMineable?
Bukan. Proyek ini komunitas dan tidak berafiliasi dengan unMineable maupun XMRig. Lihat [DISCLAIMER.md](DISCLAIMER.md).

### Apakah bisa dipakai di Linux atau PC?
Dirancang untuk Termux di Android. Sebagian besar fitur berjalan di Linux biasa selama ada Python 3.8 atau lebih baru dan XMRig, tetapi fitur baterai, notifikasi, dan clipboard bergantung pada Termux:API, dan dukungan non-Termux belum menjadi fokus.

### Dari mana saya sebaiknya memasang Termux?
Gunakan sumber yang direkomendasikan proyek Termux, yaitu F-Droid atau rilis resmi di GitHub. Hindari mencampur Termux dan plugin-nya (Termux:API, Termux:Boot) dari sumber yang berbeda karena tanda tangannya tidak cocok.

## Login dan akun

### Kenapa saya harus login sebelum mining?
Supaya hasil mining tercatat ke akun atau alamat yang benar dan terbukti diterima pool. Login diverifikasi langsung ke pool unMineable. Tanpa login, tool menolak memulai mining.

### Apa beda mode alias dan mode alamat?
| | Alias akun website | Alamat dompet |
|---|---|---|
| Perlu daftar di website | ya | tidak |
| Username ke pool | `ALIAS.WORKER` | `KOIN:ALAMAT.WORKER` |
| Hasil terlihat di | akun website setelah login | halaman koin, bagian Address |
| Status | disarankan unMineable | cara lama, tetap berfungsi |

### Bagaimana cara mendaftar?
Jalankan `unmineable web`, pilih **Login / Daftar akun**, lalu klik Sign In atau Get started di website. Buat Alias di akun, lalu masukkan Alias itu saat `unmineable login`.

### Apakah tool ini menyimpan password atau seed phrase saya?
Tidak. Tool ini tidak pernah meminta password website, seed phrase, atau kunci privat. Yang disimpan hanya alias atau alamat dompet, nama worker, dan pengaturan.

### Saya salah memasukkan alamat. Bagaimana memperbaikinya?
Jalankan `unmineable login` lagi dan isi data yang benar. Dana yang sudah terlanjur dibayarkan ke alamat yang salah tidak bisa dikembalikan oleh tool ini.

### Bisakah memakai beberapa akun atau perangkat?
Ya. Buat beberapa profil di menu Akun & profil dan ganti dengan `unmineable -p NAMA`. Untuk beberapa perangkat, beri nama worker yang berbeda agar mudah dibedakan di website.

## Mining

### Kenapa hasil tidak muncul di website?
Jalankan `unmineable sync`. Penyebab paling umum:
- memakai mode alamat tetapi mencari hasilnya di akun website
- membuka dashboard koin yang berbeda dari koin yang dipilih
- port 3333 diblokir ISP (ubah pool di Pengaturan > Pool)
- alamat tidak cocok dengan jaringan koin sehingga pool menolak login
- belum ada share diterima karena hashrate HP kecil, dan data website tertunda beberapa menit

Panduan lengkap ada di [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

### Berapa hashrate yang normal untuk HP?
Biasanya jauh lebih kecil dari komputer, umumnya ratusan sampai beberapa ribu H/s tergantung prosesor. Gunakan benchmark di menu Alat & diagnosa untuk mengukur perangkatmu.

### Berapa penghasilannya?
Tidak ada angka pasti. Itu bergantung pada hashrate, harga koin, kesulitan jaringan, dan fee. Gunakan simulator di website unMineable untuk gambaran, dan perhitungkan biaya listrik serta keausan perangkat. Pada banyak ponsel, hasilnya kecil.

### Kenapa HP jadi panas?
Mining memakai CPU secara terus-menerus. Kurangi thread atau batas CPU di Pengaturan > Performa, aktifkan proteksi suhu, dan jangan gunakan sambil tertutup. Lihat [DISCLAIMER.md](DISCLAIMER.md) untuk risiko.

### Apa itu guard?
Proses background yang menjaga XMRig: menjeda saat HP terlalu panas atau baterai rendah, melanjutkan saat kondisi normal, memulai ulang XMRig bila berhenti, dan mengirim notifikasi. Penjelasan lengkap ada di [ARCHITECTURE.md](ARCHITECTURE.md).

### Apakah mining tetap jalan saat layar mati?
Tool memakai wake-lock Termux dan menjalankan mining di background. Agar stabil, matikan optimasi baterai untuk Termux di pengaturan Android, dan pasang Termux:API.

### Kenapa ada beberapa port pool?
Beberapa operator atau jaringan memblokir port mining. Tool menyiapkan pool utama plus cadangan (3333, 13333, SSL 443, 80), sehingga XMRig berpindah otomatis bila satu port tidak bisa dipakai.

### Apa itu donate level?
Pengaturan bawaan XMRig yang menyisihkan sebagian kecil waktu mining untuk pengembangnya (bawaan 1 persen). Bisa diubah di Pengaturan > Performa.

### Koin apa saja yang didukung?
Daftar resminya ada di <https://unmineable.com/coins>. Tool juga bisa menampilkannya lewat `unmineable coins`. Pastikan alamat cocok dengan koin dan jaringannya.

## Pemasangan dan pembaruan

### XMRig tidak terdeteksi, apa yang harus dilakukan?
Mining tidak akan berjalan tanpa XMRig. Jalankan `unmineable install` atau buka menu Instalasi & pembaruan. Tool mencoba repo Termux, lalu tur-repo, lalu build dari source (bisa 10 sampai 30 menit).

### Bagaimana cara memperbarui?
`unmineable update`. Untuk hanya mengecek, `unmineable update --check`. Pembaruan dari release memverifikasi checksum SHA256.

### Apa beda install dari lokal dan dari release?
Dari lokal memakai folder proyek yang kamu pegang (cocok untuk pengembangan). Dari release mengunduh rilis terbaru dari GitHub ke `~/.unmineable/app` dan memverifikasi checksum.

### Bagaimana cara menghapus semuanya?
`unmineable uninstall` menghentikan mining, lalu menawarkan menghapus konfigurasi, XMRig hasil build, dan launcher.

## Tampilan

### Kenapa layar tidak bisa di-scroll?
Menu berjalan sebagai aplikasi layar penuh agar tampilan selalu bersih dan pas dengan layar. Hasil panjang dibagi per halaman. Untuk keluaran biasa yang bisa di-scroll, gunakan perintah langsung seperti `unmineable status` atau `unmineable doctor`.

### Tampilan kotak berantakan, kenapa?
Biasanya karena font tidak mendukung karakter kotak Unicode atau terminal terlalu kecil. Lihat [TROUBLESHOOTING.md](TROUBLESHOOTING.md) dan [ACCESSIBILITY.md](ACCESSIBILITY.md).

## Privasi dan keamanan

### Data apa yang dikirim ke luar?
Hanya yang diperlukan untuk berfungsi: login ke pool, kueri ke API unMineable, pengecekan rilis di GitHub, dan notifikasi Telegram bila kamu mengaktifkannya. Tidak ada telemetri. Rincian di [PRIVACY.md](PRIVACY.md).

### Bagaimana melaporkan celah keamanan?
Jangan lewat issue publik. Ikuti [SECURITY.md](SECURITY.md).

## Kontribusi

### Bagaimana saya bisa membantu?
Baca [CONTRIBUTING.md](CONTRIBUTING.md). Laporan bug, perbaikan dokumentasi, dan pull request sangat diterima.

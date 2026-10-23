# Privasi

Tool ini dibuat dengan prinsip sederhana: **tidak ada telemetri, tidak ada akun di server kami, dan tidak ada data yang dikirim ke pembuat tool.** Semua pengaturan tersimpan di perangkatmu. Dokumen ini menjelaskan data apa yang disimpan, ke mana saja tool terhubung, dan bagaimana menghapusnya.

## Yang tidak kami lakukan

- Tidak ada analitik, pelacakan, atau laporan crash otomatis
- Tidak ada server milik proyek ini yang menerima data darimu
- Tidak ada iklan
- Tidak meminta password website, seed phrase, atau kunci privat
- Tidak menjual atau membagikan data kepada pihak mana pun

## Data yang disimpan di perangkatmu

| Data | Lokasi | Catatan |
|---|---|---|
| Alias atau alamat dompet, koin, memo, kode referral, nama worker | `~/.config/unmineable/profiles/*.json` | izin berkas `600` (hanya pemilik) |
| Pengaturan performa, proteksi, pool | berkas profil yang sama | |
| Token bot dan chat ID Telegram (jika diaktifkan) | berkas profil yang sama | disimpan sebagai teks biasa |
| Waktu login terakhir | berkas profil yang sama | |
| Riwayat hashrate, share, suhu dan persen baterai | `~/.config/unmineable/history.jsonl` | maksimal 2000 baris |
| Log XMRig dan log guard | `~/.config/unmineable/logs/` | dirotasi bila lebih dari 5 MB, dapat memuat host pool dan pesan error |
| Cache pengecekan versi | `~/.config/unmineable/update_check.json` | |
| PID proses | `~/.config/unmineable/*.pid` | |

Lihat tabel lengkap lokasi di [ARCHITECTURE.md](ARCHITECTURE.md).

## Ke mana tool terhubung

| Tujuan | Kapan | Data yang dikirim |
|---|---|---|
| **Pool unMineable** (`rx.unmineable.com`, port 3333, 13333, 443, 80) | saat mining, login, dan `sync` | username pool (alias, atau koin dan alamat dompet, plus nama worker dan referral), kata sandi `x`, dan nama agen `unmineable-termux/VERSI` pada tes login. Selama mining, XMRig yang berbicara dengan pool memakai identitasnya sendiri |
| **API unMineable** (`api.unminable.com`) | wizard login (info koin), `stats`, `sync` | alamat dompet, koin, dan memo, hanya untuk membaca data publik akun |
| **GitHub** (`api.github.com`, `github.com`, `codeload.github.com`) | cek dan pasang pembaruan, install dari release, build XMRig | permintaan HTTPS biasa. GitHub dapat mencatat alamat IP-mu |
| **Telegram** (`api.telegram.org`) | hanya jika kamu mengaktifkan notifikasi Telegram | token bot, chat ID, dan teks notifikasi (judul, nama worker, pesan) |
| **Repo paket Termux** | saat `unmineable install` | permintaan paket lewat `pkg` |
| **Server XMRig devfee** | selama mining, sebesar donate level | dilakukan oleh XMRig sendiri sesuai pengaturan donate level |

Website unMineable hanya dibuka di browsermu bila kamu memilih menu website. Tool tidak membuka browser sendiri.

Server HTTP lokal XMRig (`127.0.0.1:18080`) hanya bisa diakses dari perangkatmu sendiri. Ia dipakai tool untuk membaca hashrate dan tidak terbuka ke jaringan.

## Pihak ketiga

Pool, API, GitHub, Telegram, Termux, dan XMRig punya kebijakan privasi masing-masing yang berlaku saat kamu memakai layanan mereka:

- unMineable: <https://unmineable.com>
- GitHub: <https://github.com>
- Telegram: <https://telegram.org>
- XMRig: <https://github.com/xmrig/xmrig>
- Termux: <https://termux.dev>

Kami tidak mengendalikan bagaimana pihak-pihak tersebut menangani datamu.

## Alamat dompet bersifat publik

Alamat dompet kripto dan aktivitas pembayarannya umumnya tercatat di blockchain yang bersifat publik. Mining ke suatu alamat dapat mengaitkan alamat itu dengan nama worker dan alamat IP di sisi pool. Pertimbangkan hal ini sebelum memakai alamat yang terhubung ke identitasmu.

## Keamanan data lokal

- Berkas profil memakai izin `600`. Jangan membagikan folder `~/.config/unmineable`, mengunggahnya ke repo, atau menempelkannya di issue.
- Token Telegram tersimpan sebagai teks biasa di berkas profil. Gunakan bot khusus dan cabut tokennya lewat @BotFather bila bocor.
- Tool menyamarkan alamat dompet pada tampilan (misalnya `DH5yai…R3mr7L`), tetapi log atau keluaran yang kamu salin sendiri bisa memuat data sensitif. Hapus alamat, alias, dan token sebelum menempelkan log di issue.
- Backup perangkat (misalnya cadangan Android) dapat ikut menyimpan folder konfigurasi.

## Menghapus data

- Keluar dari akun: `unmineable logout` (menawarkan menghapus alias atau alamat dari profil)
- Hapus profil tertentu: menu Akun & profil > Hapus profil
- Bersihkan log dan riwayat: menu Log > Bersihkan log
- Hapus semuanya: `unmineable uninstall`, atau secara manual:

```bash
rm -rf ~/.config/unmineable ~/.unmineable ~/.termux/boot/unmineable-start
```

Data yang sudah ada di pool, API, atau blockchain berada di luar kendali tool ini. Hubungi penyedia layanan terkait untuk permintaan penghapusan.

## Perubahan kebijakan

Perubahan pada dokumen ini dicatat di riwayat git dan, bila relevan, di [CHANGELOG.md](CHANGELOG.md).

## Kontak

Pertanyaan privasi dapat diajukan lewat [issue](https://github.com/djunekz/unmineable/issues). Untuk masalah keamanan, ikuti [SECURITY.md](SECURITY.md).

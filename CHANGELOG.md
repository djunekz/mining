# Changelog

Semua perubahan penting pada proyek ini dicatat di berkas ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/) dan proyek ini memakai [Semantic Versioning](https://semver.org/lang/id/).

Catatan di bawah judul setiap versi dipakai otomatis sebagai isi GitHub Release oleh workflow `auto-release.yml`.

## [Unreleased]

## [0.1.0] - 2026-10-23

Rilis pertama.

### Ditambahkan

- Menu interaktif layar penuh untuk Termux: setiap tampilan tampil di layar bersih tanpa scroll, menyesuaikan ukuran terminal, hasil panjang dibagi per halaman, dan proses panjang tampil di panel berukuran tetap.
- Login ke unMineable dengan dua mode: alias akun website (disarankan) atau alamat dompet, termasuk dukungan memo/tag. Login diverifikasi langsung ke pool, dan mining hanya bisa dimulai setelah login berhasil.
- Deteksi XMRig: mining ditolak jika XMRig tidak terdeteksi atau tidak bisa dijalankan, dengan tawaran pemasangan otomatis lewat repo Termux, tur-repo, atau build dari source.
- Mining di background dengan guard yang menjeda saat suhu baterai tinggi atau baterai rendah, opsi hanya mining saat charging, dan restart otomatis dengan jeda bertahap bila XMRig berhenti.
- Pool cadangan otomatis (port 3333, 13333, SSL 443, dan 80) untuk jaringan yang memblokir port mining.
- Perintah `unmineable sync` untuk menguji login ke setiap endpoint pool, status XMRig lokal, dan data di website lewat API resmi (saldo, status worker, aktivitas terakhir).
- Diagnosa otomatis dari log XMRig dengan saran perbaikan, serta perintah `doctor` untuk memeriksa lingkungan.
- Dashboard live dengan hashrate, share, riwayat hashrate, baterai, dan log, serta statistik saldo, worker, dan pembayaran dari API unMineable.
- Banyak profil akun, validasi alamat dompet per koin (termasuk aturan resmi unMineable), dan wizard setup.
- Pengaturan performa (thread, batas CPU, mode RandomX, prioritas), proteksi suhu dan baterai, pool, notifikasi Android dan Telegram, serta autostart lewat Termux:Boot.
- Benchmark CPU dan menu website (login/daftar, dashboard milikku, wizard resmi, koin, simulator, kontak resmi).
- Pembaruan dari rilis GitHub dengan verifikasi checksum SHA256, channel `main` untuk versi dev, dan pemberitahuan versi baru.
- `install.sh` dengan dua pilihan: install dari lokal atau install dari release.
- Workflow `auto-release.yml` yang membuat GitHub Release otomatis saat tag dibuat.
- Dokumen komunitas: panduan kontribusi, kode etik, kebijakan keamanan, template issue, dan template pull request.

[Unreleased]: https://github.com/djunekz/unmineable/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/djunekz/unmineable/releases/tag/v0.1.0

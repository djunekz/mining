# Aksesibilitas

Kami ingin tool ini bisa dipakai oleh sebanyak mungkin orang, termasuk pengguna dengan keterbatasan penglihatan, motorik, atau yang memakai terminal dengan pengaturan khusus. Dokumen ini menjelaskan apa yang sudah didukung, keterbatasan yang kami ketahui, dan cara melapor.

Tool ini adalah aplikasi terminal, jadi aksesibilitasnya sangat bergantung pada terminal, font, dan teknologi bantu yang kamu pakai. Kami tidak mengklaim kepatuhan terhadap standar tertentu seperti WCAG, yang ditujukan untuk web.

## Yang sudah didukung

- **Hanya papan ketik.** Semua fitur bisa dipakai lewat ketikan. Tidak ada input yang bergantung pada mouse, sentuhan khusus, atau waktu.
- **Warna tidak menjadi satu-satunya penanda.** Status selalu disertai teks, misalnya "ya", "belum login", "terdeteksi", "tidak terdeteksi", serta simbol ✓ dan ✗. Pesan kesalahan dan peringatan ditulis lengkap, bukan hanya diberi warna.
- **Mendukung `NO_COLOR`.** Jika variabel lingkungan `NO_COLOR` diatur, semua warna dimatikan.
- **Keluaran linear saat bukan terminal.** Jika keluaran dialihkan atau di-pipe, warna dan pembersihan layar otomatis dimatikan.
- **Perintah non-layar-penuh.** Perintah seperti `unmineable status`, `doctor`, `sync`, `stats`, dan `logs` mencetak keluaran biasa secara berurutan tanpa menghapus layar. Ini lebih ramah bagi pembaca layar dan alat bantu yang memantau keluaran terminal.
- **Tinggi dan lebar menyesuaikan.** Tampilan beradaptasi hingga sekitar 16 baris dan lebar 40 kolom. Header diringkas otomatis di layar kecil, termasuk saat papan ketik virtual terbuka.
- **Pesan singkat dan jelas.** Teks dalam bahasa Indonesia sederhana, tiap kesalahan disertai saran langkah berikutnya.
- **Konfirmasi untuk tindakan berisiko.** Tindakan seperti logout, hapus profil, dan uninstall meminta konfirmasi, dengan pilihan bawaan yang aman.

## Saran untuk pembaca layar dan teknologi bantu

- Gunakan perintah langsung alih-alih menu layar penuh. Menu layar penuh membersihkan dan menggambar ulang layar, yang bisa terdengar berisik di sebagian pembaca layar.
- Jalankan `unmineable login` untuk masuk, `unmineable start` untuk mulai, dan `unmineable status` untuk melihat keadaan. Wizard `login` membersihkan layar di awal, jadi gunakan `unmineable status` dan `unmineable doctor` bila ingin keluaran yang benar-benar berurutan.
- Alihkan keluaran ke berkas bila perlu, misalnya `unmineable doctor > doctor.txt`.
- Atur `NO_COLOR=1` agar tidak ada kode warna di keluaran.

## Keterbatasan yang kami ketahui

- Tampilan kotak memakai karakter Unicode (`╭ ─ │ ╰`) dan blok grafik (`▁▂▃█`). Pada font tanpa karakter ini, tampilan bisa rusak. Belum ada mode ASCII murni.
- Menu layar penuh memakai alternate screen dan penggambaran ulang, yang belum diuji dengan berbagai pembaca layar Android.
- Panel proses (pasang paket, build, mining foreground) memperbarui layar berulang kali, sehingga kurang cocok untuk pembaca layar. Alternatifnya, jalankan perintah di luar menu dan baca log lewat `unmineable logs`.
- Indikator proses (spinner) menulis ulang satu baris berulang kali saat terminal interaktif, yang bisa terdengar berisik. Indikator ini tidak muncul saat keluaran dialihkan.
- Teks hanya tersedia dalam bahasa Indonesia.
- Kontras warna bergantung pada tema terminal milikmu.

## Pedoman untuk kontributor

Saat mengubah tampilan, patuhi hal berikut:

1. Jangan menyampaikan informasi hanya lewat warna. Selalu sertakan teks atau simbol.
2. Semua keluaran lewat fungsi di `ui.py`, supaya dukungan `NO_COLOR` dan mode non-terminal tetap berlaku.
3. Jangan menambah input yang bergantung pada waktu atau kecepatan mengetik.
4. Uji di terminal kecil (sekitar 16 baris) dan besar.
5. Pastikan hal yang bisa dilakukan lewat menu juga bisa dilakukan lewat perintah.
6. Tulis pesan yang jelas dan sertakan langkah perbaikan.

## Melaporkan masalah aksesibilitas

Buka issue memakai template [Laporan bug](https://github.com/djunekz/unmineable/issues/new/choose) dan awali judul dengan `[Aksesibilitas]`. Sebutkan terminal, teknologi bantu, dan perangkat yang kamu pakai, serta apa yang sulit dilakukan. Usulan perbaikan dan pull request sangat kami hargai.

# Tata Kelola Proyek

Dokumen ini menjelaskan bagaimana proyek unMineable Termux Miner dikelola: siapa yang memutuskan, bagaimana keputusan dibuat, dan bagaimana orang baru bisa mengambil peran lebih besar.

## Tujuan dan batasan

**Tujuan:** menyediakan cara yang mudah, aman, dan transparan untuk mining ke pool unMineable lewat Termux memakai XMRig.

**Prinsip:**

- ringan: hanya pustaka standar Python, tanpa dependensi pihak ketiga
- transparan: tanpa telemetri, perilaku jelas bagi pengguna
- aman bagi perangkat: proteksi suhu dan baterai adalah fitur inti
- jujur: tidak menjanjikan penghasilan, selalu menyertakan risiko

**Di luar lingkup (tidak akan diterima):**

- fitur untuk menyembunyikan mining, menghindari deteksi, atau menambang tanpa sepengetahuan pemilik perangkat
- pengumpulan data pengguna atau telemetri
- fitur yang melewati syarat login atau pemeriksaan XMRig
- dukungan untuk aktivitas yang melanggar hukum atau ketentuan layanan pihak ketiga

## Peran

### Pemelihara (maintainer)

Pemelihara saat ini: **@djunekz** (pemilik repo).

Pemelihara berwenang untuk menggabungkan pull request, mengelola issue, membuat rilis, menegakkan [Kode Etik](CODE_OF_CONDUCT.md), dan menentukan arah proyek.

### Kontributor

Siapa pun yang mengirim issue, pull request, dokumentasi, terjemahan, atau ulasan. Kontributor tidak perlu izin khusus. Cukup ikuti [CONTRIBUTING.md](CONTRIBUTING.md).

### Pengguna

Pengguna yang memberi umpan balik, melaporkan bug, atau membantu pengguna lain adalah bagian penting dari komunitas.

## Pengambilan keputusan

Proyek ini memakai model **pemelihara utama dengan musyawarah**:

1. Diskusi terjadi terbuka di issue dan pull request.
2. Kami berusaha mencapai kesepakatan lewat diskusi. Sebagian besar keputusan selesai di tahap ini.
3. Jika tidak ada kesepakatan, pemelihara membuat keputusan akhir dan menjelaskan alasannya secara tertulis.

Perubahan kecil (perbaikan bug, dokumentasi) bisa digabungkan langsung setelah ditinjau. Perubahan besar (fitur baru, perubahan perilaku, perubahan format konfigurasi, perubahan yang memengaruhi keamanan) sebaiknya didiskusikan di issue lebih dulu.

## Ulasan pull request

- Setiap pull request ditinjau pemelihara sebelum digabungkan.
- Pull request harus lolos pemeriksaan di [CONTRIBUTING.md](CONTRIBUTING.md) dan melengkapi template.
- Perubahan yang terlihat oleh pengguna harus menambah catatan di `CHANGELOG.md`.
- Pemelihara dapat meminta perubahan, menolak dengan alasan, atau menutup pull request yang tidak aktif.

## Pembuatan rilis

Rilis dibuat oleh pemelihara dengan langkah di [CONTRIBUTING.md](CONTRIBUTING.md). Workflow `auto-release.yml` membuat GitHub Release otomatis dari tag, memakai catatan dari `CHANGELOG.md`.

## Kebijakan versi

Proyek mengikuti [Semantic Versioning](https://semver.org/lang/id/).

- **0.x.y (saat ini):** proyek masih berkembang. Versi minor (0.**x**.0) boleh memuat perubahan yang tidak kompatibel, dan akan dicatat jelas di `CHANGELOG.md`. Versi patch (0.x.**y**) hanya berisi perbaikan.
- **1.0.0 dan seterusnya:** perubahan tidak kompatibel hanya pada versi mayor, dengan pemberitahuan sebelumnya.

Format berkas profil dijaga agar bisa dibaca versi lebih baru. Bidang baru selalu punya nilai bawaan.

## Dukungan versi

Hanya rilis terbaru yang menerima perbaikan, termasuk perbaikan keamanan. Lihat [SECURITY.md](SECURITY.md).

## Menjadi pemelihara

Kontributor yang konsisten bisa diundang menjadi pemelihara. Pertimbangan utama:

- riwayat kontribusi yang berkualitas dan berkelanjutan
- pemahaman terhadap prinsip dan batasan proyek
- sikap yang baik sesuai Kode Etik
- kesediaan meluangkan waktu untuk ulasan dan dukungan

Pemelihara yang ada memutuskan undangan. Pemelihara yang tidak aktif dalam waktu lama dapat dipindahkan menjadi pemelihara emeritus, tanpa mengurangi penghargaan atas kontribusinya.

## Penyelesaian konflik

1. Selesaikan perbedaan lewat diskusi yang sopan di issue atau pull request.
2. Jika buntu, pemelihara memutuskan dan menjelaskan alasannya.
3. Pelanggaran perilaku ditangani sesuai [Kode Etik](CODE_OF_CONDUCT.md).
4. Masalah keamanan ditangani lewat jalur privat di [SECURITY.md](SECURITY.md).

## Aktivitas issue dan pull request

Issue yang menunggu informasi dari pelapor dan tidak ada tanggapan dalam waktu lama dapat ditutup, dan bisa dibuka lagi bila informasinya sudah ada. Pull request yang lama tidak aktif dapat ditutup dengan catatan agar bisa dilanjutkan kapan saja.

## Perubahan tata kelola

Dokumen ini dapat diubah lewat pull request dan diputuskan oleh pemelihara setelah diskusi terbuka. Perubahan dicatat di riwayat git.

## Lisensi dan kontribusi

Proyek dilisensikan di bawah [MIT](LICENSE). Dengan mengirim kontribusi, kamu setuju kontribusimu dilisensikan dengan lisensi yang sama.

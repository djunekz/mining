# Kebijakan Keamanan

## Versi yang didukung

Perbaikan keamanan diberikan untuk rilis terbaru.

| Versi | Didukung |
|---|---|
| 0.1.x | ya |
| di bawah 0.1.0 | tidak |

## Melaporkan kerentanan

**Jangan membuka issue publik untuk kerentanan keamanan.**

Laporkan secara privat lewat GitHub: buka tab **Security** di repo ini, pilih **Report a vulnerability**, atau langsung ke <https://github.com/djunekz/unmineable/security/advisories/new>.

Sertakan sebisa mungkin:

- jenis masalah dan dampaknya
- versi tool (`unmineable --version`), perangkat, dan cara pemasangan
- langkah untuk mereproduksi
- bukti konsep atau log yang relevan (hapus alamat dompet, token, dan alias sebelum mengirim)

Yang bisa kamu harapkan:

- konfirmasi laporan dalam beberapa hari
- kabar perkembangan selama perbaikan dikerjakan
- pencantuman nama kamu di catatan rilis jika kamu mau

Mohon beri waktu yang wajar untuk memperbaiki sebelum mengungkap masalah ke publik.

## Cakupan

Termasuk cakupan:

- pemasangan dan pembaruan tool (`install.sh`, `updater`, verifikasi checksum, ekstraksi arsip)
- penyimpanan data lokal: profil akun, token bot Telegram, dan log
- kebocoran informasi sensitif lewat keluaran, log, atau notifikasi
- injeksi perintah atau penulisan berkas di luar lokasi yang seharusnya
- jalur yang melewati syarat login atau pemeriksaan XMRig

Di luar cakupan (laporkan ke pihak terkait):

- kerentanan pada XMRig: laporkan ke <https://github.com/xmrig/xmrig>
- masalah pada layanan atau website unMineable: hubungi dukungan resmi unMineable
- serangan yang butuh akses fisik ke perangkat yang sudah tidak terkunci atau sudah di-root oleh penyerang
- profitabilitas mining, fee, dan kebijakan payout

## Catatan keamanan untuk pengguna

- Berkas profil tersimpan di `~/.config/unmineable/profiles/` dengan izin `600`. Token bot Telegram ikut tersimpan di sana dalam bentuk teks biasa, jadi jangan bagikan folder itu atau mengunggahnya ke repo.
- Saat melapor masalah, selalu hapus alamat dompet, alias, token, dan chat ID dari log yang kamu tempel.
- Pasang tool dari rilis resmi di <https://github.com/djunekz/unmineable/releases>. Installer dan pembaruan memverifikasi checksum SHA256 arsip rilis.
- Unduh XMRig hanya dari repo resmi Termux atau <https://github.com/xmrig/xmrig>.
- unMineable tidak memiliki channel Telegram atau Discord resmi. Waspadai orang yang mengaku admin, dan jangan pernah membagikan seed phrase.
- Mining hanya di perangkat milikmu atau dengan izin pemiliknya.

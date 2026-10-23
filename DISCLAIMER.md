# Penafian

Baca dokumen ini sebelum memakai unMineable Termux Miner. Dengan memakai tool ini, kamu dianggap memahami dan menerima isinya.

## Tidak berafiliasi

Proyek ini dibuat oleh komunitas dan **tidak berafiliasi, didukung, atau disetujui** oleh unMineable maupun XMRig. Semua nama, merek, dan logo adalah milik pemiliknya masing-masing. Tool ini hanya memudahkan penggunaan XMRig untuk terhubung ke pool unMineable.

## Bukan nasihat keuangan

Tidak ada bagian dari proyek ini, termasuk README, dokumentasi, simulator yang ditautkan, atau angka hashrate, yang merupakan nasihat keuangan, investasi, pajak, atau hukum.

- Harga aset kripto sangat fluktuatif dan bisa turun drastis.
- Penghasilan dari mining tidak dijamin dan bisa jauh lebih kecil dari perkiraan, bahkan bisa lebih kecil dari biaya listrik dan keausan perangkat.
- Fee, ambang pembayaran minimum, dan kebijakan payout ditentukan oleh unMineable dan dapat berubah sewaktu-waktu. Selalu cek langsung di situs resminya.
- Kamu bertanggung jawab penuh atas keputusan finansialmu.

## Risiko perangkat

Mining memakai CPU secara intensif. Pada ponsel, ini dapat menyebabkan:

- perangkat menjadi panas
- baterai cepat aus atau menggembung
- performa perangkat menurun
- pemakaian kuota data
- masa pakai perangkat berkurang

Guard suhu dan baterai di tool ini membantu mengurangi risiko, tetapi **bukan jaminan keselamatan**. Pembacaan suhu bergantung pada Termux:API dan bisa tidak akurat. Jangan menaruh perangkat yang sedang mining di tempat tertutup, di bawah bantal, atau tanpa pengawasan di lingkungan panas. Hentikan mining bila perangkat terasa terlalu panas. Risiko kerusakan perangkat sepenuhnya ada pada kamu.

## Risiko kehilangan dana

- **Alamat atau jaringan yang salah** dapat membuat dana hilang permanen. Pastikan alamat dompet cocok dengan koin dan jaringannya, dan periksa kebutuhan memo atau tag.
- Validasi alamat di tool ini hanya memeriksa format, bukan kepemilikan atau kebenaran jaringan.
- Jangan pernah membagikan seed phrase atau kunci privat kepada siapa pun. Tool ini tidak pernah memintanya.
- unMineable tidak memiliki channel Telegram atau Discord resmi menurut situs mereka. Waspadai penipu.

## Penggunaan yang sah

Gunakan tool ini **hanya di perangkat milikmu sendiri atau dengan izin tertulis pemiliknya**. Dilarang keras memakainya untuk menambang di perangkat orang lain tanpa sepengetahuan mereka (cryptojacking), menyembunyikan aktivitas mining, atau menghindari kontrol keamanan. Proyek ini tidak menyediakan dan tidak akan menerima fitur untuk menyembunyikan mining.

Kamu bertanggung jawab memastikan penggunaan sesuai hukum dan aturan yang berlaku di wilayahmu, termasuk aturan terkait aset kripto, pajak, dan kebijakan penyedia internet atau operator seluler. Beberapa jaringan, kampus, tempat kerja, atau penyedia layanan melarang mining.

## Perangkat lunak pihak ketiga

- **XMRig** adalah perangkat lunak terpisah dengan lisensi dan kebijakannya sendiri. Secara bawaan XMRig menyisihkan sebagian kecil waktu mining (donate level) untuk pengembangnya. Nilai ini bisa kamu atur di Pengaturan > Performa.
- Beberapa antivirus atau Play Protect dapat menandai XMRig sebagai ancaman (false positive). Unduh XMRig hanya dari repo resmi Termux atau <https://github.com/xmrig/xmrig>.
- **Termux**, **Termux:API**, dan **Termux:Boot** adalah proyek terpisah.
- Layanan **unMineable** dan **GitHub** dikelola pihak lain, dan ketersediaannya di luar kendali kami.

## Tanpa jaminan

Perangkat lunak ini disediakan "sebagaimana adanya" tanpa jaminan apa pun, tersurat maupun tersirat, termasuk jaminan kelayakan untuk diperdagangkan, kesesuaian untuk tujuan tertentu, dan tidak adanya pelanggaran, sebagaimana tercantum di [LICENSE](../LICENSE) (MIT). Pembuat dan kontributor tidak bertanggung jawab atas kerugian apa pun, termasuk kehilangan dana, kerusakan perangkat, kehilangan data, atau kerugian lain yang timbul dari penggunaan atau ketidakmampuan menggunakan tool ini.

Proyek ini masih berada pada versi 0.x. Perilaku dapat berubah antar rilis, dan bug mungkin ada. Lihat [CHANGELOG.md](CHANGELOG.md).

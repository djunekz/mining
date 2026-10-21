# Bantuan

## Cek dulu masalah yang umum

| Gejala | Penyebab | Solusi |
|---|---|---|
| `File 'mining.sh' is unwritable` di nano | File ada di penyimpanan bersama (`/sdcard`, `~/storage/...`) atau read-only | Salin ke folder home Termux (`cp ... ~/mining/`) atau `chmod u+w mining.sh` |
| `xmrig belum terpasang` | Miner belum di-install | Menu **Update > Miner > xmrig** (dikompilasi dari sumber, 10-30 menit) |
| `E: Unable to locate package xmrig` | xmrig memang tidak ada di repo paket Termux | Jangan pakai `pkg install xmrig`; pakai menu **Update > Miner > xmrig** |
| Kompilasi xmrig gagal / `No space left on device` | Ruang penyimpanan kurang (butuh sekitar 1 GB) | Kosongkan ruang, `pkg clean`, lalu ulangi |
| `E: Unable to locate package cpuminer` | cpuminer tidak ada di repo paket Termux | Pakai menu **Update > Miner > cpuminer** (dikompilasi dari sumber) |
| Update bilang "Sudah versi terbaru" padahal `VERSION` lebih lama dari rilis | Versi lama hanya membandingkan commit | Perbarui ke versi terbaru dari repo (clone ulang atau `git pull`); versi baru membandingkan juga `VERSION` dengan rilis terbaru |
| `termux-api tidak ada: pengaman suhu NONAKTIF` | Paket / aplikasi Termux:API belum ada | Menu **Update > Miner > Dasar**, lalu pasang aplikasi **Termux:API** dari F-Droid |
| Kotak menu terpotong atau miring | Layar terlalu sempit atau font tidak monospace | Kecilkan font Termux (cubit layar) atau ubah `UI_W` di `lib/ui.sh` |
| `DNS error: "no address"` di xmrig | DNS HP gagal meresolve nama pool | Pilih pool **otomatis** (Enter): MINING memakai alamat IP cadangan. Atau matikan VPN / Private DNS |
| `SHA-256 tidak cocok` saat pasang ccminer | Berkas unduhan berubah atau rusak | Ulangi; bila tetap, buka issue (berkas ditolak demi keamanan) |
| Ingin menghapus miner | - | **Update > Miner > Uninstall** |
| `Format pool harus host:port` | Alamat pool salah | Isi seperti `pool.example.com:3333` tanpa `http://` |
| Update gagal | Folder bukan hasil `git clone` atau ada perubahan lokal | `git clone https://github.com/djunekz/mining` ulang, atau `git stash` lalu update |
| Lupa password | Akun hanya lokal, tidak ada reset | Hapus folder `~/.mining` lalu daftar ulang |

## Masih bermasalah?

1. Cari di [issue yang ada](https://github.com/djunekz/mining/issues?q=is%3Aissue).
2. Jika belum ada, buat issue dengan template yang sesuai:
   [bug](https://github.com/djunekz/mining/issues/new?template=bug_report.yml),
   [fitur](https://github.com/djunekz/mining/issues/new?template=feature_request.yml),
   [koin baru](https://github.com/djunekz/mining/issues/new?template=new_coin.yml),
   [pool bermasalah](https://github.com/djunekz/mining/issues/new?template=pool_problem.yml).
3. **Jangan** menempelkan alamat wallet, password, atau data pribadi.

Celah keamanan: lihat [SECURITY.md](SECURITY.md), jangan lewat issue publik.

> Catatan: proyek ini hanya launcher untuk miner open-source. Pertanyaan tentang
> cara kerja miner (xmrig, cpuminer, ccminer) atau pool sebaiknya ditanyakan ke
> proyek / pool masing-masing.

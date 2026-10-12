## Koin baru

- **Nama:**
- **Simbol:**
- **Algoritma:**
- **Miner:** <!-- xmrig / cpuminer / ccminer -->
- **Situs resmi:**
- **Pool default (opsional):** <!-- host:port, pool publik yang sah -->

## Checklist

- [ ] Hanya menambah **satu file** `coins/<simbol-huruf-kecil>.sh` (dibuat dari `coins/_TEMPLATE.sh.example`)
- [ ] `bash tools/check-coins.sh` lolos
- [ ] File hanya berisi komentar dan assignment `COIN_*="teks"`; tidak ada `coin_cmd()` kecuali benar-benar perlu
- [ ] Jika memakai `coin_cmd()`: isinya hanya `CMD=(<miner> ...)` dan sudah kujelaskan di bawah
- [ ] Pool default (jika ada) adalah pool publik yang sah, **bukan** alamat yang mengalihkan hasil mining ke pihak lain
- [ ] Tidak ada alamat wallet di file koin
- [ ] Judul PR: `feat(coins): tambah koin <NAMA>`

## Catatan untuk reviewer

<!-- Praktis di HP atau tidak? Hasil uji miner? Alasan memakai coin_cmd()? -->

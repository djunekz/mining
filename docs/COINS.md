# Daftar koin

> File ini dibuat **otomatis** oleh `tools/gen-coins-md.sh` (workflow `coins-doc`).
> Jangan diedit manual; ubah file koin di folder `coins/`.

Total: **30 koin**.

| Kode | Nama | Algoritma | Miner | Pool default | Praktis di HP | Catatan |
|---|---|---|---|---|---|---|
| ARQ | ArQmA | `rx/arq` | xmrig | - | ya | CPU |
| BCH | Bitcoin Cash | `sha256d` | cpuminer | sha256.mine.zpool.ca:3333 | tidak | Hasil hampir nol |
| BTC | Bitcoin | `sha256d` | cpuminer | solo.ckpool.org:3333 (+2 cadangan) | tidak | Solo: hadiah hanya bila temu blok |
| CCX | Conceal | `cn/ccx` | xmrig | - | ya | CPU |
| DASH | Dash | `x11` | cpuminer | x11.mine.zpool.ca:3534 | tidak | Hasil hampir nol |
| DERO | Dero | `astrobwt` | xmrig | - | ya | CPU |
| DGB | DigiByte | `sha256d` | cpuminer | sha256.mine.zpool.ca:3333 | tidak | Hasil hampir nol |
| DOGE | Dogecoin | `scrypt` | cpuminer | scrypt.mine.zpool.ca:3433 | tidak | Hasil hampir nol |
| ETC | Eth. Classic | `etchash` | none | - | tidak | Butuh GPU, belum ada miner |
| GRAFT | Graft | `rx/graft` | xmrig | - | ya | CPU |
| KCN | Kylacoin | `flex` | xmrig | - | ya | CPU |
| KVA | Kevacoin | `rx/keva` | xmrig | - | ya | CPU |
| LTC | Litecoin | `scrypt` | cpuminer | scrypt.mine.zpool.ca:3433 | tidak | Hasil hampir nol |
| MBC | MicroBitcoin | `yespower` | cpuminer | - | ya | CPU |
| RTM | Raptoreum | `ghostrider` | xmrig | - | ya | CPU berat |
| RVN | Ravencoin | `kawpow` | xmrig | - | tidak | Butuh GPU |
| RYO | Ryo Currency | `cn/gpu` | xmrig | - | ya | CPU lambat |
| SAL | Salvium | `rx/0` | xmrig | - | ya | CPU |
| SFX | Safex | `rx/sfx` | xmrig | - | ya | CPU |
| TLO | Talleo | `cn-pico/tlo` | xmrig | - | ya | CPU ringan |
| TRTL | TurtleCoin | `argon2/chukwa` | xmrig | - | ya | CPU ringan |
| TUBE | BitTube | `cn-heavy/tube` | xmrig | - | ya | CPU berat |
| VRSC | Verus | `verus` | ccminer | na.luckpool.net:3956 (+2 cadangan) | ya | Populer di HP (butuh ccminer ARM) |
| WOW | Wownero | `rx/wow` | xmrig | - | ya | CPU |
| XHV | Haven | `cn-heavy/xhv` | xmrig | - | ya | CPU berat |
| XMR | Monero | `rx/0` | xmrig | pool.supportxmr.com:3333 (+3 cadangan) | ya | CPU - paling layak di HP |
| XTM | Tari (RandomX) | `rx/0` | xmrig | - | ya | CPU |
| YDA | Yadacoin | `rx/yada` | xmrig | - | ya | CPU |
| YTN | Yenten | `yespowerr16` | cpuminer | cpu-pool.com:63368 | ya | CPU |
| ZEPH | Zephyr | `rx/0` | xmrig | - | ya | CPU |

Koin yang tidak praktis (butuh ASIC/GPU) tetap ada di daftar agar mudah
diperluas, tetapi hasil mining di HP praktis nol.

Ingin menambah koin? Lihat [CONTRIBUTING.md](../CONTRIBUTING.md).

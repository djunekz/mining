# Menambah koin

Tidak perlu mengubah file lain. Cukup:

```bash
cp coins/_TEMPLATE.sh.example coins/abc.sh   # abc = simbol koin, huruf kecil
nano coins/abc.sh                             # isi datanya
bash tools/check-coins.sh                     # harus "Semua valid."
```

Lalu buat Pull Request. Koin otomatis muncul di menu **List Koin** dan **Mining**.

## Isi file koin

| Variabel | Arti |
|---|---|
| `COIN_SYMBOL` | Simbol huruf besar, harus sama dengan nama file (`abc.sh`) |
| `COIN_NAME` | Nama koin |
| `COIN_ALGO` | Nama algoritma menurut miner (xmrig: `rx/0`, `cn/r`, ...) |
| `COIN_MINER` | `xmrig`, `ccminer`, `cpuminer`, atau `none` |
| `COIN_POOL_DEFAULT` | `host:port` (boleh kosong, pengguna diminta mengisi) |
| `COIN_NOTE` | Keterangan singkat |
| `COIN_PRACTICAL` | `yes` layak di HP, `no` butuh ASIC/GPU |
| `coin_cmd()` | Opsional: susun sendiri array `CMD` bila miner butuh argumen khusus |

Jangan pakai karakter `|` di nilai apa pun.

## Aturan untuk reviewer

File koin di-`source` sebagai kode bash. Saat me-review PR, pastikan file koin
**hanya berisi assignment variabel** (dan `coin_cmd` bila perlu) — tolak yang
menjalankan perintah lain, mengunduh sesuatu, atau mengubah wallet/pool pengguna.
Pool default harus pool publik yang sah, bukan alamat yang mengarahkan hasil
mining ke pihak lain.

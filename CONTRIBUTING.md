# Kontribusi ke MINING

Terima kasih sudah mau berkontribusi! Dengan berpartisipasi, kamu setuju mengikuti
[Kode Etik](CODE_OF_CONDUCT.md). Celah keamanan: lihat [SECURITY.md](SECURITY.md).

## Menambah koin

Tidak perlu mengubah file lain. Cukup:

```bash
cp coins/_TEMPLATE.sh.example coins/abc.sh   # abc = simbol koin, huruf kecil
nano coins/abc.sh                             # isi datanya
bash tools/check-coins.sh                     # harus "Semua valid."
```

Lalu buat Pull Request (pakai template **koin baru**: tambahkan `?template=new_coin.md`
di URL PR). Koin otomatis muncul di menu **List Koin** dan **Mining**, dan
[`docs/COINS.md`](docs/COINS.md) diperbarui oleh workflow.

### Isi file koin

| Variabel | Arti |
|---|---|
| `COIN_SYMBOL` | Simbol huruf besar, harus sama dengan nama file (`abc.sh`) |
| `COIN_NAME` | Nama koin |
| `COIN_ALGO` | Nama algoritma menurut miner (xmrig: `rx/0`, `cn/r`, ...) |
| `COIN_MINER` | `xmrig`, `ccminer`, `cpuminer`, atau `none` |
| `COIN_POOL_PASS` | opsional: password pool untuk cpuminer/ccminer, mis. `c=DOGE` (zpool). Bawaan `x` |
| `COIN_POOL_DEFAULT` | `host:port` (boleh kosong, pengguna diminta mengisi) |
| `COIN_NOTE` | Keterangan singkat |
| `COIN_PRACTICAL` | `yes` layak di HP, `no` butuh ASIC/GPU |
| `coin_cmd()` | Opsional: susun sendiri array `CMD` bila miner butuh argumen khusus |

Jangan pakai karakter `|` di nilai apa pun.

## Alur kontribusi

1. Fork repo, buat branch dari `main` (`feat/koin-abc`, `fix/thread-default`, ...).
2. Lakukan perubahan, lalu jalankan pemeriksaan lokal:

   ```bash
   bash tests/smoke.sh          # menjalankan menu sungguhan dengan miner palsu
   bash tools/check-coins.sh    # validasi koin
   shellcheck -x -S warning mining.sh lib/*.sh tools/*.sh tests/*.sh   # jika terpasang
   ```

3. Buka Pull Request dan isi template-nya.
4. Tunggu CI hijau dan review maintainer.

## Format commit dan judul PR

Pakai [Conventional Commits](https://www.conventionalcommits.org/id/). Changelog dan
nomor versi dibuat **otomatis** dari pesan ini, jadi judul PR yang benar itu penting
(dicek oleh workflow `pr-title`).

```text
feat(coins): tambah koin ABC
fix(miner): perbaiki jumlah thread default
docs: perjelas cara instalasi
feat(ui)!: ubah tata letak menu        # tanda ! = perubahan besar (major)
```

| Tipe | Arti | Versi |
|---|---|---|
| `feat` | fitur / koin baru | minor |
| `fix` | perbaikan bug | patch |
| `perf`, `refactor`, `revert` | perubahan tanpa fitur baru | patch |
| `docs`, `ci`, `build`, `chore`, `test`, `style` | tidak mengubah perilaku | tidak ada rilis |

Penjelasan lengkap alur rilis dan workflow: [docs/AUTOMATION.md](docs/AUTOMATION.md).
**Jangan** mengedit `CHANGELOG.md` atau `VERSION` secara manual di PR.

## Aturan untuk reviewer

File koin di-`source` sebagai kode bash. `tools/check-coins.sh` menolak otomatis
baris selain komentar, `COIN_*="teks"`, dan `coin_cmd()` yang isinya hanya
`CMD=(...)`. Tetap periksa manual:

- file koin **hanya berisi assignment variabel**; tolak yang menjalankan perintah lain,
  mengunduh sesuatu, atau mengubah wallet/pool pengguna;
- jika ada `coin_cmd()`, pastikan `CMD=(...)` memanggil miner yang sah dengan argumen wajar;
- pool default harus pool publik yang sah, bukan alamat yang mengarahkan hasil mining
  ke pihak lain;
- tidak ada alamat wallet di dalam repo.

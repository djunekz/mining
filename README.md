# TermuxMiner

Launcher menu untuk miner open-source (xmrig, cpuminer, ccminer) di Termux.
Satu perintah, satu menu, **satu file per koin**.

## Instalasi

```bash
pkg update -y && pkg install -y git
git clone https://github.com/djunekz/mining
cd mining
bash mining.sh
```

Lalu pilih **4. Update > 2. Pasang / cek miner** untuk memasang xmrig dsb.

## Menu

```
1. Mining      -> Login / Registrasi -> pilih koin -> mulai mining
2. List Koin   -> semua koin yang ada di folder coins/
3. Wallet      -> simpan alamat wallet per koin (per akun)
4. Update      -> git pull + pasang miner
5. About
6. Referral    -> kode referral akun Anda
```

## Struktur

```
mining.sh        menu utama
config.sh        nama, repo, batas suhu, dsb. (ubah APP_AUTHOR & REPO_URL)
VERSION
lib/             modul: ui auth coins install miner wallet referral update about
coins/           SATU FILE = SATU KOIN  (xmr.sh, vrsc.sh, ...)
tools/check-coins.sh   validator file koin
```

## Menambah koin (kontributor)

Cukup 1 file. Lihat [CONTRIBUTING.md](CONTRIBUTING.md).

## Yang perlu diketahui

- **Akun itu lokal.** Login/registrasi tersimpan di perangkat Anda
  (`~/.termuxminer`, password di-hash + salt). Tidak ada server, jadi tidak ada
  "lupa password"; hapus folder itu untuk reset.
- **Referral itu pencatatan lokal**, bukan program komisi. Tidak ada hadiah otomatis
  dan tidak ada yang mengubah wallet/pool mining siapa pun.
- **Tanpa dev-fee.** Wallet & pool 100% milik Anda. Catatan: xmrig sendiri
  menyumbang 1% ke pengembangnya secara default; atur di `config.sh`
  (`XMRIG_DONATE`, 0 untuk mematikan).
- **Mining di HP umumnya tidak menguntungkan** dan memanaskan baterai/CPU.
  Pengaman suhu otomatis butuh `termux-api` (+ aplikasi Termux:API dari F-Droid).
- Koin bertanda `[tdk praktis]` (BTC, LTC, DOGE, dst.) butuh ASIC/GPU.
- Pool default hanya diisi untuk XMR dan VRSC; alamat pool bisa berubah.

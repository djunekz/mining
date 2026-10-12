# MINING

[![CI](https://github.com/djunekz/mining/actions/workflows/ci.yml/badge.svg)](https://github.com/djunekz/mining/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/djunekz/mining?display_name=tag)](https://github.com/djunekz/mining/releases)
[![Changelog](https://img.shields.io/badge/changelog-CHANGELOG.md-blue)](CHANGELOG.md)

Multi-coin miner launcher untuk **Termux**: satu menu, 30 koin, dan
**satu file per koin** sehingga kontributor cukup menambah satu file.

```
  #   #  #####  #   #  #####  #   #   ####
  ## ##    #    ##  #    #    ##  #  #
  # # #    #    # # #    #    # # #  #  ##
  #   #    #    #  ##    #    #  ##  #   #
  #   #  #####  #   #  #####  #   #   ####
      M U L T I - C O I N   M I N E R
```

## Instalasi

```bash
pkg update -y && pkg install -y git
git clone https://github.com/djunekz/mining
cd mining
bash mining.sh
```

Lalu buka **4. Update > 2. Miner** untuk memasang xmrig dan miner lainnya.

## Menu

```
1. Mining      Login / Registrasi -> pilih koin -> mulai mining
2. List Koin   semua koin di folder coins/
3. Wallet      simpan alamat wallet per koin (per akun)
4. Update      git pull + pasang miner
5. About
6. Referral    kode referral akun kamu
```

## Struktur

```
mining.sh         menu utama
config.sh         nama, repo, batas suhu
VERSION           versi (dikelola otomatis oleh rilis)
CHANGELOG.md      riwayat perubahan (otomatis)
lib/              modul (ui, auth, miner, ...)
coins/            1 FILE = 1 KOIN (xmr.sh, ...)
tools/            validator koin, generator changelog & rilis
tests/            smoke test
docs/             daftar koin (COINS.md) & dokumentasi otomasi
.github/          workflows, template issue & PR
```

## Menambah koin (kontributor)

Cukup 1 file di `coins/`. Lihat [CONTRIBUTING.md](CONTRIBUTING.md).
Daftar koin saat ini: [docs/COINS.md](docs/COINS.md).

## Dokumen lain

- [CHANGELOG.md](CHANGELOG.md): riwayat perubahan
- [CONTRIBUTING.md](CONTRIBUTING.md): cara berkontribusi dan format commit
- [docs/AUTOMATION.md](docs/AUTOMATION.md): workflow, auto changelog, auto release
- [SECURITY.md](SECURITY.md): melaporkan celah keamanan
- [SUPPORT.md](SUPPORT.md): masalah umum dan cara minta bantuan
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md): kode etik

## Yang perlu diketahui

- **Akun itu lokal.** Login/registrasi tersimpan di perangkatmu (`~/.mining`,
  password di-hash + salt). Tidak ada server, jadi tidak ada "lupa password";
  hapus folder itu untuk reset.
- **Referral itu pencatatan lokal**, bukan program komisi. Tidak ada hadiah otomatis
  dan tidak ada yang mengubah wallet/pool mining siapa pun.
- **Tanpa dev-fee.** Wallet & pool 100% milik kamu. Catatan: xmrig sendiri
  menyumbang 1% ke pengembangnya secara default; atur di `config.sh`
  (`XMRIG_DONATE`, 0 untuk mematikan).
- **Mining di HP umumnya tidak menguntungkan** dan memanaskan baterai/CPU.
  Pengaman suhu otomatis butuh `termux-api` (+ aplikasi Termux:API dari F-Droid).
- Koin bertanda `!` (BTC, LTC, DOGE, dst.) butuh ASIC/GPU, tidak praktis di HP.
- Pool default hanya diisi untuk XMR dan VRSC; alamat pool bisa berubah.

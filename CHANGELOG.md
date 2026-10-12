# Changelog

Semua perubahan penting pada proyek ini dicatat di sini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/)
dan versi mengikuti [Semantic Versioning](https://semver.org/lang/id/).

> Blok **[Unreleased]** dan setiap rilis baru diisi **otomatis** dari pesan commit
> ([Conventional Commits](https://www.conventionalcommits.org/id/)) oleh
> `tools/changelog.sh`. Jangan mengedit isi di antara penanda `<!-- changelog:... -->`.

## [Unreleased]

<!-- changelog:unreleased:start -->

_Rilis pertama belum dibuat. Perubahan akan dicatat setelah tag pertama ada._

<!-- changelog:unreleased:end -->

## [1.0.0] - 2026-10-09

### Added

- Menu utama **MINING** dengan banner, kotak menu, dan splash screen.
- Alur: Mining (Login / Registrasi, lalu pilih koin), List Koin, Wallet, Update, About, dan Referral.
- 30 koin, **satu file per koin** di folder `coins/`.
- Pengaman suhu baterai otomatis (butuh `termux-api`) dan wake-lock saat mining.
- Akun lokal dengan password ber-hash + salt; wallet tersimpan per akun.
- `tools/check-coins.sh`: validator file koin beserta guard isi file.
- `tests/smoke.sh`: smoke test yang menjalankan menu sungguhan dengan miner palsu.
- Otomasi GitHub Actions: CI (sintaks, ShellCheck, validasi koin, smoke test), validasi PR koin,
  cek judul PR (Conventional Commits), label otomatis dan ukuran PR, sapaan kontributor baru,
  stale, markdown lint, dan cek kesehatan pool mingguan.
- **Auto changelog** (`changelog.yml`) dan **auto release** (`auto-release.yml`): versi, `CHANGELOG.md`,
  tag, dan GitHub Release dibuat otomatis dari pesan commit.
- `docs/COINS.md`: daftar koin yang dibuat otomatis dari folder `coins/`.
- Template issue (bug, fitur, koin baru, pool bermasalah) dan template PR (umum dan koin baru).
- Dokumen proyek: `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, `CODE_OF_CONDUCT.md`, `docs/AUTOMATION.md`.

[Unreleased]: https://github.com/djunekz/mining/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/djunekz/mining/releases/tag/v1.0.0

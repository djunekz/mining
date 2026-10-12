## Ringkasan

<!-- Apa yang diubah dan kenapa? Tautkan issue: "Closes #123" -->

## Jenis perubahan

- [ ] Perbaikan bug
- [ ] Fitur baru
- [ ] Koin baru / perubahan koin (untuk koin baru, pakai template: tambahkan `?template=new_coin.md` di URL PR)
- [ ] Dokumentasi
- [ ] CI / tooling
- [ ] Perubahan besar (mengubah perilaku lama)

## Cara menguji

<!-- Langkah yang kamu jalankan, perangkat/Termux yang dipakai. -->

## Checklist

- [ ] Judul PR mengikuti Conventional Commits (contoh `fix(miner): perbaiki thread default`)
- [ ] `bash tests/smoke.sh` lolos
- [ ] `bash tools/check-coins.sh` lolos
- [ ] Tampilan tidak keluar dari kotak 44 kolom (jika mengubah UI)
- [ ] Tidak ada alamat wallet, password, atau data pribadi di perubahan ini
- [ ] Dokumentasi diperbarui bila perlu

<!-- CHANGELOG.md dan rilis dibuat otomatis dari judul/pesan commit; jangan edit manual. -->

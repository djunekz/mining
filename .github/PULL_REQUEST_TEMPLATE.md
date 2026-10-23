## Ringkasan

Jelaskan apa yang berubah dan kenapa.

## Jenis perubahan

- [ ] Perbaikan bug
- [ ] Fitur baru
- [ ] Refactor tanpa perubahan perilaku
- [ ] Dokumentasi
- [ ] Lainnya

## Issue terkait

Closes #

## Cara menguji

Jelaskan langkah yang kamu jalankan dan hasilnya (perangkat, versi Android, versi Termux jika relevan).

## Daftar periksa

- [ ] `python3 -m compileall -q unmineable` lolos
- [ ] `bash -n unmineable.sh` dan `bash -n install.sh` lolos
- [ ] Tidak ada komentar atau docstring pada kode
- [ ] Hanya memakai pustaka standar Python
- [ ] Tampilan diuji di terminal kecil dan besar (jika mengubah UI)
- [ ] Syarat login dan XMRig terdeteksi tidak terlewati
- [ ] Tidak ada alamat dompet, token, atau data pribadi di kode, log, atau tangkapan layar
- [ ] Catatan ditambahkan di `## [Unreleased]` pada `CHANGELOG.md`
- [ ] Dokumentasi (`README.md`) diperbarui jika perilaku berubah

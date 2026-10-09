# Pasang miner & dependensi (khusus Termux)

install_menu() {
  local c m
  while true; do
    ui_head "PASANG MINER"
    ui_row 1 "Dasar"    "termux-api, curl, git"
    ui_row 2 "xmrig"    "RandomX, CryptoNight"
    ui_row 3 "cpuminer" "yespower, scrypt"
    ui_row 4 "ccminer"  "Verus (petunjuk manual)"
    ui_row 5 "Status"   "Cek miner terpasang"
    ui_row 0 "Kembali" "Ke menu sebelumnya"
    ui_bottom
    echo
    ui_ask c "Pilih"
    case "$c" in
      1) _inst pkg install -y termux-api curl git tur-repo ;;
      2) _inst pkg install -y xmrig ;;
      3) _inst pkg install -y cpuminer ;;
      4)
        ui_head "CCMINER (VERUS)"
        ui_text "Tidak ada di repo resmi Termux."
        ui_text "1. Unduh binary ARM ccminer (fork"
        ui_text "   Verus) dari halaman rilisnya."
        ui_text "2. Taruh di \$PREFIX/bin/ccminer"
        ui_text "3. chmod +x \$PREFIX/bin/ccminer"
        ui_text "4. Pasang Termux:API dari F-Droid"
        ui_text "   untuk pembaca suhu baterai."
        ui_bottom
        ui_pause ;;
      5)
        ui_head "STATUS MINER"
        for m in xmrig cpuminer ccminer termux-api:termux-battery-status; do
          if command -v "${m#*:}" >/dev/null 2>&1; then ui_kv "${m%%:*}" "terpasang" "$C_G"; else ui_kv "${m%%:*}" "belum ada" "$C_R"; fi
        done
        ui_bottom
        ui_pause ;;
      0) return ;;
    esac
  done
}

_inst() {
  echo
  if ! command -v pkg >/dev/null 2>&1; then
    ui_err "Perintah 'pkg' tidak ditemukan. Menu ini khusus Termux."
    ui_pause; return
  fi
  ui_info "Memasang..."
  if "$@"; then ui_ok "Selesai."; else ui_err "Pemasangan gagal (cek koneksi / repo)."; fi
  ui_pause
}

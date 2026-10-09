# Pasang miner & dependensi (khusus Termux)

install_menu() {
  while true; do
    ui_banner
    echo "${C_B}== PASANG MINER ==${C_0}"
    echo " 1. Dependensi dasar (termux-api, curl, git, tur-repo)"
    echo " 2. xmrig   (RandomX/CryptoNight, dll)"
    echo " 3. cpuminer (yespower/scrypt/dll)"
    echo " 4. ccminer  (Verus) - petunjuk manual"
    echo " 5. Cek status miner"
    echo " 0. Kembali"
    echo
    read -rp "Pilih: " c || exit 0
    case "$c" in
      1) _inst pkg install -y termux-api curl git tur-repo ;;
      2) _inst pkg install -y xmrig ;;
      3) _inst pkg install -y cpuminer ;;
      4)
        echo
        ui_warn "ccminer tidak ada di repo resmi Termux."
        echo " Unduh binary ARM dari rilis ccminer (fork Verus), taruh di:"
        echo "   \$PREFIX/bin/ccminer  lalu: chmod +x \$PREFIX/bin/ccminer"
        echo " Pasang juga aplikasi Termux:API dari F-Droid untuk pembaca suhu."
        echo; ui_pause ;;
      5)
        echo
        local m
        for m in xmrig cpuminer ccminer termux-battery-status; do
          if command -v "$m" >/dev/null 2>&1; then ui_ok "$m terpasang"; else ui_err "$m belum ada"; fi
        done
        echo; ui_pause ;;
      0) return ;;
    esac
  done
}

_inst() {
  if ! command -v pkg >/dev/null 2>&1; then
    ui_err "Perintah 'pkg' tidak ditemukan. Menu ini khusus Termux."
    ui_pause; return
  fi
  "$@" || ui_err "Pemasangan gagal (cek koneksi / repo)."
  ui_pause
}

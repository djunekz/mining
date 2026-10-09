about_menu() {
  ui_banner
  echo "${C_B}== ABOUT ==${C_0}"
  echo " $APP_NAME v$APP_VERSION"
  echo " Pembuat : $APP_AUTHOR"
  echo " Repo    : $REPO_URL"
  echo
  echo " Launcher menu untuk miner open-source (xmrig, cpuminer,"
  echo " ccminer) di Termux. Wallet & pool sepenuhnya milik Anda."
  echo " Aplikasi ini TIDAK punya dev-fee atau wallet tersembunyi."
  echo
  echo " Akun bersifat LOKAL (di perangkat ini, tanpa server)."
  echo " Data: $DATA_DIR"
  echo
  ui_warn "Mining di HP umumnya tidak menguntungkan, membuat baterai"
  ui_warn "dan CPU panas. Jangan dijalankan sambil mengisi daya di"
  ui_warn "tempat tertutup. Gunakan dengan risiko sendiri."
  echo
  ui_info "Ingin menambah koin? Cukup buat 1 file di folder coins/"
  ui_info "lalu kirim Pull Request. Lihat CONTRIBUTING.md"
  echo
  ui_pause
}

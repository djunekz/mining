about_menu() {
  ui_head "ABOUT"
  ui_kv "Aplikasi" "$APP_NAME v$APP_VERSION" "$C_B"
  ui_kv "Pembuat"  "$APP_AUTHOR" "$C_C"
  ui_kv "Repo"     "github.com/djunekz/mining" "$C_L"
  local tilde="~"; ui_kv "Data"     "${DATA_DIR/#$HOME/$tilde}"
  ui_mid
  ui_text "Launcher untuk miner open-source"
  ui_text "(xmrig, cpuminer, ccminer) di Termux."
  ui_text "Wallet & pool 100% milik kamu."
  ui_text "TANPA dev-fee / wallet tersembunyi." "$C_G"
  ui_blank
  ui_text "Akun bersifat LOKAL (tanpa server)."
  ui_mid
  ui_text "PERINGATAN" "$C_Y"
  ui_text "Mining di HP umumnya tidak untung &" "$C_Y"
  ui_text "membuat baterai/CPU panas. Jangan" "$C_Y"
  ui_text "dijalankan sambil nge-charge di" "$C_Y"
  ui_text "tempat tertutup. Risiko ditanggung" "$C_Y"
  ui_text "pengguna." "$C_Y"
  ui_mid
  ui_text "Tambah koin = 1 file di folder coins/" "$C_C"
  ui_text "Lihat CONTRIBUTING.md" "$C_D"
  ui_bottom
  ui_pause
}

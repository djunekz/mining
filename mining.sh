#!/usr/bin/env bash
# =====================================================
#   MINING - multi-coin miner launcher untuk Termux
#   Jalankan:  bash mining.sh
# =====================================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT

# shellcheck disable=SC1091
source "$ROOT/config.sh"
for m in ui auth coins install miner wallet referral update about; do
  # shellcheck disable=SC1090
  source "$ROOT/lib/$m.sh"
done

main_menu() {
  local c
  while true; do
    ui_banner
    ui_row 1 "Mining"    "Login & mulai mining"
    ui_row 2 "List Koin" "Semua koin tersedia"
    ui_row 3 "Wallet"    "Kelola alamat wallet"
    ui_row 4 "Update"    "Update & pasang miner"
    ui_row 5 "About"     "Info aplikasi"
    ui_row 6 "Referral"  "Kode referral kamu"
    [ -n "$CURRENT_USER" ] && ui_row 7 "Logout" "Keluar dari akun"
    ui_row 0 "Keluar"    "Tutup aplikasi"
    ui_bottom
    echo
    ui_ask c "Pilih menu"
    case "$c" in
      1) menu_mining ;;
      2) coins_menu_list ;;
      3) wallet_menu ;;
      4) update_menu ;;
      5) about_menu ;;
      6) referral_menu ;;
      7) if [ -n "$CURRENT_USER" ]; then auth_logout; ui_ok "Kamu sudah logout."; sleep 1; fi ;;
      0) echo; ui_info "Sampai jumpa! Happy mining."; echo; exit 0 ;;
    esac
  done
}

# Menu 1: Mining -> (login / registrasi) -> pilih koin
menu_mining() {
  if [ -z "$CURRENT_USER" ]; then
    auth_menu || return
  fi
  mining_select_coin
}

auth_init
ui_splash
main_menu

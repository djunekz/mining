#!/usr/bin/env bash
# =====================================================
#  TermuxMiner - menu utama
#  Jalankan: bash mining.sh
# =====================================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT

source "$ROOT/config.sh"
for m in ui auth coins install miner wallet referral update about; do
  source "$ROOT/lib/$m.sh"
done

main_menu() {
  while true; do
    ui_banner
    echo " 1. Mining"
    echo " 2. List Koin"
    echo " 3. Wallet"
    echo " 4. Update"
    echo " 5. About"
    echo " 6. Referral"
    [ -n "$CURRENT_USER" ] && echo " 7. Logout"
    echo " 0. Keluar"
    echo
    read -rp "Pilih menu: " c || exit 0
    case "$c" in
      1) menu_mining ;;
      2) coins_menu_list ;;
      3) wallet_menu ;;
      4) update_menu ;;
      5) about_menu ;;
      6) referral_menu ;;
      7) [ -n "$CURRENT_USER" ] && { auth_logout; ui_ok "Anda sudah logout."; ui_pause; } ;;
      0) echo "Sampai jumpa."; exit 0 ;;
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
main_menu

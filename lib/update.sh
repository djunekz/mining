# Update aplikasi via git + pasang miner

update_menu() {
  while true; do
    ui_banner
    echo "${C_B}== UPDATE ==${C_0}"
    echo " Versi terpasang: $APP_VERSION"
    echo
    echo " 1. Cek & update aplikasi"
    echo " 2. Pasang / cek miner"
    echo " 0. Kembali"
    echo
    read -rp "Pilih: " c || exit 0
    case "$c" in
      1) update_app ;;
      2) install_menu ;;
      0) return ;;
    esac
  done
}

update_app() {
  echo
  if ! command -v git >/dev/null 2>&1; then ui_err "git belum terpasang (menu Pasang miner > 1)."; ui_pause; return; fi
  if [ ! -d "$ROOT/.git" ]; then
    ui_warn "Folder ini bukan hasil git clone, jadi tidak bisa di-update otomatis."
    echo " Pasang ulang dengan:  git clone $REPO_URL"
    ui_pause; return
  fi
  ui_info "Memeriksa pembaruan..."
  if ! git -C "$ROOT" fetch --quiet 2>/dev/null; then ui_err "Gagal terhubung ke repo."; ui_pause; return; fi
  local behind
  behind="$(git -C "$ROOT" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)"
  if [ "${behind:-0}" -eq 0 ]; then
    ui_ok "Sudah versi terbaru."; ui_pause; return
  fi
  ui_warn "Ada $behind pembaruan:"
  git -C "$ROOT" log --oneline 'HEAD..@{u}' | head -10
  echo
  if ui_confirm "Update sekarang?"; then
    if git -C "$ROOT" pull --ff-only; then
      ui_ok "Update selesai. Memulai ulang aplikasi..."
      sleep 1
      exec bash "$ROOT/mining.sh"
    else
      ui_err "Update gagal (ada perubahan lokal?)."
    fi
  fi
  ui_pause
}

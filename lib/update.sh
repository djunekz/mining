# Update aplikasi via git + pasang miner

update_menu() {
  local c
  while true; do
    ui_head "UPDATE"
    ui_kv "Versi" "$APP_VERSION" "$C_G"
    ui_mid
    ui_row 1 "Update" "Cek & tarik pembaruan"
    ui_row 2 "Miner"  "Pasang / cek miner"
    ui_row 0 "Kembali" "Ke menu utama"
    ui_bottom
    echo
    ui_ask c "Pilih"
    case "$c" in
      1) update_app ;;
      2) install_menu ;;
      0) return ;;
    esac
  done
}

update_app() {
  echo
  if ! command -v git >/dev/null 2>&1; then ui_err "git belum terpasang (Update > Miner > Dasar)."; ui_pause; return; fi
  if [ ! -d "$ROOT/.git" ]; then
    ui_warn "Folder ini bukan hasil git clone, tidak bisa di-update otomatis."
    ui_info "Pasang ulang:  git clone $REPO_URL"
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
  git -C "$ROOT" log --oneline 'HEAD..@{u}' | head -10 | sed 's/^/    /'
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

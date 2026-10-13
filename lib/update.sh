# Update aplikasi via git + pasang miner
#
# "Perlu update" dinilai dari DUA hal:
#   1. versi di file VERSION < rilis (tag vX.Y.Z) terbaru di GitHub, atau
#   2. ada commit baru di branch remote.
# Perubahan lokal pada file yang dilacak git (mis. VERSION yang diubah manual)
# disimpan sementara dengan "git stash" sebelum update, bukan dibuang.

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

_g() { git -C "$ROOT" "$@"; }

# true jika versi $1 lebih lama dari $2 (keduanya X.Y.Z)
_ver_lt() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

# Tarik perubahan; tanpa upstream, pakai branch yang sedang aktif
_upd_pull() {
  if _g rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    _g pull --ff-only --quiet
  else
    _g pull --ff-only --quiet origin "$(_g symbolic-ref --short HEAD 2>/dev/null || echo main)"
  fi
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
  local tags latest cur behind="?" dirty need=0 stashed=0 reason=""
  if ! tags="$(_g ls-remote --tags --refs origin 'refs/tags/v*' 2>/dev/null)"; then
    ui_err "Gagal terhubung ke repo."; ui_pause; return
  fi
  _g fetch --quiet --tags 2>/dev/null || { ui_err "Gagal mengambil data dari repo."; ui_pause; return; }

  latest="$(printf '%s\n' "$tags" | sed -E 's|.*refs/tags/v||' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)"
  cur="$APP_VERSION"; [[ "$cur" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || cur="0.0.0"
  if _g rev-parse --verify -q '@{u}' >/dev/null 2>&1; then
    behind="$(_g rev-list --count 'HEAD..@{u}' 2>/dev/null || echo "?")"
  fi
  dirty="$(_g status --porcelain --untracked-files=no 2>/dev/null)"

  # ---- ringkasan ----
  ui_head "CEK UPDATE"
  ui_kv "Terpasang" "v$APP_VERSION" "$C_C"
  if [ -n "$latest" ]; then ui_kv "Terbaru" "v$latest" "$C_G"; else ui_kv "Terbaru" "(belum ada rilis)" "$C_D"; fi
  if [ "$behind" = "?" ]; then ui_kv "Commit" "tidak diketahui" "$C_D"; else ui_kv "Commit" "$behind baru"; fi
  if [ -n "$dirty" ]; then ui_kv "Lokal" "$(printf '%s\n' "$dirty" | wc -l | tr -d ' ') file diubah" "$C_Y"; else ui_kv "Lokal" "bersih" "$C_D"; fi
  ui_bottom
  echo

  # ---- putusan ----
  if [ -n "$latest" ] && _ver_lt "$cur" "$latest"; then
    need=1; reason="Versimu (v$APP_VERSION) lebih lama dari rilis v$latest."
  fi
  if [[ "$behind" =~ ^[0-9]+$ ]] && [ "$behind" -gt 0 ]; then
    need=1; reason="${reason:-Ada $behind commit baru di repo.}"
  fi

  if [ "$need" -eq 0 ]; then
    if [ -n "$latest" ] && _ver_lt "$latest" "$cur"; then
      ui_info "Versimu (v$APP_VERSION) lebih baru dari rilis terakhir (v$latest)."
    else
      ui_ok "Sudah versi terbaru."
    fi
    if [ -n "$dirty" ]; then
      ui_warn "Ada perubahan lokal pada file yang dilacak git:"
      printf '%s\n' "$dirty" | head -8 | sed 's/^/    /'
    fi
    ui_pause; return
  fi

  ui_warn "$reason"
  if [[ "$behind" =~ ^[0-9]+$ ]] && [ "$behind" -gt 0 ]; then
    _g log --oneline 'HEAD..@{u}' | head -10 | sed 's/^/    /'
  fi
  if [ -n "$dirty" ]; then
    ui_warn "Perubahan lokal ini akan disimpan sementara (git stash):"
    printf '%s\n' "$dirty" | head -8 | sed 's/^/    /'
  fi
  echo
  ui_confirm "Update sekarang?" || { ui_pause; return; }

  if [ -n "$dirty" ]; then
    if _g -c user.name=mining -c user.email=mining@localhost stash push --quiet -m "mining-update $(date +%F-%H%M%S)"; then
      stashed=1
    else
      ui_err "Gagal menyimpan perubahan lokal (git stash). Update dibatalkan."; ui_pause; return
    fi
  fi

  if [[ "$behind" =~ ^[0-9]+$ ]] && [ "$behind" -eq 0 ]; then
    :                                  # tidak ada commit baru; stash saja sudah mengembalikan file ke versi repo
  elif ! _upd_pull; then
    if [ "$stashed" -eq 1 ]; then _g stash pop --quiet 2>/dev/null; fi
    ui_err "Update gagal (cabang lokal menyimpang dari repo?)."; ui_pause; return
  fi

  [ "$stashed" -eq 1 ] && ui_info "Perubahan lokalmu aman di stash. Lihat: git stash list   Pulihkan: git stash pop"

  local newver; newver="$(tr -d '[:space:]' < "$ROOT/VERSION" 2>/dev/null)"
  if [ -n "$latest" ] && [[ "$newver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && _ver_lt "$newver" "$latest"; then
    ui_warn "VERSION di repo (v$newver) masih lebih lama dari tag v$latest."
    ui_warn "Commit rilis mungkin belum masuk ke branch ini; coba lagi nanti."
  fi
  ui_ok "Update selesai. Memulai ulang aplikasi..."
  sleep 1
  exec bash "$ROOT/mining.sh"
}

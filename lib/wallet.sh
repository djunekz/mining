# Wallet per-akun: $DATA_DIR/wallets/<user>.conf  (baris: SYMBOL=alamat)

_wallet_file() { echo "$DATA_DIR/wallets/$CURRENT_USER.conf"; }

wallet_valid() { [[ "$1" =~ ^[A-Za-z0-9._:@-]{10,200}$ ]]; }

wallet_get() {
  local f; f="$(_wallet_file)"
  [ -f "$f" ] && grep -m1 "^$1=" "$f" | cut -d= -f2-
}

wallet_set() {
  local f; f="$(_wallet_file)"
  touch "$f"; chmod 600 "$f" 2>/dev/null
  grep -v "^$1=" "$f" > "$f.tmp"
  echo "$1=$2" >> "$f.tmp"
  mv "$f.tmp" "$f"; chmod 600 "$f" 2>/dev/null
}

wallet_del() {
  local f; f="$(_wallet_file)"
  [ -f "$f" ] || return
  grep -v "^$1=" "$f" > "$f.tmp"; mv "$f.tmp" "$f"
}

wallet_symbol_exists() { coins_scan | cut -d'|' -f1 | grep -qx "$1"; }

wallet_menu() {
  require_login || return
  local c
  while true; do
    ui_head "WALLET"
    ui_row 1 "Lihat"   "Wallet tersimpan"
    ui_row 2 "Tambah"  "Tambah / ubah wallet"
    ui_row 3 "Hapus"   "Hapus wallet"
    ui_row 0 "Kembali" "Ke menu utama"
    ui_bottom
    echo
    ui_ask c "Pilih"
    case "$c" in
      1)
        local f k v
        f="$(_wallet_file)"
        ui_head "WALLET TERSIMPAN"
        if [ -s "$f" ]; then
          while IFS='=' read -r k v; do
            [ -n "$k" ] && ui_kv "$k" "$(ui_short "$v")" "$C_G"
          done < "$f"
        else
          ui_text "Belum ada wallet tersimpan." "$C_Y"
        fi
        ui_bottom
        ui_pause ;;
      2)
        local s a
        echo
        ui_ask s "Kode koin (contoh XMR)"; s="${s^^}"
        if ! wallet_symbol_exists "$s"; then ui_err "Koin $s tidak ada (lihat menu List Koin)."; ui_pause; continue; fi
        ui_ask a "Alamat wallet $s"
        if wallet_valid "$a"; then wallet_set "$s" "$a"; ui_ok "Wallet $s disimpan."; else ui_err "Alamat tidak valid."; fi
        ui_pause ;;
      3)
        local s
        echo
        ui_ask s "Kode koin yang dihapus"; s="${s^^}"
        if [[ "$s" =~ ^[A-Z0-9]{1,10}$ ]]; then wallet_del "$s"; ui_ok "Dihapus (jika ada)."; fi
        ui_pause ;;
      0) return ;;
    esac
  done
}

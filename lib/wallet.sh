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
  while true; do
    ui_banner
    echo "${C_B}== WALLET ==${C_0}"
    echo " 1. Lihat wallet tersimpan"
    echo " 2. Tambah / ubah wallet"
    echo " 3. Hapus wallet"
    echo " 0. Kembali"
    echo
    read -rp "Pilih: " c || exit 0
    case "$c" in
      1)
        local f; f="$(_wallet_file)"
        echo
        if [ -s "$f" ]; then sed 's/=/  ->  /' "$f"; else ui_warn "Belum ada wallet tersimpan."; fi
        echo; ui_pause ;;
      2)
        local s a
        read -rp "Kode koin (contoh XMR): " s; s="${s^^}"
        if ! wallet_symbol_exists "$s"; then ui_err "Koin $s tidak ada (cek menu List Koin)."; ui_pause; continue; fi
        read -rp "Alamat wallet $s: " a
        if wallet_valid "$a"; then wallet_set "$s" "$a"; ui_ok "Wallet $s disimpan."; else ui_err "Alamat tidak valid."; fi
        ui_pause ;;
      3)
        local s
        read -rp "Kode koin yang dihapus: " s; s="${s^^}"
        if [[ "$s" =~ ^[A-Z0-9]{1,10}$ ]]; then wallet_del "$s"; ui_ok "Dihapus (jika ada)."; fi
        ui_pause ;;
      0) return ;;
    esac
  done
}

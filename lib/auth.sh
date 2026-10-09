# Akun LOKAL (disimpan di perangkat ini saja, tidak ada server).
# Format $USERS_DB:  username:salt:sha256(salt+password):refcode:referred_by:tanggal
USERS_DB="$DATA_DIR/users.db"
CURRENT_USER=""

auth_init() {
  mkdir -p "$DATA_DIR/wallets"
  chmod 700 "$DATA_DIR" 2>/dev/null
  touch "$USERS_DB"
  chmod 600 "$USERS_DB" 2>/dev/null
}

_auth_hash()    { printf '%s%s' "$1" "$2" | sha256sum | cut -d' ' -f1; }
_auth_salt()    { od -An -N8 -tx1 /dev/urandom | tr -d ' \n'; }
_auth_line()    { grep -m1 "^$1:" "$USERS_DB"; }          # username sudah divalidasi
auth_refcode()  { printf 'ref:%s' "$1" | sha256sum | cut -c1-6 | tr 'a-f' 'A-F'; }

# Cari username dari kode referral (kosong jika tidak ada)
auth_user_by_refcode() {
  awk -F: -v c="$1" '$4==c {print $1; exit}' "$USERS_DB"
}

auth_register() {
  ui_head "REGISTRASI"
  ui_text "Username: 3-20 huruf/angka/_" "$C_D"
  ui_text "Password: minimal 6 karakter" "$C_D"
  ui_bottom
  echo
  local u p1 p2 ref refby="-" salt
  ui_ask u "Username"
  if ! [[ "$u" =~ ^[A-Za-z0-9_]{3,20}$ ]]; then ui_err "Username tidak valid."; ui_pause; return 1; fi
  if [ -n "$(_auth_line "$u")" ]; then ui_err "Username sudah dipakai."; ui_pause; return 1; fi
  ui_ask_secret p1 "Password"
  ui_ask_secret p2 "Ulangi password"
  if [ "${#p1}" -lt 6 ]; then ui_err "Password terlalu pendek."; ui_pause; return 1; fi
  if [ "$p1" != "$p2" ]; then ui_err "Password tidak sama."; ui_pause; return 1; fi
  ui_ask ref "Kode referral (opsional)"
  if [ -n "$ref" ]; then
    ref="${ref^^}"
    refby="$(auth_user_by_refcode "$ref")"
    if [ -z "$refby" ]; then ui_warn "Kode referral tidak ditemukan di perangkat ini, dilewati."; refby="-"; fi
  fi
  salt="$(_auth_salt)"
  echo "$u:$salt:$(_auth_hash "$salt" "$p1"):$(auth_refcode "$u"):$refby:$(date +%F)" >> "$USERS_DB"
  CURRENT_USER="$u"
  echo
  ui_ok "Registrasi berhasil. Kamu login sebagai $u."
  ui_pause
  return 0
}

auth_login() {
  ui_head "LOGIN"
  ui_bottom
  echo
  local u p line salt hash tries=0
  ui_ask u "Username"
  [[ "$u" =~ ^[A-Za-z0-9_]{3,20}$ ]] || { ui_err "Username/password salah."; ui_pause; return 1; }
  line="$(_auth_line "$u")"
  while [ $tries -lt 3 ]; do
    ui_ask_secret p "Password"
    if [ -n "$line" ]; then
      salt="$(echo "$line" | cut -d: -f2)"
      hash="$(echo "$line" | cut -d: -f3)"
      if [ "$(_auth_hash "$salt" "$p")" = "$hash" ]; then
        CURRENT_USER="$u"
        echo
        ui_ok "Login berhasil. Selamat datang, $u!"
        ui_pause
        return 0
      fi
    fi
    tries=$((tries+1))
    ui_err "Username/password salah ($tries/3)."
  done
  ui_pause
  return 1
}

auth_logout() { CURRENT_USER=""; }

# Menu login/registrasi. Return 0 kalau berakhir dalam keadaan login.
auth_menu() {
  local c
  while [ -z "$CURRENT_USER" ]; do
    ui_head "AKSES AKUN"
    ui_row 1 "Login"      "Masuk ke akun kamu"
    ui_row 2 "Registrasi" "Buat akun baru"
    ui_row 0 "Kembali"    "Ke menu utama"
    ui_bottom
    echo
    ui_ask c "Pilih"
    case "$c" in
      1) auth_login ;;
      2) auth_register ;;
      0) return 1 ;;
    esac
  done
  return 0
}

# Dipakai menu yang butuh akun (wallet, referral)
require_login() {
  [ -n "$CURRENT_USER" ] && return 0
  auth_menu
}

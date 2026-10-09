# Referral LOKAL. Tidak ada server, jadi tidak ada hadiah/komisi otomatis dan
# tidak ada pengalihan hasil mining. Fungsinya: kode untuk dibagikan + statistik
# berapa akun di perangkat ini yang mendaftar dengan kode kamu.

referral_menu() {
  require_login || return
  local code count
  code="$(auth_refcode "$CURRENT_USER")"
  count="$(awk -F: -v u="$CURRENT_USER" '$5==u' "$USERS_DB" | wc -l)"
  ui_head "REFERRAL"
  ui_kv "Akun"      "$CURRENT_USER"
  ui_kv "Kode"      "$code" "$C_B$C_G"
  ui_kv "Dipakai"   "$count akun (di perangkat ini)" "$C_C"
  ui_mid
  ui_text "Teks untuk dibagikan:" "$C_D"
  ui_blank
  ui_text "Mining coin di Termux pakai MINING!"
  ui_text "github.com/djunekz/mining" "$C_L"
  ui_text "Kode referral saya: $code" "$C_G"
  ui_mid
  ui_text "Kode diisi saat Registrasi. Referral" "$C_D"
  ui_text "hanya pencatatan lokal; tidak mengubah" "$C_D"
  ui_text "wallet/pool mining siapa pun." "$C_D"
  ui_bottom
  ui_pause
}

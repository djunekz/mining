# Referral LOKAL. Tidak ada server, jadi tidak ada hadiah/komisi otomatis dan
# tidak ada pengalihan hasil mining. Fungsinya: kode untuk dibagikan + statistik
# berapa akun di perangkat ini yang mendaftar dengan kode Anda.

referral_menu() {
  require_login || return
  ui_banner
  echo "${C_B}== REFERRAL ==${C_0}"
  local code count
  code="$(auth_refcode "$CURRENT_USER")"
  count="$(awk -F: -v u="$CURRENT_USER" '$5==u' "$USERS_DB" | wc -l)"
  echo " Kode referral Anda : ${C_C}${C_B}$code${C_0}"
  echo " Akun yang memakai kode Anda (di perangkat ini): $count"
  echo
  echo " Teks untuk dibagikan:"
  echo "   Mining coin di Termux pakai $APP_NAME!"
  echo "   $REPO_URL"
  echo "   Kode referral saya: $code"
  echo
  ui_info "Kode diisi saat Registrasi. Referral hanya pencatatan lokal;"
  ui_info "tidak mengubah wallet/pool mining siapa pun."
  echo
  ui_pause
}

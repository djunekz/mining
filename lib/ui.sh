# Helper tampilan
C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_C=$'\e[36m'; C_B=$'\e[1m'; C_0=$'\e[0m'

ui_banner() {
  clear
  echo "${C_G}${C_B}=========================================${C_0}"
  echo "${C_G}${C_B}   $APP_NAME  v$APP_VERSION${C_0}"
  echo "${C_G}${C_B}=========================================${C_0}"
  if [ -n "$CURRENT_USER" ]; then
    echo " Login sebagai: ${C_C}$CURRENT_USER${C_0}"
  else
    echo " ${C_Y}(belum login)${C_0}"
  fi
  echo
}

ui_ok()   { echo "${C_G}[+] $*${C_0}"; }
ui_err()  { echo "${C_R}[!] $*${C_0}"; }
ui_warn() { echo "${C_Y}[*] $*${C_0}"; }
ui_info() { echo "${C_C}[i] $*${C_0}"; }

ui_pause() { read -rp "Tekan Enter untuk lanjut..." _; }

# ui_confirm "Pertanyaan?"  -> return 0 jika y/Y
ui_confirm() {
  local a
  read -rp "$1 (y/N): " a
  [[ "$a" =~ ^[Yy]$ ]]
}

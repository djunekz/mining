# =====================================================
#  MINING - library tampilan
#  Lebar kotak = UI_W (42 kolom) agar muat di layar HP.
#  Teks di dalam kotak sebaiknya ASCII supaya rata.
# =====================================================
UI_W=42

# Warna (256-color, didukung Termux)
C_G=$'\e[38;5;82m';  C_Y=$'\e[38;5;220m'; C_R=$'\e[38;5;203m'
C_C=$'\e[38;5;51m';  C_L=$'\e[38;5;39m';  C_D=$'\e[38;5;245m'
C_M=$'\e[38;5;141m'; C_B=$'\e[1m';        C_0=$'\e[0m'

UI_HR=""
for ((_i=0; _i<UI_W; _i++)); do UI_HR+="─"; done
unset _i

# ---------- kotak ----------
ui_top()    { printf '%s╭%s╮%s\n' "$C_L" "$UI_HR" "$C_0"; }
ui_mid()    { printf '%s├%s┤%s\n' "$C_L" "$UI_HR" "$C_0"; }
ui_bottom() { printf '%s╰%s╯%s\n' "$C_L" "$UI_HR" "$C_0"; }

# Judul di tengah kotak
ui_title() {
  local t="${1:0:$UI_W}" l r
  l=$(( (UI_W - ${#t}) / 2 )); r=$(( UI_W - ${#t} - l ))
  printf '%s│%s%*s%s%s%s%s%*s%s│%s\n' "$C_L" "$C_0" "$l" "" "$C_B$C_Y" "$t" "$C_0" "" "$r" "" "$C_L" "$C_0"
}

# Baris menu:  [n] Label       Deskripsi
ui_row() {
  printf '%s│%s %s[%s]%s %s%-11s%s %s%-24s%s %s│%s\n' \
    "$C_L" "$C_0" "$C_C$C_B" "$1" "$C_0" "$C_B" "${2:0:11}" "$C_0" "$C_D" "${3:0:24}" "$C_0" "$C_L" "$C_0"
}

# Baris "kunci : nilai"
ui_kv() {
  printf '%s│%s %s%-9s%s %s%-30s%s %s│%s\n' \
    "$C_L" "$C_0" "$C_D" "${1:0:9}" "$C_0" "${3:-$C_0}" "${2:0:30}" "$C_0" "$C_L" "$C_0"
}

# Baris teks biasa (maks 40 karakter)
ui_text() {
  printf '%s│%s %s%-40s%s %s│%s\n' "$C_L" "$C_0" "${2:-$C_0}" "${1:0:40}" "$C_0" "$C_L" "$C_0"
}
ui_blank() { ui_text ""; }

# ---------- banner ----------
ui_art() {
  # Huruf blok 5 baris, lebar 40 kolom, di-center terhadap kotak (44 kolom)
  local -a g=(51 45 39 33 27)
  local -a M=("█   █" "██ ██" "█ █ █" "█   █" "█   █")
  local -a I=("█████" "  █  " "  █  " "  █  " "█████")
  local -a N=("█   █" "██  █" "█ █ █" "█  ██" "█   █")
  local -a G=(" ████" "█    " "█  ██" "█   █" " ████")
  local i line pad=$(( (UI_W + 2 - 40) / 2 ))
  for i in 0 1 2 3 4; do
    line="${M[$i]}  ${I[$i]}  ${N[$i]}  ${I[$i]}  ${N[$i]}  ${G[$i]}"
    printf '%*s\e[1m\e[38;5;%sm%s%s\n' "$pad" "" "${g[$i]}" "$line" "$C_0"
    [ "$1" = "slow" ] && sleep 0.07
  done
}

_ui_center() {
  local t="$1" col="${2:-$C_D}" pad
  pad=$(( (UI_W + 2 - ${#t}) / 2 )); [ "$pad" -lt 0 ] && pad=0
  printf '%*s%s%s%s\n' "$pad" "" "$col" "$t" "$C_0"
}

_ui_count_coins() { local f=("$ROOT"/coins/*.sh); [ -e "${f[0]}" ] && echo "${#f[@]}" || echo 0; }

# Banner penuh (menu utama)
ui_banner() {
  clear
  echo
  ui_art "$1"
  _ui_center "M U L T I - C O I N   M I N E R" "$C_M"
  _ui_center "Termux  |  v$APP_VERSION  |  by $APP_AUTHOR" "$C_D"
  echo
  ui_top
  if [ -n "$CURRENT_USER" ]; then
    ui_kv "Akun" "$CURRENT_USER" "$C_G"
  else
    ui_kv "Akun" "belum login" "$C_Y"
  fi
  ui_kv "Koin" "$(_ui_count_coins) tersedia" "$C_C"
  ui_mid
}

# Header ringkas (sub-menu): ui_head "JUDUL"  -> kotak terbuka, tutup dengan ui_bottom
ui_head() {
  clear
  printf '\n  %s%sMINING%s %s%s%s' "$C_B" "$C_C" "$C_0" "$C_D" "v$APP_VERSION" "$C_0"
  [ -n "$CURRENT_USER" ] && printf '  %s[ %s ]%s' "$C_G" "$CURRENT_USER" "$C_0"
  printf '\n\n'
  ui_top
  ui_title "$1"
  ui_mid
}

# Splash saat pertama dibuka (hanya di terminal interaktif)
ui_splash() {
  [ -t 1 ] || return 0
  clear; echo
  ui_art slow
  _ui_center "M U L T I - C O I N   M I N E R" "$C_M"
  echo
  printf '   %sMemuat modul %s' "$C_D" "$C_0"
  local i
  for ((i=0; i<24; i++)); do printf '%s▰%s' "$C_C" "$C_0"; sleep 0.025; done
  printf ' %ssiap%s\n' "$C_G" "$C_0"
  sleep 0.3
}

# ---------- pesan ----------
ui_ok()   { printf '  %s✔ %s%s\n' "$C_G" "$*" "$C_0"; }
ui_err()  { printf '  %s✖ %s%s\n' "$C_R" "$*" "$C_0"; }
ui_warn() { printf '  %s! %s%s\n' "$C_Y" "$*" "$C_0"; }
ui_info() { printf '  %s• %s%s\n' "$C_C" "$*" "$C_0"; }

# ---------- input ----------
# ui_ask VAR "Label" [default]
ui_ask() {
  local _p="  ${C_D}$2${3:+ [$3]} ${C_C}❯${C_0} "
  IFS= read -r -p "$_p" "$1" || exit 0
  if [ -z "${!1}" ] && [ -n "$3" ]; then printf -v "$1" '%s' "$3"; fi
}

# ui_ask_secret VAR "Label"
ui_ask_secret() {
  IFS= read -rs -p "  ${C_D}$2 ${C_C}❯${C_0} " "$1" || exit 0
  echo
}

ui_pause() {
  local _
  printf '\n  %sTekan Enter untuk lanjut...%s' "$C_D" "$C_0"
  IFS= read -rs _ || exit 0
  echo
}

# ui_confirm "Pertanyaan?" -> return 0 jika y/Y
ui_confirm() {
  local a
  IFS= read -r -p "  ${C_Y}$1${C_0} ${C_D}(y/N)${C_0} ${C_C}❯${C_0} " a || exit 0
  [[ "$a" =~ ^[Yy]$ ]]
}

# 49gYsExample...abc123  (untuk menampilkan alamat panjang)
ui_short() {
  local a="$1"
  if [ "${#a}" -gt 28 ]; then printf '%s...%s' "${a:0:14}" "${a: -9}"; else printf '%s' "$a"; fi
}

# Durasi detik -> HH:MM:SS
ui_dur() { printf '%02d:%02d:%02d' $(($1/3600)) $(($1%3600/60)) $(($1%60)); }

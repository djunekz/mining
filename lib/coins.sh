# Loader koin: setiap file coins/*.sh = satu koin.
# Menambah koin = menambah satu file di folder coins/ (lihat coins/_TEMPLATE.sh.example).

# Cetak satu baris per koin:
# SYMBOL|NAME|ALGO|MINER|POOL|NOTE|PRACTICAL|FILE
coins_scan() {
  local f
  for f in "$ROOT"/coins/*.sh; do
    [ -f "$f" ] || continue
    (
      COIN_SYMBOL=""; COIN_NAME=""; COIN_ALGO=""; COIN_MINER="none"
      COIN_POOL_DEFAULT=""; COIN_NOTE=""; COIN_PRACTICAL="yes"
      # shellcheck disable=SC1090
      source "$f" >/dev/null 2>&1 || exit 0
      [ -n "$COIN_SYMBOL" ] || exit 0
      printf '%s|%s|%s|%s|%s|%s|%s|%s\n' "$COIN_SYMBOL" "$COIN_NAME" "$COIN_ALGO" \
        "$COIN_MINER" "$COIN_POOL_DEFAULT" "$COIN_NOTE" "$COIN_PRACTICAL" "$f"
    )
  done | sort -t'|' -k1,1
}

# Muat satu file koin ke shell saat ini
coin_load() {
  COIN_SYMBOL=""; COIN_NAME=""; COIN_ALGO=""; COIN_MINER="none"
  COIN_POOL_DEFAULT=""; COIN_NOTE=""; COIN_PRACTICAL="yes"
  unset -f coin_cmd 2>/dev/null
  # shellcheck disable=SC1090
  source "$1"
}

# Satu baris tabel koin:  No  KODE  Nama  Algoritma  [!]
_coin_row() {
  local n="$1" sym="$2" name="$3" algo="$4" prac="$5" flag=" " fc="$C_0"
  [ "$prac" = "no" ] && { flag="!"; fc="$C_Y"; }
  printf '%s│%s %s%2s%s  %s%-5s%s %-14s %s%-13s%s %s%s%s %s│%s\n' \
    "$C_L" "$C_0" "$C_C" "$n" "$C_0" "$C_B" "${sym:0:5}" "$C_0" "${name:0:14}" \
    "$C_D" "${algo:0:13}" "$C_0" "$fc" "$flag" "$C_0" "$C_L" "$C_0"
}

_coin_table_head() {
  printf '%s│%s %s%2s  %-5s %-14s %-13s   %s%s│%s\n' "$C_L" "$C_0" "$C_D" "No" "Kode" "Nama" "Algoritma" "$C_0" "$C_L" "$C_0"
  ui_mid
}

coins_menu_list() {
  ui_head "DAFTAR KOIN"
  _coin_table_head
  local n=0 sym name algo miner pool note prac file
  while IFS='|' read -r sym name algo miner pool note prac file; do
    n=$((n+1))
    _coin_row "$n" "$sym" "$name" "$algo" "$prac"
  done < <(coins_scan)
  ui_mid
  ui_kv "Total" "$n koin" "$C_G"
  ui_text "! = tidak praktis di HP (butuh ASIC/GPU)" "$C_Y"
  ui_bottom
  echo
  ui_info "Tambah koin: buat 1 file di folder coins/"
  ui_pause
}

# Menu pilih koin untuk mining
mining_select_coin() {
  local c
  while true; do
    ui_head "PILIH KOIN"
    _coin_table_head
    local -a rows=()
    local line i=0 sym name algo miner pool note prac file
    mapfile -t rows < <(coins_scan)
    for line in "${rows[@]}"; do
      IFS='|' read -r sym name algo miner pool note prac file <<<"$line"
      i=$((i+1))
      _coin_row "$i" "$sym" "$name" "$algo" "$prac"
    done
    ui_mid
    ui_row 0 "Kembali" "Ke menu utama"
    ui_bottom
    echo
    ui_ask c "Pilih nomor koin"
    [ "$c" = "0" ] && return
    if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le "${#rows[@]}" ]; then
      IFS='|' read -r sym name algo miner pool note prac file <<<"${rows[$((c-1))]}"
      coin_load "$file"
      miner_start
    fi
  done
}

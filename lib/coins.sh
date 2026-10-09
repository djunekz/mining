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

coins_menu_list() {
  ui_banner
  echo "${C_B}== DAFTAR KOIN ==${C_0}"
  local n=0 line sym name algo miner pool note prac file
  printf "%3s %-6s %-18s %-16s %-9s %s\n" "No" "Kode" "Nama" "Algoritma" "Miner" "Keterangan"
  echo "---------------------------------------------------------------------"
  while IFS='|' read -r sym name algo miner pool note prac file; do
    n=$((n+1))
    local tag=""
    [ "$prac" = "no" ] && tag="${C_Y}[tdk praktis]${C_0} "
    printf "%3s %-6s %-18s %-16s %-9s %s%s\n" "$n" "$sym" "$name" "$algo" "$miner" "$tag" "$note"
  done < <(coins_scan)
  echo
  ui_info "Total: $n koin. Tambah koin = tambah file di folder coins/."
  ui_pause
}

# Menu pilih koin untuk mining
mining_select_coin() {
  while true; do
    ui_banner
    echo "${C_B}== PILIH KOIN UNTUK MINING ==${C_0}"
    local -a rows=()
    local line i=0 sym name algo miner pool note prac file
    mapfile -t rows < <(coins_scan)
    for line in "${rows[@]}"; do
      IFS='|' read -r sym name algo miner pool note prac file <<<"$line"
      i=$((i+1))
      local tag=""
      [ "$prac" = "no" ] && tag="${C_Y}[tdk praktis]${C_0}"
      printf "%3s. %-6s %-18s %-14s %s\n" "$i" "$sym" "$name" "$algo" "$tag"
    done
    echo "  0. Kembali"
    echo
    read -rp "Pilih koin: " c || exit 0
    [ "$c" = "0" ] && return
    if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le "${#rows[@]}" ]; then
      IFS='|' read -r sym name algo miner pool note prac file <<<"${rows[$((c-1))]}"
      coin_load "$file"
      miner_start
    fi
  done
}

# Menjalankan miner untuk koin yang sudah di-load (variabel COIN_*)

miner_temp() {
  termux-battery-status 2>/dev/null | grep -o '"temperature": *[0-9.]*' | grep -o '[0-9.]*$' | cut -d. -f1
}

# Susun perintah ke array CMD. Koin boleh menimpa dengan fungsi coin_cmd()
# (variabel tersedia: POOL WALLET WORKER THREADS COIN_ALGO).
miner_build_cmd() {
  if declare -F coin_cmd >/dev/null; then
    coin_cmd
    return
  fi
  case "$COIN_MINER" in
    xmrig)
      CMD=(xmrig -o "$POOL" -u "$WALLET" -p "$WORKER" -a "$COIN_ALGO" -t "$THREADS" -k --donate-level "$XMRIG_DONATE") ;;
    ccminer)
      CMD=(ccminer -a "$COIN_ALGO" -o "stratum+tcp://$POOL" -u "$WALLET.$WORKER" -p x -t "$THREADS") ;;
    cpuminer)
      CMD=(cpuminer -a "$COIN_ALGO" -o "stratum+tcp://$POOL" -u "$WALLET.$WORKER" -p x -t "$THREADS") ;;
    *) return 1 ;;
  esac
}

miner_run() {
  local maxtemp="$1" guard="$2"; shift 2
  command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock
  "$@" &
  local pid=$! n=0 t
  trap 'kill "$pid" 2>/dev/null' INT TERM
  while kill -0 "$pid" 2>/dev/null; do
    sleep 1; n=$((n+1))
    if [ "$guard" = 1 ] && [ $((n % 30)) -eq 0 ]; then
      t="$(miner_temp)"
      if [[ "$t" =~ ^[0-9]+$ ]] && [ "$t" -ge "$maxtemp" ]; then
        ui_err "Suhu baterai ${t}C >= ${maxtemp}C. Mining dihentikan demi keamanan."
        kill "$pid" 2>/dev/null
      fi
    fi
  done
  wait "$pid" 2>/dev/null
  trap - INT TERM
  command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock
}

miner_start() {
  ui_head "MINING $COIN_SYMBOL"
  ui_kv "Koin"      "$COIN_NAME" "$C_B"
  ui_kv "Algoritma" "$COIN_ALGO"
  ui_kv "Miner"     "$COIN_MINER"
  [ -n "$COIN_NOTE" ] && ui_kv "Catatan" "$COIN_NOTE" "$C_D"
  ui_bottom
  echo

  if [ "$COIN_PRACTICAL" = "no" ]; then
    ui_warn "Koin ini tidak praktis ditambang di HP (butuh ASIC/GPU)."
    ui_confirm "Tetap lanjut?" || return
  fi
  if [ "$COIN_MINER" = "none" ]; then
    ui_err "Belum ada miner yang didukung untuk koin ini."; ui_pause; return
  fi
  if ! command -v "$COIN_MINER" >/dev/null 2>&1; then
    ui_err "$COIN_MINER belum terpasang. Pasang lewat menu Update > Miner."
    ui_pause; return
  fi

  # --- wallet ---
  WALLET="$(wallet_get "$COIN_SYMBOL")"
  if [ -z "$WALLET" ]; then
    ui_ask WALLET "Alamat wallet $COIN_SYMBOL"
    if ! wallet_valid "$WALLET"; then ui_err "Alamat tidak valid."; ui_pause; return; fi
    wallet_set "$COIN_SYMBOL" "$WALLET"
    ui_ok "Wallet disimpan."
  else
    ui_info "Wallet: $(ui_short "$WALLET")  (ubah di menu Wallet)"
  fi

  # --- pool ---
  local p
  ui_ask p "Pool host:port" "$COIN_POOL_DEFAULT"
  POOL="${p#stratum+tcp://}"
  if ! [[ "$POOL" =~ ^[A-Za-z0-9.-]+:[0-9]{2,5}$ ]]; then
    ui_err "Format pool harus host:port."; ui_pause; return
  fi

  # --- worker / thread / suhu ---
  ui_ask WORKER "Nama worker" "hp"
  [[ "$WORKER" =~ ^[A-Za-z0-9_-]{1,20}$ ]] || { ui_err "Nama worker tidak valid."; ui_pause; return; }

  local cores def maxtemp guard=1
  cores="$(nproc 2>/dev/null || echo 2)"
  def=$(( cores > 1 ? cores / 2 : 1 ))
  ui_ask THREADS "Jumlah thread (CPU $cores core)" "$def"
  [[ "$THREADS" =~ ^[0-9]{1,3}$ ]] && [ "$THREADS" -ge 1 ] || { ui_err "Thread tidak valid."; ui_pause; return; }

  ui_ask maxtemp "Batas suhu baterai (C)" "$MAX_TEMP_DEFAULT"
  [[ "$maxtemp" =~ ^[0-9]{2,3}$ ]] || { ui_err "Suhu tidak valid."; ui_pause; return; }

  if ! command -v termux-battery-status >/dev/null 2>&1; then
    ui_warn "termux-api tidak ada: pengaman suhu NONAKTIF."
    ui_confirm "Lanjut tanpa pengaman suhu?" || return
    guard=0
  fi

  CMD=()
  if ! miner_build_cmd || [ "${#CMD[@]}" -eq 0 ]; then ui_err "Gagal menyusun perintah miner."; ui_pause; return; fi

  # --- ringkasan sebelum mulai ---
  ui_head "MULAI MINING"
  ui_kv "Koin"    "$COIN_NAME ($COIN_SYMBOL)" "$C_B"
  ui_kv "Algo"    "$COIN_ALGO"
  ui_kv "Pool"    "$POOL"
  ui_kv "Wallet"  "$(ui_short "$WALLET")" "$C_G"
  ui_kv "Worker"  "$WORKER"
  ui_kv "Thread"  "$THREADS"
  if [ "$guard" = 1 ]; then ui_kv "Suhu maks" "${maxtemp} C" "$C_Y"; else ui_kv "Suhu maks" "nonaktif" "$C_R"; fi
  ui_bottom
  echo
  ui_ok "Mining dimulai. Tekan Ctrl+C untuk berhenti."
  echo

  local t0 t1
  t0="$(date +%s)"
  miner_run "$maxtemp" "$guard" "${CMD[@]}"
  t1="$(date +%s)"

  echo
  ui_top
  ui_title "MINING BERHENTI"
  ui_mid
  ui_kv "Koin"   "$COIN_SYMBOL" "$C_B"
  ui_kv "Durasi" "$(ui_dur $((t1 - t0)))" "$C_C"
  ui_bottom
  ui_pause
}

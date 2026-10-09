#!/usr/bin/env bash
# Validasi semua file di coins/ (jalankan sebelum membuat Pull Request)
#   bash tools/check-coins.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config.sh"

fail=0; seen=""; n=0
for f in "$ROOT"/coins/*.sh; do
  [ -f "$f" ] || continue
  n=$((n+1)); base="$(basename "$f" .sh)"
  out="$(
    COIN_SYMBOL=""; COIN_NAME=""; COIN_ALGO=""; COIN_MINER=""; COIN_POOL_DEFAULT=""; COIN_NOTE=""; COIN_PRACTICAL=""
    source "$f" 2>&1 || { echo "gagal di-source"; exit 0; }
    err=""
    [ -n "$COIN_SYMBOL" ] || err+="COIN_SYMBOL kosong; "
    [ -n "$COIN_NAME" ]   || err+="COIN_NAME kosong; "
    [ -n "$COIN_ALGO" ] || [ "$COIN_MINER" = "none" ] || err+="COIN_ALGO kosong; "
    [[ " $MINER_TYPES " == *" $COIN_MINER "* ]] || err+="COIN_MINER harus salah satu: $MINER_TYPES; "
    [[ "$COIN_PRACTICAL" == yes || "$COIN_PRACTICAL" == no ]] || err+="COIN_PRACTICAL harus yes/no; "
    [[ "$COIN_SYMBOL" =~ ^[A-Z0-9]{1,10}$ ]] || err+="COIN_SYMBOL harus A-Z0-9 (maks 10); "
    [ "${COIN_SYMBOL,,}" = "$base" ] || err+="nama file harus ${COIN_SYMBOL,,}.sh; "
    case "$COIN_SYMBOL$COIN_NAME$COIN_ALGO$COIN_POOL_DEFAULT$COIN_NOTE" in *"|"*) err+="jangan pakai karakter '|'; " ;; esac
    if [ -n "$COIN_POOL_DEFAULT" ] && ! [[ "$COIN_POOL_DEFAULT" =~ ^[A-Za-z0-9.-]+:[0-9]{2,5}$ ]]; then err+="COIN_POOL_DEFAULT harus host:port; "; fi
    echo "$err"
  )"
  sym="$(grep -m1 '^COIN_SYMBOL=' "$f" | cut -d'"' -f2)"
  case " $seen " in *" $sym "*) out+="simbol $sym duplikat; " ;; esac
  seen+=" $sym"
  if [ -n "$out" ]; then echo "GAGAL  $(basename "$f"): $out"; fail=1; else echo "ok     $(basename "$f")"; fi
done
echo "---"; echo "$n file koin diperiksa."
[ $fail -eq 0 ] && echo "Semua valid." || { echo "Ada yang perlu diperbaiki."; exit 1; }

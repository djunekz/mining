#!/usr/bin/env bash
# Validasi semua file di coins/ (jalankan sebelum membuat Pull Request)
#   bash tools/check-coins.sh             periksa semua koin
#   bash tools/check-coins.sh --summary   cetak tabel Markdown (untuk CI)
#
# Dua lapis pemeriksaan:
#  1. nilai variabel (simbol, miner, pool, dsb.)
#  2. GUARD isi file: file koin di-"source" sebagai kode bash, jadi hanya
#     boleh berisi komentar, assignment COIN_*="teks biasa", dan (opsional)
#     fungsi coin_cmd() yang isinya hanya CMD=(...).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/config.sh"

summary=0; [ "${1:-}" = "--summary" ] && summary=1

# Cetak pelanggaran isi file (kosong = aman). Exit 7 bila ada coin_cmd (perlu review manual).
guard() {
  awk '
    BEGIN { infn=0; bad=0; review=0 }
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    infn==0 && /^COIN_[A-Z_]+="[^"$`\\]*"[[:space:]]*(#.*)?$/ { next }
    infn==0 && /^coin_cmd\(\)[[:space:]]*\{[[:space:]]*$/ { infn=1; review=1; next }
    infn==1 && /^\}[[:space:]]*$/ { infn=0; next }
    infn==1 && /^[[:space:]]*CMD=\(.*\)[[:space:]]*$/ && !/[;|&`<>]/ && !/\$\(/ { next }
    { printf "baris %d tidak diizinkan: %s\n", NR, $0; bad=1 }
    END { if (infn) { print "coin_cmd tidak ditutup"; bad=1 } ; exit bad ? 1 : (review ? 7 : 0) }
  ' "$1"
}

fail=0; seen=""; n=0; rows=""
for f in "$ROOT"/coins/*.sh; do
  [ -f "$f" ] || continue
  n=$((n+1)); base="$(basename "$f" .sh)"
  err=""

  g="$(guard "$f")"; rc=$?
  if [ $rc -eq 1 ]; then err+="isi file tidak aman: $(echo "$g" | head -1); "
  elif [ $rc -eq 7 ]; then
    if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::warning file=coins/$base.sh::memakai coin_cmd(), perlu review manual"
    else echo "REVIEW $base.sh: memakai coin_cmd(), perlu review manual"; fi
  fi

  if [ -z "$err" ]; then
    out="$(
      COIN_SYMBOL=""; COIN_NAME=""; COIN_ALGO=""; COIN_MINER=""; COIN_POOL_DEFAULT=""; COIN_POOL_ALT=""; COIN_POOL_PASS=""; COIN_NOTE=""; COIN_PRACTICAL=""
      # shellcheck disable=SC1090
      source "$f" 2>&1 || { echo "gagal di-source"; exit 0; }
      e=""
      [ -n "$COIN_SYMBOL" ] || e+="COIN_SYMBOL kosong; "
      [ -n "$COIN_NAME" ]   || e+="COIN_NAME kosong; "
      [ -n "$COIN_ALGO" ] || [ "$COIN_MINER" = "none" ] || e+="COIN_ALGO kosong; "
      [[ " $MINER_TYPES " == *" $COIN_MINER "* ]] || e+="COIN_MINER harus salah satu: $MINER_TYPES; "
      [[ "$COIN_PRACTICAL" == yes || "$COIN_PRACTICAL" == no ]] || e+="COIN_PRACTICAL harus yes/no; "
      [[ "$COIN_SYMBOL" =~ ^[A-Z0-9]{1,10}$ ]] || e+="COIN_SYMBOL harus A-Z0-9 (maks 10); "
      [ "${COIN_SYMBOL,,}" = "$base" ] || e+="nama file harus ${COIN_SYMBOL,,}.sh; "
      case "$COIN_SYMBOL$COIN_NAME$COIN_ALGO$COIN_POOL_DEFAULT$COIN_NOTE" in *"|"*) e+="jangan pakai karakter '|'; " ;; esac
      if [ -n "$COIN_POOL_DEFAULT" ] && ! [[ "$COIN_POOL_DEFAULT" =~ ^[A-Za-z0-9.-]+:[0-9]{2,5}$ ]]; then e+="COIN_POOL_DEFAULT harus host:port; "; fi
      for p in $COIN_POOL_ALT; do
        [[ "$p" =~ ^[A-Za-z0-9.-]+:[0-9]{2,5}$ ]] || e+="COIN_POOL_ALT berisi '$p' (harus host:port dipisah spasi); "
      done
      [ -z "$COIN_POOL_ALT" ] || [ -n "$COIN_POOL_DEFAULT" ] || e+="COIN_POOL_ALT butuh COIN_POOL_DEFAULT; "
      echo "$e"
    )"
    err+="$out"
    sym="$(grep -m1 '^COIN_SYMBOL=' "$f" | cut -d'"' -f2)"
    case " $seen " in *" $sym "*) err+="simbol $sym duplikat; " ;; esac
    seen+=" $sym"
    if [ "$summary" = 1 ]; then
      rows+="| $sym | $(grep -m1 '^COIN_NAME=' "$f" | cut -d'"' -f2) | $(grep -m1 '^COIN_ALGO=' "$f" | cut -d'"' -f2) | $(grep -m1 '^COIN_MINER=' "$f" | cut -d'"' -f2) | $(grep -m1 '^COIN_PRACTICAL=' "$f" | cut -d'"' -f2) |"$'\n'
    fi
  fi

  if [ -n "$err" ]; then
    if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::error file=coins/$base.sh::$err"; fi
    echo "GAGAL  $base.sh: $err"; fail=1
  elif [ "$summary" = 0 ]; then
    echo "ok     $base.sh"
  fi
done

if [ "$summary" = 1 ]; then
  printf '### Daftar koin (%s)\n\n| Kode | Nama | Algoritma | Miner | Praktis |\n|---|---|---|---|---|\n%s\n' "$n" "$rows"
fi
echo "---"; echo "$n file koin diperiksa."
if [ $fail -eq 0 ]; then echo "Semua valid."; else echo "Ada yang perlu diperbaiki."; exit 1; fi

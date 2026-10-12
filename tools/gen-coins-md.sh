#!/usr/bin/env bash
# Membuat docs/COINS.md (daftar koin) dari isi folder coins/.
# File koin TIDAK di-source; nilainya dibaca dengan grep, jadi aman dijalankan
# di CI untuk PR dari siapa pun.
#   bash tools/gen-coins-md.sh            tulis docs/COINS.md
#   bash tools/gen-coins-md.sh --stdout   cetak saja
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

field() { grep -m1 "^$1=" "$2" | cut -d'"' -f2; }

gen() {
  local f n=0 rows="" sym name algo miner pool prac note
  for f in "$ROOT"/coins/*.sh; do
    [ -f "$f" ] || continue
    sym="$(field COIN_SYMBOL "$f")"
    [ -n "$sym" ] || continue
    name="$(field COIN_NAME "$f")";        algo="$(field COIN_ALGO "$f")"
    miner="$(field COIN_MINER "$f")";      pool="$(field COIN_POOL_DEFAULT "$f")"
    prac="$(field COIN_PRACTICAL "$f")";   note="$(field COIN_NOTE "$f")"
    n=$((n+1))
    [ "$prac" = "yes" ] && prac="ya" || prac="tidak"
    rows+="| $sym | $name | \`$algo\` | $miner | ${pool:--} | $prac | $note |"$'\n'
  done
  cat <<EOF
# Daftar koin

> File ini dibuat **otomatis** oleh \`tools/gen-coins-md.sh\` (workflow \`coins-doc\`).
> Jangan diedit manual; ubah file koin di folder \`coins/\`.

Total: **$n koin**.

| Kode | Nama | Algoritma | Miner | Pool default | Praktis di HP | Catatan |
|---|---|---|---|---|---|---|
$rows
Koin yang tidak praktis (butuh ASIC/GPU) tetap ada di daftar agar mudah
diperluas, tetapi hasil mining di HP praktis nol.

Ingin menambah koin? Lihat [CONTRIBUTING.md](../CONTRIBUTING.md).
EOF
}

if [ "${1:-}" = "--stdout" ]; then gen; else gen > "$ROOT/docs/COINS.md"; echo "docs/COINS.md diperbarui."; fi

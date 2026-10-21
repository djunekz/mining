#!/usr/bin/env bash
# Mengecek apakah pool (default + cadangan) tiap koin masih bisa dihubungi (koneksi TCP).
# File koin dibaca dengan grep (tidak di-source).
#   bash tools/check-pools.sh [file-laporan.md]
# Exit 1 bila ada pool yang gagal. Laporan Markdown ditulis ke file (default pool-report.md).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
report="${1:-pool-report.md}"

fail=0; total=0; rows=""
for f in "$ROOT"/coins/*.sh; do
  [ -f "$f" ] || continue
  sym="$(grep -m1 '^COIN_SYMBOL=' "$f" | cut -d'"' -f2)"
  pools="$(grep -m1 '^COIN_POOL_DEFAULT=' "$f" | cut -d'"' -f2) $(grep -m1 '^COIN_POOL_ALT=' "$f" | cut -d'"' -f2)"
  for pool in $pools; do
    total=$((total+1))
    if ! [[ "$pool" =~ ^[A-Za-z0-9.-]+:[0-9]{2,5}$ ]]; then
      rows+="| $sym | \`$pool\` | format salah |"$'\n'; fail=1; continue
    fi
    host="${pool%:*}"; port="${pool##*:}"
    if timeout 8 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null; then
      echo "ok     $sym  $pool"
    else
      echo "GAGAL  $sym  $pool"
      rows+="| $sym | \`$pool\` | tidak dapat dihubungi |"$'\n'; fail=1
    fi
  done
done

{
  echo "### Pemeriksaan pool"
  echo
  if [ "$fail" = 0 ]; then
    echo "Semua $total pool (default + cadangan) dapat dihubungi."
  else
    echo "Pool berikut tidak dapat dihubungi dari runner CI (bisa sementara; cek ulang sebelum mengganti):"
    echo
    echo "| Koin | Pool | Masalah |"
    echo "|---|---|---|"
    printf '%s' "$rows"
    echo
    echo "Pool pengganti? Perbarui \`COIN_POOL_DEFAULT\` atau \`COIN_POOL_ALT\` di file koinnya."
  fi
} > "$report"

echo "---"; echo "$total pool diperiksa."
exit "$fail"

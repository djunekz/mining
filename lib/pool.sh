# Pemilihan pool otomatis
#
# Urutan kandidat: COIN_POOL_DEFAULT lalu semua COIN_POOL_ALT (dipisah spasi).
#  1. Tiap kandidat dites koneksi TCP (memakai DNS perangkat).
#  2. Nama host juga di-resolve lewat DNS-over-HTTPS (1.1.1.1 / 8.8.8.8) dan alamat
#     IP-nya ditambahkan sebagai cadangan. Ini menangani galat "DNS error: no address".
# Hasilnya array POOLS (urut prioritas). xmrig memakai semuanya sebagai cadangan
# otomatis (failover); miner lain memakai yang pertama.

POOL_TIMEOUT="${POOL_TIMEOUT:-6}"
POOLS=()

# true jika host:port bisa disambung
pool_tcp() {
  timeout "$POOL_TIMEOUT" bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$1" "$2" 2>/dev/null
}

# Cetak alamat IPv4 untuk host lewat DNS-over-HTTPS; gagal bila tidak ada
pool_doh() {
  local h="$1" url ip
  command -v curl >/dev/null 2>&1 || return 1
  for url in "https://1.1.1.1/dns-query" "https://8.8.8.8/resolve"; do
    ip="$(curl -fsS -m 6 -H 'accept: application/dns-json' "$url?name=$h&type=A" 2>/dev/null \
      | grep -oE '"data": *"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"' | head -n1 \
      | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
    if [ -n "$ip" ]; then echo "$ip"; return 0; fi
  done
  return 1
}

# Daftar kandidat koin yang sedang dimuat, satu per baris
pool_candidates() {
  local p
  [ -z "${COIN_POOL_DEFAULT:-}" ] || echo "$COIN_POOL_DEFAULT"
  for p in ${COIN_POOL_ALT:-}; do echo "$p"; done
}

pool_has_candidates() { [ -n "${COIN_POOL_DEFAULT:-}${COIN_POOL_ALT:-}" ]; }

# Isi POOLS dengan pool yang bisa dihubungi. Return 0 bila ada.
# Urutan hasil: (1) nama host yang lolos tes, (2) alamat IP dari DNS-over-HTTPS.
# Entri IP selalu ikut ditambahkan sebagai cadangan, sehingga bila DNS di dalam
# miner gagal ("DNS error: no address") xmrig otomatis pindah ke alamat IP.
pool_auto() {
  local -a cand=() ips=()
  local p h port ip n=0 q
  POOLS=()
  mapfile -t cand < <(pool_candidates)
  [ "${#cand[@]}" -gt 0 ] || return 1

  ui_info "Mencari pool yang aktif..."
  for p in "${cand[@]}"; do
    h="${p%:*}"; port="${p##*:}"
    if pool_tcp "$h" "$port"; then
      ui_ok "$p"; POOLS+=("$p")
    else
      ui_warn "$p tidak terhubung"
    fi
  done

  ui_info "Menyiapkan alamat IP cadangan (DNS-over-HTTPS)..."
  for p in "${cand[@]}"; do
    [ "$n" -lt 3 ] || break
    h="${p%:*}"; port="${p##*:}"
    n=$((n+1))
    ip="$(pool_doh "$h")" || continue
    [ -n "$ip" ] || continue
    q="$ip:$port"
    case " ${ips[*]:-} " in *" $q "*) continue ;; esac
    if pool_tcp "$ip" "$port"; then ips+=("$q"); ui_ok "$p  ->  $q"; fi
  done
  POOLS+=("${ips[@]}")
  [ "${#POOLS[@]}" -le 6 ] || POOLS=("${POOLS[@]:0:6}")
  [ "${#POOLS[@]}" -gt 0 ]
}

# Pool yang diketik pengguna: tes, dan bila DNS perangkat gagal pakai IP dari DoH
pool_manual() {
  local p="$1" h port ip
  h="${p%:*}"; port="${p##*:}"
  POOLS=("$p")
  ui_info "Mengetes $p ..."
  if pool_tcp "$h" "$port"; then ui_ok "Pool terhubung."; return 0; fi
  ip="$(pool_doh "$h")" || ip=""
  if [ -n "$ip" ] && pool_tcp "$ip" "$port"; then
    ui_warn "DNS perangkat gagal; memakai alamat IP $ip"
    POOLS=("$ip:$port"); return 0
  fi
  ui_err "Pool $p tidak bisa dihubungi."
  ui_confirm "Tetap lanjut?" || return 1
  return 0
}

# Penjelasan bila tidak ada pool yang bisa dipakai
pool_diagnose() {
  echo
  ui_err "Tidak ada pool yang bisa dihubungi."
  if command -v curl >/dev/null 2>&1 && ! curl -s -m 6 -o /dev/null "https://1.1.1.1" 2>/dev/null; then
    ui_info "Internet tidak terdeteksi. Cek Wi-Fi / data seluler."
  else
    ui_info "Internet ada, tapi pool diblokir atau DNS bermasalah."
    ui_info "Coba: matikan VPN / Private DNS, ganti jaringan,"
    ui_info "atau isi pool lain (host:port) secara manual."
  fi
}

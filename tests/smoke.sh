#!/usr/bin/env bash
# =====================================================
#  Smoke test MINING: menjalankan menu sungguhan dengan input otomatis
#  dan miner palsu. Tidak menyentuh data asli (HOME sementara).
#    bash tests/smoke.sh
# =====================================================
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# salinan repo supaya tes yang menambah koin tidak mengotori repo asli
cp -r "$REPO" "$TMP/repo"
rm -rf "$TMP/repo/.git"
export HOME="$TMP/home"; mkdir -p "$HOME"
export TERM=xterm LC_ALL=C.UTF-8
unset MINING_HOME

# miner & termux-api palsu
mkdir -p "$TMP/bin"
printf '#!/bin/sh\necho "FAKE_MINER $*"\nsleep 1\n' > "$TMP/bin/xmrig"
printf '#!/bin/sh\necho "{ \\"temperature\\": 30.0 }"\n'  > "$TMP/bin/termux-battery-status"
chmod +x "$TMP/bin/"*
export PATH="$TMP/bin:$PATH"

WALLET="49gYsEXAMPLEWALLETADDRESSxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
pass=0; failn=0
strip() { sed 's/\x1b\[[0-9;]*[A-Za-z]//g'; }
run()   { timeout 60 bash "$TMP/repo/mining.sh" 2>&1 | strip; }
ok()    { pass=$((pass+1)); echo "  ok   $1"; }
bad()   { failn=$((failn+1)); echo "  GAGAL $1"; }
# check "nama tes" "teks yang dicari" "output"
check() { if grep -qF -- "$2" <<<"$3"; then ok "$1"; else bad "$1  (tidak ada: $2)"; echo "$3" | tail -15; fi; }

NCOINS="$(ls "$REPO"/coins/*.sh | wc -l)"
IDX="$(ROOT="$TMP/repo" bash -c 'source "$ROOT/config.sh"; for m in ui coins; do source "$ROOT/lib/$m.sh"; done; coins_scan | cut -d"|" -f1 | grep -nx XMR | cut -d: -f1')"

echo "== menu utama & daftar koin"
out="$(printf '%s\n' 2 "" 0 | run)"
check "banner MINING tampil"         "M U L T I - C O I N"   "$out"
check "jumlah koin di banner"        "$NCOINS tersedia"      "$out"
check "daftar koin: total"           "$NCOINS koin"          "$out"
check "daftar koin: XMR ada"         "Monero"                "$out"

echo "== registrasi + mining"
out="$(printf '%s\n' 1 2 tester secret1 secret1 "" "" "$IDX" "$WALLET" "" "" "" "" "" "" 0 0 | run)"
check "registrasi berhasil"          "Registrasi berhasil"   "$out"
check "miner dijalankan"             "FAKE_MINER -o pool.supportxmr.com:3333" "$out"
check "donate-level eksplisit"       "--donate-level 1"      "$out"
check "ringkasan durasi"             "Durasi"                "$out"
[ "$(stat -c %a "$HOME/.mining/users.db")" = "600" ] && ok "users.db izin 600" || bad "users.db izin 600"
grep -q '^tester:' "$HOME/.mining/users.db" && ok "akun tersimpan" || bad "akun tersimpan"
grep -q 'secret1' "$HOME/.mining/users.db" && bad "password TIDAK boleh plaintext" || ok "password ter-hash"

echo "== login & wallet"
out="$(printf '%s\n' 6 1 tester wrong wrong wrong "" 0 | run)"
check "login salah 3x"               "salah (3/3)"           "$out"
out="$(printf '%s\n' 3 1 tester secret1 "" 1 "" 0 0 | run)"
check "login benar"                  "Login berhasil"        "$out"
check "wallet tersimpan tampil"      "49gYsEXAMPLEWA...xxxxxxxxx" "$out"
[ "$(stat -c %a "$HOME/.mining/wallets/tester.conf")" = "600" ] && ok "wallet izin 600" || bad "wallet izin 600"

echo "== referral"
CODE="$(grep -m1 '^tester:' "$HOME/.mining/users.db" | cut -d: -f4)"
out="$(printf '%s\n' 6 2 budi pass12 pass12 "$CODE" "" "" 0 0 | run)"
check "registrasi dengan referral"   "Registrasi berhasil"   "$out"
[ "$(grep -m1 '^budi:' "$HOME/.mining/users.db" | cut -d: -f5)" = "tester" ] && ok "referred_by tercatat" || bad "referred_by tercatat"

echo "== validasi input mining"
out="$(printf '%s\n' 1 1 tester secret1 "" "$IDX" "bukan-pool" 0 0 | run)"
check "pool tidak valid ditolak"     "Format pool harus host:port" "$out"

echo "== menambah koin cukup dengan 1 file"
cat > "$TMP/repo/coins/new.sh" <<'EOF'
COIN_SYMBOL="NEW"
COIN_NAME="Koin Baru"
COIN_ALGO="rx/0"
COIN_MINER="xmrig"
COIN_POOL_DEFAULT=""
COIN_NOTE="uji"
COIN_PRACTICAL="yes"
EOF
out="$(printf '%s\n' 2 "" 0 | run)"
check "koin baru muncul di daftar"   "Koin Baru"             "$out"
check "jumlah koin bertambah"        "$((NCOINS+1)) koin"    "$out"

echo
echo "Hasil: $pass lolos, $failn gagal"
[ "$failn" -eq 0 ]

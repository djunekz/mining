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
# jaringan palsu: "timeout" mensimulasikan tes TCP pool, "curl" mensimulasikan DNS-over-HTTPS
REAL_TIMEOUT="$(command -v timeout)"
cat > "$TMP/bin/timeout" <<EOF
#!/bin/sh
# tes TCP: dua argumen terakhir = host port. Host di FAKE_DOWN dianggap mati; IP selalu hidup.
case "\$*" in
  *dev/tcp*)
    host=\$(echo "\$*" | awk '{print \$(NF-1)}')
    case " \${FAKE_DOWN:-} " in *" \$host "*) exit 1 ;; esac
    exit 0 ;;
esac
exec "$REAL_TIMEOUT" "\$@"
EOF
cat > "$TMP/bin/curl" <<'EOF'
#!/bin/sh
case "$*" in
  *dns-query*|*resolve*) echo '{"Answer":[{"name":"x","type":1,"data": "203.0.113.7"}]}'; exit 0 ;;
esac
exit 1
EOF
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

echo "== pool otomatis"
out="$(FAKE_DOWN="pool.supportxmr.com" bash -c 'printf "%s\n" 1 1 tester secret1 "" "$0" "" "" "" "" "" 0 0 | timeout 60 bash "$2/repo/mining.sh" 2>&1' "$IDX" "$WALLET" "$TMP" | strip)"
check "pool mati dilaporkan"          "pool.supportxmr.com:3333 tidak terhubung" "$out"
check "pool cadangan dipakai"         "FAKE_MINER -o xmr-eu1.nanopool.org:10300" "$out"
check "alamat IP cadangan (DoH)"      "-o 203.0.113.7:3333" "$out"
out="$(FAKE_DOWN="pool.supportxmr.com xmr-eu1.nanopool.org pool.hashvault.pro gulf.moneroocean.stream" bash -c 'printf "%s\n" 1 1 tester secret1 "" "$0" "" "" "" "" "" 0 0 | timeout 60 bash "$2/repo/mining.sh" 2>&1' "$IDX" "$WALLET" "$TMP" | strip)"
check "semua host mati: pindah ke IP" "FAKE_MINER -o 203.0.113.7:3333" "$out"

echo "== pasang xmrig & cpuminer (pkg/git/cmake/make palsu)"
GIT_REAL="$(command -v git)"
IB="$TMP/ibin"; mkdir -p "$IB" "$TMP/prefix/bin" "$TMP/tpl"
printf '#!/bin/sh\necho "FAKE_PKG $*"\n' > "$IB/pkg"
printf '#!/bin/sh\nexit 0\n' > "$TMP/tpl/autogen.sh"
printf '#!/bin/sh\necho "CFLAGS=$CFLAGS $*" > "$TMP_CMAKE_LOG"\n' > "$TMP/tpl/configure"
chmod +x "$TMP/tpl/"*
cat > "$IB/git" <<EOF
#!/bin/sh
case "\$1" in
  ls-remote)
    case "\$*" in
      *cpuminer*) printf 'a\trefs/tags/v3.9.9\nb\trefs/tags/v26.1\nc\trefs/tags/v27.4\nd\trefs/tags/v.3.21.4\n' ;;
      *) printf 'a\trefs/tags/v6.9.0\nb\trefs/tags/v6.21.0\nc\trefs/tags/v6.22.2\nd\trefs/tags/v6.22.2-rc1\n' ;;
    esac ;;
  clone) for last; do :; done; mkdir -p "\$last"; echo "\$*" > "\$TMP_CLONE_LOG"; cp "$TMP/tpl/"* "\$last/" ;;
  *) exec "$GIT_REAL" "\$@" ;;
esac
EOF
printf '#!/bin/sh\necho "$*" > "$TMP_CMAKE_LOG"\n' > "$IB/cmake"
cat > "$IB/make" <<'EOF'
#!/bin/sh
[ -n "$FAKE_MAKE_FAIL" ] && { echo "make: *** error palsu"; exit 2; }
printf '#!/bin/sh\necho "XMRig 6.22.2"\n' > xmrig; chmod +x xmrig
printf '#!/bin/sh\necho "cpuminer-opt 27.4"\n' > cpuminer; chmod +x cpuminer
EOF
printf '#!/bin/sh\n[ "$1" = "-m" ] && echo aarch64 || exec /usr/bin/uname "$@"\n' > "$IB/uname"
# curl palsu: tulis isi ccminer palsu ke berkas -o
cat > "$IB/curl" <<'EOF'
#!/bin/sh
while [ $# -gt 0 ]; do [ "$1" = "-o" ] && { shift; out="$1"; }; shift; done
[ -n "$FAKE_CURL_FAIL" ] && exit 22
printf '#!/bin/sh\necho "ccminer 3.8.3"\n' > "$out"
EOF
chmod +x "$IB/"*
FAKE_CC_SHA="$(printf '#!/bin/sh\necho "ccminer 3.8.3"\n' | sha256sum | cut -d' ' -f1)"
runi() {
  TMP_CLONE_LOG="$TMP/clone.log" TMP_CMAKE_LOG="$TMP/cmake.log" PREFIX="$TMP/prefix" \
    PATH="$IB:$TMP/prefix/bin:/usr/bin:/bin" timeout 60 bash "$TMP/repo/mining.sh" 2>&1 | strip
}
out="$(printf '%s\n' 4 2 2 y "" 0 0 0 | runi)"
check "xmrig: rilis stabil terbaru (bukan 6.9.0/rc)" "Versi: v6.22.2" "$out"
check "xmrig dipasang"               "xmrig terpasang: XMRig 6.22.2" "$out"
grep -q -- '--branch v6.22.2' "$TMP/clone.log" && ok "xmrig: clone memakai tag rilis" || bad "xmrig: clone memakai tag rilis"
grep -q -- '-DWITH_HWLOC=OFF' "$TMP/cmake.log" && ok "cmake: hwloc dimatikan" || bad "cmake: hwloc dimatikan"
[ -x "$TMP/prefix/bin/xmrig" ] && ok "xmrig ada di PREFIX/bin" || bad "xmrig ada di PREFIX/bin"
rm -f "$TMP/prefix/bin/xmrig"
out="$(printf '%s\n' 4 2 2 y "" 0 0 0 | FAKE_MAKE_FAIL=1 runi)"
check "kompilasi gagal dilaporkan"   "Kompilasi gagal"       "$out"
[ ! -e "$TMP/prefix/bin/xmrig" ] && ok "tidak ada binary saat gagal" || bad "tidak ada binary saat gagal"
out="$(printf '%s\n' 4 2 3 y "" 0 0 0 | runi)"
check "cpuminer: rilis terbaru"      "Versi: v27.4"          "$out"
check "cpuminer dipasang"            "cpuminer terpasang: cpuminer-opt 27.4" "$out"
grep -q -- '--branch v27.4' "$TMP/clone.log" && ok "cpuminer: clone memakai tag rilis" || bad "cpuminer: clone memakai tag rilis"
grep -q 'CFLAGS=' "$TMP/cmake.log" && ok "cpuminer: configure dijalankan" || bad "cpuminer: configure dijalankan"
[ -x "$TMP/prefix/bin/cpuminer" ] && ok "cpuminer ada di PREFIX/bin" || bad "cpuminer ada di PREFIX/bin"

echo "== pasang ccminer (unduh + SHA-256)"
out="$(printf '%s\n' 4 2 4 y "" 0 0 0 | CCMINER_SHA256="$FAKE_CC_SHA" runi)"
check "ccminer: SHA-256 cocok"       "SHA-256 cocok"         "$out"
check "ccminer dipasang"             "ccminer terpasang: ccminer 3.8.3" "$out"
[ -x "$TMP/prefix/bin/ccminer" ] && ok "ccminer ada di PREFIX/bin" || bad "ccminer ada di PREFIX/bin"
rm -f "$TMP/prefix/bin/ccminer"
out="$(printf '%s\n' 4 2 4 y "" 0 0 0 | CCMINER_SHA256="deadbeef" runi)"
check "ccminer: SHA-256 salah ditolak" "SHA-256 tidak cocok" "$out"
[ ! -e "$TMP/prefix/bin/ccminer" ] && ok "ccminer tidak terpasang bila hash salah" || bad "ccminer tidak terpasang bila hash salah"
out="$(printf '%s\n' 4 2 4 y "" 0 0 0 | FAKE_CURL_FAIL=1 CCMINER_SHA256="$FAKE_CC_SHA" runi)"
check "ccminer: unduhan gagal dilaporkan" "Gagal mengunduh" "$out"

echo "== uninstall miner"
for m in xmrig ccminer; do printf '#!/bin/sh\necho x\n' > "$TMP/prefix/bin/$m"; chmod +x "$TMP/prefix/bin/$m"; done
out="$(printf '%s\n' 4 2 6 1 y "" 0 0 0 0 | runi)"
check "uninstall: daftar miner"      "UNINSTALL MINER"       "$out"
check "uninstall: xmrig dihapus"     "xmrig dihapus"         "$out"
[ ! -e "$TMP/prefix/bin/xmrig" ] && ok "berkas xmrig hilang" || bad "berkas xmrig hilang"
[ -x "$TMP/prefix/bin/cpuminer" ] && ok "miner lain tidak ikut terhapus" || bad "miner lain tidak ikut terhapus"
mkdir -p "$HOME/.mining/build"; echo x > "$HOME/.mining/build/sisa"
out="$(printf '%s\n' 4 2 6 a y "" 0 0 0 | runi)"
check "uninstall semua"              "dihapus"               "$out"
[ ! -e "$TMP/prefix/bin/cpuminer" ] && [ ! -e "$TMP/prefix/bin/ccminer" ] && ok "semua miner terhapus" || bad "semua miner terhapus"
[ ! -e "$HOME/.mining/build" ] && ok "sisa kompilasi dibersihkan" || bad "sisa kompilasi dibersihkan"
[ -f "$HOME/.mining/users.db" ] && ok "akun tetap ada setelah uninstall" || bad "akun tetap ada setelah uninstall"
out="$(printf '%s\n' 4 2 6 "" 0 0 0 | runi)"
check "uninstall: tidak ada miner"   "Tidak ada miner yang terpasang" "$out"

echo "== cek update (git sungguhan, remote lokal)"
UP="$TMP/up"; mkdir -p "$UP"
GI=(-c user.name=t -c user.email=t@t)
git init -q --bare -b main "$UP/remote.git"
cp -r "$REPO" "$UP/app"; rm -rf "$UP/app/.git"
( cd "$UP/app" && git init -q -b main && git "${GI[@]}" add -A && git "${GI[@]}" commit -qm init \
  && git remote add origin "$UP/remote.git" && git push -q -u origin main )
APPV="$(tr -d '[:space:]' < "$UP/app/VERSION")"
runapp() { timeout 60 bash "$UP/app/mining.sh" 2>&1 | strip; }

out="$(printf '%s\n' 4 1 "" 0 0 | runapp)"
check "tanpa rilis: terbaca"         "(belum ada rilis)"     "$out"
check "tanpa rilis & tanpa commit baru: terbaru" "Sudah versi terbaru" "$out"

( cd "$UP/app" && git tag "v$APPV" && git push -q origin "v$APPV" )
out="$(printf '%s\n' 4 1 "" 0 0 | runapp)"
check "versi sama dengan rilis: terbaru" "Sudah versi terbaru" "$out"

# kasus yang dilaporkan pengguna: VERSION lokal diturunkan, rilis di repo lebih baru
echo "0.1.9" > "$UP/app/VERSION"
out="$(printf '%s\n' 4 1 "" 0 0 | runapp)"
check "VERSION turun: tidak lagi dianggap terbaru" "lebih lama dari rilis v$APPV" "$out"
out="$(printf '%s\n' 4 1 n "" 0 0 | runapp)"
if grep -qF "Update selesai" <<<"$out"; then bad "jawab tidak: update tidak boleh jalan"; else ok "jawab tidak: update tidak jalan"; fi
[ "$(tr -d '[:space:]' < "$UP/app/VERSION")" = "0.1.9" ] && ok "tanpa konfirmasi VERSION tidak disentuh" || bad "tanpa konfirmasi VERSION tidak disentuh"
[ "$(git -C "$UP/app" stash list | wc -l)" -eq 0 ] && ok "tanpa konfirmasi tidak ada stash" || bad "tanpa konfirmasi tidak ada stash"
out="$(printf '%s\n' 4 1 y 0 | runapp)"
check "update dijalankan"            "Update selesai"        "$out"
[ "$(tr -d '[:space:]' < "$UP/app/VERSION")" = "$APPV" ] && ok "VERSION kembali ke versi repo" || bad "VERSION kembali ke versi repo"
[ "$(git -C "$UP/app" stash list | wc -l)" -eq 1 ] && ok "perubahan lokal disimpan di stash" || bad "perubahan lokal disimpan di stash"

# rilis baru di remote
git clone -q "$UP/remote.git" "$UP/dev"
( cd "$UP/dev" && echo "9.9.9" > VERSION && git "${GI[@]}" commit -qam "chore(release): v9.9.9" \
  && git tag v9.9.9 && git push -q origin main v9.9.9 )
out="$(printf '%s\n' 4 1 y 0 | runapp)"
check "rilis baru terdeteksi"        "lebih lama dari rilis v9.9.9" "$out"
check "update ke rilis baru"         "Update selesai"        "$out"
[ "$(tr -d '[:space:]' < "$UP/app/VERSION")" = "9.9.9" ] && ok "VERSION menjadi 9.9.9" || bad "VERSION menjadi 9.9.9"
check "aplikasi restart dengan versi baru" "v9.9.9"          "$out"

echo "10.0.0" > "$UP/app/VERSION"
out="$(printf '%s\n' 4 1 "" 0 0 | runapp)"
check "versi lokal lebih baru dari rilis" "lebih baru dari rilis terakhir" "$out"
git -C "$UP/app" checkout -q -- VERSION

git -C "$UP/app" remote set-url origin "$UP/tidak-ada.git"
out="$(printf '%s\n' 4 1 "" 0 0 | runapp)"
check "remote tidak terjangkau"      "Gagal terhubung ke repo" "$out"

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

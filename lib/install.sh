# Pasang miner & dependensi (khusus Termux)
#
# Catatan: xmrig TIDAK ada di repo paket Termux (termux-main maupun tur-repo),
# jadi "pkg install xmrig" selalu gagal dengan "Unable to locate package".
# Menu ini mengompilasi xmrig dari sumber resminya (github.com/xmrig/xmrig).

XMRIG_REPO="https://github.com/xmrig/xmrig"
CPUMINER_REPO="https://github.com/JayDDee/cpuminer-opt"

# ccminer (Verus) siap pakai untuk Termux ARM64: binary dari Darktron/pre-compiled.
# Dikunci ke satu commit + SHA-256 supaya isinya tidak bisa berubah diam-diam.
# Bisa ditimpa lewat variabel lingkungan bila ada versi baru.
CCMINER_URL="${CCMINER_URL:-https://raw.githubusercontent.com/Darktron/pre-compiled/89769f1e11d3d1266166960b169f6c3fbca250d8/ccminer}"
CCMINER_SHA256="${CCMINER_SHA256:-30f8637b01b547fa487bba54cd6ae0caf4ab1d8bddeca378647a7333d6df873b}"

install_menu() {
  local c m
  while true; do
    ui_head "PASANG MINER"
    ui_row 1 "Dasar"    "termux-api, curl, git"
    ui_row 2 "xmrig"    "Kompilasi (XMR, RandomX)"
    ui_row 3 "cpuminer" "Kompilasi (YTN, MBC)"
    ui_row 4 "ccminer"  "Unduh binary (Verus)"
    ui_row 5 "Status"   "Cek miner terpasang"
    ui_row 6 "Uninstall" "Hapus miner terpasang"
    ui_row 0 "Kembali"  "Ke menu sebelumnya"
    ui_bottom
    echo
    ui_ask c "Pilih"
    case "$c" in
      1) _inst pkg install -y termux-api curl git ;;
      2) install_xmrig ;;
      3) install_cpuminer ;;
      4) install_ccminer ;;
      5)
        ui_head "STATUS MINER"
        for m in xmrig cpuminer ccminer termux-api:termux-battery-status; do
          if command -v "${m#*:}" >/dev/null 2>&1; then ui_kv "${m%%:*}" "terpasang" "$C_G"; else ui_kv "${m%%:*}" "belum ada" "$C_R"; fi
        done
        ui_bottom
        ui_pause ;;
      6) uninstall_menu ;;
      0) return ;;
    esac
  done
}

_inst() {
  echo
  if ! command -v pkg >/dev/null 2>&1; then
    ui_err "Perintah 'pkg' tidak ditemukan. Menu ini khusus Termux."
    ui_pause; return
  fi
  ui_info "Memasang..."
  if "$@"; then ui_ok "Selesai."; else ui_err "Pemasangan gagal (cek koneksi / repo)."; fi
  ui_pause
}

# ---------- xmrig: kompilasi dari sumber ----------

install_xmrig() {
  ui_head "PASANG XMRIG"
  if command -v xmrig >/dev/null 2>&1; then
    ui_kv "Status" "sudah terpasang" "$C_G"
    ui_kv "Versi"  "$(xmrig --version 2>/dev/null | head -1)"
    ui_bottom
    echo
    ui_confirm "Kompilasi ulang dan timpa?" || return
    ui_head "PASANG XMRIG"
  fi
  ui_text "xmrig tidak ada di repo paket Termux,"
  ui_text "jadi dikompilasi dari sumber resmi:"
  ui_text "github.com/xmrig/xmrig (rilis terbaru)"
  ui_blank
  ui_text "Butuh sekitar 1 GB ruang kosong dan" "$C_Y"
  ui_text "10-30 menit. Colok charger, jangan" "$C_Y"
  ui_text "tutup Termux selama proses." "$C_Y"
  ui_bottom
  echo
  if ! command -v pkg >/dev/null 2>&1; then
    ui_err "Perintah 'pkg' tidak ditemukan. Menu ini khusus Termux."
    ui_pause; return
  fi
  ui_confirm "Mulai kompilasi?" || return

  command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock
  trap ':' INT                       # Ctrl+C membatalkan build, bukan menutup aplikasi
  if _xmrig_build; then
    echo
    ui_ok "xmrig terpasang: $("${PREFIX:-/usr/local}/bin/xmrig" --version 2>/dev/null | head -1)"
  else
    echo
    ui_err "Pemasangan xmrig gagal. Lihat pesan di atas."
    ui_info "Kalau gagal lagi, kirim pesan error-nya lewat issue."
  fi
  trap - INT
  command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock
  ui_pause
}

# Rilis stabil xmrig terbaru (mis. v6.22.2) dari tag git; kosong bila gagal
_xmrig_latest_tag() {
  git ls-remote --tags --refs "$XMRIG_REPO" 'v*' 2>/dev/null \
    | sed -E 's|.*refs/tags/||' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V | tail -1
}

_xmrig_build() {
  local work="$DATA_DIR/build" src tag cores jobs bindir
  src="$work/xmrig"
  bindir="${PREFIX:-/usr/local}/bin"
  cores="$(nproc 2>/dev/null || echo 2)"
  jobs=$(( cores > 4 ? 4 : cores ))   # batasi supaya HP tidak kehabisan RAM

  ui_info "[1/5] Memasang pustaka build..."
  pkg install -y git build-essential cmake libuv openssl || { ui_err "Gagal memasang pustaka build."; return 1; }

  ui_info "[2/5] Mencari rilis xmrig terbaru..."
  tag="$(_xmrig_latest_tag)"
  [ -n "$tag" ] || { ui_err "Gagal membaca daftar rilis xmrig (cek koneksi internet)."; return 1; }
  ui_ok "Versi: $tag"

  ui_info "[3/5] Mengunduh sumber..."
  rm -rf "$work"; mkdir -p "$work"
  git clone --depth 1 --branch "$tag" "$XMRIG_REPO.git" "$src" || { ui_err "Gagal mengunduh sumber xmrig."; return 1; }

  ui_info "[4/5] Kompilasi dengan $jobs thread (paling lama)..."
  mkdir -p "$src/build"
  (
    cd "$src/build" || exit 1
    cmake .. -DCMAKE_BUILD_TYPE=Release -DWITH_HWLOC=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF || exit 1
    make -j"$jobs" || exit 1
  ) || { ui_err "Kompilasi gagal atau dibatalkan."; return 1; }
  [ -x "$src/build/xmrig" ] || { ui_err "Hasil kompilasi (xmrig) tidak ditemukan."; return 1; }

  ui_info "[5/5] Memasang ke $bindir ..."
  mkdir -p "$bindir"
  install -m 755 "$src/build/xmrig" "$bindir/xmrig" || { ui_err "Gagal menyalin xmrig ke $bindir."; return 1; }
  rm -rf "$work"                      # hemat ruang: sumber dan hasil build tidak dibutuhkan lagi
  return 0
}

# Pemasangan miner butuh Termux ('pkg'); beri tahu bila tidak ada
_need_pkg() {
  command -v pkg >/dev/null 2>&1 && return 0
  ui_err "Perintah 'pkg' tidak ditemukan. Menu ini khusus Termux."
  ui_pause; return 1
}

# Jalankan $@ dengan wake-lock aktif dan Ctrl+C hanya membatalkan proses
_with_lock() {
  command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock
  trap ':' INT
  "$@"; local rc=$?
  trap - INT
  command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock
  return "$rc"
}

# ---------- cpuminer: kompilasi cpuminer-opt (JayDDee) ----------

install_cpuminer() {
  ui_head "PASANG CPUMINER"
  if command -v cpuminer >/dev/null 2>&1; then
    ui_kv "Status" "sudah terpasang" "$C_G"
    ui_kv "Versi"  "$(cpuminer --version 2>/dev/null | head -1)"
    ui_bottom
    echo
    ui_confirm "Kompilasi ulang dan timpa?" || return
    ui_head "PASANG CPUMINER"
  fi
  ui_text "Dikompilasi dari sumber resmi cpuminer-opt"
  ui_text "(github.com/JayDDee/cpuminer-opt)."
  ui_text "Dipakai koin: YTN, MBC, dan koin CPU lain."
  ui_blank
  ui_text "Butuh sekitar 500 MB ruang kosong dan" "$C_Y"
  ui_text "5-20 menit. Colok charger." "$C_Y"
  ui_text "Pengembangnya tidak mendukung Android" "$C_Y"
  ui_text "secara resmi: BELUM DIUJI di Termux." "$C_Y"
  ui_bottom
  echo
  _need_pkg || return
  ui_confirm "Mulai kompilasi?" || return

  if _with_lock _cpuminer_build; then
    echo
    ui_ok "cpuminer terpasang: $("${PREFIX:-/usr/local}/bin/cpuminer" --version 2>/dev/null | head -1)"
  else
    echo
    ui_err "Pemasangan cpuminer gagal. Lihat pesan di atas."
    ui_info "Kirim pesan error-nya lewat issue bila perlu."
  fi
  ui_pause
}

# Rilis cpuminer-opt terbaru (format vNN.N, mis. v27.4); kosong bila gagal
_cpuminer_latest_tag() {
  git ls-remote --tags --refs "$CPUMINER_REPO" 'v*' 2>/dev/null \
    | sed -E 's|.*refs/tags/||' \
    | grep -E '^v[0-9]+\.[0-9]+(\.[0-9]+)?$' \
    | sort -V | tail -1
}

_cpuminer_build() {
  local work="$DATA_DIR/build" src tag jobs cflags bindir
  src="$work/cpuminer-opt"
  bindir="${PREFIX:-/usr/local}/bin"
  jobs="$(nproc 2>/dev/null || echo 2)"; [ "$jobs" -le 4 ] || jobs=4

  ui_info "[1/5] Memasang pustaka build..."
  pkg install -y git build-essential autoconf automake libtool pkg-config \
    libcurl libjansson openssl zlib libgmp || { ui_err "Gagal memasang pustaka build."; return 1; }

  ui_info "[2/5] Mencari rilis cpuminer-opt terbaru..."
  tag="$(_cpuminer_latest_tag)"
  [ -n "$tag" ] || { ui_err "Gagal membaca daftar rilis cpuminer-opt (cek koneksi internet)."; return 1; }
  ui_ok "Versi: $tag"

  ui_info "[3/5] Mengunduh sumber..."
  rm -rf "$work"; mkdir -p "$work"
  git clone --depth 1 --branch "$tag" "$CPUMINER_REPO.git" "$src" || { ui_err "Gagal mengunduh sumber cpuminer-opt."; return 1; }

  case "$(uname -m)" in
    aarch64|arm64) cflags="-O2 -march=armv8-a+crypto+sha2+aes -flax-vector-conversions -Wno-error" ;;
    *)             cflags="-O2 -march=native -Wno-error" ;;
  esac

  ui_info "[4/5] Kompilasi dengan $jobs thread (paling lama)..."
  (
    cd "$src" || exit 1
    ./autogen.sh || exit 1
    CFLAGS="$cflags" ./configure --with-curl || exit 1
    make -j"$jobs" || exit 1
  ) || { ui_err "Kompilasi gagal atau dibatalkan."; return 1; }
  [ -x "$src/cpuminer" ] || { ui_err "Hasil kompilasi (cpuminer) tidak ditemukan."; return 1; }

  ui_info "[5/5] Memasang ke $bindir ..."
  mkdir -p "$bindir"
  install -m 755 "$src/cpuminer" "$bindir/cpuminer" || { ui_err "Gagal menyalin cpuminer ke $bindir."; return 1; }
  rm -rf "$work"
  return 0
}

# ---------- ccminer: unduh binary siap pakai ----------

install_ccminer() {
  ui_head "PASANG CCMINER"
  if command -v ccminer >/dev/null 2>&1; then
    ui_kv "Status" "sudah terpasang" "$C_G"
    ui_bottom
    echo
    ui_confirm "Unduh ulang dan timpa?" || return
    ui_head "PASANG CCMINER"
  fi
  ui_text "ccminer (fork Verus) untuk koin VRSC."
  ui_text "Binary ARM64 siap pakai diunduh dari"
  ui_text "github.com/Darktron/pre-compiled lalu"
  ui_text "diperiksa SHA-256-nya."
  ui_blank
  ui_text "Hanya untuk HP ARM 64-bit (ARMv8)." "$C_Y"
  ui_text "Binary dari pihak ketiga: risiko Anda." "$C_Y"
  ui_bottom
  echo
  _need_pkg || return
  ui_confirm "Unduh dan pasang?" || return

  if _ccminer_get; then
    echo
    ui_ok "ccminer terpasang: $("${PREFIX:-/usr/local}/bin/ccminer" -V 2>&1 | head -1)"
  else
    echo
    ui_err "Pemasangan ccminer gagal. Lihat pesan di atas."
  fi
  ui_pause
}

_sha256() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1; }

_ccminer_get() {
  local bindir tmp got
  bindir="${PREFIX:-/usr/local}/bin"
  case "$(uname -m)" in
    aarch64|arm64) ;;
    *) ui_err "Binary ini hanya untuk ARM 64-bit (aarch64), perangkat ini: $(uname -m)."; return 1 ;;
  esac

  ui_info "[1/4] Memasang pustaka yang dibutuhkan..."
  pkg install -y curl libjansson libcurl openssl zlib libc++ || { ui_err "Gagal memasang pustaka."; return 1; }

  ui_info "[2/4] Mengunduh ccminer..."
  mkdir -p "$DATA_DIR"
  tmp="$(mktemp "$DATA_DIR/ccminer.XXXXXX")" || { ui_err "Gagal membuat berkas sementara."; return 1; }
  if ! curl -fL --retry 3 --connect-timeout 15 -o "$tmp" "$CCMINER_URL"; then
    rm -f "$tmp"; ui_err "Gagal mengunduh (cek koneksi internet)."; return 1
  fi

  ui_info "[3/4] Memeriksa SHA-256..."
  got="$(_sha256 "$tmp")"
  if [ "$got" != "$CCMINER_SHA256" ]; then
    rm -f "$tmp"
    ui_err "SHA-256 tidak cocok. Berkas ditolak."
    ui_info "Seharusnya: $CCMINER_SHA256"
    ui_info "Didapat   : ${got:-kosong}"
    return 1
  fi
  ui_ok "SHA-256 cocok."

  ui_info "[4/4] Memasang ke $bindir ..."
  mkdir -p "$bindir"
  if ! install -m 755 "$tmp" "$bindir/ccminer"; then rm -f "$tmp"; ui_err "Gagal menyalin ke $bindir."; return 1; fi
  rm -f "$tmp"
  if ! "$bindir/ccminer" -V >/dev/null 2>&1; then
    ui_warn "ccminer terpasang tetapi gagal dijalankan (pustaka kurang?)."
    ui_info "Coba: pkg install libjansson libcurl openssl zlib libc++"
    return 1
  fi
  return 0
}

# ---------- uninstall ----------

# Lokasi berkas miner di PATH (kosong bila belum terpasang)
_miner_path() {
  local p; p="$(command -v "$1" 2>/dev/null)" || return 1
  [ -n "$p" ] && echo "$p"
}

uninstall_menu() {
  local m p c name
  local -a have=()
  while true; do
    have=()
    ui_head "UNINSTALL MINER"
    for m in xmrig cpuminer ccminer; do
      if p="$(_miner_path "$m")"; then
        have+=("$m")
        ui_row "${#have[@]}" "$m" "terpasang"
      fi
    done
    if [ "${#have[@]}" -eq 0 ]; then
      ui_text "Tidak ada miner yang terpasang."
      ui_bottom
      ui_pause; return
    fi
    ui_row a "Semua" "Hapus semua di atas"
    ui_row 0 "Kembali" "Batal"
    ui_mid
    ui_text "Akun, wallet, dan data MINING tidak" "$C_G"
    ui_text "ikut terhapus." "$C_G"
    ui_bottom
    echo
    ui_ask c "Pilih"
    case "$c" in
      0|"") return ;;
      a|A) ui_confirm "Hapus SEMUA miner di atas?" || continue
           for name in "${have[@]}"; do _uninstall_one "$name"; done
           _clean_build; ui_pause ;;
      *)
        if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le "${#have[@]}" ]; then
          name="${have[$((c-1))]}"
          ui_confirm "Hapus $name?" || continue
          _uninstall_one "$name"; _clean_build; ui_pause
        else
          ui_err "Pilihan tidak valid."
        fi ;;
    esac
  done
}

# Hapus satu miner: lewat 'pkg' bila dipasang sebagai paket, selain itu hapus berkasnya
_uninstall_one() {
  local m="$1" p
  p="$(_miner_path "$m")" || { ui_info "$m tidak ditemukan."; return 0; }
  if command -v dpkg >/dev/null 2>&1 && dpkg -S "$p" >/dev/null 2>&1 && command -v pkg >/dev/null 2>&1; then
    if pkg uninstall -y "$m" >/dev/null 2>&1 || apt-get remove -y "$m" >/dev/null 2>&1; then
      ui_ok "$m dihapus (paket)."; return 0
    fi
    ui_err "Gagal menghapus paket $m."; return 1
  fi
  case "$p" in
    "${PREFIX:-/usr/local}"/bin/*|"$HOME"/*)
      if rm -f -- "$p"; then ui_ok "$m dihapus: $p"; else ui_err "Gagal menghapus $p."; return 1; fi ;;
    *) ui_err "$m ada di $p (di luar PREFIX): hapus manual."; return 1 ;;
  esac
}

# Sisa berkas kompilasi (bila proses sebelumnya terhenti)
_clean_build() {
  [ -d "$DATA_DIR/build" ] || return 0
  rm -rf "$DATA_DIR/build" && ui_ok "Sisa berkas kompilasi dibersihkan."
}

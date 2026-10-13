# Pasang miner & dependensi (khusus Termux)
#
# Catatan: xmrig TIDAK ada di repo paket Termux (termux-main maupun tur-repo),
# jadi "pkg install xmrig" selalu gagal dengan "Unable to locate package".
# Menu ini mengompilasi xmrig dari sumber resminya (github.com/xmrig/xmrig).

XMRIG_REPO="https://github.com/xmrig/xmrig"

install_menu() {
  local c m
  while true; do
    ui_head "PASANG MINER"
    ui_row 1 "Dasar"    "termux-api, curl, git"
    ui_row 2 "xmrig"    "Kompilasi dari sumber"
    ui_row 3 "cpuminer" "Coba pkg / cara manual"
    ui_row 4 "ccminer"  "Verus (petunjuk manual)"
    ui_row 5 "Status"   "Cek miner terpasang"
    ui_row 0 "Kembali"  "Ke menu sebelumnya"
    ui_bottom
    echo
    ui_ask c "Pilih"
    case "$c" in
      1) _inst pkg install -y termux-api curl git ;;
      2) install_xmrig ;;
      3) install_cpuminer ;;
      4)
        ui_head "CCMINER (VERUS)"
        ui_text "Tidak ada di repo resmi Termux."
        ui_text "1. Unduh binary ARM ccminer (fork"
        ui_text "   Verus) dari halaman rilisnya."
        ui_text "2. Taruh di \$PREFIX/bin/ccminer"
        ui_text "3. chmod +x \$PREFIX/bin/ccminer"
        ui_text "4. Pasang Termux:API dari F-Droid"
        ui_text "   untuk pembaca suhu baterai."
        ui_bottom
        ui_pause ;;
      5)
        ui_head "STATUS MINER"
        for m in xmrig cpuminer ccminer termux-api:termux-battery-status; do
          if command -v "${m#*:}" >/dev/null 2>&1; then ui_kv "${m%%:*}" "terpasang" "$C_G"; else ui_kv "${m%%:*}" "belum ada" "$C_R"; fi
        done
        ui_bottom
        ui_pause ;;
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
  jobs=$(( cores > 4 ? 4 : cores ))

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
  rm -rf "$work"
  return 0
}

install_cpuminer() {
  ui_head "PASANG CPUMINER"
  if command -v cpuminer >/dev/null 2>&1; then
    ui_kv "Status" "sudah terpasang" "$C_G"
    ui_bottom
    ui_pause; return
  fi
  ui_bottom
  echo
  if command -v pkg >/dev/null 2>&1; then
    ui_info "Mencoba paket Termux..."
    if pkg install -y cpuminer && command -v cpuminer >/dev/null 2>&1; then
      ui_ok "cpuminer terpasang."
      ui_pause; return
    fi
  else
    ui_err "Perintah 'pkg' tidak ditemukan. Menu ini khusus Termux."
  fi
  echo
  ui_head "CPUMINER: CARA MANUAL"
  ui_text "Paket 'cpuminer' tidak tersedia di"
  ui_text "repo Termux. Cara manual: kompilasi"
  ui_text "cpuminer-opt (JayDDee, Linux ARM64)."
  ui_text "BELUM DIUJI di Termux." "$C_Y"
  ui_mid
  ui_text "pkg install git build-essential \\" "$C_C"
  ui_text "  autoconf automake libtool libcurl \\" "$C_C"
  ui_text "  openssl libjansson libgmp zlib" "$C_C"
  ui_text "git clone https://github.com/JayDDee/\\" "$C_C"
  ui_text "  cpuminer-opt && cd cpuminer-opt" "$C_C"
  ui_text "./build.sh" "$C_C"
  ui_text "cp cpuminer \$PREFIX/bin/" "$C_C"
  ui_bottom
  ui_info "Hanya koin YTN dan MBC (dan koin tak praktis) yang butuh cpuminer."
  ui_pause
}

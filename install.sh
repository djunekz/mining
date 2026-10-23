#!/usr/bin/env bash
set -e

OWNER="djunekz"
NAME="unmineable"
REPO="https://github.com/${OWNER}/${NAME}"
API_LATEST="${UNMINEABLE_RELEASE_API:-https://api.github.com/repos/${OWNER}/${NAME}/releases/latest}"
API_TAG="https://api.github.com/repos/${OWNER}/${NAME}/releases/tags"
APP_HOME="${UNMINEABLE_HOME:-$HOME/.unmineable/app}"
BIN_DIR="${PREFIX:-/usr/local}/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

say() { printf '\033[36m[i]\033[0m %s\n' "$*"; }
good() { printf '\033[32m[✓]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[!]\033[0m %s\n' "$*"; }
bad() { printf '\033[31m[✗]\033[0m %s\n' "$*" >&2; }

usage() {
  cat <<TXT
Pemakaian: bash install.sh [local|release] [tag]

  local            pasang dari folder proyek ini
  release          unduh dan pasang rilis terbaru dari GitHub
  release vX.Y.Z   pasang rilis dengan tag tertentu

Tanpa argumen, akan muncul pilihan interaktif.
TXT
}

has_local() {
  [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/unmineable.sh" ] && [ -d "$SCRIPT_DIR/unmineable" ]
}

install_packages() {
  if command -v pkg >/dev/null 2>&1; then
    say "Memasang paket dasar"
    pkg update -y
    pkg install -y python git curl tar termux-api procps coreutils
  fi
  command -v python3 >/dev/null 2>&1 || { bad "python3 tidak ditemukan"; exit 1; }
  command -v curl >/dev/null 2>&1 || { bad "curl tidak ditemukan"; exit 1; }
}

link_launcher() {
  local root="$1"
  chmod +x "$root/unmineable.sh"
  mkdir -p "$BIN_DIR"
  ln -sf "$root/unmineable.sh" "$BIN_DIR/unmineable"
  good "Terpasang: $BIN_DIR/unmineable"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR belum ada di PATH" ;;
  esac
}

install_local() {
  if ! has_local; then
    bad "Folder proyek tidak ditemukan di sebelah install.sh. Pilih install dari release."
    exit 1
  fi
  say "Install dari lokal: $SCRIPT_DIR"
  link_launcher "$SCRIPT_DIR"
}

parse_release() {
  python3 -c '
import json, sys
data = json.load(sys.stdin)
tag = data.get("tag_name", "")
asset_name = ""
asset_url = ""
sums_url = ""
for item in data.get("assets", []):
    name = item.get("name", "")
    if name.endswith(".tar.gz") and not asset_url:
        asset_name = name
        asset_url = item.get("browser_download_url", "")
    if name == "SHA256SUMS":
        sums_url = item.get("browser_download_url", "")
if not asset_url:
    asset_name = tag + ".tar.gz"
    asset_url = data.get("tarball_url", "")
print(tag)
print(asset_name)
print(asset_url)
print(sums_url)
'
}

install_release() {
  local wanted="${1:-}" endpoint json tag asset url sums tmp expected actual
  if [ -n "$wanted" ]; then
    endpoint="$API_TAG/$wanted"
  else
    endpoint="$API_LATEST"
  fi
  say "Mengambil data rilis dari GitHub"
  if ! json="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$endpoint")"; then
    bad "Gagal mengambil data rilis. Cek koneksi, atau rilis belum dibuat."
    exit 1
  fi
  { read -r tag; read -r asset; read -r url; read -r sums; } < <(printf '%s' "$json" | parse_release)
  if [ -z "$tag" ] || [ -z "$url" ]; then
    bad "Data rilis tidak lengkap"
    exit 1
  fi
  say "Rilis ditemukan: $tag"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  say "Mengunduh $asset"
  curl -fsSL "$url" -o "$tmp/$asset"
  if [ -n "$sums" ]; then
    expected="$(curl -fsSL "$sums" | awk -v f="$asset" '{n=$2; sub(/^\*/, "", n)} n==f {print $1}')"
    if [ -n "$expected" ]; then
      actual="$(sha256sum "$tmp/$asset" | awk '{print $1}')"
      if [ "$expected" != "$actual" ]; then
        bad "Checksum tidak cocok, instalasi dibatalkan"
        exit 1
      fi
      good "Checksum SHA256 cocok"
    else
      warn "Checksum untuk $asset tidak ditemukan, verifikasi dilewati"
    fi
  else
    warn "Rilis tanpa SHA256SUMS, verifikasi dilewati"
  fi
  mkdir -p "$tmp/extract"
  tar -xzf "$tmp/$asset" -C "$tmp/extract" --strip-components=1
  if [ ! -f "$tmp/extract/unmineable.sh" ] || [ ! -d "$tmp/extract/unmineable" ]; then
    bad "Arsip rilis tidak berisi proyek unmineable"
    exit 1
  fi
  mkdir -p "$(dirname "$APP_HOME")"
  rm -rf "$APP_HOME"
  mv "$tmp/extract" "$APP_HOME"
  echo "$tag" > "$APP_HOME/.release"
  good "Rilis $tag dipasang di $APP_HOME"
  link_launcher "$APP_HOME"
}

pick_mode() {
  local choice
  if [ ! -r /dev/tty ]; then
    echo "release"
    return
  fi
  {
    echo
    echo "Pilih cara instalasi:"
    if has_local; then
      echo "  1) Install dari lokal    (pakai folder ini: $SCRIPT_DIR)"
    else
      echo "  1) Install dari lokal    (tidak tersedia, folder proyek tidak ada)"
    fi
    echo "  2) Install dari release  (unduh rilis terbaru dari GitHub)"
    echo
  } > /dev/tty
  read -r -p "Pilih [1/2]: " choice < /dev/tty
  case "$choice" in
    1) echo "local" ;;
    2) echo "release" ;;
    *) echo "invalid" ;;
  esac
}

MODE="${1:-}"
TAG_ARG="${2:-}"

case "$MODE" in
  -h|--help|help) usage; exit 0 ;;
  "") MODE="$(pick_mode)" ;;
esac

case "$MODE" in
  local)
    install_packages
    install_local
    ;;
  release)
    install_packages
    install_release "$TAG_ARG"
    ;;
  *)
    bad "Pilihan tidak valid"
    usage
    exit 1
    ;;
esac

say "Ketik: unmineable"

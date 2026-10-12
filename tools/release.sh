#!/usr/bin/env bash
# =====================================================
#  Menyiapkan rilis: hitung versi baru, tulis VERSION,
#  perbarui CHANGELOG.md dan RELEASE_NOTES.md.
#  TIDAK melakukan commit/tag/push (itu tugas workflow).
#
#    tools/release.sh [auto|patch|minor|major] [--dry-run]
#
#  auto : bump ditentukan dari Conventional Commits sejak tag terakhir.
#         Tanpa tag sama sekali, rilis pertama = isi VERSION apa adanya.
#  Exit 10 = tidak ada perubahan yang perlu dirilis.
# =====================================================
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

mode="${1:-auto}"; dry=0
[ "${2:-}" = "--dry-run" ] && dry=1
case "$mode" in auto|patch|minor|major) ;; *) echo "mode tidak dikenal: $mode" >&2; exit 2 ;; esac

last="$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
current="$(tr -d '[:space:]' < VERSION)"
[[ "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "VERSION bukan semver: '$current'" >&2; exit 2; }
base="${last#v}"; base="${base:-$current}"

bump_version() {
  local a b c
  IFS=. read -r a b c <<<"$1"
  case "$2" in
    major) echo "$((a+1)).0.0" ;;
    minor) echo "$a.$((b+1)).0" ;;
    patch) echo "$a.$b.$((c+1))" ;;
  esac
}

if [ "$mode" = auto ]; then
  if [ -z "$last" ]; then
    new="$current"                      # rilis pertama
  else
    level="$(tools/changelog.sh bump)"
    if [ "$level" = none ]; then echo "Tidak ada perubahan yang perlu dirilis sejak $last."; exit 10; fi
    new="$(bump_version "$base" "$level")"
  fi
else
  new="$(bump_version "$base" "$mode")"
fi

if git rev-parse -q --verify "refs/tags/v$new" >/dev/null; then
  echo "Tag v$new sudah ada." >&2; exit 3
fi

echo "Versi: ${last:-<belum ada tag>} -> v$new"
if [ "$dry" = 1 ]; then
  echo "--- perubahan yang akan dicatat ---"
  tools/changelog.sh body
  exit 0
fi

echo "$new" > VERSION
tools/changelog.sh release "$new"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  { echo "version=$new"; echo "tag=v$new"; } >> "$GITHUB_OUTPUT"
fi
echo "Siap: v$new (VERSION, CHANGELOG.md, RELEASE_NOTES.md diperbarui)."

#!/usr/bin/env bash
# =====================================================
#  Generator CHANGELOG.md dari Conventional Commits.
#
#    tools/changelog.sh unreleased            perbarui blok [Unreleased]
#    tools/changelog.sh release X.Y.Z [TGL]   pindahkan ke versi X.Y.Z
#                                             (+ tulis RELEASE_NOTES.md)
#    tools/changelog.sh bump                  cetak: major|minor|patch|none
#    tools/changelog.sh body                  cetak isi perubahan sejak tag terakhir
#
#  Dipakai oleh workflow changelog.yml dan release.yml.
# =====================================================
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

FILE="CHANGELOG.md"
START='<!-- changelog:unreleased:start -->'
END='<!-- changelog:unreleased:end -->'
NOTES_FILE="RELEASE_NOTES.md"

die() { echo "changelog: $*" >&2; exit 1; }

repo_url() {
  if [ -n "${GITHUB_REPOSITORY:-}" ]; then echo "https://github.com/$GITHUB_REPOSITORY"; return; fi
  local r
  r="$(git config --get remote.origin.url 2>/dev/null || true)"
  r="${r%.git}"; r="${r#git@github.com:}"; r="${r#https://github.com/}"
  if [[ "$r" =~ ^[^/:]+/[^/:]+$ ]]; then echo "https://github.com/$r"; else echo "https://github.com/djunekz/mining"; fi
}

last_tag() { git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true; }

# ---------- baca & klasifikasi commit ----------
declare -A SEC=()
BREAK=0; FEAT=0; PATCH=0
SECTIONS=("Breaking changes" "Added" "Fixed" "Changed" "Documentation" "Maintenance")

collect() {
  local tag range url hash subj body type scope bang desc sect line
  local re='^([a-zA-Z]+)(\(([^)]+)\))?(!)?:[[:space:]]*(.+)$'
  tag="$(last_tag)"; range="HEAD"; [ -n "$tag" ] && range="$tag..HEAD"
  url="$(repo_url)"
  while IFS=$'\x1f' read -r -d $'\x1e' hash subj body; do
    hash="${hash#$'\n'}"
    [ -z "$hash" ] && continue
    case "$subj" in
      "chore(release)"*|"chore(changelog)"*|*"[skip changelog]"*) continue ;;
    esac
    type=""; scope=""; bang=""; desc="$subj"
    if [[ "$subj" =~ $re ]]; then
      type="${BASH_REMATCH[1],,}"; scope="${BASH_REMATCH[3]}"
      bang="${BASH_REMATCH[4]}"; desc="${BASH_REMATCH[5]}"
    fi
    desc="$(printf '%s' "$desc" | sed -E "s|\\(#([0-9]+)\\)|([#\\1]($url/pull/\\1))|g")"
    [ -n "$scope" ] && desc="**$scope:** $desc"
    line="- $desc ([\`$hash\`]($url/commit/$hash))"

    if [ -n "$bang" ] || grep -qE '^BREAKING[ -]CHANGE' <<<"$body"; then
      BREAK=1; SEC["Breaking changes"]+="$line"$'\n'; continue
    fi
    case "$type" in
      feat)                     sect="Added";         FEAT=1 ;;
      fix)                      sect="Fixed";         PATCH=1 ;;
      perf|refactor|revert)     sect="Changed";       PATCH=1 ;;
      docs)                     sect="Documentation" ;;
      ci|build|chore|test|style) sect="Maintenance" ;;
      *)                        sect="Changed";       PATCH=1 ;;
    esac
    SEC["$sect"]+="$line"$'\n'
  done < <(git log --no-merges --format='%h%x1f%s%x1f%b%x1e' "$range")
}

emit_body() {
  local s
  for s in "${SECTIONS[@]}"; do
    if [ -n "${SEC[$s]:-}" ]; then printf '### %s\n\n%s\n' "$s" "${SEC[$s]}"; fi
  done
}

bump_level() {
  if   [ "$BREAK" = 1 ]; then echo major
  elif [ "$FEAT"  = 1 ]; then echo minor
  elif [ "$PATCH" = 1 ]; then echo patch
  else echo none; fi
}

need_markers() {
  [ -f "$FILE" ] || die "$FILE tidak ditemukan"
  grep -qF "$START" "$FILE" && grep -qF "$END" "$FILE" || die "penanda [Unreleased] tidak ada di $FILE"
}

# ---------- perintah ----------
cmd_unreleased() {
  need_markers
  local tmp body
  tmp="$(mktemp)"
  if [ -z "$(last_tag)" ]; then
    printf '\n_Rilis pertama belum dibuat. Perubahan akan dicatat setelah tag pertama ada._\n\n' > "$tmp"
  else
    collect
    body="$(emit_body)"
    if [ -z "$body" ]; then
      printf '\n_Belum ada perubahan sejak rilis terakhir._\n\n' > "$tmp"
    else
      { echo; printf '%s\n' "$body"; echo; } > "$tmp"
    fi
  fi
  inject_unreleased "$tmp"
  rm -f "$tmp"
}

inject_unreleased() {
  local out; out="$(mktemp)"
  awk -v s="$START" -v e="$END" -v f="$1" '
    $0==s { print; skip=1; while ((getline l < f) > 0) print l; next }
    $0==e { skip=0 }
    !skip { print }' "$FILE" > "$out"
  mv "$out" "$FILE"
}

cmd_release() {
  local ver="${1:-}" date="${2:-$(date -u +%F)}" url tag sec out links body
  [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "versi harus X.Y.Z (dapat: '$ver')"
  need_markers
  url="$(repo_url)"; tag="$(last_tag)"

  if grep -q "^## \[$ver\]" "$FILE"; then
    # Catatan versi ini sudah ditulis manual: pakai apa adanya.
    body="$(awk -v v="$ver" 'index($0,"## ["v"]")==1 {p=1; next} /^## \[/ {p=0} p' "$FILE")"
  else
    collect
    body="$(emit_body)"
    [ -n "$body" ] || body=$'### Changed\n\n- Perubahan kecil dan perbaikan internal.\n'
    sec="$(mktemp)"
    { printf '## [%s] - %s\n\n' "$ver" "$date"; printf '%s\n' "$body"; echo; } > "$sec"
    out="$(mktemp)"
    awk -v s="$START" -v e="$END" -v f="$sec" '
      $0==s { print; skip=1; next }
      $0==e { skip=0; print; print ""; while ((getline l < f) > 0) print l; next }
      !skip { print }' "$FILE" > "$out"
    mv "$out" "$FILE"; rm -f "$sec"
  fi

  # kosongkan blok Unreleased
  local empty; empty="$(mktemp)"; printf '\n_Belum ada perubahan sejak rilis terakhir._\n\n' > "$empty"
  inject_unreleased "$empty"; rm -f "$empty"

  # tautan di dasar file
  links="$(grep -E '^\[[0-9]+\.[0-9]+\.[0-9]+\]: ' "$FILE" | grep -v "^\[$ver\]: " || true)"
  out="$(mktemp)"
  grep -vE '^\[(Unreleased|[0-9]+\.[0-9]+\.[0-9]+)\]: ' "$FILE" > "$out" || true
  {
    cat "$out"
    echo "[Unreleased]: $url/compare/v$ver...HEAD"
    echo "[$ver]: $url/releases/tag/v$ver"
    [ -z "$links" ] || echo "$links"
  } | cat -s > "$FILE"
  rm -f "$out"

  # catatan rilis untuk GitHub Release
  {
    printf '%s\n' "$body"
    [ -z "$tag" ] || printf '\n**Full Changelog**: %s/compare/%s...v%s\n' "$url" "$tag" "$ver"
  } > "$NOTES_FILE"
}

case "${1:-}" in
  unreleased) cmd_unreleased ;;
  release)    shift; cmd_release "$@" ;;
  bump)       collect; bump_level ;;
  body)       collect; emit_body ;;
  *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac

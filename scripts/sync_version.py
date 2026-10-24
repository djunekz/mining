#!/usr/bin/env python3
"""Sinkronkan nomor versi di seluruh berkas proyek dengan VERSION di unmineable/constants.py.

Pemakaian:
  python3 scripts/sync_version.py          terapkan perubahan
  python3 scripts/sync_version.py --check  hanya periksa, keluar dengan kode 1 bila ada yang belum sinkron
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO = "https://github.com/djunekz/unmineable"
VER = r"\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?"


def read_version():
    text = (ROOT / "unmineable" / "constants.py").read_text(encoding="utf-8")
    match = re.search(r'^VERSION = "(' + VER + r')"', text, re.MULTILINE)
    if not match:
        sys.exit("VERSION tidak ditemukan atau formatnya tidak valid di unmineable/constants.py")
    return match.group(1)


def rules(version):
    major, minor = version.split(".")[:2]
    series = f"{major}.{minor}"
    return [
        ("README.md", rf"(bash install\.sh release v){VER}", rf"\g<1>{version}"),
        (".github/ISSUE_TEMPLATE/bug_report.yml", rf"(placeholder: unmineable ){VER}", rf"\g<1>{version}"),
        (".github/ISSUE_TEMPLATE/connection_issue.yml", rf"(placeholder: unmineable ){VER}", rf"\g<1>{version}"),
        ("SECURITY.md", r"^\| \d+\.\d+\.x \| ya \|", f"| {series}.x | ya |"),
        ("SECURITY.md", r"^\| di bawah \d+\.\d+\.0 \| tidak \|", f"| di bawah {series}.0 | tidak |"),
        ("CHANGELOG.md", rf"^(\[Unreleased\]: {re.escape(REPO)}/compare/v){VER}(\.\.\.HEAD)", rf"\g<1>{version}\g<2>"),
    ]


def changelog_link(text, version):
    """Pastikan ada tautan [versi]: ... di bagian bawah CHANGELOG."""
    link = f"[{version}]: {REPO}/releases/tag/v{version}"
    if re.search(rf"^\[{re.escape(version)}\]: ", text, re.MULTILINE):
        return text
    unreleased = re.search(r"^\[Unreleased\]: .*$", text, re.MULTILINE)
    if unreleased:
        return text[: unreleased.end()] + "\n" + link + text[unreleased.end():]
    return text.rstrip("\n") + "\n" + link + "\n"


def main(argv):
    check = "--check" in argv
    quiet = "--quiet" in argv
    version = read_version()
    changed = []
    texts = {}
    for name, pattern, replacement in rules(version):
        path = ROOT / name
        if not path.exists():
            print(f"! lewati (tidak ada): {name}")
            continue
        text = texts.get(name)
        if text is None:
            text = path.read_text(encoding="utf-8")
        new = re.sub(pattern, replacement, text, flags=re.MULTILINE)
        texts[name] = new
    if "CHANGELOG.md" in texts:
        texts["CHANGELOG.md"] = changelog_link(texts["CHANGELOG.md"], version)
    for name, new in texts.items():
        path = ROOT / name
        if path.read_text(encoding="utf-8") != new:
            changed.append(name)
            if not check:
                path.write_text(new, encoding="utf-8")

    problems = []
    log = ROOT / "CHANGELOG.md"
    if log.exists() and not re.search(rf"^## \[{re.escape(version)}\]", log.read_text(encoding="utf-8"), re.MULTILINE):
        problems.append(f"CHANGELOG.md belum punya bagian '## [{version}]' (dibutuhkan untuk catatan rilis)")

    if check:
        for name in changed:
            print(f"✗ belum sinkron dengan VERSION {version}: {name}")
        for problem in problems:
            print(f"✗ {problem}")
        if changed or problems:
            print("Jalankan: python3 scripts/sync_version.py")
            return 1
        print(f"✓ semua berkas sinkron dengan VERSION {version}")
        return 0

    if not quiet:
        for name in changed:
            print(f"✓ diperbarui ke {version}: {name}")
        if not changed:
            print(f"✓ sudah sinkron dengan VERSION {version}")
        for problem in problems:
            print(f"! {problem}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

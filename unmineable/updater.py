from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import tarfile
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

from . import api, guard, paths, system, ui
from . import constants as C

PACKAGE = "unmineable"
ROOT_FILES = ("unmineable.sh", "install.sh", "README.md", "LICENSE", ".gitignore")


def project_root():
    return Path(__file__).resolve().parent.parent


def install_kind(root=None):
    root = root or project_root()
    return "git" if (root / ".git").exists() and system.which("git") else "arsip"


def parse_version(text):
    return tuple(int(part) for part in re.findall(r"\d+", str(text))[:3])


def is_newer(candidate, current=C.VERSION):
    return parse_version(candidate) > parse_version(current)


def latest_release(timeout=15):
    data = api.get_json(C.RELEASES_API, timeout=timeout)
    if not isinstance(data, dict) or not data.get("tag_name"):
        return None
    assets = data.get("assets") or []
    archive = next((a for a in assets if str(a.get("name", "")).endswith(".tar.gz")), None)
    sums = next((a for a in assets if a.get("name") == "SHA256SUMS"), None)
    tag = str(data["tag_name"])
    return {
        "tag": tag,
        "version": tag.lstrip("vV"),
        "notes": data.get("body") or "",
        "url": (archive or {}).get("browser_download_url") or data.get("tarball_url"),
        "name": (archive or {}).get("name") or f"{tag}.tar.gz",
        "sums": (sums or {}).get("browser_download_url"),
        "page": data.get("html_url") or C.RELEASES_PAGE,
    }


def _read_cache():
    try:
        return json.loads(paths.UPDATE_CACHE.read_text())
    except (OSError, ValueError):
        return None


def _write_cache(version):
    try:
        paths.ensure()
        paths.UPDATE_CACHE.write_text(json.dumps({"t": time.time(), "version": version}))
    except OSError:
        pass


def notice():
    cache = _read_cache()
    stale = cache is None or time.time() - float(cache.get("t", 0)) > C.UPDATE_CHECK_HOURS * 3600
    if stale:
        info = latest_release(timeout=4)
        version = info["version"] if info else (cache or {}).get("version", "")
        _write_cache(version)
    else:
        version = cache.get("version", "")
    if version and is_newer(version):
        return version
    return None


def pkg_installed_version():
    """Versi paket `unmineable` yang terpasang lewat dpkg/pkg, atau None bila tidak terpasang lewat pkg."""
    if not system.which("dpkg-query"):
        return None
    code, out = system.run(["dpkg-query", "-W", "-f=${Status}|${Version}", PACKAGE], timeout=15)
    if code != 0:
        return None
    status, _, version = out.partition("|")
    if "install ok installed" not in status or not version.strip():
        return None
    return version.strip()


def pkg_candidate_version():
    """Versi terbaru yang ada di daftar paket (sesuai index terakhir), atau None bila tidak ada di repo."""
    if not system.which("apt-cache"):
        return None
    code, out = system.run(["apt-cache", "policy", PACKAGE], timeout=20)
    if code != 0:
        return None
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("Candidate:"):
            value = line.split(":", 1)[1].strip()
            return None if value in ("", "(none)") else value
    return None


def version_newer(candidate, installed):
    """True hanya bila candidate benar-benar lebih baru dari installed."""
    if candidate == installed:
        return False
    if system.which("dpkg"):
        code, _ = system.run(["dpkg", "--compare-versions", candidate, "gt", installed], timeout=10)
        return code == 0
    try:
        return parse_version(candidate) > parse_version(installed)
    except (TypeError, ValueError):
        return False


def pkg_status(refresh=False):
    """Bandingkan versi terpasang dengan versi di repo. refresh=True menjalankan `pkg update`
    (hanya menyegarkan daftar paket, tidak meng-upgrade apa pun)."""
    installed = pkg_installed_version()
    if installed is None:
        return None
    refreshed = None
    if refresh and system.which("pkg"):
        refreshed = ui.run_command_panel("Menyegarkan daftar paket", ["pkg", "update", "-y"]) == 0
    candidate = pkg_candidate_version()
    return {
        "installed": installed,
        "candidate": candidate,
        "newer": bool(candidate and version_newer(candidate, installed)),
        "refreshed": refreshed,
    }


def update_pkg(assume_yes=False):
    status = pkg_status(refresh=True)
    if status is None:
        ui.fail("Paket unmineable tidak terpasang lewat pkg.")
        return False
    if status["refreshed"] is False:
        ui.warn("Gagal menyegarkan daftar paket, memakai daftar yang tersimpan (mungkin sudah usang).")
    if not status["candidate"]:
        ui.warn("Paket unmineable tidak ditemukan di repo pkg yang aktif.")
        ui.info(f"Terpasang: {status['installed']}. Tidak ada yang di-upgrade.")
        return False
    if not status["newer"]:
        ui.ok(f"Sudah versi terbaru ({status['installed']}). Tidak menjalankan upgrade.")
        return True
    ui.warn(f"Versi baru di repo: {status['candidate']} (terpasang {status['installed']})")
    if not assume_yes and not ui.confirm(f"Perbarui {status['installed']} ke {status['candidate']}?", True):
        return False
    # --only-upgrade: hanya paket unmineable yang diperbarui, bukan seluruh paket Termux.
    code = ui.run_command_panel("Memperbarui unmineable", ["apt", "install", "--only-upgrade", "-y", PACKAGE])
    if code != 0:
        ui.fail("Upgrade lewat pkg gagal. Coba jalankan manual: pkg update lalu pkg install unmineable")
        return False
    ui.ok("Pembaruan selesai")
    if guard.is_running():
        ui.info("Mining masih memakai versi lama. Jalankan: unmineable restart")
    ui.info("Buka ulang unmineable untuk memakai versi baru")
    return True


def show_notes(info):
    lines = [line.strip() for line in info["notes"].splitlines() if line.strip()][:12]
    limit = ui.term_width() - 6
    body = [line[:limit] for line in lines] or ["Tidak ada catatan rilis."]
    ui.box(f"Rilis {info['tag']}", body + ["", info["page"][:limit]], ui.GREEN)


def check():
    status = pkg_status()
    if status is not None:
        if not status["candidate"]:
            ui.info(f"Terpasang lewat pkg ({status['installed']}), paket belum ada di repo aktif.")
        elif status["newer"]:
            ui.warn(f"Versi baru di repo pkg: {status['candidate']} (terpasang {status['installed']}). Jalankan: unmineable update")
        else:
            ui.ok(f"Sudah versi terbaru di repo pkg ({status['installed']})")
        return status
    with ui.Spinner("Memeriksa rilis terbaru di GitHub"):
        info = latest_release()
    if not info:
        ui.fail("Tidak bisa mengambil data rilis. Cek koneksi atau belum ada rilis di GitHub.")
        return None
    _write_cache(info["version"])
    if is_newer(info["version"]):
        ui.warn(f"Versi baru tersedia: {info['version']} (terpasang {C.VERSION})")
        show_notes(info)
    else:
        ui.ok(f"Sudah versi terbaru ({C.VERSION})")
    return info


def download(url, target):
    request = urllib.request.Request(url, headers={"User-Agent": api.USER_AGENT})
    with urllib.request.urlopen(request, timeout=90) as response, open(target, "wb") as handle:
        shutil.copyfileobj(response, handle)


def verify(info, archive_path):
    if not info or not info.get("sums"):
        ui.warn("Rilis tanpa berkas SHA256SUMS, verifikasi checksum dilewati.")
        return True
    body = api.get_text(info["sums"])
    expected = None
    for line in (body or "").splitlines():
        parts = line.split()
        if len(parts) == 2 and parts[1].lstrip("*") == info["name"]:
            expected = parts[0].lower()
    if not expected:
        ui.warn("Checksum arsip tidak ditemukan di SHA256SUMS, verifikasi dilewati.")
        return True
    actual = hashlib.sha256(Path(archive_path).read_bytes()).hexdigest()
    if actual != expected:
        ui.fail("Checksum tidak cocok, pembaruan dibatalkan.")
        return False
    ui.ok("Checksum SHA256 cocok")
    return True


def _safe_extract(archive, destination):
    root = Path(destination).resolve()
    for member in archive.getmembers():
        target = (root / member.name).resolve()
        if root not in target.parents and target != root:
            raise ValueError("arsip tidak aman")
        if member.issym() or member.islnk():
            raise ValueError("arsip berisi tautan, ditolak")
    try:
        archive.extractall(destination, filter="data")
    except TypeError:
        archive.extractall(destination)


def apply_archive(archive_path, root):
    with tempfile.TemporaryDirectory() as workspace:
        with tarfile.open(archive_path) as archive:
            _safe_extract(archive, workspace)
        folders = sorted(p for p in Path(workspace).iterdir() if p.is_dir())
        if not folders:
            raise ValueError("arsip kosong")
        source = folders[0]
        if not (source / PACKAGE / "__init__.py").exists():
            raise ValueError("arsip bukan paket unmineable")
        staged = root / f"{PACKAGE}.new"
        shutil.rmtree(staged, ignore_errors=True)
        shutil.copytree(source / PACKAGE, staged)
        shutil.rmtree(root / PACKAGE, ignore_errors=True)
        os.rename(staged, root / PACKAGE)
        for name in ROOT_FILES:
            if (source / name).exists():
                shutil.copy2(source / name, root / name)


def update_archive(root, channel, info):
    if channel == "release":
        url, name = info["url"], info["name"]
    else:
        url, name = C.TARBALL_URL, "main.tar.gz"
    if not url:
        ui.fail("Rilis tidak punya arsip yang bisa diunduh.")
        return False
    with tempfile.TemporaryDirectory() as workspace:
        target = Path(workspace) / name
        try:
            with ui.Spinner("Mengunduh pembaruan"):
                download(url, target)
            if channel == "release" and not verify(info, target):
                return False
            apply_archive(target, root)
        except (urllib.error.URLError, OSError, tarfile.TarError, ValueError) as error:
            ui.fail(f"Gagal memperbarui: {error}")
            return False
    return True


def update_git(root, channel, info):
    ui.info("Instalasi berupa git clone, memperbarui lewat git")
    code, out = system.run(["git", "-C", str(root), "fetch", "--tags", "--force"], timeout=180)
    if code != 0:
        ui.fail(f"git fetch gagal: {out}")
        return False
    if channel == "release":
        code, out = system.run(["git", "-C", str(root), "checkout", "--quiet", f"tags/{info['tag']}"], timeout=60)
    else:
        code, out = system.run(["git", "-C", str(root), "checkout", "--quiet", "main"], timeout=60)
        if code == 0:
            code, out = system.run(["git", "-C", str(root), "pull", "--ff-only"], timeout=180)
    if code != 0:
        ui.fail(f"git gagal: {out}")
        return False
    return True


def update(channel="auto", assume_yes=False):
    if channel == "auto":
        channel = "pkg" if pkg_installed_version() is not None else "release"
    if channel == "pkg":
        return update_pkg(assume_yes)
    root = project_root()
    info = None
    if channel == "release":
        with ui.Spinner("Memeriksa rilis terbaru di GitHub"):
            info = latest_release()
        if not info:
            ui.fail("Tidak bisa mengambil data rilis. Cek koneksi atau belum ada rilis di GitHub.")
            return False
        if not is_newer(info["version"]):
            ui.ok(f"Sudah versi terbaru ({C.VERSION})")
            return True
        show_notes(info)
        question = f"Perbarui {C.VERSION} ke {info['version']}?"
    else:
        question = "Perbarui ke commit terbaru branch main (versi dev)?"
    if not assume_yes and not ui.confirm(question, True):
        return False
    if install_kind(root) == "git":
        done = update_git(root, channel, info)
    else:
        done = update_archive(root, channel, info)
    if not done:
        return False
    _write_cache(info["version"] if info else C.VERSION)
    ui.ok("Pembaruan selesai")
    if guard.is_running():
        ui.info("Mining masih memakai versi lama. Jalankan: unmineable restart")
    ui.info("Buka ulang unmineable untuk memakai versi baru")
    return True

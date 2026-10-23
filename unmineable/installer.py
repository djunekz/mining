from __future__ import annotations

import os
import shutil

from . import constants as C
from . import paths, system, ui

DEPENDENCIES = (
    "python",
    "curl",
    "git",
    "cmake",
    "make",
    "clang",
    "libuv",
    "openssl",
    "termux-api",
    "procps",
    "coreutils",
)


VERSION_CACHE = {}


def run_live(command, title, cwd=None):
    return ui.run_command_panel(title, command, cwd=cwd)


def xmrig_path():
    found = system.which("xmrig")
    if found:
        return found
    local = paths.BIN_DIR / "xmrig"
    if local.exists() and os.access(local, os.X_OK):
        return str(local)
    return None


def xmrig_version(binary=None):
    binary = binary or xmrig_path()
    if not binary:
        return None
    if binary in VERSION_CACHE:
        return VERSION_CACHE[binary]
    code, out = system.run([binary, "--version"], timeout=10)
    if code != 0 or not out:
        return None
    VERSION_CACHE[binary] = out.splitlines()[0].strip()
    return VERSION_CACHE[binary]


def xmrig_ready(deep=False):
    binary = xmrig_path()
    if not binary:
        return False
    if not deep:
        return True
    return xmrig_version(binary) is not None


def supports_http(binary=None):
    binary = binary or xmrig_path()
    if not binary:
        return False
    _, out = system.run([binary, "--help"], timeout=10)
    return "--http-port" in out


def install_dependencies():
    if not system.which("pkg"):
        ui.warn("Perintah pkg tidak ditemukan (bukan Termux).")
        ui.info("Pasang manual: " + " ".join(DEPENDENCIES))
        return False
    run_live(["pkg", "update", "-y"], "Memperbarui daftar paket")
    return run_live(["pkg", "install", "-y", *DEPENDENCIES], "Memasang dependensi") == 0


def build_from_source():
    if system.disk_free_mb() < 1200:
        ui.warn("Ruang penyimpanan kurang dari 1.2 GB, build mungkin gagal.")
    ui.warn("Build dari source bisa memakan 10-30 menit. Jaga HP tetap menyala dan dingin.")
    target = paths.SRC_DIR / "xmrig"
    shutil.rmtree(target, ignore_errors=True)
    paths.ensure()
    if run_live(["git", "clone", "--depth", "1", C.XMRIG_REPO, str(target)], "Build XMRig [1/3] mengunduh source") != 0:
        return False
    build = target / "build"
    build.mkdir(parents=True, exist_ok=True)
    flags = [
        "cmake",
        "..",
        "-DCMAKE_BUILD_TYPE=Release",
        "-DWITH_HWLOC=OFF",
        "-DWITH_OPENCL=OFF",
        "-DWITH_CUDA=OFF",
    ]
    if run_live(flags, "Build XMRig [2/3] konfigurasi cmake", cwd=str(build)) != 0:
        return False
    jobs = max(1, system.cpu_count() // 2)
    if run_live(["make", f"-j{jobs}"], "Build XMRig [3/3] kompilasi (10-30 menit)", cwd=str(build)) != 0:
        return False
    built = build / "xmrig"
    if not built.exists():
        return False
    destination = paths.BIN_DIR / "xmrig"
    shutil.copy2(built, destination)
    os.chmod(destination, 0o755)
    return True


def install_xmrig(force=False):
    if xmrig_path() and not force:
        ui.ok(f"XMRig sudah terpasang: {xmrig_path()}")
        return True
    if not system.which("pkg"):
        ui.fail("Pasang XMRig manual lalu jalankan ulang.")
        return False
    if run_live(["pkg", "install", "-y", "xmrig"], "Pasang XMRig [1/3] repo Termux") == 0 and system.which("xmrig"):
        ui.ok("XMRig terpasang dari repo Termux")
        return True
    if run_live(["pkg", "install", "-y", "tur-repo"], "Pasang XMRig [2/3] tur-repo") == 0:
        if run_live(["pkg", "install", "-y", "xmrig"], "Pasang XMRig [2/3] dari tur-repo") == 0 and system.which("xmrig"):
            ui.ok("XMRig terpasang dari tur-repo")
            return True
    if build_from_source():
        ui.ok(f"XMRig berhasil di-build: {paths.BIN_DIR / 'xmrig'}")
        return True
    ui.fail("Instalasi XMRig gagal")
    return False


def install_all():
    paths.ensure()
    install_dependencies()
    done = install_xmrig()
    if done:
        version = xmrig_version()
        if version:
            ui.info(version)
        if not supports_http():
            ui.warn("Build XMRig ini tanpa HTTP API, hashrate live tidak tersedia.")
    if not system.which("termux-battery-status"):
        ui.warn("Pasang aplikasi Termux:API agar proteksi suhu dan baterai aktif.")
    return done

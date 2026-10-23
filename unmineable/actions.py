from __future__ import annotations

import shutil
import sys

from . import boot, config, guard, installer, logs, miner, paths, profiles, stats, system, ui


def interactive():
    return sys.stdin.isatty() and sys.stdout.isatty()


def ensure_login(allow_prompt):
    profile = config.active()
    if profile.session_ok():
        return profile
    ui.fail("Belum login ke unMineable. Mining tidak bisa dimulai sebelum login.")
    if allow_prompt and ui.confirm("Login sekarang?", True):
        profile = profiles.wizard(profile)
        return profile if profile.session_ok() else None
    return None


def ensure_xmrig(allow_prompt):
    if installer.xmrig_ready(deep=True):
        return True
    if installer.xmrig_path():
        ui.fail("XMRig ditemukan tetapi tidak bisa dijalankan (arsitektur tidak cocok atau rusak).")
    else:
        ui.fail("XMRig tidak terdeteksi di Termux ini. Mining tidak bisa dimulai sebelum XMRig terpasang.")
    if allow_prompt and ui.confirm("Pasang XMRig sekarang?", True):
        installer.install_all()
        return installer.xmrig_ready(deep=True)
    return False


def preflight(allow_prompt=True):
    allow_prompt = allow_prompt and interactive()
    profile = ensure_login(allow_prompt)
    if profile is None:
        return None
    if not ensure_xmrig(allow_prompt):
        return None
    problems = profile.problems()
    if problems:
        for problem in problems:
            ui.fail(problem)
        return None
    return profile


def start(quiet=False):
    profile = preflight(allow_prompt=not quiet)
    if profile is None:
        return False
    if guard.is_running():
        if not quiet:
            ui.ok("Mining sudah berjalan di background")
        return True
    if not guard.start_background():
        ui.fail(f"Guard gagal start. Lihat {paths.GUARD_LOG}")
        return False
    if not quiet:
        ui.ok("Mining dimulai di background dengan guard suhu & baterai")
        ui.info("unmineable status   untuk melihat hashrate")
        ui.info("unmineable sync     untuk memastikan pool dan website terhubung")
        ui.info("unmineable stop     untuk berhenti")
    return True


def stop():
    if not guard.is_running() and not miner.is_running():
        ui.info("Mining tidak sedang berjalan")
        return
    with ui.Spinner("Menghentikan mining"):
        guard.stop_background()
    ui.ok("Mining dihentikan")


def restart():
    stop()
    return start()


def foreground():
    profile = preflight()
    if profile is None:
        return
    if guard.is_running():
        ui.warn("Mining background sedang berjalan. Hentikan dulu agar tidak dobel.")
        return
    miner.run_foreground(profile)


def status():
    stats.dashboard(config.active())


def install():
    return installer.install_all()


def reinstall_xmrig():
    return installer.install_xmrig(force=True)


def login_toggle():
    profile = config.active()
    if profile.logged_in:
        profiles.show(profile, brief=True)
        print()
        if ui.confirm("Logout dari akun ini?", False):
            profiles.logout()
        return
    profiles.wizard(profile)


def quickstart():
    ui.banner()
    ui.step(1, 3, "Login ke unMineable")
    profile = config.active()
    if profile.session_ok():
        ui.ok(f"Sudah login: {profile.display_id()}")
    else:
        profile = profiles.wizard(profile)
        if not profile.session_ok():
            return
    ui.step(2, 3, "Memeriksa XMRig")
    if not ensure_xmrig(True):
        return
    ui.ok("XMRig terdeteksi")
    ui.step(3, 3, "Mulai mining")
    if ui.confirm("Mulai mining sekarang?", True):
        start()


def uninstall():
    if not ui.confirm("Hentikan mining dan hapus tool ini?", False):
        return
    stop()
    boot.disable()
    if ui.confirm("Hapus semua konfigurasi, profil, dan log?", False):
        shutil.rmtree(paths.CONFIG_DIR, ignore_errors=True)
    if ui.confirm("Hapus XMRig hasil build dan source?", False):
        shutil.rmtree(paths.DATA_DIR, ignore_errors=True)
    if paths.LAUNCHER.exists() or paths.LAUNCHER.is_symlink():
        system.remove(paths.LAUNCHER)
        ui.ok("Launcher dihapus")
    ui.ok("Uninstall selesai")


def follow_log():
    logs.follow(paths.MINER_LOG)

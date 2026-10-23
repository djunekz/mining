from __future__ import annotations

import sys

from . import boot, config, guard, installer, system, ui
from . import constants as C

ICONS = {
    "ok": lambda: ui.paint("✓", ui.GREEN, ui.BOLD),
    "warn": lambda: ui.paint("!", ui.YELLOW, ui.BOLD),
    "fail": lambda: ui.paint("✗", ui.RED, ui.BOLD),
}


def checks(profile):
    rows = []

    def add(name, state, detail):
        rows.append((name, state, detail))

    add("Lingkungan", "ok" if system.is_termux() else "warn", "Termux" if system.is_termux() else "Bukan Termux")
    add("Python", "ok" if sys.version_info >= (3, 8) else "fail", sys.version.split()[0])
    add("Arsitektur", "ok", system.cpu_model() + f" · {system.cpu_count()} core")

    memory = system.mem_total_mb()
    add("RAM", "ok" if memory >= 3000 else "warn", f"{memory} MB total")

    disk = system.disk_free_mb()
    add("Penyimpanan", "ok" if disk >= 1500 else "warn", f"{disk} MB bebas")

    add("Login", "ok" if profile.session_ok() else "fail", f"login sejak {profile.login_time or '-'}" if profile.session_ok() else "belum login, mining tidak bisa dimulai")

    binary = installer.xmrig_path()
    if binary:
        runnable = installer.xmrig_ready(deep=True)
        add("XMRig", "ok" if runnable else "fail", f"{installer.xmrig_version(binary)} · {binary}" if runnable else f"{binary} ditemukan tetapi tidak bisa dijalankan")
        add("HTTP API XMRig", "ok" if installer.supports_http(binary) else "warn", "hashrate live" if installer.supports_http(binary) else "tidak didukung build ini")
    else:
        add("XMRig", "fail", "tidak terdeteksi, mining tidak bisa dimulai")

    battery = system.battery()
    if battery:
        add("Termux:API", "ok", f"baterai {battery['percent']}% · {battery['temp']}°C")
    else:
        add("Termux:API", "warn", "tidak tersedia, proteksi suhu/baterai nonaktif")

    add("Wake-lock", "ok" if system.which("termux-wake-lock") else "warn", "tersedia" if system.which("termux-wake-lock") else "tidak ada")

    endpoint_rows = []
    for host, port, tls in profile.endpoints():
        reachable, latency = system.tcp_check(host, port, timeout=5.0)
        endpoint_rows.append((config.endpoint_url(host, port, tls), reachable, latency))
    working = [row for row in endpoint_rows if row[1]]
    detail = ", ".join(f"{label} {ms}ms" for label, _, ms in working) or "semua endpoint pool tidak terjangkau"
    add("Pool", "ok" if working else "fail", detail)
    add("Mode akun", "ok", "alias akun website" if profile.mode == "alias" else "alamat dompet (legacy)")

    site, _ = system.tcp_check("unmineable.com", 443)
    add("Website", "ok" if site else "fail", "unmineable.com terjangkau" if site else "unmineable.com tidak terjangkau")

    endpoint, _ = system.tcp_check("api.unmineable.com", 443)
    add("API unMineable", "ok" if endpoint else "warn", "terjangkau" if endpoint else "tidak terjangkau")

    problems = profile.problems()
    add("Profil", "ok" if not problems else "warn", f"{profile.name} siap" if not problems else "; ".join(problems))
    add("Guard", "ok" if guard.is_running() else "warn", "aktif" if guard.is_running() else "mati")
    add("Autostart", "ok" if boot.enabled() else "warn", "aktif" if boot.enabled() else "nonaktif")
    return rows


def advice(profile):
    tips = []
    memory = system.mem_total_mb()
    cores = system.cpu_count()
    if 0 < memory < 3000 and profile.rx_mode != "light":
        tips.append("RAM kurang dari 3 GB: gunakan mode RandomX light di Pengaturan > Performa.")
    if profile.threads == 0 and cores >= 8:
        tips.append(f"Core banyak ({cores}): thread otomatis memakai setengahnya, naikkan manual bila HP kuat menahan panas.")
    if not system.which("termux-battery-status"):
        tips.append("Pasang app Termux:API agar auto-pause saat panas aktif.")
    if profile.donate == 0:
        tips.append("Donate level 0 dipilih, XMRig tidak menyisihkan waktu untuk pengembangnya.")
    return tips


def render(profile):
    rows = checks(profile)
    lines = []
    for name, state, detail in rows:
        lines.append(f"{ICONS[state]()} {ui.paint(name.ljust(16), ui.BOLD)}{detail}")
    ui.box("Diagnosa", lines, ui.CYAN)
    tips = advice(profile)
    if tips:
        ui.box("Saran", tips, ui.YELLOW)
    failed = sum(1 for _, state, _ in rows if state == "fail")
    warned = sum(1 for _, state, _ in rows if state == "warn")
    print()
    if failed:
        ui.fail(f"{failed} masalah kritis, {warned} peringatan")
    elif warned:
        ui.warn(f"Tidak ada masalah kritis, {warned} peringatan")
    else:
        ui.ok("Semua pemeriksaan lolos")
    print(ui.paint(f"{C.APP_NAME} v{C.VERSION}", ui.GRAY))

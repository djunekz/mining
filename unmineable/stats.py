from __future__ import annotations

import time

from . import api, config, connection, guard, history, installer, logs, miner, paths, system, ui


def battery_text(battery):
    if not battery:
        return ui.paint("tidak tersedia (pasang Termux:API)", ui.GRAY)
    parts = []
    if battery.get("percent") is not None:
        parts.append(f"{battery['percent']}%")
    if battery.get("temp") is not None:
        parts.append(f"{battery['temp']:.1f}°C")
    if battery.get("status"):
        parts.append(battery["status"].lower())
    if battery.get("stale"):
        parts.append("(terakhir diketahui)")
    elif battery.get("source") == "sysfs":
        parts.append("(sysfs)")
    return " · ".join(parts) or "-"


def state_text(active, on="aktif", off="mati"):
    return ui.paint(on, ui.GREEN, ui.BOLD) if active else ui.paint(off, ui.RED)


def status_lines(profile):
    running = miner.is_running()
    ready = installer.xmrig_ready()
    version = installer.xmrig_version() if ready else None
    if profile.logged_in:
        login = ui.paint("ya", ui.GREEN, ui.BOLD) + (f" · {profile.login_time}" if profile.login_time else "")
    else:
        login = ui.paint("belum login", ui.RED, ui.BOLD)
    if ready:
        xmrig = ui.paint(version or "terdeteksi", ui.GREEN)
    else:
        xmrig = ui.paint("tidak terdeteksi", ui.RED, ui.BOLD)
    endpoint = config.endpoint_url(profile.host, profile.port, profile.tls)
    pairs = [
        ("Akun", f"{profile.name} · {profile.display_id()}"),
        ("Login", login),
        ("XMRig", xmrig),
        ("Pool", endpoint + ("  +cadangan" if profile.failover else "")),
        ("Mining", f"{state_text(running, 'berjalan', 'berhenti')} · guard {state_text(guard.is_running())}"),
        ("Baterai", battery_text(system.battery())),
    ]
    if running:
        summary = api.miner_summary()
        if summary:
            pairs.append(("Hashrate", ui.paint(ui.human_rate(summary["h10"]), ui.CYAN, ui.BOLD)))
    return ui.kv(pairs)


def status_compact(profile):
    login = ui.paint("login ✓", ui.GREEN) if profile.logged_in else ui.paint("belum login", ui.RED, ui.BOLD)
    xmrig = ui.paint("XMRig ✓", ui.GREEN) if installer.xmrig_ready() else ui.paint("XMRig ✗", ui.RED, ui.BOLD)
    mining = ui.paint("mining ●", ui.GREEN) if miner.is_running() else ui.paint("mining ○", ui.GRAY)
    return f"{login} · {xmrig} · {mining}"


def hashrate_lines(summary):
    accepted = summary["shares_good"]
    total = summary["shares_total"]
    pairs = [
        ("10 detik", ui.human_rate(summary["h10"])),
        ("60 detik", ui.human_rate(summary["h60"])),
        ("15 menit", ui.human_rate(summary["h15"])),
        ("Puncak", f"{ui.human_rate(summary['highest'])}  {ui.bar(summary['h10'], summary['highest'], 14)}"),
        ("Share", f"{accepted} diterima / {total} total"),
        ("Kesulitan", str(summary["diff"])),
        ("Ping pool", f"{summary['ping']} ms"),
        ("Thread", str(summary["threads"])),
        ("Uptime", ui.human_duration(summary["uptime"])),
        ("Versi", str(summary["version"]) or "-"),
    ]
    return ui.kv(pairs)


def history_lines(entries):
    stats = history.summary(entries)
    spark = ui.sparkline([e.get("h10", 0) for e in entries], 50)
    lines = [ui.paint(spark, ui.CYAN)]
    if stats:
        lines.extend(
            ui.kv(
                [
                    ("Rata-rata", ui.human_rate(stats["avg"])),
                    ("Tertinggi", ui.human_rate(stats["max"])),
                    ("Terendah", ui.human_rate(stats["min"])),
                    ("Sampel", f"{stats['count']} dalam {ui.human_duration(stats['span'])}"),
                ]
            )
        )
    return lines


def dashboard_boxes(profile):
    boxes = [ui.box_lines("Status", status_lines(profile), ui.CYAN)]
    needs = []
    if not profile.session_ok():
        needs.append("Belum login. Buka menu Login untuk mulai.")
    if not installer.xmrig_ready():
        needs.append("XMRig tidak terdeteksi. Buka Instalasi & pembaruan.")
    if needs:
        boxes.append(ui.box_lines("Perlu tindakan", needs, ui.RED))
    running = miner.is_running()
    summary = api.miner_summary() if running else None
    if summary:
        boxes.append(ui.box_lines("Hashrate live", hashrate_lines(summary), ui.GREEN))
    elif running:
        boxes.append(ui.box_lines("Hashrate live", ["Menunggu data dari XMRig..."], ui.YELLOW))
    findings = connection.log_findings()
    if findings["status"] != "kosong":
        tone = ui.GREEN if findings["status"] == "ok" else (ui.RED if findings["status"] == "error" else ui.YELLOW)
        boxes.append(ui.box_lines("Koneksi pool", connection.finding_lines(findings), tone))
    entries = history.load(60)
    if entries:
        boxes.append(ui.box_lines("Riwayat hashrate", history_lines(entries), ui.MAGENTA))
    limit = ui.term_width() - 6
    tail = [line[:limit] for line in logs.tail(paths.MINER_LOG, 5)]
    if tail:
        boxes.append(ui.box_lines("Log XMRig terakhir", tail, ui.BLUE))
    return boxes


def dashboard(profile):
    for lines in dashboard_boxes(profile):
        print("\n".join(lines))


def watch(interval=3.0):
    try:
        while True:
            budget = max(8, ui.screen_rows() - 2)
            lines = ui.banner_lines(compact=True)
            for box in dashboard_boxes(config.active()):
                if len(lines) + len(box) <= budget - 1:
                    lines.extend(box)
            lines.append(ui.paint("Ctrl+C untuk kembali · refresh 3 detik", ui.GRAY))
            ui.clear()
            print("\n".join(lines[:budget]))
            time.sleep(interval)
    except KeyboardInterrupt:
        print()


def flatten(node, prefix=""):
    rows = []
    if isinstance(node, dict):
        for key, value in node.items():
            rows.extend(flatten(value, f"{prefix}{key}."))
    elif isinstance(node, list):
        rows.append((prefix.rstrip("."), f"{len(node)} item"))
    else:
        rows.append((prefix.rstrip("."), str(node)))
    return rows


def account_view(profile):
    if not profile.ready():
        ui.warn("Profil belum lengkap. Atur akun atau dompet dulu.")
        return
    if profile.mode == "alias":
        ui.warn("Mode alias: API publik hanya untuk alamat. Lihat saldo dan worker di website setelah login.")
        ui.info(connection.dashboard_url(profile))
        return
    with ui.Spinner("Mengambil data akun dari API unMineable"):
        info = api.address_info(profile)
        uuid = (info or {}).get("uuid")
        stats = api.account_stats(uuid) if uuid else None
        workers = api.account_workers(uuid) if uuid else None
        payments = api.account_payments(uuid) if uuid else None
    if not info:
        ui.fail("Gagal mengambil data. Cek koneksi, koin, dan alamat. Detail lengkap ada di website.")
        return
    pairs = [
        ("Alamat", str(info.get("address", "-"))),
        ("Jaringan", str(info.get("network", "-"))),
        ("Saldo pending", str(info.get("balance", "-"))),
        ("Ambang bayar", str(info.get("payment_threshold", "-"))),
        ("Fee mining", f"{info.get('mining_fee', '-')}%"),
        ("Bayar otomatis", "aktif" if info.get("auto") else "mati"),
        ("Pembayaran", "normal" if info.get("enabled", True) else "sedang maintenance"),
        ("Alamat baru", "ya (belum pernah mining)" if info.get("fresh") else "tidak"),
    ]
    if stats:
        rewarded = stats.get("rewarded") or {}
        pairs.extend(
            [
                ("Reward 24 jam", str(rewarded.get("past_24h", "-"))),
                ("Reward 7 hari", str(rewarded.get("past_7d", "-"))),
                ("Total dibayar", str(stats.get("paid", "-"))),
            ]
        )
    ui.box("Akun di website", ui.kv(pairs, 15), ui.GREEN)
    rows = []
    for group in (workers or {}).values():
        if not isinstance(group, dict):
            continue
        for worker in group.get("workers") or []:
            mark = ui.paint("online", ui.GREEN) if worker.get("online") else ui.paint("offline", ui.YELLOW)
            rows.append((worker.get("name", "-"), mark, ui.human_rate(worker.get("chr") or 0), connection.format_time(worker.get("last"))))
    if rows:
        ui.table(("Worker", "Status", "Hashrate", "Terakhir aktif"), rows)
    else:
        ui.warn("Belum ada worker terdaftar di website untuk alamat ini.")
    listing = ((payments or {}).get("list")) or []
    if listing:
        print()
        ui.table(("Jumlah", "Status", "Waktu"), [(p.get("amount", "-"), p.get("status", "-"), connection.format_time(p.get("timestamp"))) for p in listing[:5]])
    print()
    ui.info("Dashboard: " + connection.dashboard_url(profile))

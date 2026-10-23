from __future__ import annotations

from . import actions, api, benchmark, config, connection, doctor, installer, logs, paths, profiles, settings, stats, system, ui, updater, web
from . import constants as C


def header(level=0):
    profile = config.active()
    latest = updater.notice()
    if level == 0:
        lines = ui.banner_lines() + ui.box_lines("Status", stats.status_lines(profile), ui.CYAN)
        if latest:
            lines.append(ui.paint(f"! Versi baru {latest} tersedia (Instalasi & pembaruan)", ui.YELLOW))
        return lines
    lines = ui.banner_lines(compact=True) + [stats.status_compact(profile)]
    if latest:
        lines.append(ui.paint(f"! Versi baru {latest} tersedia", ui.YELLOW))
    return lines


def opener(function):
    def go():
        function()
        return ui.NOPAUSE

    go._live = True
    return go


def sync_view():
    connection.sync_check(config.active())


def mining_menu():
    items = [
        ("1", "Mulai mining (background + guard)", ui.live(actions.start)),
        ("2", "Stop mining", actions.stop),
        ("3", "Restart mining", ui.live(actions.restart)),
        ("4", "Mining foreground (lihat langsung)", ui.live(actions.foreground)),
        ("5", "Dashboard sekali tampil", actions.status),
        ("6", "Cek koneksi & sinkron ke website", sync_view),
    ]
    return ui.Menu("Mining", items, header=header)


def wallet_menu():
    items = [
        ("1", "Login / ganti akun (wizard)", ui.live(lambda: profiles.wizard(config.active()))),
        ("2", "Logout", ui.live(profiles.logout)),
        ("3", "Lihat profil aktif", lambda: profiles.show(config.active())),
        ("4", "Daftar profil", profiles.listing),
        ("5", "Ganti profil aktif", ui.live(profiles.switch)),
        ("6", "Buat profil baru", ui.live(profiles.create)),
        ("7", "Duplikat profil", ui.live(profiles.duplicate)),
        ("8", "Hapus profil", ui.live(profiles.remove)),
        ("9", "Validasi alamat dompet", ui.live(profiles.validate_address)),
    ]
    return ui.Menu("Akun & profil", items, header=header)


def install_menu():
    items = [
        ("1", "Setup lengkap (dependensi + XMRig)", ui.live(actions.install)),
        ("2", "Pasang dependensi saja", ui.live(installer.install_dependencies)),
        ("3", "Pasang ulang XMRig", ui.live(actions.reinstall_xmrig)),
        ("4", "Cek pembaruan", updater.check),
        ("5", "Perbarui ke rilis terbaru", ui.live(lambda: updater.update("release"))),
        ("6", "Perbarui dari branch main (dev)", ui.live(lambda: updater.update("main"))),
        ("7", "Uninstall", ui.live(actions.uninstall)),
    ]
    return ui.Menu("Instalasi & pembaruan", items, header=header)


def logs_menu():
    def sizes():
        ui.table(("Berkas", "Ukuran"), logs.sizes())

    def clear_logs():
        if ui.confirm("Hapus semua log dan riwayat hashrate?", False):
            logs.clear_all()
            ui.ok("Log dibersihkan")

    items = [
        ("1", "Ikuti log XMRig (live)", ui.live(actions.follow_log)),
        ("2", "50 baris terakhir log XMRig", lambda: logs.show(paths.MINER_LOG, 50)),
        ("3", "Log guard (pause / lanjut / crash)", lambda: logs.show(paths.GUARD_LOG, 50)),
        ("4", "Ukuran berkas log", sizes),
        ("5", "Bersihkan log", ui.live(clear_logs)),
    ]
    return ui.Menu("Log", items, header=header)


def tools_menu():
    def coin_list():
        with ui.Spinner("Mengambil daftar koin"):
            symbols = api.coins()
        if not symbols:
            ui.warn(f"Gagal membaca API. Lihat {C.SITE}/coins")
            return
        ui.box(f"{len(symbols)} koin", [" ".join(symbols)], ui.GREEN)

    def pool_test():
        profile = config.active()
        for host, port, tls in profile.endpoints():
            reachable, latency = system.tcp_check(host, port, timeout=5.0)
            label = config.endpoint_url(host, port, tls)
            if reachable:
                ui.ok(f"{label} terjangkau ({latency} ms)")
            else:
                ui.fail(f"{label} tidak terjangkau")

    def device():
        ui.box("Info perangkat", ui.kv(system.device_info(), 13), ui.CYAN)

    items = [
        ("1", "Benchmark CPU", ui.live(lambda: benchmark.run(config.active()))),
        ("2", "Diagnosa lengkap", lambda: doctor.render(config.active())),
        ("3", "Daftar koin (API)", coin_list),
        ("4", "Saldo & worker (API)", lambda: stats.account_view(config.active())),
        ("5", "Tes koneksi pool", pool_test),
        ("6", "Info perangkat", device),
        ("7", "Tes notifikasi", settings.test),
        ("8", "Cek koneksi & sinkron ke website", sync_view),
    ]
    return ui.Menu("Alat & diagnosa", items, header=header)


def about():
    lines = ui.kv(
        [
            ("Versi", C.VERSION),
            ("Repo", C.REPO),
            ("Website", C.SITE),
            ("Algoritma", "RandomX (rx/0) via XMRig, CPU"),
            ("Lisensi", "MIT"),
        ],
        12,
    )
    ui.box("Tentang", lines, ui.CYAN)
    tips = [
        "Mining butuh: sudah login dan XMRig terdeteksi.",
        "Hashrate HP kecil dan perangkat bisa panas, pakai guard suhu.",
        "Cek fee dan minimum payout di unmineable.com.",
        "Mining hanya di perangkat milikmu atau dengan izin pemilik.",
        "Tool ini tidak berafiliasi dengan unMineable maupun XMRig.",
    ]
    ui.box("Catatan", tips, ui.YELLOW)


def login_label():
    profile = config.active()
    if profile.logged_in:
        return f"Logout ({profile.display_id()})"
    return "Login ke unMineable"


def main_menu():
    items = [
        ("s", "Mulai cepat (panduan)", ui.live(actions.quickstart)),
        ("l", login_label, ui.live(actions.login_toggle)),
        ("1", "Mining  ▸", mining_menu().opener()),
        ("2", "Dashboard live", ui.live(stats.watch)),
        ("3", "Akun & profil  ▸", wallet_menu().opener()),
        ("4", "Pengaturan lanjutan  ▸", opener(settings.menu)),
        ("5", "Website unMineable  ▸", opener(web.menu)),
        ("6", "Instalasi & pembaruan  ▸", install_menu().opener()),
        ("7", "Log  ▸", logs_menu().opener()),
        ("8", "Alat & diagnosa  ▸", tools_menu().opener()),
        ("9", "Tentang & catatan", about),
        ("c", "Cek koneksi & sinkron", sync_view),
    ]
    return ui.Menu("Menu utama", items, header=header, back="Keluar")


def run():
    main_menu().run()

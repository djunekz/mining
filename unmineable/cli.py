from __future__ import annotations

import argparse
import sys

from . import actions, api, benchmark, boot, config, connection, doctor, guard, installer, logs, menu, paths, profiles, settings, stats, system, ui, updater, web
from . import constants as C


def cmd_menu(args):
    ui.enter_screen()
    try:
        menu.run()
    finally:
        ui.leave_screen()


def cmd_start(args):
    return 0 if actions.start(quiet=args.quiet) else 1


def cmd_stop(args):
    actions.stop()


def cmd_restart(args):
    return 0 if actions.restart() else 1


def cmd_status(args):
    actions.status()


def cmd_watch(args):
    ui.enter_screen()
    try:
        stats.watch()
    finally:
        ui.leave_screen()


def cmd_run(args):
    actions.foreground()


def cmd_config(args):
    profiles.wizard(config.active())


def cmd_login(args):
    profiles.wizard(config.active())


def cmd_logout(args):
    profiles.logout()


def cmd_profiles(args):
    profiles.listing()


def cmd_stats(args):
    stats.account_view(config.active())


def cmd_coins(args):
    with ui.Spinner("Mengambil daftar koin"):
        symbols = api.coins()
    if not symbols:
        ui.warn(f"Gagal membaca API. Lihat {C.SITE}/coins")
        return 1
    print(" ".join(symbols))


def cmd_web(args):
    web.menu()


def cmd_install(args):
    return 0 if installer.install_all() else 1


def cmd_bench(args):
    benchmark.run(config.active())


def cmd_doctor(args):
    doctor.render(config.active())


def cmd_update(args):
    if args.check:
        updater.check()
        return 0
    return 0 if updater.update(args.channel, args.yes) else 1


def cmd_check(args):
    updater.check()


def cmd_boot(args):
    if args.action == "on":
        boot.enable()
        ui.ok("Autostart diaktifkan")
    elif args.action == "off":
        boot.disable()
        ui.ok("Autostart dinonaktifkan")
    else:
        ui.info("Autostart: " + ("aktif" if boot.enabled() else "nonaktif"))


def cmd_logs(args):
    if args.follow:
        actions.follow_log()
    else:
        logs.show(paths.GUARD_LOG if args.guard else paths.MINER_LOG, args.lines)


def cmd_notify_test(args):
    settings.test()


def cmd_sync(args):
    connection.sync_check(config.active())


def cmd_info(args):
    ui.box("Info perangkat", ui.kv(system.device_info(), 13), ui.CYAN)


def cmd_quickstart(args):
    actions.quickstart()


def cmd_uninstall(args):
    actions.uninstall()


def cmd_guard(args):
    guard.Guard().run()


COMMANDS = (
    ("menu", "menu interaktif (default)", cmd_menu),
    ("quickstart", "panduan mulai cepat", cmd_quickstart),
    ("install", "pasang dependensi dan XMRig", cmd_install),
    ("login", "login ke unMineable (alias atau dompet)", cmd_login),
    ("logout", "logout dan hentikan mining", cmd_logout),
    ("config", "sama dengan login", cmd_config),
    ("profiles", "daftar profil", cmd_profiles),
    ("start", "mulai mining di background", cmd_start),
    ("stop", "hentikan mining", cmd_stop),
    ("restart", "restart mining", cmd_restart),
    ("run", "mining foreground", cmd_run),
    ("status", "dashboard sekali tampil", cmd_status),
    ("watch", "dashboard live", cmd_watch),
    ("stats", "statistik akun dari API unMineable", cmd_stats),
    ("coins", "daftar koin dari API", cmd_coins),
    ("web", "menu website unMineable", cmd_web),
    ("bench", "benchmark CPU", cmd_bench),
    ("sync", "cek koneksi dan sinkron ke website", cmd_sync),
    ("doctor", "diagnosa lingkungan", cmd_doctor),
    ("info", "info perangkat", cmd_info),
    ("notify-test", "tes notifikasi", cmd_notify_test),
    ("check", "cek versi terbaru", cmd_check),
    ("uninstall", "hapus tool", cmd_uninstall),
)


def build_parser():
    parser = argparse.ArgumentParser(prog=C.APP_NAME, description="unMineable XMRig miner untuk Termux")
    parser.add_argument("-p", "--profile", help="gunakan profil tertentu")
    parser.add_argument("-V", "--version", action="version", version=f"{C.APP_NAME} {C.VERSION}")
    sub = parser.add_subparsers(dest="command", metavar="perintah")
    for name, description, handler in COMMANDS:
        child = sub.add_parser(name, help=description)
        child.set_defaults(handler=handler)
        if name == "start":
            child.add_argument("-q", "--quiet", action="store_true", help="tanpa keluaran")
    update_parser = sub.add_parser("update", help="perbarui tool dari GitHub")
    update_parser.add_argument("-c", "--channel", choices=("auto", "pkg", "release", "main"), default="auto", help="auto (pkg bila terpasang lewat pkg, selain itu release), pkg, release (stabil), atau main (dev)")
    update_parser.add_argument("-y", "--yes", action="store_true", help="tanpa konfirmasi")
    update_parser.add_argument("--check", action="store_true", help="hanya cek versi")
    update_parser.set_defaults(handler=cmd_update)
    boot_parser = sub.add_parser("boot", help="autostart Termux:Boot")
    boot_parser.add_argument("action", nargs="?", choices=("on", "off", "status"), default="status")
    boot_parser.set_defaults(handler=cmd_boot)
    logs_parser = sub.add_parser("logs", help="lihat log")
    logs_parser.add_argument("-f", "--follow", action="store_true", help="ikuti log live")
    logs_parser.add_argument("-g", "--guard", action="store_true", help="log guard")
    logs_parser.add_argument("-n", "--lines", type=int, default=50, help="jumlah baris")
    logs_parser.set_defaults(handler=cmd_logs)
    hidden = sub.add_parser("_guard")
    hidden.set_defaults(handler=cmd_guard)
    return parser


def main(argv=None):
    paths.ensure()
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.profile:
        name = config.safe_name(args.profile)
        if not config.exists(name):
            ui.fail(f"Profil {name} tidak ditemukan")
            sys.exit(1)
        config.set_active(name)
    handler = getattr(args, "handler", cmd_menu)
    if not hasattr(args, "quiet"):
        args.quiet = False
    try:
        code = handler(args)
    except KeyboardInterrupt:
        print()
        sys.exit(130)
    sys.exit(code or 0)

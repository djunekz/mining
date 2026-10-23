from __future__ import annotations

from . import boot, config, connection, notify, profiles, system, ui
from . import constants as C


def performance():
    profile = config.active()
    cores = system.cpu_count()
    ui.info(f"Perangkat punya {cores} core. 0 = otomatis (setengah core).")
    profile.threads = ui.ask_int("Jumlah thread CPU", profile.threads, 0, cores)
    profile.cpu_limit = ui.ask_int("Batas penggunaan CPU (%)", profile.cpu_limit, 10, 100)
    options = [("auto", "auto (disarankan)"), ("fast", "fast (butuh RAM 2 GB+ bebas)"), ("light", "light (hemat RAM)")]
    profile.rx_mode = ui.choose("Mode RandomX", options, profile.rx_mode)
    profile.priority = ui.ask_int("Prioritas CPU (0-5)", profile.priority, 0, 5)
    profile.donate = ui.ask_int("Donate level XMRig (%)", profile.donate, 0, 50)
    config.save(profile)
    ui.ok("Pengaturan performa tersimpan")


def protection():
    profile = config.active()
    ui.info("Butuh app Termux:API agar suhu dan baterai terbaca.")
    profile.max_temp = ui.ask_float("Pause jika suhu baterai mencapai (°C)", profile.max_temp, 30, 60)
    profile.resume_temp = ui.ask_float("Lanjut setelah suhu turun ke (°C)", profile.resume_temp, 25, profile.max_temp - 1)
    profile.min_battery = ui.ask_int("Pause jika baterai di bawah (%) dan tidak charging", profile.min_battery, 0, 90)
    profile.only_charging = ui.confirm("Mining hanya saat charging?", profile.only_charging)
    config.save(profile)
    ui.ok("Pengaturan proteksi tersimpan")


def pool():
    profile = config.active()
    options = [
        ("0", "rx.unmineable.com:3333 (default)"),
        ("1", "rx.unmineable.com:13333 (port alternatif)"),
        ("2", "SSL rx.unmineable.com:443 (tembus blokir ISP)"),
        ("3", "rx.unmineable.com:80 (tembus blokir ISP)"),
        ("c", "Kustom (host dan port sendiri)"),
    ]
    current = config.endpoint_url(profile.host, profile.port, profile.tls)
    ui.info(f"Pool utama saat ini: {current}")
    picked = ui.choose("Pilih pool utama", options, "0")
    if picked == "c":
        profile.host = ui.ask("Host pool", profile.host)
        profile.port = ui.ask_int("Port pool", profile.port, 1, 65535)
        profile.tls = ui.confirm("Gunakan SSL/TLS?", profile.tls)
    else:
        host, port, tls = C.POOL_ENDPOINTS[int(picked)]
        profile.host, profile.port, profile.tls = host, port, tls
    profile.failover = ui.confirm("Aktifkan pool cadangan otomatis (13333, SSL 443, 80)?", profile.failover)
    config.save(profile)
    ui.ok("Pengaturan pool tersimpan. Restart mining untuk menerapkan.")
    if profile.ready() and ui.confirm("Uji login ke pool sekarang?", True):
        connection.sync_check(profile)


def notifications():
    profile = config.active()
    profile.notify_local = ui.confirm("Aktifkan notifikasi Android (Termux:API)?", profile.notify_local)
    profile.notify_telegram = ui.confirm("Aktifkan notifikasi Telegram?", profile.notify_telegram)
    if profile.notify_telegram:
        ui.info("Buat bot lewat @BotFather, lalu kirim pesan ke bot dan ambil chat ID kamu.")
        token = ui.ask("Token bot", "-" if profile.telegram_token else "", secret=True)
        if token != "-":
            profile.telegram_token = token.strip()
        profile.telegram_chat = ui.ask("Chat ID", profile.telegram_chat).strip()
    config.save(profile)
    ui.ok("Pengaturan notifikasi tersimpan")
    if ui.confirm("Kirim notifikasi tes sekarang?", True):
        test(profile)


def test(profile=None):
    profile = profile or config.active()
    result = notify.send(profile, "unMineable", "Notifikasi tes berhasil")
    if not result:
        ui.warn("Tidak ada kanal notifikasi yang aktif.")
        return
    for channel, success in result.items():
        if success:
            ui.ok(f"Notifikasi {channel} terkirim")
        else:
            ui.fail(f"Notifikasi {channel} gagal")


def autostart():
    if boot.enabled():
        ui.info("Autostart saat ini: aktif")
        if ui.confirm("Nonaktifkan autostart?", False):
            boot.disable()
            ui.ok("Autostart dinonaktifkan")
        return
    ui.info("Autostart memakai aplikasi Termux:Boot (F-Droid). Buka sekali agar aktif.")
    if ui.confirm("Aktifkan autostart mining saat HP menyala?", False):
        boot.enable()
        ui.ok("Autostart diaktifkan")


def reset():
    current = config.active()
    if not ui.confirm("Kembalikan semua pengaturan teknis ke default? (dompet tetap)", False):
        return
    fresh = config.Profile(name=current.name)
    fresh.coin = current.coin
    fresh.address = current.address
    fresh.worker = current.worker
    fresh.referral = current.referral
    config.save(fresh)
    ui.ok("Pengaturan teknis dikembalikan ke default")


def menu():
    items = [
        ("1", "Performa (thread, CPU, RandomX, prioritas)", ui.live(performance)),
        ("2", "Proteksi suhu & baterai", ui.live(protection)),
        ("3", "Pool (utama + cadangan)", ui.live(pool)),
        ("4", "Notifikasi (Android & Telegram)", ui.live(notifications)),
        ("5", "Autostart saat HP menyala (Termux:Boot)", ui.live(autostart)),
        ("6", "Lihat profil aktif", lambda: profiles.show(config.active())),
        ("7", "Reset pengaturan teknis", ui.live(reset)),
    ]
    ui.Menu("Pengaturan lanjutan", items).run()


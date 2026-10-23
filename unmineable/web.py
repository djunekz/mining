from __future__ import annotations

from . import config, connection, system, ui
from . import constants as C


def open_key(key):
    for name, _, url in C.LINKS:
        if name == key:
            ui.info(url)
            if not system.open_url(url):
                ui.warn("Browser tidak bisa dibuka otomatis. Salin tautan di atas.")
            return


def open_dashboard():
    profile = config.active()
    if not profile.ready():
        ui.warn("Akun belum diatur. Atur dulu di menu Dompet & profil.")
        return
    url = connection.dashboard_url(profile)
    if profile.mode == "address" and system.clipboard_set(profile.address):
        ui.ok("Alamat dompet disalin ke clipboard")
    ui.info(url)
    if not system.open_url(url):
        ui.warn("Browser tidak bisa dibuka otomatis. Salin tautan di atas.")
    if profile.mode == "alias":
        ui.info("Setelah login, buka dashboard akun untuk melihat worker dan saldo.")
    else:
        ui.info("Data muncul setelah pool menerima share, bisa tertunda beberapa menit.")


def show_guide():
    lines = [
        "Ada dua cara mining di unMineable:",
        "",
        "1. Akun website (alias) - disarankan",
        "   Daftar/login di website, buat Alias, lalu pakai Alias di tool ini.",
        "   Hasil tampil di akun website kamu.",
        "",
        "2. Alamat dompet (legacy)",
        "   Tanpa daftar. Hasil dilihat lewat halaman koin > Address, atau",
        "   menu Buka dashboard milikku di sini.",
        "",
        "Jika hasil tidak muncul di website, jalankan: unmineable sync",
        "Kalau port 3333 diblokir ISP, pakai port 80 atau SSL 443.",
    ]
    ui.box("Panduan akun & login", lines, ui.CYAN)


def show_support():
    lines = ui.kv(
        [
            ("Email resmi", C.SUPPORT_EMAIL),
            ("X", "https://x.com/un_mineable"),
            ("Instagram", "https://instagram.com/unminable"),
            ("Pusat bantuan", C.SITE + "/support"),
        ],
        16,
    )
    ui.box("Kontak resmi", lines, ui.GREEN)
    ui.warn("Menurut website resmi, unMineable tidak punya channel Telegram atau Discord resmi.")
    ui.warn("Waspada penipu yang mengaku admin dan jangan pernah membagikan seed phrase.")


def menu():
    items = []
    for index, (key, label, _) in enumerate(C.LINKS, 1):
        items.append((str(index), label, lambda k=key: open_key(k)))
    items.append(("a", "Buka dashboard milikku di website", open_dashboard))
    items.append(("c", "Cek koneksi & sinkron ke website", lambda: connection.sync_check(config.active())))
    items.append(("g", "Panduan akun & login", show_guide))
    items.append(("k", "Kontak resmi & peringatan penipuan", show_support))
    ui.Menu("Website unMineable", items).run()

from __future__ import annotations

import re

import time

from . import api, coins, config, connection, guard, system, ui
from . import constants as C


def show(profile, brief=False):
    if profile.mode == "alias":
        identity = [("Mode", "alias akun website"), ("Alias", profile.alias or "-")]
    else:
        identity = [
            ("Mode", "alamat dompet (legacy)"),
            ("Koin", f"{profile.coin} ({coins.name(profile.coin)})" if profile.coin else "-"),
            ("Alamat", profile.masked_address()),
            ("Memo/tag", profile.memo or "-"),
            ("Referral", profile.referral or "-"),
        ]
    login_text = f"ya · {profile.login_time}" if profile.logged_in else "belum login"
    if brief:
        pairs = [("Profil", profile.name), ("Login", login_text)] + identity + [("Worker", profile.worker)]
        ui.box("Akun", ui.kv(pairs, 12), ui.CYAN)
        return
    pairs = [("Nama profil", profile.name), ("Login", login_text)] + identity + [
        ("Worker", profile.worker),
        ("Pool utama", config.endpoint_url(profile.host, profile.port, profile.tls)),
        ("Pool cadangan", "aktif (port 13333, SSL 443, 80)" if profile.failover else "mati"),
        ("Thread", str(profile.threads or f"otomatis ({profile.effective_threads()})")),
        ("Batas CPU", f"{profile.cpu_limit}%"),
        ("RandomX", profile.rx_mode),
        ("Prioritas", str(profile.priority)),
        ("Donate", f"{profile.donate}%"),
        ("Pause suhu", f"{profile.max_temp:g}°C"),
        ("Lanjut suhu", f"{profile.resume_temp:g}°C"),
        ("Baterai min", f"{profile.min_battery}%"),
        ("Hanya charging", "ya" if profile.only_charging else "tidak"),
        ("Notif lokal", "aktif" if profile.notify_local else "mati"),
        ("Notif Telegram", "aktif" if profile.notify_telegram else "mati"),
    ]
    ui.box("Profil", ui.kv(pairs, 16), ui.CYAN)
    for problem in profile.problems():
        ui.warn(problem)


def optional(value):
    return "" if value == "-" else value


def alias_flow(profile):
    ui.box(
        "Mode akun website (disarankan)",
        [
            "1. Daftar atau login di website unMineable",
            "2. Buat Alias di akun kamu dan atur pembagian koin",
            "3. Masukkan nama Alias itu di sini",
            "Hasil mining akan tampil di akun website kamu.",
        ],
        ui.GREEN,
    )
    if ui.confirm("Buka halaman Sign In di browser sekarang?", False):
        system.open_url(C.SIGNIN_URL)
        ui.info(C.SIGNIN_URL)

    def check(value):
        if not value or re.search(r"[\s.:#]", value):
            return "Alias tidak boleh kosong, berspasi, atau mengandung . : #"
        return None

    profile.alias = config.safe_alias(ui.ask("Nama Alias akun", profile.alias, check))
    profile.referral = ""
    profile.memo = ""


def address_flow(profile):
    ui.info("Koin populer: " + " ".join(coins.QUICK))
    profile.coin = coins.normalize(ui.ask("Koin yang diterima", profile.coin or "DOGE"))
    ui.info(coins.hint(profile.coin))
    with ui.Spinner("Mengambil info koin dari unMineable"):
        info = api.coin_info(profile.coin)
    official = None
    if info:
        official = info.get("regex")
        ui.info(f"Ambang bayar {info.get('payment_threshold', '-')} {info.get('symbol', profile.coin)}"
                + ("" if info.get("payment_enabled", True) else " · pembayaran sedang maintenance"))

    def check(value):
        if official:
            try:
                if re.match(official, value):
                    return None
                return f"Bukan alamat {profile.coin} yang valid menurut aturan unMineable"
            except re.error:
                pass
        state, message = coins.validate(profile.coin, value)
        return message if state is False else None

    profile.address = ui.ask("Alamat dompet", profile.address, check).replace(" ", "")
    if info and info.get("regex_memo"):
        ui.warn("Koin ini butuh memo / payment tag agar pembayaran sampai.")
        profile.memo = config.safe_memo(ui.ask("Memo / tag", profile.memo))
    else:
        profile.memo = config.safe_memo(optional(ui.ask("Memo / tag (opsional, - untuk kosong)", profile.memo or "-")))
    state, message = coins.validate(profile.coin, profile.address)
    if state is None and not official:
        ui.warn(message)
    referral = optional(ui.ask("Kode referral unMineable (opsional)", profile.referral))
    profile.referral = config.safe_referral(referral)
    profile.alias = ""


def verify(profile):
    with ui.Spinner("Memverifikasi login ke pool unMineable"):
        results = connection.scan(profile)
    if any(result["ok"] for _, result in results):
        if profile.mode == "alias":
            ui.warn("Pool hanya menjawab 'OK' pada koneksi; ini belum membuktikan alias terdaftar di akunmu.")
            ui.warn("Cek di website: worker harus muncul online setelah ada share diterima.")
        return "ok", "Login diterima pool"
    rejected = [r for _, r in results if r["stage"] == "login" and "menolak" in r["message"]]
    if rejected:
        return "rejected", rejected[0]["message"]
    if all(r["stage"] in ("tcp", "tls") for _, r in results):
        return "network", "Tidak bisa terhubung ke pool. Cek internet, atau ISP memblokir port mining (coba SSL 443 / port 80)."
    return "unknown", "Pool tidak membalas verifikasi login"


def mark_logged_in(profile):
    profile.logged_in = True
    profile.login_time = time.strftime("%d-%m-%Y %H:%M")
    config.save(profile)


def wizard(profile=None):
    profile = profile or config.active()
    ui.clear()
    ui.banner()
    ui.box(
        "Login ke unMineable",
        [
            "Mining hanya bisa dimulai setelah login berhasil.",
            "Ketik - untuk mengosongkan kolom opsional.",
        ],
        ui.CYAN,
    )
    options = [
        ("alias", "Akun website (alias) - disarankan, hasil tampil di akun kamu"),
        ("address", "Alamat dompet langsung (legacy) - cepat, tanpa daftar"),
    ]
    profile.mode = ui.choose("Cara login", options, profile.mode)
    print()
    if profile.mode == "alias":
        alias_flow(profile)
    else:
        address_flow(profile)
    profile.worker = config.safe_worker(ui.ask("Nama worker", profile.worker))
    profile.logged_in = False
    profile.login_time = ""
    config.save(profile)
    config.set_active(profile.name)
    print()
    status, message = verify(profile)
    if status == "ok":
        mark_logged_in(profile)
        ui.ok("Login berhasil. Mining sekarang bisa dimulai.")
    elif status == "unknown":
        ui.warn(message)
        if ui.confirm("Tetap anggap login berhasil dan lanjut?", False):
            mark_logged_in(profile)
            ui.ok("Login disimpan tanpa verifikasi pool.")
        else:
            ui.fail("Belum login. Mining tidak bisa dimulai.")
    else:
        ui.fail(message)
        ui.fail("Belum login. Mining tidak bisa dimulai. Perbaiki data lalu ulangi login.")
    print()
    show(profile, brief=True)
    return profile


def logout():
    profile = config.active()
    if not profile.logged_in:
        ui.info("Kamu belum login.")
        return
    if not ui.confirm(f"Logout dari {profile.display_id()}? Mining akan dihentikan.", False):
        return
    guard.stop_background()
    profile.logged_in = False
    profile.login_time = ""
    if ui.confirm("Hapus juga alias/alamat dari profil?", False):
        profile.alias = ""
        profile.address = ""
        profile.memo = ""
        profile.referral = ""
    config.save(profile)
    ui.ok("Logout berhasil. Mining dihentikan.")


def create():
    name = config.safe_name(ui.ask("Nama profil baru", "profil2"))
    if config.exists(name) and not ui.confirm(f"Profil {name} sudah ada, timpa?", False):
        return
    return wizard(config.Profile(name=name))


def switch():
    names = config.list_profiles()
    if not names:
        ui.warn("Belum ada profil tersimpan.")
        return
    current = config.active_name()
    options = [(n, f"{n}" + ("  (aktif)" if n == current else "")) for n in names]
    picked = ui.choose("Pilih profil", options, current)
    config.set_active(picked)
    ui.ok(f"Profil aktif: {picked}")
    ui.info("Restart mining untuk menerapkan profil baru segera.")


def duplicate():
    source = config.active()
    name = config.safe_name(ui.ask("Nama salinan", f"{source.name}-copy"))
    clone = config.Profile.from_dict(source.to_dict())
    clone.name = name
    clone.worker = config.safe_worker(ui.ask("Nama worker untuk salinan", f"{source.worker}-2"))
    config.save(clone)
    ui.ok(f"Profil {name} dibuat dari {source.name}")


def remove():
    names = config.list_profiles()
    if not names:
        ui.warn("Belum ada profil tersimpan.")
        return
    picked = ui.choose("Profil yang dihapus", [(n, n) for n in names])
    if not ui.confirm(f"Hapus profil {picked}?", False):
        return
    config.delete(picked)
    ui.ok(f"Profil {picked} dihapus")
    if config.active_name() == picked:
        remaining = config.list_profiles()
        config.set_active(remaining[0] if remaining else "default")


def listing():
    names = config.list_profiles()
    if not names:
        ui.warn("Belum ada profil. Jalankan setup akun.")
        return
    current = config.active_name()
    rows = []
    for name in names:
        profile = config.load(name)
        marker = ui.paint("●", ui.GREEN) if name == current else " "
        rows.append((marker, name, profile.mode, profile.display_id(), profile.worker))
    ui.table(("", "Profil", "Mode", "Akun", "Worker"), rows)


def validate_address():
    coin = coins.normalize(ui.ask("Koin", config.active().coin or "BTC"))
    address = ui.ask("Alamat")
    state, message = coins.validate(coin, address)
    if state is True:
        ui.ok(message)
    elif state is None:
        ui.warn(message)
    else:
        ui.fail(message)

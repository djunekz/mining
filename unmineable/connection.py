from __future__ import annotations

import json
import re
import socket
import ssl
import time

from . import api, coins, config, logs, miner, paths, ui
from . import constants as C

ACCEPT_PATTERN = re.compile(r"(?:accepted|rejected) \((\d+)/(\d+)\)", re.IGNORECASE)
POOL_PATTERN = re.compile(r"use pool (\S+)", re.IGNORECASE)
ERROR_WORDS = ("error", "refused", "timed out", "unreachable", "unauthenticated", "invalid", "failed", "banned")


def _parse(line):
    try:
        return json.loads(line.decode("utf-8", "replace"))
    except ValueError:
        return None


def _interpret(reply, ms):
    error = reply.get("error")
    if error:
        text = error.get("message") if isinstance(error, dict) else str(error)
        return {"ok": False, "stage": "login", "message": f"pool menolak login: {text}", "ms": ms}
    result = reply.get("result") or {}
    status = str(result.get("status", "OK"))
    if status.upper() != "OK":
        return {"ok": False, "stage": "login", "message": f"status login: {status}", "ms": ms}
    return {"ok": True, "stage": "login", "message": "login diterima pool", "ms": ms}


def login_test(profile, host, port, tls, timeout=10.0):
    started = time.time()
    try:
        raw = socket.create_connection((host, port), timeout=timeout)
    except OSError as error:
        return {"ok": False, "stage": "tcp", "message": f"tidak bisa terhubung ({error})", "ms": 0}
    try:
        if tls:
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            sock = context.wrap_socket(raw, server_hostname=host)
        else:
            sock = raw
    except (ssl.SSLError, OSError) as error:
        raw.close()
        return {"ok": False, "stage": "tls", "message": f"jabat tangan TLS gagal ({error})", "ms": 0}
    ms = int((time.time() - started) * 1000)
    request = {
        "id": 1,
        "jsonrpc": "2.0",
        "method": "login",
        "params": {"login": profile.username(), "pass": "x", "agent": f"unmineable-termux/{C.VERSION}", "algo": ["rx/0"]},
    }
    outcome = {"ok": False, "stage": "login", "message": "pool tidak membalas login", "ms": ms}
    finished = False
    try:
        sock.settimeout(timeout)
        sock.sendall((json.dumps(request) + "\n").encode())
        buffer = b""
        deadline = time.time() + timeout
        while not finished and time.time() < deadline:
            chunk = sock.recv(4096)
            if not chunk:
                break
            buffer += chunk
            while b"\n" in buffer and not finished:
                line, buffer = buffer.split(b"\n", 1)
                reply = _parse(line)
                if isinstance(reply, dict) and reply.get("id") == 1:
                    outcome = _interpret(reply, ms)
                    finished = True
    except (OSError, ssl.SSLError):
        pass
    finally:
        try:
            sock.close()
        except OSError:
            pass
    return outcome


def scan(profile):
    rows = []
    for host, port, tls in profile.endpoints():
        rows.append(((host, port, tls), login_test(profile, host, port, tls)))
    return rows


def log_findings(count=400):
    lines = logs.tail(paths.MINER_LOG, count)
    info = {"accepted": 0, "rejected": 0, "pool": None, "error": None, "status": "kosong"}
    last_error_at = -1
    last_good_at = -1
    for index, line in enumerate(lines):
        low = line.lower()
        match = ACCEPT_PATTERN.search(line)
        if match:
            info["accepted"] = int(match.group(1))
            info["rejected"] = int(match.group(2))
            last_good_at = index
            continue
        found = POOL_PATTERN.search(line)
        if found:
            info["pool"] = found.group(1)
            last_good_at = index
        if "new job" in low:
            last_good_at = index
        elif any(word in low for word in ERROR_WORDS):
            info["error"] = line.strip()
            last_error_at = index
    if not lines:
        info["status"] = "kosong"
    elif last_error_at > last_good_at:
        info["status"] = "error"
    elif info["accepted"] > 0:
        info["status"] = "ok"
    elif info["pool"]:
        info["status"] = "menunggu"
    else:
        info["status"] = "belum"
    return info


def explain_error(text):
    low = (text or "").lower()
    if any(word in low for word in ("connect", "refused", "timed out", "unreachable", "network", "resolve")):
        return "Koneksi ke pool gagal. Kemungkinan port 3333 diblokir ISP/jaringan. Pakai port 13333, 80, atau SSL 443 (Pengaturan > Pool)."
    if any(word in low for word in ("invalid", "address", "login", "unauthenticated", "banned")):
        return "Pool menolak login. Periksa koin, alamat dompet (harus sesuai jaringan koin), atau nama alias akun."
    if "low difficulty" in low:
        return "Share ditolak karena low difficulty, biasanya sementara."
    return "Ada pesan error dari XMRig. Lihat log XMRig untuk detailnya."


def finding_lines(info):
    status = info["status"]
    if status == "ok":
        head = ui.paint("terhubung, share diterima pool", ui.GREEN, ui.BOLD)
    elif status == "menunggu":
        head = ui.paint("terhubung, menunggu share pertama", ui.YELLOW, ui.BOLD)
    elif status == "error":
        head = ui.paint("ada masalah koneksi", ui.RED, ui.BOLD)
    else:
        head = ui.paint("belum ada koneksi tercatat", ui.GRAY)
    pairs = [("Status", head)]
    if info["pool"]:
        pairs.append(("Pool", info["pool"]))
    pairs.append(("Share", f"{info['accepted']} diterima / {info['rejected']} ditolak"))
    lines = ui.kv(pairs)
    if status == "error":
        limit = ui.term_width() - 8
        lines.append(ui.paint((info["error"] or "")[:limit], ui.GRAY))
        lines.append(explain_error(info["error"]))
    return lines


def dashboard_url(profile):
    if profile.mode == "alias":
        return C.SIGNIN_URL
    return f"{C.SITE}/coins/{coins.base(profile.coin)}/address/{profile.address}"


def find_worker(workers, name):
    for group in (workers or {}).values():
        if not isinstance(group, dict):
            continue
        for worker in group.get("workers") or []:
            if worker.get("name") == name:
                return worker
    return None


def format_time(millis):
    try:
        return time.strftime("%d-%m %H:%M:%S", time.localtime(int(millis) / 1000))
    except (TypeError, ValueError, OverflowError):
        return "-"


def website_state(profile):
    state = {"info": None, "worker": None, "stats": None, "reachable": False}
    info = api.address_info(profile)
    if not info:
        return state
    state["info"] = info
    state["reachable"] = True
    uuid = info.get("uuid")
    if uuid:
        state["stats"] = api.account_stats(uuid)
        state["worker"] = find_worker(api.account_workers(uuid), profile.worker)
    return state


def sync_check(profile):
    if not profile.ready():
        ui.warn("Profil belum lengkap. Atur akun atau dompet dulu.")
        return
    ui.box("Akun yang diuji", ui.kv([("Mode", "alias akun website" if profile.mode == "alias" else "alamat dompet"), ("Login", _masked_login(profile))], 8), ui.CYAN)

    with ui.Spinner("Menguji login ke pool unMineable"):
        results = scan(profile)
    rows = []
    for (host, port, tls), result in results:
        mark = ui.paint("OK", ui.GREEN, ui.BOLD) if result["ok"] else ui.paint("GAGAL", ui.RED, ui.BOLD)
        label = config.endpoint_url(host, port, tls).replace("stratum+ssl://", "ssl://")
        rows.append((label, mark, f"{result['ms']} ms" if result["ok"] else "-", result["message"]))
    ui.table(("Endpoint", "Hasil", "Waktu", "Keterangan"), rows)
    print()
    login_ok = any(result["ok"] for _, result in results)

    running = miner.is_running()
    summary = api.miner_summary() if running else None
    findings = log_findings()
    accepted = summary["shares_good"] if summary else findings["accepted"]
    ui.box("Miner lokal", ui.kv([("XMRig", "berjalan" if running else "berhenti"), ("Share diterima", str(accepted)), ("Pool dipakai", (summary or {}).get("pool") or findings["pool"] or "-")], 15), ui.BLUE)

    verdict = []
    state = None
    if profile.mode == "address":
        with ui.Spinner("Mengecek data di website unMineable"):
            state = website_state(profile)
        lines = []
        if state["reachable"]:
            info = state["info"]
            lines.extend(ui.kv([("Alamat dikenal", "ya" if not info.get("fresh") else "baru, belum pernah mining"), ("Saldo pending", str(info.get("balance", "-"))), ("Fee mining", f"{info.get('mining_fee', '-')}%"), ("Ambang bayar", str(info.get("payment_threshold", "-")))], 15))
            worker = state["worker"]
            if worker:
                status = ui.paint("online", ui.GREEN, ui.BOLD) if worker.get("online") else ui.paint("offline", ui.YELLOW)
                lines.extend(ui.kv([("Worker", f"{profile.worker} · {status}"), ("Aktivitas terakhir", format_time(worker.get("last"))), ("Hashrate (hitung)", ui.human_rate(worker.get("chr") or 0))], 15))
            else:
                lines.append(f"Worker {profile.worker} belum terlihat di website")
        else:
            lines.append("Gagal mengambil data website (cek koneksi, koin, atau alamat)")
        ui.box("Data di website", lines, ui.MAGENTA)
    else:
        ui.box("Data di website", ["Mode alias: data tampil setelah login di website.", "Buka menu Website > Login / Daftar akun."], ui.MAGENTA)

    if not login_ok:
        verdict.append("Tidak ada endpoint pool yang menerima login.")
        if all(r["stage"] == "tcp" for _, r in results):
            verdict.append("Semua koneksi gagal: periksa internet, atau ISP memblokir port mining. Coba SSL 443 / port 80.")
        else:
            verdict.append("Pool menolak login: periksa koin, alamat (jaringan harus cocok), atau alias akun.")
    elif not running:
        verdict.append("Login ke pool berhasil, tetapi mining belum berjalan. Jalankan: unmineable start")
    elif accepted == 0:
        verdict.append("Terhubung, tetapi belum ada share yang diterima. Hashrate HP kecil, tunggu beberapa menit sampai jam.")
    elif profile.mode == "address" and state and state["reachable"] and not state["worker"]:
        verdict.append("Pool sudah menerima share, tetapi worker belum tampil di website. Data website tertunda beberapa menit.")
        verdict.append("Pastikan membuka dashboard koin yang sama dengan alamat yang sama (link di bawah).")
    else:
        verdict.append("Sinkron: pool menerima share" + (" dan worker terlihat di website." if profile.mode == "address" else "."))
    color = ui.GREEN if login_ok and running and accepted else ui.YELLOW
    ui.box("Kesimpulan", verdict, color)
    print()
    ui.info("Dashboard: " + dashboard_url(profile))


def _masked_login(profile):
    login = profile.username()
    if profile.mode == "alias":
        return login
    return login.replace(profile.address, profile.masked_address())

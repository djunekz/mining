from __future__ import annotations

import glob
import json
import os
import platform
import shutil
import socket
import subprocess
import sys
import time
import webbrowser

from . import paths


def which(command):
    return shutil.which(command)


def run(command, timeout=15):
    try:
        done = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.SubprocessError):
        return 1, ""
    return done.returncode, (done.stdout or "").strip()


def is_termux():
    return "com.termux" in os.environ.get("PREFIX", "") or bool(os.environ.get("TERMUX_VERSION"))


def cpu_count():
    return os.cpu_count() or 1


def read_meminfo():
    data = {}
    try:
        with open("/proc/meminfo") as handle:
            for line in handle:
                key, _, rest = line.partition(":")
                parts = rest.split()
                if parts:
                    data[key] = int(parts[0]) // 1024
    except (OSError, ValueError):
        pass
    return data


def mem_total_mb():
    return read_meminfo().get("MemTotal", 0)


def mem_available_mb():
    return read_meminfo().get("MemAvailable", 0)


def cpu_model():
    try:
        with open("/proc/cpuinfo") as handle:
            for line in handle:
                if line.lower().startswith(("hardware", "model name")):
                    return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return platform.processor() or platform.machine()


def disk_free_mb(path=None):
    target = str(path or paths.HOME)
    try:
        return shutil.disk_usage(target).free // (1024 * 1024)
    except OSError:
        return 0


def load_average():
    try:
        return os.getloadavg()
    except (OSError, AttributeError):
        return None


_BATTERY_CACHE = {"data": None, "time": 0.0, "last_try": 0.0, "fail_until": 0.0}
_BATTERY_MAX_AGE = 900
_API_MIN_INTERVAL = 60
_API_BACKOFF = 300
_POWER_SUPPLY = "/sys/class/power_supply/battery"


def _battery_from_api():
    """Satu kali percobaan saja. Memanggil ulang saat timeout membuat Termux:API
    mencatat 'Connection refused' (klien sudah keburu mati), jadi tidak diulang."""
    if not which("termux-battery-status"):
        return None
    code, out = run(["termux-battery-status"], timeout=25)
    if code != 0 or not out:
        return None
    try:
        data = json.loads(out)
    except ValueError:
        return None
    temp = data.get("temperature")
    return {
        "percent": data.get("percentage"),
        "temp": float(temp) if isinstance(temp, (int, float)) else None,
        "status": str(data.get("status", "")).upper(),
        "plugged": str(data.get("plugged", "")).upper(),
        "health": str(data.get("health", "")).upper(),
        "source": "termux-api",
    }


def _read_sys(name):
    try:
        with open(f"{_POWER_SUPPLY}/{name}") as handle:
            return handle.read().strip()
    except OSError:
        return None


def _battery_from_sysfs():
    capacity = _read_sys("capacity")
    if capacity is None:
        return None
    try:
        percent = int(capacity)
    except ValueError:
        return None
    temp = None
    raw = _read_sys("temp")
    if raw:
        try:
            temp = float(raw) / 10.0
        except ValueError:
            temp = None
    status = (_read_sys("status") or "").upper().replace(" ", "_")
    if status == "NOT_CHARGING":
        status = "DISCHARGING"
    return {
        "percent": percent,
        "temp": temp,
        "status": status,
        "plugged": "",
        "health": (_read_sys("health") or "").upper(),
        "source": "sysfs",
    }


def battery():
    """Termux:API paling sering sekali per menit; setelah gagal ditunda 5 menit.
    Di sela itu dipakai sysfs atau nilai terakhir (maks 15 menit)."""
    now = time.time()
    cache = _BATTERY_CACHE
    if cache["data"] and now - cache["time"] < _API_MIN_INTERVAL:
        return cache["data"]
    data = None
    if now >= cache["fail_until"]:
        cache["last_try"] = now
        data = _battery_from_api()
        if data is None:
            cache["fail_until"] = now + _API_BACKOFF
    if data is None:
        data = _battery_from_sysfs()
    if data:
        cache["data"] = data
        cache["time"] = now
        return data
    if cache["data"] and now - cache["time"] <= _BATTERY_MAX_AGE:
        return dict(cache["data"], stale=True)
    return None


def cpu_temp():
    best = None
    for node in glob.glob("/sys/class/thermal/thermal_zone*/temp"):
        try:
            with open(node) as handle:
                value = float(handle.read().strip())
        except (OSError, ValueError):
            continue
        if value > 1000:
            value /= 1000
        if 10 < value < 120:
            best = value if best is None else max(best, value)
    return best


def wake_lock():
    if which("termux-wake-lock"):
        run(["termux-wake-lock"], 5)


def wake_unlock():
    if which("termux-wake-unlock"):
        run(["termux-wake-unlock"], 5)


def notification(title, text):
    if not which("termux-notification"):
        return False
    code, _ = run(["termux-notification", "--id", "unmineable", "--title", title, "--content", text], 8)
    return code == 0


def clipboard_set(text):
    if not which("termux-clipboard-set"):
        return False
    try:
        done = subprocess.run(["termux-clipboard-set"], input=text, text=True, timeout=6)
    except (OSError, subprocess.SubprocessError):
        return False
    return done.returncode == 0


def open_url(url):
    if which("termux-open-url"):
        code, _ = run(["termux-open-url", url], 10)
        if code == 0:
            return True
    if which("am"):
        code, _ = run(["am", "start", "-a", "android.intent.action.VIEW", "-d", url], 10)
        if code == 0:
            return True
    try:
        return bool(webbrowser.open(url))
    except webbrowser.Error:
        return False


def tcp_check(host, port, timeout=6.0):
    started = time.time()
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True, int((time.time() - started) * 1000)
    except OSError:
        return False, 0


def read_pid(path):
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None


def write_pid(path, pid):
    path.write_text(str(pid))


def remove(path):
    try:
        path.unlink()
    except OSError:
        pass


def reap(pid):
    try:
        os.waitpid(pid, os.WNOHANG)
    except OSError:
        pass


def pid_alive(pid):
    if not pid:
        return False
    reap(pid)
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    except OSError:
        return False
    return True


def device_info():
    memory = read_meminfo()
    return [
        ("Sistem", f"{platform.system()} {platform.release()}"),
        ("Arsitektur", platform.machine()),
        ("CPU", cpu_model()),
        ("Core", str(cpu_count())),
        ("RAM", f"{memory.get('MemAvailable', 0)} MB bebas / {memory.get('MemTotal', 0)} MB"),
        ("Penyimpanan", f"{disk_free_mb()} MB bebas"),
        ("Python", sys.version.split()[0]),
        ("Termux", "ya" if is_termux() else "bukan"),
        ("Termux:API", "tersedia" if which("termux-battery-status") else "tidak ada"),
    ]

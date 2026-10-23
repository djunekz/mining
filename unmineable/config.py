from __future__ import annotations

import json
import os
import re
import socket
from dataclasses import asdict, dataclass, field, fields

from . import coins, paths
from . import constants as C
from . import system


def default_worker():
    host = re.sub(r"[^A-Za-z0-9_-]", "", socket.gethostname())[:10]
    return f"termux-{host}" if host else "termux"


def safe_name(value):
    return re.sub(r"[^A-Za-z0-9_-]", "", str(value))[:24] or "default"


def safe_worker(value):
    return re.sub(r"[^A-Za-z0-9_-]", "", str(value))[:32] or "termux"


def safe_referral(value):
    return re.sub(r"[^A-Za-z0-9_-]", "", str(value))[:32]


def safe_alias(value):
    return re.sub(r"[\s.:#]", "", str(value))[:40]


def safe_memo(value):
    return re.sub(r"[\s.#:]", "", str(value))[:40]


def endpoint_url(host, port, tls):
    return f"stratum+ssl://{host}:{port}" if tls else f"{host}:{port}"


@dataclass
class Profile:
    name: str = "default"
    logged_in: bool = False
    login_time: str = ""
    mode: str = "address"
    alias: str = ""
    coin: str = ""
    address: str = ""
    memo: str = ""
    worker: str = field(default_factory=default_worker)
    referral: str = ""
    host: str = C.POOL_HOST
    port: int = C.POOL_PORT
    tls: bool = False
    failover: bool = True
    threads: int = 0
    cpu_limit: int = 100
    rx_mode: str = "auto"
    priority: int = 1
    donate: int = 1
    max_temp: float = 42.0
    resume_temp: float = 38.0
    min_battery: int = 20
    only_charging: bool = False
    notify_local: bool = True
    notify_telegram: bool = False
    telegram_token: str = ""
    telegram_chat: str = ""

    def username(self):
        if self.mode == "alias":
            return f"{self.alias}.{self.worker}"
        target = f"{self.address}:{self.memo}" if self.memo else self.address
        value = f"{self.coin}:{target}.{self.worker}"
        if self.referral:
            value += f"#{self.referral}"
        return value

    def session_ok(self):
        return self.logged_in and self.ready()

    def ready(self):
        if self.mode == "alias":
            return bool(self.alias)
        return bool(self.coin and self.address)

    def masked_address(self):
        if not self.address:
            return "-"
        if len(self.address) <= 14:
            return self.address
        return f"{self.address[:6]}…{self.address[-6:]}"

    def display_id(self):
        if self.mode == "alias":
            return f"alias {self.alias or '-'}"
        return f"{self.coin or '-'} · {self.masked_address()}"

    def endpoints(self):
        primary = (self.host, self.port, self.tls)
        result = [primary]
        if self.failover and self.host == C.POOL_HOST:
            for item in C.POOL_ENDPOINTS:
                if item not in result:
                    result.append(item)
        return result

    def effective_threads(self):
        cores = system.cpu_count()
        if self.threads > 0:
            return min(self.threads, cores)
        return max(1, cores // 2)

    def problems(self):
        found = []
        if self.mode == "alias":
            if not self.alias:
                found.append("Alias akun belum diatur")
        else:
            if not self.coin:
                found.append("Koin belum diatur")
            if not self.address:
                found.append("Alamat dompet belum diatur")
            elif self.coin:
                state, message = coins.validate(self.coin, self.address)
                if state is False:
                    found.append(message)
        if self.resume_temp >= self.max_temp:
            found.append("Suhu lanjut harus lebih rendah dari suhu pause")
        if not 1 <= self.port <= 65535:
            found.append("Port pool tidak valid")
        if self.rx_mode not in C.RX_MODES:
            found.append("Mode RandomX tidak dikenal")
        if self.notify_telegram and not (self.telegram_token and self.telegram_chat):
            found.append("Notifikasi Telegram aktif tetapi token/chat ID kosong")
        return found

    def to_dict(self):
        return asdict(self)

    @classmethod
    def from_dict(cls, data):
        profile = cls()
        for item in fields(cls):
            if item.name not in data:
                continue
            current = getattr(profile, item.name)
            raw = data[item.name]
            try:
                if isinstance(current, bool):
                    value = bool(raw)
                elif isinstance(current, int):
                    value = int(raw)
                elif isinstance(current, float):
                    value = float(raw)
                else:
                    value = str(raw)
            except (TypeError, ValueError):
                continue
            setattr(profile, item.name, value)
        return profile


def profile_path(name):
    return paths.PROFILES_DIR / f"{safe_name(name)}.json"


def list_profiles():
    paths.ensure()
    return sorted(p.stem for p in paths.PROFILES_DIR.glob("*.json"))


def exists(name):
    return profile_path(name).exists()


def load(name):
    try:
        data = json.loads(profile_path(name).read_text())
    except (OSError, ValueError):
        return None
    profile = Profile.from_dict(data)
    profile.name = safe_name(name)
    return profile


def save(profile):
    paths.ensure()
    profile.name = safe_name(profile.name)
    target = profile_path(profile.name)
    target.write_text(json.dumps(profile.to_dict(), indent=2, ensure_ascii=False))
    os.chmod(target, 0o600)


def delete(name):
    system.remove(profile_path(name))


def active_name():
    try:
        value = paths.ACTIVE_FILE.read_text().strip()
    except OSError:
        return "default"
    return safe_name(value)


def set_active(name):
    paths.ensure()
    paths.ACTIVE_FILE.write_text(safe_name(name))


def active():
    name = active_name()
    return load(name) or Profile(name=name)

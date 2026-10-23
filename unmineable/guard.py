from __future__ import annotations

import os
import signal
import subprocess
import sys
import time
from pathlib import Path

from . import api, config, connection, history, installer, miner, notify, paths, system
from . import constants as C


def decide(profile, battery, hot):
    if battery is None:
        return False, "", hot
    temp = battery.get("temp")
    if temp is not None:
        temp = float(temp)
        if hot:
            if temp >= profile.resume_temp:
                return True, f"menunggu dingin ({temp:.1f}°C)", True
            hot = False
        if temp >= profile.max_temp:
            return True, f"terlalu panas ({temp:.1f}°C)", True
    charging = battery.get("status") in ("CHARGING", "FULL")
    if profile.only_charging and not charging:
        return True, "mode hanya-charging", hot
    percent = battery.get("percent")
    if percent is not None and percent < profile.min_battery and not charging:
        return True, f"baterai rendah ({percent}%)", hot
    return False, "", hot


def log(message):
    paths.ensure()
    stamp = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(paths.GUARD_LOG, "a") as handle:
        handle.write(f"[{stamp}] {message}\n")


def pid():
    return system.read_pid(paths.GUARD_PID)


def is_running():
    return system.pid_alive(pid())


def _environment():
    env = dict(os.environ)
    root = str(Path(__file__).resolve().parent.parent)
    existing = env.get("PYTHONPATH")
    env["PYTHONPATH"] = root + (os.pathsep + existing if existing else "")
    env["PYTHONUNBUFFERED"] = "1"
    env["PYTHONSAFEPATH"] = "1"
    return env


def start_background():
    if is_running():
        return True
    paths.ensure()
    with open(paths.GUARD_LOG, "ab") as handle:
        subprocess.Popen(
            [sys.executable, "-m", "unmineable", "_guard"],
            stdout=handle,
            stderr=handle,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
            env=_environment(),
        )
    deadline = time.time() + 6
    while time.time() < deadline:
        if is_running():
            return True
        time.sleep(0.3)
    return False


def stop_background(timeout=20.0):
    current = pid()
    if current and system.pid_alive(current):
        try:
            os.kill(current, signal.SIGTERM)
        except OSError:
            pass
        deadline = time.time() + timeout
        while time.time() < deadline and system.pid_alive(current):
            time.sleep(0.3)
        if system.pid_alive(current):
            try:
                os.kill(current, signal.SIGKILL)
            except OSError:
                pass
    system.remove(paths.GUARD_PID)
    miner.stop(release_wake=True)


class Guard:
    def __init__(self):
        self.stop_flag = False
        self.hot = False
        self.paused = False
        self.crashes = 0
        self.next_try = 0.0
        self.last_record = 0.0
        self.announced_crash = False
        self.announced_link = False
        self.last_link_check = 0.0
        self.warned = set()

    def handle_signal(self, signum, frame):
        self.stop_flag = True

    def nap(self, seconds):
        end = time.time() + seconds
        while not self.stop_flag and time.time() < end:
            time.sleep(0.5)

    def run(self):
        paths.ensure()
        system.write_pid(paths.GUARD_PID, os.getpid())
        signal.signal(signal.SIGTERM, self.handle_signal)
        signal.signal(signal.SIGINT, self.handle_signal)
        log(f"guard aktif (pid {os.getpid()})")
        notify.send(config.active(), "unMineable", "Guard mining aktif")
        try:
            while not self.stop_flag:
                try:
                    self.tick()
                except Exception as error:
                    log(f"galat di guard: {error}")
                self.nap(C.LOOP_INTERVAL)
        finally:
            miner.stop(release_wake=True)
            system.remove(paths.GUARD_PID)
            log("guard berhenti")

    def note(self, key, message):
        if key not in self.warned:
            self.warned.add(key)
            log(message)

    def blocked(self, profile):
        if not profile.session_ok():
            self.note("login", "BELUM LOGIN: mining tidak dijalankan")
            return True
        self.warned.discard("login")
        if not installer.xmrig_ready():
            self.note("xmrig", "XMRIG TIDAK TERDETEKSI: mining tidak dijalankan")
            return True
        self.warned.discard("xmrig")
        return False

    def tick(self):
        profile = config.active()
        if self.blocked(profile):
            if miner.is_running():
                miner.stop()
                log("Mining dihentikan karena syarat login/XMRig tidak terpenuhi")
            return
        battery = system.battery()
        pause, reason, self.hot = decide(profile, battery, self.hot)
        running = miner.is_running()
        if pause:
            if running:
                miner.stop()
                log(f"PAUSE: {reason}")
                notify.send(profile, "Mining dijeda", reason)
            self.paused = True
            return
        if self.paused:
            self.paused = False
            log("LANJUT: kondisi normal")
            notify.send(profile, "Mining dilanjutkan", "Suhu dan baterai kembali normal")
            self.crashes = 0
        if not running:
            self.launch(profile)
        else:
            self.crashes = 0
            self.announced_crash = False
            self.watch_link(profile)
            self.sample(profile, battery)

    def launch(self, profile):
        if time.time() < self.next_try:
            return
        try:
            started = miner.start(profile)
        except RuntimeError as error:
            log(f"gagal start: {error}")
            started = False
        if started:
            log("START: XMRig berjalan")
            return
        self.crashes += 1
        delay = min(300, 15 * (2 ** min(self.crashes, 5)))
        self.next_try = time.time() + delay
        log(f"XMRig gagal/berhenti (percobaan {self.crashes}), coba lagi {delay} detik")
        if self.crashes >= 3 and not self.announced_crash:
            self.announced_crash = True
            notify.send(profile, "Mining bermasalah", "XMRig berulang kali berhenti, cek log")

    def watch_link(self, profile):
        if time.time() - self.last_link_check < 300:
            return
        self.last_link_check = time.time()
        findings = connection.log_findings()
        if findings["status"] == "error":
            if not self.announced_link:
                self.announced_link = True
                hint = connection.explain_error(findings["error"])
                log(f"MASALAH KONEKSI: {findings['error']}")
                notify.send(profile, "Mining tidak terhubung ke pool", hint)
        elif findings["status"] == "ok":
            self.announced_link = False

    def sample(self, profile, battery):
        if time.time() - self.last_record < C.HISTORY_INTERVAL:
            return
        summary = api.miner_summary()
        if not summary:
            return
        self.last_record = time.time()
        history.record(
            {
                "h10": summary["h10"],
                "h60": summary["h60"],
                "shares": summary["shares_good"],
                "temp": (battery or {}).get("temp"),
                "bat": (battery or {}).get("percent"),
            }
        )

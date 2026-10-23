from __future__ import annotations

import os
import signal
import subprocess
import time

from . import constants as C
from . import config, installer, paths, system, ui


def build_command(profile):
    binary = installer.xmrig_path()
    if not binary:
        raise RuntimeError("XMRig belum terpasang")
    command = [binary]
    for host, port, tls in profile.endpoints():
        command.extend(
            [
                "-o",
                config.endpoint_url(host, port, tls),
                "-a",
                C.ALGO,
                "-k",
                "-u",
                profile.username(),
                "-p",
                "x",
            ]
        )
    command.extend(
        [
            "-t",
            str(profile.effective_threads()),
            f"--donate-level={profile.donate}",
            f"--cpu-priority={profile.priority}",
            "--retries=3",
            "--retry-pause=5",
            "--print-time=60",
            "--no-color",
        ]
    )
    if profile.rx_mode != "auto":
        command.append(f"--randomx-mode={profile.rx_mode}")
    if profile.cpu_limit < 100:
        command.append(f"--cpu-max-threads-hint={profile.cpu_limit}")
    if installer.supports_http(binary):
        command.extend(["--http-host=127.0.0.1", f"--http-port={C.HTTP_PORT}"])
    return command


def pid():
    return system.read_pid(paths.MINER_PID)


def is_running():
    return system.pid_alive(pid())


def rotate_logs(limit_mb=C.LOG_LIMIT_MB):
    limit = limit_mb * 1024 * 1024
    for target in (paths.MINER_LOG, paths.GUARD_LOG):
        try:
            if target.stat().st_size > limit:
                backup = target.with_suffix(".log.1")
                system.remove(backup)
                target.rename(backup)
        except OSError:
            continue


def start(profile):
    if is_running():
        return True
    paths.ensure()
    command = build_command(profile)
    rotate_logs()
    system.wake_lock()
    with open(paths.MINER_LOG, "ab") as log:
        process = subprocess.Popen(
            command,
            stdout=log,
            stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )
    system.write_pid(paths.MINER_PID, process.pid)
    time.sleep(1.5)
    if process.poll() is not None:
        system.remove(paths.MINER_PID)
        return False
    return True


def stop(release_wake=False, timeout=8.0):
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
            time.sleep(0.3)
            system.reap(current)
    system.remove(paths.MINER_PID)
    if release_wake:
        system.wake_unlock()


def run_foreground(profile):
    command = build_command(profile)
    system.wake_lock()
    try:
        return ui.run_command_panel("Mining foreground", command)
    finally:
        system.wake_unlock()

from __future__ import annotations

import re

from . import installer, ui

SPEED = re.compile(r"speed 10s/60s/15m\s+([0-9.]+)")


def run(profile, threads=None):
    if not installer.xmrig_ready(deep=True):
        ui.fail("XMRig tidak terdeteksi. Pasang dulu lewat menu Instalasi & pembaruan.")
        return
    binary = installer.xmrig_path()
    count = threads or profile.effective_threads()
    command = [binary, "--bench=1M", "-t", str(count), "--no-color"]
    seen = {"rate": None}

    def watch(line):
        match = SPEED.search(line)
        if match:
            seen["rate"] = float(match.group(1))

    code = ui.run_command_panel(f"Benchmark RandomX 1M · {count} thread", command, on_line=watch)
    if code == 130:
        ui.warn("Benchmark dibatalkan")
    elif seen["rate"] is not None:
        ui.ok(f"Hashrate terakhir terbaca: {ui.human_rate(seen['rate'])} dengan {count} thread")

from __future__ import annotations

from . import history, paths, ui


def tail(path, count=20):
    try:
        data = path.read_bytes()[-200000:]
    except OSError:
        return []
    return data.decode("utf-8", "replace").splitlines()[-count:]


def show(path, count=50):
    lines = tail(path, count)
    if not lines:
        ui.warn("Belum ada log.")
        return
    print("\n".join(lines))


def follow(path):
    ui.follow_panel("Log XMRig (live)", path)


def sizes():
    rows = []
    for target in (paths.MINER_LOG, paths.GUARD_LOG, paths.HISTORY_FILE):
        try:
            rows.append((target.name, ui.human_size(target.stat().st_size)))
        except OSError:
            rows.append((target.name, "-"))
    return rows


def clear_all():
    for target in (paths.MINER_LOG, paths.GUARD_LOG):
        try:
            target.write_text("")
        except OSError:
            continue
    history.clear()

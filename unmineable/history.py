from __future__ import annotations

import json
import time

from . import paths


def record(entry):
    paths.ensure()
    payload = dict(entry)
    payload["t"] = int(time.time())
    with open(paths.HISTORY_FILE, "a") as handle:
        handle.write(json.dumps(payload) + "\n")
    trim()


def trim(limit=2000):
    try:
        lines = paths.HISTORY_FILE.read_text().splitlines()
    except OSError:
        return
    if len(lines) > limit:
        paths.HISTORY_FILE.write_text("\n".join(lines[-limit:]) + "\n")


def load(limit=60):
    try:
        lines = paths.HISTORY_FILE.read_text().splitlines()
    except OSError:
        return []
    entries = []
    for line in lines[-limit:]:
        try:
            entries.append(json.loads(line))
        except ValueError:
            continue
    return entries


def summary(entries):
    rates = [float(e.get("h10", 0) or 0) for e in entries]
    if not rates:
        return None
    return {
        "avg": sum(rates) / len(rates),
        "max": max(rates),
        "min": min(rates),
        "count": len(rates),
        "span": int(entries[-1].get("t", 0)) - int(entries[0].get("t", 0)),
    }


def clear():
    try:
        paths.HISTORY_FILE.unlink()
    except OSError:
        pass

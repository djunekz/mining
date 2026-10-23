from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request

from . import coins as coin_catalog
from . import constants as C

USER_AGENT = f"unmineable-termux/{C.VERSION}"


def get_json(url, timeout=15):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8", "replace"))
    except (urllib.error.URLError, ValueError, OSError):
        return None


def get_text(url, timeout=15):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.read().decode("utf-8", "replace")
    except (urllib.error.URLError, OSError):
        return None


def payload_data(payload):
    if isinstance(payload, dict) and payload.get("success", True) is not False:
        return payload.get("data")
    return None


def miner_summary(port=C.HTTP_PORT):
    data = get_json(f"http://127.0.0.1:{port}/2/summary", timeout=3)
    if not isinstance(data, dict):
        return None
    hashrate = data.get("hashrate") or {}
    totals = hashrate.get("total") or []

    def pick(index):
        if len(totals) > index and totals[index] is not None:
            return float(totals[index])
        return 0.0

    results = data.get("results") or {}
    connection = data.get("connection") or {}
    return {
        "h10": pick(0),
        "h60": pick(1),
        "h15": pick(2),
        "highest": float(hashrate.get("highest") or 0),
        "shares_good": int(results.get("shares_good") or 0),
        "shares_total": int(results.get("shares_total") or 0),
        "diff": results.get("diff_current") or 0,
        "uptime": int(data.get("uptime") or 0),
        "pool": connection.get("pool") or "-",
        "ping": connection.get("ping") or 0,
        "algo": data.get("algo") or "-",
        "version": data.get("version") or "",
        "threads": len(hashrate.get("threads") or []),
    }


def lookup_target(profile):
    return f"{profile.address}:{profile.memo}" if profile.memo else profile.address


def address_info(profile):
    target = urllib.parse.quote(lookup_target(profile), safe=":")
    coin = urllib.parse.quote(profile.coin, safe=":")
    return payload_data(get_json(f"{C.API_BASE}/address/{target}?coin={coin}", timeout=20))


def account_stats(uuid):
    return payload_data(get_json(f"{C.API_BASE}/account/{uuid}/stats", timeout=20))


def account_workers(uuid):
    return payload_data(get_json(f"{C.API_BASE}/account/{uuid}/workers", timeout=20))


def account_payments(uuid, page=1):
    return payload_data(get_json(f"{C.API_BASE}/account/{uuid}/payments?page={page}", timeout=20))


def coin_info(coin):
    symbol = urllib.parse.quote(coin_catalog.base(coin), safe="")
    return payload_data(get_json(f"{C.API_BASE}/coin/{symbol}", timeout=10))


def _collect(node, found):
    if isinstance(node, dict):
        symbol = node.get("symbol")
        if isinstance(symbol, str):
            found.add(symbol.upper())
        for value in node.values():
            _collect(value, found)
    elif isinstance(node, list):
        for value in node:
            _collect(value, found)


def coins():
    data = get_json(f"{C.API_BASE}/coin", timeout=20)
    found = set()
    _collect(data, found)
    return sorted(found)

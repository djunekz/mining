from __future__ import annotations

import urllib.error
import urllib.parse
import urllib.request

from . import system


def telegram(token, chat, text):
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    data = urllib.parse.urlencode({"chat_id": chat, "text": text}).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(url, data=data), timeout=10) as response:
            return response.status == 200
    except (urllib.error.URLError, OSError, ValueError):
        return False


def send(profile, title, message):
    result = {}
    if profile.notify_local:
        result["lokal"] = system.notification(title, message)
    if profile.notify_telegram and profile.telegram_token and profile.telegram_chat:
        text = f"{title}\n[{profile.worker}] {message}"
        result["telegram"] = telegram(profile.telegram_token, profile.telegram_chat, text)
    return result

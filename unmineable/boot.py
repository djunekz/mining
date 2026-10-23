from __future__ import annotations

import os

from . import paths

SCRIPT = (
    "#!/data/data/com.termux/files/usr/bin/sh\n"
    "termux-wake-lock\n"
    "unmineable start --quiet\n"
)


def enabled():
    return paths.BOOT_SCRIPT.exists()


def enable():
    paths.BOOT_DIR.mkdir(parents=True, exist_ok=True)
    paths.BOOT_SCRIPT.write_text(SCRIPT)
    os.chmod(paths.BOOT_SCRIPT, 0o755)


def disable():
    try:
        paths.BOOT_SCRIPT.unlink()
    except OSError:
        pass

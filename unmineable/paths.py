import os
from pathlib import Path

HOME = Path(os.environ.get("HOME", str(Path.home())))
PREFIX = Path(os.environ.get("PREFIX", "/usr/local"))

CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", str(HOME / ".config"))) / "unmineable"
DATA_DIR = HOME / ".unmineable"
BIN_DIR = DATA_DIR / "bin"
SRC_DIR = DATA_DIR / "src"
LOG_DIR = CONFIG_DIR / "logs"
PROFILES_DIR = CONFIG_DIR / "profiles"

ACTIVE_FILE = CONFIG_DIR / "active_profile"
HISTORY_FILE = CONFIG_DIR / "history.jsonl"
UPDATE_CACHE = CONFIG_DIR / "update_check.json"
MINER_PID = CONFIG_DIR / "xmrig.pid"
GUARD_PID = CONFIG_DIR / "guard.pid"
MINER_LOG = LOG_DIR / "xmrig.log"
GUARD_LOG = LOG_DIR / "guard.log"

BOOT_DIR = HOME / ".termux" / "boot"
BOOT_SCRIPT = BOOT_DIR / "unmineable-start"
LAUNCHER = PREFIX / "bin" / "unmineable"


def ensure():
    for folder in (CONFIG_DIR, DATA_DIR, BIN_DIR, SRC_DIR, LOG_DIR, PROFILES_DIR):
        folder.mkdir(parents=True, exist_ok=True)

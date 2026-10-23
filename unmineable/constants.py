import os

APP_NAME = "unmineable"
VERSION = "0.1.0"
AUTHOR = "djunekz"

REPO = "https://github.com/djunekz/unmineable"
REPO_GIT = REPO + ".git"
TARBALL_URL = "https://codeload.github.com/djunekz/unmineable/tar.gz/refs/heads/main"
RELEASES_API = os.environ.get("UNMINEABLE_RELEASE_API", "https://api.github.com/repos/djunekz/unmineable/releases/latest")
RELEASES_PAGE = REPO + "/releases"
XMRIG_REPO = "https://github.com/xmrig/xmrig"

SITE = "https://unmineable.com"
API_BASE = "https://api.unminable.com/v4"
SUPPORT_EMAIL = "support@unmineable.com"
SIGNIN_URL = "https://www.unmineable.com/account/signin"
WIZARD_URL = "https://www.unmineable.com/wizard"

POOL_HOST = "rx.unmineable.com"
POOL_PORT = 3333
POOL_ENDPOINTS = (
    ("rx.unmineable.com", 3333, False),
    ("rx.unmineable.com", 13333, False),
    ("rx.unmineable.com", 443, True),
    ("rx.unmineable.com", 80, False),
)
ALGO = "rx"
HTTP_PORT = 18080

LOOP_INTERVAL = 20
HISTORY_INTERVAL = 60
LOG_LIMIT_MB = 5
UPDATE_CHECK_HOURS = 12

RX_MODES = ("auto", "fast", "light")

LINKS = (
    ("login", "Login / Daftar akun (Sign In)", SIGNIN_URL),
    ("wizard", "Wizard resmi unMineable (buat .sh / .bat)", WIZARD_URL),
    ("home", "Beranda unMineable", SITE),
    ("coins", "Daftar koin yang didukung", SITE + "/coins"),
    ("simulator", "Simulator profit", SITE + "/simulator"),
    ("support", "Pusat bantuan", SITE + "/support"),
    ("x", "X resmi (@un_mineable)", "https://x.com/un_mineable"),
    ("instagram", "Instagram resmi (@unminable)", "https://instagram.com/unminable"),
    ("repo", "Repo tool ini", REPO),
)

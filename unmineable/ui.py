from __future__ import annotations

import atexit
import collections
import contextlib
import getpass
import io
import os
import re
import shutil
import subprocess
import sys
import textwrap
import threading
import time

from . import constants as C

ENABLED = sys.stdout.isatty() and "NO_COLOR" not in os.environ
ANSI_RE = re.compile(r"\033\[[0-9;]*m")
CONTROL_RE = re.compile(r"\033\[[0-9;?]*[A-Za-z]")
NOPAUSE = "nopause"

_fullscreen = False


def _code(value):
    return f"\033[{value}m" if ENABLED else ""


RESET = _code(0)
BOLD = _code(1)
RED = _code(31)
GREEN = _code(32)
YELLOW = _code(33)
BLUE = _code(34)
MAGENTA = _code(35)
CYAN = _code(36)
GRAY = _code(90)


def paint(text, *styles):
    if not ENABLED:
        return str(text)
    return "".join(styles) + str(text) + RESET


def visible_len(text):
    return len(ANSI_RE.sub("", text))


def pad(text, size):
    return text + " " * max(0, size - visible_len(text))


def center(text, size):
    gap = max(0, size - visible_len(text))
    left = gap // 2
    return " " * left + text + " " * (gap - left)


def screen_size():
    size = shutil.get_terminal_size((80, 24))
    return size.columns, size.lines


def screen_rows():
    return screen_size()[1]


def term_width():
    return max(40, min(screen_size()[0], 86))


def enter_screen():
    global _fullscreen
    if _fullscreen or not sys.stdout.isatty():
        return
    sys.stdout.write("\033[?1049h\033[3J\033[2J\033[H")
    sys.stdout.flush()
    _fullscreen = True
    atexit.register(leave_screen)


def leave_screen():
    global _fullscreen
    if not _fullscreen:
        return
    sys.stdout.write("\033[?1049l")
    sys.stdout.flush()
    _fullscreen = False


def clear():
    if sys.stdout.isatty():
        sys.stdout.write("\033[3J\033[2J\033[H")
        sys.stdout.flush()


def live(func):
    func._live = True
    return func


def box_lines(title="", lines=(), color=CYAN):
    inner = term_width() - 2
    label = f" {title} " if title else ""
    top = "╭─" + label + "─" * max(0, inner - 1 - len(label)) + "╮"
    rows = [paint(top, color)]
    for line in lines:
        if ANSI_RE.search(line):
            parts = [line]
        else:
            parts = textwrap.wrap(line, inner - 2, drop_whitespace=False) or [""]
        for part in parts:
            rows.append(paint("│", color) + " " + pad(part, inner - 2) + " " + paint("│", color))
    rows.append(paint("╰" + "─" * inner + "╯", color))
    return rows


def box(title="", lines=(), color=CYAN):
    print("\n".join(box_lines(title, lines, color)))


def banner_lines(compact=False):
    if compact:
        return [paint("UNMINEABLE", BOLD, CYAN) + paint(f"  v{C.VERSION}", GRAY)]
    inner = term_width() - 4
    lines = [
        center(paint("U N M I N E A B L E", BOLD, CYAN), inner),
        center(paint("XMRig Miner untuk Termux", GRAY), inner),
        center(paint(f"v{C.VERSION}  ·  github.com/{C.AUTHOR}/{C.APP_NAME}", GRAY), inner),
    ]
    return box_lines("", lines, CYAN)


def banner():
    print("\n".join(banner_lines()))


def ok(message):
    print(f"{paint('✓', GREEN, BOLD)} {message}")


def info(message):
    print(f"{paint('i', CYAN, BOLD)} {message}")


def warn(message):
    print(f"{paint('!', YELLOW, BOLD)} {message}")


def fail(message):
    print(f"{paint('✗', RED, BOLD)} {message}")


def step(number, total, message):
    tag = f"[{number}/{total}]"
    print(f"{paint(tag, MAGENTA, BOLD)} {message}")


def kv(pairs, width=13):
    return [f"{paint(str(key).ljust(width), GRAY)}{value}" for key, value in pairs]


def ask(label, default="", validator=None, secret=False):
    suffix = f" [{default}]" if str(default) != "" else ""
    prompt = f"{paint('›', CYAN, BOLD)} {label}{suffix}: "
    while True:
        try:
            raw = (getpass.getpass(prompt) if secret else input(prompt)).strip()
        except EOFError:
            raw = ""
        value = raw if raw else str(default)
        if validator:
            problem = validator(value)
            if problem:
                fail(problem)
                continue
        return value


def ask_int(label, default, low, high):
    def check(value):
        try:
            number = int(value)
        except ValueError:
            return "Masukkan angka bulat"
        if number < low or number > high:
            return f"Harus antara {low} dan {high}"
        return None

    return int(ask(label, default, check))


def ask_float(label, default, low, high):
    def check(value):
        try:
            number = float(value)
        except ValueError:
            return "Masukkan angka"
        if number < low or number > high:
            return f"Harus antara {low} dan {high}"
        return None

    return float(ask(label, default, check))


def confirm(label, default=False):
    hint = "Y/n" if default else "y/N"
    try:
        raw = input(f"{paint('?', YELLOW, BOLD)} {label} [{hint}]: ").strip().lower()
    except EOFError:
        raw = ""
    if not raw:
        return default
    return raw in ("y", "ya", "yes", "1")


def choose(label, options, default=None):
    for index, (_, text) in enumerate(options, 1):
        print(f"  {paint(str(index), CYAN, BOLD)}. {text}")
    start = 1
    if default is not None:
        for index, (value, _) in enumerate(options, 1):
            if value == default:
                start = index
    picked = ask_int(label, start, 1, len(options))
    return options[picked - 1][0]


def pause(message="Tekan Enter untuk kembali..."):
    try:
        input(paint(f"\n{message}", GRAY))
    except (EOFError, KeyboardInterrupt):
        print()


def table(headers, rows):
    widths = [visible_len(str(h)) for h in headers]
    for row in rows:
        for index, cell in enumerate(row):
            widths[index] = max(widths[index], visible_len(str(cell)))
    head = "  ".join(paint(pad(str(h), widths[i]), BOLD) for i, h in enumerate(headers))
    print(head)
    print(paint("  ".join("─" * w for w in widths), GRAY))
    for row in rows:
        print("  ".join(pad(str(cell), widths[i]) for i, cell in enumerate(row)))


def bar(value, maximum, size=20):
    ratio = 0.0 if maximum <= 0 else max(0.0, min(1.0, value / maximum))
    filled = int(round(ratio * size))
    return paint("█" * filled, GREEN) + paint("░" * (size - filled), GRAY) + f" {int(ratio * 100):>3d}%"


def sparkline(values, size=40):
    blocks = "▁▂▃▄▅▆▇█"
    data = [float(v) for v in values][-size:]
    if not data:
        return ""
    low, high = min(data), max(data)
    if high == low:
        return blocks[3] * len(data)
    scale = (len(blocks) - 1) / (high - low)
    return "".join(blocks[int((v - low) * scale)] for v in data)


def human_rate(value):
    value = float(value or 0)
    for unit in ("H/s", "kH/s", "MH/s", "GH/s"):
        if value < 1000 or unit == "GH/s":
            return f"{value:.1f} {unit}" if unit == "H/s" else f"{value:.2f} {unit}"
        value /= 1000
    return f"{value:.2f} GH/s"


def human_duration(seconds):
    seconds = int(seconds or 0)
    days, rest = divmod(seconds, 86400)
    hours, rest = divmod(rest, 3600)
    minutes, secs = divmod(rest, 60)
    parts = []
    if days:
        parts.append(f"{days}h")
    if hours:
        parts.append(f"{hours}j")
    if minutes:
        parts.append(f"{minutes}m")
    if secs or not parts:
        parts.append(f"{secs}d")
    return " ".join(parts)


def human_size(size):
    size = float(size)
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024 or unit == "GB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} GB"


def clean_line(raw):
    parts = [part for part in str(raw).replace("\n", "").split("\r") if part]
    text = parts[-1] if parts else ""
    return CONTROL_RE.sub("", text).expandtabs(4)


def paginate(lines):
    if not sys.stdout.isatty():
        print("\n".join(lines))
        return
    height = max(5, screen_rows() - 3)
    pages = [lines[i:i + height] for i in range(0, max(len(lines), 1), height)] or [[]]
    index = 0
    while True:
        clear()
        print("\n".join(pages[index]))
        if len(pages) == 1:
            pause()
            return
        footer = f"Halaman {index + 1}/{len(pages)}  ·  Enter lanjut  ·  b mundur  ·  q selesai"
        print(paint(footer, GRAY))
        try:
            key = input(f"{paint('›', CYAN, BOLD)} ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            return
        if key == "q":
            return
        if key == "b":
            index = max(0, index - 1)
        else:
            index += 1
            if index >= len(pages):
                return


def run_view(handler):
    clear()
    print(paint("Memproses...", GRAY))
    sys.stdout.flush()
    buffer = io.StringIO()
    with contextlib.redirect_stdout(buffer):
        try:
            handler()
        except KeyboardInterrupt:
            warn("Dibatalkan")
        except Exception as error:
            fail(f"Terjadi kesalahan: {error}")
    text = buffer.getvalue().rstrip("\n")
    paginate(text.splitlines() or ["(tidak ada keluaran)"])


def draw_panel(title, lines, footer=""):
    clear()
    limit = term_width() - 6
    body = [line[:limit] for line in lines]
    if footer:
        body = body + ["", footer]
    box(title, body, MAGENTA)


def panel_capacity():
    return max(3, screen_rows() - 7)


def run_command_panel(title, command, cwd=None, on_line=None):
    try:
        process = subprocess.Popen(
            command,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL,
            text=True,
            errors="replace",
            bufsize=1,
        )
    except OSError as error:
        fail(f"Gagal menjalankan {command[0]}: {error}")
        return 127
    tty = sys.stdout.isatty()
    window = collections.deque(maxlen=panel_capacity())
    footer = "Ctrl+C untuk menghentikan"
    last_draw = 0.0
    try:
        for raw in process.stdout:
            line = clean_line(raw)
            window.append(line)
            if on_line:
                on_line(line)
            if not tty:
                print(line)
                continue
            now = time.time()
            if now - last_draw > 0.15:
                draw_panel(title, window, footer)
                last_draw = now
        process.wait()
    except KeyboardInterrupt:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
        if tty:
            draw_panel(title, window, "Dihentikan")
        return 130
    if tty:
        draw_panel(title, window, "Selesai" if process.returncode == 0 else f"Berhenti dengan kode {process.returncode}")
    return process.returncode


def follow_panel(title, path):
    window = collections.deque(maxlen=panel_capacity())
    try:
        handle = open(path, "rb")
    except OSError:
        warn("Belum ada log. Mulai mining dulu.")
        return
    with handle:
        handle.seek(0, 2)
        size = handle.tell()
        handle.seek(max(0, size - 6000))
        for raw in handle.read().decode("utf-8", "replace").splitlines()[-window.maxlen:]:
            window.append(clean_line(raw))
        draw_panel(title, window, "Ctrl+C untuk kembali")
        try:
            while True:
                chunk = handle.read()
                if chunk:
                    for raw in chunk.decode("utf-8", "replace").splitlines():
                        window.append(clean_line(raw))
                    draw_panel(title, window, "Ctrl+C untuk kembali")
                time.sleep(0.8)
        except KeyboardInterrupt:
            print()


class Spinner:
    FRAMES = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    def __init__(self, text):
        self.text = text
        self._stop = threading.Event()
        self._thread = None

    def __enter__(self):
        if sys.stdout.isatty():
            self._thread = threading.Thread(target=self._spin, daemon=True)
            self._thread.start()
        else:
            print(self.text)
        return self

    def _spin(self):
        index = 0
        while not self._stop.is_set():
            frame = self.FRAMES[index % len(self.FRAMES)]
            sys.stdout.write(f"\r{paint(frame, CYAN)} {self.text}")
            sys.stdout.flush()
            index += 1
            time.sleep(0.1)

    def __exit__(self, *_):
        self._stop.set()
        if self._thread:
            self._thread.join()
            sys.stdout.write("\r" + " " * (visible_len(self.text) + 4) + "\r")
            sys.stdout.flush()
        return False


class Menu:
    def __init__(self, title, items, header=None, back="Kembali"):
        self.title = title
        self.items = items
        self.header = header
        self.back = back

    @staticmethod
    def _label(label):
        return label() if callable(label) else label

    def opener(self):
        def go():
            self.run()
            return NOPAUSE

        go._live = True
        return go

    def compose(self):
        _, rows = screen_size()
        budget = max(8, rows - 2)
        entries = [f"{paint('[' + key + ']', BOLD, CYAN)} {self._label(label)}" for key, label, _ in self.items]
        entries.append(f"{paint('[0]', BOLD, CYAN)} {self.back}")
        body = box_lines(self.title, entries, BLUE)
        head = []
        if self.header:
            for level in (0, 1):
                head = self.header(level)
                if len(head) + len(body) <= budget:
                    break
            else:
                head = []
        if len(head) + len(body) > budget:
            body = [paint(self.title, BOLD, BLUE)] + entries
        return head + body

    def run(self):
        while True:
            clear()
            print("\n".join(self.compose()))
            try:
                choice = input(f"{paint('›', CYAN, BOLD)} Pilih menu: ").strip().lower()
            except (EOFError, KeyboardInterrupt):
                print()
                return
            if choice in ("0", "q"):
                return
            if not choice:
                continue
            handler = None
            for key, _, action in self.items:
                if key.lower() == choice:
                    handler = action
                    break
            if handler is None:
                continue
            if getattr(handler, "_live", False):
                clear()
                try:
                    result = handler()
                except KeyboardInterrupt:
                    print()
                    warn("Dibatalkan")
                    result = None
                except Exception as error:
                    fail(f"Terjadi kesalahan: {error}")
                    result = None
                if result != NOPAUSE:
                    pause()
            else:
                run_view(handler)

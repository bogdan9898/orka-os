#!/usr/bin/env python3
"""Orka Calculator: the real window, off-screen. Clicks every key in every
mode, the bits, bases, word sizes, switches and history, types on the
keyboard, checks there are no QML warnings, and saves screenshots.

    python3 apps/calculator/tests/test_window.py [screenshot folder]

Needs PySide6 (and the JetBrainsMono Nerd Font for faithful screenshots).
"""

import json
import os
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parent
SHOTS = Path(sys.argv[1]) if len(sys.argv) > 1 else None

tmp = Path(tempfile.mkdtemp(prefix="orka-calc-test-"))
os.environ["XDG_CONFIG_HOME"] = str(tmp / "config")
os.environ["XDG_STATE_HOME"] = str(tmp / "state")
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")
THEMES = {
    "dark": {"name": "Orka", "mode": "dark", "colors": {"background": "#0d1620", "foreground": "#dce6ef",
             "accent": "#3fa7d6", "accent2": "#7fd1c7", "urgent": "#ef6461", "inactive": "#2e3d4d"}},
    "light": {"name": "Orka Light", "mode": "light", "colors": {"background": "#eef3f7", "foreground": "#1b2a38",
              "accent": "#1f7fb0", "accent2": "#2a9d8f", "urgent": "#d64545", "inactive": "#b8c5d1"}},
}
theme_file = tmp / "config/orka/current/theme.json"
theme_file.parent.mkdir(parents=True)
theme_file.write_text(json.dumps(THEMES["dark"]))

sys.path.insert(0, str(APP))
import main as calcmain  # noqa: E402  (reads the environment above)
from PySide6.QtCore import QUrl, qInstallMessageHandler, Qt, QMetaObject, QEvent  # noqa: E402
from PySide6.QtGui import QGuiApplication, QKeyEvent  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402
from PySide6.QtQuick import QQuickWindow  # noqa: E402,F401  (so the window comes back as a QQuickWindow)
from calculator import Calculator  # noqa: E402

warnings = []
qInstallMessageHandler(lambda mode, ctx, msg: warnings.append(msg) if "qml" in msg.lower() or (ctx.file or "").endswith(".qml") else None)

QGuiApplication.setDesktopFileName("org.orka.Calculator")
app = QGuiApplication(sys.argv)
calc = Calculator()
theme = calcmain.Theme()
bridge = calcmain.Bridge(calc)
pressed = []
real_press = calc.press
calc.press = lambda k: (pressed.append((k, real_press(k))), pressed[-1][1])[1]
engine = QQmlApplicationEngine()
engine.rootContext().setContextProperty("calc", bridge)
engine.rootContext().setContextProperty("theme", theme)
engine.load(QUrl.fromLocalFile(str(APP / "qml/Main.qml")))
win = engine.rootObjects()[0]

failures = []
count = 0


def check(name, got, want):
    global count
    count += 1
    if got != want:
        failures.append(f"{name}: got {got!r}, want {want!r}")


def settle():
    for _ in range(5):
        app.processEvents()


def all_items():
    """Every visible item (walks the visual tree: Repeater items have no
    QObject parent, so findChildren doesn't see them)."""
    out, todo = [], [win.contentItem()]
    while todo:
        it = todo.pop()
        if not it.isVisible():
            continue
        out.append(it)
        todo.extend(it.childItems())
    return out


def items(prefix):
    return [o for o in all_items() if o.objectName().startswith(prefix)]


def item(name):
    found = [o for o in items(name) if o.objectName() == name]
    if not found:
        raise LookupError(name)
    return found[0]


def click(name):
    QMetaObject.invokeMethod(item(name), "click")
    settle()


def text(name):
    return item(name).property("text")


def clicks(names):
    for n in names.split():
        click(n if ":" in n or n in ("history", "angle", "signed", "clearHistory") else "key:" + n)


def key(code, mods=Qt.NoModifier, text=""):
    for kind in (QEvent.KeyPress, QEvent.KeyRelease):
        QGuiApplication.sendEvent(win, QKeyEvent(kind, code, mods, text))
    settle()


def type_text(s):
    for ch in s:
        code = Qt.Key(ord(ch.upper())) if ch.isalnum() else Qt.Key_unknown
        key(code, Qt.NoModifier, ch)


def shot(name):
    if SHOTS:
        SHOTS.mkdir(parents=True, exist_ok=True)
        settle()
        win.grabWindow().save(str(SHOTS / f"{name}.png"))


settle()

# Every key in every mode: visible, handled by Python, and the right count.
expected_keys = {"standard": 24 + 5, "expert": 24 + 30 + 5, "programmer": 36}
for mode in ("standard", "expert", "programmer"):
    click("mode:" + mode)
    check(f"mode {mode}", bridge.mode, mode)
    keys = items("key:")
    check(f"{mode}: number of keys", len(keys), expected_keys[mode])
    for k in keys:
        kid = k.objectName()[4:]
        if not k.property("usable"):
            continue
        calc.press("ac") if mode != "programmer" or kid != "ac" else None
        pressed.clear()
        click(k.objectName())
        check(f"{mode}: key {kid} handled", pressed[:1], [(kid, True)])
    click("key:ac")

# Window size follows the mode.
sizes = {}
for mode in ("standard", "expert", "programmer"):
    click("mode:" + mode)
    sizes[mode] = (win.width(), win.height())
check("standard width", sizes["standard"][0], 380)
check("expert width", sizes["expert"][0], 760)
check("programmer width", sizes["programmer"][0], 720)

# Standard, by clicking
click("mode:standard")
clicks("ac d1 d2 dot d5 mul d4 add d8")
check("typed", text("main"), "12.5 × 4 + 8")
check("live preview", text("preview"), "= 58")
clicks("eq")
check("result", text("main"), "58")
check("last line", text("last"), "12.5 × 4 + 8 =")
clicks("ac d5 div d0 eq")
check("error shown", text("preview"), "Can't divide by zero")
clicks("ac d9 ms ac key:mr add d1 eq")
check("memory", text("main"), "10")
clicks("ac mod")   # mod on empty: 0 mod
check("mod key", text("main"), "0 mod")
clicks("ac")

# History panel in Standard mode
w0 = win.width()
click("history")
check("history opens in standard", bridge.historyOpen, True)
check("window grows for history", win.width(), w0 + 240)
shot("standard-history-dark")
click("history:0")
check("history entry used", text("main"), "10")
click("clearHistory")
check("history cleared", bridge.history, [])
click("history")
check("history closes", win.width(), w0)
clicks("ac")

# Expert
click("mode:expert")
click("angle")
check("RAD", item("angle").property("label"), "RAD")
click("angle")
clicks("second sin d0 dot d5 eq")
check("sin⁻¹ via clicks", text("main"), "30")
clicks("ac d2 pow d1 d0 eq")
check("2^10 via clicks", text("main"), "1,024")
clicks("ac")

# Programmer
click("mode:programmer")
clicks("dC")
check("C key types C", text("main"), "C")
clicks("ac")
check("AC clears", text("main"), "0")
click("bit:0")
click("bit:4")
check("bits flipped", text("main"), "11")
check("dec row", text("baseText:dec"), "17")
check("bin row", text("baseText:bin"), "1 0001")
click("base:dec")
check("dec base", text("main"), "17")
check("A–F disabled in dec", item("key:dA").property("usable"), False)
click("base:hex")
click("word:8")
check("BYTE greys bit 8", item("bit:8").property("usable"), False)
click("bit:7")
click("signed")
check("signed", text("baseText:dec"), "−111")
click("signed")
click("word:64")
clicks("ac dF dF and d0 dF eq")
check("AND via clicks", text("main"), "F")
clicks("not")
check("NOT via clicks", text("main"), "FFFFFFFFFFFFFFF0")
clicks("ac")

# Keyboard
click("mode:standard")
type_text("12+3*2")
key(Qt.Key_Return)
settle()
check("keyboard", text("main"), "18")
key(Qt.Key_Escape)
settle()
check("Escape clears", text("main"), "0")
key(Qt.Key_2, Qt.ControlModifier)
settle()
check("Ctrl+2 expert", bridge.mode, "expert")
key(Qt.Key_3, Qt.ControlModifier)
settle()
type_text("ff&f0")
key(Qt.Key_Return)
settle()
check("keyboard hex", text("main"), "F0")
key(Qt.Key_H, Qt.ControlModifier)
settle()
check("Ctrl+H", bridge.historyOpen, True)
key(Qt.Key_H, Qt.ControlModifier)
key(Qt.Key_Escape)
settle()

# Screenshots in both themes
for name, t in THEMES.items():
    theme_file.write_text(json.dumps(t))
    theme.reload()
    settle()
    check(f"theme {name} applied", theme.property("bg"), t["colors"]["background"])
    click("mode:standard")
    clicks("ac d1 d2 dot d5 mul d4 add d8")
    shot(f"standard-{name}")
    click("mode:expert")
    clicks("ac second")
    type_text("2*")
    clicks("pi")
    shot(f"expert-{name}")
    clicks("ac second")
    click("mode:programmer")
    clicks("ac dC d0 dF dF dE dE")
    check(f"C0FFEE in the hex row ({name})", text("baseText:hex"), "C0 FFEE")
    shot(f"programmer-{name}")
    clicks("ac")

check("no QML warnings", warnings, [])

if failures:
    print("\n".join(failures))
    print(f"FAILED {len(failures)} of {count}")
    sys.exit(1)
print(f"ok: {count} checks" + (f", screenshots in {SHOTS}" if SHOTS else ""))

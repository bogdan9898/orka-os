#!/usr/bin/env python3
"""Orka Calculator: the window (QML, Main.qml) and the Python behind it.

    orka-calculator [--mode standard|expert|programmer]

The colors follow the current OrkaOS theme (~/.config/orka/current/
theme.json, written by orka-settings) and change with it. Mode, history,
memory and the programmer settings are kept in
~/.local/state/orka/calculator.json.
"""

import json
import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from PySide6.QtCore import QObject, Property, Signal, Slot, QFileSystemWatcher, QTimer, Qt, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from calculator import Calculator, MODES
from engine import BASES

CONFIG = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
STATE = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "orka/calculator.json"
THEME = CONFIG / "orka/current/theme.json"

DEFAULT_COLORS = {"background": "#0d1620", "foreground": "#dce6ef", "accent": "#3fa7d6",
                  "accent2": "#7fd1c7", "urgent": "#ef6461", "inactive": "#2e3d4d"}


def mix(a, b, percent):
    """A color between a and b (percent of b), like orka-settings does."""
    a, b = a.lstrip("#"), b.lstrip("#")
    out = "".join("%02x" % round((int(a[i:i + 2], 16) * (100 - percent) + int(b[i:i + 2], 16) * percent) / 100)
                  for i in (0, 2, 4))
    return "#" + out


class Theme(QObject):
    """The current OrkaOS theme's colors, plus the shades the window uses."""
    changed = Signal()

    def __init__(self):
        super().__init__()
        self.c = dict(DEFAULT_COLORS)
        self.light = False
        self.watcher = QFileSystemWatcher(self)
        self.watcher.directoryChanged.connect(self.reload)
        self.watcher.fileChanged.connect(self.reload)
        self.reload()

    def reload(self, *_):
        # orka-settings replaces the file (write + rename): watch the folder too.
        for p in (THEME.parent, THEME):
            if p.exists() and str(p) not in self.watcher.directories() + self.watcher.files():
                self.watcher.addPath(str(p))
        try:
            data = json.loads(THEME.read_text())
            colors = data.get("colors", {})
            c = dict(DEFAULT_COLORS)
            for k in c:
                v = colors.get(k)
                if isinstance(v, str) and len(v) == 7 and v.startswith("#"):
                    c[k] = v
            self.c = c
            self.light = data.get("mode") == "light"
        except (OSError, ValueError, AttributeError):
            pass
        self.changed.emit()

    bg = Property(str, lambda s: s.c["background"], notify=changed)
    fg = Property(str, lambda s: s.c["foreground"], notify=changed)
    accent = Property(str, lambda s: s.c["accent"], notify=changed)
    accent2 = Property(str, lambda s: s.c["accent2"], notify=changed)
    urgent = Property(str, lambda s: s.c["urgent"], notify=changed)
    inactive = Property(str, lambda s: s.c["inactive"], notify=changed)
    # Shades between background and text, as in the mock-up.
    surface = Property(str, lambda s: mix(s.c["background"], s.c["foreground"], 7), notify=changed)
    key = Property(str, lambda s: mix(s.c["background"], s.c["foreground"], 8), notify=changed)
    keyop = Property(str, lambda s: mix(s.c["background"], s.c["foreground"], 12), notify=changed)
    line = Property(str, lambda s: mix(s.c["background"], s.c["foreground"], 22), notify=changed)
    dim = Property(str, lambda s: mix(s.c["foreground"], s.c["background"], 45), notify=changed)
    isLight = Property(bool, lambda s: s.light, notify=changed)


# Keyboard: Qt key codes and typed characters → key ids.
SCI_CHARS = {"+": "add", "-": "sub", "−": "sub", "*": "mul", "×": "mul", "x": "mul", "/": "div", "÷": "div",
             "^": "pow", "(": "lparen", ")": "rparen", "%": "mod", "!": "fact", ".": "dot", ",": "dot",
             "=": "eq", "p": "pi", "e": "e"}
PROG_CHARS = {"+": "add", "-": "sub", "−": "sub", "*": "mul", "×": "mul", "/": "div", "÷": "div",
              "(": "lparen", ")": "rparen", "%": "mod", "=": "eq", "&": "and", "|": "or", "~": "not",
              "<": "shl", ">": "shr"}


class Bridge(QObject):
    """The Calculator for QML: properties to show, slots for the keys."""
    changed = Signal()

    def __init__(self, calc):
        super().__init__()
        self.calc = calc
        self.saver = QTimer(self, singleShot=True, interval=400)
        self.saver.timeout.connect(self.save)

    def update(self):
        self.changed.emit()
        self.saver.start()

    def save(self):
        try:
            STATE.parent.mkdir(parents=True, exist_ok=True)
            tmp = STATE.with_suffix(".tmp")
            tmp.write_text(json.dumps(self.calc.to_state(), indent=1))
            tmp.replace(STATE)
        except OSError:
            pass

    # What the window shows
    mode = Property(str, lambda s: s.calc.mode, notify=changed)
    mainText = Property(str, lambda s: s.calc.main_text, notify=changed)
    previewText = Property(str, lambda s: s.calc.preview_text, notify=changed)
    lastText = Property(str, lambda s: s.calc.last_text, notify=changed)
    hasError = Property(bool, lambda s: s.calc.has_error, notify=changed)
    memorySet = Property(bool, lambda s: s.calc.memory_set, notify=changed)
    degrees = Property(bool, lambda s: s.calc.degrees, notify=changed)
    second = Property(bool, lambda s: s.calc.second, notify=changed)
    base = Property(str, lambda s: s.calc.base, notify=changed)
    word = Property(int, lambda s: s.calc.word, notify=changed)
    signed = Property(bool, lambda s: s.calc.signed, notify=changed)
    baseTexts = Property("QVariantMap", lambda s: s.calc.base_texts(), notify=changed)
    bits = Property("QVariantList", lambda s: s.calc.bits(), notify=changed)
    disabledKeys = Property("QVariantList", lambda s: s.calc.disabled_keys(), notify=changed)
    history = Property("QVariantList", lambda s: [{"expr": h["expr"], "result": h["result"]}
                                                  for h in s.calc.history_for_mode()], notify=changed)
    historyOpen = Property(bool, lambda s: s.calc.history_open, notify=changed)

    @Slot(str, result=bool)
    def press(self, key):
        ok = self.calc.press(key)
        self.update()
        return ok

    @Slot(str)
    def setMode(self, mode):
        self.calc.set_mode(mode)
        self.update()

    @Slot(str)
    def setBase(self, base):
        self.calc.set_base(base)
        self.update()

    @Slot(int)
    def setWord(self, word):
        self.calc.set_word(word)
        self.update()

    @Slot()
    def toggleSigned(self):
        self.calc.toggle_signed()
        self.update()

    @Slot(int)
    def flipBit(self, i):
        self.calc.flip_bit(i)
        self.update()

    @Slot(int)
    def useHistory(self, i):
        self.calc.use_history(i)
        self.update()

    @Slot()
    def clearHistory(self):
        self.calc.clear_history()
        self.update()

    @Slot()
    def toggleHistory(self):
        self.calc.history_open = not self.calc.history_open
        self.update()

    @Slot()
    def copy(self):
        c = self.calc
        v = c.memory_value()
        text = c.format_value(v) if v is not None else c.expression_text()
        QGuiApplication.clipboard().setText(text.replace(" ", "").replace("−", "-"))

    @Slot()
    def paste(self):
        text = QGuiApplication.clipboard().text().strip()
        for ch in text[:200]:
            if ch in " ,_'" and not (ch == "," and not self.calc.prog):
                continue
            self.type_char(ch)
        self.update()

    def type_char(self, ch):
        c = self.calc
        if c.prog:
            up = ch.upper()
            if up in "0123456789ABCDEF" and len(up) == 1:
                return c.press("d" + up)
            key = PROG_CHARS.get(ch)
        else:
            if ch.isdigit() and ch.isascii():
                return c.press("d" + ch)
            key = SCI_CHARS.get(ch) if c.mode == "expert" or ch not in "pe!" else None
        return c.press(key) if key else False

    @Slot(int, str, int, result=bool)
    def keyEvent(self, key, text, modifiers):
        """A key pressed in the window; True if it was used."""
        K = Qt.Key
        ctrl = bool(modifiers & Qt.KeyboardModifier.ControlModifier.value)
        if ctrl:
            if K.Key_1.value <= key <= K.Key_3.value:
                self.setMode(MODES[key - K.Key_1.value])
            elif key == K.Key_H.value:
                self.toggleHistory()
            elif key == K.Key_C.value:
                self.copy()
            elif key == K.Key_V.value:
                self.paste()
            else:
                return False
            return True
        if key in (K.Key_Return.value, K.Key_Enter.value):
            return self.press("eq")
        if key == K.Key_Backspace.value:
            return self.press("back")
        if key in (K.Key_Escape.value, K.Key_Delete.value):
            return self.press("ac")
        if text and len(text) == 1:
            ok = self.type_char(text)
            self.update()
            return ok
        return False


def main():
    args = sys.argv[1:]
    QGuiApplication.setDesktopFileName("org.orka.Calculator")   # the Wayland app id
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Calculator")
    app.setOrganizationName("OrkaOS")

    calc = Calculator()
    try:
        calc.from_state(json.loads(STATE.read_text()))
    except (OSError, ValueError):
        pass
    if "--mode" in args and args.index("--mode") + 1 < len(args):
        calc.set_mode(args[args.index("--mode") + 1])

    theme = Theme()
    bridge = Bridge(calc)
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("calc", bridge)
    engine.rootContext().setContextProperty("theme", theme)
    engine.load(QUrl.fromLocalFile(str(HERE / "qml" / "Main.qml")))
    if not engine.rootObjects():
        sys.exit(1)
    app.aboutToQuit.connect(bridge.save)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()

# Calculator

**Orka Calculator** (`orka-calculator`, the calculator key, or "Calculator" in the launcher) replaces GNOME Calculator. It's a small floating window in the OrkaOS look (square corners, flat keys, JetBrains Mono) and follows the theme and dark/light mode live.

Code: [`apps/calculator/`](../apps/calculator/), installed to `/usr/share/orka/apps/calculator/`.

## Modes

| Mode | What | Window |
|---|---|---|
| **Standard** | Digits, `+ − × ÷`, `mod`, `ans` (last result), `AC`, `⌫`, `¹/x`, `x²`, `√x`, `±`; memory `MC MR M+ M− MS` | 380 px wide |
| **Expert** | Standard plus 30 scientific keys: `2nd` (inverse functions), `π`, `e`, `( )`, `sin cos tan` and `sinh cosh tanh` (and inverses), `xʸ`, `ʸ√x`, `eˣ`, `10ˣ`, `2ˣ`, `ln`, `log`, `log₂`, `×10ⁿ`, `x³`, `∛x`, `\|x\|`, `n!`, `rand`, `⌊x⌋`, `⌈x⌉`, `round`, `nCr`, `nPr`; DEG/RAD switch | 760 px |
| **Programmer** | The value in HEX, DEC, OCT and BIN (click a row to type in that base; digits it doesn't have are greyed out), word size QWORD/DWORD/WORD/BYTE, signed/unsigned, all 64 bits (click to flip), `AND OR XOR NAND NOT << >> ROL ROR mod ±`, `A–F` | 720 px |

**History** (`History` button or Ctrl+H) opens on the right in every mode: the calculations of that mode, newest first; click one to use its result. Standard/Expert and Programmer keep separate expressions, history and answers.

While typing, the answer appears in teal under the expression; the line above shows the previous calculation. Errors (`Can't divide by zero`, `Not defined`) appear in red; `⌫` or the next key clears them.

Keys that work on the last number: `¹/x`, `x²`, `x³`, `√x`, `∛x`, `|x|`, `n!`, `±`, `⌊x⌋`, `⌈x⌉`, `round` (e.g. `2 + 9 √x` → `2 + √(9)`). In Programmer mode `NOT`, `±`, `ROL`, `ROR` and flipping a bit work on the whole value shown.

## Keyboard

| Keys | |
|---|---|
| Digits, `.` or `,`, `+ - * / ^ ( ) %` (mod), `!` and `p` (π), `e` in Expert | Type |
| Enter or `=` | Calculate |
| Backspace / Escape or Delete | `⌫` / `AC` |
| `a`–`f`, `& \| ~ < >` (AND OR NOT << >>) | Programmer |
| Ctrl+1 / 2 / 3 | Standard / Expert / Programmer |
| Ctrl+H | History |
| Ctrl+C / Ctrl+V | Copy the result / paste a number or expression |

## How it works

- **Python does the math** (`engine.py`): scientific modes use exact decimals (`decimal`, 34 digits, so 0.1 + 0.2 = 0.3), trigonometry goes through `math` and is cleaned of float noise (sin 30° = 0.5, sin 180° = 0, tan 90° is "Not defined"). Results show 16 significant digits; whole numbers up to 20 digits in full (20! = 2,432,902,008,176,640,000), bigger or tiny ones as `1.55e+25`. Programmer mode uses Python's unlimited integers, wrapped to the word size (two's complement when signed; `÷` and `mod` truncate like C; `>>` is arithmetic when signed). Expressions are parsed by our own parser (precedence, right-to-left `^`, implicit `2π` and `2(3+4)`), never `eval`.
- **The keys** (`calculator.py`): every button sends a key id (`d7`, `add`, `sqrt`, `dA`…) to `Calculator.press()`; no Qt in there, so it's testable on its own.
- **The window** (`qml/`, Qt Quick through PySide6, `main.py`): colors from `~/.config/orka/current/theme.json` (watched; the shades are mixed like `orka-settings` does), app id `org.orka.Calculator` (Hyprland floats, centers and keeps it fully opaque, `orka/windows.lua`).
- **Kept between runs** in `~/.local/state/orka/calculator.json`: mode, DEG/RAD, base, word size, signed, memory, answers, the last 50 calculations, whether History is open.

## Tests

```sh
python3 apps/calculator/tests/test_calculator.py          # the math and every key, no Qt needed (313 checks)
python3 apps/calculator/tests/test_window.py [shots/]     # the real window off-screen: clicks every key in every mode,
                                                          # bits, bases, word sizes, history, keyboard; screenshots (159 checks)
```

The installed system's self-test runs the first one (`calculator:` line).

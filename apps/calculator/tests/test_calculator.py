#!/usr/bin/env python3
"""Orka Calculator: tests for the math and every key (no Qt needed).

    python3 apps/calculator/tests/test_calculator.py
"""

import re
import sys
from decimal import Decimal
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parent
sys.path.insert(0, str(APP))

from calculator import Calculator  # noqa: E402

failures = []
count = 0


def check(name, got, want):
    global count
    count += 1
    if got != want:
        failures.append(f"{name}: got {got!r}, want {want!r}")


def run(keys, mode="standard", **setup):
    c = Calculator()
    c.set_mode(mode)
    for k, v in setup.items():
        if k == "base":
            c.set_base(v)
        elif k == "word":
            c.set_word(v)
        elif k == "signed":
            if v != c.signed:
                c.toggle_signed()
        elif k == "degrees":
            if v != c.degrees:
                c.toggle_angle()
    for k in keys.split():
        if k.startswith("@bit"):
            c.flip_bit(int(k[4:]))
        elif k.startswith("@base:"):
            c.set_base(k[6:])
        elif k.startswith("@word:"):
            c.set_word(int(k[6:]))
        elif k == "@signed":
            c.toggle_signed()
        elif not c.press(k):
            failures.append(f"{keys!r}: key {k!r} not handled in {mode}")
    return c


def result(keys, mode="standard", **setup):
    c = run(keys, mode, **setup)
    return c.area.error or c.main_text


# --- Standard ---------------------------------------------------------------
S = "standard"
check("12.5×4+8 preview", run("d1 d2 dot d5 mul d4 add d8").preview_text, "= 58")
check("no preview for 2 ×", run("d2 mul").preview_text, "")
check("no preview for −5", run("sub d5").preview_text, "")
check("preview for 2 × 3 +", run("d2 mul d3 add").preview_text, "= 6")
c = run("d1 d2 dot d5 mul d4 add d8 eq")
check("12.5×4+8", c.main_text, "58")
check("last line", c.last_text, "12.5 × 4 + 8 =")
check("0.1+0.2", result("d0 dot d1 add d0 dot d2 eq"), "0.3")
check("1÷3", result("d1 div d3 eq"), "0.3333333333333333")
check("2÷3", result("d2 div d3 eq"), "0.6666666666666667")
check("÷0", result("d5 div d0 eq"), "Can't divide by zero")
c = run("d5 div d0 eq back")
check("⌫ clears the error", (c.area.error, c.main_text), ("", "5 ÷ 0"))
check("7 mod 3", result("d7 mod d3 eq"), "1")
check("−7 mod 3", result("sub d7 mod d3 eq"), "2")
check("7.5 mod 2", result("d7 dot d5 mod d2 eq"), "1.5")
check("ans", result("d5 add d3 eq ac ans mul d2 eq"), "16")
check("ans before any result", result("ans add d1 eq"), "1")
check("AC", run("d1 d2 add d3 ac").main_text, "0")
check("AC clears last line", run("d1 add d1 eq ac").last_text, "")
check("⌫ digit", run("d1 d2 d3 back").main_text, "12")
check("⌫ to empty", run("d1 back back").main_text, "0")
check("⌫ operator", run("d1 add back").main_text, "1")
check("⌫ after result edits it", run("d1 d2 add d3 eq back").main_text, "1")
check("1/x", result("d4 inv eq"), "0.25")
check("1/x shows", run("d4 inv").main_text, "1 ÷ 4")
check("1/0", result("d0 inv eq"), "Can't divide by zero")
check("x² of a result", result("d2 add d3 eq sq eq"), "25")
check("x²", result("d3 sq eq"), "9")
check("√16", result("d1 d6 sqrt eq"), "4")
check("√ shows", run("d1 d6 sqrt").main_text, "√(16)")
check("√(2+3) not √((2+3))", run("d2 add d3 eq ac d1 add d2").main_text, "1 + 2")
check("√2", result("d2 sqrt eq"), "1.414213562373095")
check("±", run("d5 neg").main_text, "−5")
check("± twice", run("d5 neg neg").main_text, "5")
check("± of a negative result", result("d2 sub d7 eq neg eq"), "5")
check("± in the middle", result("d3 sub d5 neg eq"), "8")
check("0.5 from .", run("dot d5").main_text, "0.5")
check("one dot only", run("d1 dot dot d2").main_text, "1.2")
check("leading zeros", run("d0 d0 d7").main_text, "7")
check("operator replaces operator", result("d5 add mul d2 eq"), "10")
check("5 × −2", result("d5 mul sub d2 eq"), "−10")
check("+ on empty", result("add d3 eq"), "3")
check("− on empty", result("sub d3 eq"), "−3")
check("= with a trailing operator", result("d5 add eq"), "5")
check("2+3×4", result("d2 add d3 mul d4 eq"), "14")
check("big", result("d9 d9 d9 d9 d9 d9 d9 d9 d9 d9 mul d9 d9 d9 d9 d9 d9 d9 d9 d9 d9 eq"), "99,999,999,980,000,000,001")
check("grouping", result("d1 d2 d3 d4 d5 d6 d7 eq"), "1,234,567")
check("digit after result starts over", run("d1 add d1 eq d9").main_text, "9")
check("operator after result continues", result("d1 d0 div d3 eq mul d3 eq"), "10")
check("−5 result then +", result("d2 sub d7 eq add d1 eq"), "−4")
check("tiny", result("d1 div d1 d0 d0 d0 d0 d0 d0 d0 d0 d0 d0 d0 d0 eq"), "1e−12")
check("negative grouping", result("d0 sub d1 d2 d3 d4 eq"), "−1,234")
check("history", run("d1 add d1 eq d2 mul d3 eq").history[0]["expr"], "2 × 3")
c = run("d1 add d1 eq d2 mul d3 eq ac")
c.use_history(1)
check("use history", c.main_text, "2")
c = run("d5 ms ac mr add d1 eq")
check("MS / MR", c.main_text, "6")
c.press("mplus")
check("M+", c.memory, Decimal(11))
c.press("mminus")
c.press("mminus")
check("M−", c.memory, Decimal(-1))
c.press("mc")
check("MC", c.memory, None)
check("MR when empty does nothing", run("mc mr").main_text, "0")
check("MR after a number multiplies", result("d5 ms ac d2 mr eq"), "10")
check(") without ( is ignored", run("d2 rparen").main_text, "2")
check("precision kept after =", result("d1 div d3 eq mul d3 eq"), "1")
check("÷ shows", run("d8 div d2").main_text, "8 ÷ 2")

# --- Expert -------------------------------------------------------------------
E = "expert"
check("π", result("pi eq", E), "3.141592653589793")
check("2π", result("d2 pi eq", E), "6.283185307179586")
check("e", result("e eq", E), "2.718281828459045")
check("sin 30°", result("sin d3 d0 rparen eq", E), "0.5")
check("sin 30° (no ))", result("sin d3 d0 eq", E), "0.5")
check("cos 60°", result("cos d6 d0 eq", E), "0.5")
check("tan 45°", result("tan d4 d5 eq", E), "1")
check("tan 90°", result("tan d9 d0 eq", E), "Not defined")
check("tan −90°", result("tan sub d9 d0 eq", E), "Not defined")
check("sin 180°", result("sin d1 d8 d0 eq", E), "0")
check("sin π rad", result("sin pi eq", E, degrees=False), "0")
check("cos π rad", result("cos pi eq", E, degrees=False), "−1")
check("DEG/RAD switch", run("angle", E).degrees, False)
check("sin⁻¹ 0.5", result("second sin d0 dot d5 eq", E), "30")
check("2nd resets", run("second sin", E).second, False)
check("2nd shows", run("second sin", E).main_text, "sin⁻¹(")
check("cos⁻¹ 0", result("second cos d0 eq", E), "90")
check("tan⁻¹ 1", result("second tan d1 eq", E), "45")
check("sin⁻¹ 2", result("second sin d2 eq", E), "Not defined")
check("sinh 0", result("sinh d0 eq", E), "0")
check("cosh 0", result("cosh d0 eq", E), "1")
check("tanh 0", result("tanh d0 eq", E), "0")
check("sinh 1", result("sinh d1 eq", E), "1.1752011936438")
check("cosh⁻¹ 1", result("second cosh d1 eq", E), "0")
check("sinh⁻¹ 0", result("second sinh d0 eq", E), "0")
check("tanh⁻¹ 2", result("second tanh d2 eq", E), "Not defined")
check("ln e", result("ln e eq", E), "1")
check("ln −1", result("ln sub d1 eq", E), "Not defined")
check("log 1000", result("log d1 d0 d0 d0 eq", E), "3")
check("log₂ 8", result("log2 d8 eq", E), "3")
check("2^10", result("d2 pow d1 d0 eq", E), "1,024")
check("2^0.5", result("d2 pow d0 dot d5 eq", E), "1.414213562373095")
check("2^−1", result("d2 pow sub d1 eq", E), "0.5")
check("27 root 3", result("d2 d7 root d3 eq", E), "3")
check("−8 root 3", result("lparen sub d8 rparen root d3 eq", E), "−2")
check("(−8)^(1/3)", result("lparen sub d8 rparen pow lparen d1 div d3 rparen eq", E), "−2")
check("(−4)^0.5", result("lparen sub d4 rparen pow d0 dot d5 eq", E), "Not defined")
check("0^−1", result("d0 pow sub d1 eq", E), "Can't divide by zero")
check("eˣ", result("exp d1 eq", E), "2.718281828459045")
check("eˣ shows", run("exp d2", E).main_text, "e^2")
check("10ˣ", result("pow10 d3 eq", E), "1,000")
check("2ˣ", result("pow2 d1 d0 eq", E), "1,024")
check("×10ⁿ", result("d1 dot d5 ee d3 eq", E), "1,500")
check("×10ⁿ shows", run("d1 dot d5 ee d3", E).main_text, "1.5E3")
check("×10⁻ⁿ", result("d1 ee sub d3 eq", E), "0.001")
check("x³", result("d3 cube eq", E), "27")
check("∛27", result("d2 d7 cbrt eq", E), "3")
check("−∛8", result("sub d8 cbrt eq", E), "−2")
check("∛(−8)", result("lparen sub d8 rparen cbrt eq", E), "−2")
check("∛ shows", run("lparen sub d8 rparen cbrt", E).main_text, "∛(−8)")
check("|−5|", result("lparen sub d5 rparen abs eq", E), "5")
check("5!", result("d5 fact eq", E), "120")
check("0!", result("d0 fact eq", E), "1")
check("2.5!", result("d2 dot d5 fact eq", E), "n! needs a whole number ≥ 0")
check("20!", result("d2 d0 fact eq", E), "2,432,902,008,176,640,000")
c = run("rand", E)
v = Decimal(c.tokens[0][1])
check("rand in [0,1)", 0 <= v < 1, True)
check("⌊2.7⌋", result("d2 dot d7 floor eq", E), "2")
check("⌈2.1⌉", result("d2 dot d1 ceil eq", E), "3")
check("round 2.5", result("d2 dot d5 round eq", E), "3")
check("⌊−2.5⌋", result("lparen sub d2 dot d5 rparen floor eq", E), "−3")
check("5 nCr 2", result("d5 ncr d2 eq", E), "10")
check("5 nPr 2", result("d5 npr d2 eq", E), "20")
check("5 nCr 7", result("d5 ncr d7 eq", E), "0")
check("2.5 nCr 1", result("d2 dot d5 ncr d1 eq", E), "nCr and nPr need whole numbers ≥ 0")
check("(2+3)×4", result("lparen d2 add d3 rparen mul d4 eq", E), "20")
check("(2+3)(4)", result("lparen d2 add d3 rparen lparen d4 rparen eq", E), "20")
check("−2²", result("sub d2 sq eq", E), "−4")
check("2^3^2 (right to left)", result("d2 pow d3 pow d2 eq", E), "512")
check("auto-close )", result("lparen lparen d1 add d2 mul d3 eq", E), "7")
check("( after number multiplies", result("d2 lparen d3 rparen eq", E), "6")
check("sin after number multiplies", result("d2 sin d3 d0 eq", E), "1")

# --- Programmer ---------------------------------------------------------------
P = "programmer"
c = run("dF dF eq", P)
check("FF", c.main_text, "FF")
check("FF dec", c.base_texts()["dec"], "255")
check("FF oct", c.base_texts()["oct"], "377")
check("FF bin", c.base_texts()["bin"], "1111 1111")
check("hex: no disabled digits", run("", P).disabled_keys(), [])
check("dec disables A–F", run("", P, base="dec").disabled_keys(), ["dA", "dB", "dC", "dD", "dE", "dF"])
check("oct disables 8–F", run("", P, base="oct").disabled_keys()[:2], ["d8", "d9"])
check("bin disables 2–F", len(run("", P, base="bin").disabled_keys()), 14)
check("C types C in hex", run("dC", P).main_text, "C")
check("AC clears in programmer", run("dC dA dF dE ac", P).main_text, "0")
check("⌫ in programmer", run("dC dA dF back", P).main_text, "CA")
check("digit not in base ignored", run("dF d2", P, base="bin").main_text, "0")
check("bin digits", run("d1 d0 d1", P, base="bin").base_texts()["dec"], "5")
check("hex E is a digit, not ×10ⁿ", run("dC d0 dF dF dE dE", P).base_texts()["hex"], "C0 FFEE")
check("hex E then +", result("dE add d1 eq", P), "F")
check("hex E then −", result("dE sub d1 eq", P), "D")
check("25! in scientific notation", result("d2 d5 fact eq", E), "1.551121004333099e+25")
check("AND", result("dF dF and dF d0 eq", P), "F0")
check("OR", result("dF d0 or d0 dF eq", P), "FF")
check("XOR", result("dF dF xor d0 dF eq", P), "F0")
check("NAND 64", result("dF dF nand d0 dF eq", P), "FFFF FFFF FFFF FFF0")
check("NAND 8", result("dF dF nand d0 dF eq", P, word=8), "F0")
check("<<", result("d1 shl d4 eq", P), "10")
check(">>", result("dF d0 shr d4 eq", P), "F")
check("NOT 64", run("d0 not", P).main_text, "FFFFFFFFFFFFFFFF")
check("NOT 8", run("d0 not", P, word=8).main_text, "FF")
check("ROL 8", run("d8 d0 rol", P, word=8).main_text, "1")
check("ROR 8", run("d1 ror", P, word=8).main_text, "80")
check("± unsigned 8", run("d1 neg", P, word=8).main_text, "FF")
c = run("d5 neg", P, base="dec", signed=True, word=8)
check("± signed dec", c.main_text, "−5")
check("± signed hex value", c.base_texts()["hex"], "FB")
check("wraps at 8 bits", result("dF dF add d1 eq", P, word=8), "0")
check("signed 8-bit overflow", result("d1 d2 d7 add d1 eq", P, base="dec", signed=True, word=8), "−128")
check("signed ÷ truncates", result("sub d7 div d2 eq", P, base="dec", signed=True), "−3")
check("signed mod", result("sub d7 mod d2 eq", P, base="dec", signed=True), "−1")
check("÷0", result("d5 div d0 eq", P), "Can't divide by zero")
check("mod 0", result("d5 mod d0 eq", P), "Can't divide by zero")
check("base switch keeps value", run("dF dF @base:dec", P).main_text, "255")
check("base switch to bin", run("dF @base:bin", P).main_text, "1111")
check("digits that don't fit are refused", run("dF dF dF", P, word=8).main_text, "FF")
check("flip bit 0", run("@bit0", P).main_text, "1")
check("flip bits 0 and 4", run("@bit0 @bit4", P).main_text, "11")
check("flip bit 63", run("@bit0 @bit63", P).main_text, "8000000000000001")
check("flip bit back", run("@bit3 @bit3", P).main_text, "0")
check("flip outside word ignored", run("@bit9", P, word=8).main_text, "0")
check("flip on an expression", run("d5 add d3 @bit0", P).main_text, "9")
check("bits list", run("d5", P).bits()[:4], [1, 0, 1, 0])
check("− on empty, unsigned 8", result("sub d1 eq", P, word=8), "FF")
check("1+2×3", result("d1 add d2 mul d3 eq", P), "7")
check("1 OR 2 AND 3", result("d1 or d2 and d3 eq", P), "3")
check(">> signed (arithmetic)", result("d8 d0 shr d1 eq", P, word=8, signed=True), "C0")
check(">> unsigned (logical)", result("d8 d0 shr d1 eq", P, word=8), "40")
check("word change wraps", run("d1 d2 d3 d4 @word:8", P).main_text, "34")
check("signed switch keeps bits", run("dF dF @signed", P, word=8).base_texts()["dec"], "−1")
check("parens", result("lparen d1 add d2 rparen mul d3 eq", P), "9")
check("prog history", run("d1 add d1 eq", P).history_for_mode()[0]["result"], "2")
c = run("d1 add d1 eq ac", P)
c.use_history(0)
check("prog use history", c.main_text, "2")
check("modes keep their own expression", run("d7", S).areas["prog"].tokens, [])
c = Calculator()
c.press("d7")
c.set_mode("programmer")
c.press("d1")
c.set_mode("standard")
check("standard expression kept", c.main_text, "7")

# --- Every key in the window exists in its mode ---------------------------------
qml = APP / "qml"
ids = lambda f: re.findall(r'\bid: "(\w+)"', (qml / f).read_text())
for f, mode in (("StandardKeys.qml", S), ("StandardKeys.qml", E), ("ExpertKeys.qml", E),
                ("ProgrammerKeys.qml", P), ("Main.qml", S)):
    for k in ids(f):
        c = Calculator()
        c.set_mode(mode)
        check(f"{f} key {k} works in {mode}", c.press(k), True)

# Saving and loading
c = run("d5 ms d1 add d1 eq", S)
c.set_mode("programmer")
c.set_base("dec")
d = Calculator()
d.from_state(c.to_state())
check("state round trip", (d.mode, d.base, d.memory, len(d.history)), ("programmer", "dec", Decimal(5), 1))
d.from_state({"mode": 5, "history": "x", "memory": "abc"})
check("damaged state ignored", d.mode, "programmer")

if failures:
    print("\n".join(failures))
    print(f"FAILED {len(failures)} of {count}")
    sys.exit(1)
print(f"ok: {count} checks")

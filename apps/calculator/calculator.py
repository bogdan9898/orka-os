"""Orka Calculator: what the keys do (no Qt here, so it's testable on its own).

Every button in the window sends a key id to Calculator.press(); the window
shows what the properties below say. Two separate expressions are kept: one
for Standard/Expert (exact decimals) and one for Programmer (integers).

Key ids
  both:        d0…d9 add sub mul div mod lparen rparen eq ac back
  standard:    dot ans inv sq sqrt neg  mc mr mplus mminus ms
  expert:      second pi e lparen rparen sin cos tan sinh cosh tanh pow root
               ln log log2 exp (eˣ) pow10 (10ˣ) pow2 (2ˣ) ee (×10ⁿ) cube cbrt
               abs fact rand floor ceil round ncr npr angle (DEG/RAD)
  programmer:  dA…dF and or xor nand not shl shr rol ror neg
"""

from decimal import Decimal
import random

from engine import (CalcError, SciEvaluator, ProgEvaluator, format_decimal, format_int,
                    normalize, bits_of, BASES)

MODES = ("standard", "expert", "programmer")
WORDS = (64, 32, 16, 8)
HISTORY_MAX = 50

SCI_OPS = {"add": "+", "sub": "−", "mul": "×", "div": "÷", "mod": "mod", "pow": "^", "root": "root",
           "ncr": "ncr", "npr": "npr"}
PROG_OPS = {"add": "+", "sub": "−", "mul": "×", "div": "÷", "mod": "mod", "and": "and", "or": "or",
            "xor": "xor", "nand": "nand", "shl": "shl", "shr": "shr"}
OP_TEXT = {"+": " + ", "−": " − ", "×": " × ", "÷": " ÷ ", "mod": " mod ", "^": "^", "root": " root ",
           "ncr": " nCr ", "npr": " nPr ",
           "and": " AND ", "or": " OR ", "xor": " XOR ", "nand": " NAND ", "shl": " << ", "shr": " >> "}
FUNC_TEXT = {"sin": "sin(", "cos": "cos(", "tan": "tan(", "asin": "sin⁻¹(", "acos": "cos⁻¹(",
             "atan": "tan⁻¹(", "sinh": "sinh(", "cosh": "cosh(", "tanh": "tanh(", "asinh": "sinh⁻¹(",
             "acosh": "cosh⁻¹(", "atanh": "tanh⁻¹(", "ln": "ln(", "log": "log(", "log2": "log₂(",
             "sqrt": "√(", "cbrt": "∛(", "abs": "abs(", "floor": "floor(", "ceil": "ceil(", "round": "round("}
CONST_TEXT = {"pi": "π", "e": "e", "ans": "ans"}
MAX_DIGITS = 40


class Area:
    """One expression being typed, and what happened to it last."""

    def __init__(self):
        self.tokens = []
        self.done = False      # showing the result of "="
        self.error = ""        # why the last "=" failed
        self.last = ""         # the previous calculation, shown above ("12 × 3 =")
        self.value = None      # the result of "=" while done


def is_unary_position(tokens, i):
    """Is the "−" at tokens[i] a sign rather than a subtraction?"""
    return i == 0 or tokens[i - 1][0] in ("op", "(", "func")


def ends_operand(tok):
    return tok[0] in ("num", ")", "const", "post")


class Calculator:
    def __init__(self):
        self.mode = "standard"
        self.areas = {"sci": Area(), "prog": Area()}
        self.ans = Decimal(0)
        self.prog_ans = 0
        self.memory = None
        self.degrees = True
        self.second = False
        self.base = "hex"
        self.word = 64
        self.signed = False
        self.history = []          # newest first: {area, expr, result, value}
        self.history_open = False

    # --- State -------------------------------------------------------------

    @property
    def prog(self):
        return self.mode == "programmer"

    @property
    def area(self):
        return self.areas["prog" if self.prog else "sci"]

    @property
    def tokens(self):
        return self.area.tokens

    def sci_eval(self):
        return SciEvaluator(self.degrees, self.ans)

    def prog_eval(self):
        return ProgEvaluator(self.base, self.word, self.signed, self.prog_ans)

    def evaluate(self, tokens):
        return (self.prog_eval() if self.prog else self.sci_eval()).run(tokens)

    def trimmed(self, tokens=None):
        """The expression without what's still unfinished at its end
        ("5 × (" → "5"), for the live preview and the programmer value."""
        toks = list(self.tokens if tokens is None else tokens)
        exponent = not self.prog    # "1.5E" is an unfinished ×10ⁿ; in hex, E is a digit
        while toks and (toks[-1][0] in ("op", "(", "func") or
                        (exponent and toks[-1][0] == "num" and toks[-1][1].endswith(("E", "E-")))):
            if toks[-1][0] == "num":
                toks[-1] = ("num", toks[-1][1].rstrip("-").rstrip("E"), None)
                break
            toks.pop()
        return toks

    def current_value(self):
        toks = self.trimmed()
        if not toks:
            return None
        try:
            return self.evaluate(toks)
        except CalcError:
            return None

    # --- Display -----------------------------------------------------------

    def token_text(self, i, tokens=None):
        toks = self.tokens if tokens is None else tokens
        tok = toks[i]
        kind = tok[0]
        if kind == "num":
            return tok[1]
        if kind == "op":
            if tok[1] == "−" and is_unary_position(toks, i):
                return "−"
            return OP_TEXT[tok[1]]
        if kind == "(":
            return "("
        if kind == ")":
            return ")"
        if kind == "func":
            return FUNC_TEXT[tok[1]]
        if kind == "const":
            return CONST_TEXT[tok[1]]
        return "!"

    def expression_text(self, tokens=None):
        toks = self.tokens if tokens is None else tokens
        return "".join(self.token_text(i, toks) for i in range(len(toks))).strip()

    @property
    def main_text(self):
        """The big line: what's being typed, or the result."""
        a = self.area
        if a.done and a.value is not None:
            return self.format_value(a.value, group=True)
        return self.expression_text() or "0"

    @property
    def preview_text(self):
        """The small line under it: "= 58" while typing, or the error."""
        a = self.area
        if a.error:
            return a.error
        if a.done or not self.tokens:
            return ""
        if self.prog:
            return ""   # the base rows show the value
        toks = self.trimmed()
        if all(t[0] == "num" for t in toks) or (len(toks) == 2 and toks[0] == ("op", "−") and toks[1][0] == "num"):
            return ""   # just a number ("2 ×" too): nothing to preview
        v = self.current_value()
        return "= " + format_decimal(v, group=True) if v is not None else ""

    @property
    def last_text(self):
        return self.area.last

    @property
    def has_error(self):
        return bool(self.area.error)

    def format_value(self, v, group=False):
        if self.prog:
            return format_int(v, self.base, self.word, group=group)
        return format_decimal(v, group=group)

    # Programmer panel
    @property
    def prog_value(self):
        a = self.areas["prog"]
        if a.done and a.value is not None:
            return a.value
        if not self.prog:
            return 0
        v = self.current_value()
        return 0 if v is None else v

    def base_texts(self):
        v = self.prog_value
        return {b: format_int(v, b, self.word) for b in BASES}

    def bits(self):
        u = bits_of(self.prog_value, self.word)
        return [(u >> i) & 1 for i in range(64)]

    def disabled_keys(self):
        if not self.prog:
            return []
        radix = BASES[self.base]
        return ["d" + "0123456789ABCDEF"[i] for i in range(radix, 16)]

    @property
    def memory_set(self):
        return self.memory is not None

    def history_for_mode(self):
        area = "prog" if self.prog else "sci"
        return [h for h in self.history if h["area"] == area]

    # --- Keys --------------------------------------------------------------

    def press(self, key):
        """Handle a key id; False if it isn't one (or does nothing here)."""
        handler = (self.prog_handlers() if self.prog else self.sci_handlers()).get(key)
        if handler is None:
            return False
        handler()
        return True

    def sci_handlers(self):
        h = {"d%d" % n: (lambda n=n: self.digit(str(n))) for n in range(10)}
        h.update({k: (lambda op=op: self.operator(op)) for k, op in SCI_OPS.items()})
        h.update({f: (lambda f=f: self.function(f)) for f in
                  ("sin", "cos", "tan", "sinh", "cosh", "tanh", "ln", "log", "log2")})
        h.update({
            "dot": lambda: self.digit("."), "ee": self.exponent_entry,
            "lparen": self.lparen, "rparen": self.rparen, "eq": self.equals,
            "ac": self.clear_all, "back": self.backspace,
            "ans": lambda: self.operand([("const", "ans")]),
            "pi": lambda: self.operand([("const", "pi")]),
            "e": lambda: self.operand([("const", "e")]),
            "rand": lambda: self.operand([("num", "%.10f" % random.random(), None)]),
            "pow10": lambda: self.operand([("num", "10", None), ("op", "^")]),
            "pow2": lambda: self.operand([("num", "2", None), ("op", "^")]),
            "exp": lambda: self.operand([("const", "e"), ("op", "^")]),
            "inv": lambda: self.wrap("inv"), "sq": lambda: self.wrap("sq"), "cube": lambda: self.wrap("cube"),
            "sqrt": lambda: self.wrap("sqrt"), "cbrt": lambda: self.wrap("cbrt"),
            "abs": lambda: self.wrap("abs"), "fact": lambda: self.wrap("fact"), "neg": lambda: self.wrap("neg"),
            "floor": lambda: self.wrap("floor"), "ceil": lambda: self.wrap("ceil"),
            "round": lambda: self.wrap("round"),
            "mc": self.memory_clear, "mr": self.memory_recall, "ms": self.memory_store,
            "mplus": lambda: self.memory_add(1), "mminus": lambda: self.memory_add(-1),
            "second": self.toggle_second, "angle": self.toggle_angle,
        })
        return h

    def prog_handlers(self):
        h = {"d" + c: (lambda c=c: self.prog_digit(c)) for c in "0123456789ABCDEF"}
        h.update({k: (lambda op=op: self.operator(op)) for k, op in PROG_OPS.items()})
        h.update({
            "lparen": self.lparen, "rparen": self.rparen, "eq": self.equals,
            "ac": self.clear_all, "back": self.backspace,
            "not": lambda: self.prog_action("not"), "neg": lambda: self.prog_action("neg"),
            "rol": lambda: self.prog_action("rol"), "ror": lambda: self.prog_action("ror"),
        })
        return h

    # Typing

    def start_fresh_if_done(self):
        a = self.area
        if a.done:
            a.tokens = []
            a.done = False
            a.value = None
        a.error = ""

    def continue_from_result(self):
        a = self.area
        a.done = False
        a.value = None
        a.error = ""

    def digit(self, ch):
        self.start_fresh_if_done()
        toks = self.tokens
        if toks and toks[-1][0] == "num" and toks[-1][2] is None:
            text = toks[-1][1]
            if ch == ".":
                if "." in text or "E" in text:
                    return
                text += "."
            elif text == "0":
                text = ch
            elif text == "-0":
                text = "-" + ch
            else:
                if len(text.replace(".", "")) >= MAX_DIGITS:
                    return
                text += ch
            toks[-1] = ("num", text, None)
            return
        if toks and ends_operand(toks[-1]):
            toks.append(("op", "×"))
        toks.append(("num", "0." if ch == "." else ch, None))

    def exponent_entry(self):
        """×10ⁿ: 1.5E3 = 1500."""
        self.start_fresh_if_done()
        toks = self.tokens
        if toks and toks[-1][0] == "num" and toks[-1][2] is None and "E" not in toks[-1][1]:
            toks[-1] = ("num", toks[-1][1].rstrip(".") + "E", None)

    def prog_digit(self, ch):
        radix = BASES[self.base]
        if int(ch, 16) >= radix:
            return
        self.start_fresh_if_done()
        toks = self.tokens
        limit = (1 << self.word) - 1
        if toks and toks[-1][0] == "num":
            text = "" if toks[-1][1] == "0" else toks[-1][1]
            if int(text + ch, radix) > limit:
                return      # wouldn't fit the word size
            toks[-1] = ("num", text + ch, None)
            return
        if toks and ends_operand(toks[-1]):
            toks.append(("op", "×"))
        toks.append(("num", ch, None))

    def operator(self, op):
        self.continue_from_result()
        toks = self.tokens
        if not self.prog and toks and toks[-1][0] == "num" and toks[-1][1].endswith("E"):
            if op == "−":
                toks[-1] = ("num", toks[-1][1] + "-", None)   # a negative exponent
                return
            toks[-1] = ("num", toks[-1][1][:-1], None)
        if not self.prog and toks and toks[-1][0] == "num" and toks[-1][1].endswith("E-"):
            return
        if toks and toks[-1][0] in ("(", "func"):
            if op == "−":
                toks.append(("op", "−"))
            return
        if toks and toks[-1][0] == "op":
            if op == "−" and toks[-1][1] != "−" and not is_unary_position(toks, len(toks) - 1):
                toks.append(("op", "−"))   # 5 × −3
                return
            while toks and toks[-1][0] == "op":
                toks.pop()                 # another operator replaces it
            if not toks:
                if op == "−":
                    toks.append(("op", "−"))
                    return
                toks.append(("num", "0", None))
            elif toks[-1][0] in ("(", "func"):
                return
            toks.append(("op", op))
            return
        if not toks:
            if op == "−":
                toks.append(("op", "−"))
                return
            toks.append(("num", "0", None))
        toks.append(("op", op))

    def operand(self, new):
        """Add a constant, ans, a random number, 10^, e^…"""
        self.start_fresh_if_done()
        toks = self.tokens
        if toks and ends_operand(toks[-1]):
            toks.append(("op", "×"))
        toks.extend(new)

    def function(self, name):
        if self.second and name in ("sin", "cos", "tan", "sinh", "cosh", "tanh"):
            name = "a" + name
        self.second = False
        self.operand([("func", name)])

    def lparen(self):
        self.operand([("(",)])

    def rparen(self):
        toks = self.tokens
        a = self.area
        if a.done:
            return
        depth = sum(1 for t in toks if t[0] in ("(", "func")) - sum(1 for t in toks if t[0] == ")")
        if depth > 0 and toks and ends_operand(toks[-1]):
            toks.append((")",))

    def operand_span(self):
        """Where the last operand starts (a number, constant, (…), f(…), x!),
        or None if the expression doesn't end with one."""
        toks = self.tokens
        i = len(toks) - 1
        if i < 0:
            return None
        while i >= 0 and toks[i][0] == "post":
            i -= 1
        if i < 0:
            return None
        kind = toks[i][0]
        if kind in ("num", "const"):
            return i
        if kind == ")":
            depth = 0
            while i >= 0:
                if toks[i][0] == ")":
                    depth += 1
                elif toks[i][0] in ("(", "func"):
                    depth -= 1
                    if depth == 0:
                        return i
                i -= 1
        return None

    def wrap(self, what):
        """1/x, x², x³, √x, ∛x, |x|, n!, ±: applied to the last operand."""
        a = self.area
        if a.done and a.value is not None:
            # Work on the exact result, not on its rounded text.
            a.tokens = self.value_tokens(a.value)
        self.continue_from_result()
        start = self.operand_span()
        if start is None:
            return
        toks = self.tokens
        span = toks[start:]
        head = toks[:start]
        if what == "neg":
            if head and head[-1] == ("op", "−") and is_unary_position(head, len(head) - 1):
                head = head[:-1]
            else:
                head = head + [("op", "−")]
            a.tokens = head + span
            return
        if what in ("sq", "cube"):
            a.tokens = head + span + [("op", "^"), ("num", "2" if what == "sq" else "3", None)]
            return
        if what == "fact":
            a.tokens = head + span + [("post", "!")]
            return
        if what == "inv":
            a.tokens = head + [("num", "1", None), ("op", "÷")] + span
            return
        name = what   # sqrt cbrt abs floor ceil round: f(operand)
        if span[0] == ("(",) and self.matching_paren(span) == len(span) - 1:
            a.tokens = head + [("func", name)] + span[1:]       # √(2+3), not √((2+3))
        else:
            a.tokens = head + [("func", name)] + span + [(")",)]

    @staticmethod
    def matching_paren(span):
        depth = 0
        for j, t in enumerate(span):
            if t[0] in ("(", "func"):
                depth += 1
            elif t[0] == ")":
                depth -= 1
                if depth == 0:
                    return j
        return -1

    def value_tokens(self, v):
        """A value as tokens (a negative one as "−" and its size)."""
        if self.prog:
            if self.base == "dec" and v < 0:
                return [("op", "−"), ("num", format_int(-v, "dec", self.word, group=False), None)]
            return [("num", format_int(v, self.base, self.word, group=False), None)]
        if v < 0:
            return [("op", "−"), ("num", format_decimal(-v), -v)]
        return [("num", format_decimal(v), v)]

    def prog_action(self, what):
        """NOT, ±, ROL, ROR: on the whole value shown."""
        v = self.current_value()
        if v is None:
            return
        ev = self.prog_eval()
        if what == "not":
            v = ev.bit_not(v)
        elif what == "neg":
            v = ev.norm(-v)
        else:
            v = ev.rotate(v, what == "rol")
        a = self.area
        a.tokens = self.value_tokens(v)
        a.done = False
        a.value = None
        a.error = ""

    def equals(self):
        a = self.area
        if a.done or not a.tokens:
            return
        toks = self.trimmed()
        if not toks:
            return
        try:
            value = self.evaluate(toks)
        except CalcError as e:
            a.error = str(e)
            return
        expr = self.expression_text(toks)
        if self.prog:
            self.prog_ans = value
        else:
            self.ans = value
        a.last = expr + " ="
        a.value = value
        a.tokens = self.value_tokens(value)
        a.done = True
        a.error = ""
        self.history.insert(0, {"area": "prog" if self.prog else "sci", "expr": expr,
                                "result": self.format_value(value, group=True),
                                "value": str(value), "base": self.base})
        del self.history[HISTORY_MAX:]

    def clear_all(self):
        a = self.area
        a.tokens = []
        a.done = False
        a.value = None
        a.error = ""
        a.last = ""
        self.second = False

    def backspace(self):
        a = self.area
        if a.error:
            a.error = ""
            return
        if a.done:
            a.done = False       # edit the result as a number
            a.value = None
            a.last = ""
        toks = a.tokens
        if not toks:
            return
        tok = toks[-1]
        if tok[0] == "num":
            text = tok[1][:-1]
            if text in ("", "-"):
                toks.pop()
            else:
                toks[-1] = ("num", text, None)
        else:
            toks.pop()

    # Memory (Standard and Expert)

    def memory_value(self):
        a = self.area
        if a.done and a.value is not None:
            return a.value
        return self.current_value()

    def memory_store(self):
        v = self.memory_value()
        if v is not None:
            self.memory = v

    def memory_add(self, sign):
        v = self.memory_value()
        if v is not None:
            self.memory = (self.memory or Decimal(0)) + sign * v

    def memory_clear(self):
        self.memory = None

    def memory_recall(self):
        if self.memory is not None:
            self.operand(self.value_tokens(self.memory))

    # Switches

    def toggle_second(self):
        self.second = not self.second

    def toggle_angle(self):
        self.degrees = not self.degrees

    def set_mode(self, mode):
        if mode in MODES:
            self.mode = mode
            self.second = False

    def collapse_prog(self, change):
        """Change base/word/sign, keeping the value shown."""
        a = self.areas["prog"]
        v = self.prog_value if a.tokens else None
        change()
        if v is not None:
            v = normalize(v, self.word, self.signed)
            a.tokens = self.value_tokens(v) if self.prog else a.tokens
            if a.done:
                a.value = v
        a.error = ""

    def set_base(self, base):
        if base in BASES and base != self.base:
            self.collapse_prog(lambda: setattr(self, "base", base))

    def set_word(self, word):
        if word in WORDS and word != self.word:
            self.collapse_prog(lambda: setattr(self, "word", word))

    def toggle_signed(self):
        self.collapse_prog(lambda: setattr(self, "signed", not self.signed))

    def flip_bit(self, i):
        if not (0 <= i < self.word) or not self.prog:
            return
        u = bits_of(self.prog_value, self.word) ^ (1 << i)
        v = normalize(u, self.word, self.signed)
        a = self.area
        a.tokens = self.value_tokens(v)
        a.done = False
        a.value = None
        a.error = ""

    def use_history(self, index):
        items = self.history_for_mode()
        if not (0 <= index < len(items)):
            return
        h = items[index]
        if self.prog:
            v = normalize(int(h["value"]), self.word, self.signed)
        else:
            v = Decimal(h["value"])
        self.operand(self.value_tokens(v))

    def clear_history(self):
        area = "prog" if self.prog else "sci"
        self.history = [h for h in self.history if h["area"] != area]

    # --- Saving between runs -----------------------------------------------

    def to_state(self):
        return {"mode": self.mode, "degrees": self.degrees, "base": self.base, "word": self.word,
                "signed": self.signed, "memory": None if self.memory is None else str(self.memory),
                "ans": str(self.ans), "progAns": self.prog_ans, "history": self.history,
                "historyOpen": self.history_open}

    def from_state(self, s):
        try:
            if s.get("mode") in MODES:
                self.mode = s["mode"]
            self.degrees = bool(s.get("degrees", True))
            if s.get("base") in BASES:
                self.base = s["base"]
            if s.get("word") in WORDS:
                self.word = s["word"]
            self.signed = bool(s.get("signed", False))
            if s.get("memory") is not None:
                self.memory = Decimal(s["memory"])
            self.ans = Decimal(s.get("ans", "0"))
            self.prog_ans = int(s.get("progAns", 0))
            self.history = [h for h in s.get("history", []) if isinstance(h, dict) and h.get("area") in ("sci", "prog")
                            and all(k in h for k in ("expr", "result", "value"))][:HISTORY_MAX]
            self.history_open = bool(s.get("historyOpen", False))
        except (ArithmeticError, ValueError, TypeError, AttributeError):
            pass   # a damaged state file: keep what was read so far

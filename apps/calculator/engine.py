"""Orka Calculator: the math.

Expressions are lists of tokens (built by calculator.py from the keys):
    ("num", text, exact)   a number; text as typed (or the shown result),
                           exact = a Decimal/int to use instead of text, or None
    ("op", name)           + − × ÷ mod ^ root  (scientific)
                           + − × ÷ mod and or xor nand shl shr  (programmer)
                           "−" is also the unary minus
    ("(",) (")",)          parentheses
    ("func", name)         a function and its "(": sin cos tan asin acos atan
                           sinh cosh tanh asinh acosh atanh ln log log2
                           sqrt cbrt abs floor ceil round
    ("const", name)        pi e ans
    ("post", "!")          factorial

Scientific mode uses exact decimals (Decimal, 34 digits), so 0.1 + 0.2 = 0.3.
Programmer mode uses Python's unlimited integers, wrapped to the word size
(8/16/32/64 bits, two's complement when signed).
"""

from decimal import Decimal, localcontext, InvalidOperation, DivisionByZero, Overflow, ROUND_HALF_EVEN
import math

PREC = 34
PI = Decimal("3.141592653589793238462643383279503")
E = Decimal("2.718281828459045235360287471352662")
SHOWN_DIGITS = 16          # significant digits on the display


class CalcError(Exception):
    """An expression that can't be calculated; str() is shown to the user."""


# --- Parsing (both modes) -------------------------------------------------

# Binary operators: precedence, right-associative?
SCI_OPS = {"+": (1, False), "−": (1, False), "×": (2, False), "÷": (2, False), "mod": (2, False),
           "ncr": (2, False), "npr": (2, False), "^": (4, True), "root": (4, True)}
PROG_OPS = {"or": (1, False), "xor": (2, False), "and": (3, False), "nand": (3, False),
            "shl": (4, False), "shr": (4, False), "+": (5, False), "−": (5, False),
            "×": (6, False), "÷": (6, False), "mod": (6, False)}
UNARY_PREC = {"sci": 3, "prog": 7}   # unary minus: -2^2 = -4 in scientific mode


def is_operand_end(tok):
    """Does this token end an operand (so a following one means ×)?"""
    return tok[0] in ("num", ")", "const", "post")


def is_operand_start(tok):
    return tok[0] in ("num", "(", "func", "const")


def with_implicit_multiplication(tokens):
    """2π, 3(4+1), (1+1)(2+2), 2sin(30): insert the × that's meant."""
    out = []
    for tok in tokens:
        if out and is_operand_end(out[-1]) and is_operand_start(tok):
            out.append(("op", "×"))
        out.append(tok)
    return out


class Parser:
    """Precedence climbing over a token list; returns a tree of tuples."""

    def __init__(self, tokens, ops, unary_prec):
        self.toks = with_implicit_multiplication(tokens)
        self.ops = ops
        self.unary_prec = unary_prec
        self.i = 0

    def peek(self):
        return self.toks[self.i] if self.i < len(self.toks) else None

    def take(self):
        tok = self.peek()
        self.i += 1
        return tok

    def parse(self):
        if not self.toks:
            raise CalcError("Nothing to calculate")
        tree = self.expr(0)
        if self.peek() is not None:
            raise CalcError("Syntax error")
        return tree

    def expr(self, min_prec):
        left = self.unary()
        while True:
            tok = self.peek()
            if tok is None or tok[0] != "op" or tok[1] not in self.ops:
                return left
            prec, right_assoc = self.ops[tok[1]]
            if prec < min_prec:
                return left
            self.take()
            right = self.expr(prec if right_assoc else prec + 1)
            left = ("bin", tok[1], left, right)

    def unary(self):
        tok = self.peek()
        if tok is not None and tok[0] == "op" and tok[1] in ("−", "+"):
            self.take()
            operand = self.expr(self.unary_prec)
            return ("neg", operand) if tok[1] == "−" else operand
        return self.postfix()

    def postfix(self):
        node = self.primary()
        while self.peek() is not None and self.peek()[0] == "post":
            self.take()
            node = ("fact", node)
        return node

    def primary(self):
        tok = self.take()
        if tok is None:
            raise CalcError("Incomplete")
        kind = tok[0]
        if kind == "num":
            return ("num", tok[1], tok[2] if len(tok) > 2 else None)
        if kind == "const":
            return ("const", tok[1])
        if kind in ("(", "func"):
            inner = self.expr(0)
            if self.take() is None:   # the closing ")" (missing ones are added before)
                raise CalcError("Incomplete")
            return ("call", tok[1], inner) if kind == "func" else inner
        raise CalcError("Syntax error")


def close_parens(tokens):
    """Add the ")" still missing at the end."""
    depth = sum(1 for t in tokens if t[0] in ("(", "func")) - sum(1 for t in tokens if t[0] == ")")
    return list(tokens) + [(")",)] * max(depth, 0)


# --- Scientific evaluation -----------------------------------------------

def to_decimal(text):
    try:
        return Decimal(text.replace("E", "e"))
    except InvalidOperation:
        raise CalcError("Syntax error") from None


def clean_float(x):
    """A float result (trig) as a Decimal, without float noise:
    sin(30°) = 0.5, not 0.49999999999999994; sin(180°) = 0."""
    if math.isnan(x) or math.isinf(x):
        raise CalcError("Not defined")
    if abs(x) < 1e-15:
        return Decimal(0)
    return Decimal(repr(x)).quantize(Decimal(1).scaleb(math.floor(math.log10(abs(x))) - 14)).normalize()


def factorial(x):
    if x != x.to_integral_value() or x < 0:
        raise CalcError("n! needs a whole number ≥ 0")
    if x > 5000:
        raise CalcError("Number too big")
    return Decimal(math.factorial(int(x)))


def power(base, exp):
    if exp == exp.to_integral_value() and abs(exp) <= 100000:
        if base == 0 and exp < 0:
            raise CalcError("Can't divide by zero")
        return base ** int(exp)
    if base > 0:
        return (base.ln() * exp).exp()
    if base == 0:
        if exp > 0:
            return Decimal(0)
        raise CalcError("Can't divide by zero")
    # A negative base: only odd roots (x^(1/3)) have a real result.
    inv = (Decimal(1) / exp)
    rounded = inv.to_integral_value()
    if abs(inv - rounded) < Decimal("1e-20") and int(rounded) % 2 == 1:
        return -power(-base, exp)
    raise CalcError("Not defined")


def nth_root(x, n):
    if n == 0:
        raise CalcError("Not defined")
    if x < 0:
        if n == n.to_integral_value() and int(n) % 2 == 1:
            return -power(-x, Decimal(1) / n)
        raise CalcError("Not defined")
    return power(x, Decimal(1) / n)


def snap(x):
    """Round away the last digits' noise of ln/exp chains: ∛27 = 3, not
    3.000…001 (the shown result is rounded to SHOWN_DIGITS anyway)."""
    if x == 0:
        return x
    nearest = x.to_integral_value()
    if nearest != 0 and abs(x - nearest) / abs(x) < Decimal("1e-28"):
        return nearest
    return x


class SciEvaluator:
    def __init__(self, degrees=True, ans=Decimal(0)):
        self.degrees = degrees
        self.ans = ans

    def run(self, tokens):
        tree = Parser(close_parens(tokens), SCI_OPS, UNARY_PREC["sci"]).parse()
        with localcontext() as ctx:
            ctx.prec = PREC
            ctx.traps[DivisionByZero] = True
            ctx.traps[InvalidOperation] = True
            ctx.traps[Overflow] = True
            try:
                value = self.ev(tree)
            except DivisionByZero:
                raise CalcError("Can't divide by zero") from None
            except (InvalidOperation, ValueError):
                raise CalcError("Not defined") from None
            except (Overflow, OverflowError):
                raise CalcError("Number too big") from None
            value = +value     # round to the context precision
        return snap(value)

    def ev(self, node):
        kind = node[0]
        if kind == "num":
            return node[2] if node[2] is not None else to_decimal(node[1])
        if kind == "const":
            return {"pi": PI, "e": E, "ans": self.ans}[node[1]]
        if kind == "neg":
            return -self.ev(node[1])
        if kind == "fact":
            return factorial(self.ev(node[1]))
        if kind == "call":
            return self.call(node[1], self.ev(node[2]))
        a, b = self.ev(node[2]), self.ev(node[3])
        op = node[1]
        if op == "+":
            return a + b
        if op == "−":
            return a - b
        if op == "×":
            return a * b
        if op == "÷":
            if b == 0:
                raise CalcError("Can't divide by zero")
            return a / b
        if op == "mod":
            if b == 0:
                raise CalcError("Can't divide by zero")
            return a - b * (a / b).to_integral_value(rounding="ROUND_FLOOR")   # sign of the divisor
        if op == "^":
            return power(a, b)
        if op == "root":
            return nth_root(a, b)
        if op in ("ncr", "npr"):
            if a != a.to_integral_value() or b != b.to_integral_value() or a < 0 or b < 0:
                raise CalcError("nCr and nPr need whole numbers ≥ 0")
            if a > 100000:
                raise CalcError("Number too big")
            n, r = int(a), int(b)
            return Decimal(math.comb(n, r) if op == "ncr" else math.perm(n, r))
        raise CalcError("Syntax error")

    def call(self, name, x):
        if name == "sqrt":
            if x < 0:
                raise CalcError("Not defined")
            return x.sqrt()
        if name == "cbrt":
            return nth_root(x, Decimal(3))
        if name == "abs":
            return abs(x)
        if name == "ln":
            if x <= 0:
                raise CalcError("Not defined")
            return x.ln()
        if name == "log":
            if x <= 0:
                raise CalcError("Not defined")
            return x.log10()
        if name == "log2":
            if x <= 0:
                raise CalcError("Not defined")
            return x.ln() / Decimal(2).ln()
        if name == "floor":
            return x.to_integral_value(rounding="ROUND_FLOOR")
        if name == "ceil":
            return x.to_integral_value(rounding="ROUND_CEILING")
        if name == "round":
            return x.to_integral_value(rounding="ROUND_HALF_UP")
        if name in ("sinh", "cosh", "tanh", "asinh", "acosh", "atanh"):
            f = getattr(math, name)
            try:
                return clean_float(f(float(x)))
            except (ValueError, OverflowError):
                raise CalcError("Not defined") from None
        if name in ("sin", "cos", "tan"):
            if self.degrees:
                deg = x % 360
                if deg < 0:
                    deg += 360
                if name == "tan" and deg % 180 == 90:
                    raise CalcError("Not defined")
                # Exact values where people expect them.
                if name == "sin" and deg % 180 == 0 or name == "cos" and deg % 180 == 90 or name == "tan" and deg % 180 == 0:
                    return Decimal(0)
                rad = float(deg) * math.pi / 180
            else:
                rad = float(x)
            return clean_float({"sin": math.sin, "cos": math.cos, "tan": math.tan}[name](rad))
        if name in ("asin", "acos", "atan"):
            f = {"asin": math.asin, "acos": math.acos, "atan": math.atan}[name]
            try:
                r = f(float(x))
            except ValueError:
                raise CalcError("Not defined") from None
            return clean_float(math.degrees(r) if self.degrees else r)
        raise CalcError("Syntax error")


def format_decimal(value, digits=SHOWN_DIGITS, group=False):
    """A result for the display: rounded to `digits` significant digits,
    plain notation for everyday sizes, 1.23e+25 for huge or tiny ones."""
    if value == 0:
        return "0"
    with localcontext() as ctx:
        ctx.prec = PREC
        whole = value == value.to_integral_value() and abs(value) < Decimal(10) ** 20
    if whole:
        # Exact whole numbers up to 20 digits are shown in full (20! too).
        n = int(value)
        text = format(abs(n), "," if group else "d")
        return ("−" + text) if n < 0 else text
    with localcontext() as ctx:
        ctx.prec = digits
        ctx.rounding = ROUND_HALF_EVEN
        v = (+value).normalize()
    exp = v.adjusted()
    if -10 <= exp < digits:
        text = format(v, "f")
        if "." in text:
            text = text.rstrip("0").rstrip(".")
        if group:
            sign = "−" if text.startswith("-") else ""
            whole, _, frac = text.lstrip("-").partition(".")
            text = sign + format(int(whole), ",") + ("." + frac if frac else "")
        elif text.startswith("-"):
            text = "−" + text[1:]
        return text
    mant, _, e = format(v, "e").partition("e")
    if "." in mant:
        mant = mant.rstrip("0").rstrip(".")
    return (mant + "e" + e).replace("-", "−")


# --- Programmer evaluation -----------------------------------------------

BASES = {"hex": 16, "dec": 10, "oct": 8, "bin": 2}


def normalize(v, word, signed):
    """Wrap to the word size (two's complement)."""
    v &= (1 << word) - 1
    if signed and v >> (word - 1):
        v -= 1 << word
    return v


def bits_of(v, word):
    """The bit pattern (unsigned) of a normalized value."""
    return v & ((1 << word) - 1)


class ProgEvaluator:
    def __init__(self, base="hex", word=64, signed=False, ans=0):
        self.radix = BASES[base]
        self.word = word
        self.signed = signed
        self.ans = ans

    def norm(self, v):
        return normalize(v, self.word, self.signed)

    def run(self, tokens):
        tree = Parser(close_parens(tokens), PROG_OPS, UNARY_PREC["prog"]).parse()
        return self.norm(self.ev(tree))

    def ev(self, node):
        kind = node[0]
        if kind == "num":
            if node[2] is not None:
                return self.norm(node[2])
            try:
                return self.norm(int(node[1].replace(" ", ""), self.radix))
            except ValueError:
                raise CalcError("Syntax error") from None
        if kind == "const":
            if node[1] == "ans":
                return self.norm(self.ans)
            raise CalcError("Syntax error")
        if kind == "neg":
            return self.norm(-self.ev(node[1]))
        if kind in ("fact", "call"):
            raise CalcError("Syntax error")
        a, b = self.ev(node[2]), self.ev(node[3])
        op = node[1]
        if op == "+":
            return self.norm(a + b)
        if op == "−":
            return self.norm(a - b)
        if op == "×":
            return self.norm(a * b)
        if op in ("÷", "mod"):
            if b == 0:
                raise CalcError("Can't divide by zero")
            q = abs(a) // abs(b)
            if (a < 0) != (b < 0):
                q = -q          # truncate toward zero, like C
            return self.norm(q if op == "÷" else a - b * q)
        if op == "and":
            return self.norm(a & b)
        if op == "or":
            return self.norm(a | b)
        if op == "xor":
            return self.norm(a ^ b)
        if op == "nand":
            return self.norm(~(a & b))
        if op in ("shl", "shr"):
            n = bits_of(b, self.word)
            if n >= self.word:
                return 0 if op == "shl" or not self.signed or a >= 0 else -1
            if op == "shl":
                return self.norm(a << n)
            # signed: arithmetic shift (keeps the sign); unsigned: logical
            return self.norm(a >> n) if self.signed else self.norm(bits_of(a, self.word) >> n)
        raise CalcError("Syntax error")

    # One-operand actions (NOT, ROL, ROR) work on the whole value.
    def bit_not(self, v):
        return self.norm(~v)

    def rotate(self, v, left):
        u = bits_of(v, self.word)
        w = self.word
        u = ((u << 1) | (u >> (w - 1))) if left else ((u >> 1) | ((u & 1) << (w - 1)))
        return self.norm(u)


def format_int(v, base, word, group=True):
    """A programmer value in a base: HEX/OCT/BIN show the bit pattern
    (two's complement), DEC the value itself (negative when signed)."""
    if base == "dec":
        text = format(abs(v), "," if group else "d")
        return ("−" + text) if v < 0 else text
    u = bits_of(v, word)
    text = {"hex": format(u, "X"), "oct": format(u, "o"), "bin": format(u, "b")}[base]
    if group:
        size = 3 if base == "oct" else 4
        head = len(text) % size
        parts = ([text[:head]] if head else []) + [text[i:i + size] for i in range(head, len(text), size)]
        text = " ".join(parts)
    return text

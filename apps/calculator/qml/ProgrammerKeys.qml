// Programmer keys. Digits the current base doesn't have are greyed out
// (calc.disabledKeys). NOT, ±, ROL and ROR change the whole value shown.
import QtQuick

KeyGrid {
    columns: 6
    keys: [
        { id: "and", label: "AND", kind: "fn" }, { id: "or", label: "OR", kind: "fn" }, { id: "xor", label: "XOR", kind: "fn" },
        { id: "not", label: "NOT", kind: "fn" }, { id: "shl", label: "<<", kind: "fn" }, { id: "shr", label: ">>", kind: "fn" },

        { id: "dA", label: "A" }, { id: "dB", label: "B" }, { id: "mod", label: "mod", kind: "fn" },
        { id: "ac", label: "AC", kind: "clear" }, { id: "back", label: "⌫", kind: "clear" }, { id: "div", label: "÷", kind: "op" },

        { id: "dC", label: "C" }, { id: "dD", label: "D" }, { id: "d7", label: "7" },
        { id: "d8", label: "8" }, { id: "d9", label: "9" }, { id: "mul", label: "×", kind: "op" },

        { id: "dE", label: "E" }, { id: "dF", label: "F" }, { id: "d4", label: "4" },
        { id: "d5", label: "5" }, { id: "d6", label: "6" }, { id: "sub", label: "−", kind: "op" },

        { id: "lparen", label: "(", kind: "fn" }, { id: "rparen", label: ")", kind: "fn" }, { id: "d1", label: "1" },
        { id: "d2", label: "2" }, { id: "d3", label: "3" }, { id: "add", label: "+", kind: "op" },

        { id: "neg", label: "±", kind: "fn" }, { id: "rol", label: "ROL", kind: "fn" }, { id: "ror", label: "ROR", kind: "fn" },
        { id: "d0", label: "0" }, { id: "nand", label: "NAND", kind: "fn" }, { id: "eq", label: "=", kind: "eq" }
    ]
}

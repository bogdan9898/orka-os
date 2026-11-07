// Standard keys (also the right half in Expert mode).
import QtQuick

KeyGrid {
    columns: 4
    keys: [
        { id: "mod", label: "mod", kind: "fn" }, { id: "ans", label: "ans", kind: "fn" },
        { id: "ac", label: "AC", kind: "clear" }, { id: "back", label: "⌫", kind: "clear" },
        { id: "inv", label: "¹/x", kind: "fn" }, { id: "sq", label: "x²", kind: "fn" },
        { id: "sqrt", label: "√x", kind: "fn" }, { id: "div", label: "÷", kind: "op" },
        { id: "d7", label: "7" }, { id: "d8", label: "8" }, { id: "d9", label: "9" }, { id: "mul", label: "×", kind: "op" },
        { id: "d4", label: "4" }, { id: "d5", label: "5" }, { id: "d6", label: "6" }, { id: "sub", label: "−", kind: "op" },
        { id: "d1", label: "1" }, { id: "d2", label: "2" }, { id: "d3", label: "3" }, { id: "add", label: "+", kind: "op" },
        { id: "neg", label: "±", kind: "fn" }, { id: "d0", label: "0" }, { id: "dot", label: "." }, { id: "eq", label: "=", kind: "eq" }
    ]
}

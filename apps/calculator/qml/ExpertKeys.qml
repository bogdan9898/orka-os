// Expert: scientific keys left of the standard ones. 2nd turns sin/cos/tan
// and sinh/cosh/tanh into their inverses (for the next function).
import QtQuick

KeyGrid {
    columns: 5
    readonly property bool s: calc.second
    keys: [
        { id: "second", label: "2nd", kind: "sci" }, { id: "pi", label: "π", kind: "sci" },
        { id: "e", label: "e", kind: "sci" }, { id: "lparen", label: "(", kind: "sci" }, { id: "rparen", label: ")", kind: "sci" },

        { id: "sin", label: s ? "sin⁻¹" : "sin", kind: "sci" }, { id: "cos", label: s ? "cos⁻¹" : "cos", kind: "sci" },
        { id: "tan", label: s ? "tan⁻¹" : "tan", kind: "sci" }, { id: "pow", label: "xʸ", kind: "sci" },
        { id: "root", label: "ʸ√x", kind: "sci" },

        { id: "sinh", label: s ? "sinh⁻¹" : "sinh", kind: "sci" }, { id: "cosh", label: s ? "cosh⁻¹" : "cosh", kind: "sci" },
        { id: "tanh", label: s ? "tanh⁻¹" : "tanh", kind: "sci" }, { id: "exp", label: "eˣ", kind: "sci" },
        { id: "pow10", label: "10ˣ", kind: "sci" },

        { id: "ln", label: "ln", kind: "sci" }, { id: "log", label: "log", kind: "sci" },
        { id: "log2", label: "log₂", kind: "sci" }, { id: "pow2", label: "2ˣ", kind: "sci" },
        { id: "ee", label: "×10ⁿ", kind: "sci" },

        { id: "cube", label: "x³", kind: "sci" }, { id: "cbrt", label: "∛x", kind: "sci" },
        { id: "abs", label: "|x|", kind: "sci" }, { id: "fact", label: "n!", kind: "sci" },
        { id: "rand", label: "rand", kind: "sci" },

        { id: "floor", label: "⌊x⌋", kind: "sci" }, { id: "ceil", label: "⌈x⌉", kind: "sci" },
        { id: "round", label: "round", kind: "sci" }, { id: "ncr", label: "nCr", kind: "sci" },
        { id: "npr", label: "nPr", kind: "sci" }
    ]
}

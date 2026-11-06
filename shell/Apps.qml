pragma Singleton
// Starting programs from the shell, the same way the Hyprland bindings do
// (orka/apps.lua): through uwsm, terminal programs in their own floating
// Ghostty window (class org.orka.<name>).
import QtQuick
import Quickshell

Singleton {
    readonly property string terminal: "ghostty"

    function run(args) {
        Quickshell.execDetached(["uwsm", "app", "--"].concat(args))
    }

    function tui(command) {
        const id = command.split(" ")[0]
        run([terminal, "--class=org.orka." + id, "-e"].concat(command.split(" ")))
    }
}

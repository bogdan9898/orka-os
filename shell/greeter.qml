// OrkaOS login screen, a greetd greeter. greetd runs it as the "greeter"
// user inside the cage kiosk compositor (/etc/greetd/config.toml):
//   cage -s -- qs -p /usr/share/orka/shell/greeter.qml
// It's a separate entry point next to shell.qml, so it shares Theme.qml and
// the shell's components but none of the desktop parts.
import QtQuick
import Quickshell
import qs.greeter

ShellRoot {
    Greeter {}
}

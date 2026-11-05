# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi

~/.automated_script.sh

# OrkaOS: offer the installer on the first console.
if [[ "$(tty)" == /dev/tty1 && ! -e /tmp/orka-install-offered ]]; then
    touch /tmp/orka-install-offered
    orka-install
fi

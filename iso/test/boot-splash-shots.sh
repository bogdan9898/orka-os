#!/usr/bin/env bash
# Screenshots of the installed system booting: the Limine menu, the OrkaOS
# boot screen (Plymouth) and the login screen. Boots the test VM's disk
# headless, saves a screenshot every half second, then shuts the VM down
# cleanly. Run as the build user inside the archlinux WSL distro, after
# install-test.sh.
#
#   iso/test/boot-splash-shots.sh [seconds]   default 40; screenshots in $SHOTS
#                                             (default /tmp/orka-splash): f001.png, f002.png…
set -u
S="${SHOTS:-/tmp/orka-splash}"
SECONDS_TOTAL="${1:-40}"
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
rm -rf "$S"; mkdir -p "$S"
pkill -x qemu-system-x86; sleep 1
bash iso/test/vm.sh --offline > /tmp/orka-vm.log 2>&1 &
mon() { printf '%s\n' "$1" | socat - UNIX-CONNECT:/tmp/orka-qmon.sock >/dev/null 2>&1; }
sleep 1
for i in $(seq -f '%03g' $((SECONDS_TOTAL * 2))); do
  mon "screendump /tmp/vms.ppm"
  magick /tmp/vms.ppm "$S/f$i.png" 2>/dev/null
  sleep 0.45
done
mon "system_powerdown"
for _ in $(seq 60); do pgrep -x qemu-system-x86 >/dev/null || break; sleep 1; done
pkill -x qemu-system-x86
ls "$S" | wc -l

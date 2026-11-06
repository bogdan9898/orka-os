#!/usr/bin/env bash
# Screenshots of the installed system's boot menu (Limine): boots the test
# VM's disk headless, waits until the screen is no longer black, stops the
# countdown with a key and saves a few screenshots, then stops the VM (it
# never boots past the menu, so nothing is written to the disk). Run as the
# build user inside the archlinux WSL distro, after install-test.sh.
#
#   iso/test/boot-menu-shots.sh          screenshots in $SHOTS (default /tmp/orka-boot)
#
#   menu-down.png    after Down (countdown stopped)
#   menu-up.png      back on the default entry
#   menu-down3.png   three entries further (the "OrkaOS" folder line selected)
set -u
S="${SHOTS:-/tmp/orka-boot}"
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
rm -rf "$S"; mkdir -p "$S"
pkill -x qemu-system-x86; sleep 1
bash iso/test/vm.sh --offline > /tmp/orka-vm.log 2>&1 &
mon() { printf '%s\n' "$1" | socat - UNIX-CONNECT:/tmp/orka-qmon.sock >/dev/null 2>&1; }
shot() { mon "screendump /tmp/vmb.ppm"; sleep 0.3; magick /tmp/vmb.ppm "$S/$1.png" 2>/dev/null; }
found=0
for i in $(seq 80); do
  sleep 0.25
  mon "screendump /tmp/vmb.ppm"; sleep 0.2
  m=$(magick /tmp/vmb.ppm -format '%[fx:mean]' info: 2>/dev/null || echo 0)
  if awk -v m="$m" 'BEGIN { exit !(m > 0.03) }'; then   # the wallpaper is up
    echo "menu after $i polls (mean brightness $m)"
    found=1
    mon "sendkey down"; sleep 0.6; shot menu-down
    mon "sendkey up"; sleep 0.6; shot menu-up
    mon "sendkey down"; sleep 0.3; mon "sendkey down"; sleep 0.3; mon "sendkey down"; sleep 0.6; shot menu-down3
    break
  fi
done
((found)) || echo "no boot menu seen (screen stayed black)"
pkill -x qemu-system-x86
ls "$S"

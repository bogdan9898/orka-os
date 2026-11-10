#!/usr/bin/env bash
# Boot an OrkaOS ISO from a Ventoy USB stick in the test VM (UEFI), the way
# it boots from a real Ventoy stick. Run as root inside the archlinux WSL
# distro:
#
#   iso/test/ventoy-test.sh [ISO]     default: newest ISO in ~bogdan/dev/orka-build/out
#
# Downloads Ventoy (Linux release) into ~bogdan/ventoy-test once, creates a
# 6 GiB stick image there, installs Ventoy on it, reformats the data partition
# as ext4 (Ventoy supports ext4; the WSL kernel cannot write exFAT), copies the
# ISO onto it and boots it as a USB stick with an empty system disk. Ventoy's
# menu boots the ISO after 3 s (ventoy/ventoy.json). Screenshots every 5 s go
# to $SHOTS (default /tmp/orka-ventoy); the run stops when the live system
# logs in on the serial console or after $SECS seconds (default 240).
set -u
VERSION=1.1.18
U=bogdan
T=/home/$U/ventoy-test
S="${SHOTS:-/tmp/orka-ventoy}"
SECS="${SECS:-240}"
ISO="${1:-$(ls -t /home/$U/dev/orka-build/out/*.iso | head -1)}"
OVMF=/usr/share/edk2/x64
die() { echo "ventoy-test: $*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die "run as root"
[[ -f "$ISO" ]] || die "no ISO: $ISO"

mkdir -p "$T"; cd "$T" || exit 1
if [[ ! -d ventoy-$VERSION ]]; then
  curl -sSLO "https://github.com/ventoy/Ventoy/releases/download/v$VERSION/ventoy-$VERSION-linux.tar.gz" ||
    die "Ventoy download failed"
  tar xf "ventoy-$VERSION-linux.tar.gz" || die "Ventoy unpack failed"
fi

# Fresh stick: Ventoy (GPT), data partition reformatted as ext4.
rm -f stick.img; truncate -s 6G stick.img
dev=$(losetup -fP --show stick.img) || die "losetup failed"
trap 'umount -q "$T/mnt"; losetup -d "$dev" 2>/dev/null' EXIT
(cd ventoy-$VERSION && printf 'y\ny\n' | bash Ventoy2Disk.sh -I -g "$dev") > ventoy-install.log 2>&1 ||
  { tail ventoy-install.log; die "Ventoy2Disk failed"; }
losetup -d "$dev"; dev=$(losetup -fP --show stick.img); sleep 1   # re-read the partitions
mkfs.ext4 -q -F -L Ventoy "${dev}p1" || die "mkfs failed"
sync; sleep 1
mkdir -p mnt; mount -t ext4 "${dev}p1" mnt || die "mount failed"
mkdir -p mnt/ventoy
printf '{ "control": [ { "VTOY_MENU_TIMEOUT": "3" }, { "VTOY_SECONDARY_BOOT_MENU": "0" } ] }\n' > mnt/ventoy/ventoy.json
echo "copying $(basename "$ISO") ..."
cp "$ISO" mnt/
umount mnt; losetup -d "$dev"; trap - EXIT

# Boot it: USB stick on xHCI, empty NVMe system disk, serial console logged.
rm -rf "$S"; mkdir -p "$S"
qemu-img create -q -f qcow2 sys.qcow2 20G
cp "$OVMF/OVMF_VARS.4m.fd" vars.fd
rm -f /tmp/orka-vt-mon.sock /tmp/orka-vt-serial.log
qemu-system-x86_64 -enable-kvm -machine q35 -cpu host -smp 4 -m 6G \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF/OVMF_CODE.4m.fd" \
  -drive if=pflash,format=raw,file=vars.fd \
  -device qemu-xhci -drive if=none,id=stick,format=raw,file=stick.img -device usb-storage,drive=stick,removable=on,bootindex=0 \
  -drive if=none,id=sys,format=qcow2,file=sys.qcow2 -device nvme,drive=sys,serial=orka \
  -nic none -display none -vga std \
  -serial file:/tmp/orka-vt-serial.log -monitor unix:/tmp/orka-vt-mon.sock,server,nowait &
qpid=$!
mon() { printf '%s\n' "$1" | socat - UNIX-CONNECT:/tmp/orka-vt-mon.sock >/dev/null 2>&1; }
for ((t = 5; t <= SECS; t += 5)); do
  sleep 5
  kill -0 $qpid 2>/dev/null || break
  mon "screendump /tmp/orka-vt.ppm"; sleep 0.3
  magick /tmp/orka-vt.ppm "$S/t$(printf %03d $t).png" 2>/dev/null
  ((t == 15)) && mon "sendkey ret"   # in case Ventoy's "Boot in normal mode" menu still shows
  if grep -q "login:" /tmp/orka-vt-serial.log 2>/dev/null; then echo "RESULT: live system reached a login prompt after ~${t}s"; break; fi
done
grep -q "login:" /tmp/orka-vt-serial.log 2>/dev/null || echo "RESULT: no login prompt within ${SECS}s"
mon "quit"; sleep 1; kill $qpid 2>/dev/null
echo "screenshots: $S  serial log: /tmp/orka-vt-serial.log"

#!/usr/bin/env bash
# End-to-end test: boot the ISO in a VM without internet, run the installer
# unattended, reboot into the installed system and print its self-test report.
#
#   iso/test/install-test.sh [ISO] [--mode wipe|free] [--windows-disk during|later] [--gui]
#
# ISO defaults to the newest one in ~/dev/orka-build/out (iso/build.sh) or
# ~/dev/orka-build-out (iso/build-in-docker.sh).
# --mode free          first creates a fake "Windows" layout on the target
#                      disk, to test installing next to it.
# --windows-disk WHEN  adds a second disk with a fake Windows installation:
#                      "during" = attached while installing (must be listed,
#                      left untouched, and get a boot entry), "later" =
#                      attached only after the install (the boot service must
#                      add the entry).

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="${ORKA_TEST_DIR:-$HOME/dev/orka-test}"
ISO="" MODE=wipe GUI=() WINDISK=""
while (($#)); do
  case "$1" in
    --mode) MODE="$2"; shift ;;
    --gui) GUI=(--gui) ;;
    --windows-disk) WINDISK="$2"; shift ;;
    *) ISO="$1" ;;
  esac
  shift
done
# Newest ISO from iso/build.sh (~/dev/orka-build/out) or iso/build-in-docker.sh (~/dev/orka-build-out).
# (ls fails when one of the two folders has no ISO: not an error here.)
[[ -n "$ISO" ]] || ISO="$( { ls -t "$HOME"/dev/orka-build/out/*.iso "$HOME"/dev/orka-build-out/*.iso 2>/dev/null || true; } | head -1)"
[[ -f "$ISO" ]] || { echo "no ISO found" >&2; exit 1; }

log() { printf '\e[1;36m[test]\e[0m %s\n' "$*"; }
vm_ssh() {
  ssh -i "$T/id_orka" -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR -o ConnectTimeout=3 root@127.0.0.1 "$@"
}
qmon() { printf '%s\n' "$1" | socat -t1 - UNIX-CONNECT:/tmp/orka-qmon.sock >/dev/null 2>&1 || true; }
vm_running() { pgrep -f "qemu-system-x86_64.*orka-qmon" >/dev/null; }
wait_vm_exit() { local _; for _ in $(seq "$1"); do vm_running || return 0; sleep 1; done; return 1; }

vm_running && { echo "a test VM is already running" >&2; exit 1; }

# Fake Windows disk: GPT with an ESP holding EFI/Microsoft/Boot/bootmgfw.efi,
# an MSR and a "Basic data" (NTFS type) partition. Built on the host with
# sgdisk + mtools, no root needed.
WIN_IMG="$T/windows.img"
make_windows_disk() {
  rm -f "$WIN_IMG"; truncate -s 2G "$WIN_IMG"
  sgdisk -n 1:0:+260M -t 1:ef00 -c "1:EFI system partition"          -n 2:0:+16M -t 2:0c01 -c "2:Microsoft reserved partition"          -n 3:0:0 -t 3:0700 -c "3:Basic data partition" "$WIN_IMG" >/dev/null
  local start; start="$(sgdisk -i 1 "$WIN_IMG" | awk '/First sector/ {print $3}')"
  local esp="$WIN_IMG@@$((start * 512))"
  mformat -i "$esp" -T $((260 * 2048)) -F ::
  mmd -i "$esp" ::/EFI ::/EFI/Microsoft ::/EFI/Microsoft/Boot
  echo "fake Windows Boot Manager" | mcopy -i "$esp" - ::/EFI/Microsoft/Boot/bootmgfw.efi
  sha256sum "$WIN_IMG" | cut -d' ' -f1 > "$WIN_IMG.sha256"
}
win_disk_untouched() { [[ "$(sha256sum "$WIN_IMG" | cut -d' ' -f1)" == "$(cat "$WIN_IMG.sha256")" ]]; }

DURING=() AFTER=()
case "$WINDISK" in
  "") ;;
  during) make_windows_disk; DURING=(--extra-disk "$WIN_IMG"); AFTER=(--extra-disk "$WIN_IMG") ;;
  later)  make_windows_disk; AFTER=(--extra-disk "$WIN_IMG") ;;
  *) echo "--windows-disk: during or later" >&2; exit 1 ;;
esac

log "ISO: $ISO"
log "booting the live ISO (offline, mode=$MODE)"
setsid "$HERE/vm.sh" --iso "$ISO" --offline --fresh "${DURING[@]}" "${GUI[@]}" >/tmp/orka-vm.log 2>&1 &

for _ in $(seq 120); do vm_ssh true 2>/dev/null && break; sleep 2; done
vm_ssh true || { log "live ISO did not come up over SSH"; tail /tmp/orka-vm.log; exit 1; }
log "live ISO is up; internet blocked: $(vm_ssh 'curl -s -m 5 -o /dev/null https://archlinux.org && echo NO || echo yes')"

if [[ "$MODE" == free ]]; then
  log "creating a fake Windows layout (100 MiB ESP with bootmgfw.efi + 15 GiB partition)"
  vm_ssh 'set -e
    sgdisk --zap-all /dev/vda >/dev/null
    sgdisk -n 1:0:+100M -t 1:ef00 -c 1:EFI -n 2:0:+16M -t 2:0c01 -c 2:MSR -n 3:0:+15G -t 3:0700 -c 3:Windows /dev/vda >/dev/null
    partprobe /dev/vda; udevadm settle
    mkfs.fat -F 32 /dev/vda1 >/dev/null; udevadm settle; mkdir -p /tmp/w; mount -t vfat /dev/vda1 /tmp/w
    mkdir -p /tmp/w/EFI/Microsoft/Boot; echo fake > /tmp/w/EFI/Microsoft/Boot/bootmgfw.efi; umount /tmp/w'
fi

log "installer disk menu:"
vm_ssh 'orka-install --list-disks' | sed 's/^/    /'

log "running the installer (unattended)"
start=$SECONDS
if ! vm_ssh "ORKA_UNATTENDED=1 ORKA_TEST=1 ORKA_DISK=/dev/vda ORKA_MODE=$MODE \
      ORKA_HOSTNAME=orka-test ORKA_USER=tester ORKA_PASSWORD=tester orka-install"; then
  log "installer FAILED; last lines of its log:"
  vm_ssh 'tail -40 /tmp/orka-install.log' || true
  qmon quit; exit 1
fi
log "installer finished in $((SECONDS - start)) s"
vm_ssh 'lsblk -o NAME,SIZE,FSTYPE,PARTLABEL /dev/vda; efibootmgr' || true

vm_ssh 'systemctl poweroff' || true
wait_vm_exit 60 || qmon quit
wait_vm_exit 10

log "booting the installed system"
if ((${#DURING[@]})); then
  if win_disk_untouched; then log "Windows disk untouched by the installer: yes"
  else log "Windows disk was MODIFIED by the installer"; exit 1; fi
fi
setsid "$HERE/vm.sh" --offline "${AFTER[@]}" "${GUI[@]}" >/tmp/orka-vm.log 2>&1 &
for _ in $(seq 300); do grep -q ORKA-SELFTEST-END /tmp/orka-serial.log 2>/dev/null && break; sleep 1; done
qmon quit
wait_vm_exit 10 || true

if grep -q ORKA-SELFTEST-END /tmp/orka-serial.log; then
  log "self-test report:"
  sed -n '/ORKA-SELFTEST-BEGIN/,/ORKA-SELFTEST-END/p' /tmp/orka-serial.log | tr -d '\r'
  if [[ -n "$WINDISK" ]]; then
    if grep -q "windows entries: [1-9]" /tmp/orka-serial.log; then log "Windows boot entry: present"
    else log "Windows boot entry: MISSING"; exit 1; fi
  fi
else
  log "no self-test report after 5 minutes; last serial output:"
  tail -40 /tmp/orka-serial.log | tr -d '\r'
  exit 1
fi

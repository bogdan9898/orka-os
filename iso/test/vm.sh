#!/usr/bin/env bash
# Start the OrkaOS test VM (QEMU + KVM, UEFI). State lives in ~/orka-test.
#
#   iso/test/vm.sh [options]
#     --iso PATH     boot this ISO (default: boot the installed disk)
#     --offline      no internet for the guest (SSH port forward still works)
#     --gui          show a window with VirGL (default: headless)
#     --fresh        new empty disk + UEFI variables
#     --disk-gib N   size of a fresh disk (default 40)
#     --extra-disk F attach F (raw image) as a second disk (/dev/vdb)
#
# The live ISO gets the test SSH key through a cloud-init seed:
#   ssh -i ~/orka-test/id_orka -p 2222 root@127.0.0.1
# Serial console output: /tmp/orka-serial.log, QEMU monitor: /tmp/orka-qmon.sock,
# QMP (e.g. input-send-event for mouse clicks in tests): /tmp/orka-qmp.sock

set -euo pipefail

T="$HOME/orka-test"
OVMF=/usr/share/edk2/x64
ISO="" OFFLINE=0 GUI=0 FRESH=0 DISK_GIB=40 EXTRA=""

while (($#)); do
  case "$1" in
    --iso) ISO="$2"; shift ;;
    --offline) OFFLINE=1 ;;
    --gui) GUI=1 ;;
    --fresh) FRESH=1 ;;
    --disk-gib) DISK_GIB="$2"; shift ;;
    --extra-disk) EXTRA="$(realpath "$2")"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

mkdir -p "$T"
cd "$T"

if ((FRESH)) || [[ ! -f disk.qcow2 ]]; then
  rm -f disk.qcow2 vars.fd
  qemu-img create -q -f qcow2 disk.qcow2 "${DISK_GIB}G"
fi
[[ -f vars.fd ]] || cp "$OVMF/OVMF_VARS.4m.fd" vars.fd

# cloud-init seed with the test SSH key (used by the live ISO only).
if [[ ! -f seed.iso ]]; then
  [[ -f id_orka ]] || ssh-keygen -q -t ed25519 -N "" -f id_orka -C orka-test
  printf '#cloud-config\nusers:\n  - name: root\n    ssh_authorized_keys:\n      - %s\n' "$(cat id_orka.pub)" > user-data
  printf 'instance-id: orka-test\n' > meta-data
  mkisofs -quiet -output seed.iso -volid cidata -joliet -rock user-data meta-data
fi

net="user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22"
((OFFLINE)) && net="$net,restrict=on"

# shellcheck disable=SC2054  # commas belong to QEMU options
args=(
  -enable-kvm -machine q35 -cpu host -smp 8 -m 8G
  -drive if=pflash,format=raw,readonly=on,file="$OVMF/OVMF_CODE.4m.fd"
  -drive if=pflash,format=raw,file=vars.fd
  -drive file=disk.qcow2,if=virtio,format=qcow2
)
[[ -n "$EXTRA" ]] && args+=(-drive "file=$EXTRA,if=virtio,format=raw")
# shellcheck disable=SC2054
args+=(
  -drive file=seed.iso,if=virtio,format=raw,readonly=on
  -nic "$net"
  -monitor unix:/tmp/orka-qmon.sock,server,nowait
  -qmp unix:/tmp/orka-qmp.sock,server,nowait
  -serial file:/tmp/orka-serial.log
)
if ((GUI)); then
  # WSL: Mesa may pick llvmpipe by default; force the d3d12 driver (real GPU).
  export GALLIUM_DRIVER=d3d12
  # shellcheck disable=SC2054
  args+=(-device virtio-vga-gl -display gtk,gl=on
         -audiodev pa,id=snd0,server=unix:/mnt/wslg/PulseServer -device ich9-intel-hda -device hda-output,audiodev=snd0)
else
  # A silent sound card, so the guest has an audio output and a microphone
  # (volume, mute and the OSD can be tested headless).
  # shellcheck disable=SC2054
  args+=(-device virtio-vga -display none
         -audiodev none,id=snd0 -device ich9-intel-hda -device hda-duplex,audiodev=snd0)
fi
[[ -n "$ISO" ]] && args+=(-cdrom "$ISO" -boot once=d)

: > /tmp/orka-serial.log
exec qemu-system-x86_64 "${args[@]}"

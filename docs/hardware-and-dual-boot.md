# Hardware & dual boot

## Target machine

Collected from Windows on 2026-11-05.

| Component | Model | Linux support |
|---|---|---|
| Board | MSI MAG B650 Tomahawk WiFi (MS-7D75), BIOS 1.70, UEFI | Standard desktop |
| CPU | AMD Ryzen 7 7700X (8 cores / 16 threads) | Stock kernel |
| GPU | AMD Radeon RX 6800 XT (+ Ryzen iGPU) | Open-source `amdgpu` + Mesa; no NVIDIA |
| RAM | 32 GB | |
| Wi-Fi / BT | MediaTek RZ616 (MT7922), Wi-Fi 6E | Stock kernel (`mt7921e`) |
| Ethernet | Realtek 2.5GbE | Stock kernel (`r8169`) |
| Monitor | LG UltraGear | FreeSync works over **DisplayPort** with the stock kernel. Use DP rather than HDMI for VRR. |

| Disk | Type | Current use | Free |
|---|---|---|---|
| Samsung 970 EVO Plus 1 TB | NVMe | `C:` Windows (+ 100 MB EFI partition, recovery) | 217 GB |
| Samsung 870 QVO 1 TB | SATA SSD | `D:` "Slow SSD", data | 193 GB |

**Kernel:** Arch stock `linux` is enough. Use `linux-zen` if we want desktop-responsiveness tuning similar to Omarchy's kernel.

## Dual-boot plan

- OrkaOS gets a **separate, dedicated disk** (decided 2026-11-05). The installer's `wipe` mode uses the whole disk: 2 GB ESP + Btrfs.
- During the install, **both Windows disks are disconnected**, to be safe. The installer still handles other disks: the disk menu shows what's on each disk (e.g. `[Windows, 4 partitions]`), only the chosen disk is touched, and erasing a disk that is not empty shows a clear warning listing everything that will be deleted.
- **Windows boot entry:** `orka-windows-entry.service` runs at every boot and adds a Limine entry for any Windows Boot Manager it finds on another disk's EFI partition. After reconnecting the Windows disks, the entry appears automatically (it's written during that boot, so it shows in the menu from the next boot on).
- **Boot order:** the firmware decides which disk's boot loader starts. After reconnecting the Windows disks, check in the BIOS that **"Limine"** (on the OrkaOS disk) is first; Windows is then started from the Limine menu.
- Bootloader: Limine, managed by `limine-mkinitcpio-hook` (see [ISO and installer](iso.md)).
- Encryption: not used (decided: Btrfs + snapshots, no LUKS).

## Checklist before installing

- [ ] Back up anything important
- [ ] **Secure Boot off** in the BIOS
- [ ] **Windows Fast Startup off** (*Control Panel → Power Options → Choose what the power buttons do*). With the Windows disks disconnected this doesn't affect the install, but it matters when Linux later reads the Windows disks.
- [ ] Clock fix: Windows uses local time, Linux uses UTC. Set Windows to UTC with `reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f` (run as admin)
- [ ] Disconnect both Windows disks, install, reconnect, set the BIOS boot order (Limine first)
- [x] Test the full setup in a VM first (offline install, next to Windows, Windows disk attached during and after the install)

## Test environment

- **Build / work VM:** Lubuntu VM in VirtualBox (`lubuntu`, LAN IP, bridged), reachable over SSH from WSL. Shared folder: `VirtualBox shared folder` ↔ `~/shared`.
- **Test VM for OrkaOS:** QEMU/KVM with VirGL in the `archlinux` WSL distro (`iso/test/`). VirtualBox can boot the ISO (with EFI on) and install, but its graphics can't run the login screen: see [Known small issues](approach.md#known-small-issues).

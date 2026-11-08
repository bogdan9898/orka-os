# ISO and installer

The OrkaOS ISO is an archiso live system with the full package set baked in as a local repo, so installing needs **no network**.

## Layout

| Path | What |
|---|---|
| `iso/build.sh` | Builds the ISO (stages: `aur`, `repo`, `iso`, `clean`) |
| `iso/live-packages.txt` | Extra packages for the live environment only (`gum`) |
| `iso/profile/` | Overlay on archiso's `releng` profile |
| `installer/orka-install` | The installer (runs in the live ISO) |
| `installer/target/` | Files copied onto the installed system (network, zram, mirrors, first-boot setup) |
| `iso/test/vm.sh` | Starts the QEMU test VM |
| `iso/test/install-test.sh` | End-to-end test: offline install + boot report |

## Build

In the `archlinux` WSL distro (needs `archiso`, `base-devel`, `git`):

```sh
cd /mnt/c/<path to>/orka-os
sudo ./iso/build.sh            # all stages
sudo ./iso/build.sh iso        # only re-assemble the ISO (installer changes)
```

| Stage | Does |
|---|---|
| `aur` | Clones the AUR packages from `packages-aur.txt`, installs their build dependencies, builds them with `makepkg` (as the normal user) |
| `repo` | Downloads every package from `packages.txt` plus all dependencies (resolved against an empty pacman db, as on a fresh install) and creates the `orka` repo with the AUR packages. Package signatures are kept |
| `nvim` | Runs Neovim headless with the LazyVim config (`config/user/nvim`): installs the plugins at the commits in `lazy-lock.json`, the treesitter parsers and the Mason tools (`iso/nvim-bundle.lua`), and packs them as `nvim-data.tar.zst`. Fails if the lockfile would change. See [Neovim](neovim.md) |
| `iso` | Copies archiso's `releng` profile, applies `iso/profile/`, renames it to OrkaOS (UEFI only), adds the repo and the installer, runs `mkarchiso` |

Output: `~/orka-build/out/orkaos-YYYY.MM.DD-x86_64.iso` (about 3.2 GB). Build files live in `~/orka-build` (see [TEMP-FILES.md](../TEMP-FILES.md)).

The package snapshot is whatever the Arch mirrors serve at build time. Rebuild the `repo` stage to refresh it; after installing, `pacman -Syu` updates from the normal mirrors.

## Installer

Boots straight into `orka-install` on the first console. It asks for the disk, the mode, hostname, username and password, then:

1. **Partitions**: a 2 GiB ESP (FAT32) + Btrfs root, either in the largest free space (`free`, keeps Windows) or on the whole disk (`wipe`).
2. **Btrfs subvolumes** `@`, `@home`, `@log`, `@pkg`, `zstd` compression.
3. **Boot config before packages**: `/etc/default/limine`, a base `/boot/limine.conf`, the initramfs hooks. `limine-mkinitcpio-hook` then installs kernels into the ESP and writes the boot entries itself.
4. **Packages** with `pacstrap` from the local repo.
5. **System setup**: locale, timezone, user (groups `wheel`, `docker`), services, Snapper config for `/`, KWallet PAM unlock, then `snap-pac` (pre/post snapshots for every pacman transaction).
6. **Desktop**: Hyprland defaults to `/usr/share/orka/hypr`, `orka-*` commands to `/usr/local/bin`, the user's dotfiles via `orka-setup-user` (see [desktop](desktop.md)).
7. **Limine**: UEFI entry, fallback loader, and a Windows entry for every other disk with Windows Boot Manager. `orka-windows-entry.service` repeats the scan at every boot, so Windows disks that were disconnected during the install get their entry later.

**Several disks:** the disk menu shows each disk's size, model and contents (`[empty]`, `[Windows, 4 partitions]`, ...). Only the chosen disk is touched. Erasing a disk that is not empty shows a red warning with every partition that will be deleted, and still needs the disk name typed to confirm; unattended mode refuses unless `ORKA_ERASE_NONEMPTY=1`.

Unattended mode (used by the test): `ORKA_UNATTENDED=1 ORKA_DISK=/dev/vda ORKA_MODE=wipe ORKA_HOSTNAME=… ORKA_USER=… ORKA_PASSWORD=… orka-install`. See the header of `installer/orka-install`.

### USB sticks and Ventoy

The live system finds its medium by the ISO's UUID (`archisosearchuuid=`). That works for a stick written with `dd`/Rufus (DD mode), a DVD or a VM. On a Ventoy stick the ISO is only a file on Ventoy's data partition; Ventoy's initramfs helper normally maps it to a device-mapper device, and then the UUID lookup finds it. On the first real-hardware boot (2026-11-07) that mapping never appeared, and archiso dropped to the `[rootfs ~]#` emergency shell with `ERROR: Device '<uuid>' not found` (archiso's file search only scans plain partitions).

The build adds the hook `orka_isofile` (`iso/profile/airootfs/etc/initcpio/`) to the live initramfs, right after `archiso_loop_mnt`. It tries the UUID first as before; if the volume is not there, it looks for an `.iso` file with the matching volume UUID in the top two directory levels of every partition (removable first) and boots it through archiso's loop-device handler. It also writes the boot device to `/run/orka-boot-device`, which the installer uses to hide the USB stick from the disk menu (before, the Ventoy stick was listed first and pre-selected).

### Offline details

- **Keyring failures:** if `pacman-init` fails (or is not done after 120 s), the installer re-runs it once on a fresh keyring tmpfs, then shows a screen with the current clock and the choices *Set the correct time and retry* (live system only, the hardware clock is not touched), *Retry*, *Show the error* (journal) and *Quit*. Seen once on the real PC (online, Windows kept the hardware clock in local time); not reproducible in the VM with a wrong clock, online or offline. Tested by masking the service (`systemd.mask=pacman-init.service`).
- archiso's keyring service waits for an NTP time sync, which never happens offline; the build removes `systemd-time-wait-sync` from the live system.
- The live system's keyring checks the official packages' signatures; the AUR packages are our own unsigned builds (`SigLevel = Optional TrustAll` for the `orka` repo only).
- The installed system gets a fixed mirrorlist (`geo` + `fastly` mirrors) for later updates.

## Test

```sh
iso/test/install-test.sh                 # newest ISO, whole-disk install
iso/test/install-test.sh --mode free     # next to a fake Windows install on the same disk
iso/test/install-test.sh --windows-disk during   # 2nd disk with fake Windows attached while installing
iso/test/install-test.sh --windows-disk later    # ...attached only afterwards (boot service adds the entry)
iso/test/install-test.sh --gui           # watch it in a window
```

`iso/test/ventoy-test.sh [ISO]` (as root) boots the ISO from a Ventoy stick: it downloads Ventoy into `~bogdan/ventoy-test`, makes a 6 GiB stick image with an ext4 data partition (the WSL kernel cannot write exFAT), and boots it on USB next to an empty NVMe disk, with a screenshot every 5 s in `/tmp/orka-ventoy`. The last screenshot should show the installer's disk menu without the stick. The fallback path, with no Ventoy helper, was tested on 2026-11-07 like this: an exFAT partition (Ventoy's `tool/x86_64/mkexfatfs`) holding `isos/<iso>`, and the ISO's kernel and initramfs booted directly under OVMF with `archisobasedir=orka archisosearchuuid=<uuid>`.

The VM runs with `restrict=on` networking: no internet, but SSH to the live ISO works (port 2222, key from a cloud-init seed). With `ORKA_TEST=1` the installer adds a serial console and `orka-selftest.service`, which prints a boot report the test script reads from the serial log.

`iso/test/vm.sh --gui` boots the installed disk in a window for manual testing (with sound through WSLg). Headless runs get a silent virtual sound card (QEMU `-audiodev none`), so the guest still has an audio output and a microphone for volume and OSD tests.

### Desktop tests (screenshots, keys, clicks)

`iso/test/vm-session.sh` boots the installed disk headless and runs a list of steps, saving a screenshot after each one (`$SHOTS/shot1.png`, ..., default `/tmp/orka-shots`): type a command (`"@4 ls"`), press keys (`"!meta_l-k"`), type without Enter (`"%roman"`), click at a pixel (`"^445,360"`, through QEMU's QMP socket `/tmp/orka-qmp.sock`), or send a raw monitor command (`"#info status"`). The header of the script lists the details (`NOLOGIN=1` to log in on the graphical login screen yourself, `VMOPTS=` for network, `KEYWAIT=0.6` to catch the OSD). Example, as `bogdan` inside the `archlinux` WSL distro:

```sh
NOLOGIN=1 iso/test/vm-session.sh "@20 tester" "!meta_l-ret" "!meta_l-k" "%tmux" "!esc"
```

To move files into or out of the guest, boot it with network (`VMOPTS=`) and run `iso/test/vm-http.py <port> <serve dir> <upload dir>` on the host side: the guest fetches with `curl 10.0.2.2:<port>/file` and uploads with `curl --data-binary @- 10.0.2.2:<port>/name`. This is how changed shell files were tried without rebuilding the ISO (copy into `/usr/share/orka/...` with sudo, then `sync`, `hyprctl reload`, `systemctl --user restart orka-shell`).

Gotchas: run everything in one `wsl ... bash -c` call (the VM stops when it returns); the session shuts the guest down with `system_powerdown` (killing QEMU can leave just-written files empty on the guest's Btrfs); stop helper servers by PID, never with `pkill -f` (it matches its own shell); the test user is `tester` / `tester`.

## Boot menu look

The installed system's boot menu (Limine) uses the Orka "Deep water" theme. The global options at the top of `/boot/limine.conf` (written by `prepare_boot` in `installer/orka-install`; limine-entry-tool only manages the entries below them) set:

- `wallpaper: boot():/orka/wallpaper.jpg`: the ESP copy of `branding/limine/wallpaper.jpg`, the ocean from below with light rays. Regenerate it with `branding/limine/make-wallpaper.sh [WIDTHxHEIGHT]` (ImageMagick 7; default 2560x1440, Limine stretches it to the screen).
- `interface_branding_colour` (the "OrkaOS" title) = the accent `3fa7d6`; help text `7f8b97`, countdown `7fd1c7`.
- `term_*`: text colors and the 16-color palette of the Orka Ghostty theme; `term_background: ff0d1620` makes the text background invisible (`TT` = transparency), so the whole wallpaper shows behind the menu (a translucent panel was tried: it hid the light rays and looked boxy).

Screenshots of it from the test VM (after `install-test.sh`): `iso/test/boot-menu-shots.sh` (it stops the countdown with a key; images in `/tmp/orka-boot`).

To change it on an installed system, edit the top of `/boot/limine.conf` as root; it applies at the next boot. The live ISO's own boot menu (systemd-boot, from archiso) stays plain on purpose: systemd-boot can't be themed, archiso can't build a Limine ISO, and switching the ISO to GRUB just for its looks wasn't worth it (decided 2026-11-07). Its entries are already named "OrkaOS installer".

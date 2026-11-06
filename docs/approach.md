# Approach

## Options considered

1. **Overlay:** install stock Omarchy, then add a package that rebrands and debloats it. Little work, but it's still Omarchy underneath.
2. **Light fork:** fork `omarchy` (and later `omarchy-iso`), rename and debloat with scripts, keep their package repo for dependencies. Needs a big rename, and it's hard to keep up with upstream.
3. **Full distro fork:** also fork `omarchy-pkgs` and host our own repo, ISO and mirror. Far too much for personal use.
4. **Own install script on base Arch (recommended):** our own repo with a package list, dotfiles and branding, borrowing freely from Omarchy (MIT).

## Fork v4 vs. own script

| | Fork and debloat v4 | Own script on base Arch |
|---|---|---|
| Work to get started | High: rename ~56k occurrences, strip hardware support, untangle the shell | Medium: write the script and configs, borrowing from Omarchy |
| Maintenance | Rebasing against a fast-moving upstream, or freezing | Just `pacman -Syu`; change things only when we want |
| Understanding the system | Thousands of inherited files | We know every line |
| Branding and naming | A big rename job | Ours from day one |
| Updates | Their update and migration machinery | Plain Arch updates; the script only runs on install or re-runs |
| v4 Quickshell desktop | ✅ Kept | ❌ Not inherited: we write our own in Quickshell |

**Why the script wins here:** most of Omarchy's complexity (582 commands, `$OMARCHY_PATH`, the package repo, migrations, the custom shell) arrived with v4 and exists to support many users and many machines. A personal, single-machine setup needs none of it. Omarchy **v3.8.4** (July 2026), the last release built from standard tools, is the ideal reference to borrow from.

## Repo layout

```text
orka-os/
├── packages.txt        # official repo packages for this hardware
├── packages-aur.txt    # AUR packages (prebuilt into the ISO)
├── installer/          # orka-install (runs in the live ISO) + target/ (files for the installed system)
├── config/hypr/        # Hyprland defaults → /usr/share/orka/hypr
├── config/user/        # user dotfiles → ~/.config (seeded once by orka-setup-user)
├── bin/                # orka-* helper commands → /usr/local/bin
├── iso/                # build.sh, archiso profile overlay, test/ (QEMU VM + install test)
├── themes/             # (later) color schemes and wallpapers
├── branding/           # (later) logo, Plymouth theme, fastfetch art
├── shell/              # Quickshell desktop (the bar so far)
└── docs/
```

## Install flow

1. Boot the **OrkaOS ISO** (USB stick). No network needed: every package is in the ISO's local repo. Details: [ISO and installer](iso.md).
2. `orka-install` starts automatically on the first console and asks for the disk, the mode (whole disk / free space), hostname, username and password, then partitions (2 GiB ESP + Btrfs with Snapper), installs all packages from the local repo, sets up Limine (`linux-zen`, `linux`, Windows), services, the firewall and the Hyprland dotfiles, and points pacman at the normal Arch mirrors for later updates.
3. Reboot, log in on **tty1**: Hyprland starts. See [desktop](desktop.md).

## Roadmap

Status on 2026-11-05 (end of day 1).

1. **Foundation**
   - [x] Package list (official + AUR), debloated from Omarchy v3.8.4 ([packages](packages.md))
   - [x] Offline ISO build (`iso/build.sh`) and installer (`orka-install`), UEFI only
   - [x] Multiple disks: contents shown in the disk menu, red warning before erasing any non-empty disk, Windows boot entry added at every boot (`orka-windows-entry`)
   - [x] Hyprland 0.57 config in Lua, key bindings ported from Omarchy, `orka-*` helpers, Hyprland starts on tty1
   - [x] Shell and terminal setup: starship prompt, aliases (`eza`, `zoxide`, `fzf`), Ghostty and tmux configs ([shell](shell.md))
   - [x] Neovim config: LazyVim, plugins bundled into the ISO ([neovim](neovim.md))
   - [ ] Basic theme (colors are a placeholder, see `config/hypr/orka/theme.lua`); Qt/GTK theming (Kvantum, Adwaita-dark, icon theme)
2. **Test in a VM**
   - [x] QEMU/KVM in the `archlinux` WSL distro; automated offline install test incl. Windows next to it / on a 2nd disk (`iso/test/install-test.sh`)
   - [x] Hyprland starts and basic bindings work in the VM
   - [ ] Click through the interactive installer once (only the first screen and the warning box were checked visually)
3. **Branding:** Orka logo, Plymouth theme, boot menu, fastfetch, wallpapers.
   - [ ] **TODO: create the logo with an actual orca** (not just a fin). Needs variants for the boot splash, boot menu, fastfetch (ASCII/image), icon and wallpaper.
   - [ ] **TODO: rebrand fastfetch:** replace the Arch logo and text with the Orka logo and name.
   - [ ] **TODO: replace every occurrence of the OS name** so the system shows **OrkaOS** instead of "Arch Linux": `/etc/os-release` (`NAME`, `PRETTY_NAME`, `ID=orka` with `ID_LIKE=arch` so Arch tools still recognize it, `LOGO`), Limine boot entries, ISO label and boot menu, Plymouth, the TTY login banner (`/etc/issue`), fastfetch.
   - [ ] **TODO: choose Orka's fonts** (UI, monospace for terminal/editor, icon font). For now the current set is fine: `noto-fonts`, `noto-fonts-emoji`, `ttf-jetbrains-mono-nerd`, `woff2-font-awesome`.
   - [ ] Icon theme (Yaru was dropped: its AUR build needs gnome-shell)
4. **Install on the host** (separate disk, Windows disks disconnected; checklist in [dual boot](hardware-and-dual-boot.md)). Then check what the VM can't: FreeSync/`highrr`, screenshots/recording, media keys, Wi-Fi/Bluetooth, KDE Connect.
5. **Quickshell desktop**, one component at a time: bar (done: [quickshell](quickshell.md#the-bar)) → notifications → polkit agent → launcher → OSD → lock screen → login greeter.

### Known small issues

- `pacman` warns "database file for 'core' does not exist" until the first time the installed system is online (`orka-firstboot` runs `pacman -Sy` when there is network).
- The luarocks pacman hook prints `/usr/bin/lua5.1: No such file or directory` during install (harmless; add `lua51` if Neovim plugins need LuaRocks builds).
- The current ISO in `~/orka-build/out` predates the last three commits (key list fix, erase warning); rebuild with `sudo ./iso/build.sh iso`.

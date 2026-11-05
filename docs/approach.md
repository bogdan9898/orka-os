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

## Proposed repo layout

```text
orka-os/
├── install.sh          # entry point; idempotent, safe to re-run
├── packages.txt        # curated package list for this hardware
├── packages-aur.txt    # AUR packages (via yay/paru)
├── config/             # dotfiles → ~/.config (hypr, ghostty, nvim…)
├── themes/             # color schemes and wallpapers
├── branding/           # logo, plymouth theme, login screen, fastfetch art
├── shell/              # Quickshell desktop (bar, notifications, launcher, OSD, lock, greeter)
├── bin/                # orka-* helper commands
├── iso/                # archiso profile + offline repo build
└── docs/
```

## Install flow

1. Boot the **OrkaOS ISO** (USB stick). No network needed: every package is in the ISO's local repo.
2. The installer (`install.sh`, started automatically) asks for username, password and hostname, then:
   1. partitions the free space next to Windows (see [dual boot](hardware-and-dual-boot.md)): a new ESP plus a Btrfs root with Snapper
   2. installs packages from `packages.txt` and `packages-aur.txt` out of the local repo
   3. installs Limine with entries for `linux-zen`, `linux` and Windows
   4. links or copies dotfiles from `config/` and the Quickshell desktop from `shell/`
   5. enables services: iwd, Bluetooth, PipeWire, Docker, Snapper
   6. applies branding: Plymouth boot splash, fastfetch logo, wallpapers
   7. switches pacman to the normal Arch mirrors for later updates
3. Reboot into OrkaOS, log in on the TTY and run `uwsm start hyprland` (until the Quickshell greeter exists).

## Roadmap

1. **Foundation:** repo skeleton, package list, offline ISO (archiso) and installer, Hyprland started from the TTY, basic theme.
2. **Test in a VM:** QEMU/KVM with VirGL in the `archlinux` WSL distro, including a fully offline install.
3. **Branding:** Orka logo, Plymouth theme, boot menu, fastfetch, wallpapers.
   - [ ] **TODO: create the logo with an actual orca** (not just a fin). Needs variants for the boot splash, boot menu, fastfetch (ASCII/image), icon and wallpaper.
   - [ ] **TODO: rebrand fastfetch:** replace the Arch logo and text with the Orka logo and name.
   - [ ] **TODO: replace every occurrence of the OS name** so the system shows **OrkaOS** instead of "Arch Linux": `/etc/os-release` (`NAME`, `PRETTY_NAME`, `ID=orka` with `ID_LIKE=arch` so Arch tools still recognize it, `LOGO`), Limine boot entries, ISO label and boot menu, Plymouth, the TTY login banner (`/etc/issue`), fastfetch.
   - [ ] **TODO: choose Orka's fonts** (UI, monospace for terminal/editor, icon font). For now the current set is fine: `noto-fonts`, `noto-fonts-emoji`, `ttf-jetbrains-mono-nerd`, `woff2-font-awesome`.
4. **Install on the host** (dual boot).
5. **Quickshell desktop**, one component at a time: bar → notifications → polkit agent → launcher → OSD → lock screen → login greeter.

# OrkaOS

A personal, Arch-based Linux setup with its own name and branding, inspired by [Omarchy](https://github.com/omacom/omarchy). Built for one machine only (see [hardware](docs/hardware-and-dual-boot.md)), dual-booted alongside Windows 11. Not intended for public release.

> Status (2026-11-06, end of day 2): **offline installer ISO works** (tested in QEMU, incl. Windows on another disk); **Hyprland desktop config**; **shell, terminal, git and Neovim (LazyVim, offline)**; our own **Quickshell desktop** is complete: bar, notifications, polkit agent, launcher, lock and login screens, cheat sheet, OSD, settings app with themes and wallpapers. Next: the real Orka theme, branding, then install on the real machine. See the [roadmap](docs/approach.md#roadmap).

## Naming

| Use | Value |
|---|---|
| Display name (boot splash, login screen, about, ISO) | **OrkaOS** |
| Command prefix | `orka` (e.g. `orka-update`, `orka-theme`) |
| Config / state dirs | `~/.config/orka`, `~/.local/state/orka` |
| Package / repo name | `orka` |
| Logo idea | Orca silhouette or dorsal fin, black and white |

Why "Orka" rather than "Orca": `orca` is already an Arch package (the GNOME screen reader, which installs `/usr/bin/orca`) and is crowded in the AUR (OrcaSlicer and ~25 others). `orka` is free in both the Arch repos and the AUR (checked 2026-11-05).

## Goals

- Keep the spirit and structure of Omarchy (Hyprland, opinionated defaults, themes, keybindings, menus), but **debloat** it and give it **custom names and branding**.
- Tailored to a single machine: drop everything for hardware it doesn't have.
- Dual boot with the existing Windows 11 install.
- A **custom OrkaOS ISO** that installs fully offline (done, see [ISO and installer](docs/iso.md)).
- Eventually: a custom desktop shell (bar, widgets, launcher, notifications, lock screen) written in **Quickshell**.

## Decisions so far

| Topic | Decision | Notes |
|---|---|---|
| Audience | Personal, single machine | No package repo, mirrors, signing or release channels needed |
| Base | Arch Linux | |
| Approach | **Own install script on base Arch** | Rather than forking and debloating Omarchy v4. See [approach](docs/approach.md) |
| Reference source | Omarchy **v3.8.4** (MIT) | The last release built from standard tools (Waybar, Walker, Mako, SwayOSD) |
| ISO | **Custom OrkaOS ISO, built now** (archiso) | Installs **fully offline**: all packages, including AUR ones, baked in as a local repo |
| Build / test machine | `archlinux` WSL distro | QEMU + KVM + VirGL test VM. See [hardware & dual boot](docs/hardware-and-dual-boot.md#test-environment) |
| Disk layout | **Dedicated disk: 2 GB ESP + Btrfs with Snapper snapshots, no encryption** | Windows disks are disconnected during the install; their boot entry is added automatically afterwards |
| Bootloader | **Limine** | Windows entry, snapshot boot entries |
| Kernel | **`linux-zen`**, with stock `linux` as fallback | Omarchy's custom kernel isn't needed on this hardware |
| Locale | `en_US.UTF-8`, US keyboard, `Europe/Bucharest` | Taken from the Windows settings |
| Desktop shell | **Our own Quickshell shell, no stock tools** | No Waybar, Mako, SwayOSD, Hyprlock, Walker or SDDM. The login screen runs in greetd + cage. See [quickshell](docs/quickshell.md) |
| Login screen | **Our Quickshell greeter via greetd** (in the cage compositor) | Password login, then Hyprland via uwsm |

## Open questions

- Theme and look: colors, wallpapers, logo design, fonts (current set is a placeholder; see [roadmap](docs/approach.md#roadmap)).

## Docs

- [Omarchy analysis](docs/omarchy-analysis.md): what Omarchy is, license, structure, why it patches its kernel and packages
- [Approach](docs/approach.md): fork vs. own script, proposed repo layout, roadmap
- [Packages](docs/packages.md): what's in the package lists and what was dropped from Omarchy
- [ISO and installer](docs/iso.md): building the offline ISO, what the installer does, testing in QEMU
- [Desktop](docs/desktop.md): Hyprland (Lua) config layout and key bindings
- [Shell and terminal](docs/shell.md): bash, starship, Ghostty, tmux and git configs, aliases and key bindings
- [Neovim](docs/neovim.md): LazyVim, bundled offline into the ISO
- [Settings](docs/settings.md): the OrkaOS settings app, `orka-settings`, themes and wallpapers
- [Quickshell](docs/quickshell.md): building our own bar, widgets, lock screen and more
- [Hardware & dual boot](docs/hardware-and-dual-boot.md): target machine specs and the dual-boot checklist

## License note

Anything copied or adapted from Omarchy is MIT-licensed. Keep its copyright notice (`Copyright (c) David Heinemeier Hansson`) in our `LICENSE` alongside our own. The "Omarchy" name and logo are not ours to use, so all of them must be replaced.

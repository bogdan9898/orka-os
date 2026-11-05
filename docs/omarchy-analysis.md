# Omarchy analysis

Analysis of [omacom/omarchy](https://github.com/omacom/omarchy), done 2026-11-05 against the `quattro` branch (version `4.0.0.alpha`, latest release `v4.5.0-rc3`).

## License

- **MIT**, `Copyright (c) David Heinemeier Hansson`. Forking, renaming, modifying and redistributing are all allowed, as long as the copyright notice is kept.
- The MIT license covers the code, **not the name or logo**. Rebranding is required anyway.
- Bundled third-party content (theme wallpapers, fonts such as `ttf-ia-writer`, Basecamp/HEY web-app entries) has its own licenses. Most of it goes away with the debloat.

## What Omarchy is

A full Arch-based distribution, not just dotfiles. It's split across several repos in the `omacom` GitHub org:

| Piece | Repo / host | Contents |
|---|---|---|
| Distro (scripts, configs, desktop shell, themes, migrations) | `omacom/omarchy` | ~5,300 files; installed as a package into `/usr/share/omarchy` |
| Package repo | `omacom/omarchy-pkgs`, served from `pkgs.omarchy.org` | 266 PKGBUILDs: their kernel, their apps, patched packages, prebuilt AUR packages |
| Installer ISO | `omacom/omarchy-iso`, served from `iso.omarchy.org` | archiso-based installer; pacstraps `install/omarchy-base.packages` |
| Arch mirror | `mirror.omarchy.org` | Pinned mirror of Arch core/extra |
| Updates | `omarchy update` + 228 migration scripts | Users upgrade from their package repo, with `edge` → `rc` → `stable` channels |

### Main repo layout

| Dir | Files | Purpose |
|---|---|---|
| `bin/` | 582 | All `omarchy-*` commands |
| `shell/` | 283 | Quickshell desktop shell (bar, menus, notifications, lock screen…) |
| `default/` | 472 | Default configs (hypr, plymouth, sddm, pacman, systemd, fonts…) |
| `config/` | 49 | User-level configs copied to `~/.config` |
| `install/` | 124 | Installer steps, hardware fixes, package lists |
| `migrations/` | 228 | Per-user upgrade scripts |
| `themes/` | 274 | Themes |
| `manual/` | 2,594 | User manual, mostly translations |
| `test/` | 535 | Tests, including QEMU end-to-end tests (`oligarchy-tests/`) |

## How deep the name goes

- ~56,000 occurrences of "omarchy" in 1,500+ files (excluding the manual and tests)
- 850 files with the name in the filename, including all 582 commands
- Built into the system itself: `$OMARCHY_PATH`, `~/.config/omarchy`, `~/.local/state/omarchy`, systemd units, sudoers files, pacman hooks, Plymouth and SDDM themes, and the custom icon font `omarchy.ttf`
- A rename is scriptable, but it should be a **re-runnable script**, not a one-time commit, so it can be re-applied after pulling upstream changes.

## Upstream churn

- Very active: about 50 commits in 4 days.
- v4.0 (August 2026) was a big architecture change: the standard tools were replaced by a custom Quickshell shell, and Omarchy itself became a pacman package.
- A renamed and debloated fork would conflict on every upstream merge. The choice is between **tracking upstream** (rename script plus a patch set, rebased regularly) and **forking hard** (freeze a version and diverge).

## Why they patch the kernel and packages

37 of the 266 packages carry patches.

### Kernel (`linux-omarchy`, ~200 patches on Linux 7.2)

Based on Arch's stock `linux` package. The patches:

1. **Desktop performance:** BORE CPU scheduler, ADIOS I/O scheduler, `-O3` build, scheduler and memory tweaks, zram/zstd speedups, Btrfs and FUSE performance.
2. **Hardware fixes and backports:** most of the list. Specific laptops (Dell XPS, ASUS ROG/Zenbook, Lenovo, Acer, Razer, Framework), Intel IPU webcams, AMD HDMI VRR/FRL/OLED, Intel panel power-saving bugs, Intel/MediaTek Bluetooth, Broadcom Wi-Fi, Thunderbolt/USB-C, laptop audio.
3. **Prebuilt NVIDIA open modules:** no DKMS rebuilds on kernel updates.
4. **Gaming extras:** e.g. `futex_waitv` for Wine/Proton.

Variants: `-bore`, `-eevdf`, `-muqss`, `-aarch64`. Apple Silicon gets a separate Asahi-based kernel (`linux-aurora`) and `mesa-aurora`.

### Other patched packages

- **Hyprland:** an NVIDIA EGL crash on exit, a monitor hotplug bug that kills clients, per-monitor VRR rules
- **power-profiles-daemon:** makes power profiles work on ARM laptops (Snapdragon, NVIDIA N1x/GB10, Apple)
- **Quickshell:** pinned past v0.3.2, plus a Qt compatibility patch

### Why their own repo

- Pinned, tested versions with release channels, plus a pinned Arch mirror
- Prebuilt AUR packages (`yay`, `superwhisper-bin`…), so users never compile from the AUR
- Distribution for their own apps (`omacalc`, `omasnap`, `owe`, `omawrite`, `hype`…)

### What this means for OrkaOS

None of this is needed for a single all-AMD desktop. The stock Arch kernel (or `linux-zen` for similar desktop tuning) supports all of this hardware. No package repo is needed either.

## Debloat candidates

Apps and features from Omarchy we likely don't want:

- **Apps:** LibreOffice, Obsidian, Docker, `superwhisper`, LocalSend, Moonlight, Pinta, .NET runtime
- **Database and language libraries:** MariaDB/Postgres libs, Ruby
- **Their own apps:** `omawrite`, `omacut`, `hype`, `signed`, `monologue`
- **AI stack:** `omarchy-local-ai`, `herdr`, the `omarchy-agent-*` commands
- **Web apps:** Basecamp, HEY and the other web-app launchers
- **Input methods:** CJK input (fcitx5 extras), if not needed

Hardware support that doesn't apply to this machine:

- ARM/aarch64, Apple/Mac, T2, Surface, Snapdragon, N1x/GB10
- Dell, ASUS, Lenovo, Framework and Tuxedo laptop fixes
- NVIDIA drivers and setup, Intel GPU/camera drivers
- Laptop features: battery, touchpad, lid, power profiles

The final list is still to be decided.

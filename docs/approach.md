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
├── installer/          # orka-install (runs in the live ISO) + target/ (files it writes once: greetd, mirrorlist)
├── pkg/                # the orka package: PKGBUILD, stage.sh (what goes where), release.sh, join-repo.sh
├── system/             # packaged system files (services, network, zram, PAM, app entries), as on the system
├── config/hypr/        # Hyprland defaults → /usr/share/orka/hypr
├── config/user/        # user dotfiles → ~/.config (seeded once by orka-setup-user)
├── bin/                # orka-* helper commands → /usr/bin
├── iso/                # build.sh, archiso profile overlay, test/ (QEMU VM + install test)
├── themes/             # color themes (theme.json + ghostty.conf) → /usr/share/orka/themes
├── branding/           # logo/ (the logo + make.sh), plymouth/ (boot screen), fastfetch/, limine/ (boot menu wallpaper), os-release
├── shell/              # Quickshell desktop
└── docs/
```

## Install flow

1. Boot the **OrkaOS ISO** (USB stick). No network needed: every package is in the ISO's local repo. Details: [ISO and installer](iso.md).
2. `orka-install` starts automatically on the first console and asks for the disk, the mode (whole disk / free space), hostname, username and password, then partitions (2 GiB ESP + Btrfs with Snapper), installs all packages from the local repo, sets up Limine (`linux-zen`, `linux`, Windows), services, the firewall and the Hyprland dotfiles, and points pacman at the normal Arch mirrors for later updates.
3. Reboot, log in on the login screen: Hyprland starts. See [desktop](desktop.md).

## Roadmap

Status on 2026-11-08 (night after day 4): everything up to branding is done: theme + dark/light mode, btop, mouse cursor and Animations pages in Settings, our own Calculator, the OrkaOS logo and name (OrkaOS 1.0) on the boot screen, bar, login screen, About and fastfetch, and six OrkaOS wallpapers. **First boots on the real PC** (from a Ventoy stick) found two problems, both fixed: the live system did not find itself on the Ventoy stick (`7accc6f`, see [ISO: USB sticks and Ventoy](iso.md#usb-sticks-and-ventoy); the installer also hides the stick now), and the pacman keyring setup failed because Windows kept the hardware clock in local time (Windows switched to UTC; the installer now retries and offers to set the time, `e91fe8c`). On the real PC the installer's disk menu then appeared; the user stopped there to buy a **new SSD dedicated to OrkaOS**.

Status on 2026-11-08 (day 5): **OrkaOS is installed on the new SSD and boots fine on the real PC.** First bug reports from using it:
- SUPER + W didn't close the cheat sheet (nor the launcher or Settings): those panels take the keyboard, but Hyprland handles SUPER + W first, so the window hidden under the panel closed instead. Fixed in `466c1b9` (the binding closes the open panel first), tested in the VM. Not on the PC yet: see the update mechanism below.
- After logging in, uwsm prints `graphical.target is queued for start, waiting for 60s...` before the desktop appears. Being analyzed live on the PC (see Known small issues).

Status on 2026-11-09 (end of day 5), all committed and pushed, **no package published yet**:
- **Updates without reinstalling: done.** OrkaOS is the pacman package `orka` (`pkg/`), published in our own signed package repository (the GitHub release `repo`); `sudo pacman -Syu` updates it with Arch. The installer installs the package and connects new systems; a system installed before that (the user's PC) runs `pkg/join-repo.sh` once. Tested in the VM: migrating an old install, a fresh install, an upgrade. See [updates](updates.md). The repository is on GitHub (bogdan9898/orka-os); the ISO is not published (3.4 GB, over GitHub's 2 GiB file limit), the README explains how to build it.
- Steam and Discord installed by default (`ae41cd5`; the installer enables multilib; new installs only, the user is fine with that).
- SUPER + SHIFT + S snips a screen region to the clipboard and `~/Pictures/Screenshots`, preview in the notification, click it to draw on it in satty (`c678070`); Sublime Text moved to SUPER + SHIFT + E. The package's install script reloads a running Hyprland after an update (an update could leave it in emergency mode).
- Clicking or scrolling the workspace numbers in the bar did nothing (a QML function named `focus` clashed with the built-in property): fixed in `d3cfac6`.

Status on 2026-11-10 (day 6, Claude Code working directly on the OrkaOS PC; latest release **`orka 1.0.r61`**, all committed and pushed). Done today, each in its own commit with docs:
- **Publishing moved to the PC:** the signing key is in the user's GnuPG keyring, `github-cli` is installed and logged in; `bash pkg/release.sh` publishes ([updates](updates.md)). `github-cli` and `vim` added to `packages.txt`.
- **Login wait fixed:** `systemd-networkd-wait-online` waited 2 min for the unused Wi-Fi; now `--any --timeout=10` (graphical.target after ~11.5 s instead of 2 min). The greeter waits for the boot itself and shows "Welcome, <name>" with the ripples for at least 3 s; `orka-session` starts uwsm without its console text (see Known small issues and [quickshell](quickshell.md)).
- **r60 broke every login** (an inline `sh -c '...'` session command, which greetd mangles by joining words with spaces); the user rolled back to r58 from a text console; fixed in r61 with `bin/orka-session`, verified by a real login through greetd in the VM. Lesson: anything at boot/login is tested end to end in the VM before publishing.
- **Grey boot screen with three dots fixed:** Plymouth's text fallback; `UseSimpledrm=1` in `/etc/plymouth/plymouthd.conf` (installer; added by hand on the PC). Details in [branding](branding.md#boot-screen-plymouth).
- **Updates:** no more `pacman -Sy` at first boot (partial-upgrade trap); `orka-update-reminder` asks for the first `pacman -Syu` at every login until it has run.
- **Bar:** notification center (bell, SUPER + N, 50 kept), keep-awake cup, hover labels (icons expand after 400 ms). fastfetch logo no longer squished.
- **ISO and tests on the PC:** `iso/build-in-docker.sh` builds the ISO without sudo (and fixed a real bug: Neovim plugins were not at their pinned commits); `iso/test/*` run here as well as on WSL; the install test passes. The Docker build cache was cleaned up afterwards; the test VM disk is kept on purpose (moved to `~/dev/orka-test` on 2026-11-10: nothing of the tests or builds goes directly into the home folder).

**Next up:**
1. **Confirm `orka 1.0.r68` on the PC (published 2026-11-10; needs a reboot): no boot-screen frame after the login screen** (`greetd.service.d/clear-console.conf` wipes `/dev/fb0`; Hyprland's background black; [quickshell](quickshell.md#login-screen)). r65 on the PC: fonts and transitions confirmed by the user, but the boot screen's logo and ripples flashed between "Welcome" and the desktop.
1. **Confirm `orka 1.0.r65` on the PC** (published 2026-11-10: no cage log flashing after a login, login screen fade-in / crossfade to "Welcome" / fade to black, Settings → Fonts; see [quickshell](quickshell.md#login-screen) and [settings](settings.md#fonts)). On the PC: `sudo pacman -Syu`, then once `sudo sed -i 's|^command = .*|command = "orka-greeter"|' /etc/greetd/config.toml`, then log out and in: the login screen fades in, the form crossfades into "Welcome", fades to black, then the desktop, no text. If the login screen doesn't come up: `CTRL + ALT + F2` and put the old command back (`env XCURSOR_THEME=Bibata-Modern-Classic XCURSOR_SIZE=24 QT_WAYLAND_DISABLE_WINDOWDECORATION=1 QS_DISABLE_CRASH_HANDLER=1 cage -s -d -- qs -p /usr/share/orka/shell/greeter.qml`), then `sudo systemctl restart greetd`.
2. The user keeps reporting bugs and small features from the PC: fix in the repo, test (VM end to end for boot/login), commit, and publish only when the user says so.
3. Open questions, not started, each needs the user's decision first:
   - Old installs don't get installer-written settings (e.g. `UseSimpledrm=1`, greetd config): should the package's install script bring them up to date?
   - The `docker` group the installer adds users to is root-equivalent (Docker's own docs): keep, rootless Docker, or `sudo docker`?
   - The PC's firmware (UEFI) phase (43 s cold boot, 72 s on reboots) is before Limine starts (Limine itself takes ~3 s, its timeout). Investigated 2026-11-10: most likely DDR5 memory training on AM5 (MSI B650 Tomahawk, BIOS 1.70 of 08/2023, EXPO on). BIOS options: Memory Context Restore + Power Down Mode, or a BIOS update. The user chose to leave it as it is.
   - Why the amdgpu devices never reach Plymouth inside the initramfs (worked around, cause unknown).
   - Publishing the ISO as split release assets (GitHub's limit is 2 GiB per file, the ISO is 3.5 GB): undecided.
   - ~2.5 s of black between the boot screen and the login screen (seen in the VM). Not the greeter itself: in the VM greetd to "Configuration Loaded" takes ~0.45 s, on the PC the greeter draws its first frame ~0.1 s after start; a shader cache would save ~3 ms (measured 2026-11-10).
4. AI review of AUR packages before they are built (planned, see 6. below), then the open TODOs (fonts, clicking through the interactive installer) and the real-machine checks below.

1. **Foundation**
   - [x] Package list (official + AUR), debloated from Omarchy v3.8.4 ([packages](packages.md))
   - [x] Offline ISO build (`iso/build.sh`) and installer (`orka-install`), UEFI only
   - [x] Multiple disks: contents shown in the disk menu, red warning before erasing any non-empty disk, Windows boot entry added at every boot (`orka-windows-entry`)
   - [x] Hyprland 0.57 config in Lua, key bindings ported from Omarchy (with sections, `orka/keys.lua`), `orka-*` helpers
   - [x] Shell and terminal setup: starship prompt, aliases (`eza`, `zoxide`, `fzf`), Ghostty and tmux configs ([shell](shell.md))
   - [x] Neovim config: LazyVim, plugins bundled into the ISO ([neovim](neovim.md))
   - [x] Themes: switching (5 themes, Settings → Theme, [settings](settings.md)); Orka "Deep water" + Orka Light; GTK and Qt apps colored from the theme (adw-gtk3, qt6ct + Breeze), Papirus icons
   - [x] btop follows the theme (`~/.config/btop/themes/orka.theme`, generated by `orka-settings`, reloaded live)
   - [x] Dark / light mode: a theme picked for each mode, switched in Settings → Theme or with SUPER + CTRL + D; apps and browsers learn it through the portal (`org.freedesktop.appearance color-scheme`) ([settings](settings.md#dark-and-light-mode))
   - [x] Settings → Animations: on/off, speed, window open/close style, workspace switch style, moving/resizing on/off ([settings](settings.md#pages))
   - [x] Own calculator app replacing GNOME Calculator: Standard, Expert and Programmer modes, history, follows the theme; Python + Qt Quick ([calculator](calculator.md))
   - [x] Mouse cursor: Bibata Modern Classic by default, same in Hyprland, GTK, Qt/KDE, X11 apps and the login screen; Settings → Mouse cursor picks a theme (Bibata variants, phinger, Breeze, Adwaita, your own in `~/.local/share/icons`) and a size ([settings](settings.md#mouse-cursor))
2. **Test in a VM**
   - [x] QEMU/KVM in the `archlinux` WSL distro; automated offline install test incl. Windows next to it / on a 2nd disk (`iso/test/install-test.sh`)
   - [x] Hyprland starts and basic bindings work in the VM
   - [x] Every desktop component checked in the VM with screenshots, keys and mouse clicks (QMP); headless VM has a silent sound card
   - [ ] Click through the interactive installer once (only the first screen and the warning box were checked visually)
3. **Branding:** Orka logo, Plymouth theme, boot menu, fastfetch, wallpapers.
   - [x] Boot menu (Limine) in the Deep water theme: wallpaper (`branding/limine/make-wallpaper.sh`), menu colors, OrkaOS branding color ([iso](iso.md#boot-menu-look)). The logo can be added to the wallpaper once it exists.
   - [x] Logo: the user's own design (orca over a wave in a ring, "Orka OS"), traced to SVG; badge for the bar, login screen, About and app icon ([branding](branding.md))
   - [x] fastfetch: the logo as a white image in Ghostty, half-block text logo on the consoles, OrkaOS info layout
   - [x] The name **OrkaOS 1.0** instead of Arch Linux: os-release (`ID_LIKE=arch`, kept by a pacman hook), `/etc/issue`, About, boot screen (Plymouth: logo above ripples on the Deep water background)
   - [x] Wallpapers (2560×1440): orcas in the ocean (the default, the user's picture), light rays, bubbles, moon, ice floes, fins ([branding](branding.md#wallpapers))
   - [x] Settings → Fonts: interface and monospace font with sizes, for the shell, GTK, Qt, fontconfig and the terminal ([settings](settings.md#fonts))
   - [ ] **TODO: choose Orka's fonts** (UI, monospace for terminal/editor, icon font). For now the current set is fine: `noto-fonts`, `noto-fonts-emoji`, `ttf-jetbrains-mono-nerd`, `woff2-font-awesome`.
4. **Install on the host** (new SSD just for OrkaOS, from the Ventoy stick; the Windows disks may stay connected, only the chosen disk is touched; checklist in [dual boot](hardware-and-dual-boot.md)). Live ISO boot + installer start: confirmed on the real PC 2026-11-08; **installed and booting on the new SSD the same day**. Then check what the VM can't: FreeSync/`highrr`, screenshots/recording, media keys, Wi-Fi/Bluetooth, KDE Connect.
5. **Quickshell desktop** (all done, see [quickshell](quickshell.md)): bar, notifications, polkit agent, launcher, lock screen, login screen (greetd + cage), cheat sheet, OSD (volume, mic, media, Caps/Num Lock), settings app ([settings](settings.md)). Possible later: notification center (history), tooltips in the bar, brightness via DDC/CI, confirmation dialog for log out.
6. **AI review of AUR packages** (planned 2026-11-09, discussed, not built). Why: AUR packages have been used to spread malware (new look-alike packages, orphaned packages taken over by a new maintainer). An AUR package runs its own code at build time (`makepkg` runs `build()`/`package()` as the user) and its `.install` script as root at install time, so the check must happen **before `makepkg`** (a pacman hook is too late).
   - [ ] Proposed design: a wrapper, e.g. `orka-yay`. It downloads the build files first (`yay -G`), reviews them, and only then calls `yay -S`. This is more reliable than plugging a script into yay's `--editmenu --editor` (whether yay aborts when the "editor" fails is unverified).
   - [ ] The review runs `claude -p` headless **with no tools** (it only reads text), with a fixed verdict format: safe / suspicious / malicious + reasons. Anything other than safe stops and asks the user; forcing needs an explicit flag.
   - [ ] Input: PKGBUILD, `.install`, patches, **the diff since the installed version** (yay keeps it), AUR metadata (maintainer changes, first submitted, votes), source URLs (real upstream or not). Red flags: `curl | sh`, base64/obfuscation, downloads in `build()`, writing to shell rc files or systemd units, `-bin` packages from unexpected hosts.
   - Limits: it can't see inside downloaded tarballs or binaries (only judge where they come from); prompt injection in comments (hence no tools, a strict format, and "unclear = stop"); one API call per AUR install or update (review only the diff on updates). A second opinion, not a guarantee.

### Known small issues

- `pacman` warns "database file for 'core' does not exist" until the first `pacman -Syu` (the install is offline). Until that first full upgrade, `orka-update-reminder` shows a notification at every login; clicking it runs `sudo pacman -Syu` in a terminal. `orka-firstboot` no longer runs `pacman -Sy` (changed 2026-11-09): refreshing the lists without upgrading set up a partial upgrade on the next `pacman -S`, a trap that grows with the ISO's age.
- The luarocks pacman hook prints `/usr/bin/lua5.1: No such file or directory` during install (harmless; add `lua51` if Neovim plugins need LuaRocks builds).
- No current ISO exists: the last one (`orkaos-2026.11.08-x86_64.iso`, in the old WSL setup's `~/orka-build/out`) predates the 2026-11-09/10 fixes, including installer-only ones (Plymouth `UseSimpledrm=1`, the self-test). Build a new one before a fresh install: `iso/build-in-docker.sh` (on the PC, no sudo; ~30-45 min from scratch, the cache was cleaned up).
- **Login wait (real PC, fixed 2026-11-09, confirmed after a reboot: `graphical.target` after 11.9 s instead of 2 min 3 s):** after the password, uwsm printed `graphical.target is queued for start, waiting for 60s...`: uwsm waits while `graphical.target` has a start job queued. Measured on the PC (`systemd-analyze critical-chain graphical.target`): the target was reached 2 min 3 s into the boot, held by `docker.service` ← `network-online.target` ← `systemd-networkd-wait-online` (2 min, its timeout). Both `.network` files say `RequiredForOnline=routable`, so it waited for Wi-Fi too, which was not connected (Ethernet was up in seconds); reproduced with `systemd-networkd-wait-online --timeout=5` (fails) vs. `--any` (succeeds at once). Fix: a drop-in (`system/usr/lib/systemd/system/systemd-networkd-wait-online.service.d/orka.conf`) runs it with `--any --timeout=10`: online as soon as one link is up, at most 10 s with no network. And the greeter waits for the boot itself (same check as uwsm, up to 20 s, and shows it at least 3 s) with the boot screen's ripples, so uwsm's text no longer shows (see [quickshell.md](quickshell.md)). Kept: `docker.service` (not `docker.socket`: containers with a restart policy would only start on the first `docker` command) and uwsm's own check (not `uwsm start -g 0`).
- The keyring failure on the real PC did not reproduce in the VM (wrong clock in 2019, 2045, or +2 h with internet all worked); the cause given (clock 2 h ahead, corrected by a network time sync during `pacman-init`) is likely but unproven. Switching Windows to UTC made it go away. Rebuild with `sudo ./iso/build.sh iso` after changes (`nvim iso` if the Neovim config changed, `repo iso` if packages changed).
- **VirtualBox** (tried by the user 2026-11-07, not a supported test target; QEMU/KVM with VirGL is): the ISO is UEFI only, so the VM needs "Enable EFI" (and Secure Boot off). Without 3D acceleration the login screen's `cage` stops with `VMware: No 3D enabled` / `Unable to create the wlroots renderer`. With 3D on, `cage` starts (GL ES 3.0 on SVGA3D) but the Quickshell greeter is disconnected with `The Wayland connection experienced a fatal error: Protocol error … handle for plane 0: Invalid argument`: VirtualBox's vmwgfx can't import the client's dmabuf buffers. Both are VirtualBox graphics limits, not OrkaOS bugs (they don't happen in QEMU/VirGL and aren't expected on the AMD GPU). The user was told not to fix it. If ever wanted: a software-rendering fallback for the greeter (`WLR_RENDERER=pixman` for cage) would at least show the login screen; Hyprland has no software renderer.
- Not yet seen on screen in the VM after its last change: the 2560×1440 version of `orka-ice.png` (replaced the 2560×1400 one after the last VM run; same install step). The boot screen's ripples are faint and small in the VM screenshots: judge on the real machine.
- Faint rounded window shadow visible at the bottom edge behind the dimmed overlays (settings, cheat sheet) right after a theme change: Hyprland redraw, cosmetic.
- Not testable in the VM, check on the real machine: FreeSync/`highrr`, several monitors (bar per monitor, popups on the focused one), suspend (lock before sleep), screen off after idle, real Wi-Fi/Bluetooth icons, the system tray with KDE Connect, sound device switching, notification clicks from real apps, the monitor's resolution (the boot menu wallpaper is 2560x1440: regenerate with `branding/limine/make-wallpaper.sh WxH` if it differs) and the boot menu's font size at that resolution.

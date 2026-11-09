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

**Next up:**
1. The user keeps reporting bugs from the PC ("a few things to fix" before the first release). Fix each, test in the VM, commit and push.
2. **First release, only when the user says so:** `pkg/release.sh` publishes the package (see [updates](updates.md#publishing-an-update)); then a `v1.0` GitHub release (tag and notes, no ISO). Then the PC runs `pkg/join-repo.sh` once and `sudo pacman -Syu`: that is how all the fixes above reach it. The user must also back up the signing key (see [updates](updates.md#the-signing-key)).
3. The uwsm login wait, analyzed with Claude Code running on the PC (see Known small issues). Don't fix it blind.
4. AI review of AUR packages before they are built (planned, see 6. below).
5. Then the open TODOs (fonts, clicking through the interactive installer) and the real-machine checks below.

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
- The ISO in `~/orka-build/out` (`orkaos-2026.11.08-x86_64.iso`, 3.4 GB, sha256 `25400a9107a94adba7710452067b4dc296f0b7790e6f6ee6db5dab0a474631b2`) was rebuilt on day 5 with the `orka` package (everything up to and including the SUPER + W fix); it overwrote the same-named ISO built from `e91fe8c` that the user installed on the PC. The PC doesn't need it: it updates through the package repository after running `pkg/join-repo.sh` once. The 11.05, 11.06 and 11.07 ISOs next to it can be deleted. It predates `ae41cd5` (Steam, Discord) and later: rebuild (`sudo ./iso/build.sh repo iso`, packages changed) before a fresh-install test. Desktop fixes can be tested without a rebuild: build the package with a higher version and install it in the VM with `pacman -U` (see [updates](updates.md#tests)).
- **Login wait (real PC, fixed 2026-11-09, confirmed after a reboot: `graphical.target` after 11.9 s instead of 2 min 3 s):** after the password, uwsm printed `graphical.target is queued for start, waiting for 60s...`: uwsm waits while `graphical.target` has a start job queued. Measured on the PC (`systemd-analyze critical-chain graphical.target`): the target was reached 2 min 3 s into the boot, held by `docker.service` ← `network-online.target` ← `systemd-networkd-wait-online` (2 min, its timeout). Both `.network` files say `RequiredForOnline=routable`, so it waited for Wi-Fi too, which was not connected (Ethernet was up in seconds); reproduced with `systemd-networkd-wait-online --timeout=5` (fails) vs. `--any` (succeeds at once). Fix: a drop-in (`system/usr/lib/systemd/system/systemd-networkd-wait-online.service.d/orka.conf`) runs it with `--any --timeout=10`: online as soon as one link is up, at most 10 s with no network. And the greeter waits for the boot itself (same check as uwsm, up to 20 s, and shows it at least 3 s) with the boot screen's ripples, so uwsm's text no longer shows (see [quickshell.md](quickshell.md)). Kept: `docker.service` (not `docker.socket`: containers with a restart policy would only start on the first `docker` command) and uwsm's own check (not `uwsm start -g 0`).
- The keyring failure on the real PC did not reproduce in the VM (wrong clock in 2019, 2045, or +2 h with internet all worked); the cause given (clock 2 h ahead, corrected by a network time sync during `pacman-init`) is likely but unproven. Switching Windows to UTC made it go away. Rebuild with `sudo ./iso/build.sh iso` after changes (`nvim iso` if the Neovim config changed, `repo iso` if packages changed).
- **VirtualBox** (tried by the user 2026-11-07, not a supported test target; QEMU/KVM with VirGL is): the ISO is UEFI only, so the VM needs "Enable EFI" (and Secure Boot off). Without 3D acceleration the login screen's `cage` stops with `VMware: No 3D enabled` / `Unable to create the wlroots renderer`. With 3D on, `cage` starts (GL ES 3.0 on SVGA3D) but the Quickshell greeter is disconnected with `The Wayland connection experienced a fatal error: Protocol error … handle for plane 0: Invalid argument`: VirtualBox's vmwgfx can't import the client's dmabuf buffers. Both are VirtualBox graphics limits, not OrkaOS bugs (they don't happen in QEMU/VirGL and aren't expected on the AMD GPU). The user was told not to fix it. If ever wanted: a software-rendering fallback for the greeter (`WLR_RENDERER=pixman` for cage) would at least show the login screen; Hyprland has no software renderer.
- Not yet seen on screen in the VM after its last change: the 2560×1440 version of `orka-ice.png` (replaced the 2560×1400 one after the last VM run; same install step). The boot screen's ripples are faint and small in the VM screenshots: judge on the real machine.
- Faint rounded window shadow visible at the bottom edge behind the dimmed overlays (settings, cheat sheet) right after a theme change: Hyprland redraw, cosmetic.
- Not testable in the VM, check on the real machine: FreeSync/`highrr`, several monitors (bar per monitor, popups on the focused one), suspend (lock before sleep), screen off after idle, real Wi-Fi/Bluetooth icons, the system tray with KDE Connect, sound device switching, notification clicks from real apps, the monitor's resolution (the boot menu wallpaper is 2560x1440: regenerate with `branding/limine/make-wallpaper.sh WxH` if it differs) and the boot menu's font size at that resolution.

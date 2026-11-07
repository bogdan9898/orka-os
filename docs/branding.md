# Branding

OrkaOS has its own name, version (**1.0**) and logo: an orca leaping over a wave inside a ring, with "Orka OS" (the user's own design, `branding/logo/source.png`).

## The logo files

All made from `source.png` by **`branding/logo/make.sh`** (traced to vectors with potrace; needs imagemagick, potrace, librsvg, chafa, python3). Run it again after changing the source.

| File | What | Used for |
|---|---|---|
| `logo/orkaos-logo.svg` | Full logo with the name, white, see-through inside the ring | (the boot screen's PNG is made from it) |
| `logo/orkaos-logo-badge.svg` | Full logo with a black disc inside the ring | Settings → About |
| `logo/orkaos-badge.svg` | Without the name, black disc ("dark form") | The bar (left end, instead of the fish), the login screen, the app icon `orkaos` |
| `logo/orkaos-mark.svg` | Without the name, white, see-through | (fastfetch's PNG is made from it) |
| `plymouth/orka/logo.png`, `ripple.png` | Boot screen images | Plymouth |
| `fastfetch/orkaos.png`, `orkaos.txt` | fastfetch logo: image, and drawn with half blocks for terminals without images | fastfetch |

The badge keeps its black disc and white lines in light and dark themes alike; its ring makes it stand out on both.

Installed to `/usr/share/orka/branding/`; the badge also as `/usr/share/icons/hicolor/scalable/apps/orkaos.svg`.

## The name

| Where | What |
|---|---|
| `/usr/lib/os-release` (`/etc/os-release` links to it) | `NAME="OrkaOS"`, `PRETTY_NAME="OrkaOS 1.0"`, `VERSION="1.0"`, `ID=orkaos`, `ID_LIKE=arch` (so tools that know Arch still treat it as Arch), `LOGO=orkaos`. From `branding/os-release`. The `filesystem` package ships Arch's version of this file; the pacman hook `/etc/pacman.d/hooks/orka-os-release.hook` puts ours back after each update |
| `/etc/issue` | The text console banner: `OrkaOS 1.0` in the Orka blue |
| Limine boot menu | Entries and the menu title say OrkaOS (`TARGET_OS_NAME`, `interface_branding`) |
| ISO | `orkaos-<date>-x86_64.iso`, label `ORKAOS_<yyyymm>`, boot entry "OrkaOS installer" |
| Settings → About | The full logo, name and version (from os-release) |
| Login screen | The badge and "OrkaOS", bottom left |

## Boot screen (Plymouth)

From the moment Limine starts Linux until the login screen: the boot menu's Deep water background, the full logo in white (30 % of the screen height) and below it ripples spreading on the water (three rings growing and fading, a 2-second cycle). Theme `orka` in `/usr/share/plymouth/themes/orka/` (`branding/plymouth/orka/`: `orka.plymouth`, `orka.script`; `logo.png`, `ripple.png` and `background.png`, the boot menu wallpaper as PNG because Plymouth only loads PNG, all made by `make.sh`).

Set up by `orka-install`: `plymouth` in the initramfs hooks (`/etc/mkinitcpio.conf.d/orka.conf`), `quiet splash` on the kernel command line (`/etc/default/limine`), `Theme=orka` in `/etc/plymouth/plymouthd.conf`; greetd waits for Plymouth to finish (`greetd.service.d/plymouth.conf`). After changing the theme: `sudo limine-mkinitcpio` (rebuilds the initramfs with it).

## fastfetch

`/etc/xdg/fastfetch/config.jsonc` (from `branding/fastfetch/config.jsonc`; your `~/.config/fastfetch/config.jsonc` replaces it): the logo as a white image in Ghostty (kitty graphics protocol), then title, OS (`OrkaOS 1.0 x86_64`), kernel, uptime, packages, shell, display, WM, the OrkaOS theme and dark/light mode, icons, cursor, terminal, CPU, GPU, memory, disk and the terminal's colors. Labels are the terminal's blue, which the OrkaOS themes set to the accent color.

Terminals that can't show images (the text consoles): the `fastfetch` shell function (`config/bash/functions`) switches to `orkaos.txt`, the logo drawn with half blocks that every console font has.

## Tests

The installed system's self-test prints a `branding:` line (os-release values, Plymouth theme, Plymouth in the initramfs, hook, icon, fastfetch config, `splash` on the command line). `iso/test/boot-splash-shots.sh` boots the test VM and saves a screenshot every half second (the boot menu, the boot screen, the login screen).

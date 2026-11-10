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
| `/usr/lib/os-release` (`/etc/os-release` links to it) | `NAME="OrkaOS"`, `PRETTY_NAME="OrkaOS 1.0"`, `VERSION="1.0"`, `ID=orkaos`, `ID_LIKE=arch` (so tools that know Arch still treat it as Arch), `LOGO=orkaos`. From `branding/os-release`. The `filesystem` package ships Arch's version of this file; the orka package's pacman hook `/usr/share/libalpm/hooks/orka-os-release.hook` puts ours back after each update |
| `/etc/issue` | The text console banner: `OrkaOS 1.0` in the Orka blue |
| Limine boot menu | Entries and the menu title say OrkaOS (`TARGET_OS_NAME`, `interface_branding`) |
| ISO | `orkaos-<date>-x86_64.iso`, label `ORKAOS_<yyyymm>`, boot entry "OrkaOS installer" |
| Settings → About | The full logo, name and version (from os-release) |
| Login screen | The badge and "OrkaOS", bottom left |

## Boot screen (Plymouth)

From the moment Limine starts Linux until the login screen: the boot menu's Deep water background, the full logo in white (30 % of the screen height) and below it ripples spreading on the water (three rings growing and fading, a 2-second cycle). Theme `orka` in `/usr/share/plymouth/themes/orka/` (`branding/plymouth/orka/`: `orka.plymouth`, `orka.script`; `logo.png`, `ripple.png` and `background.png`, the boot menu wallpaper as PNG because Plymouth only loads PNG, all made by `make.sh`).

Set up by `orka-install`: `plymouth` in the initramfs hooks (`/etc/mkinitcpio.conf.d/orka.conf`), `quiet splash` on the kernel command line (`/etc/default/limine`), `Theme=orka` and `UseSimpledrm=1` in `/etc/plymouth/plymouthd.conf`; greetd waits for Plymouth to finish (`greetd.service.d/plymouth.conf`). After changing the theme or this file: `sudo limine-mkinitcpio` (rebuilds the initramfs with it).

**Grey screen with three dots (fixed 2026-11-10):** on the real PC Plymouth showed its built-in *text* theme for ~7 s before the login screen. Its debug log (`plymouth.debug` on the kernel command line, log in `/var/log/plymouth-debug.log`) showed why: it ignores the firmware framebuffer (simpledrm) while waiting for the real GPU driver, the amdgpu devices never reached it inside the initramfs, so after `DeviceTimeout` (8 s) it fell back to text, and it ignored the GPUs when their events came after the switch to the real root ("already using text splash"). Why the events don't arrive in the initramfs is not known. `UseSimpledrm=1` makes it draw on the firmware framebuffer from the start; tested with `plymouth.use-simpledrm` on the kernel command line: the animation stays until the login screen. The VM never showed it (its GPU is ready from the start).

## fastfetch

`/etc/xdg/fastfetch/config.jsonc` (from `branding/fastfetch/config.jsonc`; your `~/.config/fastfetch/config.jsonc` replaces it): the logo as a white image in Ghostty (kitty graphics protocol), then title, OS (`OrkaOS 1.0 x86_64`), kernel, uptime, packages, shell, display, WM, the OrkaOS theme and dark/light mode, icons, cursor, terminal, CPU, GPU, memory, disk and the terminal's colors. Labels are the terminal's blue, which the OrkaOS themes set to the accent color.

Terminals that can't show images (the text consoles): the `fastfetch` shell function (`config/bash/functions`) switches to `orkaos.txt`, the logo drawn with half blocks that every console font has.

## Tests

The installed system's self-test prints a `branding:` line (os-release values, Plymouth theme, Plymouth in the initramfs, hook, icon, fastfetch config, `splash` on the command line). `iso/test/boot-splash-shots.sh` boots the test VM and saves a screenshot every half second (the boot menu, the boot screen, the login screen).

## Wallpapers

In `/usr/share/orka/wallpapers/` (Settings → Wallpaper lists them), all 2560×1440:

| File | What |
|---|---|
| `orka-ocean.png` | Orcas swimming under the light from the surface (the user's picture). **The default** for new users (`.wallpaper` in `config/user/orka/settings.json`) |
| `deep-water-rays.jpg` | The boot menu's light rays (`branding/limine/wallpaper.jpg`) |
| `deep-water-bubbles.jpg` | Light from above, bubbles rising through dark water (`branding/wallpapers/bubbles.py`) |
| `orka-moon.png` | An orca leaping in front of the full moon at night (the user's picture) |
| `orka-ice.png` | Orcas swimming among ice floes, seen from above (the user's picture) |
| `orka-fins.png` | Orca fins cutting through the waves, the water seen above and below the surface (the user's picture) |

`branding/wallpapers/make.sh` makes the bubbles one (python3, librsvg, imagemagick). "Theme default" in Settings → Wallpaper still means the theme's own wallpaper or its background color.

### Blurry wallpapers, and getting more (open, not decided)

Reported by the user 2026-11-10: some wallpapers look soft on the 2560×1440 monitor. The user's AI-generated pictures came out of the generator smaller than that and were scaled up. A rough check (how much detail a picture loses when shrunk to 50 % and enlarged again; an enlarged picture loses little) gave: `orka-ice.png` 0.0033 (lowest by far), `orka-ocean.png` 0.0066, `orka-moon.png` 0.0079, `orka-fins.png` 0.0071, `deep-water-bubbles.jpg` 0.019. The light rays are a smooth gradient, so their low score means nothing. Only a hint: the user has to say which ones look blurry. We also want more wallpapers.

Options (looked up 2026-11-10; the generators' sizes come from comparison blogs, not the vendors' docs, so check them before paying):

1. **Generate again at full size, then shrink** (recommended): shrinking stays sharp, enlarging blurs. Flux 1.1 Pro Ultra (Black Forest Labs) is said to do 16:9 up to ~4 megapixels (2560×1440 is 3.7); Midjourney's HD mode is said to give 2912×1632 at 16:9. Ideogram (~2048 px, its upscaler crops to its own ratios) fits worse.
2. **AI-upscale the originals** if the user still has them: Real-ESRGAN runs locally on the AMD GPU through Vulkan (AUR `realesrgan-ncnn-vulkan`, upstream stale; `upscayl-ncnn-git` is a newer fork). Better than plain scaling, worse than generating at full size. Installing it needs the user's OK.
3. **Real orca photos** under a clear license, since the repository is public: NOAA (mostly public domain as US government work; some are other people's photos under CC BY-SA, check each one and credit the photographer) and Wikimedia Commons (license per file). The Unsplash License is disputed for distributions (not on Fedora's list of good content licenses, Parabola blacklisted wallpapers under it). Wallpaper sites like Wallhaven: rights mostly unclear, avoid.
4. **Made by code**, like `bubbles.py`: sharp at any resolution, no license question. Ideas in the Deep water style: light rays, caustics, ripples, a silhouette built from the logo.

# Settings

**OrkaOS Settings** (`SUPER + ALT + SPACE`, right click on the bar's fish button, or "OrkaOS Settings" in the launcher) is a window of the OrkaOS shell (`shell/settings/`). Escape or a click outside closes it.

Everything it changes is stored in **`~/.config/orka/settings.json`** and applied at once by **`orka-settings`**, which works from a terminal too:

```sh
orka-settings get                          # all settings
orka-settings set .appearance.dark '"tokyo-night"'   # change one value and apply it
orka-settings set .idle.lockAfter 600
orka-settings mode toggle                  # dark ↔ light mode (also: dark, light; no argument prints it)
orka-settings apply                        # re-apply everything
orka-settings themes                       # installed themes (JSON)
orka-settings about                        # system information (JSON)
```

## Pages

| Page | What | Stored as | Applied by |
|---|---|---|---|
| Theme | Dark mode switch; the theme for dark mode and the theme for light mode, picked independently (color swatches) | `.appearance.mode` (`"dark"`/`"light"`), `.appearance.dark`, `.appearance.light` | `current/theme.json`, `current/ghostty.conf`, `current/hyprland.lua`, `hyprctl reload`, Ghostty reload (SIGUSR2), GTK `color-scheme` → portal (see [Dark and light mode](#dark-and-light-mode)) |
| Wallpaper | Theme default (its wallpaper or background color), or an image from your folder | `.wallpaper` (path, `""` = theme default) | `orka-wallpaper` (swaybg) |
| Animations | On/off; speed (Relaxed ×1.5, Normal, Quick ×0.7, Snappy ×0.45); opening and closing windows (Pop in, Slide, Grow, Fade only); switching workspaces (Off, Slide, Slide up/down, Fade, Slide + fade); moving and resizing windows on/off | `.animations.enabled`, `.speed`, `.windows` (`popin` `slide` `gnomed` `fade`), `.workspaces` (`off` `slide` `slidevert` `fade` `slidefade`), `.moves` | `current/hyprland.lua` → `orka/looknfeel.lua` (`hl.animation`), `hyprctl reload` |
| Mouse cursor | Size (24, 32, 40, 48) and a cursor theme, each shown with its arrow, hand, text and busy cursor | `.cursor.theme`, `.cursor.size` | see [Mouse cursor](#mouse-cursor) |
| Display | Resolution + refresh rate (from the modes the monitor reports), scale (100–200 %), per monitor. **Goes back after 15 s** unless you press Keep | `.monitors["DP-1"] = { mode, scale }` | `current/hyprland.lua` → `hl.monitor`, `hyprctl reload` |
| Idle & lock | Lock after / screen off after: 1, 2, 5, 10, 15, 30 min, 1 h, never; "Lock now" | `.idle.lockAfter`, `.idle.screenOffAfter` (seconds) | The shell (`lock/Idle.qml`) |
| Sound | Default output and input device, volume, mute | Pipewire itself (remembered by WirePlumber) | Pipewire |
| Night light | On/off, 2500–6500 K; stays on after logging in again | `.nightlight.on`, `.nightlight.temperature` | hyprsunset |
| Keyboard | Layouts (search the 100 xkeyboard-config layouts), switch key (Alt + Shift, Ctrl + Shift, both Alts, Caps Lock), repeat delay and speed, a field to try it | `.keyboard.layouts`, `.switch`, `.repeatRate`, `.repeatDelay` | `current/hyprland.lua` → `input`, `hyprctl reload` |
| About | System, computer name, install date, CPU, GPU, memory, disk, uptime, kernel, Hyprland, Quickshell | – | – |

## Your folders

| Folder | For |
|---|---|
| `~/.config/orka/themes/<name>/theme.json` | Your themes (a name that exists in `/usr/share/orka/themes` replaces the built-in one). Format: [themes/README.md](../themes/README.md) |
| `~/Pictures/Wallpapers/` | Your wallpapers (JPEG, PNG, WebP), shown as thumbnails. `/usr/share/orka/wallpapers/` is for OrkaOS's own (none yet: branding TODO) |
| `~/.local/share/icons/<name>/` | Your cursor themes: the folder that has a `cursors/` folder inside (as found in the downloaded archive, e.g. from GitHub or gnome-look.org). A name that also exists in `/usr/share/icons` replaces that one. `~/.icons` works too |

All three pages have an "Open … folder" button.

## Themes

Built in (all work offline, also in Ghostty and Neovim): **Orka** ("Deep water": navy, ocean blue, sea-glass teal; the default for dark mode), **Orka Light** (the default for light mode), **Tokyo Night**, **Catppuccin Mocha**, **Catppuccin Latte** (light).

### Dark and light mode

There's a theme for dark mode and one for light mode (Settings → Theme lists the dark themes under one and the light themes under the other). The **Dark mode** switch on that page, **SUPER + CTRL + D** (`orka-darkmode`, with an on-screen notice) or `orka-settings mode toggle` changes which one is in use, everywhere at once.

Apps learn the mode the standard way: `orka-settings` sets the GNOME setting `org.gnome.desktop.interface color-scheme` (`prefer-dark` / `prefer-light`), and `xdg-desktop-portal-gtk` publishes it as the portal setting **`org.freedesktop.appearance color-scheme`** (1 = dark, 2 = light), with a `SettingChanged` signal on every switch. Firefox, Chromium-based browsers (and so websites' `prefers-color-scheme`), Electron apps and GTK 4/libadwaita apps read it from there and follow along live. To ask from a script:

```sh
orka-settings mode                                   # dark / light
busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
  org.freedesktop.portal.Settings ReadOne ss org.freedesktop.appearance color-scheme   # v u 1 (dark) / v u 2 (light)
```

Older settings files with a single `"theme"` are converted on the next change or login: that theme becomes the theme of its own mode, and that mode is switched on.

A theme reaches:

| App | How | When |
|---|---|---|
| The shell (bar, notifications, launcher, lock and login...) | `Theme.qml` watches `~/.config/orka/current/theme.json` | At once |
| Hyprland borders | `orka/theme.lua` ← `orka/settings.lua` ← `current/hyprland.lua` | At once (`hyprctl reload`) |
| Ghostty | `config-file = ?"~/.config/orka/current/ghostty.conf"` in your Ghostty config: a built-in Ghostty theme by name, or the theme's own `ghostty.conf` | At once (SIGUSR2) |
| tmux | Uses the terminal's colors (named colors only) | With Ghostty |
| Neovim | `plugins/orka.lua` reads `"neovim"` from `current/theme.json` | At start, and in a running Neovim when it gets focus |
| GTK / Firefox (portal) | `gsettings` `color-scheme` (prefer-dark/light), `gtk-theme` (adw-gtk3 / adw-gtk3-dark), `icon-theme`; colors in `current/gtk.css`, imported by `~/.config/gtk-{3,4}.0/gtk.css` | Light/dark and GTK 3 theme at once; the colors when an app starts |
| Qt / KDE apps (Dolphin, Filelight, KDE Connect) | `QT_QPA_PLATFORMTHEME=qt6ct`: Breeze style, palette `current/qt6ct-colors.conf` and icon theme set in `~/.config/qt6ct/qt6ct.conf`; KDE colors in `~/.config/kdeglobals` (only those keys are changed, the rest of both files is yours) | When an app starts |
| Icons | Papirus-Dark, or Papirus-Light for light themes (`"icons"` in `theme.json` to choose another), for GTK, Qt and KDE apps | As above |
| Wallpaper | The theme's `wallpaper` image, or its background color, when the wallpaper is "Theme default" | At once |
| btop | `~/.config/btop/themes/orka.theme`, generated from the theme's colors; `color_theme = "orka"` in `~/.config/btop/btop.conf` is set only while btop's theme is `"Default"` (or not set), so a theme you pick in btop's options stays | At once (SIGUSR2) |

The GTK, Qt, icon, btop and cursor settings are also applied at each login (`orka-settings apply apps`), because `gsettings` needs the session's D-Bus.

## Mouse cursor

Default: **Bibata Modern Classic** (black), size 24, the same in every color theme. Settings → Mouse cursor offers every installed cursor theme:

- **Bibata** (`bibata-cursor-theme-bin`, AUR): Modern (rounded) and Original (pointed), each in Classic (black), Ice (white) and Amber, plus left-handed `-Right` versions
- **phinger** (`phinger-cursors`, AUR): light and dark, plus left-handed versions
- **Breeze** and **Breeze Light** (`breeze-cursors`, comes with the Breeze Qt style), **Adwaita** (GNOME's)
- your own, from `~/.local/share/icons`

The previews are made by `orka-settings cursors` with `xcur2png` and cached in `~/.cache/orka/cursor-previews/`. From a terminal:

```sh
orka-settings cursors                                                  # installed cursor themes (JSON)
orka-settings set .cursor '{"theme":"Bibata-Modern-Ice","size":32}'
```

Most apps let Hyprland draw the cursor (Wayland cursor-shape protocol), so it changes everywhere at once; an app that draws its own (some X11 apps) picks it up when it's started again.

| Where | How |
|---|---|
| Hyprland and the apps it starts | `XCURSOR_THEME`/`XCURSOR_SIZE`/`HYPRCURSOR_SIZE` in `orka/envs.lua` (from `current/hyprland.lua`); in a running session `hyprctl setcursor` |
| GTK | `gsettings` `cursor-theme`, `cursor-size` |
| Qt / KDE apps | `[Mouse]` in `~/.config/kcminputrc` |
| X11 apps (XWayland) | `~/.local/share/icons/default/index.theme` (`Inherits=`) |
| Login screen | `XCURSOR_THEME` in `/etc/greetd/config.toml` (fixed, not from your settings) |

## How Hyprland gets the values

`orka-settings` writes `~/.config/orka/current/hyprland.lua` (generated, rewritten on each change) and runs `hyprctl reload`. `orka/settings.lua` loads that file; `orka/theme.lua` takes the colors, and `orka/init.lua` applies the monitors and keyboard after the other OrkaOS defaults. Your own `~/.config/hypr/*.lua` are loaded after that, so a setting there (e.g. `kb_layout` in `input.lua`) wins over the settings app.

The login screen doesn't use these settings (it runs before you log in, as another user).

## Tested

2026-11-07 (animations) in the VM from a fresh install: the Animations page shows the defaults; `orka-settings set .animations '{"speed":0.7,"windows":"slide","workspaces":"slidefade","moves":false}'` changes Hyprland's live table (`hyprctl animations`: windowsIn 2.87 `slide`, workspaces 2.45 `slidefade 20%`, windowsMove off) and the page follows; turning animations off sets `animations:enabled` false. All 20 window × workspace style combinations pass `Hyprland --verify-config`; unknown values fall back to the defaults. Not judged yet: how the animations look and feel (screenshots can't show motion; check on the real machine).

2026-11-07 (dark/light mode) in the VM from a fresh install: SUPER + CTRL + D switches the shell, Ghostty, Hyprland borders and Firefox (its window and the page's color scheme, live) to Orka Light; the Settings → Theme switch turns dark mode back on; the portal's `org.freedesktop.appearance color-scheme` reads 1 in dark mode and 2 in light mode, `gsettings` `color-scheme` `prefer-dark`/`prefer-light`. Old settings with a single `"theme"` are converted (tested in WSL for a dark and a light theme). Not yet seen: a Chromium-based browser, an Electron app.

2026-11-07 (btop, cursor) in the VM from a fresh install: btop opens in the Orka colors (`color_theme = "orka"` set on the first login); Bibata Modern Classic in the session (`XCURSOR_THEME`, gsettings); Settings → Mouse cursor lists the themes with previews, a click on a theme changes the pointer at once, and so does the size (Huge, 48). A running btop takes a changed theme file on SIGUSR2 (tested in WSL). Not yet seen: the login screen's cursor, a theme of your own from `~/.local/share/icons` in the VM (tested only with `orka-settings cursors` in WSL), XWayland apps.

2026-11-07 (theming) in the VM from a fresh install: the session and the shell get `QT_QPA_PLATFORMTHEME=qt6ct`; Dolphin (Breeze style, Papirus icons, Deep water colors, soft unfocused selection), gnome-calculator (libadwaita) and the launcher's app icons in Orka, then `orka-settings set .theme '"orka-light"'` switches the bar, Ghostty, Hyprland borders, GTK and, for newly started apps, Qt. Without `[UiSettings] ColorScheme=*` in kdeglobals, Dolphin ignored the qt6ct palette (Breeze Light with unreadable labels).

2026-11-06 in the VM, from a fresh install, by clicking (QEMU's QMP `input-send-event`, now enabled in `iso/test/vm.sh`): all eight pages show real data (26 display modes of the virtual monitor, the sound devices, 100 keyboard layouts, system information); choosing Tokyo Night recolors the shell, the Hyprland borders and Ghostty at once; a wallpaper from `~/Pictures/Wallpapers` is applied; 1024×768 is applied and, without pressing Keep, goes back to 1280×800 after 15 s; the night light turns on; searching "roman" and Enter adds the Romanian layout (`hyprctl getoption input:kb_layout` → `us,ro`). Not yet tried: the Idle & lock choices by click (same mechanism; the VM's screen had just changed size), Sound device switching (the VM has one device each way), the scale choices, several monitors, Neovim following a theme change, a theme of your own.

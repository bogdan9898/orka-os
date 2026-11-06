# Settings

**OrkaOS Settings** (`SUPER + ALT + SPACE`, right click on the bar's fish button, or "OrkaOS Settings" in the launcher) is a window of the OrkaOS shell (`shell/settings/`). Escape or a click outside closes it.

Everything it changes is stored in **`~/.config/orka/settings.json`** and applied at once by **`orka-settings`**, which works from a terminal too:

```sh
orka-settings get                          # all settings
orka-settings set .theme '"tokyo-night"'   # change one value and apply it
orka-settings set .idle.lockAfter 600
orka-settings apply                        # re-apply everything
orka-settings themes                       # installed themes (JSON)
orka-settings about                        # system information (JSON)
```

## Pages

| Page | What | Stored as | Applied by |
|---|---|---|---|
| Theme | Pick a theme (color swatches, light/dark) | `.theme` | `current/theme.json`, `current/ghostty.conf`, `current/hyprland.lua`, `hyprctl reload`, Ghostty reload (SIGUSR2), GTK `color-scheme` |
| Wallpaper | Theme default (its wallpaper or background color), or an image from your folder | `.wallpaper` (path, `""` = theme default) | `orka-wallpaper` (swaybg) |
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

Both pages have an "Open … folder" button.

## Themes

Built in (all work offline, also in Ghostty and Neovim): **Orka** (the placeholder colors, the default), **Tokyo Night**, **Catppuccin Mocha**, **Catppuccin Latte** (light).

A theme reaches:

| App | How | When |
|---|---|---|
| The shell (bar, notifications, launcher, lock and login...) | `Theme.qml` watches `~/.config/orka/current/theme.json` | At once |
| Hyprland borders | `orka/theme.lua` ← `orka/settings.lua` ← `current/hyprland.lua` | At once (`hyprctl reload`) |
| Ghostty | `config-file = ?"~/.config/orka/current/ghostty.conf"` in your Ghostty config: a built-in Ghostty theme by name, or the theme's own `ghostty.conf` | At once (SIGUSR2) |
| tmux | Uses the terminal's colors (named colors only) | With Ghostty |
| Neovim | `plugins/orka.lua` reads `"neovim"` from `current/theme.json` | At start, and in a running Neovim when it gets focus |
| GTK / Firefox (portal) | `gsettings set org.gnome.desktop.interface color-scheme prefer-dark/light` | At once (apps that follow it) |
| Wallpaper | The theme's `wallpaper` image, or its background color, when the wallpaper is "Theme default" | At once |

Not themed yet: Qt apps (Dolphin, KDE Connect: Kvantum is installed but not configured), the icon theme, btop. Part of the theme roadmap item.

## How Hyprland gets the values

`orka-settings` writes `~/.config/orka/current/hyprland.lua` (generated, rewritten on each change) and runs `hyprctl reload`. `orka/settings.lua` loads that file; `orka/theme.lua` takes the colors, and `orka/init.lua` applies the monitors and keyboard after the other OrkaOS defaults. Your own `~/.config/hypr/*.lua` are loaded after that, so a setting there (e.g. `kb_layout` in `input.lua`) wins over the settings app.

The login screen doesn't use these settings (it runs before you log in, as another user).

## Tested

2026-11-06 in the VM, from a fresh install, by clicking (QEMU's QMP `input-send-event`, now enabled in `iso/test/vm.sh`): all eight pages show real data (26 display modes of the virtual monitor, the sound devices, 100 keyboard layouts, system information); choosing Tokyo Night recolors the shell, the Hyprland borders and Ghostty at once; a wallpaper from `~/Pictures/Wallpapers` is applied; 1024×768 is applied and, without pressing Keep, goes back to 1280×800 after 15 s; the night light turns on; searching "roman" and Enter adds the Romanian layout (`hyprctl getoption input:kb_layout` → `us,ro`). Not yet tried: the Idle & lock choices by click (same mechanism; the VM's screen had just changed size), Sound device switching (the VM has one device each way), the scale choices, several monitors, Neovim following a theme change, a theme of your own.

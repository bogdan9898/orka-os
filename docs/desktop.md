# Desktop (Hyprland)

Hyprland **0.57** is configured in **Lua** (`hyprland.lua`); the old `hyprland.conf` format is gone ("RIP hyprlang"), so Omarchy v3.8.4's `.conf` files were ported, not copied. API reference: `/usr/share/hypr/stubs/hl.meta.lua` and https://wiki.hypr.land/configuring/.

## Layout

| Where (installed) | From the repo | What |
|---|---|---|
| `/usr/share/orka/hypr/orka/` | `config/hypr/orka/` | OrkaOS defaults. Replaced on updates; don't edit |
| `~/.config/hypr/hyprland.lua` | `config/user/hypr/` | Your config: loads the defaults (`require("orka")`), then your files |
| `~/.config/hypr/{monitors,input,looknfeel,bindings,autostart}.lua` | `config/user/hypr/` | Your overrides (loaded last, so they win) |
| `~/.config/hypr/hypridle.conf` | `config/user/hypr/` | Idle: screen off after 10 min (no lock screen yet) |
| `/usr/local/bin/orka-*` | `bin/` | Helper commands used by the bindings |

`orka-setup-user` seeds the user files and never overwrites them: if a default changed, the new version is written next to yours as `*.orka-new`.

Default apps (terminal, browser, ...) are in `orka/apps.lua`; override them with `ORKA_APPS = { browser = "chromium" }` at the top of `~/.config/hypr/hyprland.lua`.

**Session start:** log in on **tty1** and Hyprland starts (`uwsm start hyprland.desktop`, from `~/.bash_profile`). Other consoles (Ctrl+Alt+F2...) stay plain shells.

**Check a config change** without restarting: `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`. In the repo: `iso/test/verify-hypr.sh`.

## Not there yet (planned Quickshell components)

The bar, notifications and the polkit agent (admin password dialog) are done ([quickshell](quickshell.md#the-bar)). Not there yet: launcher, volume OSD, lock screen or login screen. Stand-ins: `SUPER + SPACE` opens Hyprland's run dialog (`hyprland-run`); `SUPER + K` lists all bindings.

## Key bindings

Based on Omarchy v3.8.4. `SUPER + K` shows the full list.

### Windows and workspaces

| Keys | Action |
|---|---|
| `SUPER + W` | Close window |
| `SUPER + T` | Toggle floating/tiling |
| `SUPER + F` / `SUPER + ALT + F` | Full screen / full width |
| `SUPER + J` / `SUPER + P` | Toggle split / pseudo-tile |
| `SUPER + O` | Pin floating window |
| `SUPER + arrows` | Focus window |
| `SUPER + SHIFT + arrows` | Swap window |
| `SUPER + 1..0` | Go to workspace 1..10 |
| `SUPER + SHIFT + 1..0` | Move window to workspace (and follow) |
| `SUPER + SHIFT + ALT + 1..0` | Move window to workspace (stay) |
| `SUPER + TAB` / `SUPER + SHIFT + TAB` / `SUPER + CTRL + TAB` | Next / previous / former workspace |
| `SUPER + S` / `SUPER + ALT + S` | Scratchpad / move window there |
| `SUPER + -` / `SUPER + =` (+ `SHIFT`) | Resize width (height) |
| `SUPER + drag` (left / right mouse) | Move / resize |
| `ALT + TAB` / `ALT + SHIFT + TAB` | Next / previous window |
| `CTRL + ALT + TAB` | Next monitor |
| `SUPER + SHIFT + ALT + arrows` | Move workspace to monitor |
| `SUPER + G`, `SUPER + ALT + G`, `SUPER + ALT + arrows`, `SUPER + ALT + TAB` | Groups (tabs): toggle, leave, join, next |

### Apps

| Keys | App |
|---|---|
| `SUPER + RETURN` / `SUPER + ALT + RETURN` | Ghostty / Ghostty with tmux |
| `SUPER + SHIFT + RETURN`, `SUPER + SHIFT + B` | Firefox (`+ ALT`: private) |
| `SUPER + SHIFT + F` | Dolphin |
| `SUPER + SHIFT + Y` | Yazi |
| `SUPER + SHIFT + N` / `SUPER + SHIFT + S` | Neovim / Sublime Text |
| `SUPER + SHIFT + O` | LibreOffice |
| `SUPER + SHIFT + D` / `SUPER + SHIFT + G` | lazydocker / lazygit |
| `SUPER + CTRL + T / A / B / W` | btop / audio (wiremix) / Bluetooth (bluetui) / Wi-Fi (impala) |

### Utilities

| Keys | Action |
|---|---|
| `SUPER + SPACE` | Run a program (stand-in launcher) |
| `SUPER + K` | Search key bindings |
| `SUPER + ,` / `SUPER + SHIFT + ,` | Dismiss last / all notifications |
| `SUPER + ALT + ,` / `SUPER + SHIFT + ALT + ,` | Invoke last notification / bring back the last one that disappeared |
| `SUPER + CTRL + ,` | Do not disturb (only critical notifications pop up) |
| `SUPER + C / V / X` | Copy / paste / cut (works in terminals too) |
| `PRINT` / `SHIFT + PRINT` | Screenshot region / screen (edit in satty) |
| `SUPER + CTRL + PRINT` | Copy text from a screen region (OCR) |
| `ALT + PRINT` | Start/stop screen recording |
| `SUPER + PRINT` | Color picker |
| `SUPER + CTRL + N` | Night light |
| `SUPER + CTRL + Z` / `SUPER + CTRL + ALT + Z` | Zoom / reset |
| Media keys | Volume, mute, play/pause, next/previous |
| `SUPER + CTRL + ALT + ESCAPE` | Log out |

## Tested

In the QEMU test VM (2026-11-05): Hyprland starts on tty1 login with this config (no config errors), `SUPER + RETURN` (Ghostty, tiled), `SUPER + K` (floating key list), silent move (`SUPER + SHIFT + ALT + 2`), previous window (`ALT + SHIFT + TAB`), wallpaper. Not yet tried on real hardware: FreeSync/`highrr`, screenshots and recording, media keys, KDE Connect.

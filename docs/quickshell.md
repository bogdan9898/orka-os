# Quickshell

[Quickshell](https://quickshell.org) is a toolkit for building your own desktop shell (bars, widgets, launchers, notifications, lock screens) on Wayland, using QtQuick/QML. Omarchy's entire v4 desktop is built with it, and it's the long-term plan for OrkaOS's desktop.

## What it can build

| Component | How | Replaces |
|---|---|---|
| Status bars, docks, panels | `PanelWindow`: windows anchored to screen edges, which reserve space | Waybar |
| Widgets (clock, CPU, weather…) | Any QML element; `Quickshell.Io` runs commands, reads files, watches processes | |
| Lock screen | `WlSessionLock` (a real Wayland session lock) + `Pam` for password checks | Hyprlock |
| Notifications | `NotificationServer` | Mako / Dunst |
| App launcher | `DesktopEntries` lists apps; we build the search UI | Walker / Fuzzel |
| System tray | `SystemTray` | |
| Volume / media | `Pipewire` (audio), `Mpris` (players) | |
| Wi-Fi / Bluetooth | `Networking`, `Bluetooth` modules | |
| Workspaces / windows | `Quickshell.Hyprland`: live state and IPC | |
| Admin password prompts | `Polkit` | polkit-gnome etc. |
| OSD, power menu, battery | Plain windows + `UPower` | SwayOSD, wlogout |

Omarchy's `shell/` uses all of these: 67 files import `Quickshell`, 21 `Quickshell.Wayland`, 12 `Quickshell.Hyprland`, plus Pipewire, UPower, Mpris, SystemTray, Polkit, Pam, Notifications, Networking and Bluetooth.

## Why it's nice

- **QML + JavaScript:** real animations, transparency and any layout, with far more freedom than Waybar's config-and-CSS approach.
- **Hot reload:** save a file and the shell updates instantly.
- **One process for everything:** the bar, launcher, notifications, lock screen and OSD share the same theme, colors and state.

## Trade-offs

- **It's a programming project, not a config file.** A good bar is a weekend. A full shell is much more (Omarchy's is 283 files).
- **It's pre-1.0, so updates can break things.** Pin a version (Omarchy pins a specific commit) and update deliberately.
- **We handle the edge cases ourselves:** multiple monitors, the lock screen failing safely, notification actions.

## Plan for OrkaOS

No stock desktop tools: Waybar, Mako, SwayOSD, Hyprlock, Walker and SDDM are **not** installed. Every piece is our own Quickshell code, built over time. Until a piece exists, the TTY covers it (log in on the console, start Hyprland with `uwsm start hyprland`).

1. `quickshell` (Arch `extra`, 0.3.2) is in the base package list. Our shell lives in this repo under `shell/`, is installed to `/usr/share/orka/shell/` and started from Hyprland (`qs -p /usr/share/orka/shell`, in `orka/autostart.lua`).
2. Build components one at a time: **bar (done, see below) → notifications → polkit agent → launcher → OSD → lock screen**. The lock screen comes late because a broken lock screen is a security problem; until then, there is no screen lock.
3. Last: a login greeter via greetd (`Quickshell.Services.Greetd`) to replace the TTY login.
4. The polkit agent (admin password dialog) is ours too, built on `Quickshell.Services.Polkit` (included in Arch's 0.3.2). `polkit-gnome` is not installed. Until our agent exists, GUI apps that need admin rights (mounting disks in Nautilus, GNOME Disks) can't ask for a password; in the terminal, `pkexec` and `sudo` still work.

## The bar

Layout taken from Omarchy v3.8.4's Waybar; the code is our own (Omarchy v4's Quickshell shell, a plugin system of 139 QML files, was only used to check API details).

| Where | What | Click | Right click / scroll |
|---|---|---|---|
| Left | Fish icon (placeholder for the Orka logo) | Run a program (`hyprland-run`, stand-in launcher) | Terminal |
| Left | Workspaces 1–5, plus others in use; active = filled square, empty = dimmed | Go to workspace | Scroll: previous / next |
| Center | Clock `Friday 14:05` | Toggle the date (`06 November W45 2026`) | |
| Center | Red dot while recording the screen | Stop recording | |
| Right | System tray (KDE Connect, ...) | App's action | Menu (middle click: secondary action) |
| Right | Bluetooth: off / on / connected (hidden without an adapter) | bluetui | |
| Right | Network: Wi-Fi signal / wired / offline | impala | |
| Right | Volume of the default output | wiremix | Right: mute; scroll: ±5% |
| Right | CPU | btop | |

Not in it (on purpose): battery (desktop), Omarchy's weather, update, dictation, idle and do-not-disturb indicators (no such features yet), tooltips (later).

Files (`shell/`): `shell.qml` (one bar per monitor), `Theme.qml` (colors, font, glyphs; placeholder until the Orka theme), `Apps.qml` (start programs via uwsm, like `orka/apps.lua`), `bar/*.qml` (one file per widget). Network state comes from `orka-netstatus`, because Quickshell's Networking module only supports NetworkManager and OrkaOS uses iwd + systemd-networkd.

**Tested** 2026-11-06 in the VM (installed from the ISO, Hyprland on tty1): the bar starts with Hyprland, windows tile below it, workspaces follow `SUPER + 1..5`, the clock shows, the network icon shows wired with internet and offline without, volume shows muted (the VM has no sound device), Bluetooth is hidden (no adapter). Shell log: no QML errors. Not yet tried: the tray (needs a tray app such as KDE Connect), clicks, volume scrolling, the recording dot, multiple monitors, real Wi-Fi.

**Working on it:** run a copy from the repo with `qs -p ~/dev/orka-os/shell` (stop the installed one first: `pkill -x qs` or `pkill quickshell`); saving a file reloads it. Logs: `qs log -p /usr/share/orka/shell` (or the repo path).

## References

- Omarchy's `shell/` folder (MIT): a complete real-world Quickshell desktop to study and borrow from
- Quickshell docs: https://quickshell.org

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

No stock desktop tools: Waybar, Mako, SwayOSD, Hyprlock, Walker and SDDM are **not** installed. Every piece is our own Quickshell code, built over time. The only stock piece is greetd (with the cage compositor), which runs our login screen.

1. `quickshell` (Arch `extra`, 0.3.2) is in the base package list. Our shell lives in this repo under `shell/`, is installed to `/usr/share/orka/shell/` and runs as the systemd user service `orka-shell.service` (`qs -p /usr/share/orka/shell`), started with the Hyprland session and restarted if it crashes.
2. Build components one at a time: **bar (done) → notifications (done) → polkit agent (done) → launcher (done) → lock screen (done) → cheat sheet (done) → OSD (done)**.
3. A login screen via greetd (`Quickshell.Services.Greetd`) instead of the TTY login: done, see [login screen](#login-screen).
4. The polkit agent (admin password dialog) is ours too, built on `Quickshell.Services.Polkit` (included in Arch's 0.3.2); `polkit-gnome` is not installed. Done, see [polkit agent](#polkit-agent).

## The bar

Layout taken from Omarchy v3.8.4's Waybar; the code is our own (Omarchy v4's Quickshell shell, a plugin system of 139 QML files, was only used to check API details).

| Where | What | Click | Right click / scroll |
|---|---|---|---|
| Left | Fish icon (placeholder for the Orka logo) | App launcher | Settings |
| Left | Workspaces 1–5, plus others in use; active = filled square, empty = dimmed | Go to workspace | Scroll: previous / next |
| Center | Clock `Friday 14:05` | Toggle the date (`06 November W45 2026`) | |
| Center | Red dot while recording the screen | Stop recording | |
| Right | System tray (KDE Connect, ...) | App's action | Menu (middle click: secondary action) |
| Right | Bluetooth: off / on / connected (hidden without an adapter) | bluetui | |
| Right | Network: Wi-Fi signal / wired / offline | impala | |
| Right | Volume of the default output | wiremix | Right: mute; scroll: ±5% |
| Right | CPU | btop | |
| Center | Bell with a slash while do not disturb is on | Turn it off | |

Not in it (on purpose): battery (desktop), Omarchy's weather, update, dictation and idle indicators (no such features yet), tooltips (later).

Files (`shell/`): `shell.qml` (one bar per monitor, the notification popups), `Notifications.qml` (the notification daemon), `notifications/` (popups), `polkit/` (the admin password dialog), `LauncherState.qml` + `launcher/` (the app launcher), `LockState.qml` + `lock/` (lock screen, idle), `Settings.qml` (`~/.config/orka/settings.json`), `greeter.qml` + `greeter/` (the login screen), `cheatsheet/` (keyboard shortcuts, SUPER + K), `osd/` (on-screen display), `SettingsState.qml` + `settings/` (the settings app, see [settings](settings.md)), `Theme.qml` (colors, font, glyphs; placeholder until the Orka theme), `Apps.qml` (start programs via uwsm, like `orka/apps.lua`), `bar/*.qml` (one file per widget). Network state comes from `orka-netstatus`, because Quickshell's Networking module only supports NetworkManager and OrkaOS uses iwd + systemd-networkd.

**Tested** 2026-11-06 in the VM (installed from the ISO, Hyprland on tty1): the bar starts with Hyprland, windows tile below it, workspaces follow `SUPER + 1..5`, the clock shows, the network icon shows wired with internet and offline without, volume shows muted (the VM has no sound device), Bluetooth is hidden (no adapter). Shell log: no QML errors. Not yet tried: the tray (needs a tray app such as KDE Connect), clicks, volume scrolling, the recording dot, multiple monitors, real Wi-Fi.

**Working on it:** run a copy from the repo with `qs -p ~/dev/orka-os/shell` (stop the installed one first: `systemctl --user stop orka-shell`, and start it again afterwards); saving a file reloads it. Logs: `qs log -p /usr/share/orka/shell` (or the repo path).

## Notifications

The shell is the notification daemon (`NotificationServer` in `Notifications.qml`); there is no mako. Behaviour follows Omarchy's mako setup:

- **Popups** top right under the bar, on the focused monitor, newest on top, at most 5 (older ones are hidden, not lost). Blue border, red for critical.
- **Timeout:** 5 seconds, or what the app asks for (`notify-send -t`). Critical notifications stay until dismissed. The mouse over a popup pauses all timeouts.
- **Click:** the app's default action (e.g. open the chat), then the popup closes; without one it just closes. **Right click:** dismiss. Other actions are shown as buttons.
- A popup that timed out isn't gone: the last 20 are kept, and `SUPER + SHIFT + ALT + ,` brings the latest back.
- **Do not disturb** (`SUPER + CTRL + ,`, bell icon in the bar): nothing pops up except critical notifications; the rest are kept for restoring.
- Shows the image an app sends, otherwise its icon; the body may use `<b>`, `<i>`, `<u>` and links.

| Keys | Command | Action |
|---|---|---|
| `SUPER + ,` | `orka-notifications dismiss` | Dismiss the newest |
| `SUPER + SHIFT + ,` | `orka-notifications dismiss-all` | Dismiss all shown |
| `SUPER + ALT + ,` | `orka-notifications invoke` | Run the newest one's default action |
| `SUPER + SHIFT + ALT + ,` | `orka-notifications restore` | Bring back the last one that disappeared |
| `SUPER + CTRL + ,` | `orka-notifications dnd` | Toggle do not disturb |
| | `orka-notifications status` | Prints `dnd=off shown=1 hidden=3` |

**Tested** 2026-11-06 in the VM with `notify-send`: popups stack newest first, critical (red) stays, action buttons, bold/italic body, app timeout (`-t 3000`) and the 5 s default, images and theme icons (a missing icon is left out), restore, do not disturb (bell in the bar, notification kept), `SUPER + ,` and `SUPER + SHIFT + ,`. Not yet tried: mouse clicks on popups (default action, right-click dismiss, hover pause), `SUPER + ALT + ,`, real apps (Firefox, KDE Connect).

`orka-notifications` calls the shell over IPC (`qs -p /usr/share/orka/shell ipc call notifications <function>`). Try it with `notify-send "Hello" "World"` (`libnotify`, now in the package list). Not yet: a notification center (history panel), sounds, inline replies.

## Polkit agent

When an app needs admin rights, polkit asks the session's agent for the password; ours is `polkit/PolkitDialog.qml` (`PolkitAgent` from `Quickshell.Services.Polkit`, D-Bus path `/org/orka/PolkitAgent`). Without an agent such requests simply fail: GParted wouldn't start from the desktop, Dolphin couldn't mount internal disks. `sudo` and `pkexec` in a terminal never needed it.

- A dialog in the middle of the focused monitor, the rest of the screen dimmed. It takes all keyboard input until answered.
- Shows what polkit says the app wants to do (e.g. "Authentication is needed to run `/usr/bin/true` as the super user") and the action ID (`org.freedesktop.policykit.exec`).
- **Enter** or *Authenticate*: check the password. **Escape** or *Cancel*: refuse (the app gets "Request dismissed").
- Wrong password: red border and "Wrong password, try again", the field is cleared, polkit asks again. Messages from PAM (e.g. account locked) are shown under the field.

**Tested** 2026-11-06 in the VM with `pkexec true` from Ghostty: dialog shown, wrong password rejected and asked again, right password accepted, Escape cancels; the log says `orka: polkit agent registered`. Not yet tried: a real GUI app (GParted, Dolphin), several monitors, a request arriving while another is open (polkit queues them).

## Launcher

`SUPER + SPACE` (or the fish button in the bar) opens `launcher/Launcher.qml`: a search box at the top of the focused monitor, listing the installed apps (`DesktopEntries`, hidden entries left out) with icon, name and description; apps that run in a terminal are marked "terminal". Replaces Omarchy's Walker and our `hyprland-run` stand-in.

| Keys | Action |
|---|---|
| type | Search |
| `↑` `↓`, `TAB` / `SHIFT + TAB`, `CTRL + J/K`, `CTRL + N/P` | Move the selection |
| `ENTER` / click | Start the app; with no matching app, run the text as a command (`sh -c`) |
| `ESCAPE` / click outside | Close |

- **Search order:** name starts with the text → a word in the name starts with it → the name contains it → its letters appear in order (`ffx` → Firefox) → generic name, keywords, description or ID contain it. Ties: more used first, then A–Z.
- **Most used first:** each start counts (up to 20 points, so a good name match still wins); with an empty search the most used apps are at the top. Counts live in `~/.local/state/orka/launcher.json`.
- **Starting:** `uwsm app -- <id>.desktop`, so apps get their own systemd scope like the key bindings. Terminal apps (btop, Neovim, yazi) open in Ghostty through `xdg-terminal-exec`, configured by the seeded `~/.config/xdg-terminals.list`.
- The mouse selects a row only once it has really moved: when the list opens under a resting pointer, Wayland reports that as motion too, and Enter would otherwise start whatever happens to be under the pointer.
- IPC target `launcher`: `qs -p /usr/share/orka/shell ipc call launcher toggle|open|close`.

**Tested** 2026-11-06 in the VM: app list with icons, search (`bto` → btop), letters in order (`ffx` → Firefox), Enter starts btop in Ghostty (terminal app), Escape closes, the count is saved, a typed command (`notify-send Launched`) runs. The resting-pointer case was a bug found in the test and fixed. Not yet tried: selecting with a moving mouse (QEMU's tablet can't be moved from the monitor), desktop actions (e.g. Firefox's "New private window"), several monitors.

## Lock screen

`lock/Lock.qml`: a real Wayland session lock (`WlSessionLock`, the ext-session-lock protocol) on every monitor, with a big clock, the date, the user and a password field. Enter checks the password with PAM (`/etc/pam.d/orka-lock`, which includes `login` like swaylock and hyprlock do), Escape clears it, a wrong password shows red and asks again. Notifications and other windows can't appear above it.

| Locks when | How |
|---|---|
| `SUPER + CTRL + L` | `orka-lock` (`qs -p /usr/share/orka/shell ipc call lock lock`) |
| Idle for `lockAfter` seconds (default 300) | `lock/Idle.qml` (`IdleMonitor`) |
| Before suspend | hypridle: `before_sleep_cmd = loginctl lock-session` → `lock_cmd = orka-lock`, and `inhibit_sleep = 3` waits until the lock is up |

There is deliberately no command or IPC call that unlocks: only the password does.

**If the shell crashes while locked**, the session stays locked: that's how ext-session-lock works (Hyprland shows its "lock screen crashed" screen instead of the desktop). systemd restarts the shell (`orka-shell.service`, `Restart=on-failure`), Hyprland lets the new shell take over the lock (`misc.allow_session_lock_restore`), and the shell locks again at once because it finds `$XDG_RUNTIME_DIR/orka-locked`. Last resort: switch to another console (`CTRL + ALT + F2`), log in, `systemctl --user restart orka-shell`.

**Wrong passwords:** the `login` PAM stack includes `pam_faillock`, so 3 wrong passwords in a row lock the account for 10 minutes (Arch's default, `/etc/security/faillock.conf`); the lock screen then shows PAM's message. Undo it from another console as root: `faillock --user <name> --reset`.

### Idle settings

The shell reads `~/.config/orka/settings.json` (`Settings.qml`) and watches it, so a change applies at once. A future settings app will write this file.

```json
{ "idle": { "lockAfter": 300, "screenOffAfter": 330 } }
```

Seconds without keyboard or mouse input until the screen locks / the monitors turn off (`0` = never). Apps that inhibit idle (a playing video) hold both off. Invalid JSON or missing values fall back to these defaults. hypridle no longer has idle timers; it only handles "lock before sleep".

## Login screen

At boot greetd shows our login screen on tty1: `greeter.qml` (a second entry point next to `shell.qml`, so it shares `Theme.qml` and the buttons), run as the `greeter` user inside **cage**, a kiosk compositor that shows one app full screen (`/etc/greetd/config.toml`: `cage -s -d -- qs -p /usr/share/orka/shell/greeter.qml`, with Qt's own title bar and crash dialog turned off).

- Clock, date, the user (the only normal user, UID 1000+; with several, TAB or the arrows switch), password field. Enter logs in; a wrong password shows red and asks again.
- After a login it starts `uwsm start -e -D Hyprland hyprland.desktop` (what Hyprland's own `hyprland-uwsm` session runs) and quits; cage exits with it and greetd starts the session.
- **Reboot** / **Shut down** buttons (`systemctl`, allowed for the active seat).
- KWallet is unlocked with the login password here too (`pam_kwallet5` in `/etc/pam.d/greetd`).
- `cage -s` keeps console switching on: `CTRL + ALT + F2` still gives a text login if the login screen breaks.

**Tested** 2026-11-06 in the VM (fresh install from the ISO): login screen shows at boot with the user filled in, a wrong password gives "Wrong password" and asks again, the right one starts Hyprland with the bar; `SUPER + CTRL + L` locks, wrong password is refused, right one unlocks; idle lock after `lockAfter` (set to 10 s by editing `settings.json` while running); a deliberate crash of the shell while locked (`pkill -SEGV`) brings the lock screen straight back. Bugs found and fixed in the test: a changed idle time had no effect (the monitor is now recreated), greetd's follow-up error replaced "Wrong password", a title bar on the login screen, Quickshell's crash-report dialog after the crash. Not yet tried: lock before suspend (the VM doesn't suspend), screen off after `screenOffAfter`, several monitors, Reboot / Shut down buttons, pam_faillock after 3 wrong passwords.

## Cheat sheet

`SUPER + K` opens `cheatsheet/CheatSheet.qml`: every keyboard shortcut on one screen, grouped by section in as many columns as fit. Type to filter (e.g. `tmux`, `SUPER + SHIFT`, `screenshot`), `↑` `↓` / `PAGE UP` `PAGE DOWN` to scroll, Escape clears the search and then closes, a click outside closes.

**Always up to date:** nothing is written down twice. Each time it opens, the sheet runs `orka-keys`, which reads the bindings as they are right now:

| Source | Read from | Sections |
|---|---|---|
| Hyprland (windows, workspaces, apps, notifications, screenshots, media, ...) | `hyprctl binds -j`: the live bindings, so a changed `bindings.lua` shows after Hyprland reloads it (it does on save) | From the description, `"Section: text"`, written by `orka/keys.lua`; without a section: "Your bindings" |
| tmux | The running tmux server's `list-keys -N`, or a short-lived server started with `~/.config/tmux/tmux.conf` when none runs | "tmux" (no prefix), "tmux: after CTRL + SPACE" (the prefix is read live too), "tmux: copy mode" |

Only bindings with a description are listed: in Hyprland that's the `description` option (all OrkaOS bindings have one), in tmux a note (`bind -N "..."`; tmux's own default keys have notes, ours were given one).

`orka-keys` also tidies the list: several keys for the same action become one row (`SUPER + TAB / SUPER + scroll down`), and rows that only differ in a number become a range (`SUPER + 1…0  Workspace 1…10`). Number-row, mouse and media keys get readable names. `orka-keys --tsv` prints it as text; `SUPER + SHIFT + K` (`orka-keybindings`) shows that list in a searchable terminal.

**Tested** 2026-11-06 in the VM: the sheet lists all sections with ranges and merged keys, search filters (`notif` → the 5 notification keys), a binding added to `~/.config/hypr/bindings.lua` appears in its own section after the reload, a tmux binding added to `~/.config/tmux/tmux.conf` appears in "tmux: after CTRL + SPACE". (An interrupted VM test once left a just-copied `orka/keys.lua` empty, which put Hyprland into emergency mode: an empty module makes `require` return `true`. Not a bug in the config, but worth knowing: if Hyprland reports "attempt to index a boolean value" in the bindings, check that file.)

## On-screen display

`osd/Osd.qml`, the SwayOSD replacement, adapted from Omarchy v4's Quickshell OSD (`shell/plugins/osd`, MIT): a small card at the bottom of the focused monitor with an icon and either a bar with a value or a message. It never takes clicks or keys (empty input region) and hides 1.2 s after the last change.

| Shows | When | How |
|---|---|---|
| Volume (icon by level, bar, `45%`) / "Muted" | Any change of the default output: volume keys, scrolling on the bar's volume icon, a mixer | Watches Pipewire's default sink; quiet for 1.5 s at startup and after the output device changes, so those don't flash it |
| "Microphone on" / "Microphone off" | Muting the default input (`XF86AudioMicMute`) | Watches the default source |
| Play / pause icon with "Title — Artist" | Media keys | The bindings run `playerctl ...; orka-osd media`; the OSD reads the playing (or first) MPRIS player |
| "Caps Lock on/off", "Num Lock on/off" | Pressing Caps Lock or Num Lock (with any modifiers) | Hyprland sends no event for lock keys, so pass-through bindings (`non_consuming`, no description, so not in the cheat sheet) run `orka-osd keylock caps|num`; the OSD then reads the main keyboard's state from `hyprctl devices -j` |
| Any message, optionally with a bar | Scripts | `orka-osd <icon> <message> [0-100]`; used by `orka-nightlight` ("Night light on/off") |

Icons for scripts: `volume muted mic mic-off play pause media night lock info`, or any Nerd Font glyph. IPC target `osd`: `display <icon> <message> <value|none>`, `media`, `hide`. (The function is not called `show`: `qs ipc` reads that as its own `show` command.)

No brightness: the target machine is a desktop with external monitors and no brightness keys. External monitor brightness would need DDC/CI (`ddcutil`); the OSD can show it with `orka-osd info Brightness 70` once something sets it.

**Tested** 2026-11-06 in the VM (now with a silent virtual sound card, `iso/test/vm.sh`): volume up/down and mute keys, microphone mute, Caps Lock and Num Lock on/off (the keys keep working: typed text came out in capitals), "No media player" for the play key without a player, `orka-osd` messages with and without a bar. Not yet tried: a real player's track info, the bar's volume scroll, several monitors.

## References

- Omarchy's `shell/` folder (MIT): a complete real-world Quickshell desktop to study and borrow from
- Quickshell docs: https://quickshell.org

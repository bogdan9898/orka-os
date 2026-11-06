# Shell and terminal

Bash with a starship prompt, Ghostty as the terminal, tmux for sessions, and a git config. Ported from Omarchy v3.8.4 (MIT), minus the parts for tools we don't ship (mise, opencode/codex aliases, the `omarchy` command completion, Kitty image previews, transcoding helpers).

## Layout

Same idea as the [Hyprland config](desktop.md#layout): OrkaOS defaults in `/usr/share/orka/` (replaced on updates), plus your own files that load them first and then your settings.

| Where (installed) | From the repo | What |
|---|---|---|
| `/usr/share/orka/bash/` | `config/bash/` | Defaults: `envs`, `shell` (history, completion), `aliases`, `functions`, `init` (starship, zoxide, fzf), `inputrc` |
| `~/.bashrc` | `config/user/bash/bashrc` | Sources `/usr/share/orka/bash/rc`, then your settings |
| `~/.config/starship.toml` | `config/user/starship.toml` | Prompt: directory, git branch and status |
| `~/.config/ghostty/config` | `config/user/ghostty/config` | Font (JetBrainsMono Nerd Font 9), padding, keys |
| `/usr/share/orka/tmux/tmux.conf` | `config/tmux/tmux.conf` | tmux defaults |
| `~/.config/tmux/tmux.conf` | `config/user/tmux/tmux.conf` | Sources the defaults, then your settings |
| `/usr/share/orka/git/config` | `config/git/config` | git defaults (see [git](#git)) |
| `~/.config/git/config` | `config/user/git/config` | Includes the defaults, then your settings (name, email). A `~/.gitconfig` also works and wins over both |

`orka-setup-user` seeds the user files without overwriting your changes (new defaults land next to them as `*.orka-new`). The one exception is `~/.bashrc`: Arch's stock version from `/etc/skel` is replaced; one you have edited is kept.

Starship and Ghostty can't load a defaults file *before* the user's file (Ghostty's `config-file` loads after the file it's in, so it would override you), so those two are seeded as complete files.

## Commands

| Command | What |
|---|---|
| `ls`, `lsa`, `lt`, `lta` | eza: long list with icons, `+ hidden`, tree (2 levels, with git status), `+ hidden` |
| `cd <dir>` | Normal `cd` for a real directory; otherwise a zoxide jump (`cd orka` → most used directory matching "orka") |
| `z`, `zi` | zoxide jump / interactive pick |
| `ff`, `eff` | Find a file with fzf and a bat preview / open it in `$EDITOR` |
| `CTRL + R`, `CTRL + T`, `ALT + C` | fzf: history search, insert a file path, cd into a directory |
| `↑` / `↓` | History search for what you've typed so far |
| `TAB` / `SHIFT + TAB` | Cycle through completions (case-insensitive) |
| `..`, `...`, `....` | Up 1 / 2 / 3 directories |
| `n [file]` | Neovim (current directory if no file) |
| `g`, `gcm`, `gcam`, `gcad`, `lg` | git, commit -m, commit -a -m, commit -a --amend, lazygit |
| `d`, `t` | docker, tmux (attach, or new session "Work") |
| `open <file>` | Open with its default app |
| `compress <dir>`, `decompress <file>` | tar.gz |
| `iso2sd <iso> [device]` | Write an ISO to a USB stick (picks from USB drives, asks first) |
| `format-drive <device> <label>` | Erase a drive into one exFAT partition (asks first) |
| `fip <host> <ports>`, `dip <ports>`, `lip` | SSH port forwards: start, stop, list |
| `ga <branch>`, `gd` | Git worktree `../<repo>--<branch>` on a new branch / remove it and the branch |

`EDITOR` is `nvim` (for git, `sudoedit` and so on); man pages are colored with bat.

## Ghostty

Default colors for now (the Orka theme is a roadmap TODO). `SHIFT + INSERT` / `CTRL + INSERT` paste and copy; `SUPER + C / V` work too, via Hyprland. `SHIFT + ENTER` is sent as CSI-u so TUIs (and Claude Code) can tell it from `ENTER`. Check the file with `ghostty +validate-config`.

## tmux

Prefix is `CTRL + SPACE` (`CTRL + B` also works). Status bar on top, mouse on, windows numbered from 1, vi copy mode (`v` select, `y` copy). Reload: prefix + `q`.

| Keys | Action |
|---|---|
| `ALT + RETURN` / `ALT + SHIFT + RETURN` | Split below / to the right |
| `ALT + ESCAPE` | Close pane |
| `CTRL + ALT + arrows` (`+ SHIFT`) | Focus pane (resize) |
| `ALT + 1..9`, `ALT + ←/→` (`+ SHIFT`) | Go to window, previous/next (move window) |
| `ALT + ↑/↓` | Previous / next session |
| prefix + `c` / `k` / `r` | New / kill / rename window |
| prefix + `C` / `K` / `R` | New / kill / rename session |
| prefix + `h` / `v` / `x` | Split below / right, kill pane |

## git

Omarchy's git config, unchanged:

| Setting | Effect |
|---|---|
| aliases `co`, `br`, `ci`, `st` | `git st` = `git status`, ... |
| `init.defaultBranch = master` | New repos start on `master` |
| `pull.rebase = true` | `git pull` rebases your local commits instead of merging |
| `push.autoSetupRemote = true` | First push of a new branch needs no `--set-upstream` |
| `diff.algorithm = histogram`, `colorMoved`, `mnemonicPrefix` | Clearer diffs; moved lines in their own color |
| `commit.verbose = true` | The diff is shown below the commit message in the editor |
| `column.ui = auto`, `branch.sort = -committerdate`, `tag.sort = -version:refname` | Branches in columns, most recent first; tags in version order |
| `rerere.enabled`, `rerere.autoupdate` | Remember and reuse merge-conflict resolutions |

Shell aliases on top: `g` (git), `gcm` (commit -m), `gcam` (commit -a -m), `gcad` (commit -a --amend), `lg` (lazygit).

## Tested

2026-11-06 in a throwaway home in the `archlinux` WSL distro: seeding by `orka-setup-user` (stock `.bashrc` replaced), interactive bash loads with no errors (eza, zoxide `cd`, starship, fzf keys, `EDITOR=nvim`), tmux config loads, `ghostty +validate-config` passes, shellcheck clean. The automated VM install test checks the same (self-test lines `bashrc`, `tmux`, `ghostty config`, `git`). git config include checked the same way.

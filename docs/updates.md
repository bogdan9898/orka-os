# Updates

OrkaOS itself (the desktop shell, configs, themes, `orka-*` commands, services, branding) is one pacman package, **`orka`**, published in our own package repository. So an installed system updates with the usual command, together with Arch:

```bash
sudo pacman -Syu
```

No reinstall, and no ISO involved: the ISO is only for installing. If an update goes wrong, boot the snapshot from before it in the Limine menu (Snapper takes one before and after every pacman transaction).

## How it fits together

| Part | Where |
|---|---|
| The package recipe | `pkg/PKGBUILD` (version `1.0.r<number of commits>`), install script `pkg/orka.install` |
| What goes where | `pkg/stage.sh`: `/usr/share/orka/*`, `/usr/bin/orka-*`, `system/` (services in `/usr/lib/systemd`, network defaults, zram, PAM, app entries), branding, boot screen |
| The repository | The GitHub release **`repo`** of this repository: `orka.db`, `orka.files` and the newest `orka-*.pkg.tar.zst`, each with a `.sig`. Only the newest version is kept |
| On the system | `[orka]` in `/etc/pacman.conf` (`SigLevel = Required`, `Server = https://github.com/bogdan9898/orka-os/releases/download/repo`) and the OrkaOS signing key in pacman's keyring |
| Signing key | `OrkaOS packages`, ed25519, fingerprint `3A6BF9C31940B07E97F1360C0E8E7A18FDF5DD2C`. Public part: `pkg/orka-packages.asc`. Private part: the build user's GnuPG keyring in the `archlinux` WSL distro, no passphrase (so releases can be scripted) |

Your own files are never touched by an update: the package only owns system files. Your dotfiles in `~/.config` were seeded once by `orka-setup-user`; when a default changes, run `orka-setup-user` and it writes the new version next to yours as `*.orka-new`. The three files in `/etc` that the package owns (`/etc/iwd/main.conf`, `/etc/pam.d/orka-lock`, `/etc/xdg/fastfetch/config.jsonc`) are marked as config files: if you edited one, pacman keeps yours and saves the new one as `.pacnew`.

Hyprland and the Quickshell shell notice changed files and reload them by themselves; if something looks off after an update, log out and back in.

**Not in the package** (the installer writes them once; an update doesn't change them): greetd's config (the login screen command), the mirrorlist, Plymouth's and mkinitcpio's config, the boot menu (`/boot/limine.conf` and its wallpaper on the ESP), os-release's first copy (afterwards the package's hook keeps it), `/etc/issue`, hostname, users. A change to the boot screen theme takes effect with the next initramfs build (kernel update, or `sudo limine-update`).

The AUR packages (yay, limine helpers, claude-code, sublime-text-4, cursors) are not in this repository: update them with `yay`.

## Connecting a system

New installs are connected by the installer. A system installed **before 2026-11-08** (files copied by the installer, no `orka` package) needs this once:

```bash
curl -fsSLO https://raw.githubusercontent.com/bogdan9898/orka-os/master/pkg/join-repo.sh
sudo bash join-repo.sh
```

It downloads the public key and checks its fingerprint, trusts it in pacman's keyring, adds `[orka]` to `/etc/pacman.conf` and installs the `orka` package. Because the installer had copied the same files, it installs with `--overwrite '*'` (only for that one package), and the package's install script moves the old copies out of the way: `orka-*` commands from `/usr/local/bin` (now `/usr/bin`), our units from `/etc/systemd/system` (now `/usr/lib/systemd/system`, kept enabled as they were), and the unchanged network, resolved, zram, greetd and pacman-hook files from `/etc` (an `/etc` file would override the packaged one). Files you edited stay. Then run `sudo pacman -Syu` once.

## Publishing an update

After committing (and pushing) a change, in the `archlinux` WSL distro as the build user:

```bash
GH_TOKEN="$(gh auth token)" bash pkg/release.sh     # gh token from Windows, or `gh auth login` in WSL once
```

`pkg/release.sh` refuses uncommitted changes, builds the package (`pkg/build.sh`), signs it and a fresh repository database, uploads them to the `repo` release (creating it the first time) and removes the older package files. The version comes from the number of commits, so every release needs at least one new commit. Needs `github-cli` in WSL.

To build the package without publishing: `bash pkg/build.sh [outdir]`. `iso/build.sh iso` builds it too and puts it into the ISO's offline repository, so a fresh install starts with the same files.

## The signing key

Without the private key no new version can be published (and making a new key means every system has to trust it again, by re-running `join-repo.sh`). **Back it up** somewhere safe outside WSL, for example a password manager:

```bash
gpg --export-secret-keys --armor 3A6BF9C31940B07E97F1360C0E8E7A18FDF5DD2C > orka-signing-key.asc
```

Restore with `gpg --import orka-signing-key.asc`. Never commit it.

## Tests

Tested in the QEMU VM (2026-11-08): an install from the old ISO (files copied, no package) joined a local signed copy of the repository with `join-repo.sh`, got the package, kept its services enabled, then upgraded to a newer version and rebooted into a working desktop. A fresh install from the new ISO has the package from the start and the repository configured (self-test line `orka package:`).

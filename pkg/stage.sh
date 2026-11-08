#!/usr/bin/env bash
# Lay out every file of the "orka" package under DESTDIR, as it ends up on
# the installed system. Used by pkg/PKGBUILD (package()).
#
#   pkg/stage.sh DESTDIR
#
# What is NOT in the package (the installer writes it once, see
# installer/orka-install): files owned by other packages or specific to the
# machine: greetd's config, the mirrorlist, Plymouth's and mkinitcpio's
# config, the boot menu (/boot), os-release, /etc/issue, hostname, users.
set -euo pipefail

R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="${1:?usage: stage.sh DESTDIR}"
S="$D/usr/share/orka"

# Copy a directory tree with clean modes (files on a Windows drive all look
# 0777 under WSL): dirs 755, files 644, plus *.py/*.sh executable as in git.
copy_tree() {   # copy_tree <from> <to>
  local from="$1" to="$2" f rel
  install -d -m755 "$to"
  while IFS= read -r -d '' f; do
    rel="${f#"$from"/}"
    if [[ -d "$f" ]]; then
      install -d -m755 "$to/$rel"
    else
      install -D -m"$(git_mode "$f")" "$f" "$to/$rel"
    fi
  done < <(find "$from" -mindepth 1 \( -name __pycache__ -o -name '*.pyc' -o -name '*.orka-new' \) -prune -o -print0)
}

# 755 for files git tracks as executable, else 644 (untracked files: 644).
git_mode() {
  local m
  m="$(git -C "$R" ls-files -s -- "${1#"$R"/}" 2>/dev/null | cut -d' ' -f1)"
  [[ "$m" == 100755 ]] && echo 755 || echo 644
}

# Defaults for Hyprland, bash, tmux and git; the files seeded into a new
# user's home (orka-setup-user); the shell, themes and our apps.
for d in hypr bash tmux git; do copy_tree "$R/config/$d" "$S/$d"; done
copy_tree "$R/config/user" "$S/user"
for d in shell themes apps; do copy_tree "$R/$d" "$S/$d"; done

# Commands.
for f in "$R"/bin/orka-*; do install -Dm755 "$f" "$D/usr/bin/${f##*/}"; done

# Branding: logo files, os-release (put back by the pacman hook), fastfetch,
# app icon, boot screen, wallpapers.
install -d -m755 "$S/branding/fastfetch" "$S/wallpapers"
install -m644 "$R"/branding/logo/orkaos-*.svg "$R/branding/os-release" "$S/branding/"
install -m644 "$R/branding/fastfetch/orkaos.png" "$R/branding/fastfetch/orkaos.txt" "$S/branding/fastfetch/"
install -Dm644 "$R/branding/fastfetch/config.jsonc" "$D/etc/xdg/fastfetch/config.jsonc"
install -Dm644 "$R/branding/logo/orkaos-badge.svg" "$D/usr/share/icons/hicolor/scalable/apps/orkaos.svg"
install -d -m755 "$D/usr/share/plymouth/themes/orka"
install -m644 "$R"/branding/plymouth/orka/* "$D/usr/share/plymouth/themes/orka/"
install -m644 "$R"/branding/wallpapers/*.jpg "$R"/branding/wallpapers/*.png "$S/wallpapers/"
install -m644 "$R/branding/limine/wallpaper.jpg" "$S/wallpapers/deep-water-rays.jpg"

# System files (services, network defaults, zram, pacman hook, PAM, iwd,
# app entries): system/ mirrors their place on the system.
copy_tree "$R/system" "$D"

install -Dm644 "$R/LICENSE" "$D/usr/share/licenses/orka/LICENSE"

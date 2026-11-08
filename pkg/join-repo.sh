#!/usr/bin/env bash
# Connect an OrkaOS system to the OrkaOS package repository (a GitHub release),
# so `sudo pacman -Syu` also updates OrkaOS itself (the "orka" package).
#
#   sudo bash join-repo.sh               trust the signing key, add [orka] to
#                                        /etc/pacman.conf, install the orka package
#   sudo bash join-repo.sh --setup-only  key + pacman.conf only (used by the installer)
#   sudo bash join-repo.sh --noconfirm   don't ask before installing
# ORKA_REPO_SERVER=URL replaces the GitHub address (tests with a local server).
#
# Systems installed before OrkaOS was packaged (up to 2026-11-08) need this
# once: the package then takes over the files the installer had copied
# (--overwrite), and its install script moves the old copies out of the way.
# Run it from a checkout, or download it and it fetches the key itself:
#   curl -fsSLO https://raw.githubusercontent.com/bogdan9898/orka-os/master/pkg/join-repo.sh
#   sudo bash join-repo.sh
set -euo pipefail

FPR=3A6BF9C31940B07E97F1360C0E8E7A18FDF5DD2C   # OrkaOS packages signing key
SERVER="${ORKA_REPO_SERVER:-https://github.com/bogdan9898/orka-os/releases/download/repo}"
KEY_URL=https://raw.githubusercontent.com/bogdan9898/orka-os/master/pkg/orka-packages.asc

die() { echo "join-repo: $*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die "run as root (sudo bash $0)"
setup_only=0 confirm=()
for a in "$@"; do
  case "$a" in
    --setup-only) setup_only=1 ;;
    --noconfirm) confirm=(--noconfirm) ;;
    *) die "unknown option: $a" ;;
  esac
done

# The public key: next to this script, or from GitHub.
key="$(dirname "$(readlink -f "$0")")/orka-packages.asc"
if [[ ! -f "$key" ]]; then
  key="$(mktemp)"
  curl -fsSL "$KEY_URL" -o "$key" || die "could not download the signing key"
fi
got="$(gpg --show-keys --with-colons "$key" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')"
[[ "$got" == "$FPR" ]] || die "the key file has fingerprint '$got', expected $FPR"

if ! pacman-key --list-keys "$FPR" >/dev/null 2>&1; then
  pacman-key --add "$key" >/dev/null
fi
pacman-key --lsign-key "$FPR" >/dev/null 2>&1 || die "could not trust the signing key"
echo "Signing key trusted: $FPR"

if ! grep -q '^\[orka\]' /etc/pacman.conf; then
  cat >>/etc/pacman.conf <<EOF

# OrkaOS: the orka package (desktop, configs, tools), signed with the OrkaOS key.
[orka]
SigLevel = Required
Server = $SERVER
EOF
  echo "Added [orka] to /etc/pacman.conf"
fi

# An offline install leaves the ISO's own repository database behind under
# the same name (sync/orka.db: unsigned, listing every package of the ISO).
# With [orka] now pointing to GitHub it would be wrong; the next sync
# downloads the real one.
rm -f /var/lib/pacman/sync/orka.db /var/lib/pacman/sync/orka.db.sig \
      /var/lib/pacman/sync/orka.files /var/lib/pacman/sync/orka.files.sig

((setup_only)) && exit 0

pacman -Sy
if pacman -Q orka >/dev/null 2>&1; then
  echo "The orka package is already installed: update with sudo pacman -Syu"
else
  # First time: take over the files the installer had copied.
  pacman -S "${confirm[@]}" --overwrite '*' orka
  echo "Done. From now on, sudo pacman -Syu updates OrkaOS together with Arch."
fi

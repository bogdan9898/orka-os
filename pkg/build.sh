#!/usr/bin/env bash
# Build the "orka" package from this repository (working tree as it is).
#
#   pkg/build.sh [OUTDIR]     (default OUTDIR: ~/orka-build/orka-pkg)
#
# Run as a normal user on Arch (OrkaOS, or the archlinux WSL distro). Prints the
# path of the built package. Needs base-devel and git.
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$HOME/orka-build/orka-pkg}"
[[ $EUID -ne 0 ]] || { echo "pkg/build.sh: run as a normal user, not root" >&2; exit 1; }

W="$(mktemp -d /tmp/orka-pkg-XXXX)"
trap 'rm -rf "$W"' EXIT
cp "$R/pkg/PKGBUILD" "$R/pkg/orka.install" "$W/"
mkdir -p "$OUT"

# Builds in /tmp (not on the Windows drive), without makepkg's debug package.
sed -E 's/^(OPTIONS=.*[( ])debug/\1!debug/' /etc/makepkg.conf > "$W/makepkg.conf"
(cd "$W" && ORKA_SRC="$R" BUILDDIR="$W/build" PKGDEST="$OUT" \
  makepkg --config "$W/makepkg.conf" -f --nodeps --noconfirm >"$W/makepkg.log" 2>&1) ||
  { tail -20 "$W/makepkg.log" >&2; exit 1; }
(cd "$W" && ORKA_SRC="$R" PKGDEST="$OUT" makepkg --config "$W/makepkg.conf" --packagelist)

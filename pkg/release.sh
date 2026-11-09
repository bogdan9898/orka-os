#!/usr/bin/env bash
# Publish a new version of the "orka" package to the OrkaOS package
# repository: the GitHub release "repo" of bogdan9898/orka-os, which
# installed systems use as a pacman repository ([orka] in pacman.conf).
#
#   GH_TOKEN=... pkg/release.sh        (WSL / Arch, as the build user)
#
# Builds the package from the committed state (refuses uncommitted changes),
# signs it and a fresh repository database with the OrkaOS key, uploads them
# and deletes older package files from the release. The repository only ever
# holds the newest version. Needs: base-devel, git, github-cli (gh) logged in
# or GH_TOKEN set (from Windows: GH_TOKEN="$(gh auth token)"), and the
# signing key in the build user's GnuPG keyring.
set -euo pipefail
export LC_ALL=C.UTF-8
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FPR=3A6BF9C31940B07E97F1360C0E8E7A18FDF5DD2C
GH_REPO=bogdan9898/orka-os
TAG=repo
export GH_REPO

die() { echo "release: $*" >&2; exit 1; }
[[ -z "$(git -C "$R" status --porcelain --untracked-files=no)" ]] ||
  die "uncommitted changes: commit (and push) first, the package is built from the committed state"
gpg --list-secret-keys "$FPR" >/dev/null 2>&1 || die "signing key $FPR not in this user's GnuPG keyring"
command -v gh >/dev/null || die "gh (github-cli) is not installed"

W="$(mktemp -d /tmp/orka-release-XXXX)"
trap 'rm -rf "$W"' EXIT

pkg="$(bash "$R/pkg/build.sh" "$W")"
name="${pkg##*/}"
echo "Built $name"

if gh release view "$TAG" --json assets -q '.assets[].name' 2>/dev/null | grep -qxF "$name"; then
  die "$name is already published (commit something new first)"
fi

sign() { gpg --batch --yes --pinentry-mode loopback --passphrase '' -u "$FPR" --detach-sign --output "$1.sig" "$1"; }
sign "$pkg"
GPGKEY="$FPR" repo-add -q -s -k "$FPR" "$W/orka.db.tar.gz" "$pkg"
# pacman downloads orka.db / orka.files: real files, not repo-add's symlinks.
for f in orka.db orka.files; do
  cp --remove-destination "$(readlink -f "$W/$f")" "$W/$f"
  cp --remove-destination "$(readlink -f "$W/$f.sig")" "$W/$f.sig"
done

if ! gh release view "$TAG" >/dev/null 2>&1; then
  gh release create "$TAG" --title "OrkaOS package repository" --latest=false --notes \
"The pacman repository of OrkaOS: \`sudo pacman -Syu\` downloads the **orka** package from here.
Not meant for manual download. To connect a system: [pkg/join-repo.sh](https://github.com/$GH_REPO/blob/master/pkg/join-repo.sh)."
fi

gh release upload "$TAG" --clobber "$pkg" "$pkg.sig" "$W/orka.db" "$W/orka.db.sig" "$W/orka.files" "$W/orka.files.sig"
gh release view "$TAG" --json assets -q '.assets[].name' |
  { grep -E '^orka-[0-9].*\.pkg\.tar\.zst(\.sig)?$' | grep -vxF -e "$name" -e "$name.sig" || true; } |
  while read -r old; do gh release delete-asset "$TAG" "$old" --yes; echo "Removed $old"; done
echo "Published $name"

#!/usr/bin/env bash
# Build the OrkaOS installer ISO.
#
#   sudo ./iso/build.sh [stage...]
#
# Stages (default: all, in this order):
#   aur    build the AUR packages from packages-aur.txt with makepkg
#   repo   download every official package (with all dependencies) and
#          create the offline repo "orka" together with the AUR packages
#   nvim   download the Neovim (LazyVim) plugins, parsers and language
#          servers and pack them, so Neovim works offline on the first start
#   iso   assemble the archiso profile (releng + iso/profile overlay) and
#          run mkarchiso
#   clean  delete the build directory's work/ dir (keeps caches and output)
#
# Must run as root on Arch Linux (archiso, pacman). makepkg runs as the
# unprivileged build user: $SUDO_USER, or $ORKA_BUILD_USER if set.
# Everything is written below $ORKA_BUILD_DIR (default: ~build_user/orka-build).

set -euo pipefail
export LC_ALL=C.UTF-8   # built into glibc; the build host may have no locales generated

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_USER="${ORKA_BUILD_USER:-${SUDO_USER:-}}"
RELENG=/usr/share/archiso/configs/releng
REPO_NAME=orka

log()  { printf '\e[1;36m==>\e[0m \e[1m%s\e[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { printf '\e[1;31mERROR:\e[0m %s\n' "$*" >&2; exit 1; }

# Package names from a list file: strip comments and blank lines.
read_list() { sed -e 's/#.*//' "$1" | tr -s ' \t' '\n' | grep -v '^$' || true; }

# Strip version constraints: "go>=1.26" -> "go".
strip_ver() { sed -E 's/[<>=].*$//'; }

as_user() { runuser -u "$BUILD_USER" -- "$@"; }

preflight() {
  [[ $EUID -eq 0 ]] || die "run as root (sudo $0)"
  [[ -n "$BUILD_USER" && "$BUILD_USER" != root ]] || die "no build user: run with sudo, or set ORKA_BUILD_USER"
  command -v mkarchiso >/dev/null || die "archiso is not installed (pacman -S archiso)"
  [[ -d "$RELENG" ]] || die "archiso releng profile not found at $RELENG"

  BUILD_HOME="$(getent passwd "$BUILD_USER" | cut -d: -f6)"
  B="${ORKA_BUILD_DIR:-$BUILD_HOME/orka-build}"
  AUR_SRC="$B/aur-src"       # AUR git checkouts (build user)
  AUR_PKGS="$B/aur-pkgs"     # built AUR packages (build user)
  CACHE="$B/pkg-cache"       # downloaded official packages (reused between builds)
  PACDB="$B/pacman-db"       # empty pacman db, so downloads include every dependency
  REPO="$B/repo"             # the offline repo that goes into the ISO
  PROFILE="$B/profile"       # generated archiso profile
  WORK="$B/work"             # mkarchiso work dir (large, deleted after the build)
  OUT="$B/out"               # finished ISOs

  install -d -o "$BUILD_USER" -g "$BUILD_USER" "$B" "$AUR_SRC" "$AUR_PKGS"
  install -d "$CACHE" "$PACDB" "$OUT"

  # makepkg config without separate -debug packages.
  MAKEPKG_CONF="$B/makepkg.conf"
  sed -E 's/^(OPTIONS=.*[( ])debug/\1!debug/' /etc/makepkg.conf > "$MAKEPKG_CONF"
}

# ---------------------------------------------------------------------------
# Stage: aur
# ---------------------------------------------------------------------------

# Values of a .SRCINFO key for one package of a (possibly split) package base:
#   srcinfo_values <.SRCINFO> <pkgname> <key>
# A key set in the package's own section replaces the pkgbase value; keys like
# depends_x86_64 count as well.
srcinfo_values() {
  awk -v pkg="$2" -v key="$3" -F' = ' '
    /^pkgbase = / { sect = "base"; next }
    /^pkgname = / { sect = ($2 == pkg) ? "pkg" : "other"; next }
    {
      k = $1; sub(/^[ \t]+/, "", k)
      if (k != key && k != key "_x86_64") next
      if (sect == "base") base[++nb] = $2
      else if (sect == "pkg") own[++no] = $2
    }
    END { if (no) for (i = 1; i <= no; i++) print own[i]; else for (i = 1; i <= nb; i++) print base[i] }
  ' "$1"
}

stage_aur() {
  log "Building AUR packages"
  local aur_wanted pkg base dir deps missing
  mapfile -t aur_wanted < <(read_list "$SRC/packages-aur.txt")
  rm -f "$B/aur-runtime-deps.txt"

  for pkg in "${aur_wanted[@]}"; do
    base="$(curl -fsS "https://aur.archlinux.org/rpc/v5/info?arg[]=$pkg" |
            python -c 'import json,sys; r=json.load(sys.stdin)["results"]; print(r[0]["PackageBase"] if r else "")')"
    [[ -n "$base" ]] || die "AUR package not found: $pkg"
    dir="$AUR_SRC/$base"

    if [[ -d "$dir/.git" ]]; then
      as_user git -C "$dir" pull -q --ff-only
    else
      as_user git clone -q "https://aur.archlinux.org/$base.git" "$dir"
    fi

    # Build and runtime dependencies come from the official repos (none of
    # ours depends on another AUR package). Install the missing ones.
    local d
    mapfile -t deps < <( { srcinfo_values "$dir/.SRCINFO" "$pkg" depends
                           srcinfo_values "$dir/.SRCINFO" "$pkg" makedepends
                           srcinfo_values "$dir/.SRCINFO" "$pkg" checkdepends; } | strip_ver | sort -u)
    missing=()
    for d in "${deps[@]}"; do pacman -T "$d" >/dev/null || missing+=("$d"); done
    if ((${#missing[@]})); then
      info "$pkg: installing build deps: ${missing[*]}"
      pacman -S --noconfirm --needed --asdeps "${missing[@]}" >/dev/null
    fi

    # Runtime deps must also be in the offline repo.
    srcinfo_values "$dir/.SRCINFO" "$pkg" depends | strip_ver >> "$B/aur-runtime-deps.txt"

    local want
    want="$(cd "$dir" && as_user env PKGDEST="$AUR_PKGS" makepkg --config "$MAKEPKG_CONF" --packagelist | grep -E "/$pkg-[^-/]+-[^-/]+-[^-/]+\.pkg\.tar\.zst$" || true)"
    if [[ -n "$want" && -f "$want" ]]; then
      info "$pkg: up to date ($(basename "$want"))"
      continue
    fi
    info "$pkg: building ($base)"
    (cd "$dir" && as_user env PKGDEST="$AUR_PKGS" makepkg --config "$MAKEPKG_CONF" -f -c --noconfirm >"$B/makepkg-$base.log" 2>&1) ||
      die "makepkg failed for $base, see $B/makepkg-$base.log"
  done
  sort -u -o "$B/aur-runtime-deps.txt" "$B/aur-runtime-deps.txt"
}

# ---------------------------------------------------------------------------
# Stage: repo
# ---------------------------------------------------------------------------

stage_repo() {
  log "Downloading official packages into the offline repo"
  [[ -f "$B/aur-runtime-deps.txt" ]] || die "run the aur stage first"

  # pacman.conf: the system's official repos, but an empty local database so
  # that every dependency gets downloaded (as on a fresh install).
  local conf="$B/pacman-download.conf"
  # No DownloadUser: pacman would download as "alpm", which can't write here.
  sed -e '/^\[multilib\]/,/^$/d' -e '/^DownloadUser/d' /etc/pacman.conf > "$conf"
  sed -i -e "s|^#\?DBPath.*|DBPath = $PACDB/|" -e "s|^#\?CacheDir.*|CacheDir = $CACHE/|" "$conf"
  grep -q "^DBPath" "$conf"   || sed -i "/^\[options\]/a DBPath = $PACDB/" "$conf"
  grep -q "^CacheDir" "$conf" || sed -i "/^\[options\]/a CacheDir = $CACHE/" "$conf"

  local names aur_names
  mapfile -t aur_names < <(read_list "$SRC/packages-aur.txt")
  mapfile -t names < <( { read_list "$SRC/packages.txt"; cat "$B/aur-runtime-deps.txt"; } | sort -u)
  # AUR runtime deps that are themselves AUR packages are provided by aur-pkgs.
  mapfile -t names < <(printf '%s\n' "${names[@]}" | grep -vxF -f <(printf '%s\n' "${aur_names[@]}"))

  pacman --config "$conf" -Sy --noconfirm >/dev/null
  pacman --config "$conf" -Sw --noconfirm --needed "${names[@]}" >"$B/download.log" 2>&1 ||
    { tail -20 "$B/download.log"; die "package download failed, see $B/download.log"; }

  # Fresh repo dir with exactly the files of this snapshot (hard links).
  rm -rf "$REPO"; install -d "$REPO"
  local url f n=0
  while read -r url; do
    f="$CACHE/${url##*/}"
    [[ -f "$f" ]] || die "missing download: ${url##*/}"
    ln "$f" "$REPO/"
    [[ -f "$f.sig" ]] && ln "$f.sig" "$REPO/"
    n=$((n + 1))
  done < <(pacman --config "$conf" -Sp "${names[@]}")
  info "$n official packages"

  local p
  for p in "${aur_names[@]}"; do
    f="$(find "$AUR_PKGS" -maxdepth 1 -name "$p-*.pkg.tar.zst" -printf '%T@ %p\n' |
         awk -v p="$p" '{n=$2; sub(".*/","",n); if (n ~ "^"p"-[^-]+-[^-]+-[^-]+\\.pkg\\.tar\\.zst$") print}' |
         sort -n | tail -1 | cut -d' ' -f2)"
    [[ -n "$f" ]] || die "built AUR package not found: $p (run the aur stage)"
    cp "$f" "$REPO/"
  done
  info "${#aur_names[@]} AUR packages"

  repo-add -q "$REPO/$REPO_NAME.db.tar.zst" "$REPO"/*.pkg.tar.zst
  info "repo size: $(du -sh "$REPO" | cut -f1)"
}

# ---------------------------------------------------------------------------
# Stage: nvim
# ---------------------------------------------------------------------------

# LazyVim downloads its plugins, treesitter parsers and language servers on
# the first start. Do that here instead, with the versions pinned in
# config/user/nvim/lazy-lock.json, and pack the result for the installer.
stage_nvim() {
  log "Bundling Neovim plugins (LazyVim)"
  local t
  for t in nvim tree-sitter; do
    command -v "$t" >/dev/null || pacman -S --noconfirm --needed --asdeps neovim tree-sitter-cli >/dev/null
  done
  local home="$B/nvim-home" lock="$SRC/config/user/nvim/lazy-lock.json"
  rm -rf "$home"
  install -d -o "$BUILD_USER" -g "$BUILD_USER" "$home" "$home/.config"
  as_user cp -r --no-preserve=mode "$SRC/config/user/nvim" "$home/.config/nvim"
  (cd "$home" && as_user env -i HOME="$home" PATH=/usr/bin TERM=dumb \
     nvim --headless "+Lazy! restore" "+luafile $SRC/iso/nvim-bundle.lua") >"$B/nvim-bundle.log" 2>&1 ||
    { tail -20 "$B/nvim-bundle.log"; die "Neovim bundle failed, see $B/nvim-bundle.log"; }
  cmp -s "$lock" "$home/.config/nvim/lazy-lock.json" ||
    die "lazy-lock.json changed during the bundle (a plugin was added or removed?): update it from $home/.config/nvim/lazy-lock.json"
  info "$(grep -E '^(parsers|mason):' "$B/nvim-bundle.log" | tr '\n' ' ')"

  # Mason writes absolute paths into some wrapper scripts; the installer
  # rewrites this path to the user's home.
  local data="$home/.local/share/nvim"
  printf '%s\n' "$data" >"$data/.orka-build-path"
  tar -C "$home/.local/share" --zstd -cf "$B/nvim-data.tar.zst" nvim
  info "bundle: $(du -h "$B/nvim-data.tar.zst" | cut -f1)"
}

# ---------------------------------------------------------------------------
# Stage: iso
# ---------------------------------------------------------------------------

stage_iso() {
  log "Assembling the archiso profile"
  [[ -f "$REPO/$REPO_NAME.db.tar.zst" ]] || die "run the repo stage first"
  [[ -f "$B/nvim-data.tar.zst" ]] || die "run the nvim stage first"

  rm -rf "$PROFILE"
  cp -a "$RELENG" "$PROFILE"
  # --no-preserve=mode: files on a Windows drive (WSL /mnt/c) all look 0777.
  cp -r --no-preserve=mode,ownership "$SRC/iso/profile/." "$PROFILE/"

  # Naming and boot modes (UEFI only: the target machine has no BIOS boot).
  # shellcheck disable=SC2016  # the label's $(date ...) is evaluated by profiledef.sh
  sed -i \
    -e 's|^iso_name=.*|iso_name="orkaos"|' \
    -e 's|^iso_label=.*|iso_label="ORKAOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"|' \
    -e 's|^iso_publisher=.*|iso_publisher="OrkaOS"|' \
    -e 's|^iso_application=.*|iso_application="OrkaOS installer"|' \
    -e 's|^install_dir=.*|install_dir="orka"|' \
    -e "/^bootmodes=/,/)/c\\bootmodes=('uefi.systemd-boot')" \
    "$PROFILE/profiledef.sh"
  sed -i '/^file_permissions=(/a \  ["/usr/local/bin/orka-install"]="0:0:755"\n  ["/root/.zlogin"]="0:0:644"' "$PROFILE/profiledef.sh"
  rm -rf "$PROFILE/syslinux" "$PROFILE/grub"
  sed -i 's/Arch Linux install medium/OrkaOS installer/' "$PROFILE"/efiboot/loader/entries/*.conf

  # zstd instead of xz: the payload is mostly already-compressed packages.
  sed -i "s|^airootfs_image_tool_options=.*|airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')|" "$PROFILE/profiledef.sh"

  # Offline: do not wait for NTP before initializing the pacman keyring.
  rm -f "$PROFILE/airootfs/etc/systemd/system/sysinit.target.wants/systemd-time-wait-sync.service"

  # Extra packages for the live environment.
  read_list "$SRC/iso/live-packages.txt" >> "$PROFILE/packages.x86_64"

  # Offline repo and OrkaOS sources (installer, package lists, configs).
  install -d "$PROFILE/airootfs/opt/orka"
  cp -al "$REPO" "$PROFILE/airootfs/opt/orka/repo"
  cp "$B/nvim-data.tar.zst" "$PROFILE/airootfs/opt/orka/"
  install -d "$PROFILE/airootfs/opt/orka/src"
  cp -r --no-preserve=mode,ownership "$SRC/installer" "$SRC/config" "$SRC/bin" "$SRC/shell" "$SRC/themes" \
    "$SRC/packages.txt" "$SRC/packages-aur.txt" "$PROFILE/airootfs/opt/orka/src/"
  install -Dm755 "$SRC/installer/orka-install" "$PROFILE/airootfs/usr/local/bin/orka-install"

  log "Running mkarchiso"
  rm -rf "$WORK"
  mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE" >"$B/mkarchiso.log" 2>&1 ||
    { tail -30 "$B/mkarchiso.log"; die "mkarchiso failed, see $B/mkarchiso.log"; }
  rm -rf "$WORK"
  chown -R "$BUILD_USER:" "$OUT"
  info "ISO: $(ls -t "$OUT"/*.iso | head -1) ($(du -h "$(ls -t "$OUT"/*.iso | head -1)" | cut -f1))"
}

stage_clean() { log "Removing $WORK"; rm -rf "$WORK"; }

# ---------------------------------------------------------------------------

preflight
stages=("$@"); ((${#stages[@]})) || stages=(aur repo nvim iso)
for s in "${stages[@]}"; do
  case "$s" in
    aur|repo|nvim|iso|clean) "stage_$s" ;;
    *) die "unknown stage: $s" ;;
  esac
done
log "Done"

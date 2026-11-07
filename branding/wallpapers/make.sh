#!/usr/bin/env bash
# Build the generated OrkaOS wallpapers (2560x1440). Needs python3,
# rsvg-convert (librsvg) and imagemagick.
#
#   bash branding/wallpapers/make.sh
#
# OrkaOS ships these in /usr/share/orka/wallpapers (Settings → Wallpaper):
#   deep-water-bubbles.jpg  generated here (bubbles.py)
#   orka-ocean.png          the user's own picture (orcas in the ocean), as is;
#                           the default wallpaper
#   orka-moon.png           the user's own picture (an orca leaping in front
#                           of the moon), as is
#   orka-ice.png            the user's own picture (orcas among ice floes,
#                           seen from above)
#   orka-fins.png           the user's own picture (orca fins on the waves,
#                           above and below the surface)
#   deep-water-rays.jpg     the boot menu wallpaper (../limine/wallpaper.jpg),
#                           copied by orka-install
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT

# Bubbles, with a fine grain so the soft gradients don't show bands.
python3 "$HERE/bubbles.py" >"$W/bubbles.svg"
rsvg-convert -w 2560 -h 1440 "$W/bubbles.svg" -o "$W/bubbles.png"
magick "$W/bubbles.png" -attenuate 0.35 +noise Gaussian -quality 92 "$HERE/deep-water-bubbles.jpg"
echo "wallpapers: ok"

#!/usr/bin/env bash
# The OrkaOS boot menu (Limine) wallpaper, "Deep water": the ocean seen from
# below, lighter at the surface, with soft light rays fading into the deep.
# Colors from themes/orka (background #0d1620, accent #3fa7d6, teal #7fd1c7).
# Needs ImageMagick 7. Writes wallpaper.jpg next to this script.
#
#   branding/limine/make-wallpaper.sh [WIDTHxHEIGHT]   (default 2560x1440)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
size="${1:-2560x1440}"
w="${size%x*}" h="${size#*x}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Water: surface blue at the top, Orka's background in the middle, darker
# at the bottom.
magick -size "${w}x$((h / 2))" gradient:'#14476a-#0d1620' "$tmp/top.png"
magick -size "${w}x$((h - h / 2))" gradient:'#0d1620-#060b11' "$tmp/bottom.png"
magick "$tmp/top.png" "$tmp/bottom.png" -append "$tmp/water.png"

# Light rays: thin wedges from above the top edge, blurred and faded out
# towards the deep.
rays=()
for spec in "0.18 0.06 0.30" "0.34 0.04 0.22" "0.52 0.07 0.34" "0.70 0.05 0.24" "0.86 0.04 0.18"; do
  read -r x spread alpha <<<"$spec"
  cx=$(awk -v w="$w" -v x="$x" 'BEGIN { printf "%d", w * x }')
  half=$(awk -v w="$w" -v s="$spread" 'BEGIN { printf "%d", w * s }')
  top=$(awk -v w="$w" 'BEGIN { printf "%d", w * 0.012 }')
  rays+=(-fill "rgba(127,209,199,$alpha)" -draw "polygon $((cx - top)),0 $((cx + top)),0 $((cx + half - w / 10)),$h $((cx - half - w / 10)),$h")
done
magick -size "${w}x$h" xc:none "${rays[@]}" -blur 0x$((w / 60)) "$tmp/rays.png"
# Fade mask: opaque at the top, transparent at the bottom (dst_in keeps the
# rays only as much as the mask is opaque).
magick -size "${w}x$h" gradient:white-black -evaluate pow 1.6 -alpha copy "$tmp/fade.png"
magick "$tmp/rays.png" "$tmp/fade.png" -compose dst_in -composite "$tmp/rays-faded.png"

# Surface shimmer: a soft bright band just under the top edge.
magick -size "${w}x$h" xc:none -fill 'rgba(63,167,214,0.22)' \
  -draw "ellipse $((w / 2)),0 $((w * 6 / 10)),$((h / 7)) 0,360" -blur 0x$((h / 12)) "$tmp/surface.png"

# Vignette, then a little noise so the gradients don't band.
magick "$tmp/water.png" "$tmp/surface.png" -composite "$tmp/rays-faded.png" -compose screen -composite \
  \( -size "${w}x$h" radial-gradient:'rgba(0,0,0,0)-rgba(0,0,0,0.55)' \) -compose over -composite \
  -attenuate 0.2 +noise gaussian -quality 92 wallpaper.jpg
echo "wrote $(pwd)/wallpaper.jpg ($size)"

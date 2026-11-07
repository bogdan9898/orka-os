#!/usr/bin/env bash
# Build every OrkaOS logo file from source.png (the original logo, white on
# black). Needs imagemagick, potrace, rsvg-convert (librsvg), python3.
#
#   bash branding/logo/make.sh
#
# Writes, next to this script:
#   orkaos-logo.svg        the full logo with "Orka OS", white, see-through inside
#   orkaos-logo-badge.svg  the same with the black disc inside the ring
#   orkaos-mark.svg        without the name, white, see-through
#   orkaos-badge.svg       without the name, with the black disc (bar, app icon)
# and the PNGs other places need:
#   ../plymouth/orka/logo.png    boot screen (full logo, white), 640 px
#   ../plymouth/orka/ripple.png  the boot screen's ripple ring
#   ../plymouth/orka/background.png  the boot menu wallpaper (../limine) as PNG
#   ../fastfetch/orkaos.png      fastfetch (no name, white), 512 px
#   ../fastfetch/orkaos.txt      the same drawn with half blocks (▀▄█), for
#                                terminals without images (text consoles)
# Also needs chafa (for orkaos.txt).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/source.png"
W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT

# The white parts, as black-on-white bitmaps for potrace: everything, and
# without the name (painted over first).
magick "$SRC" -background black -alpha remove -alpha off -colorspace gray -threshold 55% -negate "$W/full.pbm"
magick "$SRC" -background black -alpha remove -alpha off -fill black -draw "rectangle 535,735 1056,858" \
  -colorspace gray -threshold 55% -negate "$W/mark.pbm"
for n in full mark; do
  potrace "$W/$n.pbm" -s -o "$W/$n.svg" --turdsize 6 --alphamax 1.0 --opttolerance 0.3
done
python3 "$HERE/compose.py" "$W" "$HERE"

mkdir -p "$HERE/../plymouth/orka" "$HERE/../fastfetch"
rsvg-convert -w 640 -h 640 "$HERE/orkaos-logo.svg" -o "$HERE/../plymouth/orka/logo.png"
rsvg-convert -w 512 -h 512 "$HERE/orkaos-mark.svg" -o "$HERE/../fastfetch/orkaos.png"
# Only blocks every console font has; "$1" = fastfetch's logo color 1.
{ printf '$1'; chafa -f symbols --symbols "space+solid+hhalf+vhalf" --colors none --size 34x17 \
    --bg black --fg white "$HERE/../fastfetch/orkaos.png" | sed 's/[[:space:]]*$//'; } >"$HERE/../fastfetch/orkaos.txt"
# The background: the boot menu wallpaper as PNG (Plymouth's script themes
# only load PNG), 1280x720: it's soft and blurry, scaled to the screen anyway,
# and small keeps the initramfs small.
magick "$HERE/../limine/wallpaper.jpg" -resize 1280x720 -strip "$HERE/../plymouth/orka/background.png"
# The ripple: a flat ring (an ellipse seen from the side, as on water), in
# the Orka accent color; the boot script scales and fades it.
magick -size 400x96 xc:none -fill none -stroke '#3fa7d6' -strokewidth 4 \
  -draw "ellipse 200,48 196,44 0,360" "$HERE/../plymouth/orka/ripple.png"
echo "png: ok"

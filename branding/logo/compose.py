#!/usr/bin/env python3
"""Build the OrkaOS logo SVGs from potrace's output (called by make.sh).

potrace traces the white parts of the logo (ring, the orca's white areas and
outlines, the waves, the name). The badge versions put a black disc behind
them, inside the ring, so the logo looks the same on light and dark
backgrounds.

    compose.py <work dir with full.svg and mark.svg> <output dir>
"""
import re
import sys
from pathlib import Path

work, out = Path(sys.argv[1]), Path(sys.argv[2])

# The ring in source.png (1254x1254): its outer edge spans 1054x1029 px from
# (97,80); the disc fills the inside of it.
DISC = '<ellipse cx="624" cy="594.5" rx="519" ry="506" fill="#000000"/>'
VIEWBOX = "84 54 1080 1080"     # a square around the ring


def traced(name):
    svg = (work / f"{name}.svg").read_text()
    g = re.search(r'<g transform="([^"]+)"[^>]*>(.*?)</g>', svg, re.S)
    return f'<g transform="{g.group(1)}" fill="#ffffff">{" ".join(g.group(2).split())}</g>'


def write(filename, title, parts):
    (out / filename).write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{VIEWBOX}">'
        f"<title>{title}</title>{''.join(parts)}</svg>\n")


full, mark = traced("full"), traced("mark")
write("orkaos-logo.svg", "OrkaOS", [full])                     # white, see-through inside
write("orkaos-logo-badge.svg", "OrkaOS", [DISC, full])         # with the black disc
write("orkaos-mark.svg", "OrkaOS", [mark])                     # without the name
write("orkaos-badge.svg", "OrkaOS", [DISC, mark])              # without the name, black disc
print("svg: ok")

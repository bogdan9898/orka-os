#!/usr/bin/env python3
"""The "Deep water bubbles" wallpaper as SVG (2560x1440): light from above,
soft bubbles rising through dark water. Rendered by make.sh.

    bubbles.py > deep-water-bubbles.svg
"""
import random

W, H = 2560, 1440
BG, DEEP, ACC, ACC2 = "#0d1620", "#060c12", "#3fa7d6", "#7fd1c7"

random.seed(4)   # the layout that was picked; change for a different one
bubbles = []
for _ in range(110):
    x = random.gauss(W * 0.62, W * 0.2)
    y = random.uniform(0, H)
    depth = y / H
    r = random.choice([3, 4, 5, 6, 8, 10, 14, 20, 28]) * (1.2 - 0.5 * depth)
    op = (0.08 + 0.35 * (1 - depth)) * random.uniform(0.4, 1)
    blur = ' filter="url(#soft)"' if r > 12 else ""
    bubbles.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r:.1f}" fill="{ACC2}" fill-opacity="{op * 0.25:.3f}" '
                   f'stroke="{ACC2}" stroke-opacity="{op:.3f}" stroke-width="1.5"{blur}/>')

print(f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
  <linearGradient id="sea" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#12304a"/><stop offset=".55" stop-color="{BG}"/><stop offset="1" stop-color="{DEEP}"/>
  </linearGradient>
  <radialGradient id="beam" cx=".62" cy="0" r=".9">
    <stop offset="0" stop-color="{ACC}" stop-opacity=".18"/><stop offset="1" stop-color="{ACC}" stop-opacity="0"/>
  </radialGradient>
  <filter id="soft"><feGaussianBlur stdDeviation="2.5"/></filter>
</defs>
<rect width="{W}" height="{H}" fill="url(#sea)"/>
<rect width="{W}" height="{H}" fill="url(#beam)"/>
{"".join(bubbles)}
</svg>''')

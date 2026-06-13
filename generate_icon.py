#!/usr/bin/env python3
"""Generate a simple app icon for DevBox Manager."""

from PIL import Image, ImageDraw, ImageFont
import os, subprocess, tempfile, shutil

SIZE = 1024

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Rounded-rectangle background — dark blue-grey gradient feel
def rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)
    draw.pieslice([x0, y0, x0 + 2*radius, y0 + 2*radius], 180, 270, fill=fill)
    draw.pieslice([x1 - 2*radius, y0, x1, y0 + 2*radius], 270, 360, fill=fill)
    draw.pieslice([x0, y1 - 2*radius, x0 + 2*radius, y1], 90, 180, fill=fill)
    draw.pieslice([x1 - 2*radius, y1 - 2*radius, x1, y1], 0, 90, fill=fill)

# Background
margin = 20
corner = 185
rounded_rect(draw, [margin, margin, SIZE - margin, SIZE - margin], corner, (34, 40, 49))

# Inner darker panel for the "server" body
panel_l, panel_r = 160, SIZE - 160
panel_t, panel_b = 180, SIZE - 180
panel_corner = 60
rounded_rect(draw, [panel_l, panel_t, panel_r, panel_b], panel_corner, (24, 28, 36))

# Draw 3 server "bays" (horizontal slices)
bay_h = 130
gap = 24
total_h = 3 * bay_h + 2 * gap
start_y = (SIZE - total_h) // 2

for i in range(3):
    y = start_y + i * (bay_h + gap)
    bay_l = panel_l + 40
    bay_r = panel_r - 40
    r = 28
    rounded_rect(draw, [bay_l, y, bay_r, y + bay_h], r, (50, 58, 70))

    # LED dot — green for top bay, amber for middle, blue for bottom
    colors = [(72, 219, 140), (245, 185, 66), (88, 166, 255)]
    led_x = bay_l + 50
    led_y = y + bay_h // 2
    led_r = 16
    draw.ellipse([led_x - led_r, led_y - led_r, led_x + led_r, led_y + led_r], fill=colors[i])

    # Drive bay lines (decorative)
    line_y_center = y + bay_h // 2
    for j in range(4):
        lx = bay_r - 80 - j * 44
        draw.rounded_rectangle(
            [lx, line_y_center - 30, lx + 28, line_y_center + 30],
            radius=6,
            fill=(62, 72, 85),
        )

# Save as 1024x1024 PNG, then create .iconset and convert to .icns
import sys
script_dir = os.path.dirname(os.path.abspath(__file__))
iconset_dir = os.path.join(script_dir, "DevBoxManager.iconset")
os.makedirs(iconset_dir, exist_ok=True)

# Output path from argument or default
icns_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(script_dir, "AppIcon.icns")

# macOS icon sizes
sizes = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for name, sz in sizes:
    resized = img.resize((sz, sz), Image.LANCZOS)
    resized.save(os.path.join(iconset_dir, name))

# Convert to icns
subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True)

# Clean up iconset
shutil.rmtree(iconset_dir)

print(f"✅ Icon generated: {icns_path}")

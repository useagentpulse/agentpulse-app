#!/usr/bin/env python3
"""
Generates Agent Pulse app icon in all required macOS sizes.
Design: dark charcoal background, terracotta pulse/ECG waveform, subtle glow.
Run: python3 scripts/generate_icons.py
Requires: pip3 install Pillow
"""

import math
import os
from PIL import Image, ImageDraw, ImageFilter

ICON_DIR = "AgentPulse/Resources/Assets.xcassets/AppIcon.appiconset"

BG_COLOR     = (28, 28, 32)       # dark charcoal
PULSE_COLOR  = (217, 119, 87)     # Anthropic terracotta
GLOW_COLOR   = (217, 119, 87, 60) # faint glow
WHITE        = (255, 255, 255)

SIZES = [
    ("icon_16x16.png",       16),
    ("icon_16x16@2x.png",    32),
    ("icon_32x32.png",       32),
    ("icon_32x32@2x.png",    64),
    ("icon_128x128.png",     128),
    ("icon_128x128@2x.png",  256),
    ("icon_256x256.png",     256),
    ("icon_256x256@2x.png",  512),
    ("icon_512x512.png",     512),
    ("icon_512x512@2x.png",  1024),
]

def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded rect background
    radius = size * 0.22
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=BG_COLOR)

    # ECG / pulse waveform path
    # Spans 80% of width, vertically centred
    margin_x = size * 0.10
    w = size - margin_x * 2
    cy = size * 0.50
    lw = max(1, int(size * 0.038))

    # Waveform control points (normalised 0–1 in x, -1–1 in y amplitude)
    # Flat → small bump → sharp spike up → sharp spike down → flat → small bump → flat
    amp  = size * 0.28
    amp2 = size * 0.10

    def px(nx): return margin_x + nx * w
    def py(ny): return cy - ny * amp

    points = [
        (px(0.00), py(0.00)),
        (px(0.15), py(0.00)),
        (px(0.22), py(0.12)),   # small pre-bump
        (px(0.28), py(0.00)),
        (px(0.35), py(1.00)),   # spike up
        (px(0.42), py(-0.80)),  # spike down
        (px(0.48), py(0.20)),   # recovery bump
        (px(0.54), py(0.00)),
        (px(0.65), py(0.10)),   # small trailing bump
        (px(0.72), py(0.00)),
        (px(1.00), py(0.00)),
    ]

    # Glow layer (blurred wider line)
    glow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_img)
    gd.line(points, fill=(*PULSE_COLOR, 80), width=lw * 4)
    glow_img = glow_img.filter(ImageFilter.GaussianBlur(radius=lw * 2))
    img = Image.alpha_composite(img, glow_img)

    # Main line
    draw = ImageDraw.Draw(img)
    draw.line(points, fill=(*PULSE_COLOR, 255), width=lw)

    # Dot at the tip of the spike
    dot_x = px(0.35)
    dot_y = py(1.00)
    dot_r = lw * 1.6
    draw.ellipse(
        [dot_x - dot_r, dot_y - dot_r, dot_x + dot_r, dot_y + dot_r],
        fill=(*WHITE, 230)
    )

    return img


def main():
    os.makedirs(ICON_DIR, exist_ok=True)
    for filename, size in SIZES:
        img = draw_icon(size)
        path = os.path.join(ICON_DIR, filename)
        img.save(path, "PNG")
        print(f"  ✓ {filename} ({size}×{size})")
    print(f"\nIcons written to {ICON_DIR}/")
    print("Rebuild in Xcode to pick them up.")


if __name__ == "__main__":
    main()

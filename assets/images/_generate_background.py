"""Procedurally generate background.jpg for the Neck Alert app.

Run from the repo root:  python neck_alert/assets/images/_generate_background.py
Produces a 1080x1920 dark-teal gradient with soft bokeh dots and starry specks.
Deterministic (fixed seed) so re-runs produce the same image.
"""
import os
import random
from PIL import Image, ImageDraw, ImageFilter

W, H = 1080, 1920
OUT = os.path.join(os.path.dirname(__file__), "background.jpg")

# --- 1. Diagonal 3-stop gradient: 0F2027 -> 203A43 -> 2C5364 ---
STOPS = [(0.0, (15, 32, 39)), (0.5, (32, 58, 67)), (1.0, (44, 83, 100))]


def lerp(a, b, t):
    return int(a + (b - a) * t)


def grad_color(t):
    for i in range(len(STOPS) - 1):
        t0, c0 = STOPS[i]
        t1, c1 = STOPS[i + 1]
        if t0 <= t <= t1:
            f = (t - t0) / (t1 - t0)
            return (lerp(c0[0], c1[0], f), lerp(c0[1], c1[1], f), lerp(c0[2], c1[2], f))
    return STOPS[-1][1]


img = Image.new("RGB", (W, H), (0, 0, 0))
px = img.load()
# Diagonal gradient direction (top-left -> bottom-right)
max_d = W + H
for y in range(H):
    for x in range(W):
        t = (x + y) / max_d
        px[x, y] = grad_color(t)

# --- 2. Soft bokeh circles (drawn on overlay then blurred and composited) ---
overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(overlay)
rand = random.Random(42)
tints = [(100, 200, 220), (80, 160, 180), (150, 220, 255)]
for _ in range(60):
    cx = rand.randint(-50, W + 50)
    cy = rand.randint(-50, H + 50)
    r = rand.randint(40, 220)
    alpha = rand.randint(15, 45)
    tint = rand.choice(tints)
    draw.ellipse(
        [cx - r, cy - r, cx + r, cy + r],
        fill=(tint[0], tint[1], tint[2], alpha),
    )

overlay = overlay.filter(ImageFilter.GaussianBlur(radius=18))
img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")

# --- 3. Tiny star specks ---
draw = ImageDraw.Draw(img)
for _ in range(120):
    x = rand.randint(0, W - 1)
    y = rand.randint(0, H - 1)
    r = rand.randint(1, 2)
    a = rand.randint(80, 180)
    color = (255, 255, 255)
    # PIL doesn't blend alpha on RGB easily; approximate by mixing toward white.
    cur = img.getpixel((x, y))
    f = a / 255.0
    mixed = (
        lerp(cur[0], color[0], f),
        lerp(cur[1], color[1], f),
        lerp(cur[2], color[2], f),
    )
    draw.ellipse([x - r, y - r, x + r, y + r], fill=mixed)

# --- 4. Save ---
img.save(OUT, "JPEG", quality=85, optimize=True)
size_kb = os.path.getsize(OUT) / 1024
print(f"Saved {OUT} ({size_kb:.1f} KB)")

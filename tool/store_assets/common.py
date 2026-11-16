"""Shared drawing helpers for Sort Sphere store assets (icon, splash,
feature graphic, screenshot frames). Needs Pillow.

Colors mirror lib/core/theme/app_colors.dart so the store art matches the
game.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

# App palette (AppColors / BallPalette).
BG = (8, 13, 26)
NAVY_TOP = (22, 32, 70)
NAVY_BOTTOM = (6, 10, 22)
CYAN = (54, 228, 255)
BLUE = (92, 124, 255)
VIOLET = (155, 108, 255)
GOLD = (255, 209, 102)
GREEN = (53, 211, 154)
WHITE = (248, 250, 255)
MUTED = (180, 192, 216)

BALL_RED = (255, 92, 122)
BALL_CYAN = (54, 221, 245)
BALL_YELLOW = (255, 209, 102)
BALL_PURPLE = (155, 108, 255)
BALL_GREEN = (53, 211, 154)
BALL_ORANGE = (255, 159, 67)

FONT = '/System/Library/Fonts/Avenir Next.ttc'
HEAVY, BOLD, DEMI, MEDIUM = 8, 0, 2, 5


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


def lighten(c, t):
    return lerp(c, (255, 255, 255), t)


def darken(c, t):
    return lerp(c, (0, 0, 0), t)


def vertical_gradient(size, top, bottom):
    w, h = size
    g = Image.new('RGB', (1, h))
    for y in range(h):
        g.putpixel((0, y), lerp(top, bottom, y / max(1, h - 1)))
    return g.resize((w, h))


def linear_fill(size, c1, c2, angle_deg=0):
    """Gradient image along an angle (0 = left to right)."""
    w, h = size
    big = int(math.hypot(w, h)) + 2
    g = Image.new('RGB', (big, 1))
    for x in range(big):
        g.putpixel((x, 0), lerp(c1, c2, x / (big - 1)))
    g = g.resize((big, big)).rotate(-angle_deg, resample=Image.BICUBIC)
    left, top = (big - w) // 2, (big - h) // 2
    return g.crop((left, top, left + w, top + h))


def radial_glow(size, center, radius, color, alpha=0.35):
    """Soft light blob as an RGBA layer."""
    layer = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=tuple(color) + (int(255 * alpha),))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.45))


def backdrop(size, accent=BLUE):
    """The game's night-sky background with two soft glows."""
    w, h = size
    img = vertical_gradient(size, NAVY_TOP, NAVY_BOTTOM).convert('RGBA')
    img.alpha_composite(radial_glow(size, (w * 0.22, h * 0.18), max(w, h) * 0.45, accent, 0.40))
    img.alpha_composite(radial_glow(size, (w * 0.88, h * 0.86), max(w, h) * 0.40, VIOLET, 0.32))
    return img


def ball(img, cx, cy, r, base, shadow=True, glow=0.0):
    """Glossy 3D sphere, lit from the top-left like the in-game balls."""
    w, h = img.size
    if glow:
        img.alpha_composite(radial_glow((w, h), (cx, cy), r * 1.5, base, glow))
    if shadow:
        sh = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(sh).ellipse([cx - r * 0.85, cy + r * 0.62, cx + r * 0.85, cy + r * 1.08], fill=(0, 0, 0, 120))
        img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(r * 0.14)))

    size = int(r * 2) + 4
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    o = size / 2
    hx, hy = -r * 0.32, -r * 0.36  # light source offset
    dark = darken(base, 0.62)
    mid = base
    light = lighten(base, 0.30)
    steps = 120
    for i in range(steps, 0, -1):
        t = i / steps  # 1 = outer rim, 0 = hot spot
        rr = r * t
        ox, oy = hx * (1 - t), hy * (1 - t)
        if t > 0.5:
            c = lerp(mid, dark, ((t - 0.5) / 0.5) ** 1.6)
        else:
            c = lerp(light, mid, t / 0.5)
        d.ellipse([o + ox - rr, o + oy - rr, o + ox + rr, o + oy + rr], fill=c + (255,))
    # Bottom bounce light: a thin crescent near the lower rim.
    rim = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim)
    rd.ellipse([o - r * 0.70, o + r * 0.52, o + r * 0.70, o + r * 0.94], fill=lighten(base, 0.25) + (80,))
    rd.ellipse([o - r * 0.80, o + r * 0.30, o + r * 0.80, o + r * 0.80], fill=(0, 0, 0, 0))
    rim = rim.filter(ImageFilter.GaussianBlur(r * 0.08))
    # Specular highlight: soft window reflection + small hot spot.
    spec = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(spec)
    sd.ellipse([o - r * 0.58, o - r * 0.74, o - r * 0.02, o - r * 0.36], fill=(255, 255, 255, 120))
    spec = spec.filter(ImageFilter.GaussianBlur(r * 0.07))
    sd2 = ImageDraw.Draw(spec)
    sd2.ellipse([o - r * 0.44, o - r * 0.60, o - r * 0.26, o - r * 0.46], fill=(255, 255, 255, 240))
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse([o - r, o - r, o + r, o + r], fill=255)
    for extra in (rim, spec):
        a = extra.getchannel('A')
        extra.putalpha(Image.composite(a, Image.new('L', a.size, 0), mask))
        layer.alpha_composite(extra)
    layer.putalpha(Image.composite(layer.getchannel('A'), Image.new('L', mask.size, 0), mask))
    img.alpha_composite(layer, (int(cx - o), int(cy - o)))


def tube(img, x, top, width, height, glow_color=None):
    """Glass test tube with a rounded bottom (drawn behind and in front of balls)."""
    w, h = img.size
    r = width / 2
    box = [x - r, top, x + r, top + height]
    if glow_color:
        g = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(g).rounded_rectangle(box, radius=r, fill=tuple(glow_color) + (110,))
        img.alpha_composite(g.filter(ImageFilter.GaussianBlur(width * 0.22)))
    body = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle(box, radius=r, fill=(170, 200, 255, 30))
    # Square off the top so it reads as an open tube.
    bd.rectangle([x - r, top, x + r, top + r], fill=(170, 200, 255, 30))
    img.alpha_composite(body)


def tube_front(img, x, top, width, height):
    """Glass rim, outline and reflections, drawn over the balls."""
    w, h = img.size
    r = width / 2
    lw = max(2, int(width * 0.035))
    front = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(front)
    # Outline: one continuous U (a rounded rect whose top is cut off).
    fd.rounded_rectangle([x - r, top - width, x + r, top + height], radius=r, outline=(220, 235, 255, 145), width=lw)
    fd.rectangle([x - r - lw, top - width - lw, x + r + lw, top + width * 0.05], fill=(0, 0, 0, 0))
    # Lip.
    lip_h = width * 0.11
    fd.rounded_rectangle([x - r - width * 0.08, top - lip_h * 0.3, x + r + width * 0.08, top + lip_h * 0.7],
                         radius=lip_h / 2, fill=(225, 238, 255, 170))
    img.alpha_composite(front)
    # Long reflection strip on the left.
    refl = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(refl).rounded_rectangle(
        [x - r * 0.72, top + width * 0.28, x - r * 0.48, top + height - width * 0.55],
        radius=width * 0.06, fill=(255, 255, 255, 80))
    img.alpha_composite(refl.filter(ImageFilter.GaussianBlur(width * 0.02)))
    thin = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(thin).rounded_rectangle(
        [x + r * 0.55, top + width * 0.35, x + r * 0.66, top + height * 0.55],
        radius=width * 0.03, fill=(255, 255, 255, 45))
    img.alpha_composite(thin)


def sparkle(img, cx, cy, s, color=(235, 250, 255), alpha=230):
    """Four-point star sparkle."""
    w, h = img.size
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    k = s * 0.18
    d.polygon([(cx, cy - s), (cx + k, cy - k), (cx + s, cy), (cx + k, cy + k),
               (cx, cy + s), (cx - k, cy + k), (cx - s, cy), (cx - k, cy - k)], fill=color + (alpha,))
    img.alpha_composite(radial_glow((w, h), (cx, cy), s * 0.9, color, 0.35))
    img.alpha_composite(layer)

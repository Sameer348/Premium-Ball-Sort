"""Google Play feature graphic, 1024x500.

Run after make_icon.py: python3 tool/store_assets/make_feature_graphic.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

from common import *

W, H, SS = 1024, 500, 3


def gradient_text(img, xy, text, font, c1, c2):
    w, h = img.size
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).text(xy, text, font=font, fill=255)
    box = mask.getbbox()
    if not box:
        return
    grad = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    grad.paste(linear_fill((box[2] - box[0], box[3] - box[1]), c1, c2, 0).convert('RGBA'), box[:2])
    grad.putalpha(mask)
    img.alpha_composite(grad)


def main():
    w, h = W * SS, H * SS
    img = backdrop((w, h), accent=BLUE)
    img.alpha_composite(radial_glow((w, h), (w * 0.74, h * 0.55), h * 0.7, CYAN, 0.16))

    # Right: four tubes, two already sorted, one ball mid-flight.
    tw = h * 0.14
    br = tw * 0.40
    gap = br * 0.12
    th = br * 2 * 4 + gap * 3 + tw * 0.42
    top = h * 0.29
    xs = [w * 0.60 + i * tw * 1.62 for i in range(4)]
    stacks = [
        [BALL_CYAN, BALL_CYAN, BALL_CYAN, BALL_CYAN],
        [BALL_RED, BALL_RED, BALL_RED],
        [BALL_YELLOW, BALL_YELLOW, BALL_YELLOW],
        [BALL_PURPLE, BALL_PURPLE, BALL_PURPLE, BALL_PURPLE],
    ]
    for i, (x, stack) in enumerate(zip(xs, stacks)):
        sorted_tube = len(stack) == 4 and len(set(stack)) == 1
        tube(img, x, top, tw, th, glow_color=stack[0] if sorted_tube else None)
        bottom = top + th - tw * 0.5 + br * 0.98 - br
        for j, col in enumerate(stack):
            ball(img, x, bottom - j * (br * 2 + gap), br, col, shadow=False)
        tube_front(img, x, top, tw, th)
        if sorted_tube:
            sparkle(img, x + tw * 0.62, top - tw * 0.35, h * 0.028)
    # Yellow ball flying from tube 2 to tube 3 along an arc.
    arc = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ad = ImageDraw.Draw(arc)
    x1, x2 = xs[1], xs[2]
    for k in range(24):
        t = k / 23 * 0.72
        ax = x1 + (x2 - x1) * t
        ay = top - h * 0.03 - (1 - (2 * t - 1) ** 2) * h * 0.13
        rr = br * 0.13 * (0.4 + t)
        ad.ellipse([ax - rr, ay - rr, ax + rr, ay + rr], fill=BALL_YELLOW + (int(190 * t),))
    img.alpha_composite(arc)
    ball(img, x1 + (x2 - x1) * 0.8, top - h * 0.03 - (1 - (2 * 0.8 - 1) ** 2) * h * 0.13, br, BALL_YELLOW, shadow=False, glow=0.35)

    # Left: icon, wordmark, tagline.
    icon = Image.open(os.path.join(ROOT, 'store', 'branding', 'app_icon_1024.png')).convert('RGBA')
    isz = int(h * 0.24)
    icon = icon.resize((isz, isz), Image.LANCZOS)
    m = Image.new('L', (isz, isz), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, isz - 1, isz - 1], radius=int(isz * 0.22), fill=255)
    icon.putalpha(m)
    lx = int(w * 0.065)
    img.alpha_composite(icon, (lx, int(h * 0.12)))
    title = ImageFont.truetype(FONT, int(h * 0.165), index=HEAVY)
    sub = ImageFont.truetype(FONT, int(h * 0.058), index=DEMI)
    d = ImageDraw.Draw(img)
    d.text((lx, int(h * 0.42)), 'SORT', font=title, fill=WHITE)
    gradient_text(img, (lx, int(h * 0.59)), 'SPHERE', title, CYAN, BLUE)
    d = ImageDraw.Draw(img)
    d.text((lx, int(h * 0.82)), 'Calm, satisfying ball sort puzzles', font=sub, fill=MUTED)

    out = img.resize((W, H), Image.LANCZOS).convert('RGB')
    os.makedirs(os.path.join(ROOT, 'store', 'google_play'), exist_ok=True)
    out.save(os.path.join(ROOT, 'store', 'google_play', 'feature_graphic_1024x500.png'))
    print('feature graphic ok')


if __name__ == '__main__':
    main()

"""Framed store screenshots with headlines.

Input:  store/raw_screenshots/*.png  (iPhone 17 Pro Max captures, 1320x2868)
Output: store/google_play/screenshots      (1080x1920, Play phone)
        store/app_store/screenshots_6.9    (1320x2868)
        store/app_store/screenshots_6.5    (1284x2778)
Run:    python3 tool/store_assets/make_screenshots.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

from common import *

RAW = os.path.join(ROOT, 'store', 'raw_screenshots')

# (raw file, line 1, highlighted line 2, subtitle, accent)
SLIDES = [
    ('game', 'Sort the balls', 'one color per tube', 'Calm, satisfying, easy to learn', CYAN),
    ('game_hard', '2,000 levels', 'from calm to clever', 'Up to 12 tubes and 10 colors', VIOLET),
    ('complete', 'Collect stars', 'on every level', 'Beat the move target for 3 stars', GOLD),
    ('daily', 'A new puzzle', 'every single day', 'Daily Challenge with streak rewards', BLUE),
    ('home', '5 ways to play', 'your way', 'Classic · Daily · Endless · Time Attack · Perfect', CYAN),
    ('map', 'Follow the', 'journey map', 'Collect stars as the puzzles grow', GREEN),
    ('shop', 'Unlock ball skins', '& glowing themes', 'Glass, Neon, Crystal, Galaxy and more', BALL_RED),
    ('hint', 'Stuck? Get a', 'smart hint', 'Hint, Undo, Extra Tube and Shuffle', VIOLET),
]

TARGETS = [
    ('google_play/screenshots', 1080, 1920),
    ('app_store/screenshots_6.9', 1320, 2868),
    ('app_store/screenshots_6.5', 1284, 2778),
]


def gradient_text(img, xy, text, font, c1, c2):
    w, h = img.size
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).text(xy, text, font=font, fill=255, anchor='mt')
    box = mask.getbbox()
    if not box:
        return
    grad = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    grad.paste(linear_fill((box[2] - box[0], box[3] - box[1]), c1, c2, 0).convert('RGBA'), box[:2])
    grad.putalpha(mask)
    img.alpha_composite(grad)


def fit_font(text, index, size, max_w):
    while True:
        f = ImageFont.truetype(FONT, size, index=index)
        if f.getlength(text) <= max_w or size < 20:
            return f
        size -= 2


def slide(raw, l1, l2, sub, accent, W, H):
    img = backdrop((W, H), accent=accent)
    img.alpha_composite(radial_glow((W, H), (W * 0.5, H * 0.96), W * 0.6, BLUE, 0.22))

    wide = W / H > 0.5  # Play's 9:16 canvas is wider relative to height
    title_size = int(W * (0.088 if not wide else 0.074))
    sub_size = int(W * (0.037 if not wide else 0.033))
    f1 = fit_font(l1, HEAVY, title_size, W * 0.9)
    f2 = fit_font(l2, HEAVY, title_size, W * 0.9)
    fs = fit_font(sub, DEMI, sub_size, W * 0.9)
    top = int(H * (0.05 if not wide else 0.04))
    d = ImageDraw.Draw(img)
    d.text((W / 2, top), l1, font=f1, fill=WHITE, anchor='mt')
    gradient_text(img, (W / 2, top + title_size * 1.2), l2, f2, lighten(accent, 0.35), lerp(accent, BLUE, 0.4))
    d = ImageDraw.Draw(img)
    d.text((W / 2, top + title_size * 2.5), sub, font=fs, fill=MUTED, anchor='mt')

    # Phone frame.
    shot = Image.open(os.path.join(RAW, raw + '.png')).convert('RGBA')
    dev_top = int(top + title_size * 2.5 + sub_size * 2.1)
    avail_h = H - dev_top + int(H * 0.08)  # the phone may run off the bottom edge a little
    dev_w = int(W * (0.80 if not wide else 0.62))
    dev_h = int(dev_w * shot.height / shot.width)
    if dev_h > avail_h * 1.15:
        dev_h = int(avail_h * 1.15)
        dev_w = int(dev_h * shot.width / shot.height)
    bezel = int(dev_w * 0.028)
    radius = int(dev_w * 0.13)
    shot = shot.resize((dev_w, dev_h), Image.LANCZOS)
    m = Image.new('L', (dev_w, dev_h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, dev_w - 1, dev_h - 1], radius=radius - bezel, fill=255)
    shot.putalpha(m)

    fw, fh = dev_w + bezel * 2, dev_h + bezel * 2
    x = (W - fw) // 2
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([x, dev_top + 30, x + fw, dev_top + fh + 30], radius=radius, fill=(0, 0, 0, 170))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(40)))
    gl = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(gl).rounded_rectangle([x, dev_top, x + fw, dev_top + fh], radius=radius, fill=tuple(accent) + (80,))
    img.alpha_composite(gl.filter(ImageFilter.GaussianBlur(60)))
    frame = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle([x, dev_top, x + fw, dev_top + fh], radius=radius,
                                            fill=(20, 24, 36, 255), outline=(90, 100, 130, 255), width=max(2, bezel // 6))
    img.alpha_composite(frame)
    img.alpha_composite(shot, (x + bezel, dev_top + bezel))
    return img.convert('RGB')


def main():
    for folder, W, H in TARGETS:
        out = os.path.join(ROOT, 'store', folder)
        os.makedirs(out, exist_ok=True)
        for i, (raw, l1, l2, sub, accent) in enumerate(SLIDES, 1):
            slide(raw, l1, l2, sub, accent, W, H).save(os.path.join(out, f'{i:02d}_{raw}.png'), optimize=True)
        print('ok', folder)


if __name__ == '__main__':
    main()

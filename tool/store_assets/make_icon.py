"""Sort Sphere app icon + splash logo.

Writes:
  store/branding/app_icon_1024.png, play_store_icon_512.png, splash_logo.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/*   (every listed size)
  ios/Runner/Assets.xcassets/LaunchImage.imageset/* (splash logo 1x/2x/3x)
  android/app/src/main/res/mipmap-*/ic_launcher*.png + adaptive icon XML
  android/app/src/main/res/drawable*/splash_logo.png

Run: python3 tool/store_assets/make_icon.py   (needs Pillow)
"""
import json
import os
from PIL import Image, ImageDraw

from common import *

SS = 3  # supersampling


def glyph(size, scale=1.0, glow=True):
    """Glass tube holding three sorted-looking balls, on transparency."""
    S = size * SS
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    c = S / 2
    tw = S * 0.255 * scale         # tube width
    br = tw * 0.40                 # ball radius
    gap = br * 0.12
    th = br * 2 * 3 + gap * 2 + tw * 0.42  # tube height fits 3 balls + headroom
    top = c - th / 2 + S * 0.01 * scale
    tube(img, c, top, tw, th, glow_color=CYAN if glow else None)
    bottom = top + th - tw * 0.5 + br * 0.98 - br  # resting point of lowest ball
    colors = [BALL_PURPLE, BALL_RED, BALL_CYAN]
    for i, col in enumerate(colors):
        cy = bottom - i * (br * 2 + gap)
        ball(img, c, cy, br, col, shadow=False)
    tube_front(img, c, top, tw, th)
    # Sparkles around the top ball: "sorted!" feedback from the game.
    sparkle(img, c + tw * 0.95, top + tw * 0.35, S * 0.045 * scale)
    sparkle(img, c - tw * 0.92, top + tw * 0.95, S * 0.028 * scale, alpha=200)
    sparkle(img, c + tw * 0.80, top - tw * 0.18, S * 0.020 * scale, color=(255, 230, 170), alpha=200)
    return img


def background(size):
    S = size * SS
    return backdrop((S, S), accent=BLUE)


def master(size=1024):
    bg = background(size)
    bg.alpha_composite(glyph(size))
    return bg.resize((size, size), Image.LANCZOS).convert('RGB')


def splash_logo(px):
    """Transparent logo for the native launch screen (no square backdrop)."""
    return glyph(px, scale=1.1, glow=False).resize((px, px), Image.LANCZOS)


def main():
    out = os.path.join(ROOT, 'store', 'branding')
    os.makedirs(out, exist_ok=True)
    icon = master(1024)
    icon.save(os.path.join(out, 'app_icon_1024.png'))
    icon.resize((512, 512), Image.LANCZOS).save(os.path.join(out, 'play_store_icon_512.png'))
    splash_logo(768).save(os.path.join(out, 'splash_logo.png'))

    # iOS app icon: every size listed in Contents.json (no alpha allowed).
    ios_dir = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    contents = json.load(open(os.path.join(ios_dir, 'Contents.json')))
    for im in contents['images']:
        if 'filename' not in im:
            continue
        pts = float(im['size'].split('x')[0])
        px = int(round(pts * int(im['scale'][0])))
        icon.resize((px, px), Image.LANCZOS).save(os.path.join(ios_dir, im['filename']))

    # iOS launch image (used by LaunchScreen.storyboard).
    li = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset')
    if os.path.isdir(li):
        for k, name in [(1, 'LaunchImage.png'), (2, 'LaunchImage@2x.png'), (3, 'LaunchImage@3x.png')]:
            splash_logo(160 * k).save(os.path.join(li, name))

    # Android legacy launcher icons (rounded square + round).
    res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
    dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    mask_sq = Image.new('L', (1024, 1024), 0)
    ImageDraw.Draw(mask_sq).rounded_rectangle([0, 0, 1023, 1023], radius=220, fill=255)
    mask_rd = Image.new('L', (1024, 1024), 0)
    ImageDraw.Draw(mask_rd).ellipse([0, 0, 1023, 1023], fill=255)
    sq = icon.convert('RGBA'); sq.putalpha(mask_sq)
    rd = icon.convert('RGBA'); rd.putalpha(mask_rd)
    fg_master = glyph(432, scale=0.72)  # adaptive content must sit in the inner 66 of 108 dp
    bg_master = background(432).convert('RGB')
    for name, k in dens.items():
        d = os.path.join(res, f'mipmap-{name}')
        os.makedirs(d, exist_ok=True)
        sq.resize((int(48 * k), int(48 * k)), Image.LANCZOS).save(os.path.join(d, 'ic_launcher.png'))
        rd.resize((int(48 * k), int(48 * k)), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_round.png'))
        fg_master.resize((int(108 * k), int(108 * k)), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_foreground.png'))
        bg_master.resize((int(108 * k), int(108 * k)), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_background.png'))
        # Splash logo for the launch window (Android < 12) and Android 12+ splash icon.
        dd = os.path.join(res, f'drawable-{name}')
        os.makedirs(dd, exist_ok=True)
        splash_logo(int(160 * k)).save(os.path.join(dd, 'splash_logo.png'))
        # Android 12 splash icon: 240dp canvas, logo inside the 160dp circle.
        s12 = Image.new('RGBA', (int(240 * k), int(240 * k)), (0, 0, 0, 0))
        logo = splash_logo(int(150 * k))
        s12.alpha_composite(logo, ((s12.width - logo.width) // 2, (s12.height - logo.height) // 2))
        s12.save(os.path.join(dd, 'splash_icon.png'))

    any_dir = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(any_dir, exist_ok=True)
    xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
           '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
           '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
           '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
           '</adaptive-icon>\n')
    for n in ('ic_launcher.xml', 'ic_launcher_round.xml'):
        open(os.path.join(any_dir, n), 'w').write(xml)
    print('icons ok')


if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == 'preview':
        master(1024).save(sys.argv[2])
    else:
        main()

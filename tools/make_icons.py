"""Crop the rounded square out of the Gemini logo sheet and regenerate all app icons.

The source render is close to but not exactly on-brand, so every generated pixel is
snapped to the two official brand colours.
"""
from PIL import Image
import os

SRC = 'photos/Gemini_Generated_Image_b0krisb0krisb0kr.png'
MASTER = 'photos/app_icon_rounded_square.png'

# As rendered by Gemini — used only to classify source pixels.
SRC_LIGHT = (204, 217, 189)
SRC_DARK = (43, 78, 56)

# Official brand colours.
BRAND_LIGHT = (197, 212, 182)   # #C5D4B6
BRAND_DARK = (35, 73, 52)       # #234934

FULL = sum(abs(a - b) for a, b in zip(SRC_DARK, SRC_LIGHT))

# iOS standalone splash screens. Representative iPhone size classes; each one
# needs a matching <link rel="apple-touch-startup-image"> media query in
# web/index.html — add here and there together or the device silently falls
# back to a blank canvas.
SPLASH_SIZES = [(750, 1334), (1170, 2532), (1179, 2556), (1284, 2778), (1290, 2796)]


def near(c, t, tol=40):
    return sum(abs(a - b) for a, b in zip(c, t)) < tol


def find_square(im):
    """Bounding box of the light-green rounded square (the caption below is excluded)."""
    w, h = im.size
    px = im.load()
    rows = [sum(1 for x in range(0, w, 2) if near(px[x, y], SRC_LIGHT)) for y in range(h)]
    ys = [y for y, n in enumerate(rows) if n > 25]
    top, bottom = ys[0], ys[-1]
    cols = [sum(1 for y in range(top, bottom, 2) if near(px[x, y], SRC_LIGHT)) for x in range(w)]
    xs = [x for x, n in enumerate(cols) if n > 25]
    return xs[0], top, xs[-1] + 1, bottom + 1


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def build_master(crop):
    """Rounded square on transparency, recoloured to the exact brand palette.

    Alpha comes from distance to the white paper; the light↔dark mix comes from
    distance to the source background, so anti-aliasing on both the outer corners
    and the glyph edges is preserved.
    """
    crop = crop.convert('RGB')
    w, h = crop.size
    px = crop.load()
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            # 6 = tolerance for off-white paper; 54 spreads the ramp over the
            # remaining distance so edge pixels get a proportional alpha.
            dist = 255 - min(r, g, b) - 6
            if dist <= 0:
                continue
            a = min(255, int(dist * 255 / 54))
            # 20 = noise floor; the flat background varies by a few levels per
            # channel and would otherwise read as a faint glyph everywhere.
            d = sum(abs(c - s) for c, s in zip((r, g, b), SRC_LIGHT)) - 20
            t = 0.0 if d <= 0 else min(1.0, d / (FULL * 0.6))
            op[x, y] = lerp(BRAND_LIGHT, BRAND_DARK, t) + (a,)
    return out


def extract_glyph(master):
    """The dark mark alone, on transparency, cropped tight."""
    w, h = master.size
    px = master.load()
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            # Only fully-opaque pixels are interior; softer ones are the rounded
            # corner edge and must not be mistaken for the glyph.
            if a < 250:
                continue
            d = sum(abs(c - s) for c, s in zip((r, g, b), BRAND_LIGHT))
            full = sum(abs(x_ - y_) for x_, y_ in zip(BRAND_DARK, BRAND_LIGHT))
            ga = min(255, int(d * 255 / (full * 0.6)))
            if ga > 8:
                op[x, y] = BRAND_DARK + (ga,)
    return out.crop(out.getbbox())


def centred(content, canvas_size, coverage, bg=None):
    """Scale `content` to `coverage` of the canvas and centre it."""
    canvas = Image.new('RGBA', (canvas_size, canvas_size), bg or (0, 0, 0, 0))
    target = int(canvas_size * coverage)
    cw, ch = content.size
    scale = target / max(cw, ch)
    resized = content.resize((max(1, round(cw * scale)), max(1, round(ch * scale))), Image.LANCZOS)
    canvas.paste(resized, ((canvas_size - resized.width) // 2,
                           (canvas_size - resized.height) // 2), resized)
    return canvas


def centred_rect(content, width, height, coverage, bg):
    """Scale `content` to `coverage` of the canvas *width* and centre it.

    Width-relative rather than max-dimension (as `centred` is): splash canvases
    are portrait and range from 750x1334 to 1290x2796, so scaling off the long
    edge would make the mark balloon on the taller devices while staying small
    on the 4.7" one.
    """
    canvas = Image.new('RGBA', (width, height), bg)
    target = int(width * coverage)
    cw, ch = content.size
    scale = target / max(cw, ch)
    resized = content.resize((max(1, round(cw * scale)), max(1, round(ch * scale))), Image.LANCZOS)
    canvas.paste(resized, ((width - resized.width) // 2,
                           (height - resized.height) // 2), resized)
    return canvas


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f'  {path}  {img.size[0]}x{img.size[1]}')


src = Image.open(SRC)
box = find_square(src)
print(f'square bbox {box} -> {box[2]-box[0]}x{box[3]-box[1]}')

cropped = build_master(src.crop(box))
side = max(cropped.size)
master = Image.new('RGBA', (side, side), (0, 0, 0, 0))
master.paste(cropped, ((side - cropped.width) // 2, (side - cropped.height) // 2), cropped)
print('\nmaster:')
save(master, MASTER)

glyph = extract_glyph(master)
print(f'glyph {glyph.size[0]}x{glyph.size[1]}')

print('\nandroid legacy (ic_launcher.png) — the rounded square itself:')
for dpi, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    save(master.resize((size, size), Image.LANCZOS),
         f'android/app/src/main/res/mipmap-{dpi}/ic_launcher.png')

# Adaptive icons are masked to the launcher's shape, so the foreground carries the
# mark alone and the background colour supplies the green — a nested rounded square
# would otherwise show up as a double border.
print('\nandroid adaptive (ic_launcher_foreground.png) — mark inside the 66dp safe zone:')
for dpi, size in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216), ('xxhdpi', 324), ('xxxhdpi', 432)]:
    save(centred(glyph, size, 0.58),
         f'android/app/src/main/res/mipmap-{dpi}/ic_launcher_foreground.png')

print('\nweb:')
save(master.resize((192, 192), Image.LANCZOS), 'web/icons/Icon-192.png')
save(master.resize((512, 512), Image.LANCZOS), 'web/icons/Icon-512.png')
save(master.resize((32, 32), Image.LANCZOS), 'web/favicon.png')

opaque = BRAND_LIGHT + (255,)
# Apple applies its own corner rounding, so ship a full-bleed square.
save(centred(glyph, 180, 0.64, bg=opaque), 'web/icons/Icon-apple-touch-180.png')
# Maskable icons get cropped to the platform shape: full bleed, content in the safe zone.
save(centred(glyph, 192, 0.60, bg=opaque), 'web/icons/Icon-maskable-192.png')
save(centred(glyph, 512, 0.60, bg=opaque), 'web/icons/Icon-maskable-512.png')

# The splash canvas is BRAND_LIGHT, matching manifest.json's background_color
# and index.html's body background — so the handoff from splash to first Flutter
# frame is invisible. That means the *mark alone* goes on it, not the rounded
# square master: a light-green square on a light-green field would vanish.
print('\nios splash — mark on the brand background:')
for sw, sh in SPLASH_SIZES:
    save(centred_rect(glyph, sw, sh, 0.30, opaque),
         f'web/splash/apple-splash-{sw}x{sh}.png')

print('\nplay store:')
save(master.resize((512, 512), Image.LANCZOS), 'docs/play-store-icon-512.png')

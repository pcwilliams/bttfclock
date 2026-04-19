"""Generate BTTF Time Circuits app icons (standard, dark, tinted) at 1024x1024."""
from PIL import Image, ImageDraw, ImageFilter
import os
import random

SIZE = 1024
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "bttfclock", "Assets.xcassets", "AppIcon.appiconset")


def brushed_metal_background(c_top, c_bot):
    img = Image.new("RGB", (SIZE, SIZE), c_top)
    pix = img.load()
    random.seed(42)
    for y in range(SIZE):
        t = y / SIZE
        base_r = int(c_top[0] * (1 - t) + c_bot[0] * t)
        base_g = int(c_top[1] * (1 - t) + c_bot[1] * t)
        base_b = int(c_top[2] * (1 - t) + c_bot[2] * t)
        x = 0
        while x < SIZE:
            seg = random.randint(18, 80)
            jitter = random.randint(-8, 8)
            r = max(0, min(255, base_r + jitter))
            g = max(0, min(255, base_g + jitter))
            b = max(0, min(255, base_b + jitter))
            for ix in range(x, min(x + seg, SIZE)):
                pix[ix, y] = (r, g, b)
            x += seg
    return img


def draw_rivet(draw, cx, cy, r):
    draw.ellipse([cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2],
                 fill=(10, 10, 8))
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 40, 36))
    draw.ellipse([cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4],
                 fill=(95, 95, 88))
    draw.ellipse([cx - r + 7, cy - r + 7, cx + r - 2, cy + r - 2],
                 fill=(55, 55, 50))


def draw_row(img, y0, y1, color_core, digit_pattern):
    draw = ImageDraw.Draw(img, "RGBA")
    pad = 56
    rx, ry = pad, y0
    rw, rh = SIZE - 2 * pad, y1 - y0
    # bezel
    draw.rounded_rectangle([rx - 4, ry - 4, rx + rw + 4, ry + rh + 4],
                           radius=20, fill=(8, 8, 6, 255))
    # inner tinted window
    tint = tuple(int(c * 0.10) for c in color_core) + (255,)
    draw.rounded_rectangle([rx, ry, rx + rw, ry + rh], radius=16, fill=tint)
    # subtle bevel highlight
    draw.rounded_rectangle([rx, ry, rx + rw, ry + 6], radius=12,
                           fill=(255, 255, 255, 20))

    # render glow on a transparent layer
    glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer)

    # strip of blocks
    strip_w = rw - 80
    strip_h = rh - 60
    sx = rx + 40
    sy = ry + 30
    num = len(digit_pattern)
    block_w = strip_w // num
    for i, is_on in enumerate(digit_pattern):
        bx = sx + i * block_w + 6
        by = sy + 10
        bw = block_w - 12
        bh = strip_h - 20
        if is_on:
            gd.rounded_rectangle([bx, by, bx + bw, by + bh], radius=8,
                                 fill=color_core + (255,))
        else:
            dim = tuple(c // 8 for c in color_core) + (255,)
            gd.rounded_rectangle([bx, by, bx + bw, by + bh], radius=8, fill=dim)

    glow = glow_layer.filter(ImageFilter.GaussianBlur(radius=28))
    img.paste(glow, (0, 0), glow)
    img.paste(glow_layer, (0, 0), glow_layer)


def make_icon(variant):
    if variant == "standard":
        metal_top = (58, 56, 50)
        metal_bot = (28, 28, 24)
        red = (255, 50, 45)
        green = (55, 255, 85)
        amber = (255, 175, 20)
    elif variant == "dark":
        metal_top = (34, 34, 30)
        metal_bot = (10, 10, 8)
        red = (255, 70, 60)
        green = (80, 255, 110)
        amber = (255, 195, 50)
    else:  # tinted: greyscale for iOS tinted mode
        metal_top = (70, 70, 70)
        metal_bot = (25, 25, 25)
        grey = (220, 220, 220)
        red = green = amber = grey

    img = brushed_metal_background(metal_top, metal_bot).convert("RGB")

    # dashboard pattern: OCT 26 1985 style with nine blocks, some unlit to suggest digits
    pattern_dest = [1, 1, 1, 0, 1, 1, 0, 1, 1]
    pattern_present = [1, 1, 1, 0, 1, 1, 0, 1, 1]
    pattern_last = [1, 1, 1, 0, 1, 1, 0, 1, 1]

    top_y = 170
    row_h = 210
    row_gap = 18
    draw_row(img, top_y, top_y + row_h, red, pattern_dest)
    draw_row(img, top_y + row_h + row_gap, top_y + 2 * row_h + row_gap, green, pattern_present)
    draw_row(img, top_y + 2 * (row_h + row_gap),
             top_y + 3 * row_h + 2 * row_gap, amber, pattern_last)

    rd = ImageDraw.Draw(img)
    for cx, cy in [(95, 95), (SIZE - 95, 95),
                   (95, SIZE - 95), (SIZE - 95, SIZE - 95)]:
        draw_rivet(rd, cx, cy, 28)

    return img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for variant, suffix in [("standard", ""),
                            ("dark", "_dark"),
                            ("tinted", "_tinted")]:
        icon = make_icon(variant)
        out = os.path.join(OUT_DIR, f"bttfclock_icon{suffix}.png")
        icon.save(out, "PNG", optimize=True)
        print(f"wrote {out}")


if __name__ == "__main__":
    main()

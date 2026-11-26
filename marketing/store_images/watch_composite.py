"""Swap each language's real watch screen (marketing/watch_screenshots/<os>/<lang>) into the
watch bezel renders used by the Watch / Wear OS store slides. Placement was found by matching
the English screen against each bezel; the mask keeps only pixels that came from the screen."""
import os, sys, numpy as np
from PIL import Image, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', 'watch_screenshots')
# bezel file, screen os, screenshot, x, y, size (w, h)
JOBS = {
    'aw_today':   ('bezel_apple_watch_today.png',     'watchos', '1_today.png',      72, 184, (422, 514)),
    'aw_log':     ('bezel_apple_watch_ultra_log.png', 'watchos', '2_log_amount.png', 99, 213, (422, 514)),
    'wear_today': ('bezel_wear_today.png',            'wear_os', '1_today.png',     117, 470, (939, 939)),
    'wear_log':   ('bezel_wear_log.png',              'wear_os', '2_log_amount.png', 60, 173, (279, 279)),
}
LANGS = ['en', 'bs', 'de', 'es', 'fr', 'it', 'pt', 'tr']

def place(img, bezel, x, y, size):
    layer = Image.new('RGBA', bezel.size, (0, 0, 0, 0))
    layer.paste(img.convert('RGBA').resize(size, Image.LANCZOS), (x, y))
    return layer

def main(out_dir):
    for key, (bz, os_, shot, x, y, size) in JOBS.items():
        bezel = Image.open(os.path.join(HERE, 'assets', bz)).convert('RGBA')
        en = place(Image.open(os.path.join(SHOTS, os_, 'en', shot)), bezel, x, y, size)
        b = np.asarray(bezel, np.float32); e = np.asarray(en, np.float32)
        diff = np.abs(b[..., :3] - e[..., :3]).mean(-1)
        hit = (diff < 40) & (e[..., 3] > 0)
        # the screen is convex: fill each row and column between its outermost matching pixels
        rows = np.zeros_like(hit); cols = np.zeros_like(hit)
        for yy in np.where(hit.any(1))[0]:
            xs = np.where(hit[yy])[0]
            if len(xs) > 20: rows[yy, xs[0]:xs[-1] + 1] = True
        for xx in np.where(hit.any(0))[0]:
            ys = np.where(hit[:, xx])[0]
            if len(ys) > 20: cols[ys[0]:ys[-1] + 1, xx] = True
        m = (rows & cols).astype(np.uint8) * 255
        mask = Image.fromarray(m).filter(ImageFilter.MinFilter(5)).filter(ImageFilter.GaussianBlur(1.5))
        for lang in LANGS:
            src = os.path.join(SHOTS, os_, lang, shot)
            loc = place(Image.open(src), bezel, x, y, size)
            out = bezel.copy(); out.paste(loc, (0, 0), mask)
            # keep the bezel's own alpha (transparent background around the watch)
            out.putalpha(bezel.getchannel('A'))
            d = os.path.join(out_dir, lang); os.makedirs(d, exist_ok=True)
            out.save(os.path.join(d, key + '.png'))
        print(key, 'mask px', int((m > 0).sum()))

if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'build', 'watch'))

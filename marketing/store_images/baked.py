"""Some text layers stayed visible in the exported text-hidden bases (Figma did not hide
them in the copy). A layer counts as baked in when the English render adds (almost) nothing
on top of the base inside its box while the box has ink. For those, record the colour just
around the box (on the layer's own side of any mask) so render.mjs paints a patch over the
English before drawing the translation. Writes build/baked.json. Run after `render.mjs en`."""
import json, os, re, numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
fig = json.load(open(os.path.join(HERE, 'figma_text.json')))
hp = os.path.join(HERE, 'build', 'hidden.json')
hidden = json.load(open(hp)) if os.path.exists(hp) else {}
FILES = {'284:22055': 'ios/en/01_build_habits', '284:60035': 'ios/en/02_track_your_way', '284:60036': 'ios/en/03_consistency', '284:60071': 'ios/en/04_reminders', '284:60077': 'ios/en/08_any_mood',
         '284:34815': 'android/en/01_build_habits', '287:63136': 'android/en/02_track_your_way', '287:63958': 'android/en/03_consistency', '287:64557': 'android/en/04_reminders', '287:65106': 'android/en/07_any_mood'}

def polygon(mask):
    pts = [tuple(map(float, p)) for p in re.findall(r'[ML]\s*([-\d.]+)\s+([-\d.]+)', mask['path'] or '')]
    a, b, c, d, e, f = mask['tf']
    return [(e + a * x + c * y, f + b * x + d * y) for x, y in pts]

def inside(poly, x, y):
    r = False
    for i in range(len(poly)):
        (x1, y1), (x2, y2) = poly[i], poly[i - 1]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1: r = not r
    return r

# Partly under the phone notch: looks like ink but is not baked, and a patch would erase the notch
NOT_BAKED = {'Edit habit in the past'}
out = {}
for fid, F in fig.items():
    B = np.asarray(Image.open(os.path.join(HERE, 'base', fid.replace(':', '-') + '.png')).convert('RGB'), np.float32)
    E = np.asarray(Image.open(os.path.join(HERE, 'out', FILES[fid] + '.png')).convert('RGB'), np.float32)
    H, W, _ = B.shape
    for it in F['items']:
        if it['id'] in hidden.get(fid, []) or it['k'] in NOT_BAKED: continue
        a, b, c, d, e, f = it['tf']
        poly = polygon(F['masks'][it['mask'][1]]) if it['mask'] else None
        want_in = it['mask'] and it['mask'][0] == 'in'
        def pts(us, vs, side_only):
            for u in us:
                for v in vs:
                    x, y = e + a * u + c * v, f + b * u + d * v
                    xi, yi = int(round(x)), int(round(y))
                    if not (0 <= xi < W and 0 <= yi < H): continue
                    if side_only and poly and len(poly) > 2 and inside(poly, x, y) != bool(want_in): continue
                    yield yi, xi
        w, h, pad = it['w'], it['h'], 6
        ins = list(pts(np.linspace(0, w, 60), np.linspace(0, h, 16), True))
        if len(ins) < 10: continue
        bi = np.array([B[p] for p in ins]); ei = np.array([E[p] for p in ins])
        # background = the dominant colour inside the box (text is the minority of pixels)
        bg = np.median(bi, 0)
        ink = (np.abs(bi - bg).mean(-1) > 40).mean()
        added = (np.abs(ei - bi).mean(-1) > 40).mean()
        if ink > 0.45: continue  # mostly something else (e.g. the notch): no flat colour to patch with
        if ink > 0.02 and added < ink * 0.8:
            out.setdefault(fid, {})[it['id']] = [int(x) for x in bg]
    print(fid, 'baked', len(out.get(fid, {})))
json.dump(out, open(os.path.join(HERE, 'build', 'baked.json'), 'w'), indent=1)

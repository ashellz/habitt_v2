"""Find Figma text layers that are covered in the original design (e.g. by an opaque card
painted over them) so render.mjs does not draw them. Compares, per layer, the original
section screenshot (assets/figma_section_*.png) with the text-hidden base and with the
English overlay render: if the English overlay adds ink there but the original shows none,
the layer is covered. Writes build/hidden.json. Run after `render.mjs en`."""
import json, os, numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
SECTIONS = {  # section width, frame x inside the section, frame y (None = find it)
    'ios': (7574, 'assets/figma_section_ios.png', 372, {'284:22055': 398, '284:60035': 1831, '284:60036': 3264, '284:60071': 4697, '284:60077': 6130}),
    'android': (6620, 'assets/figma_section_play.png', None, {'284:34815': 382, '287:63136': 1576, '287:63958': 2770, '287:64557': 3964, '287:65106': 5158}),
}
FILES = {'284:22055': '01_build_habits', '284:60035': '02_track_your_way', '284:60036': '03_consistency', '284:60071': '04_reminders', '284:60077': '08_any_mood',
         '284:34815': '01_build_habits', '287:63136': '02_track_your_way', '287:63958': '03_consistency', '287:64557': '04_reminders', '287:65106': '07_any_mood'}
fig = json.load(open(os.path.join(HERE, 'figma_text.json')))
arr = lambda im: np.asarray(im.convert('RGB'), np.float32)
hidden = {}
for store, (secW, shot, fy, frames) in SECTIONS.items():
    S = Image.open(os.path.join(HERE, shot)); k = S.width / secW; SA = arr(S)
    for fid, fx in frames.items():
        F = fig[fid]; w, h = round(F['w'] * k), round(F['h'] * k)
        base = arr(Image.open(os.path.join(HERE, 'base', fid.replace(':', '-') + '.png')).resize((w, h), Image.LANCZOS))
        en = arr(Image.open(os.path.join(HERE, 'out', store, 'en', FILES[fid] + '.png')).resize((w, h), Image.LANCZOS))
        # find the frame in the screenshot (it has a margin): search around the expected spot
        ex, ey = round(fx * k), round((fy or 372) * k)
        small = base[::4, ::4]
        best = min((np.mean(np.abs(SA[y:y + h:4, x:x + w:4] - small)), x, y)
                   for y in range(max(0, ey - 60), min(SA.shape[0] - h, ey + 60))
                   for x in range(max(0, ex - 60), min(SA.shape[1] - w, ex + 60)))
        _, x0, y0 = best
        orig = SA[y0:y0 + h, x0:x0 + w]
        for it in F['items']:
            a, b, c, d, e, f = it['tf']
            xs = [e, e + a * it['w'], e + c * it['h'], e + a * it['w'] + c * it['h']]
            ys_ = [f, f + b * it['w'], f + d * it['h'], f + b * it['w'] + d * it['h']]
            bx0, bx1 = max(0, int(min(xs) * k)), min(w, int(np.ceil(max(xs) * k)))
            by0, by1 = max(0, int(min(ys_) * k)), min(h, int(np.ceil(max(ys_) * k)))
            cx, cy, cw, ch = it['clip']
            bx0, by0 = max(bx0, int(cx * k)), max(by0, int(cy * k)); bx1, by1 = min(bx1, int((cx + cw) * k)), min(by1, int((cy + ch) * k))
            if bx1 <= bx0 or by1 <= by0: hidden.setdefault(fid, []).append(it['id']); continue
            sl = np.s_[by0:by1, bx0:bx1]
            d_en = np.abs(en[sl] - base[sl]).mean()
            if d_en < 1.0: continue  # too faint to judge: keep it
            seen = np.abs(orig[sl] - base[sl]).mean() / d_en
            if seen < 0.3: hidden.setdefault(fid, []).append(it['id'])
        print(store, fid, 'at', x0, y0, 'hidden', len(hidden.get(fid, [])), 'of', len(F['items']))
os.makedirs(os.path.join(HERE, 'build'), exist_ok=True)
json.dump(hidden, open(os.path.join(HERE, 'build', 'hidden.json'), 'w'), indent=1)

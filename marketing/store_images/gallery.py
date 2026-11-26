"""Writes out/index.html: every rendered image, per language and store. Open it in a browser."""
import glob, html, os
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, 'out')
langs = ['en', 'bs', 'de', 'es', 'fr', 'it', 'pt', 'tr']
parts = []
for l in langs:
    parts.append(f'<section id="{l}"><h2>{l.upper()}</h2>')
    for store, label in [('ios', 'App Store'), ('android', 'Google Play')]:
        imgs = sorted(os.path.relpath(p, OUT) for p in glob.glob(os.path.join(OUT, store, l, '*.png')))
        parts.append(f'<h3>{label} · {len(imgs)}</h3><div class="row">' + ''.join(
            f'<a href="{p}" target="_blank"><img src="{p}" loading="lazy" title="{html.escape(p)}"><span>{os.path.basename(p)}</span></a>' for p in imgs) + '</div>')
    parts.append('</section>')
nav = ' '.join(f'<a href="#{l}">{l.upper()}</a>' for l in langs)
open(os.path.join(OUT, 'index.html'), 'w').write(f'''<!doctype html><meta charset="utf-8"><title>Habitt store images</title>
<style>body{{font-family:-apple-system,sans-serif;margin:0;background:#1d1d1f;color:#eee}}nav{{position:sticky;top:0;background:#000;padding:10px 16px;z-index:1}}nav a{{color:#02D382;margin-right:14px;text-decoration:none;font-weight:600}}
section{{padding:8px 16px 24px}}.row{{display:flex;gap:12px;overflow-x:auto;padding-bottom:8px}}.row a{{flex:none;color:#aaa;text-decoration:none;font-size:12px;text-align:center}}.row img{{height:520px;display:block;border-radius:8px;margin-bottom:4px}}</style>
<nav>{nav}</nav>{''.join(parts)}''')
print('wrote', os.path.join(OUT, 'index.html'))

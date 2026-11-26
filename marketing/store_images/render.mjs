// Renders the localized store images with headless Chrome. See README.md.
//
//   node marketing/store_images/render.mjs            all languages
//   node marketing/store_images/render.mjs de tr      only these
//
// Two kinds of images:
//  - Figma images (5 per store): base/<frameId>.png is the Figma frame exported with
//    every translatable text layer hidden; figma_text.json has each layer's position and
//    style, and the text is drawn back on top in Satoshi, translated.
//  - Slides (slides.mjs): the 6 extra slides, built on the Figma frames' tokens with the
//    app's own icons. Watch slides get that language's watch screens (watch_composite.py).
// Every translated text is shrunk until it fits the space the English text used.

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { slidePage, STORES } from './slides.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const CHROME = process.env.CHROME || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const T = JSON.parse(fs.readFileSync(path.join(HERE, 'translations.json'), 'utf8'));
const LANGS = process.argv.slice(2).length ? process.argv.slice(2) : ['en', ...T.langs];
const OUT = path.join(HERE, 'out');
const TMP = path.join(HERE, 'build', 'html');
fs.mkdirSync(TMP, { recursive: true });

const tr = (en, lang) => (lang === 'en' ? en : T.strings[en]?.[lang] ?? (() => { throw new Error(`no ${lang} for ${JSON.stringify(en)}`); })());
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const htmlText = (s) => esc(s).replace(/\r/g, '').replace(/\n/g, '<br>');
const url = (p) => pathToFileURL(path.join(HERE, p)).href;

// ─── Store sets ──────────────────────────────────────────────────────────────
// Figma frames: [frame id, name]. iOS 1290×2796, Play 1080×1920.
const IOS_FIGMA = [['284:22055', 'build_habits'], ['284:60035', 'track_your_way'], ['284:60036', 'consistency'], ['284:60071', 'reminders'], ['284:60077', 'any_mood']];
const PLAY_FIGMA = [['284:34815', 'build_habits'], ['287:63136', 'track_your_way'], ['287:63958', 'consistency'], ['287:64557', 'reminders'], ['287:65106', 'any_mood']];
// Final order per store: figma names or slide names.
const IOS_ORDER = ['build_habits', 'track_your_way', 'consistency', 'reminders', 'slide:Main', 'slide:Health', 'slide:Themes', 'any_mood', 'slide:Watch'];
const PLAY_ORDER = ['build_habits', 'track_your_way', 'consistency', 'reminders', 'slide:Main', 'slide:HealthConnect', 'any_mood', 'slide:WearOS'];

// ─── Shared page bits ────────────────────────────────────────────────────────
const FONT_FACES = `
@font-face{font-family:"Satoshi";font-weight:400;src:url("${url('assets/Satoshi-Regular.otf')}")}
@font-face{font-family:"Satoshi";font-weight:500;src:url("${url('assets/Satoshi-Medium.otf')}")}
@font-face{font-family:"Satoshi";font-weight:700;src:url("${url('assets/Satoshi-Bold.otf')}")}
@font-face{font-family:"Satoshi";font-weight:900;src:url("${url('assets/Satoshi-Black.otf')}")}
@font-face{font-family:"Satoshi Variable";font-weight:300 900;src:url("${url('assets/Satoshi-Variable.ttf')}")}`;

// Shrinks each [data-fit] element until it is no taller than data-maxh (or its English
// height, measured first) and no wider than data-maxw (or its box). Then flags done.
const FIT_SCRIPT = `<script>
document.fonts.ready.then(() => {
  for (const el of document.querySelectorAll('[data-fit]')) {
    const cs = getComputedStyle(el);
    let size = parseFloat(cs.fontSize); const min = size * (+el.dataset.min || 0.55);
    const tx = el.innerHTML;
    let maxH = parseFloat(el.dataset.maxh || 'NaN'), maxW = parseFloat(el.dataset.maxw || 'NaN');
    if (el.dataset.en !== undefined) { el.innerHTML = el.dataset.en; if (isNaN(maxH)) maxH = el.offsetHeight; el.innerHTML = tx; }
    if (el.dataset.lines) { const one = parseFloat(cs.lineHeight) || size * 1.2; maxH = Math.max(maxH, one * +el.dataset.lines); }
    const tooBig = () => el.offsetHeight > maxH + 1 || (isNaN(maxW) ? el.scrollWidth > el.clientWidth + 1 : el.scrollWidth > maxW + 1);
    const lh = cs.lineHeight; const lhRatio = lh.endsWith('px') ? parseFloat(lh) / size : null;
    while (tooBig() && size > min) { size *= 0.97; el.style.fontSize = size + 'px'; if (lhRatio) el.style.lineHeight = (lhRatio * size) + 'px'; }
    if (tooBig()) console.warn('still too big', tx);
  }
  document.body.dataset.done = '1';
});
</script>`;

function shoot(html, file, w, h) {
  const tmp = path.join(TMP, path.relative(OUT, file).replaceAll(path.sep, '_').replace(/\.png$/, '.html'));
  fs.writeFileSync(tmp, html);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const args = ['--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1', '--allow-file-access-from-files',
    `--window-size=${w},${h}`, '--virtual-time-budget=4000', `--screenshot=${file}`, pathToFileURL(tmp).href];
  // Chrome sometimes exits non-zero after writing the screenshot ("Teardown watchdog
  // expired"): accept a freshly written file, otherwise retry once.
  for (let attempt = 0; ; attempt++) {
    const started = Date.now();
    try { execFileSync(CHROME, args, { stdio: 'pipe' }); return; } catch (err) {
      if (fs.existsSync(file) && fs.statSync(file).mtimeMs >= started - 1000) return;
      if (attempt >= 1) throw err;
    }
  }
}

// ─── HTML slides: see slides.mjs ────────────────────────────────────────────

// ─── Figma images ────────────────────────────────────────────────────────────
const FIG = fs.existsSync(path.join(HERE, 'figma_text.json')) ? JSON.parse(fs.readFileSync(path.join(HERE, 'figma_text.json'), 'utf8')) : null;
// Layers covered in the original design (written by occlusion.py)
const HIDDEN_FILE = path.join(HERE, 'build', 'hidden.json');
const HIDDEN = fs.existsSync(HIDDEN_FILE) ? JSON.parse(fs.readFileSync(HIDDEN_FILE, 'utf8')) : {};
const BAKED_FILE = path.join(HERE, 'build', 'baked.json');
const BAKED = fs.existsSync(BAKED_FILE) ? JSON.parse(fs.readFileSync(BAKED_FILE, 'utf8')) : {};
// Texts that must stay narrower than their Figma box (the black half on Any mood). The bell
// on Reminders sits next to the headline's first line only, so those translations keep line 1 short.
const NARROW = { 'Light, Dark or System mode': 0.8 };
// Labels that Figma centres through their parent's auto layout (the text layer itself says
// LEFT): grow them evenly to both sides. Pills (All / Any time / …) are detected by size.
const WEEKDAYS = new Set(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
const CENTERED = new Set(['Habit details', 'March 2026', 'Settings', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Light', 'Dark', 'System',
  'Home', 'Habits', 'Calendar', 'Profile', 'Strength']);
// Behind the enlarged reminder card: the phone's own rows peek out next to it.
const ALSO_HIDDEN = { '284:60071': ['Daily reminders', 'Edit habit in the past'], '287:64557': ['Daily reminders', 'Edit habit in the past'] };
// "Mark as complete" chip, redrawn around each translation (iOS geometry in px at the
// chip's 42.52px text; Play is the same component scaled). Measured from the export.
const CHIP = { fontPx: 42.52, top: -33, height: 123, padL: 48, icon: 72, gap: 31, padR: 48 };
const CHECK_ON = fs.readFileSync(path.join(HERE, '..', '..', 'assets', 'images', 'new-svg', 'check-on-light.svg'), 'utf8');
const WEIGHT = { Regular: 400, Medium: 500, Bold: 700, Black: 900, Light: 300 };
const css = (c) => `rgba(${Math.round(c[0] * 255)},${Math.round(c[1] * 255)},${Math.round(c[2] * 255)},${c[3]})`;

// The tilted "Mark as complete" chip: white pill, the app's check-on icon, text in the chip's
// green; it grows or shrinks with the translation (left edge fixed, like the design).
function chipHtml(it, lang) {
  const [, , , size, color] = it.segs[0];
  const k = size / CHIP.fontPx;
  const [a, b, c, d, e, f] = it.tf;
  const left = -(CHIP.padL + CHIP.icon + CHIP.gap) * k;
  const icon = CHECK_ON.replace('<svg ', `<svg style="width:${CHIP.icon * k}px;height:${CHIP.icon * k}px;flex:none" `);
  return `<div style="position:absolute;left:0;top:0;transform:matrix(${a},${b},${c},${d},${e},${f});transform-origin:0 0">` +
    `<div style="position:absolute;left:${left}px;top:${CHIP.top * k}px;height:${CHIP.height * k}px;box-sizing:border-box;padding:0 ${CHIP.padR * k}px 0 ${CHIP.padL * k}px;` +
    `display:flex;align-items:center;gap:${CHIP.gap * k}px;background:#fff;border-radius:${CHIP.height * k / 2}px;box-shadow:0 ${10 * k}px ${30 * k}px rgba(0,0,0,0.12);white-space:nowrap;` +
    `font-family:'Satoshi Variable','Satoshi',sans-serif;font-weight:500;font-size:${size}px;color:${css(color)}">${icon}<span>${htmlText(tr(it.k, lang))}</span></div></div>\n`;
}

function figmaHtml(fid, lang) {
  const F = FIG[fid];
  const base = `base/${fid.replace(':', '-')}.png`;
  const masks = F.masks;
  // Some layers point at a helper mask with no shape. On the Any mood frames the light and
  // dark phones share positions and the dark copy paints later, so the first copy of a
  // text is outside the diagonal mask and the second is inside it.
  const shaped = masks.findIndex((m) => m.path);
  if (shaped >= 0) {
    const seen = new Set();
    F.items = F.items.map((it) => {
      const key = `${it.k}|${Math.round(it.tf[4] / 20)}|${Math.round(it.tf[5] / 20)}`;
      const dup = seen.has(key); seen.add(key);
      return it.mask && !masks[it.mask[1]].path ? { ...it, mask: [dup ? 'in' : 'out', shaped] } : it;
    });
  }
  let body = '', maskSeq = 0;
  const skip = new Set(HIDDEN[fid] || []);
  const alsoHidden = new Set(ALSO_HIDDEN[fid] || []);
  for (const it of F.items) {
    if (skip.has(it.id) || alsoHidden.has(it.k)) continue;
    if (it.k === 'Mark as complete') { body += chipHtml(it, lang); continue; }
    const [s0] = it.segs; // all store texts are single-style
    const [, , font, size, color, ls, lh, tc] = s0;
    const [fam, style] = font.split('|');
    const weight = WEIGHT[style] ?? 400;
    const lineH = lh.unit === 'PIXELS' ? `${lh.value}px` : lh.unit === 'PERCENT' ? `${lh.value / 100}` : 'normal';
    const letter = ls.unit === 'PERCENT' ? `${(ls.value / 100) * size}px` : `${ls.value}px`;
    const text = htmlText(tr(it.k, lang));
    const ha = { LEFT: 'left', CENTER: 'center', RIGHT: 'right', JUSTIFIED: 'justify' }[it.ha];
    const [a, b, c, d, e, f] = it.tf;
    const rotated = Math.abs(b) > 1e-3;
    const wrap = it.ar === 'HEIGHT' || it.ar === 'NONE';
    // Box: wrapped texts keep their width and height. Single-line texts may grow into the
    // free space next to them (aL..aR, frame coords) before shrinking.
    let boxL = 0, boxW = it.w * (NARROW[it.k] ?? 1), maxW = boxW;
    // centred by its parent: named above, or a label filling most of a small pill
    const inPill = it.aL != null && (it.aR - it.aL) < it.w * 2.2 && Math.abs((it.aL + it.aR) / 2 - (e + it.w / 2)) < 10;
    const centered = !wrap && !rotated && (ha === 'center' || CENTERED.has(it.k) || inPill);
    if (!wrap && NARROW[it.k]) { maxW = it.w; boxW = it.w; } // auto-width but hemmed in: no growth
    else if (!wrap) {
      if (rotated || it.aL == null) { maxW = it.w * 1.25; boxL = ha === 'center' ? -(maxW - it.w) / 2 : ha === 'right' ? -(maxW - it.w) : 0; boxW = maxW; }
      else {
        const x0 = e, x1 = e + it.w;
        if (centered) { const half = Math.max(it.w / 2, Math.min(x0 + it.w / 2 - it.aL, it.aR - (x0 + it.w / 2))); maxW = half * 2; boxL = it.w / 2 - half; }
        else if (ha === 'right') { maxW = Math.max(it.w, x1 - it.aL); boxL = it.w - maxW; }
        else { maxW = Math.max(it.w, it.aR - x0); boxL = 0; }
        boxW = maxW;
      }
      // weekday labels sit in tight day circles / columns: centred, up to 1.6× the English width
      if (WEEKDAYS.has(it.k)) { maxW = it.w * 1.6; boxL = -(maxW - it.w) / 2; boxW = maxW; }
    }
    const just = centered ? 'center' : ha === 'right' ? 'flex-end' : 'flex-start';
    // single-line app labels end in "…" like the app; headlines shrink to fit instead
    const ellipsis = !wrap && !it.k.includes('\n') && size < 60;
    const textStyle = `font-family:'${fam}','Satoshi',sans-serif;font-weight:${weight};font-size:${size}px;line-height:${lineH};letter-spacing:${letter};color:${css(color)};text-align:${ha};` +
      (tc === 'UPPER' ? 'text-transform:uppercase;' : '') + (wrap ? 'white-space:pre-wrap;overflow-wrap:break-word;' : 'white-space:nowrap;');
    // English text left in the base (baked.py): cover it with the colour around it first
    const patch = BAKED[fid]?.[it.id] && lang !== 'en' ? `<div style="position:absolute;left:-3px;top:-2px;width:${it.w + 6}px;height:${it.h + 4}px;background:rgb(${BAKED[fid][it.id].join(',')})"></div>` : '';
    let el = `<div style="position:absolute;left:0;top:0;width:${it.w}px;height:${it.h}px;transform:matrix(${a},${b},${c},${d},${e},${f});transform-origin:0 0;opacity:${it.op}">${patch}` +
      `<div style="position:absolute;left:${boxL}px;top:0;width:${boxW}px;height:${it.h}px;display:flex;align-items:${wrap ? 'flex-start' : 'center'};justify-content:${just}">` +
      (ellipsis
        // labels in pills / day circles shrink a little first (the app would grow the shape)
        ? `<div ${inPill || it.w < 3 * size ? `data-fit data-min="0.75" data-maxh="${it.h * 2}" data-maxw="${maxW}" ` : ''}style="${textStyle}max-width:${maxW}px;overflow:hidden;text-overflow:ellipsis">${text}</div></div></div>`
        : `<div data-fit data-maxh="${wrap ? it.h + 2 : it.h * 1.15}" ${wrap ? '' : `data-maxw="${maxW}"`} style="${textStyle}${wrap ? `width:${boxW}px;` : ''}">${text}</div></div></div>`);
    // clip to clipping ancestors, then to the mask (inside it, or outside it)
    const [cx, cy, cw, ch] = it.clip;
    if (it.mask && masks[it.mask[1]]?.path) {
      // Figma mask group: 'in' = text is inside the masked group (show only inside the
      // mask shape); 'out' = a masked group is painted over the text (hide inside it).
      const m = masks[it.mask[1]];
      const shape = `<path transform="matrix(${m.tf.join(',')})" d="${m.path}"`;
      const id = `m${(maskSeq += 1)}`;
      const fillIn = it.mask[0] === 'in' ? '#fff' : '#000', fillOut = it.mask[0] === 'in' ? '#000' : '#fff';
      body += `<svg width="0" height="0" style="position:absolute"><defs><mask id="${id}" maskUnits="userSpaceOnUse" x="0" y="0" width="${F.w}" height="${F.h}">` +
        `<rect width="${F.w}" height="${F.h}" fill="${fillOut}"/>${shape} fill="${fillIn}"/></mask></defs></svg>`;
      el = `<div style="position:absolute;left:0;top:0;width:${F.w}px;height:${F.h}px;mask:url(#${id});-webkit-mask:url(#${id})">${el}</div>`;
    }
    body += `<div style="position:absolute;left:${cx}px;top:${cy}px;width:${cw}px;height:${ch}px;overflow:hidden"><div style="position:absolute;left:${-cx}px;top:${-cy}px;width:${F.w}px;height:${F.h}px">${el}</div></div>\n`;
  }
  return `<!doctype html><html lang="${lang}"><head><meta charset="utf-8"><style>${FONT_FACES}
html,body{margin:0;background:#fff}#f{position:relative;width:${F.w}px;height:${F.h}px;overflow:hidden;background:url("${url(base)}") 0 0/100% 100%}</style></head>
<body><div id="f">${body}</div>${FIT_SCRIPT}</body></html>`;
}

// ─── Run ─────────────────────────────────────────────────────────────────────
// Figma exports keep the frame name ("… [284:22055] text-hidden.png", the ":" may come out
// as another character); rename them to base/<id>.png.
const BASE = path.join(HERE, 'base');
fs.mkdirSync(BASE, { recursive: true });
for (const f of fs.readdirSync(BASE)) {
  const m = /\[(\d+)\D(\d+)\]/.exec(f);
  if (m && f.endsWith('.png')) fs.renameSync(path.join(BASE, f), path.join(BASE, `${m[1]}-${m[2]}.png`));
}
const missingBase = FIG ? [...IOS_FIGMA, ...PLAY_FIGMA].filter(([fid]) => !fs.existsSync(path.join(HERE, 'base', fid.replace(':', '-') + '.png'))) : [];
if (!FIG || missingBase.length) console.warn(`Figma images skipped: missing ${FIG ? missingBase.map((m) => 'base/' + m[0].replace(':', '-') + '.png').join(', ') : 'figma_text.json'}`);
const figOk = FIG && !missingBase.length;

for (const lang of LANGS) {
  for (const [store, figma, order] of [['ios', IOS_FIGMA, IOS_ORDER], ['android', PLAY_FIGMA, PLAY_ORDER]]) {
    order.forEach((item, i) => {
      const n = String(i + 1).padStart(2, '0');
      if (item.startsWith('slide:')) {
        const name = item.slice(6); const { W, H } = STORES[store];
        shoot(slidePage(name, store, lang, tr, FONT_FACES, FIT_SCRIPT), path.join(OUT, store, lang, `${n}_${name.toLowerCase()}.png`), W, H);
      } else if (figOk) {
        const [fid] = figma.find(([, nm]) => nm === item);
        const F = FIG[fid];
        shoot(figmaHtml(fid, lang), path.join(OUT, store, lang, `${n}_${item}.png`), F.w, F.h);
      }
    });
    console.log(lang, store, 'done');
  }
}

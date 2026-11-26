// The 6 extra store slides (Private, Health, Health Connect, Themes, Apple Watch, Wear OS),
// built on the Figma frames' tokens so they sit next to the 5 Figma images:
//  - frame: white, inner card inset 30px (iOS 1290×2796) / 20px (Play 1080×1920),
//    radius 90 / 70, green #02CB7D→#02BB72 or grey #F4F4F4
//  - headline Satoshi Bold 150 / 100 at x 100 / 80, y 130 / 80; subtitle Regular 70 / 60
//  - app UI (habit cards, pills) drawn like the app: Medium titles, Regular grey subtitles
//    with the clock icon, the app's own check-on / check-off / progress pie.
// Each slide's content block is designed once at 1230px wide and scaled to fit the room
// left under the headline on each store.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const APP = path.join(HERE, '..', '..', 'assets', 'images');
const url = (p) => pathToFileURL(p).href;
const svg = (p) => fs.readFileSync(path.join(APP, p), 'utf8');

export const STORES = {
  ios: { W: 1290, H: 2796, inset: 30, radius: 90, x: 100, y: 130, hw: 1090, head: 150, sub: 70, gap: 90, bottom: 110 },
  android: { W: 1080, H: 1920, inset: 20, radius: 70, x: 80, y: 80, hw: 920, head: 100, sub: 60, gap: 40, bottom: 70 },
};
const GREEN = '#02D382', INK = '#0D0D0D', GREY = '#A4A7AE';

// ─── App pieces ──────────────────────────────────────────────────────────────
const sized = (s, px, extra = '') => s.replace('<svg ', `<svg style="width:${px}px;height:${px}px;flex:none;display:block${extra}" `);
const recolor = (s, c) => s.replaceAll('#02D382', c);
const CHECK_ON = svg('new-svg/check-on-light.svg'), CHECK_OFF = svg('new-svg/check-off-light.svg'), CLOCK = svg('new-svg/clock.svg');

// the app's progress pie (new_habit_progress.dart): wedge from 12 o'clock + 2px ring at 20%
function pie(p, px, color = GREEN) {
  const a = p * 2 * Math.PI, x = 12 + 12 * Math.sin(a), y = 12 - 12 * Math.cos(a);
  return `<svg viewBox="0 0 24 24" style="width:${px}px;height:${px}px;flex:none;display:block"><path d="M12 12 L12 0 A12 12 0 ${p > 0.5 ? 1 : 0} 1 ${x.toFixed(2)} ${y.toFixed(2)} Z" fill="${color}"/>` +
    `<circle cx="12" cy="12" r="11" fill="none" stroke="${color}" stroke-opacity="0.2" stroke-width="2"/></svg>`;
}
const progressIcon = (state, px, color) => state === 'done' ? sized(recolor(CHECK_ON, color), px) : state === 'off' ? sized(CHECK_OFF, px) : pie(state, px, color);

// a habit card as in the Figma "Track habits" frame (235px tall at iOS scale). Corner radius
// follows new_habit_widget.dart: 24 on a 76px card → 74 at this scale.
export function habitCard({ icon, title, sub, state, w = 1070, k = 1, color = GREEN, tint, rot = 0, t }) {
  const done = state === 'done';
  const bg = done ? (tint ?? '#E6FAF2') : '#fff';
  const border = done ? (color === GREEN ? '#C8F2DF' : color + '55') : '#EFEFEF';
  return `<div style="width:${w * k}px;height:${235 * k}px;box-sizing:border-box;padding:0 ${48 * k}px 0 ${47 * k}px;border-radius:${74 * k}px;background:${bg};border:${3 * k}px solid ${border};` +
    `box-shadow:0 ${14 * k}px ${44 * k}px rgba(0,0,0,0.07);display:flex;align-items:center;gap:${44 * k}px;transform:rotate(${rot}deg)">` +
    `<div style="width:${132 * k}px;height:${132 * k}px;flex:none;border-radius:50%;background:${done ? '#fff' : '#F3F3F3'};display:flex;align-items:center;justify-content:center">` +
    `<img src="${icon}" style="width:${72 * k}px;height:${72 * k}px"></div>` +
    `<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:${22 * k}px">` +
    `<div style="font-weight:500;font-size:${50 * k}px;color:${INK};white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${t(title)}</div>` +
    `<div style="display:flex;align-items:center;gap:${18 * k}px;font-size:${41 * k}px;color:${GREY};white-space:nowrap;min-width:0">${sized(CLOCK, 41 * k)}<span style="overflow:hidden;text-overflow:ellipsis">${t(sub)}</span></div></div>` +
    `${progressIcon(state, 76 * k, color)}</div>`;
}

// a white pill with an icon in a soft circle (watch features, promises)
function pill({ iconSvg, text, w, h = 150, bg = '#fff', fg = INK, iconBg = '#E6FAF2', rot = 0, size = 44, t, lines = 2 }) {
  return `<div style="width:${w}px;height:${h}px;box-sizing:border-box;padding:0 ${h * 0.24}px 0 ${(h - 96) / 2}px;border-radius:${h / 2}px;background:${bg};` +
    `box-shadow:0 14px 44px rgba(0,0,0,0.08);display:flex;align-items:center;gap:26px;transform:rotate(${rot}deg)">` +
    `<div style="width:96px;height:96px;flex:none;border-radius:50%;background:${iconBg};display:flex;align-items:center;justify-content:center">${iconSvg}</div>` +
    `<div style="flex:1;min-width:0;font-weight:500;font-size:${size}px;line-height:1.2;color:${fg}"><span data-fit data-en="${esc(t.en(text))}" data-lines="${lines}" style="display:block">${t(text)}</span></div></div>`;
}
const strokeIcon = (d, color = GREEN, px = 52, sw = 2.2) => `<svg width="${px}" height="${px}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${d}</svg>`;
const ICON = {
  lock: '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  offline: '<path d="M2 8.8a15 15 0 0 1 20 0"/><path d="M5 12.5a10 10 0 0 1 14 0"/><path d="M8.5 16a5 5 0 0 1 7 0"/><path d="M12 19.5h.01"/><path d="M3 3l18 18"/>',
  noAccount: '<circle cx="9" cy="8" r="4"/><path d="M2 21v-1a6 6 0 0 1 6-6h2"/><path d="M16 15l5 5M21 15l-5 5"/>',
  shield: '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M8.5 12l2.5 2.5L15.5 10"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  crown: '<rect x="7" y="4" width="10" height="16" rx="3"/><path d="M10 8h4M10 12h4M10 16h4"/>',
  sync: '<path d="M20 11a8 8 0 0 0-14.3-4.9L4 8"/><path d="M4 4v4h4"/><path d="M4 13a8 8 0 0 0 14.3 4.9L20 16"/><path d="M20 20v-4h-4"/>',
};
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const HI = (n) => url(path.join(APP, 'health-icons', n));

// ─── Slides ──────────────────────────────────────────────────────────────────
// Each returns { bg, head, sub, subLines, content, ch } — content is 1230px wide, ch tall.
export const SLIDES = {
  Main: (store, t) => {
    const cards = [
      { icon: HI('mindfullnes.png'), title: 'Morning meditation', sub: '10 min', state: 'done', rot: -3 },
      { icon: HI('steps.png'), title: 'Walk', sub: '8,420 / 10,000 steps', state: 0.84, rot: 2.5 },
      { icon: HI('workout.png'), title: 'Workout', sub: '25 / 45 min', state: 0.55, rot: -2 },
    ];
    const rows = [['lock', 'Stays on your device'], ['offline', 'Works offline'], ['noAccount', 'No account'], ['shield', 'Encrypted backup']];
    return {
      bg: 'green', head: 'Private.\nOffline.\nNo account.', sub: 'No ads, no tracking. Your habits stay on your device.', subLines: 2, ch: 1480,
      content: `<div style="position:absolute;left:0;top:0;width:1230px;height:700px;filter:blur(9px);opacity:0.95">` +
        cards.map((c, i) => `<div style="position:absolute;left:${80 + (i % 2) * 40}px;top:${30 + i * 220}px">${habitCard({ ...c, w: 1030, t })}</div>`).join('') + `</div>` +
        `<div style="position:absolute;left:355px;top:90px;width:520px;height:520px;border-radius:50%;background:rgba(255,255,255,0.22)"></div>` +
        `<div style="position:absolute;left:430px;top:165px;width:370px;height:370px;border-radius:50%;background:#fff;box-shadow:0 30px 90px rgba(0,0,0,0.25);display:flex;align-items:center;justify-content:center">${strokeIcon(ICON.lock, '#02BB72', 190, 1.7)}</div>` +
        `<div style="position:absolute;left:70px;top:790px;width:1090px;display:flex;flex-direction:column;gap:24px">` +
        rows.map(([ic, txt]) => `<div style="height:150px;box-sizing:border-box;padding:0 44px 0 27px;border-radius:75px;background:#fff;display:flex;align-items:center;gap:32px">` +
          `<div style="width:96px;height:96px;flex:none;border-radius:50%;background:#E6FAF2;display:flex;align-items:center;justify-content:center">${strokeIcon(ICON[ic], '#02BB72', 52)}</div>` +
          `<div style="font-weight:500;font-size:52px;color:${INK};white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${t(txt)}</div></div>`).join('') + `</div>`,
    };
  },

  Health: (store, t, source = 'Apple Health') => {
    const all = [
      { icon: HI('steps.png'), title: 'Steps', sub: '8,420 / 10,000 steps', state: 0.84, rot: -2.5 },
      { icon: HI('sleep.png'), title: 'Sleep', sub: '7h 30m / 8h', state: 0.94, rot: 2 },
      { icon: HI('workout.png'), title: 'Exercise', sub: '25 / 30 min', state: 0.83, rot: -1.5 },
      { icon: HI('mindfullnes.png'), title: 'Mindful minutes', sub: '10 / 10 min', state: 'done', rot: 2.5 },
      { icon: HI('burned_calories.png'), title: 'Active calories', sub: '312 / 500 kcal', state: 0.62, rot: -2 },
    ];
    const cards = store === 'ios' ? all : all.slice(0, 4);
    const logo = source === 'Apple Health' ? url(path.join(APP, 'widget-images', 'apple-health.svg')) : url(path.join(APP, 'widget-images', 'health-connect.png'));
    const top = cards.length * 245 + 40;
    return {
      bg: 'grey', head: source === 'Apple Health' ? 'Syncs with\nApple Health' : 'Syncs with\nHealth Connect',
      sub: 'Link a habit to steps, sleep, exercise or mindful minutes and it fills itself in.', subLines: 3, ch: top + 470,
      content: cards.map((c, i) => `<div style="position:absolute;left:${80 + (i % 2) * 30}px;top:${i * 245}px">${habitCard({ ...c, w: 1040, t })}</div>`).join('') +
        `<div style="position:absolute;left:80px;top:${top}px;width:1070px;height:210px;box-sizing:border-box;padding:0 48px 0 40px;border-radius:105px;background:#fff;border:3px solid #EFEFEF;display:flex;align-items:center;gap:40px">` +
        `<img src="${logo}" style="width:132px;height:132px;flex:none;border-radius:30px">` +
        `<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:18px"><div style="font-weight:500;font-size:52px;color:${INK};white-space:nowrap">${t(source)}</div>` +
        `<div style="font-size:41px;color:${GREY};white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${t('Synced just now')}</div></div>${sized(CHECK_ON, 76)}</div>` +
        `<div style="position:absolute;left:80px;top:${top + 240}px;width:1070px;height:210px;box-sizing:border-box;padding:0 48px 0 40px;border-radius:105px;background:${INK};display:flex;align-items:center;gap:40px">` +
        `<div style="width:132px;height:132px;flex:none;border-radius:50%;background:#1E3A2D;display:flex;align-items:center;justify-content:center">${strokeIcon(ICON.lock, '#5EE0A6', 68, 1.9)}</div>` +
        `<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:18px"><div style="font-weight:500;font-size:52px;color:#fff;white-space:nowrap">${t('Read-only')}</div>` +
        `<div style="font-size:41px;color:#B7D6C6;line-height:1.2"><span data-fit data-en="${esc(t.en('Your health data stays on your phone.'))}" data-lines="2" style="display:block">${t('Your health data stays on your phone.')}</span></div></div></div>`,
    };
  },
  HealthConnect: (store, t) => SLIDES.Health(store, t, 'Health Connect'),

  // the earlier canvas layout (scattered 560px cards, soft colour glows), with app pieces
  Themes: (store, t) => {
    const themes = [['Habitt', '#02D382', 36, 70, -3], ['Lagoon', '#00CBCE', 628, 0, 3], ['Ocean', '#09A3FD', 70, 660, 2],
      ['Indigo', '#5D73EA', 596, 590, -3], ['Violet', '#955FD8', 34, 1250, -2], ['Orchid', '#DA62B7', 632, 1190, 4]];
    // habit row inside a theme card: 164px tall (app card ×2.16, so radius 24 → 52)
    const row = (title, sub, state, c, done) => `<div style="display:flex;align-items:center;gap:26px;height:164px;box-sizing:border-box;padding:0 30px;border-radius:52px;` +
      (done ? `background:${c}26;border:3px solid ${c}66` : 'background:#fff;box-shadow:0 4px 24px rgba(0,0,0,0.08)') + `">` +
      `<div style="width:104px;height:104px;flex:none;border-radius:50%;background:${done ? '#fff' : '#F3F3F3'};display:flex;align-items:center;justify-content:center"><img src="${HI(done ? 'workout.png' : 'sleep.png')}" style="width:62px;height:62px"></div>` +
      `<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:8px"><div style="font-weight:500;font-size:40px;color:${INK};white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${t(title)}</div>` +
      `<div style="display:flex;align-items:center;gap:10px;font-size:29px;color:${GREY};white-space:nowrap">${sized(CLOCK, 29)}<span style="overflow:hidden;text-overflow:ellipsis">${t(sub)}</span></div></div>` +
      `${progressIcon(state, 72, c)}</div>`;
    return {
      bg: 'grey', head: 'Make it\nyours', sub: 'Six accent themes, free for everyone.', subLines: 2, ch: 1780,
      content: `<div style="position:absolute;left:-180px;top:390px;width:620px;height:620px;border-radius:50%;background:#09A3FD;opacity:0.16;filter:blur(40px)"></div>` +
        `<div style="position:absolute;left:810px;top:-90px;width:620px;height:620px;border-radius:50%;background:#DA62B7;opacity:0.16;filter:blur(40px)"></div>` +
        `<div style="position:absolute;left:300px;top:1400px;width:700px;height:700px;border-radius:50%;background:#02D382;opacity:0.16;filter:blur(40px)"></div>` +
        themes.map(([name, c, left, top, rot]) => `<div style="position:absolute;left:${left}px;top:${top}px;width:560px;box-sizing:border-box;padding:40px;border-radius:64px;background:#fff;box-shadow:0 24px 64px rgba(0,0,0,0.12);transform:rotate(${rot}deg);display:flex;flex-direction:column;gap:22px">` +
          `<div style="display:flex;align-items:center;gap:22px;padding-bottom:6px"><div style="width:44px;height:44px;border-radius:50%;background:${c}"></div><div style="font-weight:700;font-size:54px;color:${INK};line-height:1">${t(name)}</div></div>` +
          row('Workout', '45 min', 'done', c, true) + row('Sleep', '6h / 8h', 0.62, c, false) + `</div>`).join(''),
    };
  },

  Watch: (store, t, wear = false) => {
    const W = (k) => url(path.join(HERE, 'build', 'watch', t.lang, `${k}.png`));
    const feats = [['check', 'Tap to check off'], ['crown', wear ? 'Turn the crown\nto log' : 'Turn the Digital\nCrown to log'], ['sync', wear ? 'Syncs with\nyour phone' : 'Syncs with\nyour iPhone']];
    const streak = fs.readFileSync(path.join(APP, 'new-svg', 'streak.svg'), 'utf8');
    return {
      bg: 'grey', head: 'Habits on\nyour wrist', sub: wear ? 'Check off, log and keep your streak from your Wear OS watch.' : 'Check off, log and keep your streak from Apple Watch.', subLines: 3, ch: 1800,
      content: (wear
        ? `<img src="${W('wear_today')}" style="position:absolute;left:-10px;top:0;width:640px;height:970px"><img src="${W('wear_log')}" style="position:absolute;left:600px;top:860px;width:600px;height:900px">`
        : `<img src="${W('aw_today')}" style="position:absolute;left:10px;top:20px;width:616px;height:968px"><img src="${W('aw_log')}" style="position:absolute;left:540px;top:760px;width:682px;height:1034px">`) +
        feats.map(([ic, txt], i) => `<div style="position:absolute;left:${640 + [0, -8, 8][i]}px;top:${130 + i * 200}px">${pill({ iconSvg: strokeIcon(ICON[ic], '#02BB72', 52, 2.4), text: txt, w: 550, rot: [2, -2, 1.5][i], t })}</div>`).join('') +
        `<div style="position:absolute;left:40px;top:1090px">${pill({ iconSvg: sized(streak, 60), text: '12 day streak', w: 480, bg: '#FFB01F', iconBg: '#FFDEB2', rot: -2, t })}</div>` +
        `<div style="position:absolute;left:56px;top:1290px">${pill({ iconSvg: sized(CHECK_ON, 66), text: 'Day complete', w: 480, bg: '#021911', fg: '#fff', iconBg: '#1E3A2D', rot: 2, t })}</div>`,
    };
  },
  WearOS: (store, t) => SLIDES.Watch(store, t, true),
};

// ─── Page ────────────────────────────────────────────────────────────────────
export function slidePage(name, store, lang, tr, FONT_FACES, FIT_SCRIPT) {
  const S = STORES[store];
  const html = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\r/g, '').replace(/\n/g, '<br>');
  const t = (en) => html(tr(en, lang)); t.en = (en) => html(en); t.lang = lang;
  const s = SLIDES[name](store, t);
  const green = s.bg === 'green';
  const fg = green ? '#fff' : INK, fg2 = green ? 'rgba(255,255,255,0.9)' : 'rgba(0,0,0,0.6)';
  const inner = { w: S.W - 2 * S.inset, h: S.H - 2 * S.inset };
  return `<!doctype html><html lang="${lang}"><head><meta charset="utf-8"><style>${FONT_FACES}
html,body{margin:0;background:#fff}
#f{position:relative;width:${S.W}px;height:${S.H}px;overflow:hidden;background:#fff;font-family:'Satoshi Variable','Satoshi',sans-serif}
#c{position:absolute;left:${S.inset}px;top:${S.inset}px;width:${inner.w}px;height:${inner.h}px;border-radius:${S.radius}px;overflow:hidden;background:${green ? 'linear-gradient(180deg,#02CB7D 0%,#02CB7D 35%,#02BB72 100%)' : '#F4F4F4'}}
#top{position:absolute;left:${S.x - S.inset}px;top:${S.y - S.inset}px;width:${S.hw}px}
#top h1{margin:0;text-wrap:balance;font-weight:700;font-size:${S.head}px;line-height:normal;color:${fg}}
#top p{margin:${S.gap}px 0 0;text-wrap:balance;font-weight:400;font-size:${S.sub}px;line-height:normal;color:${fg2}}
#box{position:absolute;left:0;width:1230px;height:${s.ch}px;transform-origin:0 0}
</style></head><body><div id="f"><div id="c">
<div id="top"><h1><span data-fit data-en="${esc(t.en(s.head))}" style="display:block">${t(s.head)}</span></h1>` +
    `<p><span data-fit data-en="${esc(t.en(s.sub))}" data-lines="${s.subLines}" style="display:block">${t(s.sub)}</span></p></div>
<div id="box">${s.content}</div></div></div>
${FIT_SCRIPT}
<script>
// once the text is fitted: scale the content block into the room under the headline
(function place(){ if (!document.body.dataset.done) return requestAnimationFrame(place);
  const c = document.getElementById('c'), top = document.getElementById('top'), box = document.getElementById('box');
  const y0 = top.offsetTop + top.offsetHeight + ${S.gap}, room = c.clientHeight - y0 - ${S.bottom};
  const k = Math.min(c.clientWidth / 1230, room / ${s.ch});
  box.style.transform = 'translate(' + ((c.clientWidth - 1230 * k) / 2) + 'px,' + (y0 + (room - ${s.ch} * k) / 2) + 'px) scale(' + k + ')';
  document.body.dataset.placed = '1';
})();
</script></body></html>`;
}

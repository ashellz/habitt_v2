// Habitt landing page interactions. No dependencies, no tracking.
(function () {
  "use strict";

  var root = document.documentElement;
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var $ = function (s, el) { return (el || document).querySelector(s); };
  var $$ = function (s, el) { return Array.prototype.slice.call((el || document).querySelectorAll(s)); };

  // ─── Theme ─────────────────────────────────────────────

  var systemDark = window.matchMedia("(prefers-color-scheme: dark)");

  function isDark() {
    var t = root.getAttribute("data-theme");
    return t ? t === "dark" : systemDark.matches;
  }

  // Swap every theme-aware screenshot to its light or dark variant.
  function syncScreens() {
    var dark = isDark();
    $$("img[data-light]").forEach(function (img) {
      var src = dark && img.dataset.dark ? img.dataset.dark : img.dataset.light;
      if (img.getAttribute("src") !== src) img.setAttribute("src", src);
    });
    syncStoryScreen(true);
  }

  $("#themeToggle").addEventListener("click", function () {
    var next = isDark() ? "light" : "dark";
    root.setAttribute("data-theme", next);
    try { localStorage.setItem("habitt-theme", next); } catch (e) {}
    syncScreens();
  });
  systemDark.addEventListener("change", function () {
    if (!root.getAttribute("data-theme")) syncScreens();
  });

  // ─── Nav: mobile menu, hide on scroll, progress bar ────

  var nav = $("#nav");
  var menuBtn = $("#menuBtn");
  menuBtn.addEventListener("click", function () {
    var open = nav.classList.toggle("open");
    menuBtn.setAttribute("aria-expanded", open ? "true" : "false");
    document.body.style.overflow = open ? "hidden" : "";
  });
  $$("#mobileMenu a").forEach(function (a) {
    a.addEventListener("click", function () {
      nav.classList.remove("open");
      menuBtn.setAttribute("aria-expanded", "false");
      document.body.style.overflow = "";
    });
  });

  var progress = $(".progress");
  var lastY = 0;
  function onScroll() {
    var y = window.scrollY;
    var max = document.documentElement.scrollHeight - window.innerHeight;
    progress.style.setProperty("--p", max > 0 ? (y / max).toFixed(4) : 0);
    if (!nav.classList.contains("open")) {
      nav.style.transform = y > lastY && y > 400 ? "translateY(-120%)" : "";
    }
    lastY = y;
  }
  window.addEventListener("scroll", onScroll, { passive: true });

  // ─── Split headings into words for the reveal ──────────

  $$(".split").forEach(function (el) {
    var i = 0;
    (function walk(node) {
      Array.prototype.slice.call(node.childNodes).forEach(function (child) {
        if (child.nodeType === 3) {
          var frag = document.createDocumentFragment();
          child.textContent.split(/(\s+)/).forEach(function (part) {
            if (!part) return;
            if (/^\s+$/.test(part)) { frag.appendChild(document.createTextNode(part)); return; }
            var w = document.createElement("span");
            w.className = "w";
            var inner = document.createElement("span");
            inner.textContent = part;
            inner.style.setProperty("--i", i++);
            w.appendChild(inner);
            frag.appendChild(w);
          });
          child.parentNode.replaceChild(frag, child);
        } else if (child.nodeType === 1) {
          walk(child);
        }
      });
    })(el);
  });

  // ─── Reveal on scroll ──────────────────────────────────

  var revealObs = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (!e.isIntersecting) return;
      e.target.classList.add("in");
      revealObs.unobserve(e.target);
    });
  }, { rootMargin: "0px 0px -10% 0px", threshold: 0.12 });
  $$(".reveal, .split, .heatmap, .notifs").forEach(function (el) {
    if (!el.closest(".hero")) revealObs.observe(el);
  });

  // ─── Count-up numbers ──────────────────────────────────

  function countUp(el) {
    var target = parseFloat(el.dataset.count);
    var suffix = el.dataset.suffix || "";
    if (reduceMotion || target === 0) { el.textContent = target + suffix; return; }
    var start = performance.now();
    var dur = 1400;
    (function tick(now) {
      var t = Math.min(1, (now - start) / dur);
      var eased = 1 - Math.pow(1 - t, 3);
      el.textContent = Math.round(target * eased) + suffix;
      if (t < 1) requestAnimationFrame(tick);
    })(start);
  }
  var countObs = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (!e.isIntersecting) return;
      countUp(e.target);
      countObs.unobserve(e.target);
    });
  }, { threshold: 0.6 });
  $$("[data-count]").forEach(function (el) { countObs.observe(el); });

  // ─── 3D tilt on pointer ────────────────────────────────

  var stage = $("#heroStage");
  if (stage && !reduceMotion && window.matchMedia("(pointer: fine)").matches) {
    var phones = $$(".phone", stage);
    var base = phones.map(function (p) {
      var cs = getComputedStyle(p);
      return { ry: parseFloat(cs.getPropertyValue("--ry")), rx: parseFloat(cs.getPropertyValue("--rx")) };
    });
    window.addEventListener("pointermove", function (ev) {
      var nx = ev.clientX / window.innerWidth - 0.5;
      var ny = ev.clientY / window.innerHeight - 0.5;
      phones.forEach(function (p, i) {
        var depth = i === 1 ? 1 : 0.6;
        p.style.setProperty("--ry", base[i].ry + nx * 14 * depth + "deg");
        p.style.setProperty("--rx", base[i].rx - ny * 10 * depth + "deg");
        p.style.setProperty("--tx", nx * -18 * depth + "px");
        p.style.setProperty("--ty", ny * -14 * depth + "px");
      });
    }, { passive: true });
  }

  // ─── Story: sticky phone follows the active step ───────

  var steps = $$(".step");
  var storyScreen = $("#storyScreen");
  var storyPhone = $("#storyPhone");
  var halo = $("#storyHalo");
  var activeStep = steps[0];

  function stepSrc(step) {
    return isDark() && step.dataset.dark ? step.dataset.dark : step.dataset.light;
  }

  function syncStoryScreen(instant) {
    if (!storyScreen || !activeStep) return;
    var src = stepSrc(activeStep);
    var current = storyScreen.querySelector("img:not(.out)");
    if (current && current.getAttribute("src") === src) return;
    var img = new Image();
    img.src = src;
    img.alt = "";
    img.width = 720;
    img.height = 1565;
    if (!instant) img.classList.add("out");
    storyScreen.appendChild(img);
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        img.classList.remove("out");
        $$("img", storyScreen).forEach(function (old) {
          if (old === img) return;
          old.classList.add("out");
          setTimeout(function () { old.remove(); }, 700);
        });
      });
    });
  }

  if (steps.length) {
    var stepObs = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        activeStep = e.target;
        syncStoryScreen(false);
        halo.style.setProperty("--halo", "color-mix(in srgb, " + activeStep.dataset.halo + " 38%, transparent)");
        var idx = steps.indexOf(activeStep);
        storyPhone.style.setProperty("--ry", (idx % 2 ? 10 : -10) + "deg");
        storyPhone.style.setProperty("--rz", (idx % 2 ? -1.5 : 1.5) + "deg");
        if (idx === 1) animateStrength();
      });
    }, { rootMargin: "-45% 0px -45% 0px" });
    steps.forEach(function (s) { stepObs.observe(s); });
  }

  // ─── Step 1: interactive habit cards ───────────────────

  var CONFETTI = ["#02d382", "#11f29b", "#ff9831", "#ffb764", "#2f8cff", "#ff6464"];

  function burst(el) {
    if (reduceMotion) return;
    var r = el.getBoundingClientRect();
    var cx = r.left + r.width / 2;
    var cy = r.top + r.height / 2;
    for (var i = 0; i < 22; i++) {
      var s = document.createElement("i");
      s.className = "spark";
      s.style.left = cx + "px";
      s.style.top = cy + "px";
      s.style.background = CONFETTI[i % CONFETTI.length];
      document.body.appendChild(s);
      var angle = Math.random() * Math.PI * 2;
      var dist = 50 + Math.random() * 70;
      s.animate([
        { transform: "translate(-50%,-50%) rotate(0)", opacity: 1 },
        { transform: "translate(" + (Math.cos(angle) * dist - 4) + "px," + (Math.sin(angle) * dist + 30) + "px) rotate(" + (Math.random() * 540) + "deg)", opacity: 0 }
      ], { duration: 800 + Math.random() * 400, easing: "cubic-bezier(.2,.8,.2,1)" }).onfinish = (function (n) { return function () { n.remove(); }; })(s);
    }
  }

  function setRing(card, ratio) {
    var fill = $(".fill", card);
    if (fill) fill.style.strokeDasharray = (ratio * 62.8).toFixed(1) + " 63";
  }

  function fmt(sec) {
    var m = Math.floor(sec / 60), s = sec % 60;
    return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
  }

  // Same completion sounds as the app: one for a habit, another when all are done.
  // Web Audio instead of <audio>: the timer card finishes from a setInterval, not a tap, and
  // browsers (Safari) only let an <audio> play there if that element was already started by a
  // tap. An AudioContext resumed by any earlier tap can play whenever.
  var SOUND_URLS = { habit: "assets/sound/completion.mp3", all: "assets/sound/completion_all.mp3" };
  var AudioCtx = window.AudioContext || window.webkitAudioContext;
  var audioCtx = null, buffers = {}, fallback = {};
  try { audioCtx = AudioCtx ? new AudioCtx() : null; } catch (e) {}
  Object.keys(SOUND_URLS).forEach(function (name) {
    fallback[name] = new Audio(SOUND_URLS[name]);
    if (!audioCtx) return;
    fetch(SOUND_URLS[name]).then(function (r) { return r.arrayBuffer(); }).then(function (data) {
      audioCtx.decodeAudioData(data, function (buf) { buffers[name] = buf; }, function () {});
    }).catch(function () {});
  });
  function unlockAudio() { if (audioCtx && audioCtx.state === "suspended") audioCtx.resume(); }
  ["pointerdown", "click", "touchend", "keydown"].forEach(function (ev) {
    document.addEventListener(ev, unlockAudio, { capture: true, passive: true });
  });
  function playSound(name) {
    try {
      if (audioCtx && buffers[name]) {
        unlockAudio();
        var src = audioCtx.createBufferSource();
        src.buffer = buffers[name];
        src.connect(audioCtx.destination);
        src.start(0);
        return;
      }
      var a = fallback[name];
      a.currentTime = 0;
      var p = a.play();
      if (p && p.catch) p.catch(function () {});
    } catch (e) {}
  }
  function celebrate(card) {
    burst(card);
    var cards = $$("#demoCards .habit-card");
    var allDone = cards.every(function (c) { return c.classList.contains("done"); });
    playSound(allDone ? "all" : "habit");
  }

  $$("#demoCards .habit-card").forEach(function (card) {
    var kind = card.dataset.kind;
    var timer = null;

    if (kind === "amount") setRing(card, card.dataset.amount / card.dataset.target);
    if (kind === "timer") setRing(card, card.dataset.sec / card.dataset.target);

    card.addEventListener("click", function () {
      if (kind === "check") {
        card.classList.toggle("done");
        if (card.classList.contains("done")) celebrate(card);
        return;
      }
      if (kind === "amount") {
        var a = parseInt(card.dataset.amount, 10), t = parseInt(card.dataset.target, 10);
        a = a >= t ? 0 : a + 1;
        card.dataset.amount = a;
        $(".count", card).textContent = a + " / " + t + " glasses";
        setRing(card, a / t);
        card.classList.toggle("done", a >= t);
        if (a >= t) celebrate(card);
        return;
      }
      if (kind === "timer") {
        var target = parseInt(card.dataset.target, 10);
        if (card.classList.contains("done")) {
          card.classList.remove("done");
          card.dataset.sec = 840;
          $(".count", card).textContent = fmt(840) + " / " + fmt(target);
          setRing(card, 840 / target);
          return;
        }
        if (timer) { clearInterval(timer); timer = null; $(".hint", card).textContent = "Tap to resume"; return; }
        $(".hint", card).textContent = "Running… tap to pause";
        // Fast-forwarded so the demo finishes in a few seconds.
        timer = setInterval(function () {
          var sec = Math.min(target, parseInt(card.dataset.sec, 10) + 15);
          card.dataset.sec = sec;
          $(".count", card).textContent = fmt(sec) + " / " + fmt(target);
          setRing(card, sec / target);
          if (sec >= target) {
            clearInterval(timer); timer = null;
            card.classList.add("done");
            $(".hint", card).textContent = "Tap to start timer";
            celebrate(card);
          }
        }, 60);
      }
    });
  });

  // ─── Step 2: strength ring ─────────────────────────────

  var strengthDone = false;
  function animateStrength() {
    if (strengthDone) return;
    strengthDone = true;
    var ring = $("#coachRing .f");
    var val = $("#strengthVal");
    if (!ring) return;
    ring.style.strokeDasharray = (0.96 * 251.3).toFixed(1) + " 252";
    var el = document.createElement("span");
    el.dataset.count = 96;
    countUp(el);
    var iv = setInterval(function () {
      val.textContent = el.textContent;
      if (el.textContent === "96") clearInterval(iv);
    }, 30);
  }
  // Also trigger when the ring itself scrolls in (mobile, no sticky phone).
  var coach = $("#coachRing");
  if (coach) {
    new IntersectionObserver(function (entries, obs) {
      if (entries[0].isIntersecting) { animateStrength(); obs.disconnect(); }
    }, { threshold: 0.6 }).observe(coach);
  }

  // ─── Step 3: heatmap ───────────────────────────────────

  var heat = $("#heatmap");
  if (heat) {
    var weeks = window.innerWidth < 560 ? 18 : 26;
    var seed = 7;
    var rnd = function () { seed = (seed * 9301 + 49297) % 233280; return seed / 233280; };
    var frag = document.createDocumentFragment();
    for (var w = 0; w < weeks; w++) {
      for (var d = 0; d < 7; d++) {
        var cell = document.createElement("i");
        // Consistency improves over time, like a real habit.
        var p = 0.35 + (w / weeks) * 0.6;
        var r = rnd();
        cell.dataset.l = r < p * 0.55 ? 3 : r < p * 0.85 ? 2 : r < p ? 1 : 0;
        cell.style.transitionDelay = (w * 22 + d * 8) + "ms";
        frag.appendChild(cell);
      }
    }
    heat.appendChild(frag);
  }

  // ─── Bento: timer tile ─────────────────────────────────

  var clock = $("#tileClock");
  var bar = $("#tileBar");
  if (clock && bar) {
    var secs = 840;
    var running = false;
    new IntersectionObserver(function (entries) {
      running = entries[0].isIntersecting;
    }).observe(clock);
    setInterval(function () {
      if (!running) return;
      secs = secs >= 1200 ? 0 : secs + 1;
      clock.textContent = fmt(secs);
      bar.style.width = (secs / 1200 * 100).toFixed(2) + "%";
    }, reduceMotion ? 1000 : 120);
  }

  // ─── Light / dark compare slider ───────────────────────

  var compare = $("#compare");
  var handle = $("#compareHandle");
  if (compare && handle) {
    var setPos = function (pct) {
      pct = Math.max(0, Math.min(100, pct));
      compare.style.setProperty("--pos", pct + "%");
      handle.setAttribute("aria-valuenow", Math.round(pct));
    };
    var dragging = false;
    var fromEvent = function (ev) {
      var r = compare.getBoundingClientRect();
      setPos((ev.clientX - r.left) / r.width * 100);
    };
    compare.addEventListener("pointerdown", function (ev) { ev.preventDefault(); dragging = true; compare.setPointerCapture(ev.pointerId); fromEvent(ev); });
    compare.addEventListener("pointermove", function (ev) { if (dragging) fromEvent(ev); });
    compare.addEventListener("selectstart", function (ev) { ev.preventDefault(); });
    compare.addEventListener("dragstart", function (ev) { ev.preventDefault(); });
    compare.addEventListener("pointerup", function () { dragging = false; });
    compare.addEventListener("pointercancel", function () { dragging = false; });
    handle.addEventListener("keydown", function (ev) {
      var now = parseFloat(handle.getAttribute("aria-valuenow"));
      if (ev.key === "ArrowLeft") { setPos(now - 5); ev.preventDefault(); }
      if (ev.key === "ArrowRight") { setPos(now + 5); ev.preventDefault(); }
    });
    // A gentle sweep the first time it is seen, so people notice it moves.
    if (!reduceMotion) {
      new IntersectionObserver(function (entries, obs) {
        if (!entries[0].isIntersecting) return;
        obs.disconnect();
        var t0 = performance.now();
        (function sweep(now) {
          if (dragging) return;
          var t = Math.min(1, (now - t0) / 2200);
          setPos(50 + Math.sin(t * Math.PI * 2) * 32 * (1 - t));
          if (t < 1) requestAnimationFrame(sweep);
        })(t0);
      }, { threshold: 0.6 }).observe(compare);
    }
  }

  // ─── Gallery coverflow ─────────────────────────────────

  var track = $("#galleryTrack");
  if (track) {
    var items = $$(".gallery-item", track);
    var ticking = false;
    var cover = function () {
      ticking = false;
      var mid = track.getBoundingClientRect().left + track.clientWidth / 2;
      items.forEach(function (it) {
        var r = it.getBoundingClientRect();
        var off = (r.left + r.width / 2 - mid) / r.width;
        var c = Math.max(-2.5, Math.min(2.5, off));
        var phone = $(".phone", it);
        // Screens face away from the middle: left phones turn left, right ones right
        phone.style.setProperty("--ry", (c * 24).toFixed(2) + "deg");
        phone.style.setProperty("--ty", (Math.abs(c) * 18).toFixed(1) + "px");
        phone.style.transition = "transform .15s linear";
        phone.style.setProperty("--fade", Math.min(0.35, Math.abs(c) * 0.14).toFixed(2));
        // Captions only show under the centred phone and fade in/out with scroll,
        // so they never sit visibly skewed under a tilted phone
        $("figcaption", it).style.opacity = Math.max(0, 1 - Math.abs(off) * 1.8).toFixed(2);
      });
    };
    track.addEventListener("scroll", function () {
      if (!ticking) { ticking = true; requestAnimationFrame(cover); }
    }, { passive: true });
    window.addEventListener("resize", cover);
    // Buttons scroll to an exact item centre. A native smooth scrollBy fights
    // scroll-snap on iOS Safari and ends off-centre, so animate scrollLeft
    // ourselves with snapping suspended, then hand control back to snap.
    var centerOf = function (it) {
      return it.offsetLeft - (track.clientWidth - it.offsetWidth) / 2;
    };
    var nearest = function () {
      var best = 0, bestD = Infinity;
      items.forEach(function (it, i) {
        var d = Math.abs(centerOf(it) - track.scrollLeft);
        if (d < bestD) { bestD = d; best = i; }
      });
      return best;
    };
    var anim = 0;
    var stop = function () {
      cancelAnimationFrame(anim);
      track.style.scrollSnapType = "";
    };
    ["touchstart", "wheel", "pointerdown"].forEach(function (ev) {
      track.addEventListener(ev, stop, { passive: true });
    });
    var step = function (dir) {
      stop();
      var i = Math.max(0, Math.min(items.length - 1, nearest() + dir));
      var from = track.scrollLeft, to = centerOf(items[i]);
      if (reduceMotion || from === to) { track.scrollLeft = to; return; }
      track.style.scrollSnapType = "none";
      var t0 = performance.now(), dur = 420;
      (function run(now) {
        var t = Math.min(1, (now - t0) / dur);
        track.scrollLeft = from + (to - from) * (1 - Math.pow(1 - t, 3));
        if (t < 1) { anim = requestAnimationFrame(run); }
        else { track.scrollLeft = to; track.style.scrollSnapType = ""; }
      })(t0);
    };
    $("#galPrev").addEventListener("click", function () { step(-1); });
    $("#galNext").addEventListener("click", function () { step(1); });
    // Start on the second screen so both sides have neighbours.
    requestAnimationFrame(function () {
      track.scrollLeft = items[1].offsetLeft - (track.clientWidth - items[1].offsetWidth) / 2;
      cover();
    });
  }

  // ─── CTA floating ticks ────────────────────────────────

  var ticks = $("#ctaTicks");
  if (ticks) {
    var spots = [[6, 18], [14, 70], [86, 22], [92, 64], [24, 40], [76, 82], [48, 88], [62, 12]];
    spots.forEach(function (s, i) {
      var t = document.createElement("span");
      t.innerHTML = '<svg><use href="#i-check"/></svg>';
      t.style.left = s[0] + "%";
      t.style.top = s[1] + "%";
      t.style.transform = "scale(" + (0.6 + (i % 3) * 0.25) + ")";
      t.style.animation = "bob " + (5 + i % 4) + "s " + (-i) + "s ease-in-out infinite";
      ticks.appendChild(t);
    });
  }

  // ─── Misc ──────────────────────────────────────────────

  $("#year").textContent = new Date().getFullYear();
  syncScreens();
  onScroll();
})();

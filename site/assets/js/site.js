/* Aarush Suzuki — site.js (shared across pages; each block runs only if its markup exists) */
(() => {
  const D = window.AARUSH;

  /* ---------- routing helpers ----------
     Pages use page-relative links (written by build.ps1). <meta name="site-root"> holds the path back
     to the site root ("./", "../", "../../"). link() turns a site path such as "/motorcycles/gixxer/"
     into a working relative URL. When a page is opened straight from disk (file://), folder links
     don't open index.html by themselves, so we add it. */
  const ROOT = document.querySelector('meta[name="site-root"]')?.content || '/';
  const IS_FILE = location.protocol === 'file:';
  const fileFix = (u) => (IS_FILE ? u.replace(/\/(?=$|[?#])/, '/index.html') : u);
  const link = (p) => (/^(https?:|mailto:|tel:|#)/.test(p) ? p : fileFix(ROOT + p.replace(/^\//, '')));
  if (IS_FILE) {
    document.querySelectorAll('a[href]').forEach((a) => {
      const h = a.getAttribute('href');
      if (!/^(https?:|mailto:|tel:|#|javascript:)/.test(h)) a.setAttribute('href', fileFix(h === './' || h === '' ? './' : h));
    });
  }

  // data.js is generated from src/data/*.json; derive the shapes the components use
  D.vehicles = D.vehicles.filter((v) => v.published !== false);
  const altOf = (v) => `Suzuki ${v.name}, side view`;
  D.models = D.vehicles.filter((v) => v.category !== 'premium')
    .map((v) => ({ ...v, url: link(v.url), img: link(v.image), enquire: link(`/contact/?model=${v.id}&topic=price#enquire`), line: v.summary, alt: altOf(v), featured: D.featured.includes(v.id) }));
  D.premium = D.vehicles.filter((v) => v.category === 'premium')
    .map((v) => ({ ...v, url: link(v.url), img: link(v.image), enquire: link(`/contact/?model=${v.id}&topic=availability#enquire`), line: v.summary, alt: `Suzuki ${v.name} on the road` }));
  const $ = (s, el = document) => el.querySelector(s);
  const $$ = (s, el = document) => [...el.querySelectorAll(s)];
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const wa = (text) => `https://wa.me/${D.contact.whatsapp}?text=${encodeURIComponent(text)}`;
  // Google Maps directions to a showroom, built from its address (same format as build.ps1)
  const dirUrl = (name, address) => `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(`Aarush Suzuki ${name}, ${address}`)}`;
  const priceFrom = (v) => { if (!v.prices || !v.prices.length) return ''; const n = Math.min(...v.prices.map((p) => +p[1].replace(/\D/g, ''))); return '₹' + n.toLocaleString('en-IN'); };
  const phone = (n) => `${n.slice(0, 5)} ${n.slice(5)}`;
  const CAT = { motorcycles: 'Motorcycle', scooters: 'Scooter', electric: 'Electric' };
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const desktop = matchMedia('(min-width: 961px)');
  const hasGsap = () => !reduce && window.gsap && window.ScrollTrigger;

  /* ---------- header: current page + hide on scroll down ---------- */
  const norm = (u) => u.split(/[?#]/)[0].replace(/index\.html$/, '');
  const here = norm(location.href);
  const home = norm(new URL(link('/'), location.href).href);
  $$('.site-nav a, .drawer nav a').forEach((a) => {
    const target = norm(a.href);
    if (target !== home && here.startsWith(target)) a.setAttribute('aria-current', 'page');
  });
  const header = $('[data-header]');
  let lastY = scrollY;
  addEventListener('scroll', () => {
    const y = scrollY;
    if (header && !document.body.classList.contains('is-locked')) header.classList.toggle('is-hidden', y > lastY && y > 240);
    lastY = y;
  }, { passive: true });

  /* ---------- mobile drawer ---------- */
  const toggle = $('.menu-toggle');
  const drawer = $('#drawer');
  const setDrawer = (open) => {
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    document.body.classList.toggle('is-locked', open);
    header?.classList.remove('is-hidden'); // the close button lives in the header, so it must stay visible
    if (open) { drawer.hidden = false; requestAnimationFrame(() => drawer.classList.add('is-open')); }
    else { drawer.classList.remove('is-open'); setTimeout(() => { if (!drawer.classList.contains('is-open')) drawer.hidden = true; }, 350); }
  };
  if (toggle && drawer) {
    toggle.addEventListener('click', () => setDrawer(toggle.getAttribute('aria-expanded') !== 'true'));
    addEventListener('keydown', (e) => { if (e.key === 'Escape' && !drawer.hidden) setDrawer(false); });
  }

  $$('[data-year]').forEach((el) => { el.textContent = new Date().getFullYear(); });

  /* ---------- ways to ride: index ↔ stage ---------- */
  const waysLinks = $$('[data-way]');
  const stageImgs = $$('[data-stage-img]');
  const caption = $('[data-stage-caption]');
  const heroName = Object.fromEntries(D.categories.map((c) => [c.id, D.models.find((m) => m.id === c.hero)?.name || c.name]));
  const activateWay = (id) => {
    waysLinks.forEach((a) => a.classList.toggle('is-active', a.dataset.way === id));
    stageImgs.forEach((img) => {
      const on = img.dataset.stageImg === id;
      if (img.classList.contains('is-active') && !on) {
        img.classList.add('is-leaving');
        setTimeout(() => img.classList.remove('is-leaving'), 700);
      }
      img.classList.toggle('is-active', on);
    });
    if (caption) caption.textContent = heroName[id];
  };
  if (waysLinks.length) {
    activateWay('motorcycles');
    waysLinks.forEach((a) => {
      a.addEventListener('mouseenter', () => activateWay(a.dataset.way));
      a.addEventListener('focus', () => activateWay(a.dataset.way));
    });
  }
  const tiltRoot = $('[data-stage]');
  const tiltEl = $('[data-stage-tilt]');
  if (tiltRoot && tiltEl && !reduce) {
    tiltRoot.closest('.ways').addEventListener('pointermove', (e) => {
      const r = tiltRoot.getBoundingClientRect();
      const x = (e.clientX - (r.left + r.width / 2)) / r.width;
      const y = (e.clientY - (r.top + r.height / 2)) / r.height;
      tiltEl.style.transform = `rotateY(${x * 10}deg) rotateX(${-y * 5}deg)`;
    });
  }

  /* ---------- homepage banner slider ----------
     Auto-advances every 6 s with a cross-fade; pauses on hover/focus, when the tab is hidden, or via the
     pause button; dots, arrows, swipe and arrow keys. Reduced-motion visitors get it paused. */
  $$('[data-hs]').forEach((hs) => {
    const slides = $$('[data-slide]', hs);
    const dots = $$('.hs__dot', hs);
    const n = slides.length; if (!n) return;
    const DURATION = 6000;
    const lab = $('[data-hs-label]', hs), note = $('[data-hs-note]', hs), idx = $('[data-hs-index]', hs);
    const ex = $('[data-hs-explore]', hs), ride = $('[data-hs-ride]', hs), pauseBtn = $('[data-hs-pause]', hs);
    let i = 0, timer = null, paused = reduce, held = false;
    hs.style.setProperty('--hs-duration', `${DURATION}ms`);
    const schedule = () => {
      clearTimeout(timer);
      hs.classList.remove('is-running'); void hs.offsetWidth; // restart the progress animation
      if (!paused && !held && n > 1) { hs.classList.add('is-running'); timer = setTimeout(() => show(i + 1), DURATION); }
    };
    const show = (k) => {
      i = (k + n) % n;
      slides.forEach((s, j) => {
        const on = j === i;
        s.classList.toggle('is-active', on);
        s.setAttribute('aria-hidden', String(!on));
        // warm the next banner so the cross-fade never shows an empty frame
        if (j === (i + 1) % n) $$('img', s).forEach((img) => { if (img.loading === 'lazy') img.loading = 'eager'; });
      });
      dots.forEach((d, j) => d.setAttribute('aria-current', String(j === i)));
      const s = slides[i];
      lab.textContent = s.dataset.label;
      note.textContent = s.dataset.note || '';
      if (idx) idx.textContent = String(i + 1).padStart(2, '0');
      ex.textContent = `Explore ${s.dataset.label}`;
      ex.href = link(s.dataset.url);
      ride.href = link(s.dataset.ride);
      schedule();
    };
    const setPaused = (p) => {
      paused = p;
      pauseBtn.setAttribute('aria-pressed', String(p));
      pauseBtn.setAttribute('aria-label', p ? 'Play slideshow' : 'Pause slideshow');
      hs.classList.toggle('is-paused', p);
      schedule();
    };
    dots.forEach((d) => d.addEventListener('click', () => show(+d.dataset.goto)));
    $('[data-hs-prev]', hs).addEventListener('click', () => show(i - 1));
    $('[data-hs-next]', hs).addEventListener('click', () => show(i + 1));
    pauseBtn.addEventListener('click', () => setPaused(!paused));
    hs.addEventListener('pointerenter', (e) => { if (e.pointerType === 'mouse') { held = true; schedule(); } });
    hs.addEventListener('pointerleave', () => { held = false; schedule(); });
    hs.addEventListener('focusin', () => { held = true; schedule(); });
    hs.addEventListener('focusout', (e) => { if (!hs.contains(e.relatedTarget)) { held = false; schedule(); } });
    hs.addEventListener('keydown', (e) => { if (e.key === 'ArrowLeft') show(i - 1); if (e.key === 'ArrowRight') show(i + 1); });
    document.addEventListener('visibilitychange', () => { held = document.hidden; schedule(); });
    let x0 = null;
    const track = $('.hs__track', hs);
    track.addEventListener('pointerdown', (e) => { x0 = e.clientX; });
    track.addEventListener('pointerup', (e) => {
      if (x0 === null) return; const dx = e.clientX - x0; x0 = null;
      if (Math.abs(dx) > 50) { track.dataset.swiped = '1'; show(dx < 0 ? i + 1 : i - 1); } // a swipe must not also open the banner link
    });
    track.addEventListener('click', (e) => { if (track.dataset.swiped) { e.preventDefault(); delete track.dataset.swiped; } });
    if (reduce) setPaused(true); else show(0);
  });

  /* ---------- Instagram reels ----------
     Official Instagram embeds load only when the card nears the screen. Any reel with a local MP4
     (site.json → reels[].video) autoplays muted while visible and pauses when it leaves. */
  const reelCards = $$('[data-reel]');
  if (reelCards.length) {
    const activate = (card, visible) => {
      const v = $('[data-reel-video]', card);
      const em = $('[data-reel-embed]', card);
      if (v) { if (visible) { v.muted = true; v.play().catch(() => {}); } else v.pause(); }
      if (em && visible && !em.dataset.loaded) {
        em.dataset.loaded = '1';
        em.innerHTML = `<iframe src="${esc(em.dataset.reelEmbed)}" title="Aarush Suzuki reel" loading="lazy" scrolling="no" allowtransparency="true" allow="autoplay; encrypted-media"></iframe>`;
      }
    };
    if ('IntersectionObserver' in window) {
      const io = new IntersectionObserver((entries) => entries.forEach((e) => activate(e.target, e.isIntersecting)), { rootMargin: '250px 0px', threshold: 0.2 });
      reelCards.forEach((c) => io.observe(c));
    } else reelCards.forEach((c) => activate(c, true));
  }

  /* ---------- line-up showcase ---------- */
  const track = $('[data-lineup-track]');
  if (track) {
    const featured = D.models.filter((m) => m.featured);
    track.innerHTML = featured.map((m) => `
      <article class="slide">
        <div class="slide__scene">
          <span class="slide__word" aria-hidden="true">${esc(m.name.split(' ')[0])}</span>
          <a class="slide__vehicle" href="${m.url}" tabindex="-1" aria-hidden="true">
            <img src="${m.img.replace('/img/models/', '/img/models/trim/')}" alt="" loading="lazy">
          </a>
          <span class="slide__shadow" aria-hidden="true"></span>
        </div>
        <div class="slide__info">
          <span class="slide__cat">${CAT[m.category]}</span>
          <h3 class="slide__name"><a href="${m.url}">${esc(m.name)}</a></h3>
          <p class="slide__line">${esc(m.line)}${priceFrom(m) ? `<span class="slide__price">Ex-showroom Hyderabad from <b>${priceFrom(m)}</b></span>` : ""}</p>
          <div class="slide__actions">
            <a class="link-arrow" href="${m.url}">Explore model</a>
            <a class="slide__enquire" href="${m.enquire}">Enquire now</a>
          </div>
        </div>
      </article>`).join('');
    { const tot = $('[data-lineup-total]'); if (tot) tot.textContent = String(featured.length).padStart(2, '0'); }

    const slides = $$('.slide', track);
    const vehicles = $$('.slide__vehicle', track);
    const shadows = $$('.slide__shadow', track);
    // Contact shadows: size and place each shadow under the bike's actual drawn footprint,
    // so the wheels sit on it (images are trimmed to the vehicle and bottom-aligned).
    const fitShadows = () => slides.forEach((s, i) => {
      const img = $('img', vehicles[i]);
      if (!img.naturalWidth) return;
      const scene = vehicles[i].parentElement;
      const bw = vehicles[i].offsetWidth, bh = vehicles[i].offsetHeight;
      const k = Math.min(bw / img.naturalWidth, bh / img.naturalHeight);
      const dw = img.naturalWidth * k;
      const sh = shadows[i];
      const h = Math.max(14, Math.round(dw * .045));
      sh.style.width = `${Math.round(dw * .9)}px`;
      sh.style.height = `${h}px`;
      sh.style.left = `${Math.round(vehicles[i].offsetLeft + (bw - dw * .9) / 2)}px`;
      sh.style.top = `${Math.round(vehicles[i].offsetTop + bh - h / 2 - 1)}px`;
      scene.classList.add('is-grounded');
    });
    $$('img', track).forEach((img) => { if (img.complete) fitShadows(); else img.addEventListener('load', fitShadows, { once: true }); });
    addEventListener('resize', fitShadows);
    const cur = $('[data-lineup-current]');
    const bar = $('[data-lineup-bar]');
    const pointer = { x: 0, y: 0 };
    const update = (progress) => {
      const mid = innerWidth / 2;
      let nearest = 0; let best = Infinity;
      slides.forEach((s, i) => {
        const r = s.getBoundingClientRect();
        const off = (r.left + r.width / 2 - mid) / innerWidth; // -1..1
        if (Math.abs(off) < best) { best = Math.abs(off); nearest = i; }
        if (!reduce) {
          const ry = Math.max(-1, Math.min(1, off)) * -16 + (Math.abs(off) < .35 ? pointer.x * 8 : 0);
          const rx = Math.abs(off) < .35 ? pointer.y * -4 : 0;
          const sc = 1 - Math.min(Math.abs(off), 1) * .12;
          vehicles[i].style.transform = `rotateY(${ry}deg) rotateX(${rx}deg) scale(${sc})`;
          shadows[i].style.transform = `scaleX(${sc})`;
        }
      });
      if (cur) cur.textContent = String(nearest + 1).padStart(2, '0');
      const p = progress ?? (track.scrollLeft / Math.max(1, track.scrollWidth - track.clientWidth));
      bar.style.transform = `scaleX(${Math.max(1 / slides.length, p)})`;
    };
    track.addEventListener('pointermove', (e) => {
      pointer.x = (e.clientX / innerWidth - .5) * 2;
      pointer.y = (e.clientY / innerHeight - .5) * 2;
      update();
    });

    const lineup = $('[data-lineup]');
    const pinned = () => hasGsap() && desktop.matches;
    if (pinned()) {
      gsap.registerPlugin(ScrollTrigger);
      const dist = () => track.scrollWidth - innerWidth;
      gsap.to(track, {
        x: () => -dist(), ease: 'none',
        onUpdate() { update(this.progress()); }, // runs every frame of the scrubbed tween, so rects are current
        scrollTrigger: {
          trigger: $('[data-lineup-pin]'), pin: true, scrub: .6, end: () => '+=' + dist(), invalidateOnRefresh: true,
        },
      });
    } else {
      lineup.classList.add('is-native');
      track.addEventListener('scroll', () => update(), { passive: true });
    }
    update(0);
  }

  /* ---------- premium bikes ---------- */
  const premium = $('[data-premium]');
  if (premium) {
    premium.innerHTML = D.premium.map((p) => `
      <a class="bike" href="${p.url}">
        <img src="${p.img}" alt="${esc(p.alt)}" width="550" height="640" loading="lazy">
        <span class="bike__body">
          <span><h3>${esc(p.name)}</h3><p>${esc(p.line)}</p></span>
          <span class="bike__go" aria-hidden="true"></span>
        </span>
      </a>`).join('');
  }

  /* ---------- showroom directory ---------- */
  const dir = $('[data-directory]');
  if (dir) {
    const render = (region) => {
      dir.innerHTML = D.showrooms.filter((s) => s.region === region).map((s) => `
        <li class="dir-row">
          <div><h3>${esc(s.name)}</h3><span class="dir-row__tag">${s.id.startsWith('best-value') ? 'Suzuki Best Value · Sales & service' : 'Sales & service'}</span></div>
          <address>${esc(s.address)}${s.serviceAddress ? `<small>Service centre: ${esc(s.serviceAddress)}</small>` : ''}</address>
          <div class="dir-row__phones">
            <a href="tel:+91${s.sales}"><span>Sales</span>${phone(s.sales)}</a>
            <a href="tel:+91${s.service}"><span>Service</span>${phone(s.service)}</a>
          </div>
          <a class="link-arrow dir-row__map" href="${dirUrl(s.name, s.address)}" target="_blank" rel="noopener" aria-label="Directions to Aarush Suzuki ${esc(s.name)} on Google Maps">Directions</a>
        </li>`).join('');
    };
    const tabs = $$('[data-region-tabs] button');
    tabs.forEach((b) => {
      b.textContent += ` (${D.showrooms.filter((s) => s.region === b.dataset.region).length})`;
      b.addEventListener('click', () => {
        tabs.forEach((t) => t.setAttribute('aria-selected', String(t === b)));
        render(b.dataset.region);
      });
    });
    render('hyderabad');
  }

  /* ---------- "Select your bike" picker (Send an enquiry form) ---------- */
  // Visual front-end for the vehicle <select>: the select stays in the form and keeps the value,
  // so validation, presets and the WhatsApp hand-off are unchanged.
  const BIKES = [
    ...D.models.map((m) => ({ name: m.name, group: m.category, cat: CAT[m.category], img: m.img.replace('/img/models/', '/img/models/trim/') })),
    ...D.premium.map((p) => ({ name: p.name, group: 'premium', cat: 'Premium bike', img: p.img.replace('/portrait.jpg', '/colour-1.jpg'), photo: true })),
  ];
  const BIKE_GROUPS = [['all', 'All'], ['motorcycles', 'Motorcycles'], ['scooters', 'Scooters'], ['electric', 'Electric'], ['premium', 'Premium']];
  let bikeModal = null;
  const getBikeModal = () => {
    if (bikeModal) return bikeModal;
    const dlg = document.createElement('dialog');
    dlg.className = 'bike-modal';
    dlg.setAttribute('aria-labelledby', 'bike-modal-title');
    dlg.innerHTML = `
      <div class="bike-modal__head">
        <div><p class="bike-modal__kicker">Send an enquiry</p><h2 class="bike-modal__title" id="bike-modal-title">Select your bike</h2></div>
        <button class="bike-modal__close" type="button" data-bike-close aria-label="Close">&times;</button>
      </div>
      <div class="bike-modal__filters" role="tablist" aria-label="Vehicle type">
        ${BIKE_GROUPS.map(([g, l], i) => `<button type="button" role="tab" aria-selected="${i === 0}" data-bike-filter="${g}">${l}</button>`).join('')}
      </div>
      <ul class="bike-modal__grid">
        ${BIKES.map((b) => `<li data-bike-group="${b.group}"><button type="button" class="bike-card${b.photo ? ' bike-card--photo' : ''}" data-bike="${esc(b.name)}" aria-pressed="false">
          <span class="bike-card__img"><img src="${b.img}" alt="" loading="lazy"></span>
          <span class="bike-card__cat">${esc(b.cat)}</span>
          <strong class="bike-card__name">${esc(b.name)}</strong>
        </button></li>`).join('')}
      </ul>
      <div class="bike-modal__foot"><button type="button" class="bike-modal__clear" data-bike-clear>Not sure yet, clear selection</button></div>`;
    document.body.append(dlg);
    $$('[data-bike-filter]', dlg).forEach((t) => t.addEventListener('click', () => {
      $$('[data-bike-filter]', dlg).forEach((x) => x.setAttribute('aria-selected', String(x === t)));
      $$('[data-bike-group]', dlg).forEach((li) => { li.hidden = t.dataset.bikeFilter !== 'all' && li.dataset.bikeGroup !== t.dataset.bikeFilter; });
    }));
    $('[data-bike-close]', dlg).addEventListener('click', () => dlg.close());
    dlg.addEventListener('click', (e) => { if (e.target === dlg) dlg.close(); }); // backdrop
    dlg.addEventListener('close', () => { document.documentElement.classList.remove('has-modal'); dlg._onClose?.(); });
    bikeModal = dlg;
    return dlg;
  };
  const bikePicker = (form, vSel) => {
    const field = vSel.closest('.field');
    field.classList.add('is-picker');
    const trigger = document.createElement('button');
    trigger.type = 'button';
    trigger.className = 'bike-pick';
    trigger.setAttribute('aria-haspopup', 'dialog');
    field.after(trigger);
    const sync = () => {
      const b = BIKES.find((x) => x.name === vSel.value);
      trigger.classList.toggle('is-set', !!b);
      trigger.innerHTML = `<span class="bike-pick__thumb${b && b.photo ? ' bike-pick__thumb--photo' : ''}">${b ? `<img src="${b.img}" alt="">` : '<i aria-hidden="true"></i>'}</span>
        <span class="bike-pick__text"><b>${b ? esc(b.name) : 'Select your bike'}</b><small>${b ? esc(b.cat) : 'Browse the Suzuki line-up'}</small></span>
        <span class="bike-pick__cta">${b ? 'Change' : 'Choose'}</span>`;
      trigger.setAttribute('aria-label', b ? `Selected bike: ${b.name}. Change bike` : 'Select your bike');
    };
    sync();
    vSel.addEventListener('change', sync);
    form.addEventListener('reset', () => setTimeout(sync, 0));
    trigger.addEventListener('click', () => {
      const dlg = getBikeModal();
      $$('.bike-card', dlg).forEach((c) => c.setAttribute('aria-pressed', String(c.dataset.bike === vSel.value)));
      const pick = (name) => { vSel.value = name; vSel.dispatchEvent(new Event('change', { bubbles: true })); dlg.close(); };
      const onCard = (e) => { const c = e.target.closest('[data-bike]'); if (c) pick(c.dataset.bike); };
      const onClear = () => pick('');
      dlg.addEventListener('click', onCard);
      $('[data-bike-clear]', dlg).addEventListener('click', onClear);
      dlg._onClose = () => { dlg.removeEventListener('click', onCard); $('[data-bike-clear]', dlg).removeEventListener('click', onClear); trigger.focus(); };
      document.documentElement.classList.add('has-modal');
      dlg.showModal();
      ($('.bike-card[aria-pressed="true"]', dlg) || $('[data-bike-filter][aria-selected="true"]', dlg)).focus();
    });
  };

  /* ---------- test ride form ---------- */
  $$('[data-ride-form]').forEach((form) => {
    const vSel = $('[data-vehicle-select]', form);
    [['motorcycles', 'Motorcycles'], ['scooters', 'Scooters'], ['electric', 'Electric']].forEach(([cat, label]) => {
      const g = document.createElement('optgroup'); g.label = label;
      D.models.filter((m) => m.category === cat).forEach((m) => g.append(new Option(m.name, m.name)));
      vSel.append(g);
    });
    const pg = document.createElement('optgroup'); pg.label = 'Premium Bikes';
    D.premium.forEach((p) => pg.append(new Option(p.name, p.name)));
    vSel.append(pg);
    // preset: ?model=<id> in the URL, or data-preset="<name>" on the form
    const byId = D.vehicles.find((v) => v.id === new URLSearchParams(location.search).get('model'));
    const preset = byId ? byId.name : form.dataset.preset;
    if (preset) vSel.value = preset;
    if (form.dataset.mode === 'contact' && typeof HTMLDialogElement === 'function') bikePicker(form, vSel);
    // contact form topic preset: ?topic=price|availability|testride|service|finance
    const TOPICS = { price: 'On-road price', availability: 'Availability and booking', testride: 'Test ride', service: 'Service', finance: 'Finance or insurance', accessories: 'Accessories' };
    const topicSel = $('select[name="type"]', form);
    const topicPreset = TOPICS[new URLSearchParams(location.search).get('topic')];
    if (topicSel && topicPreset && [...topicSel.options].some((o) => o.value === topicPreset)) topicSel.value = topicPreset;
    if (form.dataset.mode === 'contact' && (byId || topicPreset) && location.hash === '#enquire') {
      // arriving from an "Enquire now" button: put the cursor in the first empty field
      setTimeout(() => $('[name="name"]', form).focus({ preventScroll: true }), 400);
    }

    const mode = form.dataset.mode || 'ride';
    const sSel = $('[data-showroom-select]', form);
    D.showrooms.forEach((s) => sSel.append(new Option(mode === 'service' && s.serviceAddress ? `${s.name} (service centre)` : s.name, s.name)));
    const date = $('[data-date-min]', form);
    if (date) { const t = new Date(); date.min = new Date(t - t.getTimezoneOffset() * 6e4).toISOString().slice(0, 10); }

    const msg = { name: 'Please enter your full name.', phone: 'Enter a valid 10-digit mobile number.', vehicle: 'Choose a vehicle.', showroom: 'Choose a location.', date: 'Choose a date from today onwards.', type: 'Choose an option.', reg: '', message: '' };
    const check = (el) => {
      const ok = el.checkValidity();
      const f = el.closest('.field'); f.classList.toggle('is-invalid', !ok);
      $('.field__error', f).textContent = ok ? '' : msg[el.name];
      return ok;
    };
    const fields = () => $$('input, select, textarea', form);
    $('[name="phone"]', form).addEventListener('input', (e) => { e.target.value = e.target.value.replace(/\D/g, '').slice(0, 10); });
    fields().forEach((el) => el.addEventListener('blur', () => { if (el.value) check(el); }));
    vSel.addEventListener('change', () => document.dispatchEvent(new CustomEvent('aarush:vehicle', { detail: vSel.value })));
    if (preset) setTimeout(() => document.dispatchEvent(new CustomEvent('aarush:vehicle', { detail: preset })));

    const getEndpoint = () => (D.forms && D.forms.endpoint) || '';
    const endpoint = getEndpoint();
    const note = $('[data-form-note]', form);
    if (endpoint && note) note.textContent = 'Your request goes straight to Aarush Suzuki. Our team will call you to confirm.';
    const errBox = $('[data-form-error]', form);
    const done = $('.ride-form__done', form);
    const submitBtn = $('button[type="submit"]', form);
    const showDone = (title, text, waHref) => {
      $('[data-done-title]', form).textContent = title;
      $('[data-done-text]', form).textContent = text;
      const waBtn = $('[data-done-wa]', form);
      waBtn.hidden = !waHref; if (waHref) waBtn.href = waHref;
      done.hidden = false;
    };

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      errBox.hidden = true;
      const els = fields();
      const res = els.map(check);
      if (res.includes(false)) { els[res.indexOf(false)].focus(); return; }
      const d = Object.fromEntries(new FormData(form));
      const when = d.date ? new Date(d.date + 'T00:00').toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' }) : '';
      const lines = {
        ride: ['Test ride request', `Name: ${d.name}`, `Mobile: +91 ${d.phone}`, `Vehicle: Suzuki ${d.vehicle}`, `Showroom: ${d.showroom}`, `Preferred date: ${when}`],
        service: ['Service booking request', `Name: ${d.name}`, `Mobile: +91 ${d.phone}`, `Vehicle: Suzuki ${d.vehicle}`, d.reg ? `Registration: ${d.reg.toUpperCase()}` : '', `Service: ${d.type}`, `Service centre: ${d.showroom}`, `Preferred date: ${when}`],
        contact: ['Website enquiry', `Name: ${d.name}`, `Mobile: +91 ${d.phone}`, `Topic: ${d.type}`, d.vehicle ? `Vehicle: Suzuki ${d.vehicle}` : '', `Showroom: ${d.showroom}`, d.message ? `Message: ${d.message}` : ''],
      }[mode].filter(Boolean).join('\n');
      const waHref = wa(lines);
      const first = d.name.trim().split(/\s+/)[0];

      if (getEndpoint()) {
        // Real submission: success is shown only after the server confirms.
        submitBtn.disabled = true; const label = submitBtn.textContent; submitBtn.textContent = 'Sending…';
        try {
          const r = await fetch(getEndpoint(), {
            method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
            body: JSON.stringify({ ...d, form: mode, subject: lines.split('\n')[0], page: location.href, access_key: D.forms.accessKey || undefined }),
          });
          if (!r.ok) throw new Error(`Server responded ${r.status}`);
          location.href = link('/thank-you/');
        } catch (err) {
          errBox.textContent = 'Sorry, we couldn’t send your request just now. Please try again, call 88852 46633, or send it on WhatsApp.';
          errBox.hidden = false;
          showDone('Not sent yet', 'Your details are still in the form. You can send the same request on WhatsApp instead.', waHref);
        } finally { submitBtn.disabled = false; submitBtn.textContent = label; }
        return;
      }

      // No form backend configured: hand the request to WhatsApp and say plainly that it isn't sent yet.
      window.open(waHref, '_blank', 'noopener');
      showDone(`One more step, ${first}.`, 'WhatsApp has opened with your request written out. It is only sent to Aarush Suzuki when you press Send in WhatsApp. If WhatsApp didn’t open, use the button below.', waHref);
    });
    $('[data-form-reset]', form).addEventListener('click', () => { form.reset(); if (preset) vSel.value = preset; done.hidden = true; errBox.hidden = true; $('[name="name"]', form).focus(); });
  });

  /* ---------- test-ride page: live vehicle preview ---------- */
  const pImg = $('[data-preview-img]');
  if (pImg) {
    const LABEL = { motorcycles: 'Motorcycle', scooters: 'Scooter', electric: 'Electric', premium: 'Premium bike' };
    document.addEventListener('aarush:vehicle', (e) => {
      const v = D.vehicles.find((x) => x.name === e.detail);
      if (!v) return;
      const photo = /^https?:|\/portrait\./.test(v.image);
      pImg.classList.add('is-swapping');
      setTimeout(() => {
        pImg.src = link(v.image); pImg.alt = `Suzuki ${v.name}`;
        pImg.closest('.tr__stage').classList.toggle('tr__stage--photo', photo);
        $('[data-preview-name]').textContent = v.name;
        $('[data-preview-cat]').textContent = LABEL[v.category];
        pImg.classList.remove('is-swapping');
      }, 220);
    });
  }

  /* ---------- colour swatches ---------- */
  $$('[data-swatches]').forEach((list) => {
    const label = $('[data-colour-name]');
    const visual = $('[data-colour-visual]');
    const vName = $('#v-name span')?.textContent || '';
    // warm the cache so switching colours is instant
    $$('.swatch', list).forEach((s) => { if (s.dataset.colourImg) { const i = new Image(); i.src = link(s.dataset.colourImg); } });
    list.addEventListener('click', (e) => {
      const b = e.target.closest('.swatch'); if (!b) return;
      $$('.swatch', list).forEach((s) => s.setAttribute('aria-pressed', String(s === b)));
      if (label) label.textContent = b.dataset.colour;
      if (visual && b.dataset.colourImg) {
        visual.classList.add('is-swapping');
        setTimeout(() => {
          visual.src = link(b.dataset.colourImg); visual.alt = `Suzuki ${vName} in ${b.dataset.colour}`;
          visual.classList.remove('is-swapping');
        }, 180);
      }
    });
  });

  /* ---------- scooter selector (tabs) ---------- */
  $$('[data-selector]').forEach((sel) => {
    const tabs = $$('[role="tab"]', sel);
    const show = (tab) => {
      tabs.forEach((t) => {
        const on = t === tab;
        t.setAttribute('aria-selected', String(on));
        t.tabIndex = on ? 0 : -1;
        $('#' + t.getAttribute('aria-controls')).hidden = !on;
      });
    };
    tabs.forEach((t, i) => {
      t.tabIndex = i === 0 ? 0 : -1;
      t.addEventListener('click', () => show(t));
      t.addEventListener('keydown', (e) => {
        const dir = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[e.key];
        if (!dir) return;
        e.preventDefault();
        const next = tabs[(i + dir + tabs.length) % tabs.length]; next.focus(); show(next);
      });
    });
  });

  /* ---------- static branch lists: region filter + map ---------- */
  $$('[data-region-filter]').forEach((seg) => {
    const list = seg.closest('section').querySelector('[data-branches]');
    const apply = (region) => $$('.branch', list).forEach((b) => { b.hidden = region !== 'all' && b.dataset.region !== region; });
    const btns = $$('button', seg);
    btns.forEach((b) => b.addEventListener('click', () => { btns.forEach((x) => x.setAttribute('aria-selected', String(x === b))); apply(b.dataset.region); }));
    apply(btns.find((b) => b.getAttribute('aria-selected') === 'true').dataset.region);
  });
  const mapFrame = $('[data-map]');
  if (mapFrame) {
    document.body.classList.add('has-map');
    const overview = mapFrame.innerHTML; // live map of all Aarush Suzuki showrooms
    const label = $('[data-map-label]'), labelHtml = label ? label.innerHTML : '';
    const reset = $('[data-map-reset]');
    document.addEventListener('click', (e) => {
      const b = e.target.closest('[data-map-q]'); if (!b) return;
      $$('.branch.is-current').forEach((x) => x.classList.remove('is-current'));
      b.closest('.branch').classList.add('is-current');
      mapFrame.innerHTML = `<iframe title="Map: Aarush Suzuki ${esc(b.dataset.mapName)}" src="https://maps.google.com/maps?q=${encodeURIComponent(b.dataset.mapQ)}&z=15&output=embed" loading="lazy" referrerpolicy="no-referrer-when-downgrade" allowfullscreen></iframe>`;
      if (label) label.innerHTML = `Showing <strong>${esc(b.dataset.mapName)}</strong>`;
      if (reset) reset.hidden = false;
      if (!desktop.matches) mapFrame.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'center' });
    });
    reset?.addEventListener('click', () => {
      mapFrame.innerHTML = overview;
      if (label) label.innerHTML = labelHtml;
      reset.hidden = true;
      $$('.branch.is-current').forEach((x) => x.classList.remove('is-current'));
    });
    if (location.hash) $(location.hash)?.classList.add('is-current');
  }

  /* ---------- gallery lightbox ---------- */
  const lb = $('[data-lightbox]');
  if (lb && typeof lb.showModal === 'function') {
    document.addEventListener('click', (e) => {
      const b = e.target.closest('[data-lightbox-src]'); if (!b) return;
      $('img', lb).src = $('img', b)?.src || link(b.dataset.lightboxSrc); $('img', lb).alt = $('img', b)?.alt || '';
      lb.showModal();
    });
    lb.addEventListener('click', (e) => { if (e.target === lb || e.target.closest('[data-lightbox-close]')) lb.close(); });
  }

  /* ---------- pointer tilt for product stages ---------- */
  if (!reduce) {
    $$('[data-tilt]').forEach((el) => {
      const zone = el.closest('section') || el;
      zone.addEventListener('pointermove', (e) => {
        const r = zone.getBoundingClientRect();
        const x = (e.clientX - r.left) / r.width - .5;
        const y = (e.clientY - r.top) / r.height - .5;
        el.style.transform = `perspective(1200px) rotateY(${x * 12}deg) rotateX(${-y * 6}deg)`;
      });
      zone.addEventListener('pointerleave', () => { el.style.transform = ''; });
    });
  }

  /* ---------- motion (GSAP) ---------- */
  const start = () => {
    if (!hasGsap()) return;
    gsap.registerPlugin(ScrollTrigger);

    // hero intro + depth
    const media = $('[data-hero-media]');
    if (media) {
      gsap.fromTo(media, { scale: 1.12 }, { scale: 1, duration: 2.4, ease: 'power3.out' });
      if (document.visibilityState === 'visible') gsap.from('[data-hero-item]', { y: 30, opacity: 0, duration: 1.1, stagger: .09, delay: .15, ease: 'power3.out' });
      gsap.to(media, { yPercent: 14, ease: 'none', scrollTrigger: { trigger: '.hero', start: 'top top', end: 'bottom top', scrub: true } });
    }

    // parallax layers
    $$('[data-parallax]').forEach((el) => {
      const v = parseFloat(el.dataset.parallax) || 0;
      gsap.fromTo(el, { yPercent: -v }, { yPercent: v, ease: 'none', scrollTrigger: { trigger: el, start: 'top bottom', end: 'bottom top', scrub: true } });
    });

    // big headings settle into place
    // inner pages: page titles rise in, photos drift slowly inside their frames
    // above-the-fold intros move but never hide content; skipped entirely for pages opened in a background tab
    if (document.visibilityState === 'visible') gsap.from('.cat-hero__title, .ev-hero__title, .pr-hero__title, .svc-hero__title, .ab-hero__title, .ct-hero__title, .tr__title, .v-hero__name, .simple__title, .legal__title',
      { y: 40, duration: 1.1, ease: 'power3.out', delay: .1, clearProps: 'transform' });
    if (document.visibilityState === 'visible') gsap.from('.cat-hero__vehicle, .ev-hero__vehicle, .v-hero__visual, .svc-hero__bike', { x: 60, duration: 1.4, ease: 'power3.out', delay: .2, clearProps: 'transform' });
    $$('[data-parallax-img] img').forEach((img) => {
      gsap.fromTo(img, { yPercent: -6, scale: 1.12 }, { yPercent: 6, scale: 1.12, ease: 'none', scrollTrigger: { trigger: img.parentElement, start: 'top bottom', end: 'bottom top', scrub: true } });
    });
    $$('.mrow, .pbike, .feat, .sim, .branch').forEach((el) => {
      gsap.from(el, { y: 36, opacity: 0, duration: .9, ease: 'power3.out', scrollTrigger: { trigger: el, start: 'top 90%', once: true } });
    });

    $$('.ways__title, .lineup__title, .experience__title, .premium__title, .dealer__title, .ride__title, .directory__title, .sec-title, .daily__title, .ev-enquire__title, .v-enquire__title, .v-overview__lead').forEach((el) => {
      gsap.from(el, { y: 40, opacity: 0, duration: 1, ease: 'power3.out', scrollTrigger: { trigger: el, start: 'top 85%', once: true } });
    });
    gsap.from('.bike', { y: 80, opacity: 0, duration: 1.1, stagger: .12, ease: 'power3.out', scrollTrigger: { trigger: '.premium__gallery', start: 'top 80%', once: true } });
    gsap.from('.experience__facts li', { x: 40, opacity: 0, duration: .9, stagger: .12, ease: 'power3.out', scrollTrigger: { trigger: '.experience__facts', start: 'top 85%', once: true } });

    addEventListener('load', () => ScrollTrigger.refresh());
  };
  if (document.readyState === 'complete') start(); else addEventListener('DOMContentLoaded', start);
})();

(() => {
  const D = window.RGEN || { providers: [], hist: [], stats: [] };
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const store = {
    get: (k) => { try { return localStorage.getItem(k); } catch { return null; } },
    set: (k, v) => { try { localStorage.setItem(k, v); } catch { /* private mode */ } },
  };
  const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

  // ---------- theme ----------
  const root = document.documentElement;
  const saved = store.get('rgen-theme');
  if (saved === 'light' || saved === 'dark') root.dataset.theme = saved;
  const isDark = () => root.dataset.theme ? root.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  document.querySelector('.theme-toggle')?.addEventListener('click', () => {
    root.dataset.theme = isDark() ? 'light' : 'dark';
    store.set('rgen-theme', root.dataset.theme);
    drawGalton(true);
  });

  // ---------- install tabs ----------
  document.querySelectorAll('[data-tabs]').forEach((box) => {
    const tabs = [...box.querySelectorAll('[role="tab"]')];
    const select = (tab) => {
      tabs.forEach((t) => {
        const on = t === tab;
        t.setAttribute('aria-selected', on);
        t.tabIndex = on ? 0 : -1;
        document.getElementById(t.getAttribute('aria-controls')).hidden = !on;
      });
    };
    tabs.forEach((t, i) => {
      t.addEventListener('click', () => select(t));
      t.addEventListener('keydown', (e) => {
        if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
        const next = tabs[(i + (e.key === 'ArrowRight' ? 1 : tabs.length - 1)) % tabs.length];
        select(next); next.focus();
      });
    });
    if (/Mac|Win/.test(navigator.platform || '')) select(tabs[1]);
  });

  // ---------- copy buttons ----------
  document.querySelectorAll('.copy').forEach((btn) => {
    btn.addEventListener('click', async () => {
      try { await navigator.clipboard.writeText(btn.dataset.copy); } catch {
        const ta = Object.assign(document.createElement('textarea'), { value: btn.dataset.copy });
        document.body.append(ta); ta.select(); document.execCommand('copy'); ta.remove();
      }
      btn.textContent = 'Copied'; btn.classList.add('done');
      setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('done'); }, 1600);
    });
  });

  // ---------- provider catalog (free providers + data-pack providers) ----------
  const P = window.RGEN_PACKS || { packs: [], providers: [], prices: {}, contact: '' };
  const catalog = D.providers.concat(P.providers);
  const rows = document.getElementById('provider-rows');
  const count = document.getElementById('provider-count');
  const filter = document.getElementById('provider-filter');
  function renderCatalog(q) {
    const term = q.trim().toLowerCase();
    const list = catalog.filter((p) => !term || `${p.n} ${p.c} ${p.d} ${p.pack || ''}`.toLowerCase().includes(term));
    rows.innerHTML = list.map((p) => {
      const call = p.ex || `${p.n}(${p.a})`;
      const badge = p.pack ? ` <a class="pack-badge" href="#pack-${esc(p.pack)}">${esc(p.pack)} pack</a>` : '';
      const samples = p.s ? p.s.map((v) => `<span class="sample" title="${esc(v)}">${esc(v)}</span>`).join('') : `<span class="sample">${esc(p.d)}</span>`;
      return `<tr><td>${esc(call)}${badge}<small>${esc(p.d)}</small></td><td>${esc(p.c)}</td><td>${samples}</td></tr>`;
    }).join('') || '<tr><td colspan="3">No provider matches that. Try a broader word, like <code>name</code> or <code>date</code>.</td></tr>';
    const free = D.providers.length, paid = P.providers.length;
    count.textContent = term
      ? `${list.length} of ${catalog.length} providers match "${q.trim()}".`
      : `${free} free providers` + (paid ? ` + ${paid} in data packs (marked with a badge).` : '.');
  }
  if (rows) {
    renderCatalog('');
    filter.addEventListener('input', () => renderCatalog(filter.value));
  }

  // ---------- data packs ----------
  const grid = document.getElementById('pack-grid');
  if (grid && P.packs.length) {
    const single = P.prices.single || {};
    grid.innerHTML = P.packs.map((k) => {
      const mail = `mailto:${P.contact}?subject=${encodeURIComponent('rgen data pack: ' + k.name)}&body=${encodeURIComponent('Pack: ' + k.name + '\nName or company: \n')}`;
      const head = k.sample.columns.map((c) => `<th>${esc(c)}</th>`).join('');
      const body = k.sample.rows.map((r) => `<tr>${r.map((v) => `<td title="${esc(v)}">${esc(v)}</td>`).join('')}</tr>`).join('');
      const tmpl = k.templates.map((t) => `<li><code>${esc(k.name)}/${esc(t.name)}</code> ${esc(t.description)}</li>`).join('');
      const src = k.sources.map((x) => `${esc(x.source)} (${esc(x.license)})`).join('; ');
      return `<article class="pack" id="pack-${esc(k.name)}">
        <header><h3>${esc(k.title)}</h3><code class="pack-name">${esc(k.name)}</code></header>
        <p class="pack-pitch">${esc(k.pitch)}</p>
        <ul class="pack-bullets">${k.bullets.map((b) => `<li>${esc(b)}</li>`).join('')}</ul>
        <div class="table-scroll pack-sample" tabindex="0" aria-label="Sample rows from the ${esc(k.name)} pack"><table class="data compact"><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table></div>
        <details class="pack-more"><summary>${k.providers} providers${k.templates.length ? `, ${k.templates.length} templates` : ''}, sources</summary>
          ${tmpl ? `<ul class="pack-templates">${tmpl}</ul>` : ''}
          <p class="pack-sources">Sources: ${src}</p>
        </details>
        <footer><span class="pack-price">${esc(single.price || '')} <small>${esc(single.period || '')}</small></span><a class="btn btn-outline" href="${mail}">Buy ${esc(k.name)}</a></footer>
      </article>`;
    }).join('');
  }
  document.querySelectorAll('[data-price]').forEach((el) => {
    const pr = P.prices[el.dataset.price];
    if (!pr) return;
    el.querySelector('.price-value').textContent = pr.price;
    el.querySelector('.price-period').textContent = pr.period;
  });

  // ---------- twin histogram ----------
  const svg = document.getElementById('twin-hist');
  if (svg && D.hist.length) {
    const H = D.hist, max = Math.max(...H.flatMap((b) => [b.real, b.twin]));
    const W = 600, top = 10, base = 226, bw = W / H.length;
    let s = `<line class="axis" x1="0" y1="${base + 0.5}" x2="${W}" y2="${base + 0.5}"/>`;
    H.forEach((b, i) => {
      const hr = (b.real / max) * (base - top), ht = (b.twin / max) * (base - top);
      s += `<rect class="bar-real" x="${i * bw + 2}" y="${base - hr}" width="${bw / 2 - 2}" height="${hr}"><title>$${b.lo}–${b.lo + 20}: real ${(b.real * 100).toFixed(1)}%</title></rect>`;
      s += `<rect class="bar-twin" x="${i * bw + bw / 2}" y="${base - ht}" width="${bw / 2 - 2}" height="${ht}"><title>$${b.lo}–${b.lo + 20}: twin ${(b.twin * 100).toFixed(1)}%</title></rect>`;
    });
    [0, 100, 200, 300].forEach((v) => { s += `<text x="${(v / 400) * W}" y="${base + 20}">$${v}</text>`; });
    s += `<text x="${W}" y="${base + 20}" text-anchor="end">$400+</text>`;
    svg.innerHTML = s;
    document.getElementById('twin-stats').innerHTML =
      '<thead><tr><th></th><th class="num">rows</th><th class="num">median revenue</th><th>top product</th><th class="num">laptop share</th></tr></thead><tbody>' +
      D.stats.map((r) => `<tr><td>${r.src === 'twin' ? 'twin' : 'real'}</td><td class="num">${r.rows.toLocaleString('en-US')}</td><td class="num">$${Number(r.median_revenue).toFixed(1)}</td><td>${esc(r.top_product)}</td><td class="num">${Number(r.laptop_pct).toFixed(1)}%</td></tr>`).join('') + '</tbody>';
  }

  // ---------- Galton board (the one animated moment) ----------
  const cv = document.getElementById('galton');
  const ctx = cv && cv.getContext('2d');
  const ROWS = 12, BINS = ROWS + 1, NB = 420;
  let beads = [], start = 0, raf = 0;
  function seeded(a) { return () => { a = (a + 0x6d2b79f5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  function setup() {
    const r = seeded(7), h = new Array(BINS).fill(0);
    beads = Array.from({ length: NB }, (_, i) => {
      const path = Array.from({ length: ROWS }, () => (r() < 0.5 ? 0 : 1));
      const bin = path.reduce((a, b) => a + b, 0);
      return { t0: i * 0.018, path, bin, stack: h[bin]++ };
    });
  }
  function drawGalton(still) {
    if (!ctx) return;
    const css = getComputedStyle(root);
    const peg = css.getPropertyValue('--peg').trim(), bead = css.getPropertyValue('--bead').trim(), line = css.getPropertyValue('--line').trim();
    const W = cv.width, Hh = cv.height, gap = W / (BINS + 1), pegTop = 40, rowH = 22, binTop = pegTop + ROWS * rowH + 16, floor = Hh - 4, R = 5.2;
    const t = still ? 1e9 : (performance.now() - start) / 1000;
    ctx.clearRect(0, 0, W, Hh);
    ctx.fillStyle = peg;
    for (let j = 0; j < ROWS; j++) for (let k = 0; k <= j; k++) {
      ctx.beginPath(); ctx.arc(W / 2 + (k - j / 2) * gap, pegTop + j * rowH, 2.6, 0, 7); ctx.fill();
    }
    ctx.strokeStyle = line; ctx.lineWidth = 1;
    for (let b = 0; b <= BINS; b++) {
      const x = W / 2 + (b - BINS / 2) * gap;
      ctx.beginPath(); ctx.moveTo(x, binTop); ctx.lineTo(x, floor); ctx.stroke();
    }
    ctx.beginPath(); ctx.moveTo(W / 2 - (BINS / 2) * gap, floor + 0.5); ctx.lineTo(W / 2 + (BINS / 2) * gap, floor + 0.5); ctx.stroke();
    const perRow = Math.max(1, Math.floor(gap / (R * 2.1)));
    let falling = false;
    ctx.fillStyle = bead;
    for (const b of beads) {
      const local = t - b.t0;
      if (local < 0) { falling = true; continue; }
      const fallT = 0.07 * ROWS, dropT = 0.45, binX = W / 2 + (b.bin - ROWS / 2) * gap;
      const col = b.stack % perRow, row = Math.floor(b.stack / perRow);
      const restX = binX + (col - (perRow - 1) / 2) * R * 2.1, restY = floor - R - 1 - row * R * 1.9;
      let x, y;
      if (local < fallT) {
        const s = local / fallT * ROWS, n = Math.floor(s), f = s - n;
        let k = 0; for (let j = 0; j < n; j++) k += b.path[j];
        const next = b.path[n] ?? 0;
        x = W / 2 + (k + next * f - (n + f) / 2) * gap; y = pegTop - 14 + (n + f) * rowH;
        falling = true;
      } else if (local < fallT + dropT) {
        const p = (local - fallT) / dropT;
        x = lerp(binX, restX, p); y = lerp(binTop - 10, restY, p * p); falling = true;
      } else { x = restX; y = restY; }
      if (y < floor) { ctx.beginPath(); ctx.arc(x, y, R, 0, 7); ctx.fill(); }
    }
    if (!still && falling) raf = requestAnimationFrame(() => drawGalton(false));
  }
  const lerp = (a, b, p) => a + (b - a) * p;
  if (cv) {
    setup();
    if (reduceMotion) drawGalton(true);
    else {
      const io = new IntersectionObserver((es) => {
        if (es.some((e) => e.isIntersecting)) { io.disconnect(); start = performance.now(); drawGalton(false); }
      });
      io.observe(cv);
      drawGalton(false);
    }
  }
  window.drawGalton = drawGalton;
})();

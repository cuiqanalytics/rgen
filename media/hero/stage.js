const C = window.CONTENT;
const SQUARE = new URLSearchParams(location.search).get('aspect') === 'square';
if (SQUARE) document.body.classList.add('square');
const DURATION = 52;
window.DURATION = DURATION;
const SW = SQUARE ? 1080 : 1920, SH = 1080;

const $ = (id) => document.getElementById(id);
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const ease = (x) => (x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2);
const prog = (t, a, b) => clamp((t - a) / (b - a));
const eprog = (t, a, b) => ease(prog(t, a, b));
const lerp = (a, b, p) => a + (b - a) * p;
const typed = (s, t, a, b) => s.slice(0, Math.round(s.length * prog(t, a, b)));
const fade = (t, a, b, f = 0.3) => Math.min(prog(t, a, a + f), 1 - prog(t, b - f, b));
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const caret = '<span class="caret"></span>';
const P = '<span class="prompt">$</span> ';

// Window rectangles [left, top, width, height]
const L = SQUARE
  ? { full: [30, 30, 1020, 880], top: [30, 30, 1020, 400], bottom: [30, 450, 1020, 470], offB: [30, 1120, 1020, 470] }
  : { full: [210, 90, 1500, 820], left: [50, 90, 800, 820], right: [880, 90, 990, 820], offR: [1960, 90, 990, 820] };
const LEFT = SQUARE ? L.top : L.left, RIGHT = SQUARE ? L.bottom : L.right, OFF = SQUARE ? L.offB : L.offR;

function place(el, r1, r2 = r1, p = 0) {
  const r = r1.map((v, i) => lerp(v, r2[i], p));
  Object.assign(el.style, { left: r[0] + 'px', top: r[1] + 'px', width: r[2] + 'px', height: r[3] + 'px' });
}

// ---------- background: a faint Galton board, seek-safe (pure function of t) ----------
const bctx = $('beads').getContext('2d');
$('beads').width = SW;
function mulberry(a) { return () => { a |= 0; a = (a + 0x6d2b79f5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const BIN_W = 12, BINS = Math.floor(SW / BIN_W), SIGMA = BINS / 7, BEAD = 8, FALL = 2.4, NB = 1800;
const beads = (() => {
  const r = mulberry(42), out = [], h = new Array(BINS).fill(0);
  for (let i = 0; i < NB; i++) {
    let bin;
    do { bin = Math.round(BINS / 2 + SIGMA * Math.sqrt(-2 * Math.log(r() + 1e-12)) * Math.cos(2 * Math.PI * r())); } while (bin < 0 || bin >= BINS);
    out.push({ t0: i * (DURATION - FALL - 6) / NB, bin, stack: h[bin]++, phase: r() * 6.28 });
  }
  return out;
})();
function drawBeads(t) {
  bctx.clearRect(0, 0, SW, SH);
  const floor = SH - 5;
  for (const b of beads) {
    if (t < b.t0) break;
    const p = prog(t, b.t0, b.t0 + FALL), xEnd = (b.bin + 0.5) * BIN_W, yEnd = floor - b.stack * BEAD;
    let x = xEnd, y = yEnd;
    if (p < 1) {
      // bounce down through the pegs: drift from the centre to its bin with a peg-by-peg zigzag
      x = lerp(SW / 2, xEnd, p) + Math.sin(p * 40 + b.phase) * BIN_W * 0.5 * (1 - p);
      y = lerp(-10, yEnd, p * p);
    }
    bctx.fillStyle = p < 1 ? 'rgba(245,165,36,0.38)' : 'rgba(48,70,240,0.30)';
    bctx.beginPath(); bctx.arc(x, y, BEAD * 0.42, 0, Math.PI * 2); bctx.fill();
  }
}

// ---------- content ----------
const PULL_CMD = 'docker pull ghcr.io/cuiqanalytics/rgen';
const ALIAS = 'rgen() { docker run --rm -v "$PWD:/work" ghcr.io/cuiqanalytics/rgen "$@"; }';
const FLAT_CMD = `rgen run -n 1000 -s 0.42 -p "${C.flatProviders}" customers.csv`;
const CFG_CMD = 'rgen run --config shop.toml shop.duckdb';
const JOIN_CMD = `duckdb -box shop.duckdb -c "${C.joinSql}"`;
const TWIN_CMD = 'rgen twin --scale 2.0 sales.csv twin.duckdb';
const lines = (s) => s.replace(/\n+$/, '').split('\n').filter((l) => l.trim() !== '');

// docker pull, the way a TTY shows it: one line per layer, updated in place
const PULL = lines(C.pull);
function pullView(n) {
  const out = [], idx = {};
  for (const l of PULL.slice(0, n)) {
    const m = l.match(/^([0-9a-f]{12}): (.*)$/);
    if (m) { if (!(m[1] in idx)) { idx[m[1]] = out.length; out.push(''); } out[idx[m[1]]] = `<span class="muted">${m[1]}:</span> ${esc(m[2])}`; }
    else out.push(l.startsWith('Status:') || l.startsWith('ghcr.io') ? `<span class="ok">${esc(l)}</span>` : esc(l));
  }
  return out;
}

function termLines(t) {
  const o = [];
  if (t < 9.8) {
    o.push(P + typed(PULL_CMD, t, 0.5, 1.6) + (t < 1.8 ? caret : ''));
    if (t >= 1.9) o.push(...pullView(Math.round(PULL.length * prog(t, 1.9, 4.8))));
    if (t >= 5.3) o.push(P + esc(typed(ALIAS, t, 5.3, 7.3)) + (t < 7.5 ? caret : ''));
    if (t >= 7.7) o.push(P + typed('rgen --version', t, 7.7, 8.3));
    if (t >= 8.6) o.push(`<span class="muted">${esc(C.version.trim())}</span>`);
  } else if (t < 21) {
    o.push(P + esc(typed(FLAT_CMD, t, 10.1, 12.4)) + (t < 12.6 ? caret : ''));
    if (t >= 12.9) o.push(...lines(C.flat).map((l) => `<span class="ok">${esc(l.trim())}</span>`));
  } else if (t < 34.8) {
    if (t >= 25.6) o.push(P + typed(CFG_CMD, t, 25.6, 26.6));
    const cfg = lines(C.config);
    cfg.forEach((l, i) => { if (t >= 27.0 + i * 0.35) o.push(`<span class="${l.includes('✓') ? 'ok' : 'muted'}">${esc(l)}</span>`); });
    if (t >= 28.4) o.push(P + esc(typed(JOIN_CMD, t, 28.4, 30.3)) + (t < 30.5 ? caret : ''));
    if (t >= 30.8) o.push(`<div class="box">${esc(C.join.replace(/\n+$/, ''))}</div>`);
  } else {
    o.push(P + typed(TWIN_CMD, t, 35.1, 36.4) + (t < 36.6 ? caret : ''));
    lines(C.twin).forEach((l, i) => { if (t >= 36.8 + i * 0.3) o.push(`<span class="${l.includes('✓') ? 'ok' : 'muted'}">${esc(l)}</span>`); });
  }
  return o;
}

function drawTerm(t) {
  const body = $('termBody');
  body.innerHTML = `<div id="tc">${termLines(t).map((l) => (l.startsWith('<div') ? l : `<div>${l}</div>`)).join('')}</div>`;
  const tc = $('tc');
  tc.style.transform = `translateY(${Math.min(0, body.clientHeight - 40 - tc.offsetHeight)}px)`;
  $('termTitle').textContent = t < 9.8 ? '~/demo' : t < 21 ? '~/demo — generate a table' : t < 34.8 ? '~/demo — linked tables' : '~/demo — digital twin';
}

// customers.csv viewer: rows reveal top-down
const COLS = ['first_name', 'last_name', 'email', 'city', 'employer'];
function drawViewer(t) {
  const n = Math.round(C.rows.length * prog(t, 13.5, 15.2));
  const shown = SQUARE ? C.rows.slice(0, 9) : C.rows;
  $('viewBody').innerHTML = `<table class="grid"><tr>${COLS.map((c) => `<th>${c}</th>`).join('')}</tr>${shown.slice(0, n)
    .map((r) => `<tr>${COLS.map((c) => `<td class="${c === 'email' ? 'e' : ''}">${esc(r[c])}</td>`).join('')}</tr>`).join('')}</table>`;
}

// shop.toml editor
function hlToml(l) {
  if (/^\s*#/.test(l)) return `<span class="c">${esc(l)}</span>`;
  if (/^\s*\[/.test(l)) return `<span class="h">${esc(l)}</span>`;
  let s = esc(l).replace(/("[^"]*")/g, '<span class="s">$1</span>').replace(/\b(\d+(?:\.\d+)?)\b/g, '<span class="n">$1</span>');
  s = s.replace(/^(\s*)([a-z_]+)(\s*=)/, '$1<span class="k">$2</span>$3');
  if (l.includes('reference')) s = `<span class="ref">${s}</span>`;
  return s;
}
const TOML = C.toml.replace(/\n+$/, '').split('\n').filter((l) => !/^#/.test(l));
function drawEditor(t) {
  const n = Math.ceil(TOML.length * prog(t, 21.3, 24.8));
  const px = SQUARE ? 13 : 15;
  $('edBody').innerHTML = `<div style="font-size:${px}px">${TOML.slice(0, n).map((l, i) => `<div><span class="ln">${i + 1}</span>${hlToml(l)}</div>`).join('')}</div>`;
}

// twin chart: real (cobalt) vs twin (marigold) revenue histograms
function drawChart(t) {
  const H = C.hist, max = Math.max(...H.flatMap((b) => [b.real, b.twin]));
  const g = eprog(t, 38.0, 40.0), bw = 1000 / H.length;
  let svg = '';
  H.forEach((b, i) => {
    const hr = (b.real / max) * 300 * g, ht = (b.twin / max) * 300 * g;
    svg += `<rect x="${i * bw + 4}" y="${320 - hr}" width="${bw / 2 - 4}" height="${hr}" fill="#3046f0"/>`;
    svg += `<rect x="${i * bw + bw / 2}" y="${320 - ht}" width="${bw / 2 - 4}" height="${ht}" fill="#f5a524"/>`;
  });
  svg += '<line x1="0" y1="320.5" x2="1000" y2="320.5" stroke="#ffffff30"/>';
  $('hist').innerHTML = svg;
  const s = eprog(t, 40.2, 40.8);
  $('stats').style.opacity = s;
  $('stats').innerHTML = '<tr><th></th><th>rows</th><th>median revenue</th><th>top product</th><th>laptop share</th></tr>' +
    C.stats.map((r) => `<tr class="${r.src === 'twin' ? 't' : 'r'}"><td>${r.src}</td><td>${r.rows.toLocaleString('en-US')}</td><td>${Number(r.median_revenue).toFixed(1)}</td><td>${esc(r.top_product)}</td><td>${r.laptop_pct}%</td></tr>`).join('');
}

const CAPS = [
  ['One pull. Runs anywhere Docker does.', 0.6, 9.6],
  ['Describe the columns. Get believable rows.', 13.4, 20.7],
  ['Linked tables. Foreign keys that join.', 22.0, 34.6],
  ['Clone a real dataset, minus the real data.', 37.4, 45.7],
];

function render(t) {
  drawBeads(t);
  const outro = 1 - prog(t, 45.8, 46.5);
  // terminal: full → left at 13.1, back to full at 34.9 for the twin command, left again at 37.4
  const toSide = eprog(t, 13.1, 13.8) * (1 - eprog(t, 34.9, 35.3)) + eprog(t, 37.3, 38.0);
  const term = $('term');
  place(term, L.full, LEFT, clamp(toSide));
  term.style.opacity = prog(t, 0, 0.4) * outro * (t >= 9.75 && t < 10.0 ? 0.6 : 1);
  drawTerm(t);

  const slot = (el, a, b) => {
    const p = eprog(t, a, a + 0.7) * (1 - eprog(t, b, b + 0.6));
    place(el, OFF, RIGHT, p);
    el.style.opacity = p > 0 ? outro : 0;
    return p > 0;
  };
  if (slot($('viewer'), 13.2, 20.6)) drawViewer(t);
  if (slot($('editor'), 20.8, 34.6)) drawEditor(t);
  if (slot($('chart'), 37.4, 99)) drawChart(t);

  const cap = CAPS.find(([, a, b]) => t >= a && t < b);
  $('caption').textContent = cap ? cap[0] : '';
  $('caption').style.opacity = cap ? fade(t, cap[1], cap[2], 0.25) * outro : 0;
  $('caption').style.transform = cap ? `translateY(${(1 - eprog(t, cap[1], cap[1] + 0.35)) * 14}px)` : '';

  const e = eprog(t, 46.4, 47.2);
  $('end').style.opacity = e;
  $('end').style.transform = `scale(${lerp(0.97, 1, e)})`;
  $('mark').style.opacity = 0.9 * outro;
}

window.seek = render;
window.stageReady = document.fonts.ready;

if (!new URLSearchParams(location.search).has('render')) {
  const t0 = performance.now();
  const loop = () => { render(((performance.now() - t0) / 1000) % DURATION); requestAnimationFrame(loop); };
  loop();
} else {
  render(0);
}

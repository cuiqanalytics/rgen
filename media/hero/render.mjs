// Renders stage.html frame by frame (deterministic seek, not screen capture) into MP4.
// Usage: node render.mjs [wide|square] [fps]   — called by build.sh
import { chromium } from '/home/rabt/.local/share/fnm/node-versions/v24.13.0/installation/lib/node_modules/playwright/index.mjs';
import { spawn } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const aspect = process.argv[2] || 'wide';
const fps = +(process.argv[3] || 30);
const only = process.argv[4]; // optional: comma-separated seconds → PNG stills instead of video
const [w, h] = aspect === 'square' ? [1080, 1080] : [1920, 1080];
mkdirSync(path.join(here, 'out'), { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
page.on('pageerror', (e) => console.error('pageerror:', e.message));
await page.goto('file://' + path.join(here, 'stage.html') + '?render&aspect=' + aspect, { waitUntil: 'load' });
await page.evaluate(() => window.stageReady);
await page.waitForTimeout(500);

if (only) {
  for (const t of only.split(',').map(Number)) {
    await page.evaluate((t) => window.seek(t), t);
    await page.screenshot({ path: path.join(here, 'out', `still-${aspect}-${t}.png`) });
  }
  await browser.close();
  process.exit(0);
}

const duration = await page.evaluate(() => window.DURATION);
const out = path.join(here, 'out', aspect === 'square' ? 'rgen-hero-1x1.mp4' : 'rgen-hero-16x9.mp4');
const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(fps), '-i', '-',
  '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out],
  { stdio: ['pipe', 'inherit', 'inherit'] });
const frames = Math.round(duration * fps);
for (let i = 0; i < frames; i++) {
  await page.evaluate((t) => window.seek(t), i / fps);
  const png = await page.screenshot({ type: 'png' });
  if (!ff.stdin.write(png)) await new Promise((r) => ff.stdin.once('drain', r));
  if (i % fps === 0) process.stdout.write(`\r${aspect}: ${i / fps}s / ${duration}s`);
}
ff.stdin.end();
await new Promise((r) => ff.on('close', r));
await browser.close();
console.log('\nwrote', out);

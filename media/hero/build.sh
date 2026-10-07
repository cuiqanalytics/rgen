#!/usr/bin/env bash
# Builds the hero video from real rgen output. See README.md.
#   ./build.sh               → out/rgen-hero-16x9.mp4, out/rgen-hero-1x1.mp4, poster, gif
#   ./build.sh stills 5,15   → PNG stills at those seconds
#   ./build.sh capture       → only re-capture assets/content.js
# Needs docker (with the ghcr.io/cuiqanalytics/rgen image or network access), duckdb,
# ffmpeg, node and a global playwright. No license is needed: every beat is a free feature.
set -euo pipefail
cd "$(dirname "$0")"
HERE=$PWD
IMG=ghcr.io/cuiqanalytics/rgen

W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
cp ../../examples/shop.toml ../../examples/sales.csv "$W/"
strip() { sed 's/\x1b\[[0-9;]*m//g' | tr '\r' '\n' | grep -v '^⠋\|^⠙\|^⠹\|^⠸\|^⠼\|^⠴\|^⠦\|^⠧\|^⠇\|^⠏' | sed 's/^[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏] .*//' | sed '/^\s*$/d'; }
rg() { docker run --rm --user "$(id -u):$(id -g)" -v "$W:/work" "$IMG" "$@"; }

# 1. docker pull — the genuine registry when the image is published, otherwise a local
#    registry serving the same image (host rewritten to ghcr.io; see README.md).
if docker pull "$IMG" > "$W/pull.out" 2>&1 && grep -q "Digest" "$W/pull.out"; then
  docker rmi "$IMG" >/dev/null 2>&1 || true
  docker pull "$IMG" > "$W/pull.out" 2>&1
else
  docker rm -f rgen-hero-registry >/dev/null 2>&1 || true
  docker run -d --rm -p 5555:5000 --name rgen-hero-registry registry:2 >/dev/null
  sleep 2
  docker tag "$IMG" localhost:5555/cuiqanalytics/rgen
  docker push -q localhost:5555/cuiqanalytics/rgen >/dev/null
  # Drop every local tag so the pull really downloads the layers, then restore $IMG.
  docker rmi localhost:5555/cuiqanalytics/rgen "$IMG" >/dev/null
  docker pull localhost:5555/cuiqanalytics/rgen 2>&1 | sed 's#localhost:5555/#ghcr.io/#g' > "$W/pull.out"
  docker tag localhost:5555/cuiqanalytics/rgen "$IMG"
  docker rmi localhost:5555/cuiqanalytics/rgen >/dev/null 2>&1 || true
  docker rm -f rgen-hero-registry >/dev/null
fi

# 2. the real commands, through the container
FLAT='uuid;first_name;last_name;email_from_name(first_name,last_name) as email;city;company as employer'
rg --version > "$W/version.out"
rg run -n 1000 -s 0.42 -p "$FLAT" customers.csv 2>&1 | strip > "$W/flat.out"
rg run --config shop.toml shop.duckdb 2>&1 | strip > "$W/config.out"
JOIN="SELECT c.country, count(*) AS orders, round(avg(o.amount), 2) AS avg_amount FROM orders o JOIN customers c USING (customer_id) GROUP BY ALL ORDER BY orders DESC"
(cd "$W" && duckdb -box shop.duckdb -c "$JOIN") > "$W/join.out"
rg twin --scale 2.0 sales.csv twin.duckdb 2>&1 | strip > "$W/twin.out"

# 3. data for the on-screen panels
(cd "$W" && duckdb -json -c "SELECT first_name, last_name, email, city, employer FROM 'customers.csv' LIMIT 14") > "$W/rows.json"
(cd "$W" && duckdb -json twin.duckdb -c "
  WITH r AS (SELECT revenue FROM 'sales.csv'), t AS (SELECT revenue FROM data),
  b AS (SELECT range * 20 AS lo FROM range(0, 20))
  SELECT lo,
    (SELECT count(*) FROM r WHERE revenue >= lo AND revenue < lo + 20) / (SELECT count(*) FROM r) AS real,
    (SELECT count(*) FROM t WHERE revenue >= lo AND revenue < lo + 20) / (SELECT count(*) FROM t) AS twin
  FROM b ORDER BY lo") > "$W/hist.json"
(cd "$W" && duckdb -json twin.duckdb -c "
  SELECT 'real' AS src, count(*) AS rows, round(median(revenue), 1) AS median_revenue, mode(product) AS top_product,
         round(100 * avg((product = 'Laptop')::INT), 1) AS laptop_pct FROM 'sales.csv'
  UNION ALL
  SELECT 'twin', count(*), round(median(revenue), 1), mode(product), round(100 * avg((product = 'Laptop')::INT), 1) FROM data") > "$W/stats.json"

if grep -rqi cuiqgen "$W"/*.out; then echo "error: captured output mentions cuiqgen" >&2; exit 1; fi

node -e '
const fs = require("fs"), W = process.argv[1], r = (f) => fs.readFileSync(W + "/" + f, "utf8");
const c = { pull: r("pull.out"), version: r("version.out"), flatProviders: process.argv[2], flat: r("flat.out"),
  rows: JSON.parse(r("rows.json")), toml: r("shop.toml"), config: r("config.out"), joinSql: process.argv[3],
  join: r("join.out"), twin: r("twin.out"), hist: JSON.parse(r("hist.json")), stats: JSON.parse(r("stats.json")) };
fs.writeFileSync("content.js", "window.CONTENT = " + JSON.stringify(c, null, 1) + ";\n");
' "$W" "$FLAT" "$JOIN"
echo "captured → content.js"

[[ "${1:-}" == capture ]] && exit
if [[ "${1:-}" == stills ]]; then
  node render.mjs wide 30 "$2"; node render.mjs square 30 "$2"; exit
fi
node render.mjs wide 30
node render.mjs square 30
ffmpeg -y -loglevel error -ss 41 -i out/rgen-hero-16x9.mp4 -frames:v 1 out/rgen-hero-poster.png
ffmpeg -y -loglevel error -ss 10.5 -t 9 -i out/rgen-hero-16x9.mp4 \
  -vf "fps=12,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer" \
  out/rgen-hero.gif
cp out/rgen-hero-16x9.mp4 ../rgen-hero.mp4
cp out/rgen-hero-1x1.mp4 ../rgen-hero-square.mp4
cp out/rgen-hero.gif ../rgen-hero.gif
ffmpeg -y -loglevel error -i out/rgen-hero-poster.png -q:v 4 ../rgen-hero-poster.jpg
ls -la ..

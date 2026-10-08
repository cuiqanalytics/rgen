#!/usr/bin/env bash
# site-packs.sh: build packs.js (the website's data-pack catalogue) from the real pack files.
#
#   ./site-packs.sh            # reads ../cuiqGEN/src/dist/packs/*.rgenpack
#
# Installs every pack into throwaway RGEN_DATA_DIR/CUIQ_HOME dirs, licensed with a 1-day key minted
# by ../cuiqlicense/tools/generate-license.js (your real ~/.cuiq is never touched), then collects
# metadata, templates, sources, provider descriptions, sample values and showcase rows.
# Prices and the marketing copy for each pack live in the PACKS block below.
set -euo pipefail
cd "$(dirname "$0")"
HERE=$PWD
PACK_DIR=${PACK_DIR:-../cuiqGEN/src/dist/packs}
LIC=${CUIQLICENSE_DIR:-../cuiqlicense}
RGEN=${RGEN:-rgen}
[[ -d $PACK_DIR ]] || { echo "error: $PACK_DIR not found (make pack NAME=<pack> in cuiqGEN/src)" >&2; exit 1; }

# ------------------------------------------------------------------ prices & copy (edit here)
PRICES='{"single": {"label": "Single pack", "price": "$79", "period": "per year"},
         "all":    {"label": "All packs",   "price": "$199", "period": "per year"}}'
CONTACT=rodrigo.abt@gmail.com
PACKS='[
 {"name": "fintech", "pitch": "Card, bank and ledger data that passes real validators.",
  "bullets": ["Luhn-valid test cards for 7 networks in a realistic mix", "IBANs for 55 countries with national check digits, plus BIC, US routing numbers and Mexican CLABE", "981 merchant category codes with spend categories, merchant names and realistic ticket sizes", "Chart of accounts (EN/ES) and journal entries that always balance"]},
 {"name": "latam", "pitch": "Latin American people, IDs and places that look local.",
  "bullets": ["Chile, Argentina, Mexico, Brazil, Colombia, Peru and Uruguay", "RUT, CUIT, CURP, RFC, CPF, CNPJ, NIT, RUC and CI with valid check digits; CURP and RFC built from the person", "17,000 population-weighted places with ISO regions, matching postal codes and phone area codes", "Local names, banks, company legal forms, plates, and Chilean pensions and health insurers"]},
 {"name": "hr", "pitch": "Employees, org charts and pay that hang together.",
  "bullets": ["1,016 occupations and 54,000 real job titles (O*NET)", "Departments, seniority and management ladders, tasks, tech skills and education", "Salaries from BLS wage data by occupation, level and US state", "Templates: employees, org chart, compensation, recruiting pipeline"]},
 {"name": "saas-analytics", "pitch": "Product analytics data for dashboards, funnels and experiments.",
  "bullets": ["Real-looking user agents that parse back to browser, OS and device", "Traffic sources with UTM parameters, channels and referrers, including AI assistants", "Event taxonomies for B2B SaaS, e-commerce and mobile apps with JSON properties", "Plans, seats and MRR; growth-shaped timestamps; funnel, subscription and A/B test templates"]},
 {"name": "jobs-pro", "pitch": "A large custom list of job titles and composable role names.",
  "bullets": ["10,000+ curated job titles", "Composed titles from seniority/function modifiers and base roles"]}
]'

# Showcase config per pack: a few columns that show what the pack does (3 rows go on the site).
showcase() {
  case $1 in
    fintech) cat <<'T'
  network  = { provider = "fin_card_network" }
  card     = { derived = "rand_fin_masked_pan(rand_fin_card_number(network))" }
  iban     = { provider = "fin_iban" }
  mcc      = { provider = "fin_mcc" }
  category = { derived = "rand_fin_mcc_category(mcc)" }
  merchant = { derived = "rand_fin_merchant_name(mcc)" }
  amount   = { derived = "rand_fin_amount(mcc)" }
T
    ;;
    latam) cat <<'T'
  country  = { provider = "latam_country" }
  place_id = { derived = "rand_latam_place(country)" }
  sex      = { provider = "latam_sex" }
  given    = { derived = "rand_latam_given_name(country, sex)" }
  s1       = { derived = "rand_latam_surname(country)" }
  s2       = { derived = "rand_latam_second_surname(country)" }
  bdate    = { provider = "latam_birthdate" }
  name     = { derived = "rand_latam_full_name(given, s1, s2)" }
  id       = { derived = "CASE WHEN country = 'MX' THEN rand_latam_curp(given, s1, s2, bdate, sex, place_id) ELSE rand_latam_national_id(country) END" }
  city     = { derived = "rand_latam_city(place_id) || ', ' || rand_latam_region_code(place_id)" }
  postal   = { derived = "rand_latam_postal_code(place_id)" }
  mobile   = { derived = "rand_latam_mobile(place_id)" }
T
    ;;
    hr) cat <<'T'
  department = { provider = "hr_department" }
  soc        = { derived = "rand_hr_soc_code_in(department)" }
  job_title  = { derived = "rand_hr_job_title(soc)" }
  level      = { provider = "hr_seniority" }
  state      = { provider = "state_code" }
  salary     = { derived = "rand_hr_salary_in(soc, level, state)" }
  top_skill  = { derived = "rand_hr_tech_skill(soc)" }
T
    ;;
    saas-analytics) cat <<'T'
  source     = { provider = "saas_traffic_source" }
  channel    = { derived = "rand_saas_channel(source)" }
  ua         = { provider = "saas_user_agent" }
  browser    = { derived = "rand_saas_browser(ua) || ' / ' || rand_saas_os(ua) || ' / ' || rand_saas_device(ua)" }
  event      = { derived = "rand_saas_event('b2b_saas')" }
  properties = { derived = "rand_saas_event_properties(event)::VARCHAR" }
T
    ;;
    jobs-pro) cat <<'T'
  title    = { provider = "job_title_pro" }
  composed = { provider = "job_title_composed" }
T
    ;;
  esac
}

# ------------------------------------------------------------------ sandbox
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export RGEN_DATA_DIR=$T/data CUIQ_HOME=$T/home
mkdir -p "$RGEN_DATA_DIR" "$T/out"
KEY=$(node "$LIC/tools/generate-license.js" --user site-packs --features 'rgen:pack:*' --days 1 2>&1 | head -1)
"$RGEN" license install "$KEY" > /dev/null
for f in "$PACK_DIR"/*.rgenpack; do "$RGEN" packs install "$f" > /dev/null; done

# Provider list with arguments and descriptions, from rgen itself (pack providers say "(<pack> pack)").
"$RGEN" providers | sed 's/\x1b\[[0-9;]*m//g' > "$T/providers.txt"

for f in "$PACK_DIR"/*.rgenpack; do
  name=$(basename "$f" .rgenpack)
  duckdb -readonly -json "$f" -c "SELECT * FROM _pack_meta" > "$T/out/$name.meta.json"
  duckdb -readonly -json "$f" -c "SELECT * FROM (SELECT dataset, source, url, license FROM _pack_sources) UNION ALL SELECT NULL, NULL, NULL, NULL WHERE false" > "$T/out/$name.sources.json" 2>/dev/null \
    || echo '[]' > "$T/out/$name.sources.json"
  duckdb -readonly -json "$f" -c "SELECT name, description FROM _pack_templates ORDER BY name" > "$T/out/$name.templates.json" 2>/dev/null \
    || echo '[]' > "$T/out/$name.templates.json"
  duckdb -readonly -json "$f" -c "SELECT regexp_extract(sql, 'COMMENT ON MACRO (\w+) IS ''(\w+)\|', 1) AS macro,
                                         regexp_extract(sql, 'COMMENT ON MACRO (\w+) IS ''(\w+)\|', 2) AS category
                                  FROM _pack_macros WHERE sql LIKE 'COMMENT ON MACRO%'" > "$T/out/$name.cats.json"
  # Showcase rows
  { echo '[[tables]]'; echo 'name = "showcase"'; echo 'rows = 3'; echo; echo '  [tables.columns]'; showcase "$name"; echo
    echo '[output]'; echo 'format = "csv"'; } > "$T/$name.toml"
  "$RGEN" run --config "$T/$name.toml" "$T/out/$name.showcase" > /dev/null
done

# Sample values for every provider that runs without arguments (3 rows each).
python3 - "$T" <<'PY'
import re, subprocess, sys, csv, os, json
T = sys.argv[1]
rows = []
for line in open(f'{T}/providers.txt'):
    m = re.match(r'^\s*(\w+)\(([^)]*)\):\s*(.*?)\s*\((\S+) pack\)\s*$', line)
    if m:
        rows.append({'n': m.group(1), 'a': m.group(2), 'd': m.group(3), 'pack': m.group(4)})
for r in rows:
    if r['a'].strip():
        continue
    out = f"{T}/s_{r['n']}.csv"
    p = subprocess.run([os.environ.get('RGEN', 'rgen'), 'run', '-n', '3', '-p', r['n'], out], capture_output=True, text=True)
    if p.returncode == 0 and os.path.exists(out):
        r['s'] = [row[0] for row in list(csv.reader(open(out)))[1:4]]
json.dump(rows, open(f'{T}/out/providers.json', 'w'))
PY

python3 - "$T" "$HERE/packs.js" "$PRICES" "$PACKS" "$CONTACT" <<'PY'
import json, sys, csv, glob
T, dest, prices, packs, contact = sys.argv[1], sys.argv[2], json.loads(sys.argv[3]), json.loads(sys.argv[4]), sys.argv[5]
providers = json.load(open(f'{T}/out/providers.json'))
cats = {}
out = []
for p in packs:
    n = p['name']
    try:
        meta = json.load(open(f'{T}/out/{n}.meta.json'))[0]
    except FileNotFoundError:
        print(f'skip {n}: no built pack', file=sys.stderr)
        continue
    for c in json.load(open(f'{T}/out/{n}.cats.json')):
        cats[c['macro']] = c['category']
    rows = list(csv.DictReader(open(glob.glob(f'{T}/out/{n}.showcase/*.csv')[0])))
    hidden = {'place_id', 'soc', 'sex', 'ua', 'mcc', 'given', 's1', 's2', 'bdate'}
    cols = [c for c in rows[0].keys() if c not in hidden]
    out.append({
        'name': n, 'title': meta['title'], 'version': meta['version'], 'pitch': p['pitch'], 'bullets': p['bullets'],
        'providers': sum(1 for x in providers if x['pack'] == n),
        'templates': json.load(open(f'{T}/out/{n}.templates.json')),
        'sources': [s for s in json.load(open(f'{T}/out/{n}.sources.json')) if s.get('dataset')],
        'sample': {'columns': cols, 'rows': [[r[c] for c in cols] for r in rows]},
    })
for x in providers:
    x['c'] = cats.get('rand_' + x['n'], 'pack')
data = {'prices': prices, 'contact': contact, 'packs': out, 'providers': providers}
with open(dest, 'w') as f:
    f.write('// Generated by site-packs.sh from the built data packs. Do not edit by hand.\n')
    f.write('window.RGEN_PACKS = ' + json.dumps(data, ensure_ascii=False, indent=1) + ';\n')
print(f'packs.js: {len(out)} packs, {len(providers)} pack providers, {sum(1 for x in providers if x.get("s"))} with samples')
PY

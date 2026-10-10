#!/usr/bin/env bash
# site-packs.sh: build packs.js (the website's data-pack catalogue) from the real pack files.
#
#   ./site-packs.sh            # reads ../cuiqGEN/src/dist/packs/*.rgenpack
#
# Installs every pack into throwaway RGEN_DATA_DIR/CUIQ_HOME dirs, licensed with a 1-day key minted
# by ../cuiqlicense/tools/generate-license.js (your real ~/.cuiq is never touched), then collects
# metadata, templates, sources, provider descriptions, sample values and showcase rows.
# Prices and the marketing copy for each pack live in the PACKS block below.
#
# Also writes the Claude skill's pack references, skills/rgen/references/packs/<pack>.md: the
# curated guidance in ../cuiqGEN/lookup_data/packs/<pack>/skill.md plus provider and template
# lists read from the pack. Every recipe in the guidance (rgen lines in ```bash blocks and whole
# ```toml blocks) is executed; the script fails if one breaks.
set -euo pipefail
cd "$(dirname "$0")"
HERE=$PWD
PACK_DIR=${PACK_DIR:-../cuiqGEN/src/dist/packs}
GUIDE_DIR=${GUIDE_DIR:-../cuiqGEN/lookup_data/packs}
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
 {"name": "weather", "pitch": "Weather that behaves like weather, for demand, energy and IoT models.",
  "bullets": ["Stations in 105 cities across tropical, arid, temperate, continental and polar climates", "Sky conditions weighted by season and climate (no tropical snow), temperatures following each station\u2019s seasonal curve, flipped south of the equator", "Consistent daily and hourly series: warm and cold spells persist, snow only when cold, clear skies at night", "Templates: station catalog, daily, hourly, and an IoT sensor feed with dropouts and error codes"]},
 {"name": "healthcare", "pitch": "Patients, diagnoses, prescriptions, labs and claims that agree with each other.",
  "bullets": ["Real ICD-10-CM codes that respect age and sex (no pregnancy codes for men, no newborn codes for adults), weighted by how common each condition is", "Real FDA NDC drug packages matched to the condition, with strength, form, days supply and refills", "Lab results (LOINC) that shift with disease: high HbA1c for diabetics, high TSH for hypothyroidism, flagged against reference ranges", "NPIs with valid check digits, Medicare MBI-format member IDs, places of service, payers by age, charges, allowed and paid amounts, denials; templates for patients, a full patient journey and claims"]},
 {"name": "security-logs", "pitch": "Security logs with labelled attacks, for detection rules, SIEM demos and ML.",
  "bullets": ["Web access (NGINX combined), sshd auth.log, firewall flows and CloudTrail-style JSON in real formats", "13 attack scenarios with ground-truth labels: scans, SQL injection, Log4Shell, credential stuffing, SSH brute force, port scans, exfiltration, C2 beacons, cloud key abuse and logging tampering", "Attackers recur from fixed IPs and strike in bursts; C2 beacons every minute; normal traffic follows the working day", "MITRE ATT&CK techniques and tactics, CISA KEV CVEs, and a SIEM alert queue template"]},
 {"name": "insurance", "pitch": "Policies, premiums and claims for auto, home, renters and term life.",
  "bullets": ["Premiums driven by rating factors: driver age, vehicle value, deductible, state, prior claims, home age and roof, tobacco class and term", "VINs with real manufacturer codes, model-year codes and valid check digits for 55 popular models (checked against NHTSA vPIC)", "Claim causes that follow the coverage and the state\u2019s peril: hurricanes in Florida, hail in Oklahoma, wildfire in California", "A consistent claim lifecycle: report and close dates, open, litigation and closed statuses, deductibles, paid amounts and reserves"]},
 {"name": "logistics", "pitch": "Containers, air cargo, parcels and warehouse moves on real lanes.",
  "bullets": ["ISO 6346 container numbers, IATA air waybills, UPS and USPS tracking numbers and GS1 SSCC labels, all with valid check digits", "The 66 largest container ports and 3,000+ airports, with sea distances that follow Suez, Panama and transpacific routes", "Transit times, ETAs and delays, ocean and air rates, parcel zones, costs and outcomes", "JSON tracking histories (pickup, hub scans, exceptions, delivery) and a warehouse movement log"]},
 {"name": "retail", "pitch": "Product catalogs, orders, returns and store inventory that agree with each other.",
  "bullets": ["63 categories in 17 departments: names, sizes, colors and prices that fit the category (shoe sizes by gender, TVs by screen, no colors on groceries)", "GTIN-13, UPC-A, case GTIN-14 and ISBN-13 with valid check digits and one GS1 company prefix per brand", "Orders on the retail calendar (December, weekends, Black Friday, Cyber Monday) with seasonal categories, channels, fulfilment, payment and discounts", "Returns by category and channel with fitting reasons (too small, defective, expired), and store inventory with demand, lead times, reorder points and stock status"]},
 {"name": "telecom", "pitch": "Mobile subscribers, CDRs, data sessions and churn on real operators.",
  "bullets": ["51 operators in 14 countries with their real MCC/MNC; mobile numbers that libphonenumber accepts for the country", "IMSI, ICCID and IMEI with valid check digits; handsets and plans that fit the segment (budget phones on prepaid, Cat-M1 modules on IoT)", "Call and SMS detail records with Q.850 causes, drops by radio technology, roaming and charges; data sessions sized by app and 5G/LTE", "Activation and churn driven by plan and complaints, churn reasons, and a subscriber-by-month usage and billing grid with taxes"]},
 {"name": "energy", "pitch": "Smart-meter reads, solar, bills and outages that follow the weather and the sun.",
  "bullets": ["Residential, commercial and industrial premises in 23 cities with AC, heating type, EVs and rooftop solar that fit the climate", "Hourly or 15-minute reads: evening peaks at home, office hours at work, cooling above 22 C, electric heat below 15 C, evening EV charging", "Solar output from the sun\u2019s elevation by latitude, season and hour, with cloudy days; net import and export; utility plants with tracking", "Monthly totals that sum the same hourly reads, bills on flat, tiered, time-of-use and demand tariffs, and an outage log by cause"]},
 {"name": "education", "pitch": "Students, programs, grades and LMS activity for higher-ed analytics.",
  "bullets": ["Real CIP 2020 programs weighted by national IPEDS completions, from associate to doctoral, with gender mixes that follow each program", "Cohorts, retention, graduation and withdrawal driven by ability, first-generation status and level; GPAs, credits and class years that agree", "Course catalogs by subject, letter grades shaped by ability and course difficulty, absences that track grades", "LMS clickstreams with midterm and finals peaks and Sunday-night submissions before the deadline"]},
 {"name": "travel", "pitch": "Flights, bookings, fares, delays and hotel stays on real routes.",
  "bullets": ["23 real airlines with IATA codes, ticketing prefixes and hubs flying to 3,000+ real airports: domestic spokes for US carriers, gateways for Gulf and Asian carriers", "Great-circle distances, aircraft for the stage length, departure banks and block times", "Bookings with PNRs, 13-digit ticket numbers, cabins, fare classes, seats, fares by distance, lead time and season, loyalty miles, cancellations and refunds", "Delays and cancellations with BTS-style causes and load factors, plus hotel stays with rates by class, country and season"]},
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
    weather) cat <<'T'
  station = { provider = "weather_station" }
  city    = { derived = "rand_weather_station_city(station)" }
  zone    = { derived = "rand_weather_station_zone(station)" }
  day     = { derived = "DATE '2025-01-01' + (random() * 364)::INT" }
  sky     = { derived = "rand_weather_daily_sky(station, day)" }
  temp_c  = { derived = "rand_weather_temp_mean(station, day)" }
T
    ;;
    healthcare) cat <<'T'
  sex       = { provider = "gender" }
  age       = { provider = "healthcare_age" }
  diagnosis = { derived = "rand_healthcare_diagnosis(sex, age)" }
  condition = { derived = "rand_healthcare_condition(diagnosis)" }
  ndc       = { derived = "rand_healthcare_ndc(condition)" }
  drug      = { derived = "rand_healthcare_drug_generic(ndc) || ' ' || rand_healthcare_drug_strength(ndc)" }
  payer     = { derived = "rand_healthcare_payer(age)" }
T
    ;;
    security-logs) cat <<'T'
  scenario  = { derived = "rand_sec_scenario('web', 0.3)" }
  client_ip = { derived = "rand_sec_src_ip(scenario)" }
  method    = { derived = "rand_sec_http_method(scenario)" }
  path      = { derived = "rand_sec_path(scenario)" }
  status    = { derived = "rand_sec_http_status(scenario)" }
  technique = { derived = "rand_sec_technique(scenario)" }
T
    ;;
    insurance) cat <<'T'
  vehicle    = { provider = "ins_vehicle" }
  model_year = { derived = "rand_ins_model_year(vehicle)" }
  vin        = { derived = "rand_ins_vin(vehicle, model_year)" }
  car        = { derived = "rand_ins_make(vehicle) || ' ' || rand_ins_model(vehicle)" }
  state      = { provider = "state_code" }
  peril      = { derived = "rand_ins_peril(state)" }
  cause      = { derived = "rand_ins_loss_cause('home', 'full', state)" }
T
    ;;
    logistics) cat <<'T'
  container = { provider = "logistics_container_number" }
  pol       = { provider = "logistics_port" }
  pod       = { derived = "rand_logistics_destination_port(pol)" }
  lane      = { derived = "rand_logistics_port_name(pol) || ' > ' || rand_logistics_port_name(pod)" }
  nm        = { derived = "rand_logistics_sea_distance_nm(pol, pod)" }
  carrier   = { provider = "logistics_parcel_carrier" }
  service   = { derived = "rand_logistics_parcel_service(carrier)" }
  tracking  = { derived = "rand_logistics_tracking_number(service)" }
T
    ;;
    retail) cat <<'T'
  item     = { provider = "retail_item" }
  gtin     = { derived = "rand_retail_gtin(item)" }
  name     = { derived = "rand_retail_product_name(item)" }
  category = { derived = "rand_retail_category(item)" }
  price    = { derived = "rand_retail_list_price(item)" }
  channel  = { provider = "retail_channel" }
  returned = { derived = "rand_retail_returned(item, channel)" }
  reason   = { derived = "rand_retail_return_reason(item, returned)" }
T
    ;;
    telecom) cat <<'T'
  sub      = { provider = "telecom_subscriber" }
  country  = { derived = "rand_telecom_country(sub)" }
  operator = { derived = "rand_telecom_operator(sub)" }
  msisdn   = { derived = "rand_telecom_msisdn(sub)" }
  imei     = { derived = "rand_telecom_imei(sub)" }
  plan     = { derived = "rand_telecom_plan(sub)" }
  status   = { derived = "rand_telecom_status(sub)" }
T
    ;;
    energy) cat <<'T'
  meter    = { provider = "energy_meter" }
  city     = { derived = "rand_energy_city(meter)" }
  class    = { derived = "rand_energy_customer_class(meter)" }
  solar_kw = { derived = "rand_energy_solar_kw(meter)" }
  tariff   = { derived = "rand_energy_tariff(meter)" }
  kwh_7pm  = { derived = "rand_energy_kwh(meter, TIMESTAMP '2025-07-15 19:00:00')" }
T
    ;;
    education) cat <<'T'
  student = { provider = "edu_student" }
  level   = { derived = "rand_edu_level(student)" }
  cip     = { derived = "rand_edu_cip(student)" }
  program = { derived = "rand_edu_program(student)" }
  sex     = { derived = "rand_edu_sex(student)" }
  status  = { derived = "rand_edu_status(student)" }
  gpa     = { derived = "rand_edu_gpa(student)" }
T
    ;;
    travel) cat <<'T'
  flight      = { provider = "travel_flight" }
  flight_no   = { derived = "rand_travel_flight_number(flight)" }
  origin      = { derived = "rand_travel_origin(flight)" }
  destination = { derived = "rand_travel_destination(flight)" }
  km          = { derived = "rand_travel_distance_km(flight)" }
  aircraft    = { derived = "rand_travel_aircraft(flight)" }
  pnr         = { provider = "travel_pnr" }
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
    hidden = {'place_id', 'soc', 'sex', 'ua', 'mcc', 'given', 's1', 's2', 'bdate', 'station'}
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

# ------------------------------------------------------------------ Claude skill references
mkdir -p "$HERE/skills/rgen/references/packs"
python3 - "$T" "$HERE/skills/rgen/references/packs" "$GUIDE_DIR" "$PACK_DIR" <<'PY'
import json, os, re, subprocess, sys, tempfile
T, dest, guides, packdir = sys.argv[1:5]
rgen = os.environ.get('RGEN', 'rgen')
providers = json.load(open(f'{T}/out/providers.json'))
failures = []

def check(cmd, cwd, label):
    p = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    out = p.stdout + p.stderr
    if p.returncode != 0 or 'ERROR' in out:
        failures.append(f'{label}: {cmd[:90]}\n    {out.strip().splitlines()[-1] if out.strip() else "exit " + str(p.returncode)}')

for f in sorted(os.listdir(packdir)):
    if not f.endswith('.rgenpack'):
        continue
    name = f[:-len('.rgenpack')]
    guide_path = os.path.join(guides, name, 'skill.md')
    if not os.path.exists(guide_path):
        print(f'warning: no {guide_path}, skipping skill reference for {name}', file=sys.stderr)
        continue
    guide = open(guide_path).read().strip()
    meta = json.load(open(f'{T}/out/{name}.meta.json'))[0]
    templates = json.load(open(f'{T}/out/{name}.templates.json'))
    # Execute the guide's recipes in a scratch directory.
    work = tempfile.mkdtemp(dir=T)
    for i, (lang, body) in enumerate(re.findall(r'```(bash|toml)\n(.*?)```', guide, re.S)):
        if lang == 'bash':
            for line in body.splitlines():
                if line.strip().startswith('rgen '):
                    check(line.strip(), work, name)
        else:
            path = os.path.join(work, f'recipe{i}.toml')
            open(path, 'w').write(body)
            check(f'{rgen} run --config {path} {work}/recipe{i}.duckdb', work, name)
    rows = [p for p in providers if p['pack'] == name]
    lines = [f'# Data pack: {name} ({meta["title"]} {meta["version"]})', '',
             f'Generated by rgen-cli/site-packs.sh from the pack; edit lookup_data/packs/{name}/skill.md in cuiqGEN instead.',
             'Read only when `rgen packs list` shows this pack as licensed.', '', guide, '',
             '## All providers', '', 'Use in `-p` without the `rand_` prefix; in TOML `derived` expressions with it.', '']
    lines += [f'- `{p["n"]}({p["a"]})`: {p["d"]}' for p in sorted(rows, key=lambda p: p['n'])]
    if templates:
        lines += ['', '## Templates', '', 'Print one with `rgen templates <pack>/<name> > file.toml`, edit, then `rgen run --config file.toml out.duckdb`.', '']
        lines += [f'- `{name}/{t["name"]}`: {t["description"]}' for t in templates]
    open(os.path.join(dest, f'{name}.md'), 'w').write('\n'.join(lines) + '\n')
    print(f'skill reference: references/packs/{name}.md ({len(rows)} providers, {len(templates)} templates)')
if failures:
    print('recipe failures:\n  ' + '\n  '.join(failures), file=sys.stderr)
    sys.exit(1)
print('all skill recipes ran')
PY

# rgen quick reference

## Commands

| Command | What it does |
|---|---|
| `rgen run [flags] OUTPUT` | Generate one table from a provider string, or many from `--config` |
| `rgen providers [--search T] [--category C]` | List built-in providers (`--external-udf F` lists yours) |
| `rgen profile [--output F] SOURCE` | Infer a TOML config from CSV / Parquet / SQLite / DuckDB (`file.duckdb::table`) |
| `rgen twin [--scale X] [--impurity-profile P] [--save-profile F] SOURCE OUTPUT` | Profile + generate in one step |
| `rgen scenarios SCENARIOS.toml OUTPUT_DIR` | Generate variants of a base config |
| `rgen templates [NAME]` | List or print built-in TOML templates (`users`, `orders`, `events`...) |
| `rgen init [--template NAME]` | Scaffold a TOML config |
| `rgen serve` | Local HTTP API + web UI on port 7842 |
| `rgen ask "REQUEST"` | Natural language → data (needs `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`) |
| `rgen packs list\|install\|info\|remove` | Manage data packs (`install` takes a pack name or a `.rgenpack` file) |
| `rgen license install KEY` | Install a license that unlocks data packs (stored in `~/.cuiq/license.json`) |
| `rgen templates PACK/NAME` | Print a data pack's ready-made config, e.g. `fintech/card-transactions` |

All flags go **before** positional arguments.

## `rgen run` flags

| Flag | Meaning |
|---|---|
| `-n, --number N` | Rows to generate (default 100) |
| `-p, --providers "a;b;c"` | Semicolon-separated providers, with optional `(args)` and `as alias` |
| `-c, --config FILE.toml` | Multi-table / timeseries / state-machine config |
| `-s, --seed X` | Reproducible output, X in [-1, 1] |
| `--preview` / `--preview-rows N` | Print a sample table instead of writing a file |
| `--template events` | Built-in column preset |
| `--impurity X` | Fraction of cells to corrupt (0–1) |
| `--impurity-profile P` | `clean` 0 · `realistic` 0.03 · `noisy` 0.10 · `dirty` 0.25 · `chaotic` 0.50 |
| `--external-udf FILE.sql` | Load your own `rand_*` DuckDB macros as providers |
| `--verbose` | More detailed output |

## Output formats

The format is picked from the extension: `.csv` `.json` `.parquet` `.xlsx` (≤ ~1M rows).
For configs, use `.duckdb` / `.db` (DuckDB) or `.sqlite`. Any other path becomes a
directory with one CSV per table.

## Provider syntax

```text
uuid                                     no arguments
int(18,90)                               arguments
first_name('es')                         locale
email_from_name(first_name,last_name)    computed from earlier columns
company as employer                      alias
weighted(['free','pro'],[80,20])         weighted choice
```

## Providers

*Available Data Providers (101 total)*

### analytics

- `event_properties_json()` — JSON string: sample event_properties (page, referrer, experiment_variant, revenue_cents)
- `user_properties_json()` — JSON string: sample user_properties (plan, signup_cohort)

### animals

- `animal_farm()` — farm animal
- `animal_petname()` — pet name
- `animal_type()` — animal type
- `cat_breed()` — cat breed

### banking

- `bank_account()` — bank account number
- `bank_name()` — bank name
- `iban()` — IBAN

### colors

- `color_safe()` — web-safe color

### common

- `amount(low,high,res)` — amount between `low` (integer) and `high` (integer), both inclusive, with specified resolution `res` (integer, default 1). For example: amount(1000,2000,100)
- `bool()` — boolean (true or false)
- `choice(arr)` — element from an array, for example: choice(['a','b','c'])
- `hex()` — hexadecimal digit
- `letter()` — letter
- `literal(val)` — literal value
- `rgb_hex()` — RGB color in hexadecimal format
- `sentence(words)` — sentence with `words` (default 10) random words
- `weighted(arr,weights)` — element from an array based on the weights

### currency

- `currency_code()` — currency code

### dates

- `date(min_date,max_date,format)` — date between two dates
- `timestamp(min_ts,max_ts)` — timestamp between two timestamps

### distributions

- `beta(α,β)` — value from Beta distribution (0-1 range) with parameters `α` and `β`
- `exponential(λ)` — value from exponential distribution with rate `λ`
- `lognormal(μ,σ)` — value from lognormal distribution with given mean `μ` and standard deviation `σ`
- `normal(μ,σ)` — value from a normal distribution with given mean `μ` and standard deviation `σ`
- `pareto(xmin,α)` — value from Pareto distribution with minimum value `xmin` and shape `α`
- `poisson(λ)` — approximate random value from Poisson distribution with parameter `λ`
- `uniform(a,b)` — value from uniform distribution between `a` and `b`
- `weibull(shape,scale)` — value from Weibull distribution with shape `shape` and scale `scale`
- `zipf(n,alpha)` — power-law integer (Zipf) with n ranks and exponent alpha (e.g. alpha=1.0)

### identifiers_and_passwords

- `mac_address()` — MAC address in xx:xx:xx:xx:xx:xx format
- `password(n)` — password with `n` characters (default 16)
- `rut()` — chilean RUT
- `sensor_id(prefix)` — sensor ID like SENSOR-0042, with optional prefix (default: SENSOR)
- `ssn()` — US Social Security Number
- `uuid()` — UUID

### impurity

- `impure_date(val,factor)` — null / future date / past date / DD/MM/YYYY format
- `impure_email(val,factor)` — null / missing @ / double domain / username only
- `impure_num(val,factor)` — null / negative / 100x outlier / zero
- `impure_str(val,factor)` — null / UPPER / trailing whitespace / truncation

### language

- `language_code()` — language code

### location

- `address()` — street address (number + prefix + suffix)
- `city()` — city name from world cities
- `city_from_zip(zip)` — city matching a US zip code — use as dependent provider: city_from_zip(zip_code)
- `country(locale)` — country name with locale `locale` (default: en)
- `iso2()` — ISO 2 country code
- `lat()` — latitude
- `lon()` — longitude
- `state()` — US state name
- `state_code()` — US state abbreviation (e.g. CA, TX)
- `state_from_zip(zip)` — US state name matching a zip code — use as dependent provider: state_from_zip(zip_code)
- `street_prefix()` — street prefix
- `street_suffix()` — street suffix
- `zip_code()` — US zip code

### logging

- `apache_log_level()` — Apache log level
- `log_level()` — log level
- `syslog_level()` — syslog level

### numerical

- `float(a,b,prec)` — float between `a` and `b` with specified rounding precision `prec` (default=2)
- `int(a,b)` — integer between a and b inclusive
- `serial_id()` — serial integer number in ascending order

### payments

- `payment_card_type()` — payment card type

### personal

- `email(domain)` — email address with domain `domain` (default: @example.com)
- `email_from_name(first_name,last_name,domain)` — email address from first name and last name with domain `domain` (default: @example.com)
- `first_name(locale)` — first name with locale `locale` (default: en)
- `gender(extended)` — gender with optional `extended` flag (default: false)
- `last_name(locale)` — last name with locale `locale` (default: en)
- `name()` — full name
- `phone()` — phone number
- `prefix()` — name prefix
- `suffix()` — name suffix

### pharma

- `dose()` — dose
- `drug()` — drug
- `nrx()` — NRX

### products

- `category()` — category
- `currency()` — currency
- `price(a,b,prefix,res)` — price between `a` and `b` with `prefix` (default $) and `res` (default 1)
- `product()` — product
- `sku()` — SKU

### tech

- `hacker_abbreviation()` — abbreviation
- `hacker_adjective()` — adjective
- `hacker_noun()` — noun
- `hacker_verb()` — verb
- `semver()` — semantic version string (MAJOR.MINOR.PATCH)

### timeseries

- `seasonal(t,period,amplitude,noise_std)` — sinusoidal seasonality with noise: amplitude * sin(2π*t/period) + noise
- `trend(t,slope,noise_std)` — linear trend with Gaussian noise: slope * t + noise
- `walk(prev,step_std,min_val,max_val)` — random walk step: prev + Gaussian noise bounded by [min_val, max_val]

### vehicles

- `vehicle_fuel_type()` — vehicle fuel type
- `vehicle_maker()` — vehicle manufacturer
- `vehicle_transmission_type()` — vehicle transmission type
- `vehicle_type()` — vehicle type

### web

- `domain_suffix()` — domain suffix
- `http_method()` — HTTP method
- `http_status_code()` — HTTP status code from general set
- `http_status_simple()` — HTTP status code from simple set
- `internet_browser()` — web browser
- `ip4()` — IPv4 address

### work

- `company()` — company name
- `job_descriptor()` — job descriptor
- `job_level()` — job level
- `job_title(locale)` — job title with locale `locale` (default: en)

## TOML configs

See `skills/rgen/references/toml-reference.md` for every key, all distributions,
timeseries and state-machine modes, `[[attach]]`, custom providers and scenarios, and
`examples/` for configs you can run.

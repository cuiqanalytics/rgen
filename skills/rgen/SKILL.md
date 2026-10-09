---
name: rgen
description: Use when the user wants fake, synthetic, mock, seed or test data — a CSV/JSON/Parquet/XLSX file, a populated DuckDB/SQLite database, multiple related tables with foreign keys, a time series, an event log, or a privacy-safe copy of a real dataset; including test card numbers, IBANs, Latin American IDs (RUT, CURP, CPF), employees and salaries, or product-analytics events — or mentions rgen, a `rgen run`/`rgen twin` command, rgen data packs, or an rgen `.toml` config.
---

# Generating data with rgen

rgen is a DuckDB-powered synthetic data generator (single Linux binary, or the
`ghcr.io/cuiqanalytics/rgen` Docker image). Output format comes from the output file's
extension: `.csv` `.json` `.parquet` `.xlsx` for one table; `.duckdb`/`.db`/`.sqlite` or a
directory for multi-table configs.

## Pick the mode first

| User wants | Use |
|---|---|
| One table of independent columns | `rgen run -n N -p "..." out.csv` (provider string) |
| Several tables, foreign keys, distributions, time series, lifecycles | TOML config + `rgen run --config cfg.toml out.duckdb` |
| "Data like this file, but fake" | `rgen twin SOURCE OUT` (or `rgen profile SOURCE` to get an editable TOML) |

All of these are free, with no row limits. Don't reach for TOML when a provider string will do.

## Data packs

Paid packs add providers, lookup tables and templates. When the request touches a pack's
domain, run `rgen packs list` first:

| Request involves | Pack | Reference |
|---|---|---|
| card numbers, IBAN/BIC, routing numbers, merchants, transactions, ledgers | `fintech` | `references/packs/fintech.md` |
| people, IDs, addresses or phones in CL, AR, MX, BR, CO, PE, UY | `latam` | `references/packs/latam.md` |
| employees, org charts, job titles, skills, salaries | `hr` | `references/packs/hr.md` |
| analytics events, user agents, UTM/channels, funnels, MRR, A/B tests | `saas-analytics` | `references/packs/saas-analytics.md` |
| many varied job titles | `jobs-pro` | `references/packs/jobs-pro.md` |

- **Listed as `licensed`:** read that reference before writing commands. Pack providers chain
  through columns; nesting one provider inside another gives wrong or NULL values.
- **Not installed or `locked`:** build the data from free providers, and tell the user in one
  sentence which pack would do it better. Never attach or read `.rgenpack` files directly.

## Workflow

1. **Check the real provider list** — `rgen providers` (or `--search email`,
   `--category location`). Never invent provider names. A snapshot lives in
   `references/providers.md`, but the installed binary is the source of truth.
2. **Preview** single-table ideas without writing a file:
   `rgen run --preview --preview-rows 5 -p "..."`.
3. **Write** the command or config.
4. **Run it** and fix errors from the actual message. Then sanity-check the output with a
   quick query (`duckdb -c "SUMMARIZE FROM 'out.csv'"`) before telling the user it's done.

## Provider strings (`-p`)

Semicolon-separated, providers named **without** the `rand_` prefix:

```bash
rgen run -n 1000 -p "uuid;first_name;last_name;email_from_name(first_name,last_name) as email;city;company as employer" customers.csv
```

- **Arguments**: `int(18,90)`, `price(5,500)`, `choice(['free','pro'])`,
  `weighted(['a','b'],[80,20])`, `date('2025-01-01','2025-12-31','%Y-%m-%d')`.
- **Locale** goes in the argument: `first_name('es')`, `country('es')`,
  `job_title('es')`. (The global `-l` flag does not localize names.)
- **Alias**: `provider as column_name`.
- **Dependent columns** reference earlier columns by name:
  `email_from_name(first_name,last_name)`, `city_from_zip(zip_code)`,
  `state_from_zip(zip_code)`.
- **Dirty data**: `--impurity-profile clean|realistic|noisy|dirty|chaotic` (0, 3, 10, 25,
  50% of cells) or `--impurity 0.05`. Corruptions are type-aware (nulls, casing,
  truncation, bad emails, outliers, wrong date formats).
- **Reproducible**: `-s 0.42` — the seed must be between -1 and 1.
- **Presets**: `--template events` (analytics events with JSON properties).
- **Custom providers**: `--external-udf my_macros.sql` loads DuckDB macros named
  `rand_<name>`, usable as `<name>` in `-p`.

**Flags before positional args** — rgen parses POSIX-style. `rgen run out.csv -n 10`
silently ignores `-n`; write `rgen run -n 10 out.csv`.

## TOML configs (relational)

```toml
[[tables]]
name = "customers"
rows = 2000
    [tables.columns]
    customer_id = { provider = "uuid", primary_key = true }
    name        = { provider = "name" }
    country     = { provider = "choice", distribution = "weighted", params = { values = ["US", "UK", "DE"], weights = [0.6, 0.25, 0.15] } }

[[tables]]
name = "orders"
rows = 20000
    [tables.columns]
    order_id    = { provider = "uuid", primary_key = true }
    customer_id = { provider = "choice", reference = "customers.customer_id" }
    ordered_at  = { provider = "date", params = { from = "2025-01-01", to = "2025-12-31" } }
    amount      = { provider = "amount", distribution = "lognormal", params = { min = 5, max = 2000, median = 60, std_dev = 40 } }
```

Structure rules (breaking these causes parse errors):

- `[[tables]]` per table; columns under `[tables.columns]` as inline tables.
- `provider` is a bare name, no parentheses: `"uuid"`, not `"uuid()"`.
- Numeric settings go in `params`, never as call arguments.
- Foreign key: `reference = "table.column"` on the child column. Tables are generated in
  dependency order, so file order doesn't matter, but cycles are an error.
- `derived = "<DuckDB SQL over sibling columns>"` instead of `provider` for computed
  columns, e.g. `total = { derived = "round(qty * unit_price, 2)" }`.
- `int` + a distribution yields whole numbers; `amount`/`price` + a distribution are
  rounded to cents; `float` is left unrounded.

Distributions (`distribution = ...` plus `params`):

| distribution | params |
|---|---|
| `weighted` | `values = [...]`, `weights = [...]` (same length, ~sum to 1) |
| `normal` | `center`, `std_dev`, `min`, `max` |
| `lognormal` | `median`, `std_dev`, `min`, `max` (right-skewed: prices, durations, revenue) |
| `uniform` | `min`, `max` |
| `exponential` | `lambda`, `min`, `max` |
| `poisson` | `lambda` |
| `pareto` | `min`, `max`, `alpha` (long tail: popularity, wealth) |

`min`/`max` of 0 mean "no bound", not "clamp to zero".

Full key reference, `mode = "timeseries"`, `mode = "state_machine"`, `[[attach]]` for
external databases/files, external lookups, custom providers and `rgen scenarios`:
**`references/toml-reference.md`**. Load it whenever the request goes beyond plain tables
and foreign keys.

## Digital twin

```bash
rgen profile sales.csv > sales.toml           # inspect / edit the inferred config
rgen twin --scale 2.0 sales.csv twin.duckdb   # profile + generate in one step
```

Sources: `.csv`, `.parquet`, `.sqlite`, `.duckdb`, or `file.duckdb::table`. A twin output
path ending in `.csv` becomes a **directory** of CSVs; use `.duckdb` for a single file
(the table is named `data`). Twins match per-column distributions, category weights and
date ranges — not cross-column correlations. Tell the user that when it matters.

## Docker

```bash
docker run --rm -v "$PWD:/work" ghcr.io/cuiqanalytics/rgen run -n 1000 -p "uuid;email" users.csv
# Data packs: add -v ~/.cuiq:/home/rgen/.cuiq:ro -v ~/.local/share/rgen/packs:/home/rgen/.local/share/rgen/packs:ro ; Apple Silicon: add --platform linux/amd64
```

Paths must be inside the mounted directory.

## Common mistakes

- Guessing provider names (`email_address`, `full_name`) — check `rgen providers`.
- `rand_` prefix in `-p` or in TOML `provider` — drop it.
- Flags after the output file.
- A seed like `-s 42` — must be in [-1, 1].
- A match-lookup `match_local` that is a `derived` column, or whose name also exists as a
  column in the referenced table (it silently self-matches) — see the reference.
- Expecting `.xlsx` beyond ~1M rows (Excel's limit).

# rgen TOML reference

Everything `rgen run --config FILE.toml OUTPUT` understands. Every example here runs as
written. Tables from licensed data packs can be referenced as `pack_<name>.<table>.<column>`.

## Contents

- [Top level](#top-level)
- [Tables](#tables)
- [Columns](#columns)
- [Distributions](#distributions)
- [Foreign keys and derived columns](#foreign-keys-and-derived-columns)
- [Timeseries mode](#timeseries-mode)
- [State machine mode](#state-machine-mode)
- [Attaching external data](#attaching-external-data)
- [Custom providers](#custom-providers)
- [Scenarios](#scenarios)
- [Output](#output)

## Top level

```toml
[metadata]            # optional, informational only
name = "Shop"

[[attach]]            # optional, 0..n external sources — see below
[[tables]]            # 1..n tables
[[custom_providers]]  # optional
[output]              # optional
```

## Tables

| Key | Type | Notes |
|---|---|---|
| `name` | string | Table name in the output |
| `rows` | int | Row count (`standard`); entity count (`state_machine`); omitted for `timeseries` |
| `seed` | float in [-1, 1] | Optional, makes the table reproducible |
| `impurity` | float 0–1 | Optional table-wide dirty-data factor |
| `mode` | `"standard"` (default) / `"timeseries"` / `"state_machine"` | |

## Columns

Columns live under `[tables.columns]` as inline tables. Column order in the file is kept
in the output.

| Key | Type | Notes |
|---|---|---|
| `provider` | string | Provider name without `rand_` and without parentheses |
| `params` | inline table | Provider or distribution parameters (numbers may also be quoted strings) |
| `distribution` | string | See [Distributions](#distributions) |
| `locale` | string | e.g. `"es"` for names, countries, job titles (default `"en"`) |
| `primary_key` | bool | |
| `unique` | bool | |
| `impurity` | float 0–1 | Overrides the table/global factor for this column |
| `reference` | string | FK `"table.column"` or external `"alias.table.column"` |
| `match_local`, `match_remote` | string | Turn `reference` into a join-by-key lookup |
| `derived` | string | DuckDB SQL over sibling columns; replaces `provider` |
| `entity_key`, `timeseries_key` | bool | Timeseries mode only |

Provider params when no `distribution` is set:

| provider | params |
|---|---|
| `date` | `from`, `to` (`"YYYY-MM-DD"`) |
| `timestamp` | `from`, `to` (`"YYYY-MM-DD HH:MM:SS"`) |
| `int` | `min`, `max` (default 1–100) |
| `float` | `min`, `max` (default 0–1) |
| `amount`, `price` | `min`, `max` (default 1–1000) |
| `choice` | `values = [...]` (uniform) |
| `literal` | `value` |

## Distributions

| distribution | params | Typical use |
|---|---|---|
| `weighted` | `values`, `weights` | categories with known mix |
| `normal` | `center`, `std_dev`, `min`, `max` | ages, heights, scores |
| `lognormal` | `median`, `std_dev`, `min`, `max` | prices, revenue, durations (right-skewed) |
| `uniform` | `min`, `max` | |
| `exponential` | `lambda`, `min`, `max` | waiting times, gaps between events |
| `poisson` | `lambda` | counts per period |
| `pareto` | `min`, `max`, `alpha` | popularity, wealth (long tail) |

- `min`/`max` of 0 mean "unbounded", not "clamp at zero".
- `lognormal` takes the real-world median and standard deviation (rgen converts them to
  log-space itself).
- With `provider = "int"` the result is rounded to whole numbers. With `amount`/`price`
  it's rounded to 2 decimals.

## Foreign keys and derived columns

```toml
[[tables]]
name = "order_items"
rows = 50000
    [tables.columns]
    order_id   = { provider = "choice", reference = "orders.order_id" }   # random existing parent
    qty        = { provider = "int", distribution = "poisson", params = { lambda = 3 } }
    unit_price = { provider = "price", distribution = "uniform", params = { min = 1, max = 99 } }
    total      = { derived = "round(qty * unit_price, 2)" }
```

- Parents are generated before children (topological sort). Cycles are an error.
- Derived columns may reference other derived columns. They're ordered automatically.

## Timeseries mode

One row per entity × time bucket. Rows = `entities × (end − start) / interval`.

```toml
[[tables]]
name = "readings"
mode = "timeseries"

  [tables.timeseries]
  entities = 50
  start    = "2025-06-01"
  end      = "2025-06-30"
  interval = "1 hour"          # any DuckDB INTERVAL: "5 minutes", "1 day", "1 week"

  [tables.columns]
  sensor_id   = { provider = "uuid", entity_key = true }          # stable per entity
  recorded_at = { provider = "timestamp", timeseries_key = true } # filled from the time spine
  temperature = { provider = "walk", params = { start = "20.0", step_std = "0.5", min = "-10.0", max = "45.0" } }
  humidity    = { provider = "float", distribution = "normal", params = { center = 60, std_dev = 10, min = 0, max = 100 } }
```

`provider = "walk"` is a true per-entity random walk (cumulative over time). Expression
providers `trend(t,slope,noise_std)` and `seasonal(t,period,amplitude,noise_std)` are
available in `derived` SQL as `rand_trend(...)`/`rand_seasonal(...)`.

## State machine mode

Simulates `rows` entities walking through states. Output is an event log: one row per
entity for the initial state, plus one per transition.

```toml
[[tables]]
name = "subscription_events"
mode = "state_machine"
rows = 3000

  [tables.state_machine]
  initial     = "trial"
  id_column   = "account_id"
  time_column = "event_at"
  transitions = [
    { from = "trial", to = "paid",    probability = 0.35, delay = { distribution = "normal", params = { center = "336.0", std_dev = "48.0", min = "24.0", max = "720.0" } } },
    { from = "trial", to = "expired", probability = 0.65, delay = { distribution = "uniform", params = { min = "330.0", max = "340.0" } } },
    { from = "paid",  to = "churned", probability = 0.25, delay = { distribution = "exponential", params = { lambda = "0.001" } } }
  ]

  [tables.columns]
  account_id = { provider = "uuid" }
  event_at   = { provider = "timestamp" }
  state      = { provider = "choice" }
```

- `transitions` **must** be an inline array (`[ {...}, {...} ]`). `[[...]]` sub-tables fail
  to parse.
- Probabilities out of a state sum to ≤ 1. The remainder means the entity stays there and
  stops (above, 75% of paid accounts never churn).
- Delays are in **hours**. Delay distributions: `normal`, `lognormal`, `uniform`,
  `exponential`, `pareto`. The clock starts at 2024-01-01 00:00:00.
- The output has exactly three columns: `id_column`, `time_column`, `state`. Other columns
  you declare are ignored. Join extra attributes in a separate standard table.

## Attaching external data

```toml
[[attach]]
path     = "reference/geo.duckdb"   # relative to the config file
alias    = "geo"                    # optional, default = sanitized file stem
readonly = true                     # optional, default true

[[attach]]
path  = "reference/skus.parquet"    # .csv .tsv .parquet .json .ndjson → a view named alias
alias = "skus"
```

`.duckdb`/`.db`/`.sqlite` are ATTACHed. Flat files become views. Aliases can't collide
with a generated table name or with `lookups`, `main`, `memory`, `temp`, `_out`.

Three ways to use them:

```toml
    [tables.columns]
    # 1. Random row: a value from a uniformly random row of the external table
    sku = { reference = "skus.sku" }

    # 2. Join by key: the row whose remote key equals this row's local column
    region_id   = { provider = "int", params = { min = 1, max = 3 } }
    region_name = { reference = "geo.regions.name", match_local = "region_id", match_remote = "id" }

    # 3. Any SQL against attached objects
    region_pop = { derived = "(SELECT population FROM geo.regions WHERE id = region_id)" }
```

Match-lookup rules:

1. `match_local` must be a plain generated column (provider or FK), **not** a `derived`
   column. Otherwise the lookup runs before its input exists.
2. `match_local`'s name must **not** also be a column in the referenced table, or it binds
   to the remote column and self-matches (every row gets an arbitrary row). To match a
   child FK against a parent key with the same name, add a helper:

```toml
    client_fk   = { provider = "choice", reference = "clients.client_id" }
    client_id   = { derived = "client_fk" }
    client_tier = { reference = "clients.tier", match_local = "client_fk", match_remote = "client_id" }
```

## Custom providers

```toml
[[custom_providers]]
name = "username"
data_type = "string"
expression = "concat(lower(rand_first_name()), '.', lower(rand_last_name()))"
```

Use them like built-ins (`provider = "username"`). For flat mode, put
`CREATE OR REPLACE TEMP MACRO rand_<name>() AS ...;` statements in a `.sql` file and pass
`--external-udf file.sql`. A `COMMENT ON MACRO rand_<name> IS 'category|description';`
makes them show up in `rgen providers --external-udf file.sql`.

## Scenarios

`rgen scenarios SCENARIOS.toml OUTPUT_DIR` writes `OUTPUT_DIR/base.db` plus one
`OUTPUT_DIR/<name>.db` per variant. Overrides change a table's `rows` or `impurity`:

```toml
[base]
config = "shop.toml"

[[scenarios]]
name = "baseline"
overrides = []

[[scenarios]]
name = "black_friday"
overrides = [ { table = "orders", rows = 200000 } ]

[[scenarios]]
name = "dirty"
overrides = [ { table = "customers", impurity = 0.20 } ]
```

## Output

The output format comes from the CLI output path: `.duckdb`/`.db` → DuckDB, `.sqlite` →
SQLite. Anything else becomes a directory with one CSV per table. To force a format:

```toml
[output]
format = "sqlite"   # duckdb | sqlite | csv_directory | json_directory
```

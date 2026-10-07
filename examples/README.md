# rgen examples

Every file here runs as-is. Flags go **before** the output file (rgen parses POSIX-style).

## Flat tables (free)

```bash
# 1,000 customers with matching emails
rgen run -n 1000 -p "uuid;first_name;last_name;email_from_name(first_name,last_name) as email;city;company as employer" customers.csv

# Spanish-locale people, as Parquet
rgen run -n 5000 -p "first_name('es') as nombre;last_name('es') as apellido;country('es') as pais;job_title('es') as puesto" people.parquet

# Web logs with realistic noise (3% of cells get nulls, casing, truncation...)
rgen run -n 10000 --impurity-profile realistic -p "timestamp('2025-01-01','2025-12-31') as ts;ip4;http_method;http_status_code;internet_browser" logs.json

# Product-analytics events from a built-in preset
rgen run -n 5000 --template events events.csv

# Not sure what a provider looks like? Preview before writing anything
rgen run --preview -p "iban;bank_name;currency_code"
```

## Relational and simulations

| File | Mode | Run |
|---|---|---|
| `shop.toml` | 2 tables, foreign key, lognormal order amounts | `rgen run --config shop.toml shop.duckdb` |
| `sensors.toml` | timeseries: 50 sensors × hourly, random-walk temperature | `rgen run --config sensors.toml readings.duckdb` |
| `subscriptions.toml` | state machine: trial → paid → churned event log | `rgen run --config subscriptions.toml events.csv` |

## Digital twin

`sales.csv` stands in for a real dataset (it's built by `make_sales.sql`).

```bash
rgen profile sales.csv                       # print the inferred TOML config
rgen twin --scale 2.0 sales.csv twin.duckdb  # profile + generate 2x the rows in one go
```

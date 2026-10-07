window.CONTENT = {
 "pull": "Using default tag: latest\nlatest: Pulling from cuiqanalytics/rgen\n35f4b21e2013: Pulling fs layer\n4f4fb700ef54: Pulling fs layer\n1d4b37fc1317: Pulling fs layer\n2f97d5881f75: Pulling fs layer\n1d4b37fc1317: Already exists\n2f97d5881f75: Already exists\n62ee98f6b90d: Download complete\n4f4fb700ef54: Already exists\n35f4b21e2013: Already exists\n1d4b37fc1317: Pull complete\n4f4fb700ef54: Pull complete\n35f4b21e2013: Pull complete\n2f97d5881f75: Pull complete\nDigest: sha256:f69cbff61c36b059fe9c104ff854367551068ca37c82f6911729aadf6a3b14b2\nStatus: Downloaded newer image for ghcr.io/cuiqanalytics/rgen:latest\nghcr.io/cuiqanalytics/rgen:latest\n",
 "version": "rgen version 0.1.0\n",
 "flatProviders": "uuid;first_name;last_name;email_from_name(first_name,last_name) as email;city;company as employer",
 "flat": "✓ 1000 records in 74ms (102 KB)\n",
 "rows": [
  {
   "first_name": "Brian",
   "last_name": "Taylor",
   "email": "brian.taylor@example.com",
   "city": "Vyazemskiy",
   "employer": "Titan Solutions"
  },
  {
   "first_name": "Paul",
   "last_name": "Harris",
   "email": "paul.harris@example.com",
   "city": "Kavajë",
   "employer": "Quantum Solutions"
  },
  {
   "first_name": "Ronald",
   "last_name": "Phillips",
   "email": "ronald.phillips@example.com",
   "city": "Phalodi",
   "employer": "Pinnacle Dynamics"
  },
  {
   "first_name": "Hannah",
   "last_name": "Parker",
   "email": "hannah.parker@example.com",
   "city": "Tuttlingen",
   "employer": "Spectrum Ventures"
  },
  {
   "first_name": "Richard",
   "last_name": "Miller",
   "email": "richard.miller@example.com",
   "city": "Kovancılar",
   "employer": "Pinnacle Industries"
  },
  {
   "first_name": "Richard",
   "last_name": "Brown",
   "email": "richard.brown@example.com",
   "city": "Faisalabad",
   "employer": "Apex Solutions"
  },
  {
   "first_name": "Betty",
   "last_name": "Phillips",
   "email": "betty.phillips@example.com",
   "city": "Corupá",
   "employer": "Stellar Dynamics"
  },
  {
   "first_name": "Kimberly",
   "last_name": "Martin",
   "email": "kimberly.martin@example.com",
   "city": "Iganga",
   "employer": "Horizon Capital"
  },
  {
   "first_name": "Lisa",
   "last_name": "Thompson",
   "email": "lisa.thompson@example.com",
   "city": "Bang Bon",
   "employer": "Velocity Industries"
  },
  {
   "first_name": "Charles",
   "last_name": "Long",
   "email": "charles.long@example.com",
   "city": "Hulbuk",
   "employer": "Spectrum Ventures"
  },
  {
   "first_name": "Kimberly",
   "last_name": "Thomas",
   "email": "kimberly.thomas@example.com",
   "city": "Ipiranga",
   "employer": "Zenith Ventures"
  },
  {
   "first_name": "Barbara",
   "last_name": "Long",
   "email": "barbara.long@example.com",
   "city": "Bandar",
   "employer": "Pinnacle Holdings"
  },
  {
   "first_name": "Steven",
   "last_name": "Simmons",
   "email": "steven.simmons@example.com",
   "city": "Castlewood",
   "employer": "Pinnacle Ventures"
  },
  {
   "first_name": "Charles",
   "last_name": "Edwards",
   "email": "charles.edwards@example.com",
   "city": "Sangarébougou",
   "employer": "Quantum Industries"
  }
 ],
 "toml": "# shop.toml — customers and their orders, linked by a foreign key.\n#   rgen run --config shop.toml shop.duckdb\n[[tables]]\nname = \"customers\"\nrows = 2000\n    [tables.columns]\n    customer_id = { provider = \"uuid\", primary_key = true }\n    name        = { provider = \"name\" }\n    email       = { provider = \"email\", unique = true }\n    country     = { provider = \"choice\", distribution = \"weighted\", params = { values = [\"US\", \"UK\", \"DE\", \"MX\"], weights = [0.5, 0.2, 0.2, 0.1] } }\n\n[[tables]]\nname = \"orders\"\nrows = 20000\n    [tables.columns]\n    order_id    = { provider = \"uuid\", primary_key = true }\n    customer_id = { provider = \"choice\", reference = \"customers.customer_id\" }\n    ordered_at  = { provider = \"date\", params = { from = \"2025-01-01\", to = \"2025-12-31\" } }\n    amount      = { provider = \"amount\", distribution = \"lognormal\", params = { min = 5, max = 2000, median = 60, std_dev = 40 } }\n    status      = { provider = \"choice\", distribution = \"weighted\", params = { values = [\"paid\", \"refunded\", \"pending\"], weights = [0.85, 0.05, 0.10] } }\n",
 "config": "  ✓ customers: 2000 rows\n  ✓ orders: 20000 rows\nRelational data written to: shop.duckdb\n",
 "joinSql": "SELECT c.country, count(*) AS orders, round(avg(o.amount), 2) AS avg_amount FROM orders o JOIN customers c USING (customer_id) GROUP BY ALL ORDER BY orders DESC",
 "join": "┌─────────┬────────┬────────────┐\n│ country │ orders │ avg_amount │\n├─────────┼────────┼────────────┤\n│ US      │ 9800   │ 71.41      │\n│ DE      │ 4431   │ 72.21      │\n│ UK      │ 3804   │ 72.35      │\n│ MX      │ 1965   │ 70.49      │\n└─────────┴────────┴────────────┘\n",
 "twin": "Profiling sales.csv...\nGenerating synthetic twin → twin.duckdb\n  ✓ data: 10000 rows\nRelational data written to: twin.duckdb\n",
 "hist": [
  {
   "lo": 0,
   "real": 0.0246,
   "twin": 0.0431
  },
  {
   "lo": 20,
   "real": 0.1862,
   "twin": 0.1973
  },
  {
   "lo": 40,
   "real": 0.2298,
   "twin": 0.2131
  },
  {
   "lo": 60,
   "real": 0.1802,
   "twin": 0.154
  },
  {
   "lo": 80,
   "real": 0.1274,
   "twin": 0.1137
  },
  {
   "lo": 100,
   "real": 0.0904,
   "twin": 0.0782
  },
  {
   "lo": 120,
   "real": 0.0552,
   "twin": 0.0553
  },
  {
   "lo": 140,
   "real": 0.0382,
   "twin": 0.0391
  },
  {
   "lo": 160,
   "real": 0.023,
   "twin": 0.0229
  },
  {
   "lo": 180,
   "real": 0.0136,
   "twin": 0.0202
  },
  {
   "lo": 200,
   "real": 0.0098,
   "twin": 0.0172
  },
  {
   "lo": 220,
   "real": 0.0056,
   "twin": 0.0112
  },
  {
   "lo": 240,
   "real": 0.0054,
   "twin": 0.0076
  },
  {
   "lo": 260,
   "real": 0.0032,
   "twin": 0.0049
  },
  {
   "lo": 280,
   "real": 0.0016,
   "twin": 0.0065
  },
  {
   "lo": 300,
   "real": 0.0008,
   "twin": 0.0028
  },
  {
   "lo": 320,
   "real": 0.001,
   "twin": 0.0024
  },
  {
   "lo": 340,
   "real": 0.0014,
   "twin": 0.002
  },
  {
   "lo": 360,
   "real": 0.0004,
   "twin": 0.0013
  },
  {
   "lo": 380,
   "real": 0.0002,
   "twin": 0.0007
  }
 ],
 "stats": [
  {
   "src": "real",
   "rows": 5000,
   "median_revenue": 66.2,
   "top_product": "Laptop",
   "laptop_pct": 52
  },
  {
   "src": "twin",
   "rows": 10000,
   "median_revenue": 65.2,
   "top_product": "Laptop",
   "laptop_pct": 52.3
  }
 ]
};

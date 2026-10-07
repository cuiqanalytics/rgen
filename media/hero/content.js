window.CONTENT = {
 "pull": "Using default tag: latest\nlatest: Pulling from cuiqanalytics/rgen\nDigest: sha256:6c15ed7da892ea2c2f7ab7d33d464b3690afabff37514f586e0aa0cde31f4f0b\nStatus: Downloaded newer image for ghcr.io/cuiqanalytics/rgen:latest\nghcr.io/cuiqanalytics/rgen:latest\n",
 "version": "rgen version 0.1.0\n",
 "flatProviders": "uuid;first_name;last_name;email_from_name(first_name,last_name) as email;city;company as employer",
 "flat": "✓ 1000 records in 106ms (102 KB)\n",
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
 "join": "┌─────────┬────────┬────────────┐\n│ country │ orders │ avg_amount │\n├─────────┼────────┼────────────┤\n│ US      │ 9846   │ 71.35      │\n│ UK      │ 4111   │ 70.09      │\n│ DE      │ 3925   │ 72.17      │\n│ MX      │ 2118   │ 70.44      │\n└─────────┴────────┴────────────┘\n",
 "twin": "Profiling sales.csv...\nGenerating synthetic twin → twin.duckdb\n  ✓ data: 10000 rows\nRelational data written to: twin.duckdb\n",
 "hist": [
  {
   "lo": 0,
   "real": 0.0246,
   "twin": 0.0427
  },
  {
   "lo": 20,
   "real": 0.1862,
   "twin": 0.1973
  },
  {
   "lo": 40,
   "real": 0.2298,
   "twin": 0.2037
  },
  {
   "lo": 60,
   "real": 0.1802,
   "twin": 0.1663
  },
  {
   "lo": 80,
   "real": 0.1274,
   "twin": 0.1162
  },
  {
   "lo": 100,
   "real": 0.0904,
   "twin": 0.0784
  },
  {
   "lo": 120,
   "real": 0.0552,
   "twin": 0.0524
  },
  {
   "lo": 140,
   "real": 0.0382,
   "twin": 0.0394
  },
  {
   "lo": 160,
   "real": 0.023,
   "twin": 0.0261
  },
  {
   "lo": 180,
   "real": 0.0136,
   "twin": 0.0186
  },
  {
   "lo": 200,
   "real": 0.0098,
   "twin": 0.0137
  },
  {
   "lo": 220,
   "real": 0.0056,
   "twin": 0.0109
  },
  {
   "lo": 240,
   "real": 0.0054,
   "twin": 0.0064
  },
  {
   "lo": 260,
   "real": 0.0032,
   "twin": 0.0063
  },
  {
   "lo": 280,
   "real": 0.0016,
   "twin": 0.0045
  },
  {
   "lo": 300,
   "real": 0.0008,
   "twin": 0.0028
  },
  {
   "lo": 320,
   "real": 0.001,
   "twin": 0.0029
  },
  {
   "lo": 340,
   "real": 0.0014,
   "twin": 0.0023
  },
  {
   "lo": 360,
   "real": 0.0004,
   "twin": 0.002
  },
  {
   "lo": 380,
   "real": 0.0002,
   "twin": 0.0009
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
   "median_revenue": 66.1,
   "top_product": "Laptop",
   "laptop_pct": 51.8
  }
 ]
};

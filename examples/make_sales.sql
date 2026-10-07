-- make_sales.sql — builds sales.csv, the stand-in "real" dataset for `rgen twin`.
--   duckdb < make_sales.sql
SELECT setseed(0.7);
COPY (
  SELECT 10000 + i AS order_id,
         DATE '2025-01-01' + (random() * 364)::INT AS sold_on,
         (['North', 'South', 'East', 'West'])[1 + floor(random() * 4)::INT] AS region,
         (['Laptop', 'Monitor', 'Keyboard', 'Headset', 'Dock'])[1 + floor(random() * random() * 5)::INT] AS product,
         1 + floor(-ln(random()) * 1.5)::INT AS qty,
         round(exp(4.2 + 0.6 * sqrt(-2 * ln(random())) * cos(2 * pi() * random())), 2) AS revenue
  FROM range(5000) t(i)
) TO 'sales.csv';

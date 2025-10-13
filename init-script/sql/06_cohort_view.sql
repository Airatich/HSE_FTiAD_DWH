\connect order_service_db

CREATE SCHEMA IF NOT EXISTS dwh;

CREATE OR REPLACE VIEW dwh.v_cohort_report AS
WITH
first_order AS (
  SELECT
    user_external_id,
    min(order_date) AS first_order_date
  FROM public.orders
  GROUP BY user_external_id
),
first_order_month AS (
  SELECT
    fo.user_external_id,
    date_trunc('month', fo.first_order_date)::date AS cohort_month
  FROM first_order fo
  WHERE fo.first_order_date >= DATE '2024-01-01' AND fo.first_order_date < DATE '2025-01-01'
),
cohort_size AS (
  SELECT cohort_month, count(DISTINCT user_external_id) AS cohort_size
  FROM first_order_month
  GROUP BY cohort_month
),
user_activity AS (
  SELECT
    o.user_external_id,
    fm.cohort_month,
    (date_part('year', age(date_trunc('month', o.order_date), fm.cohort_month)) * 12
     + date_part('month', age(date_trunc('month', o.order_date), fm.cohort_month)))::int AS month_after_first_order
  FROM public.orders o
  JOIN first_order_month fm ON fm.user_external_id = o.user_external_id
  WHERE o.order_date >= DATE '2024-01-01' AND o.order_date < DATE '2025-01-01'
),
activity_per_period AS (
  SELECT cohort_month, month_after_first_order, count(DISTINCT user_external_id) AS active_users
  FROM user_activity
  GROUP BY cohort_month, month_after_first_order
),
retention AS (
  SELECT a.cohort_month, a.month_after_first_order,
         round(100.0 * a.active_users::numeric / NULLIF(b.cohort_size,0), 2) AS retention_pct
  FROM activity_per_period a
  JOIN cohort_size b USING (cohort_month)
),
revenue_by_cohort AS (
  SELECT date_trunc('month', o.order_date)::date AS cohort_month,
         sum(o.total_amount) AS total_cohort_revenue
  FROM public.orders o
  WHERE o.order_date >= DATE '2024-01-01' AND o.order_date < DATE '2025-01-01'
  GROUP BY 1
),
avg_rev AS (
  SELECT r.cohort_month,
         r.total_cohort_revenue,
         round(r.total_cohort_revenue / NULLIF(c.cohort_size,0), 2) AS avg_revenue_per_customer
  FROM revenue_by_cohort r
  JOIN cohort_size c USING (cohort_month)
)
SELECT
  c.cohort_month,
  c.cohort_size,
  max(CASE WHEN r.month_after_first_order = 0 THEN r.retention_pct END) AS period_0_pct,
  max(CASE WHEN r.month_after_first_order = 1 THEN r.retention_pct END) AS period_1_pct,
  max(CASE WHEN r.month_after_first_order = 2 THEN r.retention_pct END) AS period_2_pct,
  max(CASE WHEN r.month_after_first_order = 3 THEN r.retention_pct END) AS period_3_pct,
  max(CASE WHEN r.month_after_first_order = 4 THEN r.retention_pct END) AS period_4_pct,
  max(CASE WHEN r.month_after_first_order = 5 THEN r.retention_pct END) AS period_5_pct,
  max(CASE WHEN r.month_after_first_order = 6 THEN r.retention_pct END) AS period_6_pct,
  max(CASE WHEN r.month_after_first_order = 7 THEN r.retention_pct END) AS period_7_pct,
  max(CASE WHEN r.month_after_first_order = 8 THEN r.retention_pct END) AS period_8_pct,
  max(CASE WHEN r.month_after_first_order = 9 THEN r.retention_pct END) AS period_9_pct,
  max(CASE WHEN r.month_after_first_order = 10 THEN r.retention_pct END) AS period_10_pct,
  max(CASE WHEN r.month_after_first_order = 11 THEN r.retention_pct END) AS period_11_pct,
  a.total_cohort_revenue,
  a.avg_revenue_per_customer
FROM cohort_size c
LEFT JOIN retention r ON r.cohort_month = c.cohort_month
LEFT JOIN avg_rev a ON a.cohort_month = c.cohort_month
GROUP BY c.cohort_month, c.cohort_size, a.total_cohort_revenue, a.avg_revenue_per_customer;
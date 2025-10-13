\connect order_service_db;

WITH
params AS (
    SELECT 3000::int AS num_users, DATE '2024-01-01' AS start_date, DATE '2024-12-31' AS end_date
),
months AS (
    -- Месяцы 2024 года (0..11)
    SELECT gs AS month_offset
    FROM generate_series(0, 11) gs
),
users_2024 AS (
    -- Каждому пользователю назначаем месяц первой покупки (когорту) в 2024
    SELECT
        gen_random_uuid()            AS user_external_id,
        (SELECT start_date FROM params) + make_interval(months => cohort_idx) AS cohort_month,
        cohort_idx
    FROM (
        SELECT (floor(random() * 12))::int AS cohort_idx
        FROM generate_series(1, (SELECT num_users FROM params))
    ) r
),
user_month_activity AS (
    -- По каждому пользователю моделируем активность по месяцам после первой покупки
    -- Вероятность покупки убывает по мере удаления от когортного месяца: p = exp(-m/3)
    SELECT
        u.user_external_id,
        u.cohort_month::date                                          AS cohort_month,
        m.month_offset,
        (random() < exp(- m.month_offset / 3.0))                       AS will_buy
    FROM users_2024 u
    JOIN months m ON m.month_offset + u.cohort_idx <= 11
),
orders_2024 AS (
    -- Создаём максимум один заказ в месяц на пользователя при will_buy = true
    SELECT
        gen_random_uuid()                                             AS order_external_id,
        a.user_external_id,
        -- Дата заказа: от первого до последнего дня соответствующего месяца с рандомным временем
        (
          date_trunc('month', a.cohort_month) + make_interval(months => a.month_offset)
        )
        + make_interval(days => (floor(random()*28))::int, hours => (floor(random()*24))::int,
                        mins => (floor(random()*60))::int)            AS order_date,
        CASE WHEN random() < 0.92 THEN 'completed' ELSE 'cancelled' END::text AS status,
        -- Базовая сумма корзины
        round((20 + random() * 250)::numeric, 2)                      AS subtotal,
        round((random() * 25)::numeric, 2)                            AS tax_amount,
        round((random() * 20)::numeric, 2)                            AS shipping_cost,
        round((random() * 15)::numeric, 2)                            AS discount_amount,
        'USD'                                                         AS currency,
        gen_random_uuid()                                             AS delivery_address_external_id,
        CASE WHEN random() < 0.7 THEN 'standard' ELSE 'express' END::text AS delivery_type,
        CASE WHEN random() < 0.5 THEN 'credit_card' ELSE 'paypal' END::text AS payment_method,
        CASE WHEN random() < 0.97 THEN 'paid' ELSE 'pending' END::text     AS payment_status,
        now()                                                         AS created_at,
        now()                                                         AS updated_at,
        'generator_2024'                                              AS created_by,
        'generator_2024'                                              AS updated_by
    FROM user_month_activity a
    WHERE a.will_buy
)
INSERT INTO public.orders (
    order_external_id,
    user_external_id,
    order_number,
    order_date,
    status,
    subtotal,
    tax_amount,
    shipping_cost,
    discount_amount,
    total_amount,
    currency,
    delivery_address_external_id,
    delivery_type,
    expected_delivery_date,
    actual_delivery_date,
    payment_method,
    payment_status,
    effective_from,
    effective_to,
    is_current,
    created_at,
    updated_at,
    created_by,
    updated_by
)
SELECT
    o.order_external_id,
    o.user_external_id,
    'ORD-' || lpad((row_number() OVER (ORDER BY o.order_date, o.user_external_id))::text, 8, '0') AS order_number,
    o.order_date,
    o.status,
    o.subtotal,
    o.tax_amount,
    o.shipping_cost,
    o.discount_amount,
    round(o.subtotal + o.tax_amount + o.shipping_cost - o.discount_amount, 2) AS total_amount,
    o.currency,
    o.delivery_address_external_id,
    o.delivery_type,
    (o.order_date + interval '3 days')::date AS expected_delivery_date,
    (o.order_date + interval '3 days')::date AS actual_delivery_date,
    o.payment_method,
    o.payment_status,
    now() AS effective_from,
    NULL AS effective_to,
    TRUE AS is_current,
    o.created_at,
    o.updated_at,
    o.created_by,
    o.updated_by
FROM orders_2024 o;
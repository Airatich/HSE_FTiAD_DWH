-- =====================================================
-- Загрузка тестовых данных для order_service_db из CSV
-- =====================================================

\connect order_service_db;

-- Загрузка товаров из CSV
\copy public.products (product_sku, product_name, category, brand, price, currency, weight_grams, dimensions_length_cm, dimensions_width_cm, dimensions_height_cm, is_active, effective_from, effective_to, is_current, created_at, updated_at, created_by, updated_by) FROM '/var/lib/postgresql/mock_data/order_service_products.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Загрузка заказов из CSV
\copy public.orders (order_external_id, user_external_id, order_number, order_date, status, subtotal, tax_amount, shipping_cost, discount_amount, total_amount, currency, delivery_address_external_id, delivery_type, expected_delivery_date, actual_delivery_date, payment_method, payment_status, effective_from, effective_to, is_current, created_at, updated_at, created_by, updated_by) FROM '/var/lib/postgresql/mock_data/order_service_orders.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Загрузка позиций заказов из CSV
\copy public.order_items (order_external_id, product_sku, quantity, unit_price, total_price, product_name_snapshot, product_category_snapshot, product_brand_snapshot, created_at, updated_at, created_by, updated_by) FROM '/var/lib/postgresql/mock_data/order_service_order_items.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Загрузка истории статусов заказов из CSV
\copy public.order_status_history (order_external_id, old_status, new_status, change_reason, changed_at, changed_by, session_id, ip_address, notes) FROM '/var/lib/postgresql/mock_data/order_service_order_status_history.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

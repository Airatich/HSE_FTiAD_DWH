-- =====================================================
-- Загрузка тестовых данных для logistics_service_db из CSV
-- =====================================================

\connect logistics_service_db;

-- Загрузка складов из CSV
\copy public.warehouses (warehouse_code, warehouse_name, warehouse_type, country, region, city, street_address, postal_code, is_active, max_capacity_cubic_meters, operating_hours, contact_phone, manager_name, effective_from, effective_to, is_current, created_at, updated_at, created_by, updated_by) FROM '/var/lib/postgresql/mock_data/logistics_service_warehouses.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Загрузка пунктов выдачи из CSV
\copy public.pickup_points (pickup_point_code, pickup_point_name, pickup_point_type, country, region, city, street_address, postal_code, is_active, max_capacity_packages, operating_hours, contact_phone, partner_name, effective_from, effective_to, is_current, created_at, updated_at, created_by, updated_by) FROM '/var/lib/postgresql/mock_data/logistics_service_pickup_points.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Загрузка отгрузок из CSV
\copy public.shipments (shipment_external_id, order_external_id, tracking_number, status, weight_grams, volume_cubic_cm, package_count, origin_warehouse_code, destination_type, destination_pickup_point_code, destination_address_external_id, created_date, dispatched_date, estimated_delivery_date, actual_delivery_date, delivery_notes, recipient_name, delivery_signature, effective_from, effective_to, is_current, created_at, updated_at, created_by, updated_by) FROM '/var/lib/postgresql/mock_data/logistics_service_shipments.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Загрузка перемещений отгрузок из CSV
\copy public.shipment_movements (shipment_external_id, movement_type, location_type, location_code, movement_datetime, operator_name, notes, latitude, longitude, created_at, created_by) FROM '/var/lib/postgresql/mock_data/logistics_service_shipment_movements.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Загрузка истории статусов отгрузок из CSV
\copy public.shipment_status_history (shipment_external_id, old_status, new_status, change_reason, changed_at, changed_by, location_type, location_code, notes, customer_notified) FROM '/var/lib/postgresql/mock_data/logistics_service_shipment_status_history.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

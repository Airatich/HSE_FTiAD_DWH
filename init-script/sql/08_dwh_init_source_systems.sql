-- Инициализация систем-источников в DWH
-- Этот скрипт выполняется после создания схемы dwh_detailed

-- Вставка систем-источников
-- Используем MD5 хеш от source_system_id для hub_source_system_key
INSERT INTO dwh_detailed.hub_source_system (
    hub_source_system_key,
    source_system_id,
    source_system_name,
    load_date,
    record_source
) VALUES
    (SUBSTRING(MD5('user_service') FROM 1 FOR 32), 'user_service', 'User Service Database', CURRENT_TIMESTAMP, 'system_init'),
    (SUBSTRING(MD5('order_service') FROM 1 FOR 32), 'order_service', 'Order Service Database', CURRENT_TIMESTAMP, 'system_init'),
    (SUBSTRING(MD5('logistics_service') FROM 1 FOR 32), 'logistics_service', 'Logistics Service Database', CURRENT_TIMESTAMP, 'system_init')
ON CONFLICT (hub_source_system_key) DO NOTHING;


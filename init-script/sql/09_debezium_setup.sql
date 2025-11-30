-- Настройка PostgreSQL для Debezium
-- Этот скрипт создает replication slot и publication для Debezium

-- Создание replication slot для Debezium
SELECT pg_create_logical_replication_slot('debezium_slot', 'pgoutput');

-- Создание publication для всех таблиц
CREATE PUBLICATION debezium_publication FOR ALL TABLES;

-- Проверка, что все настроено
SELECT slot_name, plugin, slot_type, active 
FROM pg_replication_slots 
WHERE slot_name = 'debezium_slot';

SELECT pubname, puballtables 
FROM pg_publication 
WHERE pubname = 'debezium_publication';


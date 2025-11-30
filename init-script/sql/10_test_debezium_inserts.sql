-- Тестовые INSERT для проверки работы Debezium и DMP-сервиса
-- Выполняйте эти запросы после запуска всех сервисов

\connect user_service_db;

-- Тестовые пользователи
INSERT INTO public.users (
    user_external_id, email, first_name, last_name, phone,
    date_of_birth, registration_date, status,
    effective_from, is_current, created_at, updated_at,
    created_by, updated_by
) VALUES (
    'TEST-DEBEZIUM-001',
    'debezium.test1@example.com',
    'Debezium',
    'Test1',
    '+7-999-000-00-01',
    '1990-01-01'::date,
    NOW(),
    'active',
    NOW(), TRUE, NOW(), NOW(),
    'debezium_test', 'debezium_test'
) ON CONFLICT DO NOTHING;


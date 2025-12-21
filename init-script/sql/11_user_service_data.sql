-- =====================================================
-- Загрузка тестовых данных для user_service_db из CSV
-- =====================================================

\connect user_service_db;

-- Загрузка пользователей из CSV
\copy public.users (user_external_id, email, first_name, last_name, phone, date_of_birth, registration_date, status, effective_from, effective_to, is_current, created_at, updated_at, created_by, updated_by) FROM '/var/lib/postgresql/mock_data/user_service_users.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Загрузка адресов пользователей из CSV
\copy public.user_addresses (address_external_id, user_external_id, address_type, country, region, city, street_address, postal_code, apartment, is_default, effective_from, effective_to, is_current, created_at, updated_at, created_by, updated_by) FROM '/var/lib/postgresql/mock_data/user_service_user_addresses.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Загрузка истории статусов пользователей из CSV
\copy public.user_status_history (user_external_id, old_status, new_status, change_reason, changed_at, changed_by, session_id, ip_address, user_agent) FROM '/var/lib/postgresql/mock_data/user_service_user_status_history.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

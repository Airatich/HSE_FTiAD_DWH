-- Создаем пользователя для репликации
CREATE USER replica_user WITH REPLICATION ENCRYPTED PASSWORD 'replica_password';

-- Создаем слот репликации
SELECT pg_create_physical_replication_slot('replica_slot');
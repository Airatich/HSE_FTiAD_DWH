# Домашнее задание №1: 

## Описание

Реализована настройка PostgreSQL 15 с физической потоковой репликацией (streaming replication) между мастером и репликой. Создана инфраструктура с тремя базами данных (user_service_db, order_service_db, logistics_service_db) и когортным анализом клиентов.

## Архитектура

- **Master**: PostgreSQL 15 на порту 2222
- **Replica**: PostgreSQL 15 на порту 5433 (read-only)
- **Репликация**: Физическая потоковая репликация через replication slot
- **Docker**: Docker Compose для оркестрации

## Структура проекта

```
HW1_test/
├── docker-compose.yml          # Конфигурация Docker Compose
├── docker-init.sh              # Скрипт инициализации кластера
├── init-script/
│   ├── bash/                   # Bash-скрипты настройки репликации
│   │   ├── 0001-create-replica-user.sh
│   │   ├── 0002-backup-master.sh
│   │   └── 0003-init-slave.sh
│   ├── common-config/          # Общие конфигурации
│   │   ├── pg_hba.conf
│   │   └── postgresql.conf
│   ├── replica-config/         # Конфигурация реплики
│   │   └── postgresql.auto.conf
│   └── sql/                    # SQL-скрипты инициализации
│       ├── 00_replication.sql
│       ├── 01_create_db.sql
│       ├── 02_user_service.sql
│       ├── 03_order_service_db.sql
│       ├── 04_logistics_service_db.sql
│       ├── 05_order_insert_data.sql
│       └── 06_cohort_view.sql
└── README.md
```

## Требования

- Docker
- Docker Compose
- Bash

## Установка и запуск

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd HW1_test
```

### 2. Инициализация кластера

```bash
chmod +x docker-init.sh
./docker-init.sh
```

Скрипт выполняет:
- Очистку старых данных
- Запуск мастера
- Создание пользователя репликации
- Создание replication slot
- Бэкап мастера через pg_basebackup
- Запуск реплики с правильной конфигурацией

### 3. Проверка репликации

**На мастере:**
```bash
docker exec -it hw1-postgres-master psql -U postgres -c "SELECT pid, usename, application_name, client_addr, state, sync_state FROM pg_stat_replication;"
docker exec -it hw1-postgres-master psql -U postgres -c "SELECT slot_name, active, wal_status, restart_lsn FROM pg_replication_slots;"
```

**На реплике:**
```bash
docker exec -it hw1-postgres-replica psql -U postgres -c "SELECT pg_is_in_recovery();"
docker exec -it hw1-postgres-replica psql -U postgres -c "SELECT status, receive_start_lsn, received_lsn, latest_end_lsn FROM pg_stat_wal_receiver;"
```

**Тест записи/чтения:**
```bash
# Запись на мастере
docker exec -it hw1-postgres-master psql -U postgres -d order_service_db -c "INSERT INTO orders (order_external_id, user_external_id, order_number, order_date, status, subtotal, tax_amount, shipping_cost, discount_amount, total_amount, currency, delivery_address_external_id, delivery_type, payment_method, payment_status, effective_from, created_at, updated_at, created_by, updated_by) VALUES (gen_random_uuid(), gen_random_uuid(), 'TEST-001', NOW(), 'completed', 100.00, 10.00, 5.00, 0.00, 115.00, 'USD', gen_random_uuid(), 'standard', 'credit_card', 'paid', NOW(), NOW(), NOW(), 'test', 'test');"

# Чтение с реплики
docker exec -it hw1-postgres-replica psql -U postgres -d order_service_db -c "SELECT order_number, total_amount FROM orders WHERE order_number = 'TEST-001';"
```

## Connection Strings

### С хоста (localhost)

**Master (write):**
```
postgresql://postgres:postgres@localhost:2222/order_service_db
```

**Replica (read-only):**
```
postgresql://postgres:postgres@localhost:5433/order_service_db
```

### Изнутри Docker-сети

**Master:**
```
postgresql://postgres:postgres@postgres-master:5432/order_service_db
```

**Replica:**
```
postgresql://postgres:postgres@postgres-replica:5432/order_service_db
```

### Для разных языков

**JDBC:**
```
jdbc:postgresql://localhost:2222/order_service_db?user=postgres&password=postgres
```

**SQLAlchemy (Python):**
```
postgresql+psycopg2://postgres:postgres@localhost:2222/order_service_db
```

## Базы данных

### 1. user_service_db
База данных пользователей (структура определена в `init-script/sql/02_user_service.sql`).

### 2. order_service_db
База данных заказов с таблицами:
- `orders` - заказы
- `products` - товары
- `order_items` - позиции заказов
- `order_status_history` - история статусов

**Когортная витрина:**
- Схема: `dwh`
- Представление: `dwh.v_cohort_report`
- Описание: Когортный анализ клиентов с retention rate и метриками дохода

**Использование:**
```sql
SELECT * FROM dwh.v_cohort_report ORDER BY cohort_month;
```

### 3. logistics_service_db
База данных логистики с таблицами:
- `shipments` - отгрузки
- `warehouses` - склады
- `pickup_points` - пункты выдачи
- `shipment_movements` - перемещения
- `shipment_status_history` - история статусов

## Когортный анализ

В базе `order_service_db` реализована витрина когортного анализа клиентов (`dwh.v_cohort_report`):

**Метрики:**
- `cohort_month` - месяц первой покупки (когорта)
- `cohort_size` - размер когорты
- `period_0_pct` - retention в месяц первой покупки (100%)
- `period_1_pct` - retention через 1 месяц
- `period_2_pct` - retention через 2 месяца
- ... `period_11_pct` - retention через 11 месяцев
- `total_cohort_revenue` - общая выручка когорты
- `avg_revenue_per_customer` - средняя выручка на клиента

**Запрос:**
```sql
SELECT 
  cohort_month,
  cohort_size,
  period_0_pct,
  period_1_pct,
  period_2_pct,
  period_3_pct,
  period_4_pct,
  period_5_pct,
  total_cohort_revenue,
  avg_revenue_per_customer
FROM dwh.v_cohort_report
ORDER BY cohort_month;
```

## Управление кластером

### Остановка
```bash
docker compose down
```

### Полная очистка и перезапуск
```bash
docker compose down
rm -rf ./data/* ./replica_data/*
./docker-init.sh
```

### Просмотр логов
```bash
docker logs hw1-postgres-master
docker logs hw1-postgres-replica
```

## Настройка репликации

### Параметры мастера (docker-compose.yml)
- `wal_level = replica`
- `max_wal_senders = 10`
- `wal_keep_size = 64`
- `listen_addresses = '*'`
- `hot_standby = on`

### Параметры реплики
- `hot_standby = on`
- `primary_conninfo` (через postgresql.auto.conf)
- `primary_slot_name = 'replication_slot_1'`

### Replication Slot
- Название: `replication_slot_1`
- Тип: physical
- Пользователь: `replicator`

## Проверка работоспособности

### 1. Проверка репликации
```bash
# На мастере
docker exec -it hw1-postgres-master psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# На реплике
docker exec -it hw1-postgres-replica psql -U postgres -c "SELECT pg_is_in_recovery();"
```

### 2. Проверка баз данных
```bash
docker exec -it hw1-postgres-master psql -U postgres -c "\l"
```

### 3. Проверка таблиц
```bash
docker exec -it hw1-postgres-master psql -U postgres -d order_service_db -c "\dt"
docker exec -it hw1-postgres-master psql -U postgres -d logistics_service_db -c "\dt"
```

### 4. Проверка когортной витрины
```bash
docker exec -it hw1-postgres-master psql -U postgres -d order_service_db -c "SELECT * FROM dwh.v_cohort_report LIMIT 10;"
```

##### Connection string
Мастер (write), с хоста:
- psql: postgresql://postgres:postgres@localhost:2222/order_service_db
Реплика (read-only), с хоста:
- psql: postgresql://postgres:postgres@localhost:5433/order_service_db

# Домашнее задание №1+2: Детальный слой DWH

чтобы проект запустился нужно еще добавить в проект папку HSE_FTiAD_DWH/init-script/sql/mock_data с содержимым из https://disk.360.yandex.ru/d/5KJFK2Ly0S0Drg  (тут лежат csv файлы)

## Описание

Реализована настройка PostgreSQL 15 с физической потоковой репликацией (streaming replication) между мастером и репликой. Создана инфраструктура с тремя базами данных (user_service_db, order_service_db, logistics_service_db) и когортным анализом клиентов. Реализован детальный слой DWH на основе архитектуры Data Vault 2.0 с интеграцией данных через Debezium CDC и Kafka.

## Выбор архитектуры детального слоя DWH

### Обоснование выбора Data Vault 2.0

Для реализации детального слоя DWH была выбрана архитектура **Data Vault 2.0**. Ниже представлено обоснование этого выбора:

#### Преимущества Data Vault 2.0 для данного проекта:

1. **Гибкость и масштабируемость**
   - Data Vault 2.0 позволяет легко добавлять новые источники данных без изменения существующих структур
   - Архитектура поддерживает горизонтальное масштабирование за счет разделения на хабы, линки и саттелиты
   - Идеально подходит для микросервисной архитектуры с множественными источниками данных

2. **Историчность данных (Temporal Data Management)**
   - Саттелиты автоматически сохраняют историю изменений атрибутов через механизм `load_date` и `load_end_date`
   - Поддержка SCD Type 2 (Slowly Changing Dimensions) без дополнительных сложностей
   - Полная трассируемость изменений через `record_source` и метаданные загрузки

3. **Независимость от бизнес-логики**
   - Разделение бизнес-ключей (хабы), связей (линки) и описательных атрибутов (саттелиты)
   - Изменения в бизнес-логике источников не требуют перестройки структуры DWH
   - Устойчивость к изменениям в системах-источниках

4. **Параллельная загрузка данных**
   - Возможность параллельной загрузки данных из разных источников
   - Минимизация блокировок за счет независимой структуры таблиц
   - Оптимизация процессов ETL/ELT

5. **Интеграция с CDC (Change Data Capture)**
   - Data Vault 2.0 идеально подходит для работы с Debezium CDC
   - Каждое изменение из источника может быть загружено как новая версия в саттелит
   - Поддержка реального времени загрузки данных

#### Сравнение с альтернативными архитектурами:

**Data Vault (классический):**
- Не включает улучшения производительности и методологии Data Vault 2.0
- Отсутствие стандартизированных практик загрузки данных

**Якорная модель (Anchor Modeling):**
- Более сложная структура с большим количеством таблиц
- Избыточная нормализация для данного проекта
- Сложнее в поддержке и понимании для команды

**Классическая нормализованная модель (3NF):**
- Требует частых изменений при добавлении новых источников
- Сложность поддержания историчности данных
- Высокая связанность таблиц усложняет параллельную загрузку

### Структура Data Vault 2.0 в проекте

Детальный слой реализован в схеме `dwh_detailed` и включает:

- **Хабы (Hubs)**: 8 хабов для бизнес-ключей
- **Линки (Links)**: 7 линков для связей между сущностями
- **Саттелиты (Satellites)**: 15 саттелитов для описательных атрибутов и истории

Подробная структура описана в файле `init-script/sql/07_dwh_detailed_ddl.sql` и визуализирована в `EP_dwh.pdf`.

## Первичный анализ предметной области

### Описание предметной области

Проект представляет собой систему электронной коммерции (e-commerce) с микросервисной архитектурой, состоящей из трех основных доменов:

1. **User Service** - управление пользователями и их данными
2. **Order Service** - управление заказами и товарами
3. **Logistics Service** - управление логистикой и доставкой

### Выделенные сущности, атрибуты и связи

#### 1. Домен User Service

##### Сущность: User (Пользователь)
**Бизнес-ключ:** `user_external_id` (UUID)

**Атрибуты:**
- `email` - электронная почта (VARCHAR, NOT NULL)
- `first_name` - имя (VARCHAR, NOT NULL)
- `last_name` - фамилия (VARCHAR, NOT NULL)
- `phone` - телефон (VARCHAR)
- `date_of_birth` - дата рождения (DATE)
- `registration_date` - дата регистрации (TIMESTAMP, NOT NULL)
- `status` - статус пользователя (VARCHAR, NOT NULL)
- `effective_from` - начало действия записи (TIMESTAMP, NOT NULL)
- `effective_to` - окончание действия записи (TIMESTAMP)
- `is_current` - флаг актуальности (BOOLEAN, NOT NULL, DEFAULT true)
- Метаданные: `created_at`, `updated_at`, `created_by`, `updated_by`

**Связи:**
- User → Address (один ко многим) - пользователь может иметь несколько адресов
- User → Order (один ко многим) - пользователь может иметь несколько заказов

##### Сущность: Address (Адрес)
**Бизнес-ключ:** `address_external_id` (UUID)

**Атрибуты:**
- `address_type` - тип адреса (VARCHAR, NOT NULL)
- `country` - страна (VARCHAR, NOT NULL)
- `region` - регион (VARCHAR)
- `city` - город (VARCHAR, NOT NULL)
- `street_address` - улица и дом (VARCHAR, NOT NULL)
- `postal_code` - почтовый индекс (VARCHAR)
- `apartment` - квартира/офис (VARCHAR)
- `is_default` - адрес по умолчанию (BOOLEAN, NOT NULL, DEFAULT false)
- `effective_from`, `effective_to`, `is_current` - временные метки
- Метаданные: `created_at`, `updated_at`, `created_by`, `updated_by`

**Связи:**
- Address → User (многие к одному) - адрес принадлежит пользователю
- Address → Order (один ко многим) - адрес используется в заказах
- Address → Shipment (один ко многим) - адрес используется в отгрузках

##### Сущность: User Status History (История статусов пользователя)
**Бизнес-ключ:** `user_external_id` + `changed_at`

**Атрибуты:**
- `old_status` - предыдущий статус (VARCHAR)
- `new_status` - новый статус (VARCHAR, NOT NULL)
- `change_reason` - причина изменения (VARCHAR)
- `changed_at` - время изменения (TIMESTAMP, NOT NULL)
- `session_id` - идентификатор сессии (VARCHAR)
- `ip_address` - IP-адрес (INET)
- `user_agent` - информация о браузере (TEXT)

#### 2. Домен Order Service

##### Сущность: Order (Заказ)
**Бизнес-ключ:** `order_external_id` (UUID)

**Атрибуты:**
- `order_number` - номер заказа (VARCHAR, NOT NULL, UNIQUE)
- `order_date` - дата заказа (TIMESTAMP, NOT NULL)
- `status` - статус заказа (VARCHAR, NOT NULL)
- `delivery_type` - тип доставки (VARCHAR, NOT NULL)
- `expected_delivery_date` - ожидаемая дата доставки (DATE)
- `actual_delivery_date` - фактическая дата доставки (DATE)
- `payment_method` - способ оплаты (VARCHAR, NOT NULL)
- `payment_status` - статус оплаты (VARCHAR, NOT NULL)
- Финансовые атрибуты:
  - `subtotal` - стоимость без налогов (DECIMAL(15,2), NOT NULL)
  - `tax_amount` - сумма налогов (DECIMAL(15,2), NOT NULL)
  - `shipping_cost` - стоимость доставки (DECIMAL(15,2), NOT NULL)
  - `discount_amount` - сумма скидки (DECIMAL(15,2), NOT NULL, DEFAULT 0)
  - `total_amount` - итоговая сумма (DECIMAL(15,2), NOT NULL)
  - `currency` - валюта (VARCHAR(3), NOT NULL, DEFAULT 'USD')
- `effective_from`, `effective_to`, `is_current` - временные метки
- Метаданные: `created_at`, `updated_at`, `created_by`, `updated_by`

**Связи:**
- Order → User (многие к одному) - заказ принадлежит пользователю
- Order → Address (многие к одному) - адрес доставки заказа
- Order → Product (многие ко многим через Order Item) - товары в заказе
- Order → Shipment (один ко многим) - отгрузки заказа

##### Сущность: Product (Товар)
**Бизнес-ключ:** `product_sku` (VARCHAR)

**Атрибуты:**
- `product_name` - название товара (VARCHAR, NOT NULL)
- `category` - категория (VARCHAR, NOT NULL)
- `brand` - бренд (VARCHAR, NOT NULL)
- `price` - цена (DECIMAL(15,2), NOT NULL)
- `currency` - валюта (VARCHAR(3), NOT NULL, DEFAULT 'USD')
- Физические характеристики:
  - `weight_grams` - вес в граммах (INTEGER)
  - `dimensions_length_cm` - длина в см (DECIMAL(8,2))
  - `dimensions_width_cm` - ширина в см (DECIMAL(8,2))
  - `dimensions_height_cm` - высота в см (DECIMAL(8,2))
- `is_active` - активность товара (BOOLEAN, NOT NULL, DEFAULT true)
- `effective_from`, `effective_to`, `is_current` - временные метки
- Метаданные: `created_at`, `updated_at`, `created_by`, `updated_by`

**Связи:**
- Product → Order (многие ко многим через Order Item) - товары в заказах

##### Сущность: Order Item (Позиция заказа)
**Бизнес-ключ:** `order_external_id` + `product_sku`

**Атрибуты:**
- `quantity` - количество (INTEGER, NOT NULL, CHECK > 0)
- `unit_price` - цена за единицу (DECIMAL(15,2), NOT NULL, CHECK >= 0)
- `total_price` - общая стоимость позиции (DECIMAL(15,2), NOT NULL, CHECK >= 0)
- Снимки данных на момент заказа:
  - `product_name_snapshot` - название товара (VARCHAR, NOT NULL)
  - `product_category_snapshot` - категория товара (VARCHAR, NOT NULL)
  - `product_brand_snapshot` - бренд товара (VARCHAR, NOT NULL)
- Метаданные: `created_at`, `updated_at`, `created_by`, `updated_by`

**Связи:**
- Order Item → Order (многие к одному) - позиция принадлежит заказу
- Order Item → Product (многие к одному) - позиция ссылается на товар

##### Сущность: Order Status History (История статусов заказа)
**Бизнес-ключ:** `order_external_id` + `changed_at`

**Атрибуты:**
- `old_status` - предыдущий статус (VARCHAR)
- `new_status` - новый статус (VARCHAR, NOT NULL)
- `change_reason` - причина изменения (VARCHAR)
- `changed_at` - время изменения (TIMESTAMP, NOT NULL)
- `changed_by` - кто изменил (VARCHAR, NOT NULL)
- `session_id` - идентификатор сессии (VARCHAR)
- `ip_address` - IP-адрес (INET)
- `notes` - примечания (TEXT)

#### 3. Домен Logistics Service

##### Сущность: Shipment (Отгрузка)
**Бизнес-ключ:** `shipment_external_id` (UUID)

**Атрибуты:**
- `tracking_number` - номер отслеживания (VARCHAR, NOT NULL, UNIQUE)
- `status` - статус отгрузки (VARCHAR, NOT NULL)
- Физические характеристики:
  - `weight_grams` - вес в граммах (INTEGER, CHECK > 0)
  - `volume_cubic_cm` - объем в куб. см (INTEGER, CHECK > 0)
  - `package_count` - количество упаковок (INTEGER, NOT NULL, DEFAULT 1, CHECK > 0)
- `destination_type` - тип пункта назначения (VARCHAR, NOT NULL)
  - Возможные значения: 'pickup_point' или 'address'
- `destination_pickup_point_code` - код пункта выдачи (VARCHAR)
- `destination_address_external_id` - адрес доставки (UUID)
- Даты:
  - `created_date` - дата создания (TIMESTAMP, NOT NULL)
  - `dispatched_date` - дата отправки (TIMESTAMP)
  - `estimated_delivery_date` - ожидаемая дата доставки (TIMESTAMP)
  - `actual_delivery_date` - фактическая дата доставки (TIMESTAMP)
- `delivery_notes` - примечания по доставке (TEXT)
- `recipient_name` - имя получателя (VARCHAR, NOT NULL)
- `delivery_signature` - подпись получателя (VARCHAR)
- `effective_from`, `effective_to`, `is_current` - временные метки
- Метаданные: `created_at`, `updated_at`, `created_by`, `updated_by`

**Связи:**
- Shipment → Order (многие к одному) - отгрузка связана с заказом
- Shipment → Warehouse (многие к одному) - склад отправления
- Shipment → Pickup Point (многие к одному, опционально) - пункт выдачи
- Shipment → Address (многие к одному, опционально) - адрес доставки

##### Сущность: Warehouse (Склад)
**Бизнес-ключ:** `warehouse_code` (VARCHAR)

**Атрибуты:**
- `warehouse_name` - название склада (VARCHAR, NOT NULL)
- `warehouse_type` - тип склада (VARCHAR, NOT NULL)
- Адресные данные:
  - `country` - страна (VARCHAR, NOT NULL)
  - `region` - регион (VARCHAR)
  - `city` - город (VARCHAR, NOT NULL)
  - `street_address` - адрес (VARCHAR, NOT NULL)
  - `postal_code` - почтовый индекс (VARCHAR)
- `is_active` - активность склада (BOOLEAN, NOT NULL, DEFAULT true)
- `max_capacity_cubic_meters` - максимальная вместимость в куб. метрах (DECIMAL(10,2), CHECK > 0)
- `operating_hours` - часы работы (VARCHAR)
- `contact_phone` - контактный телефон (VARCHAR)
- `manager_name` - имя менеджера (VARCHAR)
- `effective_from`, `effective_to`, `is_current` - временные метки
- Метаданные: `created_at`, `updated_at`, `created_by`, `updated_by`

**Связи:**
- Warehouse → Shipment (один ко многим) - склад отправляет отгрузки

##### Сущность: Pickup Point (Пункт выдачи)
**Бизнес-ключ:** `pickup_point_code` (VARCHAR)

**Атрибуты:**
- `pickup_point_name` - название пункта выдачи (VARCHAR, NOT NULL)
- `pickup_point_type` - тип пункта выдачи (VARCHAR, NOT NULL)
- Адресные данные:
  - `country` - страна (VARCHAR, NOT NULL)
  - `region` - регион (VARCHAR)
  - `city` - город (VARCHAR, NOT NULL)
  - `street_address` - адрес (VARCHAR, NOT NULL)
  - `postal_code` - почтовый индекс (VARCHAR)
- `is_active` - активность пункта (BOOLEAN, NOT NULL, DEFAULT true)
- `max_capacity_packages` - максимальная вместимость в упаковках (INTEGER, CHECK > 0)
- `operating_hours` - часы работы (VARCHAR)
- `contact_phone` - контактный телефон (VARCHAR)
- `partner_name` - название партнера (VARCHAR)
- `effective_from`, `effective_to`, `is_current` - временные метки
- Метаданные: `created_at`, `updated_at`, `created_by`, `updated_by`

**Связи:**
- Pickup Point → Shipment (один ко многим) - пункт выдачи принимает отгрузки

##### Сущность: Shipment Movement (Перемещение отгрузки)
**Бизнес-ключ:** `shipment_external_id` + `movement_datetime`

**Атрибуты:**
- `movement_type` - тип перемещения (VARCHAR, NOT NULL)
- `location_type` - тип локации (VARCHAR, NOT NULL)
- `location_code` - код локации (VARCHAR, NOT NULL)
- `movement_datetime` - дата и время перемещения (TIMESTAMP, NOT NULL)
- `operator_name` - имя оператора (VARCHAR)
- `notes` - примечания (TEXT)
- `latitude` - широта (DECIMAL(10,8))
- `longitude` - долгота (DECIMAL(11,8))
- Метаданные: `created_at`, `created_by`

**Связи:**
- Shipment Movement → Shipment (многие к одному) - перемещение принадлежит отгрузке

##### Сущность: Shipment Status History (История статусов отгрузки)
**Бизнес-ключ:** `shipment_external_id` + `changed_at`

**Атрибуты:**
- `old_status` - предыдущий статус (VARCHAR)
- `new_status` - новый статус (VARCHAR, NOT NULL)
- `change_reason` - причина изменения (VARCHAR)
- `changed_at` - время изменения (TIMESTAMP, NOT NULL)
- `changed_by` - кто изменил (VARCHAR, NOT NULL)
- `location_type` - тип локации (VARCHAR)
- `location_code` - код локации (VARCHAR)
- `notes` - примечания (TEXT)
- `customer_notified` - уведомлен ли клиент (BOOLEAN, NOT NULL, DEFAULT false)

## Архитектура

- **Master**: PostgreSQL 15 на порту 2222
- **Replica**: PostgreSQL 15 на порту 5433 (read-only)
- **Репликация**: Физическая потоковая репликация через replication slot
- **Docker**: Docker Compose для оркестрации

## Структура проекта

```
HSE_FTiAD_DWH/
├── docker-compose.yml          # Конфигурация Docker Compose
├── docker-init.sh              # Скрипт инициализации кластера
├── debezium/                   # Конфигурация Debezium CDC
│   ├── connectors/
│   │   └── postgres-connector.json
│   └── README.md
├── dmp-service/                # Сервис загрузки данных в DWH
│   ├── config.py
│   ├── dwh_loader.py
│   ├── kafka_consumer.py
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
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
│       ├── 06_cohort_view.sql
│       ├── 07_dwh_detailed_ddl.sql    # DDL для Data Vault 2.0
│       ├── 08_dwh_init_source_systems.sql
│       ├── 09_debezium_setup.sql
│       └── 10_test_debezium_inserts.sql
├── ER_DIAGRAM_DWH_DETAILED.dbml # ER-диаграмма Data Vault 2.0
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
- Очистку старых данных (data/, replica_data/, dwh_data/)
- Запуск мастера PostgreSQL
- Инициализацию мастера (создание пользователя репликации, replication slot, баз данных и таблиц)
- Перезапуск мастера для применения конфигурации
- Создание бэкапа мастера через pg_basebackup для реплики
- Копирование бэкапа в volume реплики
- Настройку конфигурации реплики (primary_conninfo, primary_slot_name)
- Запуск реплики PostgreSQL
- Запуск DWH узла PostgreSQL
- Инициализацию систем-источников в DWH
- Настройку Debezium (создание publication в user_service_db)
- Запуск Zookeeper, Kafka и Debezium Connect
- Регистрацию Debezium connector
- Запуск DMP Service для загрузки данных в DWH

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

### 4. dwh_detailed (Детальный слой DWH)

Детальный слой DWH реализован в архитектуре Data Vault 2.0 в схеме `dwh_detailed` базы данных `dwh_db`.

**Хабы (Hubs):**
- `hub_source_system` - системы-источники данных
- `hub_user` - пользователи
- `hub_address` - адреса
- `hub_order` - заказы
- `hub_product` - товары
- `hub_shipment` - отгрузки
- `hub_warehouse` - склады
- `hub_pickup_point` - пункты выдачи

**Линки (Links):**
- `link_user_address` - связь пользователь-адрес
- `link_order_user` - связь заказ-пользователь
- `link_order_address` - связь заказ-адрес доставки
- `link_order_item` - связь заказ-товар (позиция заказа)
- `link_shipment_order` - связь отгрузка-заказ
- `link_shipment_warehouse` - связь отгрузка-склад
- `link_shipment_pickup_point` - связь отгрузка-пункт выдачи
- `link_shipment_address` - связь отгрузка-адрес доставки

**Саттелиты (Satellites):**
- `sat_user_details` - детали пользователя
- `sat_user_address_details` - детали адреса
- `sat_user_status_history` - история статусов пользователя
- `sat_order_details` - детали заказа
- `sat_order_financial` - финансовые данные заказа
- `sat_order_item_details` - детали позиции заказа
- `sat_order_status_history` - история статусов заказа
- `sat_product_details` - детали товара
- `sat_product_price` - цена товара
- `sat_shipment_details` - детали отгрузки
- `sat_shipment_movement_details` - детали перемещений отгрузки
- `sat_shipment_status_history` - история статусов отгрузки
- `sat_warehouse_details` - детали склада
- `sat_pickup_point_details` - детали пункта выдачи

**Создание структуры:**
```sql
\connect dwh_db;
\i init-script/sql/07_dwh_detailed_ddl.sql
\i init-script/sql/08_dwh_init_source_systems.sql
```

**Визуализация:**
ER-диаграмма доступна в файле `ER_DIAGRAM_DWH_DETAILED.dbml` и может быть открыта на https://dbdiagram.io

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
### ДЛЯ ПРОВЕРКИ ЛОГИКИ replica и DWH

Я подготовил скрипт 'проверка replica+dwh.sql', пробежавшись по которому можно отследить что все работает, как происходит реплика с  актуального состояния с мастера + отследить как все изменения на мастере логируются на двх

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

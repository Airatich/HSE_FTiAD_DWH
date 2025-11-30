-- =====================================================
-- Data Vault 2.0 DDL для детального слоя DWH
-- Схема: dwh_detailed
-- =====================================================

-- Создание схемы
CREATE SCHEMA IF NOT EXISTS dwh_detailed;

-- =====================================================
-- ХАБЫ (HUBS) - Бизнес-ключи
-- =====================================================

-- Хаб для систем-источников
CREATE TABLE dwh_detailed.hub_source_system (
    hub_source_system_key VARCHAR(32) PRIMARY KEY,
    source_system_id VARCHAR(50) NOT NULL,
    source_system_name VARCHAR(100) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT uk_dwh_source_system_id UNIQUE (source_system_id)
);

-- Хаб пользователей
CREATE TABLE dwh_detailed.hub_user (
    hub_user_key VARCHAR(32) PRIMARY KEY,
    user_external_id VARCHAR(255) NOT NULL,
    source_system_id VARCHAR(50) NOT NULL,
    hub_source_system_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT uk_dwh_user_external_id_source UNIQUE (user_external_id, source_system_id),
    CONSTRAINT fk_dwh_hub_user_source_system FOREIGN KEY (hub_source_system_key) REFERENCES dwh_detailed.hub_source_system(hub_source_system_key)
);

-- Хаб адресов
CREATE TABLE dwh_detailed.hub_address (
    hub_address_key VARCHAR(32) PRIMARY KEY,
    address_external_id UUID NOT NULL,
    source_system_id VARCHAR(50) NOT NULL,
    hub_source_system_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT uk_dwh_address_external_id_source UNIQUE (address_external_id, source_system_id),
    CONSTRAINT fk_dwh_hub_address_source_system FOREIGN KEY (hub_source_system_key) REFERENCES dwh_detailed.hub_source_system(hub_source_system_key)
);

-- Хаб заказов
CREATE TABLE dwh_detailed.hub_order (
    hub_order_key VARCHAR(32) PRIMARY KEY,
    order_external_id UUID NOT NULL,
    source_system_id VARCHAR(50) NOT NULL,
    hub_source_system_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT uk_dwh_order_external_id_source UNIQUE (order_external_id, source_system_id),
    CONSTRAINT fk_dwh_hub_order_source_system FOREIGN KEY (hub_source_system_key) REFERENCES dwh_detailed.hub_source_system(hub_source_system_key)
);

-- Хаб товаров
CREATE TABLE dwh_detailed.hub_product (
    hub_product_key VARCHAR(32) PRIMARY KEY,
    product_sku VARCHAR(255) NOT NULL,
    source_system_id VARCHAR(50) NOT NULL,
    hub_source_system_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT uk_dwh_product_sku_source UNIQUE (product_sku, source_system_id),
    CONSTRAINT fk_dwh_hub_product_source_system FOREIGN KEY (hub_source_system_key) REFERENCES dwh_detailed.hub_source_system(hub_source_system_key)
);

-- Хаб отгрузок
CREATE TABLE dwh_detailed.hub_shipment (
    hub_shipment_key VARCHAR(32) PRIMARY KEY,
    shipment_external_id UUID NOT NULL,
    source_system_id VARCHAR(50) NOT NULL,
    hub_source_system_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT uk_dwh_shipment_external_id_source UNIQUE (shipment_external_id, source_system_id),
    CONSTRAINT fk_dwh_hub_shipment_source_system FOREIGN KEY (hub_source_system_key) REFERENCES dwh_detailed.hub_source_system(hub_source_system_key)
);

-- Хаб складов
CREATE TABLE dwh_detailed.hub_warehouse (
    hub_warehouse_key VARCHAR(32) PRIMARY KEY,
    warehouse_code VARCHAR(255) NOT NULL,
    source_system_id VARCHAR(50) NOT NULL,
    hub_source_system_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT uk_dwh_warehouse_code_source UNIQUE (warehouse_code, source_system_id),
    CONSTRAINT fk_dwh_hub_warehouse_source_system FOREIGN KEY (hub_source_system_key) REFERENCES dwh_detailed.hub_source_system(hub_source_system_key)
);

-- Хаб пунктов выдачи
CREATE TABLE dwh_detailed.hub_pickup_point (
    hub_pickup_point_key VARCHAR(32) PRIMARY KEY,
    pickup_point_code VARCHAR(255) NOT NULL,
    source_system_id VARCHAR(50) NOT NULL,
    hub_source_system_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT uk_dwh_pickup_point_code_source UNIQUE (pickup_point_code, source_system_id),
    CONSTRAINT fk_dwh_hub_pickup_point_source_system FOREIGN KEY (hub_source_system_key) REFERENCES dwh_detailed.hub_source_system(hub_source_system_key)
);

-- =====================================================
-- ЛИНКИ (LINKS) - Связи между хабами
-- =====================================================

-- Связь пользователь-адрес
CREATE TABLE dwh_detailed.link_user_address (
    link_user_address_key VARCHAR(32) PRIMARY KEY,
    hub_user_key VARCHAR(32) NOT NULL,
    hub_address_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT fk_dwh_link_user_address_user FOREIGN KEY (hub_user_key) REFERENCES dwh_detailed.hub_user(hub_user_key),
    CONSTRAINT fk_dwh_link_user_address_address FOREIGN KEY (hub_address_key) REFERENCES dwh_detailed.hub_address(hub_address_key),
    CONSTRAINT uk_dwh_user_address UNIQUE (hub_user_key, hub_address_key)
);

-- Связь заказ-пользователь
CREATE TABLE dwh_detailed.link_order_user (
    link_order_user_key VARCHAR(32) PRIMARY KEY,
    hub_order_key VARCHAR(32) NOT NULL,
    hub_user_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT fk_dwh_link_order_user_order FOREIGN KEY (hub_order_key) REFERENCES dwh_detailed.hub_order(hub_order_key),
    CONSTRAINT fk_dwh_link_order_user_user FOREIGN KEY (hub_user_key) REFERENCES dwh_detailed.hub_user(hub_user_key),
    CONSTRAINT uk_dwh_order_user UNIQUE (hub_order_key, hub_user_key)
);

-- Связь заказ-адрес доставки
CREATE TABLE dwh_detailed.link_order_address (
    link_order_address_key VARCHAR(32) PRIMARY KEY,
    hub_order_key VARCHAR(32) NOT NULL,
    hub_address_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT fk_dwh_link_order_address_order FOREIGN KEY (hub_order_key) REFERENCES dwh_detailed.hub_order(hub_order_key),
    CONSTRAINT fk_dwh_link_order_address_address FOREIGN KEY (hub_address_key) REFERENCES dwh_detailed.hub_address(hub_address_key),
    CONSTRAINT uk_dwh_order_address UNIQUE (hub_order_key, hub_address_key)
);

-- Связь заказ-товар (позиция заказа)
CREATE TABLE dwh_detailed.link_order_item (
    link_order_item_key VARCHAR(32) PRIMARY KEY,
    hub_order_key VARCHAR(32) NOT NULL,
    hub_product_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT fk_dwh_link_order_item_order FOREIGN KEY (hub_order_key) REFERENCES dwh_detailed.hub_order(hub_order_key),
    CONSTRAINT fk_dwh_link_order_item_product FOREIGN KEY (hub_product_key) REFERENCES dwh_detailed.hub_product(hub_product_key),
    CONSTRAINT uk_dwh_order_item UNIQUE (hub_order_key, hub_product_key)
);

-- Связь отгрузка-заказ
CREATE TABLE dwh_detailed.link_shipment_order (
    link_shipment_order_key VARCHAR(32) PRIMARY KEY,
    hub_shipment_key VARCHAR(32) NOT NULL,
    hub_order_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT fk_dwh_link_shipment_order_shipment FOREIGN KEY (hub_shipment_key) REFERENCES dwh_detailed.hub_shipment(hub_shipment_key),
    CONSTRAINT fk_dwh_link_shipment_order_order FOREIGN KEY (hub_order_key) REFERENCES dwh_detailed.hub_order(hub_order_key),
    CONSTRAINT uk_dwh_shipment_order UNIQUE (hub_shipment_key, hub_order_key)
);

-- Связь отгрузка-склад отправления
CREATE TABLE dwh_detailed.link_shipment_warehouse (
    link_shipment_warehouse_key VARCHAR(32) PRIMARY KEY,
    hub_shipment_key VARCHAR(32) NOT NULL,
    hub_warehouse_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT fk_dwh_link_shipment_warehouse_shipment FOREIGN KEY (hub_shipment_key) REFERENCES dwh_detailed.hub_shipment(hub_shipment_key),
    CONSTRAINT fk_dwh_link_shipment_warehouse_warehouse FOREIGN KEY (hub_warehouse_key) REFERENCES dwh_detailed.hub_warehouse(hub_warehouse_key),
    CONSTRAINT uk_dwh_shipment_warehouse UNIQUE (hub_shipment_key, hub_warehouse_key)
);

-- Связь отгрузка-пункт выдачи
CREATE TABLE dwh_detailed.link_shipment_pickup_point (
    link_shipment_pickup_point_key VARCHAR(32) PRIMARY KEY,
    hub_shipment_key VARCHAR(32) NOT NULL,
    hub_pickup_point_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT fk_dwh_link_shipment_pickup_point_shipment FOREIGN KEY (hub_shipment_key) REFERENCES dwh_detailed.hub_shipment(hub_shipment_key),
    CONSTRAINT fk_dwh_link_shipment_pickup_point_pickup_point FOREIGN KEY (hub_pickup_point_key) REFERENCES dwh_detailed.hub_pickup_point(hub_pickup_point_key),
    CONSTRAINT uk_dwh_shipment_pickup_point UNIQUE (hub_shipment_key, hub_pickup_point_key)
);

-- Связь отгрузка-адрес доставки
CREATE TABLE dwh_detailed.link_shipment_address (
    link_shipment_address_key VARCHAR(32) PRIMARY KEY,
    hub_shipment_key VARCHAR(32) NOT NULL,
    hub_address_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    CONSTRAINT fk_dwh_link_shipment_address_shipment FOREIGN KEY (hub_shipment_key) REFERENCES dwh_detailed.hub_shipment(hub_shipment_key),
    CONSTRAINT fk_dwh_link_shipment_address_address FOREIGN KEY (hub_address_key) REFERENCES dwh_detailed.hub_address(hub_address_key),
    CONSTRAINT uk_dwh_shipment_address UNIQUE (hub_shipment_key, hub_address_key)
);

-- =====================================================
-- САТТЕЛИТЫ (SATELLITES) - Описательные атрибуты
-- =====================================================

-- Саттелит деталей пользователя
CREATE TABLE dwh_detailed.sat_user_details (
    hub_user_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    phone VARCHAR(50),
    date_of_birth DATE,
    registration_date TIMESTAMP,
    status VARCHAR(50),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    PRIMARY KEY (hub_user_key, load_date),
    CONSTRAINT fk_dwh_sat_user_details_user FOREIGN KEY (hub_user_key) REFERENCES dwh_detailed.hub_user(hub_user_key)
);

-- Саттелит деталей адреса
CREATE TABLE dwh_detailed.sat_user_address_details (
    hub_address_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    address_type VARCHAR(50),
    country VARCHAR(100),
    region VARCHAR(100),
    city VARCHAR(100),
    street_address VARCHAR(255),
    postal_code VARCHAR(20),
    apartment VARCHAR(50),
    is_default BOOLEAN,
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    PRIMARY KEY (hub_address_key, load_date),
    CONSTRAINT fk_dwh_sat_user_address_details_address FOREIGN KEY (hub_address_key) REFERENCES dwh_detailed.hub_address(hub_address_key)
);

-- Саттелит истории статусов пользователя
CREATE TABLE dwh_detailed.sat_user_status_history (
    hub_user_key VARCHAR(32) NOT NULL,
    changed_at TIMESTAMP NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    change_reason VARCHAR(255),
    session_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    PRIMARY KEY (hub_user_key, changed_at),
    CONSTRAINT fk_dwh_sat_user_status_history_user FOREIGN KEY (hub_user_key) REFERENCES dwh_detailed.hub_user(hub_user_key)
);

-- Саттелит деталей заказа
CREATE TABLE dwh_detailed.sat_order_details (
    hub_order_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    order_number VARCHAR(255),
    order_date TIMESTAMP,
    status VARCHAR(50),
    delivery_type VARCHAR(50),
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    payment_method VARCHAR(50),
    payment_status VARCHAR(50),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    PRIMARY KEY (hub_order_key, load_date),
    CONSTRAINT fk_dwh_sat_order_details_order FOREIGN KEY (hub_order_key) REFERENCES dwh_detailed.hub_order(hub_order_key)
);

-- Саттелит финансовых данных заказа
CREATE TABLE dwh_detailed.sat_order_financial (
    hub_order_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    subtotal DECIMAL(15,2),
    tax_amount DECIMAL(15,2),
    shipping_cost DECIMAL(15,2),
    discount_amount DECIMAL(15,2),
    total_amount DECIMAL(15,2),
    currency VARCHAR(3),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    PRIMARY KEY (hub_order_key, load_date),
    CONSTRAINT fk_dwh_sat_order_financial_order FOREIGN KEY (hub_order_key) REFERENCES dwh_detailed.hub_order(hub_order_key)
);

-- Саттелит деталей товара
CREATE TABLE dwh_detailed.sat_product_details (
    hub_product_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    product_name VARCHAR(255),
    category VARCHAR(255),
    brand VARCHAR(255),
    weight_grams INTEGER,
    dimensions_length_cm DECIMAL(8,2),
    dimensions_width_cm DECIMAL(8,2),
    dimensions_height_cm DECIMAL(8,2),
    is_active BOOLEAN,
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    PRIMARY KEY (hub_product_key, load_date),
    CONSTRAINT fk_dwh_sat_product_details_product FOREIGN KEY (hub_product_key) REFERENCES dwh_detailed.hub_product(hub_product_key)
);

-- Саттелит цены товара
CREATE TABLE dwh_detailed.sat_product_price (
    hub_product_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    price DECIMAL(15,2),
    currency VARCHAR(3),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    PRIMARY KEY (hub_product_key, load_date),
    CONSTRAINT fk_dwh_sat_product_price_product FOREIGN KEY (hub_product_key) REFERENCES dwh_detailed.hub_product(hub_product_key)
);

-- Саттелит деталей позиции заказа
CREATE TABLE dwh_detailed.sat_order_item_details (
    link_order_item_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    quantity INTEGER,
    unit_price DECIMAL(15,2),
    total_price DECIMAL(15,2),
    product_name_snapshot VARCHAR(255),
    product_category_snapshot VARCHAR(255),
    product_brand_snapshot VARCHAR(255),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    PRIMARY KEY (link_order_item_key, load_date),
    CONSTRAINT fk_dwh_sat_order_item_details_link FOREIGN KEY (link_order_item_key) REFERENCES dwh_detailed.link_order_item(link_order_item_key)
);

-- Саттелит истории статусов заказа
CREATE TABLE dwh_detailed.sat_order_status_history (
    hub_order_key VARCHAR(32) NOT NULL,
    changed_at TIMESTAMP NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    change_reason VARCHAR(255),
    changed_by VARCHAR(255),
    session_id VARCHAR(255),
    ip_address INET,
    notes TEXT,
    PRIMARY KEY (hub_order_key, changed_at),
    CONSTRAINT fk_dwh_sat_order_status_history_order FOREIGN KEY (hub_order_key) REFERENCES dwh_detailed.hub_order(hub_order_key)
);

-- Саттелит деталей склада
CREATE TABLE dwh_detailed.sat_warehouse_details (
    hub_warehouse_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    warehouse_name VARCHAR(255),
    warehouse_type VARCHAR(100),
    country VARCHAR(100),
    region VARCHAR(100),
    city VARCHAR(100),
    street_address VARCHAR(255),
    postal_code VARCHAR(20),
    is_active BOOLEAN,
    max_capacity_cubic_meters DECIMAL(10,2),
    operating_hours VARCHAR(255),
    contact_phone VARCHAR(50),
    manager_name VARCHAR(255),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    PRIMARY KEY (hub_warehouse_key, load_date),
    CONSTRAINT fk_dwh_sat_warehouse_details_warehouse FOREIGN KEY (hub_warehouse_key) REFERENCES dwh_detailed.hub_warehouse(hub_warehouse_key)
);

-- Саттелит деталей пункта выдачи
CREATE TABLE dwh_detailed.sat_pickup_point_details (
    hub_pickup_point_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    pickup_point_name VARCHAR(255),
    pickup_point_type VARCHAR(100),
    country VARCHAR(100),
    region VARCHAR(100),
    city VARCHAR(100),
    street_address VARCHAR(255),
    postal_code VARCHAR(20),
    is_active BOOLEAN,
    max_capacity_packages INTEGER,
    operating_hours VARCHAR(255),
    contact_phone VARCHAR(50),
    partner_name VARCHAR(255),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    PRIMARY KEY (hub_pickup_point_key, load_date),
    CONSTRAINT fk_dwh_sat_pickup_point_details_pickup_point FOREIGN KEY (hub_pickup_point_key) REFERENCES dwh_detailed.hub_pickup_point(hub_pickup_point_key)
);

-- Саттелит деталей отгрузки
CREATE TABLE dwh_detailed.sat_shipment_details (
    hub_shipment_key VARCHAR(32) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    tracking_number VARCHAR(255),
    status VARCHAR(50),
    weight_grams INTEGER,
    volume_cubic_cm INTEGER,
    package_count INTEGER,
    destination_type VARCHAR(50),
    created_date TIMESTAMP,
    dispatched_date TIMESTAMP,
    estimated_delivery_date TIMESTAMP,
    actual_delivery_date TIMESTAMP,
    delivery_notes TEXT,
    recipient_name VARCHAR(255),
    delivery_signature VARCHAR(255),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    PRIMARY KEY (hub_shipment_key, load_date),
    CONSTRAINT fk_dwh_sat_shipment_details_shipment FOREIGN KEY (hub_shipment_key) REFERENCES dwh_detailed.hub_shipment(hub_shipment_key)
);

-- Саттелит деталей перемещений отгрузки
CREATE TABLE dwh_detailed.sat_shipment_movement_details (
    hub_shipment_key VARCHAR(32) NOT NULL,
    movement_datetime TIMESTAMP NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    movement_type VARCHAR(50),
    location_type VARCHAR(50),
    location_code VARCHAR(255),
    operator_name VARCHAR(255),
    notes TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    created_at TIMESTAMP,
    created_by VARCHAR(255),
    PRIMARY KEY (hub_shipment_key, movement_datetime),
    CONSTRAINT fk_dwh_sat_shipment_movement_details_shipment FOREIGN KEY (hub_shipment_key) REFERENCES dwh_detailed.hub_shipment(hub_shipment_key)
);

-- Саттелит истории статусов отгрузки
CREATE TABLE dwh_detailed.sat_shipment_status_history (
    hub_shipment_key VARCHAR(32) NOT NULL,
    changed_at TIMESTAMP NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(100) NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    change_reason VARCHAR(255),
    changed_by VARCHAR(255),
    location_type VARCHAR(50),
    location_code VARCHAR(255),
    notes TEXT,
    customer_notified BOOLEAN,
    PRIMARY KEY (hub_shipment_key, changed_at),
    CONSTRAINT fk_dwh_sat_shipment_status_history_shipment FOREIGN KEY (hub_shipment_key) REFERENCES dwh_detailed.hub_shipment(hub_shipment_key)
);

-- =====================================================
-- ИНДЕКСЫ для оптимизации запросов
-- =====================================================

-- Индексы на хабах для поиска по бизнес-ключам
CREATE INDEX idx_hub_user_external_id ON dwh_detailed.hub_user(user_external_id);
CREATE INDEX idx_hub_address_external_id ON dwh_detailed.hub_address(address_external_id);
CREATE INDEX idx_hub_order_external_id ON dwh_detailed.hub_order(order_external_id);
CREATE INDEX idx_hub_product_sku ON dwh_detailed.hub_product(product_sku);
CREATE INDEX idx_hub_shipment_external_id ON dwh_detailed.hub_shipment(shipment_external_id);
CREATE INDEX idx_hub_warehouse_code ON dwh_detailed.hub_warehouse(warehouse_code);
CREATE INDEX idx_hub_pickup_point_code ON dwh_detailed.hub_pickup_point(pickup_point_code);

-- Индексы на саттелитах для поиска по load_date
CREATE INDEX idx_sat_user_details_load_date ON dwh_detailed.sat_user_details(hub_user_key, load_date DESC);
CREATE INDEX idx_sat_user_address_details_load_date ON dwh_detailed.sat_user_address_details(hub_address_key, load_date DESC);
CREATE INDEX idx_sat_order_details_load_date ON dwh_detailed.sat_order_details(hub_order_key, load_date DESC);
CREATE INDEX idx_sat_order_financial_load_date ON dwh_detailed.sat_order_financial(hub_order_key, load_date DESC);
CREATE INDEX idx_sat_product_details_load_date ON dwh_detailed.sat_product_details(hub_product_key, load_date DESC);
CREATE INDEX idx_sat_product_price_load_date ON dwh_detailed.sat_product_price(hub_product_key, load_date DESC);
CREATE INDEX idx_sat_warehouse_details_load_date ON dwh_detailed.sat_warehouse_details(hub_warehouse_key, load_date DESC);
CREATE INDEX idx_sat_pickup_point_details_load_date ON dwh_detailed.sat_pickup_point_details(hub_pickup_point_key, load_date DESC);
CREATE INDEX idx_sat_shipment_details_load_date ON dwh_detailed.sat_shipment_details(hub_shipment_key, load_date DESC);

-- Индексы на линках
CREATE INDEX idx_link_user_address_user ON dwh_detailed.link_user_address(hub_user_key);
CREATE INDEX idx_link_user_address_address ON dwh_detailed.link_user_address(hub_address_key);
CREATE INDEX idx_link_order_user_order ON dwh_detailed.link_order_user(hub_order_key);
CREATE INDEX idx_link_order_user_user ON dwh_detailed.link_order_user(hub_user_key);
CREATE INDEX idx_link_order_address_order ON dwh_detailed.link_order_address(hub_order_key);
CREATE INDEX idx_link_order_item_order ON dwh_detailed.link_order_item(hub_order_key);
CREATE INDEX idx_link_shipment_order_shipment ON dwh_detailed.link_shipment_order(hub_shipment_key);
CREATE INDEX idx_link_shipment_order_order ON dwh_detailed.link_shipment_order(hub_order_key);


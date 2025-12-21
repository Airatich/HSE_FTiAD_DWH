-- =====================================================
-- Создание схемы presentation для витрин данных
-- =====================================================
-- Этот скрипт выполняется в базе postgres (DWH)
-- Схема presentation создается в той же базе, где находится dwh_detailed

-- Создание схемы presentation
CREATE SCHEMA IF NOT EXISTS presentation;

-- =====================================================
-- Витрина 1: Аналитика закупок
-- =====================================================

CREATE TABLE IF NOT EXISTS presentation.purchase_analytics (
    purchase_date DATE NOT NULL,
    product_id INT NOT NULL,  -- числовой ID на основе product_sku
    product_name TEXT,
    category TEXT,
    supplier_id INT NOT NULL,  -- числовой ID на основе brand
    supplier_name TEXT,  -- brand используется как supplier_name
    purchase_qty NUMERIC,
    total_purchase_amount NUMERIC,
    avg_unit_price NUMERIC,
    PRIMARY KEY (purchase_date, product_id, supplier_id)
);

CREATE INDEX IF NOT EXISTS idx_purchase_analytics_date ON presentation.purchase_analytics(purchase_date);
CREATE INDEX IF NOT EXISTS idx_purchase_analytics_product ON presentation.purchase_analytics(product_id);
CREATE INDEX IF NOT EXISTS idx_purchase_analytics_supplier ON presentation.purchase_analytics(supplier_id);

-- =====================================================
-- Витрина 2: Доставка по складам
-- =====================================================

CREATE TABLE IF NOT EXISTS presentation.warehouse_delivery (
    shipment_date DATE NOT NULL,
    warehouse_id INT NOT NULL,  -- числовой ID на основе warehouse_code
    warehouse_name TEXT,
    order_count INT,
    total_shipment_qty NUMERIC,
    avg_processing_time_min NUMERIC,  -- среднее время обработки в минутах
    delayed_orders_count INT,
    unique_customers_count INT,
    PRIMARY KEY (shipment_date, warehouse_id)
);

CREATE INDEX IF NOT EXISTS idx_warehouse_delivery_date ON presentation.warehouse_delivery(shipment_date);
CREATE INDEX IF NOT EXISTS idx_warehouse_delivery_warehouse ON presentation.warehouse_delivery(warehouse_id);


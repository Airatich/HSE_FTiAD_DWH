\connect logistics_service_db;


CREATE TABLE public.shipments (
    shipment_id SERIAL PRIMARY KEY,
    shipment_external_id UUID NOT NULL,
    order_external_id UUID NOT NULL,
    tracking_number VARCHAR NOT NULL,
    status VARCHAR NOT NULL,
    weight_grams INTEGER CHECK (weight_grams > 0),
    volume_cubic_cm INTEGER CHECK (volume_cubic_cm > 0),
    package_count INTEGER NOT NULL DEFAULT 1 CHECK (package_count > 0),
    origin_warehouse_code VARCHAR NOT NULL,
    destination_type VARCHAR NOT NULL,
    destination_pickup_point_code VARCHAR,
    destination_address_external_id UUID,
    created_date TIMESTAMP NOT NULL,
    dispatched_date TIMESTAMP,
    estimated_delivery_date TIMESTAMP,
    actual_delivery_date TIMESTAMP,
    delivery_notes TEXT,
    recipient_name VARCHAR NOT NULL,
    delivery_signature VARCHAR,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR NOT NULL,
    updated_by VARCHAR NOT NULL,

    -- Уникальные ключи
    CONSTRAINT uk_shipment_external_id UNIQUE (shipment_external_id),
    CONSTRAINT uk_tracking_number UNIQUE (tracking_number),

    -- Проверка целостности данных для destination
    CONSTRAINT chk_destination_type CHECK (
        (destination_type = 'pickup_point' AND destination_pickup_point_code IS NOT NULL AND destination_address_external_id IS NULL) OR
        (destination_type = 'address' AND destination_address_external_id IS NOT NULL AND destination_pickup_point_code IS NULL) OR
        (destination_type NOT IN ('pickup_point', 'address'))
    )
);

CREATE TABLE public.warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    warehouse_code VARCHAR NOT NULL,
    warehouse_name VARCHAR NOT NULL,
    warehouse_type VARCHAR NOT NULL,
    country VARCHAR NOT NULL,
    region VARCHAR,
    city VARCHAR NOT NULL,
    street_address VARCHAR NOT NULL,
    postal_code VARCHAR,
    is_active BOOLEAN NOT NULL DEFAULT true,
    max_capacity_cubic_meters DECIMAL(10,2) CHECK (max_capacity_cubic_meters > 0),
    operating_hours VARCHAR,
    contact_phone VARCHAR,
    manager_name VARCHAR,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR NOT NULL,
    updated_by VARCHAR NOT NULL,

    -- Уникальный ключ для кода склада
    CONSTRAINT uk_warehouse_code UNIQUE (warehouse_code)
);

CREATE TABLE public.pickup_points(
    pickup_point_id SERIAL PRIMARY KEY,
    pickup_point_code VARCHAR NOT NULL,
    pickup_point_name VARCHAR NOT NULL,
    pickup_point_type VARCHAR NOT NULL,
    country VARCHAR NOT NULL,
    region VARCHAR,
    city VARCHAR NOT NULL,
    street_address VARCHAR NOT NULL,
    postal_code VARCHAR,
    is_active BOOLEAN NOT NULL DEFAULT true,
    max_capacity_packages INTEGER CHECK (max_capacity_packages > 0),
    operating_hours VARCHAR,
    contact_phone VARCHAR,
    partner_name VARCHAR,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR NOT NULL,
    updated_by VARCHAR NOT NULL,

    -- Уникальный ключ для кода пункта выдачи
    CONSTRAINT uk_pickup_point_code UNIQUE (pickup_point_code)
);

CREATE TABLE public.shipment_movements(
    movement_id SERIAL PRIMARY KEY,
    shipment_external_id UUID NOT NULL,
    movement_type VARCHAR NOT NULL,
    location_type VARCHAR NOT NULL,
    location_code VARCHAR NOT NULL,
    movement_datetime TIMESTAMP NOT NULL,
    operator_name VARCHAR,
    notes TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR NOT NULL

    -- Логический внешний ключ (закомментирован для кросс-базовой связи)
    -- CONSTRAINT fk_shipment_external FOREIGN KEY (shipment_external_id)
    -- REFERENCES SHIPMENTS(shipment_external_id)
);

CREATE TABLE public.shipment_status_history(
    history_id SERIAL PRIMARY KEY,
    shipment_external_id UUID NOT NULL,
    old_status VARCHAR,
    new_status VARCHAR NOT NULL,
    change_reason VARCHAR,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR NOT NULL,
    location_type VARCHAR,
    location_code VARCHAR,
    notes TEXT,
    customer_notified BOOLEAN NOT NULL DEFAULT false

    -- Логический внешний ключ (закомментирован для кросс-базовой связи)
    -- CONSTRAINT fk_shipment_status_history_shipment FOREIGN KEY (shipment_external_id)
    -- REFERENCES SHIPMENTS(shipment_external_id)
);
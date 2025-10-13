\connect order_service_db;

CREATE TABLE public.orders (
    order_id SERIAL PRIMARY KEY,
    order_external_id UUID NOT NULL,
    user_external_id UUID NOT NULL,
    order_number VARCHAR NOT NULL,
    order_date TIMESTAMP NOT NULL,
    status VARCHAR NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(15,2) NOT NULL,
    shipping_cost DECIMAL(15,2) NOT NULL,
    discount_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    delivery_address_external_id UUID NOT NULL,
    delivery_type VARCHAR NOT NULL,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    payment_method VARCHAR NOT NULL,
    payment_status VARCHAR NOT NULL,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR NOT NULL,
    updated_by VARCHAR NOT NULL,
    CONSTRAINT uk_order_external_id UNIQUE (order_external_id),
    CONSTRAINT uk_order_number UNIQUE (order_number)
);

CREATE TABLE public.products (
    product_id SERIAL PRIMARY KEY,
    product_sku VARCHAR NOT NULL,
    product_name VARCHAR NOT NULL,
    category VARCHAR NOT NULL,
    brand VARCHAR NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    weight_grams INTEGER,
    dimensions_length_cm DECIMAL(8,2),
    dimensions_width_cm DECIMAL(8,2),
    dimensions_height_cm DECIMAL(8,2),
    is_active BOOLEAN NOT NULL DEFAULT true,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR NOT NULL,
    updated_by VARCHAR NOT NULL,

    -- Уникальный ключ для SKU
    CONSTRAINT uk_product_sku UNIQUE (product_sku)
);

CREATE TABLE public.order_items(
    order_item_id SERIAL PRIMARY KEY,
    order_external_id UUID NOT NULL,
    product_sku VARCHAR NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(15,2) NOT NULL CHECK (unit_price >= 0),
    total_price DECIMAL(15,2) NOT NULL CHECK (total_price >= 0),
    product_name_snapshot VARCHAR NOT NULL,
    product_category_snapshot VARCHAR NOT NULL,
    product_brand_snapshot VARCHAR NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR NOT NULL,
    updated_by VARCHAR NOT NULL
);

CREATE TABLE public.order_status_history(
    history_id SERIAL PRIMARY KEY,
    order_external_id UUID NOT NULL,
    old_status VARCHAR,
    new_status VARCHAR NOT NULL,
    change_reason VARCHAR,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR NOT NULL,
    session_id VARCHAR,
    ip_address INET,
    notes TEXT
);


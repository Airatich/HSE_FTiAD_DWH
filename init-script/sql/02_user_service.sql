\connect user_service_db;

CREATE TABLE public.users (
    user_id SERIAL PRIMARY KEY,
    user_external_id VARCHAR UNIQUE NOT NULL,
    email VARCHAR NOT NULL,
    first_name VARCHAR NOT NULL,
    last_name VARCHAR NOT NULL,
    phone VARCHAR,
    date_of_birth DATE,
    registration_date TIMESTAMP NOT NULL,
    status VARCHAR NOT NULL,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR NOT NULL,
    updated_by VARCHAR NOT NULL
);

CREATE TABLE public.user_addresses (
    address_id SERIAL PRIMARY KEY,
    address_external_id UUID NOT NULL,
    user_external_id UUID NOT NULL,
    address_type VARCHAR NOT NULL,
    country VARCHAR NOT NULL,
    region VARCHAR,
    city VARCHAR NOT NULL,
    street_address VARCHAR NOT NULL,
    postal_code VARCHAR,
    apartment VARCHAR,
    is_default BOOLEAN NOT NULL DEFAULT false,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR NOT NULL,
    updated_by VARCHAR NOT NULL,
    CONSTRAINT uk_address_external_id UNIQUE (address_external_id)
);

CREATE TABLE public.user_status_history (
    history_id SERIAL PRIMARY KEY,
    user_external_id UUID NOT NULL,
    old_status VARCHAR,
    new_status VARCHAR NOT NULL,
    change_reason VARCHAR,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR NOT NULL,
    session_id VARCHAR,
    ip_address INET,
    user_agent TEXT
);

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

ALTER TABLE products
ADD COLUMN IF NOT EXISTS brand VARCHAR(150),
ADD COLUMN IF NOT EXISTS category VARCHAR(150),
ADD COLUMN IF NOT EXISTS sub_category VARCHAR(150),
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS ingredients TEXT,
ADD COLUMN IF NOT EXISTS nutrition_info JSONB,
ADD COLUMN IF NOT EXISTS storage_instruction TEXT,
ADD COLUMN IF NOT EXISTS manufacturer VARCHAR(200),
ADD COLUMN IF NOT EXISTS country_of_origin VARCHAR(100),
ADD COLUMN IF NOT EXISTS product_source VARCHAR(50) DEFAULT 'LOCAL_DATABASE',
ADD COLUMN IF NOT EXISTS external_source VARCHAR(100),
ADD COLUMN IF NOT EXISTS external_source_url TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

ALTER TABLE product_identifiers
ADD COLUMN IF NOT EXISTS identifier_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS identifier_value VARCHAR(150),
ADD COLUMN IF NOT EXISTS is_primary BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS source VARCHAR(50) DEFAULT 'LOCAL_DATABASE',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_identifiers_unique_value
ON product_identifiers(identifier_type, identifier_value);

CREATE INDEX IF NOT EXISTS idx_product_identifiers_product_id
ON product_identifiers(product_id);

CREATE INDEX IF NOT EXISTS idx_product_identifiers_value
ON product_identifiers(identifier_value);

CREATE INDEX IF NOT EXISTS idx_products_name
ON products(name);

CREATE INDEX IF NOT EXISTS idx_products_brand
ON products(brand);

CREATE INDEX IF NOT EXISTS idx_products_category
ON products(category);

CREATE TABLE IF NOT EXISTS external_product_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    query_value VARCHAR(255) NOT NULL,
    query_type VARCHAR(50) NOT NULL,

    external_source VARCHAR(100) NOT NULL DEFAULT 'OPEN_FOOD_FACTS',
    external_product_id VARCHAR(255),
    external_source_url TEXT,

    barcode VARCHAR(100),
    product_name VARCHAR(255),
    brand VARCHAR(150),
    category VARCHAR(150),
    description TEXT,
    ingredients TEXT,
    nutrition_info JSONB,
    storage_instruction TEXT,
    image_url TEXT,

    raw_response JSONB,

    cache_status VARCHAR(50) DEFAULT 'ACTIVE',
    fetched_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_external_product_cache_query
ON external_product_cache(query_type, query_value);

CREATE INDEX IF NOT EXISTS idx_external_product_cache_barcode
ON external_product_cache(barcode);

CREATE INDEX IF NOT EXISTS idx_external_product_cache_product_name
ON external_product_cache(product_name);

CREATE INDEX IF NOT EXISTS idx_external_product_cache_source
ON external_product_cache(external_source);

CREATE TABLE IF NOT EXISTS product_lookup_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    query_value VARCHAR(255) NOT NULL,
    query_type VARCHAR(50) NOT NULL,

    result_status VARCHAR(50) NOT NULL,
    result_source VARCHAR(100),

    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    external_cache_id UUID REFERENCES external_product_cache(id) ON DELETE SET NULL,

    requested_by VARCHAR(150),
    request_source VARCHAR(100) DEFAULT 'BACKEND_API',

    telegram_chat_id VARCHAR(150),
    telegram_user_id VARCHAR(150),
    n8n_execution_id VARCHAR(150),

    response_payload JSONB,
    error_message TEXT,

    lookup_duration_ms INTEGER,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_lookup_logs_query
ON product_lookup_logs(query_type, query_value);

CREATE INDEX IF NOT EXISTS idx_product_lookup_logs_result_status
ON product_lookup_logs(result_status);

CREATE INDEX IF NOT EXISTS idx_product_lookup_logs_created_at
ON product_lookup_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_product_lookup_logs_product_id
ON product_lookup_logs(product_id);

CREATE TABLE IF NOT EXISTS unknown_product_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    query_value VARCHAR(255) NOT NULL,
    query_type VARCHAR(50) NOT NULL,

    barcode VARCHAR(100),
    product_name VARCHAR(255),

    request_source VARCHAR(100) DEFAULT 'BACKEND_API',
    requested_by VARCHAR(150),

    telegram_chat_id VARCHAR(150),
    telegram_user_id VARCHAR(150),
    n8n_execution_id VARCHAR(150),

    status VARCHAR(50) DEFAULT 'PENDING',

    admin_notes TEXT,
    resolved_product_id UUID REFERENCES products(id) ON DELETE SET NULL,

    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_unknown_product_requests_query
ON unknown_product_requests(query_type, query_value);

CREATE INDEX IF NOT EXISTS idx_unknown_product_requests_status
ON unknown_product_requests(status);

CREATE INDEX IF NOT EXISTS idx_unknown_product_requests_barcode
ON unknown_product_requests(barcode);

CREATE INDEX IF NOT EXISTS idx_unknown_product_requests_created_at
ON unknown_product_requests(created_at);

-- Add optional validation constraints
ALTER TABLE product_lookup_logs
DROP CONSTRAINT IF EXISTS chk_product_lookup_query_type;

ALTER TABLE product_lookup_logs
ADD CONSTRAINT chk_product_lookup_query_type
CHECK (query_type IN ('PRODUCT_ID', 'BARCODE', 'PRODUCT_NAME', 'UNKNOWN'));

ALTER TABLE product_lookup_logs
DROP CONSTRAINT IF EXISTS chk_product_lookup_result_status;

ALTER TABLE product_lookup_logs
ADD CONSTRAINT chk_product_lookup_result_status
CHECK (result_status IN ('FOUND', 'NOT_FOUND', 'INVALID_QUERY', 'EXTERNAL_API_FAILED', 'ERROR'));

ALTER TABLE product_lookup_logs
DROP CONSTRAINT IF EXISTS chk_product_lookup_result_source;

ALTER TABLE product_lookup_logs
ADD CONSTRAINT chk_product_lookup_result_source
CHECK (result_source IN ('LOCAL_DATABASE', 'OPEN_FOOD_FACTS', 'CACHE', 'NONE'));

ALTER TABLE unknown_product_requests
DROP CONSTRAINT IF EXISTS chk_unknown_product_status;

ALTER TABLE unknown_product_requests
ADD CONSTRAINT chk_unknown_product_status
CHECK (status IN ('PENDING', 'CREATED', 'IGNORED', 'DUPLICATE', 'RESOLVED'));

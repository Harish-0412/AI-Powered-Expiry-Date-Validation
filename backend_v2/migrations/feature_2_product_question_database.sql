CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS product_question_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    question TEXT NOT NULL,
    detected_intent VARCHAR(100),
    extracted_entity VARCHAR(255),

    result_status VARCHAR(50),
    result_source VARCHAR(100),

    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    inventory_item_id UUID REFERENCES inventory_items(id) ON DELETE SET NULL,

    request_source VARCHAR(100) DEFAULT 'BACKEND_API',
    requested_by VARCHAR(150),

    telegram_chat_id VARCHAR(150),
    telegram_user_id VARCHAR(150),
    n8n_execution_id VARCHAR(150),

    response_payload JSONB,
    error_message TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_question_logs_intent
ON product_question_logs(detected_intent);

CREATE INDEX IF NOT EXISTS idx_product_question_logs_product_id
ON product_question_logs(product_id);

CREATE INDEX IF NOT EXISTS idx_product_question_logs_inventory_item_id
ON product_question_logs(inventory_item_id);

CREATE INDEX IF NOT EXISTS idx_product_question_logs_created_at
ON product_question_logs(created_at);

ALTER TABLE product_question_logs
DROP CONSTRAINT IF EXISTS chk_product_question_result_status;

ALTER TABLE product_question_logs
ADD CONSTRAINT chk_product_question_result_status
CHECK (result_status IN ('ANSWERED', 'NOT_FOUND', 'UNSUPPORTED_INTENT', 'INVALID_QUESTION', 'ERROR'));

ALTER TABLE product_question_logs
DROP CONSTRAINT IF EXISTS chk_product_question_result_source;

ALTER TABLE product_question_logs
ADD CONSTRAINT chk_product_question_result_source
CHECK (result_source IN ('LOCAL_DATABASE', 'NONE'));

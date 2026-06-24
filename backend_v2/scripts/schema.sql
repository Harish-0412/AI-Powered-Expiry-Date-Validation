-- =============================================================
-- Phase 2 — Complete PostgreSQL Schema
-- AI-Powered Expiry Date Validation System
-- =============================================================
-- Safe to run multiple times (all tables use IF NOT EXISTS).
-- Run with:
--   docker exec -i expiry_postgres psql -U expiry_user -d expiry_db < scripts/schema.sql

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================
-- 1. products
-- Master product catalogue. Every barcode scan and inventory
-- intake must reference a product in this table.
-- =============================================================
CREATE TABLE IF NOT EXISTS products (
    id                   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name                 VARCHAR(255) NOT NULL,
    brand                VARCHAR(255),
    sku                  VARCHAR(100) NOT NULL UNIQUE,
    barcode              VARCHAR(100) NOT NULL UNIQUE,
    barcode_type         VARCHAR(20)  NOT NULL DEFAULT 'EAN13',
    -- EAN13 | EAN8 | UPC-A | QR | CODE128 | DATAMATRIX
    category             VARCHAR(100),
    description          TEXT,
    default_storage_type VARCHAR(50),
    -- ambient | refrigerated | frozen | controlled
    image_url            VARCHAR(500),
    -- Primary product image URL (populated by image upload pipeline)
    is_active            BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_sku      ON products (sku);
CREATE INDEX IF NOT EXISTS idx_products_barcode  ON products (barcode);
CREATE INDEX IF NOT EXISTS idx_products_category ON products (category);
CREATE INDEX IF NOT EXISTS idx_products_brand    ON products (brand);

-- =============================================================
-- 2. barcode_scans
-- Records every barcode scanning event.
-- A scan may or may not resolve to a known product.
-- =============================================================
CREATE TABLE IF NOT EXISTS barcode_scans (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id      UUID        REFERENCES products (id) ON DELETE SET NULL,
    -- NULL when barcode is not yet registered in the catalogue
    raw_barcode     VARCHAR(255) NOT NULL,
    barcode_type    VARCHAR(20),
    scan_source     VARCHAR(100),
    -- device_id, session_id, api_client
    scan_status     VARCHAR(20)  NOT NULL DEFAULT 'unresolved',
    -- resolved | unresolved
    notes           TEXT,
    scanned_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_barcode_scans_product_id  ON barcode_scans (product_id);
CREATE INDEX IF NOT EXISTS idx_barcode_scans_raw_barcode ON barcode_scans (raw_barcode);
CREATE INDEX IF NOT EXISTS idx_barcode_scans_scan_status ON barcode_scans (scan_status);

-- =============================================================
-- 3. inventory_items
-- A single batch received during warehouse intake.
-- Pipeline status tracks where this batch is in the backend
-- processing flow. Final decisions come from ml_predictions.
-- =============================================================
CREATE TABLE IF NOT EXISTS inventory_items (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id       UUID         NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    barcode_scan_id  UUID         REFERENCES barcode_scans (id) ON DELETE SET NULL,
    batch_number     VARCHAR(100),
    manufacturing_date DATE,
    expiry_date        DATE,
    -- Backend pipeline status (never ACCEPTED/REJECTED here — those come from ML)
    pipeline_status  VARCHAR(30)  NOT NULL DEFAULT 'PENDING_OCR',
    -- PENDING_OCR | OCR_COMPLETED | PENDING_ML_REVIEW | ML_COMPLETED | MANUAL_REVIEW
    status_reason    TEXT,
    quantity         INTEGER      DEFAULT 1,
    unit             VARCHAR(20),
    -- units | cartons | pallets
    intake_notes     TEXT,
    intake_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inventory_items_product_id       ON inventory_items (product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_pipeline_status  ON inventory_items (pipeline_status);
CREATE INDEX IF NOT EXISTS idx_inventory_items_batch_number     ON inventory_items (batch_number);
CREATE INDEX IF NOT EXISTS idx_inventory_items_expiry_date      ON inventory_items (expiry_date);

-- =============================================================
-- 4. product_images
-- Uploaded product or label images awaiting OCR processing.
-- =============================================================
CREATE TABLE IF NOT EXISTS product_images (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id        UUID         NOT NULL REFERENCES products (id) ON DELETE CASCADE,
    file_path         VARCHAR(500) NOT NULL,
    file_url          VARCHAR(500),
    file_size_bytes   INTEGER,
    mime_type         VARCHAR(100),
    image_type        VARCHAR(50),
    -- front_label | back_label | side_label | product_photo | barcode_close_up
    processing_status VARCHAR(30)  NOT NULL DEFAULT 'uploaded',
    -- uploaded | ocr_pending | ocr_completed | failed
    notes             TEXT,
    uploaded_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_images_product_id        ON product_images (product_id);
CREATE INDEX IF NOT EXISTS idx_product_images_processing_status ON product_images (processing_status);

-- =============================================================
-- 5. ocr_results
-- Raw OCR extraction output from the processing pipeline.
-- Stores text and extracted date candidate blocks as JSON.
-- No date parsing here — that is done by the ML team.
-- =============================================================
CREATE TABLE IF NOT EXISTS ocr_results (
    id                     UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
    product_image_id       UUID  NOT NULL REFERENCES product_images (id) ON DELETE CASCADE,
    inventory_item_id      UUID  REFERENCES inventory_items (id) ON DELETE SET NULL,
    raw_text               TEXT,
    ocr_engine             VARCHAR(100),
    -- e.g. "tesseract-5.3", "google-vision-v1"
    ocr_engine_version     VARCHAR(50),
    extracted_text_blocks  JSONB,
    -- [{"label": "MFG", "value": "01/05/2026"}, {"label": "EXP", "value": "01/11/2026"}]
    overall_confidence     NUMERIC(5,4),
    -- 0.0000 – 1.0000
    ocr_status             VARCHAR(30) NOT NULL DEFAULT 'pending',
    -- pending | completed | failed
    failure_reason         TEXT,
    processed_at           TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ocr_results_product_image_id  ON ocr_results (product_image_id);
CREATE INDEX IF NOT EXISTS idx_ocr_results_inventory_item_id ON ocr_results (inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_ocr_results_ocr_status        ON ocr_results (ocr_status);

-- =============================================================
-- 6. storage_contexts
-- Physical storage location and environmental conditions
-- for an inventory batch. One-to-one with inventory_items.
-- Gives ML team context for shelf-life prediction.
-- =============================================================
CREATE TABLE IF NOT EXISTS storage_contexts (
    id                  UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_item_id   UUID  NOT NULL UNIQUE REFERENCES inventory_items (id) ON DELETE CASCADE,
    warehouse_id        VARCHAR(100),
    zone                VARCHAR(100),
    aisle               VARCHAR(50),
    shelf               VARCHAR(50),
    bin_location        VARCHAR(100),
    storage_type        VARCHAR(50),
    -- ambient | refrigerated | frozen | controlled
    temperature_celsius NUMERIC(5,2),
    humidity_percent    NUMERIC(5,2),
    notes               TEXT,
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_storage_contexts_inventory_item_id ON storage_contexts (inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_storage_contexts_warehouse_id       ON storage_contexts (warehouse_id);

-- =============================================================
-- 7. ml_predictions
-- ML team's shelf-life prediction for a batch.
-- Backend only writes here when the ML team returns a result.
-- Final decisions (ACCEPTED, REJECTED, etc.) live here ONLY.
-- =============================================================
CREATE TABLE IF NOT EXISTS ml_predictions (
    id                      UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_item_id       UUID  NOT NULL REFERENCES inventory_items (id) ON DELETE CASCADE,
    model_name              VARCHAR(200),
    model_version           VARCHAR(50),
    predicted_mfg_date      DATE,
    predicted_expiry_date   DATE,
    predicted_remaining_days INTEGER,
    predicted_decision      VARCHAR(30),
    -- ACCEPTED | PRIORITY_SALE | REJECTED | REQUIRES_REVIEW
    decision_confidence     NUMERIC(5,4),
    decision_reason         TEXT,
    raw_prediction_payload  TEXT,
    -- Full JSON string from the ML model
    prediction_status       VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- pending | completed | failed
    failure_reason          TEXT,
    predicted_at            TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ml_predictions_inventory_item_id  ON ml_predictions (inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_ml_predictions_predicted_decision ON ml_predictions (predicted_decision);
CREATE INDEX IF NOT EXISTS idx_ml_predictions_prediction_status  ON ml_predictions (prediction_status);

-- =============================================================
-- 8. manual_reviews
-- Human review records for flagged batches.
-- Created when OCR fails, ML confidence is low, or a
-- supervisor overrides an automated decision.
-- =============================================================
CREATE TABLE IF NOT EXISTS manual_reviews (
    id                   UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_item_id    UUID  NOT NULL REFERENCES inventory_items (id) ON DELETE CASCADE,
    reviewer_id          VARCHAR(200),
    reviewer_role        VARCHAR(100),
    -- warehouse_staff | supervisor | qa
    corrected_mfg_date   DATE,
    corrected_expiry_date DATE,
    human_decision       VARCHAR(30),
    -- ACCEPTED | PRIORITY_SALE | REJECTED | ESCALATE_TO_QA
    review_notes         TEXT,
    escalation_reason    TEXT,
    review_status        VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- pending | in_progress | completed | escalated
    reviewed_at          TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_manual_reviews_inventory_item_id ON manual_reviews (inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_manual_reviews_review_status     ON manual_reviews (review_status);
CREATE INDEX IF NOT EXISTS idx_manual_reviews_human_decision    ON manual_reviews (human_decision);

-- =============================================================
-- 9. audit_logs
-- Immutable append-only event log.
-- Records who did what, on which record, and what changed.
-- Never updated — only inserted.
-- =============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type      VARCHAR(100) NOT NULL,
    -- product.created | inventory.intake | ocr.completed
    -- ml.prediction_received | manual_review.completed | status.changed
    entity_type     VARCHAR(100),
    entity_id       VARCHAR(100),
    actor_id        VARCHAR(200),
    actor_type      VARCHAR(50),
    -- user | service | ml_team | system
    before_state    JSONB,
    after_state     JSONB,
    change_summary  TEXT,
    ip_address      VARCHAR(50),
    user_agent      VARCHAR(500),
    request_id      VARCHAR(100),
    occurred_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_event_type  ON audit_logs (event_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_id   ON audit_logs (entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_id    ON audit_logs (actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_occurred_at ON audit_logs (occurred_at DESC);

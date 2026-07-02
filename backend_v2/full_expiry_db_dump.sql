--
-- PostgreSQL database dump
--

\restrict XB8OZiPTzUXGXHvheB1YAprtDDeUzLNpH8v2p0PORsF6udtNztIJMOrL26zLSGs

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_type character varying(100) NOT NULL,
    entity_type character varying(100),
    entity_id character varying(100),
    action character varying(100),
    message text,
    metadata_json jsonb,
    actor_id character varying(200),
    actor_name character varying(150),
    actor_type character varying(50),
    before_state json,
    after_state json,
    change_summary text,
    ip_address character varying(50),
    user_agent character varying(500),
    request_id character varying(100),
    occurred_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: barcode_scans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.barcode_scans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid,
    scan_session_id uuid,
    raw_barcode character varying(255) NOT NULL,
    barcode_type character varying(20),
    scan_source character varying(100),
    scan_status character varying(20) DEFAULT 'unresolved'::character varying NOT NULL,
    notes text,
    scanned_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: external_product_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_product_cache (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    query_value character varying(255) NOT NULL,
    query_type character varying(50) NOT NULL,
    external_source character varying(100) DEFAULT 'OPEN_FOOD_FACTS'::character varying NOT NULL,
    external_product_id character varying(255),
    external_source_url text,
    barcode character varying(100),
    product_name character varying(255),
    brand character varying(150),
    category character varying(150),
    description text,
    ingredients text,
    nutrition_info jsonb,
    storage_instruction text,
    image_url text,
    raw_response jsonb,
    cache_status character varying(50) DEFAULT 'ACTIVE'::character varying,
    fetched_at timestamp without time zone DEFAULT now(),
    expires_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: external_product_enrichment_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_product_enrichment_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid,
    barcode_value character varying(150) NOT NULL,
    provider character varying(100) NOT NULL,
    request_url text,
    response_status character varying(50) NOT NULL,
    response_json jsonb,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: inventory_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    barcode_scan_id uuid,
    scan_session_id uuid,
    ocr_result_id uuid,
    supplier_id uuid,
    warehouse_id uuid,
    storage_location_id uuid,
    batch_number character varying(100),
    manufacturing_date date,
    expiry_date date,
    packed_date date,
    pipeline_status character varying(30) DEFAULT 'PENDING_OCR'::character varying NOT NULL,
    status_reason text,
    intake_source character varying(50) DEFAULT 'OCR_SCAN'::character varying NOT NULL,
    intake_status character varying(50) DEFAULT 'DATA_INCOMPLETE'::character varying NOT NULL,
    operator_decision character varying(100),
    quantity integer DEFAULT 1,
    unit character varying(20),
    intake_notes text,
    notes text,
    intake_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: inventory_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_movements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    inventory_item_id uuid NOT NULL,
    from_location_id uuid,
    to_location_id uuid,
    movement_type character varying(50) NOT NULL,
    quantity integer NOT NULL,
    reason text,
    moved_by character varying(100),
    moved_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: manual_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manual_reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scan_session_id uuid,
    inventory_item_id uuid,
    ocr_result_id uuid,
    review_type character varying(50) DEFAULT 'OCR_CORRECTION'::character varying NOT NULL,
    original_mfg_date date,
    original_expiry_date date,
    corrected_mfg_date date,
    corrected_expiry_date date,
    corrected_batch_number character varying(100),
    corrected_description text,
    reviewer_id character varying(200),
    reviewer_name character varying(150),
    reviewer_role character varying(100),
    reviewer_note text,
    human_decision character varying(30),
    review_notes text,
    escalation_reason text,
    review_status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ml_predictions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ml_predictions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    inventory_item_id uuid NOT NULL,
    model_name character varying(200),
    model_version character varying(50),
    predicted_mfg_date date,
    predicted_expiry_date date,
    predicted_remaining_days integer,
    predicted_decision character varying(30),
    decision_confidence double precision,
    decision_reason text,
    raw_prediction_payload text,
    prediction_status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    failure_reason text,
    predicted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ocr_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ocr_results (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_image_id uuid NOT NULL,
    product_id uuid,
    scan_session_id uuid,
    inventory_item_id uuid,
    raw_text text,
    ocr_engine character varying(100),
    ocr_engine_version character varying(50),
    extracted_text_blocks json,
    overall_confidence double precision,
    ocr_confidence numeric(5,4),
    extracted_product_name character varying(255),
    extracted_brand character varying(150),
    extracted_description text,
    extracted_ingredients_text text,
    extracted_nutrition_text text,
    candidate_mfg_date date,
    candidate_expiry_date date,
    candidate_packed_date date,
    best_before_text character varying(255),
    batch_number_detected character varying(100),
    mrp_detected numeric(10,2),
    date_parse_confidence numeric(5,4),
    response_json jsonb,
    ocr_status character varying(30) DEFAULT 'PENDING'::character varying NOT NULL,
    failure_reason text,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: product_allergens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_allergens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    allergen_name character varying(150) NOT NULL,
    allergen_type character varying(100),
    contains boolean NOT NULL,
    may_contain boolean NOT NULL,
    source_text text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: product_identifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_identifiers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    identifier_value character varying(150) NOT NULL,
    identifier_type character varying(50) NOT NULL,
    is_primary boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    source character varying(50) DEFAULT 'LOCAL_DATABASE'::character varying
);


--
-- Name: product_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_images (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    scan_session_id uuid,
    file_path character varying(500) NOT NULL,
    file_url character varying(500),
    file_size_bytes integer,
    mime_type character varying(100),
    image_type character varying(50),
    processing_status character varying(30) DEFAULT 'uploaded'::character varying NOT NULL,
    notes text,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: product_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    ingredient_name character varying(255) NOT NULL,
    ingredient_order integer,
    percentage numeric(5,2),
    is_additive boolean NOT NULL,
    additive_code character varying(50),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: product_lookup_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_lookup_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    query_value character varying(255) NOT NULL,
    query_type character varying(50) NOT NULL,
    result_status character varying(50) NOT NULL,
    result_source character varying(100),
    product_id uuid,
    external_cache_id uuid,
    requested_by character varying(150),
    request_source character varying(100) DEFAULT 'BACKEND_API'::character varying,
    telegram_chat_id character varying(150),
    telegram_user_id character varying(150),
    n8n_execution_id character varying(150),
    response_payload jsonb,
    error_message text,
    lookup_duration_ms integer,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT chk_product_lookup_query_type CHECK (((query_type)::text = ANY ((ARRAY['PRODUCT_ID'::character varying, 'BARCODE'::character varying, 'PRODUCT_NAME'::character varying, 'UNKNOWN'::character varying])::text[]))),
    CONSTRAINT chk_product_lookup_result_source CHECK (((result_source)::text = ANY ((ARRAY['LOCAL_DATABASE'::character varying, 'OPEN_FOOD_FACTS'::character varying, 'CACHE'::character varying, 'NONE'::character varying])::text[]))),
    CONSTRAINT chk_product_lookup_result_status CHECK (((result_status)::text = ANY ((ARRAY['FOUND'::character varying, 'NOT_FOUND'::character varying, 'INVALID_QUERY'::character varying, 'EXTERNAL_API_FAILED'::character varying, 'ERROR'::character varying])::text[])))
);


--
-- Name: product_nutrition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_nutrition (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    serving_size character varying(100),
    calories numeric(10,2),
    protein_g numeric(10,2),
    carbohydrates_g numeric(10,2),
    sugar_g numeric(10,2),
    fat_g numeric(10,2),
    saturated_fat_g numeric(10,2),
    sodium_mg numeric(10,2),
    fiber_g numeric(10,2),
    raw_nutrition_text text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: product_question_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_question_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    question text NOT NULL,
    detected_intent character varying(100),
    extracted_entity character varying(255),
    result_status character varying(50),
    result_source character varying(100),
    product_id uuid,
    inventory_item_id uuid,
    request_source character varying(100) DEFAULT 'BACKEND_API'::character varying,
    requested_by character varying(150),
    telegram_chat_id character varying(150),
    telegram_user_id character varying(150),
    n8n_execution_id character varying(150),
    response_payload jsonb,
    error_message text,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT chk_product_question_result_source CHECK (((result_source)::text = ANY ((ARRAY['LOCAL_DATABASE'::character varying, 'NONE'::character varying])::text[]))),
    CONSTRAINT chk_product_question_result_status CHECK (((result_status)::text = ANY ((ARRAY['ANSWERED'::character varying, 'NOT_FOUND'::character varying, 'UNSUPPORTED_INTENT'::character varying, 'INVALID_QUESTION'::character varying, 'ERROR'::character varying])::text[])))
);


--
-- Name: product_storage_requirements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_storage_requirements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    storage_type character varying(50) NOT NULL,
    min_temperature_c numeric(5,2),
    max_temperature_c numeric(5,2),
    humidity_notes text,
    handling_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    brand character varying(255),
    manufacturer character varying(255),
    sku character varying(100) NOT NULL,
    barcode character varying(100) NOT NULL,
    barcode_type character varying(20) DEFAULT 'EAN13'::character varying NOT NULL,
    category character varying(100),
    sub_category character varying(100),
    description text,
    net_quantity character varying(100),
    unit character varying(50),
    mrp numeric(10,2),
    currency character varying(10) DEFAULT 'INR'::character varying NOT NULL,
    country_of_origin character varying(100),
    product_type character varying(100),
    default_storage_type character varying(50),
    shelf_life_label character varying(255),
    image_url character varying(500),
    product_image_url character varying(500),
    is_active boolean DEFAULT true NOT NULL,
    is_perishable boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    ingredients text,
    nutrition_info jsonb,
    storage_instruction text,
    product_source character varying(50) DEFAULT 'LOCAL_DATABASE'::character varying,
    external_source character varying(100),
    external_source_url text
);


--
-- Name: scan_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_alerts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scan_session_id uuid,
    inventory_item_id uuid,
    alert_type character varying(100) NOT NULL,
    severity character varying(50) DEFAULT 'WARNING'::character varying NOT NULL,
    field_name character varying(100),
    message text NOT NULL,
    is_resolved boolean DEFAULT false NOT NULL,
    resolved_by character varying(150),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone
);


--
-- Name: scan_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_status character varying(50) DEFAULT 'IN_PROGRESS'::character varying NOT NULL,
    operator_name character varying(150),
    device_id character varying(150),
    notes text,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: storage_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.storage_contexts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    inventory_item_id uuid NOT NULL,
    warehouse_id character varying(100),
    zone character varying(100),
    aisle character varying(50),
    shelf character varying(50),
    bin_location character varying(100),
    storage_type character varying(50),
    temperature_celsius double precision,
    humidity_percent double precision,
    notes text,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: storage_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.storage_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    warehouse_id uuid NOT NULL,
    location_code character varying(100) NOT NULL,
    zone character varying(100),
    aisle character varying(50),
    rack character varying(50),
    shelf character varying(50),
    bin character varying(50),
    storage_type character varying(50),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    contact_name character varying(150),
    phone character varying(50),
    email character varying(255),
    address text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: unknown_product_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unknown_product_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    query_value character varying(255) NOT NULL,
    query_type character varying(50) NOT NULL,
    barcode character varying(100),
    product_name character varying(255),
    request_source character varying(100) DEFAULT 'BACKEND_API'::character varying,
    requested_by character varying(150),
    telegram_chat_id character varying(150),
    telegram_user_id character varying(150),
    n8n_execution_id character varying(150),
    status character varying(50) DEFAULT 'PENDING'::character varying,
    admin_notes text,
    resolved_product_id uuid,
    created_at timestamp without time zone DEFAULT now(),
    resolved_at timestamp without time zone,
    CONSTRAINT chk_unknown_product_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'CREATED'::character varying, 'IGNORED'::character varying, 'DUPLICATE'::character varying, 'RESOLVED'::character varying])::text[])))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    name character varying(255),
    hashed_password text NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: warehouses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(100),
    address text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, event_type, entity_type, entity_id, action, message, metadata_json, actor_id, actor_name, actor_type, before_state, after_state, change_summary, ip_address, user_agent, request_id, occurred_at) FROM stdin;
\.


--
-- Data for Name: barcode_scans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.barcode_scans (id, product_id, scan_session_id, raw_barcode, barcode_type, scan_source, scan_status, notes, scanned_at, created_at) FROM stdin;
\.


--
-- Data for Name: external_product_cache; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.external_product_cache (id, query_value, query_type, external_source, external_product_id, external_source_url, barcode, product_name, brand, category, description, ingredients, nutrition_info, storage_instruction, image_url, raw_response, cache_status, fetched_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: external_product_enrichment_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.external_product_enrichment_logs (id, product_id, barcode_value, provider, request_url, response_status, response_json, error_message, created_at) FROM stdin;
\.


--
-- Data for Name: inventory_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inventory_items (id, product_id, barcode_scan_id, scan_session_id, ocr_result_id, supplier_id, warehouse_id, storage_location_id, batch_number, manufacturing_date, expiry_date, packed_date, pipeline_status, status_reason, intake_source, intake_status, operator_decision, quantity, unit, intake_notes, notes, intake_at, created_at, updated_at) FROM stdin;
1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	\N	\N	\N	\N	\N	BATCH102	2026-06-01	2026-12-01	\N	READY_FOR_STOCKING	\N	MANUAL	READY_FOR_STOCKING	\N	10	pieces	\N	\N	2026-07-02 04:43:46.649746+00	2026-07-02 04:43:46.649746+00	2026-07-02 04:43:46.649746+00
\.


--
-- Data for Name: inventory_movements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inventory_movements (id, inventory_item_id, from_location_id, to_location_id, movement_type, quantity, reason, moved_by, moved_at) FROM stdin;
\.


--
-- Data for Name: manual_reviews; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.manual_reviews (id, scan_session_id, inventory_item_id, ocr_result_id, review_type, original_mfg_date, original_expiry_date, corrected_mfg_date, corrected_expiry_date, corrected_batch_number, corrected_description, reviewer_id, reviewer_name, reviewer_role, reviewer_note, human_decision, review_notes, escalation_reason, review_status, reviewed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ml_predictions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ml_predictions (id, inventory_item_id, model_name, model_version, predicted_mfg_date, predicted_expiry_date, predicted_remaining_days, predicted_decision, decision_confidence, decision_reason, raw_prediction_payload, prediction_status, failure_reason, predicted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ocr_results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ocr_results (id, product_image_id, product_id, scan_session_id, inventory_item_id, raw_text, ocr_engine, ocr_engine_version, extracted_text_blocks, overall_confidence, ocr_confidence, extracted_product_name, extracted_brand, extracted_description, extracted_ingredients_text, extracted_nutrition_text, candidate_mfg_date, candidate_expiry_date, candidate_packed_date, best_before_text, batch_number_detected, mrp_detected, date_parse_confidence, response_json, ocr_status, failure_reason, processed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: product_allergens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_allergens (id, product_id, allergen_name, allergen_type, contains, may_contain, source_text, created_at) FROM stdin;
\.


--
-- Data for Name: product_identifiers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_identifiers (id, product_id, identifier_value, identifier_type, is_primary, created_at, source) FROM stdin;
437b6e0c-b1bc-49ba-a2cb-4eb3e69613ab	a35bf76e-a8e5-4fe1-ba21-0c568817157d	8901262010011	EAN_13	t	2026-07-02 03:56:29.666604+00	LOCAL_DATABASE
\.


--
-- Data for Name: product_images; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_images (id, product_id, scan_session_id, file_path, file_url, file_size_bytes, mime_type, image_type, processing_status, notes, uploaded_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: product_ingredients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_ingredients (id, product_id, ingredient_name, ingredient_order, percentage, is_additive, additive_code, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: product_lookup_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_lookup_logs (id, query_value, query_type, result_status, result_source, product_id, external_cache_id, requested_by, request_source, telegram_chat_id, telegram_user_id, n8n_execution_id, response_payload, error_message, lookup_duration_ms, created_at) FROM stdin;
8a9511d4-61af-45c6-bc1a-67633ff910ae	8901262010011	BARCODE	FOUND	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	\N	BACKEND_API	\N	\N	\N	{"source": "LOCAL_DATABASE", "status": "FOUND", "product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}, "search_type": "BARCODE", "result_count": 1}	\N	61	2026-07-02 04:21:58.696289
86543522-06c8-42d8-b7ac-1b8205f585db	8901262010011	BARCODE	FOUND	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	codex-test	BACKEND_API	\N	\N	\N	{"source": "LOCAL_DATABASE", "status": "FOUND", "product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}, "search_type": "BARCODE", "result_count": 1}	\N	7	2026-07-02 04:31:02.693906
b9031e9c-b490-4b23-bb8f-112dc0e0adbf	Amul	PRODUCT_NAME	FOUND	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	codex-test	BACKEND_API	\N	\N	\N	{"source": "LOCAL_DATABASE", "status": "FOUND", "product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}, "search_type": "PRODUCT_NAME", "result_count": 1}	\N	7	2026-07-02 04:31:02.714027
f085f585-7d88-4dd3-ab69-39ec39396148	AMUL-TAAZA-500ML	PRODUCT_NAME	FOUND	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	codex-test	BACKEND_API	\N	\N	\N	{"source": "LOCAL_DATABASE", "status": "FOUND", "product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}, "search_type": "SKU", "result_count": 1}	\N	3	2026-07-02 04:31:02.725711
fae8b399-9a91-4ea2-a29c-4fdf28a0b74b	a35bf76e-a8e5-4fe1-ba21-0c568817157d	PRODUCT_ID	FOUND	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	codex-test	BACKEND_API	\N	\N	\N	{"source": "LOCAL_DATABASE", "status": "FOUND", "product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}, "search_type": "PRODUCT_ID", "result_count": 1}	\N	3	2026-07-02 04:31:02.733729
0f71716f-ff53-49fd-addb-8b377e87d5d1	8909999999999	BARCODE	NOT_FOUND	NONE	\N	\N	codex-test	BACKEND_API	\N	\N	\N	{"query": "8909999999999", "source": "NONE", "status": "NOT_FOUND", "message": "Product was not found in the local database or external cache.", "search_type": "BARCODE", "result_count": 0, "suggested_action": "Create a new product master record."}	\N	16	2026-07-02 04:31:02.759278
26c72951-3f04-4ded-8c98-9bba603b9aa5		UNKNOWN	INVALID_QUERY	NONE	\N	\N	codex-test	BACKEND_API	\N	\N	\N	{"query": "", "source": "NONE", "status": "INVALID_QUERY", "message": "Query cannot be empty.", "search_type": "UNKNOWN", "result_count": 0}	\N	0	2026-07-02 04:31:02.766314
21853d85-932b-4566-bdf5-173ef084a93d	8901262010011	BARCODE	FOUND	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	http-test	BACKEND_API	\N	\N	\N	{"source": "LOCAL_DATABASE", "status": "FOUND", "product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}, "search_type": "BARCODE", "result_count": 1}	\N	11	2026-07-02 04:34:28.505307
c62416fb-0178-415d-9570-f6016547f534	Amul	PRODUCT_NAME	FOUND	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	http-test	BACKEND_API	\N	\N	\N	{"source": "LOCAL_DATABASE", "status": "FOUND", "product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}, "search_type": "PRODUCT_NAME", "result_count": 1}	\N	5	2026-07-02 04:34:28.525314
7f618777-6e5c-4227-8f45-008cfbb0fcf2	AMUL-TAAZA-500ML	PRODUCT_NAME	FOUND	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	http-test	BACKEND_API	\N	\N	\N	{"source": "LOCAL_DATABASE", "status": "FOUND", "product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}, "search_type": "SKU", "result_count": 1}	\N	4	2026-07-02 04:34:28.547716
9689cce8-363e-4d65-8bc3-4c41c926a63f	a35bf76e-a8e5-4fe1-ba21-0c568817157d	PRODUCT_ID	FOUND	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	http-test	BACKEND_API	\N	\N	\N	{"source": "LOCAL_DATABASE", "status": "FOUND", "product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}, "search_type": "PRODUCT_ID", "result_count": 1}	\N	4	2026-07-02 04:34:28.558318
22ea4d5a-d7cf-48ee-80ed-b7210186acb6	8909999999999	BARCODE	NOT_FOUND	NONE	\N	\N	http-test	BACKEND_API	\N	\N	\N	{"query": "8909999999999", "source": "NONE", "status": "NOT_FOUND", "message": "Product was not found in the local database or external cache.", "search_type": "BARCODE", "result_count": 0, "suggested_action": "Create a new product master record."}	\N	9	2026-07-02 04:34:28.567551
78eb1e55-b8cd-459c-ae14-2f22acd49f7a		UNKNOWN	INVALID_QUERY	NONE	\N	\N	http-test	BACKEND_API	\N	\N	\N	{"query": "", "source": "NONE", "status": "INVALID_QUERY", "message": "Query cannot be empty.", "search_type": "UNKNOWN", "result_count": 0}	\N	0	2026-07-02 04:34:28.58285
\.


--
-- Data for Name: product_nutrition; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_nutrition (id, product_id, serving_size, calories, protein_g, carbohydrates_g, sugar_g, fat_g, saturated_fat_g, sodium_mg, fiber_g, raw_nutrition_text, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: product_question_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_question_logs (id, question, detected_intent, extracted_entity, result_status, result_source, product_id, inventory_item_id, request_source, requested_by, telegram_chat_id, telegram_user_id, n8n_execution_id, response_payload, error_message, created_at) FROM stdin;
c69a8ee0-2e56-4672-8bd5-4566e069ab41	Show product details of Amul Milk	PRODUCT_DETAILS	Amul Milk	NOT_FOUND	NONE	\N	\N	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {"entity": "Amul Milk"}, "answer": "I could not find a matching product for 'Amul Milk'.", "intent": "PRODUCT_DETAILS", "status": "NOT_FOUND", "answer_type": "PRODUCT_DETAILS"}	\N	2026-07-02 04:44:00.073444
b2a493f4-7ccd-4a29-9499-287c8e48d2d9	What is the expiry date of Amul Milk?	EXPIRY_DATE	Amul Milk	NOT_FOUND	NONE	\N	\N	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {"entity": "Amul Milk"}, "answer": "I could not find a matching product for 'Amul Milk'.", "intent": "EXPIRY_DATE", "status": "NOT_FOUND", "answer_type": "EXPIRY_DATE"}	\N	2026-07-02 04:44:00.087308
2899722f-ee15-41f4-acac-23f1a730fa66	What is the manufacturing date of 8901262010011?	MFG_DATE	8901262010011	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {"batch_number": "BATCH102", "product_name": "Amul Taaza Toned Milk 500ml", "pipeline_status": "READY_FOR_STOCKING", "manufacturing_date": "2026-06-01"}, "answer": "The latest manufacturing date for Amul Taaza Toned Milk 500ml is 2026-06-01.", "intent": "MFG_DATE", "status": "ANSWERED", "answer_type": "MFG_DATE"}	\N	2026-07-02 04:44:00.095515
7ba5072a-5bff-4687-9cd3-73bcb87c4f78	What is the batch number of Amul Milk?	BATCH_NUMBER	Amul Milk	NOT_FOUND	NONE	\N	\N	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {"entity": "Amul Milk"}, "answer": "I could not find a matching product for 'Amul Milk'.", "intent": "BATCH_NUMBER", "status": "NOT_FOUND", "answer_type": "BATCH_NUMBER"}	\N	2026-07-02 04:44:00.111737
9446bab0-33c4-4603-913b-3b3169038087	Show ingredients of Amul Milk	INGREDIENTS	Amul Milk	NOT_FOUND	NONE	\N	\N	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {"entity": "Amul Milk"}, "answer": "I could not find a matching product for 'Amul Milk'.", "intent": "INGREDIENTS", "status": "NOT_FOUND", "answer_type": "INGREDIENTS"}	\N	2026-07-02 04:44:00.11806
9297316e-2034-4456-a486-4305b069e17a	Show nutrition details of Amul Milk	NUTRITION	Amul Milk	NOT_FOUND	NONE	\N	\N	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {"entity": "Amul Milk"}, "answer": "I could not find a matching product for 'Amul Milk'.", "intent": "NUTRITION", "status": "NOT_FOUND", "answer_type": "NUTRITION"}	\N	2026-07-02 04:44:00.125308
d249304d-a18d-495b-90f4-11e331a234c9	How should I store Amul Milk?	STORAGE_INSTRUCTION	Amul Milk	NOT_FOUND	NONE	\N	\N	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {"entity": "Amul Milk"}, "answer": "I could not find a matching product for 'Amul Milk'.", "intent": "STORAGE_INSTRUCTION", "status": "NOT_FOUND", "answer_type": "STORAGE_INSTRUCTION"}	\N	2026-07-02 04:44:00.131437
08859b44-6ea0-473a-96a1-a476e898683c	Is Amul Milk expired?	PRODUCT_STATUS	Amul Milk	NOT_FOUND	NONE	\N	\N	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {"entity": "Amul Milk"}, "answer": "I could not find a matching product for 'Amul Milk'.", "intent": "PRODUCT_STATUS", "status": "NOT_FOUND", "answer_type": "PRODUCT_STATUS"}	\N	2026-07-02 04:44:00.138563
74881ad7-c8cb-40d6-9589-6ff9d0b75491	Who created this product?	UNKNOWN	Who created	UNSUPPORTED_INTENT	NONE	\N	\N	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {"supported_questions": ["What is the expiry date of Amul Milk?", "Show ingredients of 8901262010011", "What is the batch number of Amul Milk?", "How should I store Amul Milk?", "Is Amul Milk expired?"]}, "answer": "I can answer product details, expiry date, manufacturing date, batch number, ingredients, nutrition, storage instruction, and product status questions.", "intent": "UNKNOWN", "status": "UNSUPPORTED_INTENT", "answer_type": "UNKNOWN"}	\N	2026-07-02 04:44:00.146013
ed24c1a4-e9be-44ec-8f87-3983aa2f581c		UNKNOWN	\N	INVALID_QUESTION	NONE	\N	\N	BACKEND_API	codex-step2-service-test	\N	\N	\N	{"data": {}, "answer": "Question cannot be empty.", "intent": "UNKNOWN", "status": "INVALID_QUESTION", "answer_type": "UNKNOWN"}	\N	2026-07-02 04:44:00.153442
889b6c17-9c02-4d87-8e5a-b364a846e208	Show product details of Amul Milk	PRODUCT_DETAILS	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {"product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}}, "answer": "Product details found for Amul Taaza Toned Milk 500ml.", "intent": "PRODUCT_DETAILS", "status": "ANSWERED", "answer_type": "PRODUCT_DETAILS"}	\N	2026-07-02 04:44:33.656492
a3ad65d5-9509-4dc4-ab34-1f2353c92a8e	What is the expiry date of Amul Milk?	EXPIRY_DATE	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {"barcode": "8901262010011", "expiry_date": "2026-12-01", "batch_number": "BATCH102", "product_name": "Amul Taaza Toned Milk 500ml", "pipeline_status": "READY_FOR_STOCKING"}, "answer": "The latest expiry date for Amul Taaza Toned Milk 500ml is 2026-12-01.", "intent": "EXPIRY_DATE", "status": "ANSWERED", "answer_type": "EXPIRY_DATE"}	\N	2026-07-02 04:44:33.67175
0ee6355f-9eb8-4406-a380-ae6f42977541	What is the manufacturing date of 8901262010011?	MFG_DATE	8901262010011	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {"batch_number": "BATCH102", "product_name": "Amul Taaza Toned Milk 500ml", "pipeline_status": "READY_FOR_STOCKING", "manufacturing_date": "2026-06-01"}, "answer": "The latest manufacturing date for Amul Taaza Toned Milk 500ml is 2026-06-01.", "intent": "MFG_DATE", "status": "ANSWERED", "answer_type": "MFG_DATE"}	\N	2026-07-02 04:44:33.683713
2316e708-b53e-416e-95f4-100f489a778a	What is the batch number of Amul Milk?	BATCH_NUMBER	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {"expiry_date": "2026-12-01", "batch_number": "BATCH102", "product_name": "Amul Taaza Toned Milk 500ml", "manufacturing_date": "2026-06-01"}, "answer": "The latest batch number for Amul Taaza Toned Milk 500ml is BATCH102.", "intent": "BATCH_NUMBER", "status": "ANSWERED", "answer_type": "BATCH_NUMBER"}	\N	2026-07-02 04:44:33.697447
ab42b301-2778-4c27-8424-3faa50db4146	Show ingredients of Amul Milk	INGREDIENTS	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {"ingredients": "Toned milk", "product_name": "Amul Taaza Toned Milk 500ml"}, "answer": "Ingredients for Amul Taaza Toned Milk 500ml: Toned milk.", "intent": "INGREDIENTS", "status": "ANSWERED", "answer_type": "INGREDIENTS"}	\N	2026-07-02 04:44:33.708203
3d610bf9-a735-4c36-bc39-826e32b85f67	Show nutrition details of Amul Milk	NUTRITION	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {"product_name": "Amul Taaza Toned Milk 500ml", "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}}, "answer": "Nutrition information found for Amul Taaza Toned Milk 500ml.", "intent": "NUTRITION", "status": "ANSWERED", "answer_type": "NUTRITION"}	\N	2026-07-02 04:44:33.716841
58f88b49-6bf8-469f-aaae-a8bd33f0ed85	How should I store Amul Milk?	STORAGE_INSTRUCTION	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {"product_name": "Amul Taaza Toned Milk 500ml", "storage_instruction": "Keep refrigerated"}, "answer": "Storage instruction for Amul Taaza Toned Milk 500ml: Keep refrigerated.", "intent": "STORAGE_INSTRUCTION", "status": "ANSWERED", "answer_type": "STORAGE_INSTRUCTION"}	\N	2026-07-02 04:44:33.724846
5438d247-4296-48ee-a025-ba0a17b2c0e5	Is Amul Milk expired?	PRODUCT_STATUS	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {"status": "NOT_EXPIRED", "expiry_date": "2026-12-01", "batch_number": "BATCH102", "product_name": "Amul Taaza Toned Milk 500ml", "pipeline_status": "READY_FOR_STOCKING"}, "answer": "Amul Taaza Toned Milk 500ml is not expired. Latest expiry date is 2026-12-01.", "intent": "PRODUCT_STATUS", "status": "ANSWERED", "answer_type": "PRODUCT_STATUS"}	\N	2026-07-02 04:44:33.734451
9aabe1bc-f128-435e-a957-475e3284ba36	Who created this product?	UNKNOWN	Who created	UNSUPPORTED_INTENT	NONE	\N	\N	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {"supported_questions": ["What is the expiry date of Amul Milk?", "Show ingredients of 8901262010011", "What is the batch number of Amul Milk?", "How should I store Amul Milk?", "Is Amul Milk expired?"]}, "answer": "I can answer product details, expiry date, manufacturing date, batch number, ingredients, nutrition, storage instruction, and product status questions.", "intent": "UNKNOWN", "status": "UNSUPPORTED_INTENT", "answer_type": "UNKNOWN"}	\N	2026-07-02 04:44:33.74489
898e5ca0-b4bc-4908-b349-60a8fc569689		UNKNOWN	\N	INVALID_QUESTION	NONE	\N	\N	BACKEND_API	codex-step2-service-test-2	\N	\N	\N	{"data": {}, "answer": "Question cannot be empty.", "intent": "UNKNOWN", "status": "INVALID_QUESTION", "answer_type": "UNKNOWN"}	\N	2026-07-02 04:44:33.750838
489b3f1e-b539-463b-8454-b0af28c5a7de	Show product details of Amul Milk	PRODUCT_DETAILS	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	BACKEND_API	codex-step2-http-test	\N	\N	\N	{"data": {"product": {"id": "a35bf76e-a8e5-4fe1-ba21-0c568817157d", "sku": "AMUL-TAAZA-500ML", "name": "Amul Taaza Toned Milk 500ml", "brand": "Amul", "barcode": "8901262010011", "category": "Dairy", "image_url": null, "description": "Toned milk product", "ingredients": "Toned milk", "barcode_type": "EAN_13", "manufacturer": "Amul", "sub_category": null, "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}, "product_source": "LOCAL_DATABASE", "country_of_origin": "India", "storage_instruction": "Keep refrigerated"}}, "answer": "Product details found for Amul Taaza Toned Milk 500ml.", "intent": "PRODUCT_DETAILS", "status": "ANSWERED", "answer_type": "PRODUCT_DETAILS"}	\N	2026-07-02 04:44:51.29444
35e68995-ff94-4ed0-acd3-2f503f4bfd27	What is the expiry date of Amul Milk?	EXPIRY_DATE	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	BACKEND_API	codex-step2-http-test	\N	\N	\N	{"data": {"barcode": "8901262010011", "expiry_date": "2026-12-01", "batch_number": "BATCH102", "product_name": "Amul Taaza Toned Milk 500ml", "pipeline_status": "READY_FOR_STOCKING"}, "answer": "The latest expiry date for Amul Taaza Toned Milk 500ml is 2026-12-01.", "intent": "EXPIRY_DATE", "status": "ANSWERED", "answer_type": "EXPIRY_DATE"}	\N	2026-07-02 04:44:51.314874
717fadfb-b6f0-4d57-bc2f-ed2b988b32c4	What is the manufacturing date of 8901262010011?	MFG_DATE	8901262010011	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	BACKEND_API	codex-step2-http-test	\N	\N	\N	{"data": {"batch_number": "BATCH102", "product_name": "Amul Taaza Toned Milk 500ml", "pipeline_status": "READY_FOR_STOCKING", "manufacturing_date": "2026-06-01"}, "answer": "The latest manufacturing date for Amul Taaza Toned Milk 500ml is 2026-06-01.", "intent": "MFG_DATE", "status": "ANSWERED", "answer_type": "MFG_DATE"}	\N	2026-07-02 04:44:51.328902
a778fb65-1c6a-4f8b-9c45-df1c21e0abab	What is the batch number of Amul Milk?	BATCH_NUMBER	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	BACKEND_API	codex-step2-http-test	\N	\N	\N	{"data": {"expiry_date": "2026-12-01", "batch_number": "BATCH102", "product_name": "Amul Taaza Toned Milk 500ml", "manufacturing_date": "2026-06-01"}, "answer": "The latest batch number for Amul Taaza Toned Milk 500ml is BATCH102.", "intent": "BATCH_NUMBER", "status": "ANSWERED", "answer_type": "BATCH_NUMBER"}	\N	2026-07-02 04:44:51.344715
c725eb3c-600f-4972-8705-2a0a6aead9d5	Show ingredients of Amul Milk	INGREDIENTS	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	BACKEND_API	codex-step2-http-test	\N	\N	\N	{"data": {"ingredients": "Toned milk", "product_name": "Amul Taaza Toned Milk 500ml"}, "answer": "Ingredients for Amul Taaza Toned Milk 500ml: Toned milk.", "intent": "INGREDIENTS", "status": "ANSWERED", "answer_type": "INGREDIENTS"}	\N	2026-07-02 04:44:51.356612
5e9cd428-cffa-414c-b4f8-e89ae3fb04fe	Show nutrition details of Amul Milk	NUTRITION	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	BACKEND_API	codex-step2-http-test	\N	\N	\N	{"data": {"product_name": "Amul Taaza Toned Milk 500ml", "nutrition_info": {"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}}, "answer": "Nutrition information found for Amul Taaza Toned Milk 500ml.", "intent": "NUTRITION", "status": "ANSWERED", "answer_type": "NUTRITION"}	\N	2026-07-02 04:44:51.376966
73bf878a-9718-4e13-afd9-35b69049242c	How should I store Amul Milk?	STORAGE_INSTRUCTION	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	\N	BACKEND_API	codex-step2-http-test	\N	\N	\N	{"data": {"product_name": "Amul Taaza Toned Milk 500ml", "storage_instruction": "Keep refrigerated"}, "answer": "Storage instruction for Amul Taaza Toned Milk 500ml: Keep refrigerated.", "intent": "STORAGE_INSTRUCTION", "status": "ANSWERED", "answer_type": "STORAGE_INSTRUCTION"}	\N	2026-07-02 04:44:51.389219
28a5d4ae-972a-461a-af8b-0ca6432951c4	Is Amul Milk expired?	PRODUCT_STATUS	Amul Milk	ANSWERED	LOCAL_DATABASE	a35bf76e-a8e5-4fe1-ba21-0c568817157d	1c50f8a7-9dac-42c1-96fe-ea7ef61c1e69	BACKEND_API	codex-step2-http-test	\N	\N	\N	{"data": {"status": "NOT_EXPIRED", "expiry_date": "2026-12-01", "batch_number": "BATCH102", "product_name": "Amul Taaza Toned Milk 500ml", "pipeline_status": "READY_FOR_STOCKING"}, "answer": "Amul Taaza Toned Milk 500ml is not expired. Latest expiry date is 2026-12-01.", "intent": "PRODUCT_STATUS", "status": "ANSWERED", "answer_type": "PRODUCT_STATUS"}	\N	2026-07-02 04:44:51.422939
6a75e5ba-f1a0-482e-84a4-e61c727d8074	Who created this product?	UNKNOWN	Who created	UNSUPPORTED_INTENT	NONE	\N	\N	BACKEND_API	codex-step2-http-test	\N	\N	\N	{"data": {"supported_questions": ["What is the expiry date of Amul Milk?", "Show ingredients of 8901262010011", "What is the batch number of Amul Milk?", "How should I store Amul Milk?", "Is Amul Milk expired?"]}, "answer": "I can answer product details, expiry date, manufacturing date, batch number, ingredients, nutrition, storage instruction, and product status questions.", "intent": "UNKNOWN", "status": "UNSUPPORTED_INTENT", "answer_type": "UNKNOWN"}	\N	2026-07-02 04:44:51.435289
\.


--
-- Data for Name: product_storage_requirements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_storage_requirements (id, product_id, storage_type, min_temperature_c, max_temperature_c, humidity_notes, handling_notes, created_at) FROM stdin;
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.products (id, name, brand, manufacturer, sku, barcode, barcode_type, category, sub_category, description, net_quantity, unit, mrp, currency, country_of_origin, product_type, default_storage_type, shelf_life_label, image_url, product_image_url, is_active, is_perishable, created_at, updated_at, ingredients, nutrition_info, storage_instruction, product_source, external_source, external_source_url) FROM stdin;
10255b84-1c00-455b-8b83-ab0415ec4448	MTR Rava Idli Mix 500g	MTR	\N	MTR-RAVA-IDLI-500G	8901042953256	EAN13	Packaged Foods	\N	Ready to cook Rava Idli mix, a popular South Indian breakfast.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
e06d5082-137a-4d29-bc50-a1d5aa45d51f	Sakthi Sambar Powder 200g	Sakthi Masala	\N	SAKTHI-SAMBAR-200G	8906001020345	EAN13	Spices	\N	Authentic South Indian Sambar powder mix.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
63d44a18-ecb8-4009-b53e-7a51335047b9	GRB Udhayam Ghee 500ml	GRB	\N	GRB-GHEE-500ML	8906008850020	EAN13	Dairy	\N	Pure cow ghee, traditionally made in South India.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
bb6cb811-82ee-4779-9026-dd1eeeede5e4	Milky Mist Paneer 200g	Milky Mist	\N	MILKY-PANEER-200G	8904083300057	EAN13	Dairy	\N	Fresh malai paneer cubes, 200g vacuum packed.	\N	\N	\N	INR	\N	\N	refrigerated	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
526cdbfa-b588-4afc-829b-acb7125925d6	Heritage Toned Milk 500ml	Heritage	\N	HERITAGE-MILK-500ML	8901234567890	EAN13	Dairy	\N	Pasteurised toned milk, popular in AP and Telangana.	\N	\N	\N	INR	\N	\N	refrigerated	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
cba44b64-d2b6-47a8-b22c-2d96281c2956	Aashirvaad Select Atta 5kg	Aashirvaad	\N	AASH-ATTA-5KG	8901725134185	EAN13	Packaged Foods	\N	100% MP Sharbati wheat atta, premium quality.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
8df944c1-f2f2-4293-b562-0fb2856cfdd9	Bru Green Label Filter Coffee 500g	Bru	\N	BRU-FILTER-500G	8901030018516	EAN13	Beverages	\N	Traditional filter coffee powder with chicory blend.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
85f4d75f-badb-4300-bbb6-fd41f8805f40	Parachute Pure Coconut Oil 250ml	Parachute	\N	PARA-COCONUT-250ML	8901088015036	EAN13	Personal Care	\N	100% pure unrefined coconut oil, popular in Kerala.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
f6963f39-65cc-482a-842b-0b76f64c3674	Narasu's Udhayam Filter Coffee 250g	Narasu's	\N	NARASU-COFFEE-250G	8904000100159	EAN13	Beverages	\N	Classic South Indian filter coffee blend.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
0db027cb-c135-440a-8621-13fb8f6e0b09	Aachi Chicken Masala 200g	Aachi	\N	AACHI-CHICKEN-200G	8906020580327	EAN13	Spices	\N	Authentic Chettinad style chicken masala.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
76f4dc83-7043-4dca-90fd-0a1cafc7a9a3	Idhayam Sesame Oil 1L	Idhayam	\N	IDHAYAM-SESAME-1L	8901243100021	EAN13	Cooking Oil	\N	Traditional gingelly (sesame) oil, extensively used in South Indian cooking.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
3950640f-6109-4829-80be-a56bbfeadcae	Lion Dates 500g	Lion	\N	LION-DATES-500G	8906001080011	EAN13	Dry Fruits	\N	High-quality seedless dates.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
f2db829a-c9c6-4088-8986-e944f66a8cbe	Anil Vermicelli (Semiya) 200g	Anil	\N	ANIL-SEMIYA-200G	8904123400561	EAN13	Packaged Foods	\N	Roasted semiya for Payasam and Upma.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
2184e973-26a0-48b5-8932-e02110cbd310	Hatsun Curd 500g	Hatsun	\N	HATSUN-CURD-500G	8906005541129	EAN13	Dairy	\N	Thick and tasty set curd.	\N	\N	\N	INR	\N	\N	refrigerated	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
18a9144d-f4f0-4653-ba2c-3b0f292d1a3f	3 Roses Tea 500g	Brooke Bond	\N	3ROSES-TEA-500G	8901030383744	EAN13	Beverages	\N	Strong tea dust blend favoured in Tamil Nadu.	\N	\N	\N	INR	\N	\N	ambient	\N	\N	\N	t	f	2026-07-01 17:31:46.70837+00	2026-07-01 17:31:46.70837+00	\N	\N	\N	LOCAL_DATABASE	\N	\N
a35bf76e-a8e5-4fe1-ba21-0c568817157d	Amul Taaza Toned Milk 500ml	Amul	Amul	AMUL-TAAZA-500ML	8901262010011	EAN_13	Dairy	\N	Toned milk product	\N	\N	\N	INR	India	\N	\N	\N	\N	\N	t	f	2026-07-02 03:56:29.64448+00	2026-07-02 03:56:29.64448+00	Toned milk	{"fat": "3g", "energy": "58 kcal", "protein": "3.1g"}	Keep refrigerated	LOCAL_DATABASE	\N	\N
\.


--
-- Data for Name: scan_alerts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scan_alerts (id, scan_session_id, inventory_item_id, alert_type, severity, field_name, message, is_resolved, resolved_by, created_at, resolved_at) FROM stdin;
\.


--
-- Data for Name: scan_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scan_sessions (id, session_status, operator_name, device_id, notes, started_at, completed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: storage_contexts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.storage_contexts (id, inventory_item_id, warehouse_id, zone, aisle, shelf, bin_location, storage_type, temperature_celsius, humidity_percent, notes, recorded_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: storage_locations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.storage_locations (id, warehouse_id, location_code, zone, aisle, rack, shelf, bin, storage_type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.suppliers (id, name, contact_name, phone, email, address, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: unknown_product_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.unknown_product_requests (id, query_value, query_type, barcode, product_name, request_source, requested_by, telegram_chat_id, telegram_user_id, n8n_execution_id, status, admin_notes, resolved_product_id, created_at, resolved_at) FROM stdin;
d02498b8-e53c-4dd7-abf9-2c884879f0fa	8909999999999	BARCODE	8909999999999	\N	BACKEND_API	codex-test	\N	\N	\N	PENDING	\N	\N	2026-07-02 04:31:02.742978	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, email, name, hashed_password, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: warehouses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.warehouses (id, name, code, address, created_at, updated_at) FROM stdin;
\.


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: barcode_scans barcode_scans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.barcode_scans
    ADD CONSTRAINT barcode_scans_pkey PRIMARY KEY (id);


--
-- Name: external_product_cache external_product_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_product_cache
    ADD CONSTRAINT external_product_cache_pkey PRIMARY KEY (id);


--
-- Name: external_product_enrichment_logs external_product_enrichment_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_product_enrichment_logs
    ADD CONSTRAINT external_product_enrichment_logs_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: inventory_movements inventory_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT inventory_movements_pkey PRIMARY KEY (id);


--
-- Name: manual_reviews manual_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_reviews
    ADD CONSTRAINT manual_reviews_pkey PRIMARY KEY (id);


--
-- Name: ml_predictions ml_predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_predictions
    ADD CONSTRAINT ml_predictions_pkey PRIMARY KEY (id);


--
-- Name: ocr_results ocr_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_results
    ADD CONSTRAINT ocr_results_pkey PRIMARY KEY (id);


--
-- Name: product_allergens product_allergens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_allergens
    ADD CONSTRAINT product_allergens_pkey PRIMARY KEY (id);


--
-- Name: product_identifiers product_identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_identifiers
    ADD CONSTRAINT product_identifiers_pkey PRIMARY KEY (id);


--
-- Name: product_images product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_pkey PRIMARY KEY (id);


--
-- Name: product_ingredients product_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_pkey PRIMARY KEY (id);


--
-- Name: product_lookup_logs product_lookup_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_lookup_logs
    ADD CONSTRAINT product_lookup_logs_pkey PRIMARY KEY (id);


--
-- Name: product_nutrition product_nutrition_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nutrition
    ADD CONSTRAINT product_nutrition_pkey PRIMARY KEY (id);


--
-- Name: product_question_logs product_question_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_question_logs
    ADD CONSTRAINT product_question_logs_pkey PRIMARY KEY (id);


--
-- Name: product_storage_requirements product_storage_requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_storage_requirements
    ADD CONSTRAINT product_storage_requirements_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: scan_alerts scan_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_alerts
    ADD CONSTRAINT scan_alerts_pkey PRIMARY KEY (id);


--
-- Name: scan_sessions scan_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_sessions
    ADD CONSTRAINT scan_sessions_pkey PRIMARY KEY (id);


--
-- Name: storage_contexts storage_contexts_inventory_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storage_contexts
    ADD CONSTRAINT storage_contexts_inventory_item_id_key UNIQUE (inventory_item_id);


--
-- Name: storage_contexts storage_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storage_contexts
    ADD CONSTRAINT storage_contexts_pkey PRIMARY KEY (id);


--
-- Name: storage_locations storage_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storage_locations
    ADD CONSTRAINT storage_locations_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: unknown_product_requests unknown_product_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unknown_product_requests
    ADD CONSTRAINT unknown_product_requests_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: warehouses warehouses_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_code_key UNIQUE (code);


--
-- Name: warehouses warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (id);


--
-- Name: idx_external_product_cache_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_product_cache_barcode ON public.external_product_cache USING btree (barcode);


--
-- Name: idx_external_product_cache_product_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_product_cache_product_name ON public.external_product_cache USING btree (product_name);


--
-- Name: idx_external_product_cache_query; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_product_cache_query ON public.external_product_cache USING btree (query_type, query_value);


--
-- Name: idx_external_product_cache_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_product_cache_source ON public.external_product_cache USING btree (external_source);


--
-- Name: idx_product_identifiers_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_identifiers_product_id ON public.product_identifiers USING btree (product_id);


--
-- Name: idx_product_identifiers_unique_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_product_identifiers_unique_value ON public.product_identifiers USING btree (identifier_type, identifier_value);


--
-- Name: idx_product_identifiers_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_identifiers_value ON public.product_identifiers USING btree (identifier_value);


--
-- Name: idx_product_lookup_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_lookup_logs_created_at ON public.product_lookup_logs USING btree (created_at);


--
-- Name: idx_product_lookup_logs_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_lookup_logs_product_id ON public.product_lookup_logs USING btree (product_id);


--
-- Name: idx_product_lookup_logs_query; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_lookup_logs_query ON public.product_lookup_logs USING btree (query_type, query_value);


--
-- Name: idx_product_lookup_logs_result_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_lookup_logs_result_status ON public.product_lookup_logs USING btree (result_status);


--
-- Name: idx_product_question_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_question_logs_created_at ON public.product_question_logs USING btree (created_at);


--
-- Name: idx_product_question_logs_intent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_question_logs_intent ON public.product_question_logs USING btree (detected_intent);


--
-- Name: idx_product_question_logs_inventory_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_question_logs_inventory_item_id ON public.product_question_logs USING btree (inventory_item_id);


--
-- Name: idx_product_question_logs_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_question_logs_product_id ON public.product_question_logs USING btree (product_id);


--
-- Name: idx_products_brand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_brand ON public.products USING btree (brand);


--
-- Name: idx_products_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_category ON public.products USING btree (category);


--
-- Name: idx_products_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_name ON public.products USING btree (name);


--
-- Name: idx_unknown_product_requests_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unknown_product_requests_barcode ON public.unknown_product_requests USING btree (barcode);


--
-- Name: idx_unknown_product_requests_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unknown_product_requests_created_at ON public.unknown_product_requests USING btree (created_at);


--
-- Name: idx_unknown_product_requests_query; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unknown_product_requests_query ON public.unknown_product_requests USING btree (query_type, query_value);


--
-- Name: idx_unknown_product_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unknown_product_requests_status ON public.unknown_product_requests USING btree (status);


--
-- Name: ix_audit_logs_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: ix_audit_logs_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_entity_id ON public.audit_logs USING btree (entity_id);


--
-- Name: ix_audit_logs_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_event_type ON public.audit_logs USING btree (event_type);


--
-- Name: ix_audit_logs_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_id ON public.audit_logs USING btree (id);


--
-- Name: ix_audit_logs_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_occurred_at ON public.audit_logs USING btree (occurred_at);


--
-- Name: ix_barcode_scans_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_barcode_scans_id ON public.barcode_scans USING btree (id);


--
-- Name: ix_barcode_scans_scan_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_barcode_scans_scan_session_id ON public.barcode_scans USING btree (scan_session_id);


--
-- Name: ix_external_product_cache_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_cache_barcode ON public.external_product_cache USING btree (barcode);


--
-- Name: ix_external_product_cache_external_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_cache_external_source ON public.external_product_cache USING btree (external_source);


--
-- Name: ix_external_product_cache_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_cache_id ON public.external_product_cache USING btree (id);


--
-- Name: ix_external_product_cache_product_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_cache_product_name ON public.external_product_cache USING btree (product_name);


--
-- Name: ix_external_product_cache_query_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_cache_query_type ON public.external_product_cache USING btree (query_type);


--
-- Name: ix_external_product_cache_query_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_cache_query_value ON public.external_product_cache USING btree (query_value);


--
-- Name: ix_external_product_enrichment_logs_barcode_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_enrichment_logs_barcode_value ON public.external_product_enrichment_logs USING btree (barcode_value);


--
-- Name: ix_external_product_enrichment_logs_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_enrichment_logs_id ON public.external_product_enrichment_logs USING btree (id);


--
-- Name: ix_external_product_enrichment_logs_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_enrichment_logs_product_id ON public.external_product_enrichment_logs USING btree (product_id);


--
-- Name: ix_external_product_enrichment_logs_response_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_external_product_enrichment_logs_response_status ON public.external_product_enrichment_logs USING btree (response_status);


--
-- Name: ix_inventory_items_batch_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_items_batch_number ON public.inventory_items USING btree (batch_number);


--
-- Name: ix_inventory_items_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_items_id ON public.inventory_items USING btree (id);


--
-- Name: ix_inventory_items_intake_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_items_intake_status ON public.inventory_items USING btree (intake_status);


--
-- Name: ix_inventory_items_ocr_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_items_ocr_result_id ON public.inventory_items USING btree (ocr_result_id);


--
-- Name: ix_inventory_items_pipeline_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_items_pipeline_status ON public.inventory_items USING btree (pipeline_status);


--
-- Name: ix_inventory_items_scan_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_items_scan_session_id ON public.inventory_items USING btree (scan_session_id);


--
-- Name: ix_inventory_items_storage_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_items_storage_location_id ON public.inventory_items USING btree (storage_location_id);


--
-- Name: ix_inventory_items_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_items_supplier_id ON public.inventory_items USING btree (supplier_id);


--
-- Name: ix_inventory_items_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_items_warehouse_id ON public.inventory_items USING btree (warehouse_id);


--
-- Name: ix_inventory_movements_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_movements_id ON public.inventory_movements USING btree (id);


--
-- Name: ix_inventory_movements_inventory_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_movements_inventory_item_id ON public.inventory_movements USING btree (inventory_item_id);


--
-- Name: ix_inventory_movements_movement_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventory_movements_movement_type ON public.inventory_movements USING btree (movement_type);


--
-- Name: ix_manual_reviews_human_decision; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_manual_reviews_human_decision ON public.manual_reviews USING btree (human_decision);


--
-- Name: ix_manual_reviews_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_manual_reviews_id ON public.manual_reviews USING btree (id);


--
-- Name: ix_manual_reviews_inventory_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_manual_reviews_inventory_item_id ON public.manual_reviews USING btree (inventory_item_id);


--
-- Name: ix_manual_reviews_ocr_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_manual_reviews_ocr_result_id ON public.manual_reviews USING btree (ocr_result_id);


--
-- Name: ix_manual_reviews_review_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_manual_reviews_review_status ON public.manual_reviews USING btree (review_status);


--
-- Name: ix_manual_reviews_scan_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_manual_reviews_scan_session_id ON public.manual_reviews USING btree (scan_session_id);


--
-- Name: ix_ml_predictions_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ml_predictions_id ON public.ml_predictions USING btree (id);


--
-- Name: ix_ml_predictions_inventory_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ml_predictions_inventory_item_id ON public.ml_predictions USING btree (inventory_item_id);


--
-- Name: ix_ml_predictions_predicted_decision; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ml_predictions_predicted_decision ON public.ml_predictions USING btree (predicted_decision);


--
-- Name: ix_ocr_results_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ocr_results_id ON public.ocr_results USING btree (id);


--
-- Name: ix_ocr_results_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ocr_results_product_id ON public.ocr_results USING btree (product_id);


--
-- Name: ix_ocr_results_scan_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ocr_results_scan_session_id ON public.ocr_results USING btree (scan_session_id);


--
-- Name: ix_product_allergens_allergen_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_allergens_allergen_name ON public.product_allergens USING btree (allergen_name);


--
-- Name: ix_product_allergens_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_allergens_id ON public.product_allergens USING btree (id);


--
-- Name: ix_product_allergens_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_allergens_product_id ON public.product_allergens USING btree (product_id);


--
-- Name: ix_product_identifiers_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_identifiers_id ON public.product_identifiers USING btree (id);


--
-- Name: ix_product_identifiers_identifier_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_identifiers_identifier_value ON public.product_identifiers USING btree (identifier_value);


--
-- Name: ix_product_identifiers_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_identifiers_product_id ON public.product_identifiers USING btree (product_id);


--
-- Name: ix_product_images_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_images_id ON public.product_images USING btree (id);


--
-- Name: ix_product_images_scan_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_images_scan_session_id ON public.product_images USING btree (scan_session_id);


--
-- Name: ix_product_ingredients_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_ingredients_id ON public.product_ingredients USING btree (id);


--
-- Name: ix_product_ingredients_ingredient_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_ingredients_ingredient_name ON public.product_ingredients USING btree (ingredient_name);


--
-- Name: ix_product_ingredients_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_ingredients_product_id ON public.product_ingredients USING btree (product_id);


--
-- Name: ix_product_lookup_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_lookup_logs_created_at ON public.product_lookup_logs USING btree (created_at);


--
-- Name: ix_product_lookup_logs_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_lookup_logs_id ON public.product_lookup_logs USING btree (id);


--
-- Name: ix_product_lookup_logs_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_lookup_logs_product_id ON public.product_lookup_logs USING btree (product_id);


--
-- Name: ix_product_lookup_logs_query_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_lookup_logs_query_type ON public.product_lookup_logs USING btree (query_type);


--
-- Name: ix_product_lookup_logs_query_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_lookup_logs_query_value ON public.product_lookup_logs USING btree (query_value);


--
-- Name: ix_product_lookup_logs_result_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_lookup_logs_result_status ON public.product_lookup_logs USING btree (result_status);


--
-- Name: ix_product_nutrition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_nutrition_id ON public.product_nutrition USING btree (id);


--
-- Name: ix_product_nutrition_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_product_nutrition_product_id ON public.product_nutrition USING btree (product_id);


--
-- Name: ix_product_storage_requirements_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_storage_requirements_id ON public.product_storage_requirements USING btree (id);


--
-- Name: ix_product_storage_requirements_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_storage_requirements_product_id ON public.product_storage_requirements USING btree (product_id);


--
-- Name: ix_products_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_products_barcode ON public.products USING btree (barcode);


--
-- Name: ix_products_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_products_id ON public.products USING btree (id);


--
-- Name: ix_products_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_products_sku ON public.products USING btree (sku);


--
-- Name: ix_scan_alerts_alert_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scan_alerts_alert_type ON public.scan_alerts USING btree (alert_type);


--
-- Name: ix_scan_alerts_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scan_alerts_id ON public.scan_alerts USING btree (id);


--
-- Name: ix_scan_alerts_inventory_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scan_alerts_inventory_item_id ON public.scan_alerts USING btree (inventory_item_id);


--
-- Name: ix_scan_alerts_is_resolved; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scan_alerts_is_resolved ON public.scan_alerts USING btree (is_resolved);


--
-- Name: ix_scan_alerts_scan_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scan_alerts_scan_session_id ON public.scan_alerts USING btree (scan_session_id);


--
-- Name: ix_scan_alerts_severity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scan_alerts_severity ON public.scan_alerts USING btree (severity);


--
-- Name: ix_scan_sessions_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scan_sessions_id ON public.scan_sessions USING btree (id);


--
-- Name: ix_scan_sessions_session_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scan_sessions_session_status ON public.scan_sessions USING btree (session_status);


--
-- Name: ix_storage_contexts_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_storage_contexts_id ON public.storage_contexts USING btree (id);


--
-- Name: ix_storage_locations_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_storage_locations_id ON public.storage_locations USING btree (id);


--
-- Name: ix_storage_locations_location_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_storage_locations_location_code ON public.storage_locations USING btree (location_code);


--
-- Name: ix_storage_locations_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_storage_locations_warehouse_id ON public.storage_locations USING btree (warehouse_id);


--
-- Name: ix_suppliers_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_suppliers_id ON public.suppliers USING btree (id);


--
-- Name: ix_unknown_product_requests_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_unknown_product_requests_barcode ON public.unknown_product_requests USING btree (barcode);


--
-- Name: ix_unknown_product_requests_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_unknown_product_requests_created_at ON public.unknown_product_requests USING btree (created_at);


--
-- Name: ix_unknown_product_requests_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_unknown_product_requests_id ON public.unknown_product_requests USING btree (id);


--
-- Name: ix_unknown_product_requests_query_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_unknown_product_requests_query_type ON public.unknown_product_requests USING btree (query_type);


--
-- Name: ix_unknown_product_requests_query_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_unknown_product_requests_query_value ON public.unknown_product_requests USING btree (query_value);


--
-- Name: ix_unknown_product_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_unknown_product_requests_status ON public.unknown_product_requests USING btree (status);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_warehouses_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_warehouses_id ON public.warehouses USING btree (id);


--
-- Name: barcode_scans barcode_scans_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.barcode_scans
    ADD CONSTRAINT barcode_scans_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: barcode_scans barcode_scans_scan_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.barcode_scans
    ADD CONSTRAINT barcode_scans_scan_session_id_fkey FOREIGN KEY (scan_session_id) REFERENCES public.scan_sessions(id) ON DELETE SET NULL;


--
-- Name: external_product_enrichment_logs external_product_enrichment_logs_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_product_enrichment_logs
    ADD CONSTRAINT external_product_enrichment_logs_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: inventory_items fk_inventory_items_ocr_result_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_inventory_items_ocr_result_id FOREIGN KEY (ocr_result_id) REFERENCES public.ocr_results(id) ON DELETE SET NULL;


--
-- Name: inventory_items inventory_items_barcode_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_barcode_scan_id_fkey FOREIGN KEY (barcode_scan_id) REFERENCES public.barcode_scans(id) ON DELETE SET NULL;


--
-- Name: inventory_items inventory_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: inventory_items inventory_items_scan_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_scan_session_id_fkey FOREIGN KEY (scan_session_id) REFERENCES public.scan_sessions(id) ON DELETE SET NULL;


--
-- Name: inventory_items inventory_items_storage_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_storage_location_id_fkey FOREIGN KEY (storage_location_id) REFERENCES public.storage_locations(id) ON DELETE SET NULL;


--
-- Name: inventory_items inventory_items_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id) ON DELETE SET NULL;


--
-- Name: inventory_items inventory_items_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id) ON DELETE SET NULL;


--
-- Name: inventory_movements inventory_movements_from_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT inventory_movements_from_location_id_fkey FOREIGN KEY (from_location_id) REFERENCES public.storage_locations(id) ON DELETE SET NULL;


--
-- Name: inventory_movements inventory_movements_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT inventory_movements_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: inventory_movements inventory_movements_to_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT inventory_movements_to_location_id_fkey FOREIGN KEY (to_location_id) REFERENCES public.storage_locations(id) ON DELETE SET NULL;


--
-- Name: manual_reviews manual_reviews_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_reviews
    ADD CONSTRAINT manual_reviews_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: manual_reviews manual_reviews_ocr_result_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_reviews
    ADD CONSTRAINT manual_reviews_ocr_result_id_fkey FOREIGN KEY (ocr_result_id) REFERENCES public.ocr_results(id) ON DELETE SET NULL;


--
-- Name: manual_reviews manual_reviews_scan_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_reviews
    ADD CONSTRAINT manual_reviews_scan_session_id_fkey FOREIGN KEY (scan_session_id) REFERENCES public.scan_sessions(id) ON DELETE SET NULL;


--
-- Name: ml_predictions ml_predictions_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_predictions
    ADD CONSTRAINT ml_predictions_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: ocr_results ocr_results_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_results
    ADD CONSTRAINT ocr_results_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE SET NULL;


--
-- Name: ocr_results ocr_results_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_results
    ADD CONSTRAINT ocr_results_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: ocr_results ocr_results_product_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_results
    ADD CONSTRAINT ocr_results_product_image_id_fkey FOREIGN KEY (product_image_id) REFERENCES public.product_images(id) ON DELETE CASCADE;


--
-- Name: ocr_results ocr_results_scan_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_results
    ADD CONSTRAINT ocr_results_scan_session_id_fkey FOREIGN KEY (scan_session_id) REFERENCES public.scan_sessions(id) ON DELETE SET NULL;


--
-- Name: product_allergens product_allergens_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_allergens
    ADD CONSTRAINT product_allergens_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_identifiers product_identifiers_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_identifiers
    ADD CONSTRAINT product_identifiers_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_images product_images_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_images product_images_scan_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_scan_session_id_fkey FOREIGN KEY (scan_session_id) REFERENCES public.scan_sessions(id) ON DELETE SET NULL;


--
-- Name: product_ingredients product_ingredients_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_lookup_logs product_lookup_logs_external_cache_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_lookup_logs
    ADD CONSTRAINT product_lookup_logs_external_cache_id_fkey FOREIGN KEY (external_cache_id) REFERENCES public.external_product_cache(id) ON DELETE SET NULL;


--
-- Name: product_lookup_logs product_lookup_logs_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_lookup_logs
    ADD CONSTRAINT product_lookup_logs_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: product_nutrition product_nutrition_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nutrition
    ADD CONSTRAINT product_nutrition_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_question_logs product_question_logs_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_question_logs
    ADD CONSTRAINT product_question_logs_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE SET NULL;


--
-- Name: product_question_logs product_question_logs_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_question_logs
    ADD CONSTRAINT product_question_logs_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: product_storage_requirements product_storage_requirements_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_storage_requirements
    ADD CONSTRAINT product_storage_requirements_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: scan_alerts scan_alerts_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_alerts
    ADD CONSTRAINT scan_alerts_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE SET NULL;


--
-- Name: scan_alerts scan_alerts_scan_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_alerts
    ADD CONSTRAINT scan_alerts_scan_session_id_fkey FOREIGN KEY (scan_session_id) REFERENCES public.scan_sessions(id) ON DELETE SET NULL;


--
-- Name: storage_contexts storage_contexts_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storage_contexts
    ADD CONSTRAINT storage_contexts_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: storage_locations storage_locations_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storage_locations
    ADD CONSTRAINT storage_locations_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id) ON DELETE CASCADE;


--
-- Name: unknown_product_requests unknown_product_requests_resolved_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unknown_product_requests
    ADD CONSTRAINT unknown_product_requests_resolved_product_id_fkey FOREIGN KEY (resolved_product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict XB8OZiPTzUXGXHvheB1YAprtDDeUzLNpH8v2p0PORsF6udtNztIJMOrL26zLSGs


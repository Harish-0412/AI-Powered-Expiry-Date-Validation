--
-- PostgreSQL database dump
--

\restrict OqwvJO6d63HS7gj9Wedt5hPufHsNYae3lSANMKck06yGaApKrfjemnBiH4kFZmZ

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
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_type character varying(100) NOT NULL,
    entity_type character varying(100),
    entity_id character varying(100),
    actor_id character varying(200),
    actor_type character varying(50),
    before_state jsonb,
    after_state jsonb,
    change_summary text,
    ip_address character varying(50),
    user_agent character varying(500),
    request_id character varying(100),
    occurred_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO expiry_user;

--
-- Name: barcode_scans; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.barcode_scans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid,
    raw_barcode character varying(255) NOT NULL,
    barcode_type character varying(20),
    scan_source character varying(100),
    scan_status character varying(20) DEFAULT 'unresolved'::character varying NOT NULL,
    notes text,
    scanned_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.barcode_scans OWNER TO expiry_user;

--
-- Name: data_quality_issues; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.data_quality_issues (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    inventory_item_id uuid,
    related_table text,
    related_record_id uuid,
    issue_type text NOT NULL,
    severity text NOT NULL,
    issue_message text NOT NULL,
    resolution_status text DEFAULT 'open'::text NOT NULL,
    resolved_by text,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.data_quality_issues OWNER TO expiry_user;

--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    normalized_name text NOT NULL,
    ingredient_type text,
    description text,
    known_shelf_life_impact text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.ingredients OWNER TO expiry_user;

--
-- Name: inventory_items; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.inventory_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    barcode_scan_id uuid,
    batch_number character varying(100),
    manufacturing_date date,
    expiry_date date,
    pipeline_status character varying(30) DEFAULT 'PENDING_OCR'::character varying NOT NULL,
    status_reason text,
    quantity integer DEFAULT 1,
    unit character varying(20),
    intake_notes text,
    intake_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    opened_at timestamp with time zone,
    is_opened boolean DEFAULT false NOT NULL,
    observed_condition text,
    quality_score numeric(5,2)
);


ALTER TABLE public.inventory_items OWNER TO expiry_user;

--
-- Name: manual_reviews; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.manual_reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    inventory_item_id uuid NOT NULL,
    reviewer_id character varying(200),
    reviewer_role character varying(100),
    corrected_mfg_date date,
    corrected_expiry_date date,
    human_decision character varying(30),
    review_notes text,
    escalation_reason text,
    review_status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.manual_reviews OWNER TO expiry_user;

--
-- Name: ml_predictions; Type: TABLE; Schema: public; Owner: expiry_user
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
    decision_confidence numeric(5,4),
    decision_reason text,
    raw_prediction_payload text,
    prediction_status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    failure_reason text,
    predicted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.ml_predictions OWNER TO expiry_user;

--
-- Name: ocr_results; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.ocr_results (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_image_id uuid NOT NULL,
    inventory_item_id uuid,
    raw_text text,
    ocr_engine character varying(100),
    ocr_engine_version character varying(50),
    extracted_text_blocks jsonb,
    overall_confidence numeric(5,4),
    ocr_status character varying(30) DEFAULT 'pending'::character varying NOT NULL,
    failure_reason text,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    detected_mfg_text text,
    detected_expiry_text text,
    detected_ingredients_text text,
    detected_nutrition_text text,
    date_parse_confidence numeric(5,2)
);


ALTER TABLE public.ocr_results OWNER TO expiry_user;

--
-- Name: preservatives; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.preservatives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ingredient_id uuid,
    name text NOT NULL,
    code text,
    preservative_type text,
    expected_effect text,
    risk_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.preservatives OWNER TO expiry_user;

--
-- Name: product_images; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.product_images (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
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


ALTER TABLE public.product_images OWNER TO expiry_user;

--
-- Name: product_ingredients; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.product_ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    ingredient_id uuid NOT NULL,
    ingredient_order integer,
    percentage numeric(5,2),
    source text,
    confidence numeric(5,2),
    raw_text text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.product_ingredients OWNER TO expiry_user;

--
-- Name: product_packaging; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.product_packaging (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    packaging_type text,
    seal_type text,
    is_resealable boolean DEFAULT false NOT NULL,
    light_exposure_level text,
    oxygen_barrier_level text,
    moisture_barrier_level text,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.product_packaging OWNER TO expiry_user;

--
-- Name: products; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    brand character varying(255),
    sku character varying(100) NOT NULL,
    barcode character varying(100) NOT NULL,
    barcode_type character varying(20) DEFAULT 'EAN13'::character varying NOT NULL,
    category character varying(100),
    description text,
    default_storage_type character varying(50),
    image_url character varying(500),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    gtin text,
    manufacturer_name text,
    country_of_origin text,
    net_quantity text,
    ingredients_raw_text text,
    nutrition_raw_text text,
    allergen_info text,
    product_form text
);


ALTER TABLE public.products OWNER TO expiry_user;

--
-- Name: scan_sessions; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.scan_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    inventory_item_id uuid,
    session_status text DEFAULT 'in_progress'::text NOT NULL,
    barcode_completed boolean DEFAULT false NOT NULL,
    ocr_completed boolean DEFAULT false NOT NULL,
    mfg_date_completed boolean DEFAULT false NOT NULL,
    expiry_date_completed boolean DEFAULT false NOT NULL,
    product_description_completed boolean DEFAULT false NOT NULL,
    ingredients_completed boolean DEFAULT false NOT NULL,
    blocking_reason text,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.scan_sessions OWNER TO expiry_user;

--
-- Name: shelf_life_rules; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.shelf_life_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category text NOT NULL,
    storage_type text,
    packaging_type text,
    ingredient_pattern text,
    preservative_pattern text,
    estimated_min_days integer,
    estimated_max_days integer,
    confidence numeric(5,2),
    rule_source text,
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.shelf_life_rules OWNER TO expiry_user;

--
-- Name: storage_contexts; Type: TABLE; Schema: public; Owner: expiry_user
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
    temperature_celsius numeric(5,2),
    humidity_percent numeric(5,2),
    notes text,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.storage_contexts OWNER TO expiry_user;

--
-- Name: users; Type: TABLE; Schema: public; Owner: expiry_user
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    name character varying(255),
    hashed_password text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO expiry_user;

--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.audit_logs (id, event_type, entity_type, entity_id, actor_id, actor_type, before_state, after_state, change_summary, ip_address, user_agent, request_id, occurred_at) FROM stdin;
ca9fe9b8-8a92-4c1b-93fa-23cf86bdedbd	product.created	product	6bf38777-8241-442b-b443-8ed648f7ee8b	actor-1000	system	\N	\N	Product registered in catalogue.	10.0.1.1	\N	req-b3061c7b	2026-06-24 14:31:40.725803+00
e10e264d-ffba-4ac9-9b80-f12470885bb3	inventory.intake	inventory_item	876c3ed6-e32d-4e28-8b5b-ca44b1d2ec9e	actor-1001	service	\N	\N	Batch received at warehouse intake.	10.0.2.2	\N	req-44bf3059	2026-06-24 14:29:40.729916+00
71b4b71b-362f-4e46-8b95-f69a82f2da74	ocr.completed	ocr_result	3c3da521-1d6b-45d4-8431-7391aee56d77	actor-1002	service	\N	\N	OCR extraction completed successfully.	10.0.3.3	\N	req-ff0176ac	2026-06-24 14:27:40.731318+00
701b766b-0c48-41ed-9672-2a2d8172a39b	ocr.failed	ocr_result	7e4675bb-2f2e-43e7-a2ac-1f013f37b9d1	actor-1003	service	\N	\N	OCR extraction failed due to engine timeout.	10.0.4.4	\N	req-40d43f01	2026-06-24 14:25:40.732698+00
b95bb385-f6a7-48b2-9106-fc13d88b95f9	ml.prediction_received	inventory_item	84da942f-3099-4fca-9dd8-d419ecb47e1f	actor-1004	ml_team	\N	\N	ML prediction returned with decision.	10.0.1.5	\N	req-4da14f14	2026-06-24 14:23:40.73381+00
d90053aa-14f2-4e9f-b6b6-faf90646fe0c	manual_review.completed	inventory_item	4ff66496-1a5f-48a1-8ed8-cef0aba666fa	actor-1005	user	\N	\N	Manual review completed by warehouse staff.	10.0.2.6	\N	req-5d300db1	2026-06-24 14:21:40.73552+00
4325336a-3290-4b22-95d4-5a4cb607091c	status.changed	inventory_item	e5c2a776-8a2c-4c08-b30f-bef5415c9d51	actor-1006	system	{"status": "PENDING_OCR"}	{"status": "OCR_COMPLETED"}	Pipeline status updated to next stage.	10.0.3.7	\N	req-149a6b6d	2026-06-24 14:19:40.737259+00
2c3fc4f8-0f1e-4153-9e2d-f584df05bce5	barcode.scanned	barcode_scan	a6d4df42-add0-4d46-812a-184bb58f40ab	actor-1007	service	\N	\N	Barcode scanned via handheld scanner.	10.0.4.8	\N	req-0e224df0	2026-06-24 14:17:40.739048+00
b0027416-1b8b-4429-8911-eaf42a75294e	product.updated	product	497607f1-92b2-43be-94c2-76823be5855a	actor-1008	user	\N	\N	Product details updated by staff.	10.0.1.9	\N	req-19b9f5b1	2026-06-24 14:15:40.740891+00
b23d76a0-b6b5-4c77-8ceb-5c71738f93a2	inventory.flagged_for_review	inventory_item	7b815279-b5e0-46ac-a0fd-d30d853e9573	actor-1009	system	\N	\N	Item flagged for manual review due to low confidence.	10.0.2.10	\N	req-7ddfaaaa	2026-06-24 14:13:40.742273+00
e0973a5a-66b3-4884-a9b1-8a9696422f9e	product.created	product	f5cbd3a0-6057-4c6a-8f22-e81546d59e3f	actor-1000	system	\N	\N	Product registered in catalogue.	10.0.3.11	\N	req-bca9ef9e	2026-06-24 14:11:40.743903+00
f8a44d25-b622-4554-87cb-e017bd939679	inventory.intake	inventory_item	f910442a-43ba-4734-8162-3022363bee47	actor-1001	service	\N	\N	Batch received at warehouse intake.	10.0.4.12	\N	req-271ecfcf	2026-06-24 14:09:40.745642+00
99e624eb-3848-47be-88ae-88836eace884	ocr.completed	ocr_result	7d4b237c-99bc-43e2-bca4-bfb8eeadcc74	actor-1002	service	\N	\N	OCR extraction completed successfully.	10.0.1.13	\N	req-cd7fd4b4	2026-06-24 14:07:40.74727+00
9a01d678-089f-45f2-8c2b-094aaa50fed8	ocr.failed	ocr_result	6d019115-27b9-458b-9797-4b0724fd7cf7	actor-1003	service	\N	\N	OCR extraction failed due to engine timeout.	10.0.2.14	\N	req-5fa1286c	2026-06-24 14:05:40.748653+00
5f1d772f-1938-4416-9a73-5fa40975c904	ml.prediction_received	inventory_item	2f5d6bf1-fdfc-44d0-b05b-2b270f8886d2	actor-1004	ml_team	\N	\N	ML prediction returned with decision.	10.0.3.15	\N	req-1eae3894	2026-06-24 14:03:40.750251+00
d4beca48-438c-415b-8fad-51e57b450cff	manual_review.completed	inventory_item	cf0e4b36-01db-4118-a3a4-5ba93c8ad80d	actor-1005	user	\N	\N	Manual review completed by warehouse staff.	10.0.4.16	\N	req-3ca511f5	2026-06-24 14:01:40.7517+00
bd27fbd4-dc86-462a-bc2a-40cd7edbde0c	status.changed	inventory_item	90836731-ca74-4cc0-9ba0-586cbaa6e231	actor-1006	system	{"status": "PENDING_OCR"}	{"status": "OCR_COMPLETED"}	Pipeline status updated to next stage.	10.0.1.17	\N	req-7bf28884	2026-06-24 13:59:40.752982+00
3ad77317-ccc3-49cf-abbc-2494195ee28f	barcode.scanned	barcode_scan	44c5f582-d6eb-4557-be8c-20cdd443e902	actor-1007	service	\N	\N	Barcode scanned via handheld scanner.	10.0.2.18	\N	req-63de9f72	2026-06-24 13:57:40.754213+00
651461e3-f016-427f-b91c-177e704626cb	product.updated	product	835ab1c9-5fcc-4681-9a02-44dd4b4b48a4	actor-1008	user	\N	\N	Product details updated by staff.	10.0.3.19	\N	req-c46f55e9	2026-06-24 13:55:40.755283+00
63621b90-3430-43b8-a9b1-e4eeb5f0fc1c	inventory.flagged_for_review	inventory_item	f643b03b-7436-4300-9868-72f0148667f3	actor-1009	system	\N	\N	Item flagged for manual review due to low confidence.	10.0.4.20	\N	req-3fab3695	2026-06-24 13:53:40.756976+00
ebca3cec-9370-494a-ac59-8f0abcefbaf3	product.created	product	6bf38777-8241-442b-b443-8ed648f7ee8b	actor-1000	system	\N	\N	Product registered in catalogue.	10.0.1.1	\N	req-441413fa	2026-06-24 13:51:40.75845+00
9cb344d5-0dc4-4a87-b4fd-2e41fa0ddece	inventory.intake	inventory_item	0e64e0e2-9d86-49b2-8075-9386e80cf21c	actor-1001	service	\N	\N	Batch received at warehouse intake.	10.0.2.2	\N	req-d6c22681	2026-06-24 13:49:40.760003+00
128f96e6-33ff-4d14-a7d1-ced49289effc	ocr.completed	ocr_result	93ba3e86-ad9b-4167-8c7b-0d5c30062f29	actor-1002	service	\N	\N	OCR extraction completed successfully.	10.0.3.3	\N	req-4b35da7d	2026-06-24 13:47:40.761136+00
ab516782-1663-4c17-be2e-3b9ee1fdf6f8	ocr.failed	ocr_result	f6dbee2b-b68f-4b7c-aa96-e7812071251a	actor-1003	service	\N	\N	OCR extraction failed due to engine timeout.	10.0.4.4	\N	req-846be1d4	2026-06-24 13:45:40.762164+00
75b65d1d-a820-4e1a-a197-067f1c5a8bf4	ml.prediction_received	inventory_item	64488bf3-4d52-41e7-9bd4-c6de6231caff	actor-1004	ml_team	\N	\N	ML prediction returned with decision.	10.0.1.5	\N	req-b9f8fcd7	2026-06-24 13:43:40.763631+00
9175051f-94f5-461e-9991-3a5b41c94533	manual_review.completed	inventory_item	b1d79f1e-b549-49a6-b88e-474a9e582e62	actor-1005	user	\N	\N	Manual review completed by warehouse staff.	10.0.2.6	\N	req-0349e588	2026-06-24 13:41:40.7654+00
a2895a68-540f-402c-ac76-347c6aa157ea	status.changed	inventory_item	876c3ed6-e32d-4e28-8b5b-ca44b1d2ec9e	actor-1006	system	{"status": "PENDING_OCR"}	{"status": "OCR_COMPLETED"}	Pipeline status updated to next stage.	10.0.3.7	\N	req-7d2914fc	2026-06-24 13:39:40.767049+00
5bbe4f5b-cdd7-4fcc-9636-cd169f5c39d0	barcode.scanned	barcode_scan	9c187b0b-adb5-4cef-8dc2-beb8cfe55552	actor-1007	service	\N	\N	Barcode scanned via handheld scanner.	10.0.4.8	\N	req-4b6cb52f	2026-06-24 13:37:40.768404+00
ca64128c-fd7a-4093-b5fd-42516b70f292	product.updated	product	497607f1-92b2-43be-94c2-76823be5855a	actor-1008	user	\N	\N	Product details updated by staff.	10.0.1.9	\N	req-fd3417f8	2026-06-24 13:35:40.769735+00
8bdeef53-6cf6-47d4-9d9d-6c15777d2081	inventory.flagged_for_review	inventory_item	84da942f-3099-4fca-9dd8-d419ecb47e1f	actor-1009	system	\N	\N	Item flagged for manual review due to low confidence.	10.0.2.10	\N	req-ec55fa14	2026-06-24 13:33:40.77132+00
9bf8e66c-0359-4ebf-8f48-fe585e7b2639	product.created	product	f5cbd3a0-6057-4c6a-8f22-e81546d59e3f	actor-1000	system	\N	\N	Product registered in catalogue.	10.0.3.11	\N	req-2bc1859b	2026-06-24 13:31:40.77268+00
3c1e98a5-0634-4ded-86c3-36e3657bee0d	inventory.intake	inventory_item	e5c2a776-8a2c-4c08-b30f-bef5415c9d51	actor-1001	service	\N	\N	Batch received at warehouse intake.	10.0.4.12	\N	req-2f403c9b	2026-06-24 13:29:40.773988+00
0f76a9c2-ed26-405c-b6a9-22c199a89548	ocr.completed	ocr_result	a4f13fa0-ff29-4008-902b-346241ca1d62	actor-1002	service	\N	\N	OCR extraction completed successfully.	10.0.1.13	\N	req-a5baa052	2026-06-24 13:27:40.775482+00
cbe9aa20-b0b6-47de-8c03-ea4496c22aeb	ocr.failed	ocr_result	7152701f-e4c3-4253-8f8a-13ba0e03f281	actor-1003	service	\N	\N	OCR extraction failed due to engine timeout.	10.0.2.14	\N	req-0729ff79	2026-06-24 13:25:40.777218+00
1c8a9095-3eda-431d-8fd1-0159cfe7d310	ml.prediction_received	inventory_item	7b815279-b5e0-46ac-a0fd-d30d853e9573	actor-1004	ml_team	\N	\N	ML prediction returned with decision.	10.0.3.15	\N	req-1e63b22d	2026-06-24 13:23:40.778897+00
21f74068-90c2-4d87-9b96-698315f73600	manual_review.completed	inventory_item	785a3771-47c9-47ad-8832-5dcef7d65eac	actor-1005	user	\N	\N	Manual review completed by warehouse staff.	10.0.4.16	\N	req-820ba07d	2026-06-24 13:21:40.780293+00
a87c442e-f591-40d1-a343-d0ae60c18025	status.changed	inventory_item	f910442a-43ba-4734-8162-3022363bee47	actor-1006	system	{"status": "PENDING_OCR"}	{"status": "OCR_COMPLETED"}	Pipeline status updated to next stage.	10.0.1.17	\N	req-e7386d1d	2026-06-24 13:19:40.781658+00
56ff7e59-8383-4b21-9c6a-5ffa8b6ff815	barcode.scanned	barcode_scan	6ea387c4-bb6a-47f8-8ed7-07812a2c1110	actor-1007	service	\N	\N	Barcode scanned via handheld scanner.	10.0.2.18	\N	req-eb34e1ab	2026-06-24 13:17:40.782959+00
d7d18731-0feb-4a4a-9f86-c134c92da60f	product.updated	product	835ab1c9-5fcc-4681-9a02-44dd4b4b48a4	actor-1008	user	\N	\N	Product details updated by staff.	10.0.3.19	\N	req-a33986a6	2026-06-24 13:15:40.784918+00
a34f3060-ac53-4052-85f1-6f743d3b39fb	inventory.flagged_for_review	inventory_item	2f5d6bf1-fdfc-44d0-b05b-2b270f8886d2	actor-1009	system	\N	\N	Item flagged for manual review due to low confidence.	10.0.4.20	\N	req-a391d89e	2026-06-24 13:13:40.786725+00
1a055e32-dbd6-4c51-9b23-fead1438fb7f	product.created	product	bd4b5334-9134-48cf-bb3c-1d374d33063f	actor-1000	system	\N	\N	Product registered in catalogue.	10.0.1.1	\N	req-f48c2d20	2026-06-24 14:38:06.817992+00
e9063690-b1f2-4cdd-9575-98b086236740	inventory.intake	inventory_item	ce64a18e-19e3-4fe8-9db9-dc1e7eab0dba	actor-1001	service	\N	\N	Batch received at warehouse intake.	10.0.2.2	\N	req-2b114c57	2026-06-24 14:36:06.817992+00
daaa884a-d0a3-40aa-adf4-3000755f9deb	ocr.completed	ocr_result	a086bb10-365f-40ef-bb37-effa79016fa4	actor-1002	service	\N	\N	OCR extraction completed successfully.	10.0.3.3	\N	req-97914cde	2026-06-24 14:34:06.817992+00
5ddc577f-f681-41c8-af4e-0c18b538a41f	ocr.failed	ocr_result	bd279d7a-27e6-46f5-bc33-b85a4ae1611d	actor-1003	service	\N	\N	OCR extraction failed due to engine timeout.	10.0.4.4	\N	req-d8ba2e80	2026-06-24 14:32:06.817992+00
b96342eb-ed6a-4bc9-9c3c-d69775f55126	ml.prediction_received	inventory_item	50fb6d07-6219-47f3-9f9f-878534c92fb5	actor-1004	ml_team	\N	\N	ML prediction returned with decision ACCEPTED.	10.0.1.5	\N	req-a5460b4c	2026-06-24 14:30:06.817992+00
effc7e1c-6110-4f6d-adfe-159f566344ba	manual_review.completed	inventory_item	40569013-98ec-4da6-9be2-5a51744559fd	actor-1005	user	\N	\N	Manual review completed by warehouse staff.	10.0.2.6	\N	req-11cdc2e8	2026-06-24 14:28:06.817992+00
1ee6f282-bc7f-44f0-93da-cb8c2a281bb7	status.changed	inventory_item	d58109a8-b8fe-44d3-baa9-13e50c1c9a33	actor-1006	system	{"status": "PENDING_OCR"}	{"status": "OCR_COMPLETED"}	Pipeline status updated to next stage.	10.0.3.7	\N	req-b2ce7876	2026-06-24 14:26:06.817992+00
2493472a-d5d9-455c-b15f-16e166f290de	barcode.scanned	barcode_scan	c07bc966-b5eb-4db2-aac0-e62cbeb50b69	actor-1007	service	\N	\N	Barcode scanned via handheld scanner.	10.0.4.8	\N	req-7e647193	2026-06-24 14:24:06.817992+00
7e49a57d-e276-4332-92fb-c377a3d9d265	product.updated	product	e41af519-9235-4eab-9b38-b5af49f22ced	actor-1008	user	\N	\N	Product details updated by staff.	10.0.1.9	\N	req-195a0202	2026-06-24 14:22:06.817992+00
329e0863-9e99-476e-a02f-d2f6e6f477c4	inventory.flagged_for_review	inventory_item	8c0a3645-0118-4909-ac22-8aeebb844028	actor-1009	system	\N	\N	Item flagged for manual review due to low confidence.	10.0.2.10	\N	req-733617be	2026-06-24 14:20:06.817992+00
9d7bd579-33ce-4191-a893-2d63884eec38	product.created	product	db7628e5-ac98-41a5-bc78-76e7ec086a5d	actor-1000	system	\N	\N	Product registered in catalogue.	10.0.3.11	\N	req-33ad1701	2026-06-24 14:18:06.817992+00
75cde85b-2970-4797-b07f-cbbf7b04db67	inventory.intake	inventory_item	973613c3-6985-40f7-99fe-59a17f56e043	actor-1001	service	\N	\N	Batch received at warehouse intake.	10.0.4.12	\N	req-91c93f90	2026-06-24 14:16:06.817992+00
bb291277-42a9-4705-992b-099c8df179eb	ocr.completed	ocr_result	ac341a44-90d5-4f65-8e1f-481fb7c58c0b	actor-1002	service	\N	\N	OCR extraction completed successfully.	10.0.1.13	\N	req-caee7284	2026-06-24 14:14:06.817992+00
237afda6-2573-4700-a333-a5c9ba609485	ocr.failed	ocr_result	021831b0-0064-4130-8cf2-410b6392bd06	actor-1003	service	\N	\N	OCR extraction failed due to engine timeout.	10.0.2.14	\N	req-5dfbb40a	2026-06-24 14:12:06.817992+00
b8c3bdbb-d66b-431d-8d3d-f18b667cae8e	ml.prediction_received	inventory_item	fb05b148-bd2b-4f1d-937e-66513bc46ba8	actor-1004	ml_team	\N	\N	ML prediction returned with decision ACCEPTED.	10.0.3.15	\N	req-e3499fd6	2026-06-24 14:10:06.817992+00
045b3b11-f577-48f6-a944-80858cef0869	manual_review.completed	inventory_item	af992d56-d7d5-4588-a643-6b283216cc59	actor-1005	user	\N	\N	Manual review completed by warehouse staff.	10.0.4.16	\N	req-8b2dc611	2026-06-24 14:08:06.817992+00
b5a30189-317c-4965-8c2a-131fd89b4dcd	status.changed	inventory_item	ab240a4e-6caf-41d2-a793-ceef3d00131e	actor-1006	system	{"status": "PENDING_OCR"}	{"status": "OCR_COMPLETED"}	Pipeline status updated to next stage.	10.0.1.17	\N	req-5c6c1cc3	2026-06-24 14:06:06.817992+00
caa8d1bf-0752-4f05-bd8f-d773db062c24	barcode.scanned	barcode_scan	2ab224d7-bb9a-44f4-947e-89b31ffd8f2e	actor-1007	service	\N	\N	Barcode scanned via handheld scanner.	10.0.2.18	\N	req-686226d9	2026-06-24 14:04:06.817992+00
bf7c56a3-705c-410b-a15b-2e507f2fa2d8	product.updated	product	79d170f6-b0ec-452f-a1b6-c3aeb3ed61b8	actor-1008	user	\N	\N	Product details updated by staff.	10.0.3.19	\N	req-24df662c	2026-06-24 14:02:06.817992+00
e302e282-89bb-4ede-8ed9-75cd459984f2	inventory.flagged_for_review	inventory_item	2dc76abb-94d9-4416-8d88-6fce79af77ff	actor-1009	system	\N	\N	Item flagged for manual review due to low confidence.	10.0.4.20	\N	req-596d70d7	2026-06-24 14:00:06.817992+00
6f26395f-2f7d-437a-80b7-645252af229d	product.created	product	6bf38777-8241-442b-b443-8ed648f7ee8b	actor-1000	system	\N	\N	Product registered in catalogue.	10.0.1.1	\N	req-af93e25d	2026-06-24 13:58:06.817992+00
43a34151-935d-42d2-8df3-c1980a4061c1	inventory.intake	inventory_item	380df1be-e27b-473b-80bf-727c77184720	actor-1001	service	\N	\N	Batch received at warehouse intake.	10.0.2.2	\N	req-91cf10c3	2026-06-24 13:56:06.817992+00
c21c695d-79da-47c7-8777-f28d606502e2	ocr.completed	ocr_result	313287fe-5017-4bc2-bab2-f3d4b172743b	actor-1002	service	\N	\N	OCR extraction completed successfully.	10.0.3.3	\N	req-05c73e54	2026-06-24 13:54:06.817992+00
f83f2c48-eebf-40a3-b1c9-474a2dc54be2	ocr.failed	ocr_result	dc6e19a1-711c-4c65-9d94-0a9e6d6ac369	actor-1003	service	\N	\N	OCR extraction failed due to engine timeout.	10.0.4.4	\N	req-12314da4	2026-06-24 13:52:06.817992+00
1b515552-b06f-4ccc-8bec-3ca3aeb617ad	ml.prediction_received	inventory_item	6fc21afd-93ec-458c-9ddc-5c53d61250d6	actor-1004	ml_team	\N	\N	ML prediction returned with decision ACCEPTED.	10.0.1.5	\N	req-073a63e9	2026-06-24 13:50:06.817992+00
f465102e-bddc-4724-a5ef-e47d4cd99e54	manual_review.completed	inventory_item	7d794e28-dd45-43f1-9d10-b83ec8f8abd6	actor-1005	user	\N	\N	Manual review completed by warehouse staff.	10.0.2.6	\N	req-ede86720	2026-06-24 13:48:06.817992+00
8e6b09ed-df77-4c0e-9cb7-2eec03a836e4	status.changed	inventory_item	ce64a18e-19e3-4fe8-9db9-dc1e7eab0dba	actor-1006	system	{"status": "PENDING_OCR"}	{"status": "OCR_COMPLETED"}	Pipeline status updated to next stage.	10.0.3.7	\N	req-7613c6c2	2026-06-24 13:46:06.817992+00
f218919a-4921-4c7f-a0be-e022f1afb42c	barcode.scanned	barcode_scan	341acf71-a01a-45d5-b762-858f764264df	actor-1007	service	\N	\N	Barcode scanned via handheld scanner.	10.0.4.8	\N	req-e8a04e21	2026-06-24 13:44:06.817992+00
990adcb1-5fcd-438f-920c-b1a9a8b5c118	product.updated	product	425ad452-1999-416e-a374-f5004e137c5a	actor-1008	user	\N	\N	Product details updated by staff.	10.0.1.9	\N	req-db67bb63	2026-06-24 13:42:06.817992+00
9a2af4a2-bfed-493f-b5a4-0c71f551fcbe	inventory.flagged_for_review	inventory_item	50fb6d07-6219-47f3-9f9f-878534c92fb5	actor-1009	system	\N	\N	Item flagged for manual review due to low confidence.	10.0.2.10	\N	req-c549b276	2026-06-24 13:40:06.817992+00
0e2a5f58-d17a-471a-b1dc-fcd37b543f16	product.created	product	ced8ae36-7ee5-4774-983c-0fffa17fa16f	actor-1000	system	\N	\N	Product registered in catalogue.	10.0.3.11	\N	req-9ab1304c	2026-06-24 13:38:06.817992+00
878dadec-9de5-43cd-983b-cfc7ad9437ed	inventory.intake	inventory_item	d58109a8-b8fe-44d3-baa9-13e50c1c9a33	actor-1001	service	\N	\N	Batch received at warehouse intake.	10.0.4.12	\N	req-f42b6362	2026-06-24 13:36:06.817992+00
e714d6fc-a84e-4e0a-85fe-a54c71e964bd	ocr.completed	ocr_result	a29275f2-b077-499a-aee1-476cd3d0d185	actor-1002	service	\N	\N	OCR extraction completed successfully.	10.0.1.13	\N	req-2f6d238d	2026-06-24 13:34:06.817992+00
ace94927-4302-4c67-8290-562699578a26	ocr.failed	ocr_result	e15c9732-2dca-49d7-b807-80d990973313	actor-1003	service	\N	\N	OCR extraction failed due to engine timeout.	10.0.2.14	\N	req-6f39adaf	2026-06-24 13:32:06.817992+00
ab0eecf8-6117-4114-bd4e-7dc555f66428	ml.prediction_received	inventory_item	8c0a3645-0118-4909-ac22-8aeebb844028	actor-1004	ml_team	\N	\N	ML prediction returned with decision ACCEPTED.	10.0.3.15	\N	req-7e692bc5	2026-06-24 13:30:06.817992+00
0f80b06d-42d3-419c-a9fb-9a6b33236916	manual_review.completed	inventory_item	8816c74d-f540-4c87-b898-4952076cfe52	actor-1005	user	\N	\N	Manual review completed by warehouse staff.	10.0.4.16	\N	req-1c9949ca	2026-06-24 13:28:06.817992+00
b22a09d0-3c61-4e8a-bc34-dec126e0c9ab	status.changed	inventory_item	973613c3-6985-40f7-99fe-59a17f56e043	actor-1006	system	{"status": "PENDING_OCR"}	{"status": "OCR_COMPLETED"}	Pipeline status updated to next stage.	10.0.1.17	\N	req-ff63ac08	2026-06-24 13:26:06.817992+00
8a9370fb-37af-4564-9c61-cf739a772530	barcode.scanned	barcode_scan	097e61c6-88ba-471e-b1a7-2428db5f507f	actor-1007	service	\N	\N	Barcode scanned via handheld scanner.	10.0.2.18	\N	req-98758411	2026-06-24 13:24:06.817992+00
7371b0ea-2bb9-4dfc-a68f-a9a4c63efc88	product.updated	product	563c5830-dd37-4234-b574-7ae08c1586ab	actor-1008	user	\N	\N	Product details updated by staff.	10.0.3.19	\N	req-2a286a54	2026-06-24 13:22:06.817992+00
111e2d45-e7ca-43ba-908c-9ff61613a9a5	inventory.flagged_for_review	inventory_item	fb05b148-bd2b-4f1d-937e-66513bc46ba8	actor-1009	system	\N	\N	Item flagged for manual review due to low confidence.	10.0.4.20	\N	req-4dd0f0db	2026-06-24 13:20:06.817992+00
\.


--
-- Data for Name: barcode_scans; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.barcode_scans (id, product_id, raw_barcode, barcode_type, scan_source, scan_status, notes, scanned_at, created_at) FROM stdin;
f2177ce0-8334-4156-ab59-88b6d37534ed	6bf38777-8241-442b-b443-8ed648f7ee8b	8901262010011	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.458609+00	2026-06-24 14:31:40.458609+00
14f6ffd0-2784-4b39-a3b6-710d814eef26	d9d497a6-d070-43eb-a1a1-692a2977f4fa	8901058850123	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.461753+00	2026-06-24 14:31:40.461753+00
8fdf2930-5836-47b8-b013-be7f9f96c11a	0ca02492-67f1-43cb-979e-db3f38ba9dfc	8901648004321	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.463309+00	2026-06-24 14:31:40.463309+00
40fb3a06-b1d5-40a4-aefb-10e8a4f52d41	1069962a-5fe1-4d05-8fce-cd0ed1d93ee7	8901262030019	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.465121+00	2026-06-24 14:31:40.465121+00
7b403c4e-5766-4220-923e-6999e1abc5a9	8c9a25a7-71ec-4d1c-b613-5e20d1bcf839	8901063160012	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.466691+00	2026-06-24 14:31:40.466691+00
5bf33666-ea73-403b-87df-89ce291c968c	12c9f1f0-5fc1-49c3-8f44-b05bc6e6eea7	8901719101015	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.468083+00	2026-06-24 14:31:40.468083+00
2f3ffe6f-205c-4732-ace3-281ff6c58082	0ac0fa33-97f3-49d6-85a0-deb66cfe55f8	8901491100226	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.46931+00	2026-06-24 14:31:40.46931+00
a4bedee3-ce4c-4159-8294-5b3f3f1f1189	7207edd4-f970-4405-a801-bd7ad8c9f942	8901491501221	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.47065+00	2026-06-24 14:31:40.47065+00
5ffbdf9f-d63c-4e95-a8f4-6dcbea7d39a7	497607f1-92b2-43be-94c2-76823be5855a	8901764012342	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.472139+00	2026-06-24 14:31:40.472139+00
cbfefd07-c288-4067-8e2b-60e52885eece	bb457039-0100-4e72-973a-f44d04d88826	8901207011123	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.473499+00	2026-06-24 14:31:40.473499+00
fcdb5ff3-093a-44bc-a33c-8ee1623bbd68	f5cbd3a0-6057-4c6a-8f22-e81546d59e3f	8901491200452	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.474937+00	2026-06-24 14:31:40.474937+00
1b2d8850-f1fe-4b25-9c99-c787d7038a87	e9efa9a4-d2e9-42a3-997a-73347fc47c60	8901207040017	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.476049+00	2026-06-24 14:31:40.476049+00
ccc49a39-5422-4751-9766-d5c408bbbef4	b430351b-5c73-4dcf-8dd5-1dd23f0b0cef	8901725180089	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.477174+00	2026-06-24 14:31:40.477174+00
fe4f0535-2e73-44cc-8cea-3e9632e4cff8	3a8590ba-0daa-4477-967d-6b0cf8adcc3b	8901063019870	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.479052+00	2026-06-24 14:31:40.479052+00
bc50fe05-4b8e-47b5-9a4e-dfcbd38492f8	4706f11d-5ffe-4916-ba15-3328089a331c	8901725123456	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.481132+00	2026-06-24 14:31:40.481132+00
3c9c858e-d12d-4485-90d8-79dd198bc9d5	d955e05a-113a-42cf-9fb1-e9fc2ad21194	8904043901017	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.482461+00	2026-06-24 14:31:40.482461+00
48f23555-d1eb-4c2a-9b26-cb5d064e6b6d	6791233c-112c-41fc-bd6f-ebf97e36a3ef	8906007280012	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.483807+00	2026-06-24 14:31:40.483807+00
5af1ff80-c3fe-4a20-bcec-66f1dea56118	835ab1c9-5fcc-4681-9a02-44dd4b4b48a4	8901030865432	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.485181+00	2026-06-24 14:31:40.485181+00
07c85e3b-e90d-453e-a748-4339a1681dc5	d9660bec-3569-4ca4-9ef7-645ca44fcefe	8901396389012	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:31:40.486645+00	2026-06-24 14:31:40.486645+00
a1f1405d-a184-41a5-acd2-2e0f85c3cf6d	\N	9990000000001	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:31:40.487795+00	2026-06-24 14:31:40.487795+00
75c17280-5c9f-4e87-80b6-17062bca3341	\N	9990000000002	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:31:40.489041+00	2026-06-24 14:31:40.489041+00
f4d9882e-c1ec-449f-8baf-d476c840d652	\N	9990000000003	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:31:40.489994+00	2026-06-24 14:31:40.489994+00
3a0cd11e-59ff-438b-b829-82e0bbae950c	\N	9990000000004	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:31:40.491209+00	2026-06-24 14:31:40.491209+00
0d96ec94-6a6a-4d94-8353-ab6845965573	\N	9990000000005	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:31:40.492579+00	2026-06-24 14:31:40.492579+00
c83fdee2-a8d8-4d7c-9eed-cabcb837ee60	bd4b5334-9134-48cf-bb3c-1d374d33063f	8901058000027	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
57966d1c-147d-44a1-b493-8ff59bd19381	7e607917-5552-4d9c-9e38-49f5c326facb	8901030789010	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
78bcb9fd-e9af-422b-a92b-7fc6207179f8	6e5256ac-650d-4eb7-aee8-ff304e7778df	8901063150245	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
b1dc7c42-9ba2-4acd-bc80-1577dac20be8	425ad452-1999-416e-a374-f5004e137c5a	8904117100018	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
3b4344b8-f47e-41e8-8d43-a6588bac27d1	cdfb993f-640a-4116-8211-f53cd0326391	8901088100015	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
72f75753-3605-46c8-9a97-c59b467b9e35	ced8ae36-7ee5-4774-983c-0fffa17fa16f	0012000001086	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
06451d1d-71c5-4916-917f-a92578b5d36b	1ea123c5-7ba8-478e-8a8a-3873d2803591	0055100150002	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
241ed7cf-f4bc-43aa-9672-aede04839e89	f0ea470d-858d-41ef-9d88-6db353656f82	0074780300018	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
e4dd03ee-5ef4-4c96-87f9-a61c79ec025c	e41af519-9235-4eab-9b38-b5af49f22ced	0028400589758	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
0ef1adcd-faab-4051-b40a-8ff41f0c544d	5f8f150d-0310-44c2-946e-ac7c80f14dbe	7622300441937	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
e570bb99-d095-4a7a-b08b-aa997cf8af60	db7628e5-ac98-41a5-bc78-76e7ec086a5d	8906017260093	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
f2715700-8a5c-4387-8cf2-960ccc8ecc05	f777457d-54d7-4ac1-b3a0-de8d7d0a7e59	8906068110018	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
39812454-2287-4304-bdc9-fc7bbca61f8c	d02b9ab8-b73c-4cac-bb28-e839b11e9730	8904265100012	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
791f1fb5-5256-440c-8b5a-fc3389d4a3ae	563c5830-dd37-4234-b574-7ae08c1586ab	5000168003009	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
3d5afc98-0aba-414a-8c5a-e77a1248fdde	63f75a3d-078f-436c-9d0f-220c82c96c1c	0011111019220	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
6945c085-28d0-4bc6-afe0-a5c89f85fd7d	27fddffb-ab90-48a0-8b78-907ad0486d05	8901176011339	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
ea7c05dd-d400-4b3d-b141-76c74813d50f	282d231d-7e25-4f29-9134-0f5b4c650033	0035000138637	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
c3cc1633-e55b-465c-8579-4d14828cf9dd	d2d51b3c-7006-4281-ab49-1d6309a36818	8906000940019	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
1fdde142-e550-417f-a590-61bf860e234d	79d170f6-b0ec-452f-a1b6-c3aeb3ed61b8	8901058504121	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
3cdb7c63-90f9-4bad-aa31-75ed2e45e1f3	120db931-d73e-4fd3-a206-e6ead5da207d	0065251000188	EAN13	handheld_scanner	resolved	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
f8e50517-279d-4aca-a69d-cd07b454f22f	\N	9990000000001	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
48c6d2a7-9d93-4a83-8774-4c334c7603db	\N	9990000000002	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
7f2b47d5-5d90-4edf-8080-042067646700	\N	9990000000003	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
8707ea3b-bda6-496f-b71f-1c136267a748	\N	9990000000004	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
0f571a9b-ccc0-487e-bf63-c2c00e6fa919	\N	9990000000005	EAN13	mobile_app	unresolved	Barcode not found in catalogue	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
\.


--
-- Data for Name: data_quality_issues; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.data_quality_issues (id, inventory_item_id, related_table, related_record_id, issue_type, severity, issue_message, resolution_status, resolved_by, resolved_at, created_at) FROM stdin;
\.


--
-- Data for Name: ingredients; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.ingredients (id, name, normalized_name, ingredient_type, description, known_shelf_life_impact, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: inventory_items; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.inventory_items (id, product_id, barcode_scan_id, batch_number, manufacturing_date, expiry_date, pipeline_status, status_reason, quantity, unit, intake_notes, intake_at, created_at, updated_at, opened_at, is_opened, observed_condition, quality_score) FROM stdin;
b1d79f1e-b549-49a6-b88e-474a9e582e62	6bf38777-8241-442b-b443-8ed648f7ee8b	f2177ce0-8334-4156-ab59-88b6d37534ed	BATCH-2026001	2026-03-28	2026-06-19	PENDING_OCR	\N	18	units	\N	2026-06-24 14:31:40.493998+00	2026-06-24 14:31:40.493998+00	2026-06-24 14:31:40.493998+00	\N	f	\N	\N
876c3ed6-e32d-4e28-8b5b-ca44b1d2ec9e	d9d497a6-d070-43eb-a1a1-692a2977f4fa	14f6ffd0-2784-4b39-a3b6-710d814eef26	BATCH-2026002	2026-02-08	2026-07-09	OCR_COMPLETED	\N	26	units	\N	2026-06-24 14:31:40.496783+00	2026-06-24 14:31:40.496783+00	2026-06-24 14:31:40.496783+00	\N	f	\N	\N
72ac683e-2e41-435a-adc2-272c07144541	0ca02492-67f1-43cb-979e-db3f38ba9dfc	8fdf2930-5836-47b8-b013-be7f9f96c11a	BATCH-2026003	2026-01-27	2026-08-08	PENDING_ML_REVIEW	\N	30	units	\N	2026-06-24 14:31:40.498371+00	2026-06-24 14:31:40.498371+00	2026-06-24 14:31:40.498371+00	\N	f	\N	\N
04b2ecb8-4baf-4cbf-a9fa-3c354306b12e	1069962a-5fe1-4d05-8fce-cd0ed1d93ee7	40fb3a06-b1d5-40a4-aefb-10e8a4f52d41	BATCH-2026004	2026-01-14	2026-10-22	ML_COMPLETED	\N	28	units	\N	2026-06-24 14:31:40.500346+00	2026-06-24 14:31:40.500346+00	2026-06-24 14:31:40.500346+00	\N	f	\N	\N
84da942f-3099-4fca-9dd8-d419ecb47e1f	8c9a25a7-71ec-4d1c-b613-5e20d1bcf839	7b403c4e-5766-4220-923e-6999e1abc5a9	BATCH-2026005	2026-04-18	\N	MANUAL_REVIEW	\N	22	units	\N	2026-06-24 14:31:40.50205+00	2026-06-24 14:31:40.50205+00	2026-06-24 14:31:40.50205+00	\N	f	\N	\N
4ff66496-1a5f-48a1-8ed8-cef0aba666fa	12c9f1f0-5fc1-49c3-8f44-b05bc6e6eea7	5bf33666-ea73-403b-87df-89ce291c968c	BATCH-2026006	2026-01-08	2026-06-19	PENDING_OCR	\N	22	units	\N	2026-06-24 14:31:40.503596+00	2026-06-24 14:31:40.503596+00	2026-06-24 14:31:40.503596+00	\N	f	\N	\N
e5c2a776-8a2c-4c08-b30f-bef5415c9d51	0ac0fa33-97f3-49d6-85a0-deb66cfe55f8	2f3ffe6f-205c-4732-ace3-281ff6c58082	BATCH-2026007	2026-01-12	2026-07-09	OCR_COMPLETED	\N	47	units	\N	2026-06-24 14:31:40.505932+00	2026-06-24 14:31:40.505932+00	2026-06-24 14:31:40.505932+00	\N	f	\N	\N
87fa595e-3532-48d6-9bd0-34a27257cf5f	7207edd4-f970-4405-a801-bd7ad8c9f942	a4bedee3-ce4c-4159-8294-5b3f3f1f1189	BATCH-2026008	2026-04-20	2026-08-08	PENDING_ML_REVIEW	\N	26	units	\N	2026-06-24 14:31:40.507552+00	2026-06-24 14:31:40.507552+00	2026-06-24 14:31:40.507552+00	\N	f	\N	\N
001f1a1d-daa0-4414-bb6a-312768bd7ef3	497607f1-92b2-43be-94c2-76823be5855a	5ffbdf9f-d63c-4e95-a8f4-6dcbea7d39a7	BATCH-2026009	2025-12-31	2026-10-22	ML_COMPLETED	\N	20	units	\N	2026-06-24 14:31:40.509155+00	2026-06-24 14:31:40.509155+00	2026-06-24 14:31:40.509155+00	\N	f	\N	\N
7b815279-b5e0-46ac-a0fd-d30d853e9573	bb457039-0100-4e72-973a-f44d04d88826	cbfefd07-c288-4067-8e2b-60e52885eece	BATCH-2026010	2026-01-07	\N	MANUAL_REVIEW	\N	47	units	\N	2026-06-24 14:31:40.510823+00	2026-06-24 14:31:40.510823+00	2026-06-24 14:31:40.510823+00	\N	f	\N	\N
785a3771-47c9-47ad-8832-5dcef7d65eac	f5cbd3a0-6057-4c6a-8f22-e81546d59e3f	fcdb5ff3-093a-44bc-a33c-8ee1623bbd68	BATCH-2026011	2026-02-06	2026-06-19	PENDING_OCR	\N	48	units	\N	2026-06-24 14:31:40.513292+00	2026-06-24 14:31:40.513292+00	2026-06-24 14:31:40.513292+00	\N	f	\N	\N
f910442a-43ba-4734-8162-3022363bee47	e9efa9a4-d2e9-42a3-997a-73347fc47c60	1b2d8850-f1fe-4b25-9c99-c787d7038a87	BATCH-2026012	2026-03-11	2026-07-09	OCR_COMPLETED	\N	40	units	\N	2026-06-24 14:31:40.515184+00	2026-06-24 14:31:40.515184+00	2026-06-24 14:31:40.515184+00	\N	f	\N	\N
5b8055e4-1113-4660-bfb7-b794dfa35e4c	b430351b-5c73-4dcf-8dd5-1dd23f0b0cef	ccc49a39-5422-4751-9766-d5c408bbbef4	BATCH-2026013	2026-04-01	2026-08-08	PENDING_ML_REVIEW	\N	39	units	\N	2026-06-24 14:31:40.516872+00	2026-06-24 14:31:40.516872+00	2026-06-24 14:31:40.516872+00	\N	f	\N	\N
1091fc23-0cbd-4522-b45b-999481193061	3a8590ba-0daa-4477-967d-6b0cf8adcc3b	fe4f0535-2e73-44cc-8cea-3e9632e4cff8	BATCH-2026014	2026-04-12	2026-10-22	ML_COMPLETED	\N	46	units	\N	2026-06-24 14:31:40.518199+00	2026-06-24 14:31:40.518199+00	2026-06-24 14:31:40.518199+00	\N	f	\N	\N
cf0e4b36-01db-4118-a3a4-5ba93c8ad80d	4706f11d-5ffe-4916-ba15-3328089a331c	bc50fe05-4b8e-47b5-9a4e-dfcbd38492f8	BATCH-2026016	2025-12-29	2026-06-19	PENDING_OCR	\N	14	units	\N	2026-06-24 14:31:40.5205+00	2026-06-24 14:31:40.5205+00	2026-06-24 14:31:40.5205+00	\N	f	\N	\N
90836731-ca74-4cc0-9ba0-586cbaa6e231	d955e05a-113a-42cf-9fb1-e9fc2ad21194	3c9c858e-d12d-4485-90d8-79dd198bc9d5	BATCH-2026017	2026-03-07	2026-07-09	OCR_COMPLETED	\N	7	units	\N	2026-06-24 14:31:40.52226+00	2026-06-24 14:31:40.52226+00	2026-06-24 14:31:40.52226+00	\N	f	\N	\N
91465d53-29c8-42fe-8e9f-b3c09439d891	6791233c-112c-41fc-bd6f-ebf97e36a3ef	48f23555-d1eb-4c2a-9b26-cb5d064e6b6d	BATCH-2026018	2026-04-16	2026-08-08	PENDING_ML_REVIEW	\N	3	units	\N	2026-06-24 14:31:40.523802+00	2026-06-24 14:31:40.523802+00	2026-06-24 14:31:40.523802+00	\N	f	\N	\N
e9eaa4b2-56cf-4fa0-8001-30bd56a910ba	835ab1c9-5fcc-4681-9a02-44dd4b4b48a4	5af1ff80-c3fe-4a20-bcec-66f1dea56118	BATCH-2026019	2026-03-12	2026-10-22	ML_COMPLETED	\N	12	units	\N	2026-06-24 14:31:40.525306+00	2026-06-24 14:31:40.525306+00	2026-06-24 14:31:40.525306+00	\N	f	\N	\N
f643b03b-7436-4300-9868-72f0148667f3	d9660bec-3569-4ca4-9ef7-645ca44fcefe	07c85e3b-e90d-453e-a748-4339a1681dc5	BATCH-2026020	2026-04-14	\N	MANUAL_REVIEW	\N	25	units	\N	2026-06-24 14:31:40.526969+00	2026-06-24 14:31:40.526969+00	2026-06-24 14:31:40.526969+00	\N	f	\N	\N
422f517d-ec7f-4857-aed5-a0d0d73f15e7	6bf38777-8241-442b-b443-8ed648f7ee8b	f2177ce0-8334-4156-ab59-88b6d37534ed	BATCH-2026021	2026-05-24	2026-06-19	PENDING_OCR	\N	8	units	\N	2026-06-24 14:31:40.528813+00	2026-06-24 14:31:40.528813+00	2026-06-24 14:31:40.528813+00	\N	f	\N	\N
0e64e0e2-9d86-49b2-8075-9386e80cf21c	d9d497a6-d070-43eb-a1a1-692a2977f4fa	14f6ffd0-2784-4b39-a3b6-710d814eef26	BATCH-2026022	2026-01-29	2026-07-09	OCR_COMPLETED	\N	36	units	\N	2026-06-24 14:31:40.530526+00	2026-06-24 14:31:40.530526+00	2026-06-24 14:31:40.530526+00	\N	f	\N	\N
f95afaa0-c93b-45ff-b280-6722cd1c724d	0ca02492-67f1-43cb-979e-db3f38ba9dfc	8fdf2930-5836-47b8-b013-be7f9f96c11a	BATCH-2026023	2026-01-23	2026-08-08	PENDING_ML_REVIEW	\N	23	units	\N	2026-06-24 14:31:40.53183+00	2026-06-24 14:31:40.53183+00	2026-06-24 14:31:40.53183+00	\N	f	\N	\N
4b7c5b68-4bee-44fc-9a81-ba30dd8e876d	1069962a-5fe1-4d05-8fce-cd0ed1d93ee7	40fb3a06-b1d5-40a4-aefb-10e8a4f52d41	BATCH-2026024	2026-03-23	2026-10-22	ML_COMPLETED	\N	19	units	\N	2026-06-24 14:31:40.533663+00	2026-06-24 14:31:40.533663+00	2026-06-24 14:31:40.533663+00	\N	f	\N	\N
64488bf3-4d52-41e7-9bd4-c6de6231caff	8c9a25a7-71ec-4d1c-b613-5e20d1bcf839	7b403c4e-5766-4220-923e-6999e1abc5a9	BATCH-2026025	2026-04-14	\N	MANUAL_REVIEW	\N	39	units	\N	2026-06-24 14:31:40.535641+00	2026-06-24 14:31:40.535641+00	2026-06-24 14:31:40.535641+00	\N	f	\N	\N
7d794e28-dd45-43f1-9d10-b83ec8f8abd6	bd4b5334-9134-48cf-bb3c-1d374d33063f	c83fdee2-a8d8-4d7c-9eed-cabcb837ee60	BATCH-2026001	2026-02-19	2026-06-19	PENDING_OCR	\N	1	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
ce64a18e-19e3-4fe8-9db9-dc1e7eab0dba	7e607917-5552-4d9c-9e38-49f5c326facb	57966d1c-147d-44a1-b493-8ff59bd19381	BATCH-2026002	2026-03-16	2026-07-09	OCR_COMPLETED	\N	43	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
742f9e7e-b842-4e68-b9e2-d4f19cb89ed1	6e5256ac-650d-4eb7-aee8-ff304e7778df	78bcb9fd-e9af-422b-a92b-7fc6207179f8	BATCH-2026003	2026-02-12	2026-08-08	PENDING_ML_REVIEW	\N	22	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
c3460235-b703-4b9a-92bc-edbad2e62924	425ad452-1999-416e-a374-f5004e137c5a	b1dc7c42-9ba2-4acd-bc80-1577dac20be8	BATCH-2026004	2026-04-06	2026-10-22	ML_COMPLETED	\N	41	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
50fb6d07-6219-47f3-9f9f-878534c92fb5	cdfb993f-640a-4116-8211-f53cd0326391	3b4344b8-f47e-41e8-8d43-a6588bac27d1	BATCH-2026005	2026-03-25	\N	MANUAL_REVIEW	\N	28	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
40569013-98ec-4da6-9be2-5a51744559fd	ced8ae36-7ee5-4774-983c-0fffa17fa16f	72f75753-3605-46c8-9a97-c59b467b9e35	BATCH-2026006	2026-03-22	2026-06-19	PENDING_OCR	\N	19	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
d58109a8-b8fe-44d3-baa9-13e50c1c9a33	1ea123c5-7ba8-478e-8a8a-3873d2803591	06451d1d-71c5-4916-917f-a92578b5d36b	BATCH-2026007	2026-01-12	2026-07-09	OCR_COMPLETED	\N	48	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
007abc33-245d-470c-8e58-3014aacd36f2	f0ea470d-858d-41ef-9d88-6db353656f82	241ed7cf-f4bc-43aa-9672-aede04839e89	BATCH-2026008	2026-03-11	2026-08-08	PENDING_ML_REVIEW	\N	36	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
8cc23309-11e7-43bb-81cf-0b47abe33505	e41af519-9235-4eab-9b38-b5af49f22ced	e4dd03ee-5ef4-4c96-87f9-a61c79ec025c	BATCH-2026009	2026-02-11	2026-10-22	ML_COMPLETED	\N	45	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
8c0a3645-0118-4909-ac22-8aeebb844028	5f8f150d-0310-44c2-946e-ac7c80f14dbe	0ef1adcd-faab-4051-b40a-8ff41f0c544d	BATCH-2026010	2026-03-12	\N	MANUAL_REVIEW	\N	6	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
8816c74d-f540-4c87-b898-4952076cfe52	db7628e5-ac98-41a5-bc78-76e7ec086a5d	e570bb99-d095-4a7a-b08b-aa997cf8af60	BATCH-2026011	2026-01-11	2026-06-19	PENDING_OCR	\N	33	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
973613c3-6985-40f7-99fe-59a17f56e043	f777457d-54d7-4ac1-b3a0-de8d7d0a7e59	f2715700-8a5c-4387-8cf2-960ccc8ecc05	BATCH-2026012	2026-04-02	2026-07-09	OCR_COMPLETED	\N	25	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
5e136600-e2ee-4ab7-ab30-68e788af7722	d02b9ab8-b73c-4cac-bb28-e839b11e9730	39812454-2287-4304-bdc9-fc7bbca61f8c	BATCH-2026013	2026-02-21	2026-08-08	PENDING_ML_REVIEW	\N	12	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
02a4ec16-a3c4-45d8-93af-c52745daebc9	563c5830-dd37-4234-b574-7ae08c1586ab	791f1fb5-5256-440c-8b5a-fc3389d4a3ae	BATCH-2026014	2026-03-09	2026-10-22	ML_COMPLETED	\N	42	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
fb05b148-bd2b-4f1d-937e-66513bc46ba8	63f75a3d-078f-436c-9d0f-220c82c96c1c	3d5afc98-0aba-414a-8c5a-e77a1248fdde	BATCH-2026015	2026-04-07	\N	MANUAL_REVIEW	\N	44	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
af992d56-d7d5-4588-a643-6b283216cc59	27fddffb-ab90-48a0-8b78-907ad0486d05	6945c085-28d0-4bc6-afe0-a5c89f85fd7d	BATCH-2026016	2026-04-11	2026-06-19	PENDING_OCR	\N	50	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
ab240a4e-6caf-41d2-a793-ceef3d00131e	282d231d-7e25-4f29-9134-0f5b4c650033	ea7c05dd-d400-4b3d-b141-76c74813d50f	BATCH-2026017	2026-03-21	2026-07-09	OCR_COMPLETED	\N	4	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
79318c4c-0ee9-48e6-8b34-b9600fa345ef	d2d51b3c-7006-4281-ab49-1d6309a36818	c3cc1633-e55b-465c-8579-4d14828cf9dd	BATCH-2026018	2026-01-22	2026-08-08	PENDING_ML_REVIEW	\N	4	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
c7efe4b7-3c70-4fad-976c-542cef8fcc6c	79d170f6-b0ec-452f-a1b6-c3aeb3ed61b8	1fdde142-e550-417f-a590-61bf860e234d	BATCH-2026019	2026-05-13	2026-10-22	ML_COMPLETED	\N	8	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
2dc76abb-94d9-4416-8d88-6fce79af77ff	120db931-d73e-4fd3-a206-e6ead5da207d	3cdb7c63-90f9-4bad-aa31-75ed2e45e1f3	BATCH-2026020	2026-05-20	\N	MANUAL_REVIEW	\N	37	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
7b151aec-98d0-4492-a3af-cefa373d4a0d	6bf38777-8241-442b-b443-8ed648f7ee8b	c83fdee2-a8d8-4d7c-9eed-cabcb837ee60	BATCH-2026021	2026-04-07	2026-06-19	PENDING_OCR	\N	21	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
380df1be-e27b-473b-80bf-727c77184720	d9d497a6-d070-43eb-a1a1-692a2977f4fa	57966d1c-147d-44a1-b493-8ff59bd19381	BATCH-2026022	2026-01-31	2026-07-09	OCR_COMPLETED	\N	36	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
6097417e-6ae3-48f9-8d69-cd1841eac542	0ca02492-67f1-43cb-979e-db3f38ba9dfc	78bcb9fd-e9af-422b-a92b-7fc6207179f8	BATCH-2026023	2026-04-15	2026-08-08	PENDING_ML_REVIEW	\N	49	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
6ca3bed0-b39b-4b3d-8353-84cdf44f8d26	1069962a-5fe1-4d05-8fce-cd0ed1d93ee7	b1dc7c42-9ba2-4acd-bc80-1577dac20be8	BATCH-2026024	2026-02-21	2026-10-22	ML_COMPLETED	\N	14	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
6fc21afd-93ec-458c-9ddc-5c53d61250d6	8c9a25a7-71ec-4d1c-b613-5e20d1bcf839	3b4344b8-f47e-41e8-8d43-a6588bac27d1	BATCH-2026025	2026-01-29	\N	MANUAL_REVIEW	\N	7	units	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	f	\N	\N
\.


--
-- Data for Name: manual_reviews; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.manual_reviews (id, inventory_item_id, reviewer_id, reviewer_role, corrected_mfg_date, corrected_expiry_date, human_decision, review_notes, escalation_reason, review_status, reviewed_at, created_at, updated_at) FROM stdin;
08a6aea5-9633-47c4-932c-6d5b0d8cfaeb	b1d79f1e-b549-49a6-b88e-474a9e582e62	USR-1000	warehouse_staff	\N	2026-06-21	ACCEPTED	Manually verified batch. Corrected expiry date confirmed.	OCR failed -- label was torn.	completed	2026-06-24 14:31:40.710831+00	2026-06-24 14:31:40.710831+00	2026-06-24 14:31:40.710831+00
3e0c2d49-4c2f-4c9b-9a30-6e5b4d64e9d8	876c3ed6-e32d-4e28-8b5b-ca44b1d2ec9e	USR-1001	supervisor	\N	2026-07-11	REJECTED	Manually verified batch. Corrected expiry date confirmed.	ML confidence below threshold.	completed	2026-06-24 14:31:40.712991+00	2026-06-24 14:31:40.712991+00	2026-06-24 14:31:40.712991+00
d7967f45-e057-4918-8946-103287b5d31c	72ac683e-2e41-435a-adc2-272c07144541	USR-1002	qa	\N	2026-08-10	PRIORITY_SALE	Manually verified batch. Corrected expiry date confirmed.	Conflicting dates found on packaging.	completed	2026-06-24 14:31:40.714783+00	2026-06-24 14:31:40.714783+00	2026-06-24 14:31:40.714783+00
b05470b2-f8b8-4381-84fe-0b28fc44f1dc	04b2ecb8-4baf-4cbf-a9fa-3c354306b12e	USR-1003	warehouse_staff	\N	2026-10-24	ESCALATE_TO_QA	Manually verified batch. Corrected expiry date confirmed.	Batch close to expiry -- supervisor review required.	completed	2026-06-24 14:31:40.716146+00	2026-06-24 14:31:40.716146+00	2026-06-24 14:31:40.716146+00
aa9cd9f3-68db-4c49-aaa0-944cccd57ae3	84da942f-3099-4fca-9dd8-d419ecb47e1f	USR-1004	supervisor	\N	2026-07-26	ACCEPTED	Manually verified batch. Corrected expiry date confirmed.	Batch number missing from label.	completed	2026-06-24 14:31:40.717499+00	2026-06-24 14:31:40.717499+00	2026-06-24 14:31:40.717499+00
0d88f30a-4800-46b5-8e73-48749bf67ccd	4ff66496-1a5f-48a1-8ed8-cef0aba666fa	USR-1005	qa	\N	2026-06-21	REJECTED	Manually verified batch. Corrected expiry date confirmed.	OCR failed -- label was torn.	pending	\N	2026-06-24 14:31:40.718844+00	2026-06-24 14:31:40.718844+00
73cebdca-b307-48d1-ab2f-7b92f4eebb4a	e5c2a776-8a2c-4c08-b30f-bef5415c9d51	USR-1006	warehouse_staff	\N	2026-07-11	PRIORITY_SALE	Manually verified batch. Corrected expiry date confirmed.	ML confidence below threshold.	pending	\N	2026-06-24 14:31:40.719918+00	2026-06-24 14:31:40.719918+00
8d1641f2-6412-4bed-af77-63bfefa74edc	87fa595e-3532-48d6-9bd0-34a27257cf5f	USR-1007	supervisor	\N	2026-08-10	ESCALATE_TO_QA	Manually verified batch. Corrected expiry date confirmed.	Conflicting dates found on packaging.	pending	\N	2026-06-24 14:31:40.721301+00	2026-06-24 14:31:40.721301+00
ca40ba17-28d0-46b9-ae8b-94220e30edf7	001f1a1d-daa0-4414-bb6a-312768bd7ef3	USR-1008	qa	\N	2026-10-24	ACCEPTED	Manually verified batch. Corrected expiry date confirmed.	Batch close to expiry -- supervisor review required.	pending	\N	2026-06-24 14:31:40.722917+00	2026-06-24 14:31:40.722917+00
c753d04d-f994-4c08-9004-5f6b8923640b	7b815279-b5e0-46ac-a0fd-d30d853e9573	USR-1009	warehouse_staff	\N	2026-07-26	REJECTED	Manually verified batch. Corrected expiry date confirmed.	Batch number missing from label.	pending	\N	2026-06-24 14:31:40.724505+00	2026-06-24 14:31:40.724505+00
f6a96adc-b474-476f-a41f-2b4a4461aa52	7d794e28-dd45-43f1-9d10-b83ec8f8abd6	USR-1000	warehouse_staff	\N	2026-06-21	ACCEPTED	Manually verified batch. Corrected expiry date confirmed.	OCR failed -- label was torn and unreadable.	completed	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
d32b859d-e83b-4ed2-98b3-f782ec072e71	ce64a18e-19e3-4fe8-9db9-dc1e7eab0dba	USR-1001	supervisor	\N	2026-07-11	REJECTED	Manually verified batch. Corrected expiry date confirmed.	ML confidence 0.43 -- below acceptance threshold.	completed	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
f75ba8b2-8958-4267-971c-f0d658d308af	742f9e7e-b842-4e68-b9e2-d4f19cb89ed1	USR-1002	qa	\N	2026-08-10	PRIORITY_SALE	Manually verified batch. Corrected expiry date confirmed.	Conflicting manufacturing and expiry dates on label.	completed	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
64930390-a53b-4a12-ab05-4cf1766a1c8c	c3460235-b703-4b9a-92bc-edbad2e62924	USR-1003	warehouse_staff	\N	2026-10-24	ESCALATE_TO_QA	Manually verified batch. Corrected expiry date confirmed.	Batch nearing expiry -- supervisor review required.	completed	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
5d1d6ae0-63ad-49cd-ae74-9f3cb3e73a55	50fb6d07-6219-47f3-9f9f-878534c92fb5	USR-1004	supervisor	\N	2026-07-26	ACCEPTED	Manually verified batch. Corrected expiry date confirmed.	Batch number missing from product label.	completed	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
22911a83-874f-4f99-bf55-6dd0b9003491	40569013-98ec-4da6-9be2-5a51744559fd	USR-1005	qa	\N	2026-06-21	REJECTED	Manually verified batch. Corrected expiry date confirmed.	OCR failed -- label was torn and unreadable.	pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
1f79251c-c81b-4f8b-bf2a-5b6271de8d75	d58109a8-b8fe-44d3-baa9-13e50c1c9a33	USR-1006	warehouse_staff	\N	2026-07-11	PRIORITY_SALE	Manually verified batch. Corrected expiry date confirmed.	ML confidence 0.43 -- below acceptance threshold.	pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
13a8935b-d7bb-480a-8d16-7aff1d8fa302	007abc33-245d-470c-8e58-3014aacd36f2	USR-1007	supervisor	\N	2026-08-10	ESCALATE_TO_QA	Manually verified batch. Corrected expiry date confirmed.	Conflicting manufacturing and expiry dates on label.	pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
07a97dbb-7f59-4045-b899-aa1cf4155b11	8cc23309-11e7-43bb-81cf-0b47abe33505	USR-1008	qa	\N	2026-10-24	ACCEPTED	Manually verified batch. Corrected expiry date confirmed.	Batch nearing expiry -- supervisor review required.	pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
d9f67b08-95f6-45e0-b724-faa5cbd40aed	8c0a3645-0118-4909-ac22-8aeebb844028	USR-1009	warehouse_staff	\N	2026-07-26	REJECTED	Manually verified batch. Corrected expiry date confirmed.	Batch number missing from product label.	pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
\.


--
-- Data for Name: ml_predictions; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.ml_predictions (id, inventory_item_id, model_name, model_version, predicted_mfg_date, predicted_expiry_date, predicted_remaining_days, predicted_decision, decision_confidence, decision_reason, raw_prediction_payload, prediction_status, failure_reason, predicted_at, created_at, updated_at) FROM stdin;
5a7ecd4c-b8b8-462f-b5c7-bd26a01f2b1a	b1d79f1e-b549-49a6-b88e-474a9e582e62	expiry-shelf-v2.1	2.1.0	\N	2026-06-19	-5	ACCEPTED	0.8240	Product has sufficient shelf life remaining.	\N	completed	\N	2026-06-24 14:31:40.678051+00	2026-06-24 14:31:40.678051+00	2026-06-24 14:31:40.678051+00
9f6a0965-e26a-4588-aeb7-39d35e7d4e56	876c3ed6-e32d-4e28-8b5b-ca44b1d2ec9e	expiry-shelf-v2.1	2.1.0	\N	2026-07-09	15	PRIORITY_SALE	0.9608	Nearing expiry -- prioritize for immediate sale.	\N	completed	\N	2026-06-24 14:31:40.68156+00	2026-06-24 14:31:40.68156+00	2026-06-24 14:31:40.68156+00
2d60549c-bb38-483c-a740-b5838dc71131	72ac683e-2e41-435a-adc2-272c07144541	expiry-shelf-v2.1	2.1.0	\N	2026-08-08	45	REJECTED	0.9539	Product is already expired. Do not sell.	\N	completed	\N	2026-06-24 14:31:40.683064+00	2026-06-24 14:31:40.683064+00	2026-06-24 14:31:40.683064+00
2f3efdde-62fd-478e-8aca-55e93ba8f344	04b2ecb8-4baf-4cbf-a9fa-3c354306b12e	expiry-shelf-v2.1	2.1.0	\N	2026-10-22	120	REJECTED	0.9303	Remaining shelf life below minimum threshold.	\N	completed	\N	2026-06-24 14:31:40.684997+00	2026-06-24 14:31:40.684997+00	2026-06-24 14:31:40.684997+00
c35338bd-44aa-4396-a690-f91375263ef4	84da942f-3099-4fca-9dd8-d419ecb47e1f	expiry-shelf-v2.1	2.1.0	\N	\N	\N	REQUIRES_REVIEW	0.7678	Confidence too low -- requires human review.	\N	completed	\N	2026-06-24 14:31:40.686792+00	2026-06-24 14:31:40.686792+00	2026-06-24 14:31:40.686792+00
bb90654a-5a88-4950-b0cd-bfb85d90b9ad	4ff66496-1a5f-48a1-8ed8-cef0aba666fa	expiry-shelf-v2.1	2.1.0	\N	2026-06-19	-5	ACCEPTED	0.8252	Product has sufficient shelf life remaining.	\N	completed	\N	2026-06-24 14:31:40.688442+00	2026-06-24 14:31:40.688442+00	2026-06-24 14:31:40.688442+00
eb05d808-1934-416c-9113-1f25fc6f4bbe	e5c2a776-8a2c-4c08-b30f-bef5415c9d51	expiry-shelf-v2.1	2.1.0	\N	2026-07-09	15	PRIORITY_SALE	0.8382	Nearing expiry -- prioritize for immediate sale.	\N	completed	\N	2026-06-24 14:31:40.689739+00	2026-06-24 14:31:40.689739+00	2026-06-24 14:31:40.689739+00
bd165fa7-6be7-44f7-88f1-0f53211d5be0	87fa595e-3532-48d6-9bd0-34a27257cf5f	expiry-shelf-v2.1	2.1.0	\N	2026-08-08	45	REJECTED	0.7873	Product is already expired. Do not sell.	\N	completed	\N	2026-06-24 14:31:40.690991+00	2026-06-24 14:31:40.690991+00	2026-06-24 14:31:40.690991+00
5ea533ec-9900-4321-aadb-80e293b48359	001f1a1d-daa0-4414-bb6a-312768bd7ef3	expiry-shelf-v2.1	2.1.0	\N	2026-10-22	120	REJECTED	0.8486	Remaining shelf life below minimum threshold.	\N	completed	\N	2026-06-24 14:31:40.692394+00	2026-06-24 14:31:40.692394+00	2026-06-24 14:31:40.692394+00
b01f29d2-a675-48e8-bea4-c9efe729f7a6	7b815279-b5e0-46ac-a0fd-d30d853e9573	expiry-shelf-v2.1	2.1.0	\N	\N	\N	REQUIRES_REVIEW	0.7447	Confidence too low -- requires human review.	\N	completed	\N	2026-06-24 14:31:40.694134+00	2026-06-24 14:31:40.694134+00	2026-06-24 14:31:40.694134+00
9bd2afbd-705a-4284-8d64-b619f91823a7	785a3771-47c9-47ad-8832-5dcef7d65eac	expiry-shelf-v2.1	2.1.0	\N	2026-06-19	-5	ACCEPTED	0.8212	Product has sufficient shelf life remaining.	\N	completed	\N	2026-06-24 14:31:40.69573+00	2026-06-24 14:31:40.69573+00	2026-06-24 14:31:40.69573+00
0edf9dc0-5b8e-4c7f-aa26-4395ebbd3dbb	f910442a-43ba-4734-8162-3022363bee47	expiry-shelf-v2.1	2.1.0	\N	2026-07-09	15	PRIORITY_SALE	0.8975	Nearing expiry -- prioritize for immediate sale.	\N	completed	\N	2026-06-24 14:31:40.697655+00	2026-06-24 14:31:40.697655+00	2026-06-24 14:31:40.697655+00
f9f3cea4-3f8b-43bf-a005-9a637b56e328	5b8055e4-1113-4660-bfb7-b794dfa35e4c	expiry-shelf-v2.1	2.1.0	\N	2026-08-08	45	REJECTED	0.7293	Product is already expired. Do not sell.	\N	completed	\N	2026-06-24 14:31:40.698974+00	2026-06-24 14:31:40.698974+00	2026-06-24 14:31:40.698974+00
a82c7de1-8b41-40b6-8a4b-0aa2a8e774ff	1091fc23-0cbd-4522-b45b-999481193061	expiry-shelf-v2.1	2.1.0	\N	2026-10-22	120	REJECTED	0.8756	Remaining shelf life below minimum threshold.	\N	completed	\N	2026-06-24 14:31:40.700263+00	2026-06-24 14:31:40.700263+00	2026-06-24 14:31:40.700263+00
da445377-6d8e-4db3-a4d9-2be0465afa9a	cf0e4b36-01db-4118-a3a4-5ba93c8ad80d	expiry-shelf-v2.1	2.1.0	\N	2026-06-19	-5	ACCEPTED	0.8802	Product has sufficient shelf life remaining.	\N	completed	\N	2026-06-24 14:31:40.702141+00	2026-06-24 14:31:40.702141+00	2026-06-24 14:31:40.702141+00
eb2be191-9a5a-4f2a-8d2a-6257d768f796	90836731-ca74-4cc0-9ba0-586cbaa6e231	expiry-shelf-v2.1	2.1.0	\N	2026-07-09	15	PRIORITY_SALE	0.8268	Nearing expiry -- prioritize for immediate sale.	\N	completed	\N	2026-06-24 14:31:40.703921+00	2026-06-24 14:31:40.703921+00	2026-06-24 14:31:40.703921+00
e926bbd2-3eda-4042-9b29-43e057c13e52	91465d53-29c8-42fe-8e9f-b3c09439d891	expiry-shelf-v2.1	2.1.0	\N	2026-08-08	45	REJECTED	0.9512	Product is already expired. Do not sell.	\N	completed	\N	2026-06-24 14:31:40.70627+00	2026-06-24 14:31:40.70627+00	2026-06-24 14:31:40.70627+00
dc2b82ef-0d59-4443-b60f-779dc553ffcf	e9eaa4b2-56cf-4fa0-8001-30bd56a910ba	expiry-shelf-v2.1	2.1.0	\N	2026-10-22	120	REJECTED	0.9605	Remaining shelf life below minimum threshold.	\N	completed	\N	2026-06-24 14:31:40.707834+00	2026-06-24 14:31:40.707834+00	2026-06-24 14:31:40.707834+00
24d9a7f1-9468-40d4-ba99-621235dd4e01	f643b03b-7436-4300-9868-72f0148667f3	expiry-shelf-v2.1	2.1.0	\N	\N	\N	REQUIRES_REVIEW	0.8352	Confidence too low -- requires human review.	\N	completed	\N	2026-06-24 14:31:40.709472+00	2026-06-24 14:31:40.709472+00	2026-06-24 14:31:40.709472+00
bac2f0a6-ae00-4181-8a5d-47e3b093fcd7	7d794e28-dd45-43f1-9d10-b83ec8f8abd6	expiry-shelf-v2.1	2.1.0	\N	2026-06-19	-5	ACCEPTED	0.8771	Product has sufficient shelf life remaining.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
0c60ee23-cb32-42fa-848a-5da35175d1a4	ce64a18e-19e3-4fe8-9db9-dc1e7eab0dba	expiry-shelf-v2.1	2.1.0	\N	2026-07-09	15	PRIORITY_SALE	0.7619	Nearing expiry -- prioritize for immediate sale.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
33368482-57a5-4b4a-a5ef-e35c8aa78b86	742f9e7e-b842-4e68-b9e2-d4f19cb89ed1	expiry-shelf-v2.1	2.1.0	\N	2026-08-08	45	REJECTED	0.8085	Product is already expired. Do not sell.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
c8a2678d-6399-4dff-8613-dd8bfe239554	c3460235-b703-4b9a-92bc-edbad2e62924	expiry-shelf-v2.1	2.1.0	\N	2026-10-22	120	REJECTED	0.7574	Remaining shelf life below reject threshold.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
bda06d00-482d-4be6-8d74-9313b416d53d	50fb6d07-6219-47f3-9f9f-878534c92fb5	expiry-shelf-v2.1	2.1.0	\N	\N	\N	REQUIRES_REVIEW	0.9674	Confidence too low -- requires human review.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
a8f02249-3769-4051-b43e-c151b15ac56b	40569013-98ec-4da6-9be2-5a51744559fd	expiry-shelf-v2.1	2.1.0	\N	2026-06-19	-5	ACCEPTED	0.8306	Product has sufficient shelf life remaining.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
9042f410-a8c1-40bf-9e37-5edc059fd875	d58109a8-b8fe-44d3-baa9-13e50c1c9a33	expiry-shelf-v2.1	2.1.0	\N	2026-07-09	15	PRIORITY_SALE	0.8401	Nearing expiry -- prioritize for immediate sale.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
fc9dfaf9-4e73-4bc9-b3a8-8a7034f0230a	007abc33-245d-470c-8e58-3014aacd36f2	expiry-shelf-v2.1	2.1.0	\N	2026-08-08	45	REJECTED	0.8312	Product is already expired. Do not sell.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
4f9eeadc-4080-4266-b2cf-1d8bc90f621e	8cc23309-11e7-43bb-81cf-0b47abe33505	expiry-shelf-v2.1	2.1.0	\N	2026-10-22	120	REJECTED	0.9327	Remaining shelf life below reject threshold.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
e48a0c10-ceca-44dd-8157-79200041019f	8c0a3645-0118-4909-ac22-8aeebb844028	expiry-shelf-v2.1	2.1.0	\N	\N	\N	REQUIRES_REVIEW	0.8795	Confidence too low -- requires human review.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
563dfc0b-c1b6-469c-8b44-fe4ea62d17a7	8816c74d-f540-4c87-b898-4952076cfe52	expiry-shelf-v2.1	2.1.0	\N	2026-06-19	-5	ACCEPTED	0.9480	Product has sufficient shelf life remaining.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
6a6b4ab7-3e99-475e-81c3-2c9e416a8f74	973613c3-6985-40f7-99fe-59a17f56e043	expiry-shelf-v2.1	2.1.0	\N	2026-07-09	15	PRIORITY_SALE	0.8735	Nearing expiry -- prioritize for immediate sale.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
7203dcbf-0f67-4986-ba72-03d2207f4284	5e136600-e2ee-4ab7-ab30-68e788af7722	expiry-shelf-v2.1	2.1.0	\N	2026-08-08	45	REJECTED	0.7911	Product is already expired. Do not sell.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
cfce034a-d8b9-4bda-bf8c-b7a3681c4b6f	02a4ec16-a3c4-45d8-93af-c52745daebc9	expiry-shelf-v2.1	2.1.0	\N	2026-10-22	120	REJECTED	0.7506	Remaining shelf life below reject threshold.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
a1c460cd-9344-40da-a3a8-cbf32f8db988	fb05b148-bd2b-4f1d-937e-66513bc46ba8	expiry-shelf-v2.1	2.1.0	\N	\N	\N	REQUIRES_REVIEW	0.8661	Confidence too low -- requires human review.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
9f3d534a-8c5c-4151-b446-fc3e8efcdf3e	af992d56-d7d5-4588-a643-6b283216cc59	expiry-shelf-v2.1	2.1.0	\N	2026-06-19	-5	ACCEPTED	0.9669	Product has sufficient shelf life remaining.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
7a23801a-3b2e-46a1-8ddf-3b371bcf28e0	ab240a4e-6caf-41d2-a793-ceef3d00131e	expiry-shelf-v2.1	2.1.0	\N	2026-07-09	15	PRIORITY_SALE	0.9254	Nearing expiry -- prioritize for immediate sale.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
f191051d-c132-4ded-bf82-1cb41893047f	79318c4c-0ee9-48e6-8b34-b9600fa345ef	expiry-shelf-v2.1	2.1.0	\N	2026-08-08	45	REJECTED	0.9789	Product is already expired. Do not sell.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
7849f34f-dee0-46c7-9170-966e8eccb527	c7efe4b7-3c70-4fad-976c-542cef8fcc6c	expiry-shelf-v2.1	2.1.0	\N	2026-10-22	120	REJECTED	0.7577	Remaining shelf life below reject threshold.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
63819e92-bcda-4b72-b774-d8357db6099f	2dc76abb-94d9-4416-8d88-6fce79af77ff	expiry-shelf-v2.1	2.1.0	\N	\N	\N	REQUIRES_REVIEW	0.7586	Confidence too low -- requires human review.	\N	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
\.


--
-- Data for Name: ocr_results; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.ocr_results (id, product_image_id, inventory_item_id, raw_text, ocr_engine, ocr_engine_version, extracted_text_blocks, overall_confidence, ocr_status, failure_reason, processed_at, created_at, updated_at, detected_mfg_text, detected_expiry_text, detected_ingredients_text, detected_nutrition_text, date_parse_confidence) FROM stdin;
20dd5182-33d8-4e38-a64d-7d8178bb0286	1d7a938a-23c9-4762-bc7a-422fe70ea538	b1d79f1e-b549-49a6-b88e-474a9e582e62	MFG: 01/03/2026  EXP: 01/09/2026  BATCH: LOT-221A	tesseract-5.3	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	\N	pending	\N	\N	2026-06-24 14:31:40.589361+00	2026-06-24 14:31:40.589361+00	\N	\N	\N	\N	\N
2ea8b6f2-e707-4fea-9d42-e6874f4db4e6	e1e2dcc7-7e43-4ac2-a6fa-97e83e912dfa	876c3ed6-e32d-4e28-8b5b-ca44b1d2ec9e	Manufacturing Date: March 2026  Best Before: Sep 2026	google-vision-v1	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	0.8371	completed	\N	2026-06-24 14:31:40.594192+00	2026-06-24 14:31:40.594192+00	2026-06-24 14:31:40.594192+00	\N	\N	\N	\N	\N
3c3da521-1d6b-45d4-8431-7391aee56d77	f5c5516b-c7fb-4e51-bab3-b6321337cfa3	72ac683e-2e41-435a-adc2-272c07144541	Mfd: 15.02.2026  Use by: 15.08.2026  Batch No: B4421	aws-textract-v2	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.8390	completed	\N	2026-06-24 14:31:40.5963+00	2026-06-24 14:31:40.5963+00	2026-06-24 14:31:40.5963+00	\N	\N	\N	\N	\N
7e4675bb-2f2e-43e7-a2ac-1f013f37b9d1	d72be797-dc25-4cce-97e6-66f21a3e75e5	04b2ecb8-4baf-4cbf-a9fa-3c354306b12e	PROD DATE: 20/04/26  EXP DATE: 20/10/26  MRP Rs.45	tesseract-5.3	1.0	[]	0.7080	completed	\N	2026-06-24 14:31:40.598184+00	2026-06-24 14:31:40.598184+00	2026-06-24 14:31:40.598184+00	\N	\N	\N	\N	\N
a4f13fa0-ff29-4008-902b-346241ca1d62	2d74ecd4-cab0-433b-af91-7f1e41b90da1	84da942f-3099-4fca-9dd8-d419ecb47e1f	Label torn -- partial: ...exp 06/2026...	google-vision-v1	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	\N	failed	OCR engine timeout	\N	2026-06-24 14:31:40.599779+00	2026-06-24 14:31:40.599779+00	\N	\N	\N	\N	\N
7152701f-e4c3-4253-8f8a-13ba0e03f281	9ae59bdb-26ce-4f9a-8715-9665eeafd55d	4ff66496-1a5f-48a1-8ed8-cef0aba666fa	MFG 2026-01-10  EXP 2026-07-10  LOT 9921B	aws-textract-v2	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	\N	pending	\N	\N	2026-06-24 14:31:40.60141+00	2026-06-24 14:31:40.60141+00	\N	\N	\N	\N	\N
27075ff7-3615-4b01-bec1-71af791ad47e	471e5967-9088-43af-bfe2-807096588f68	e5c2a776-8a2c-4c08-b30f-bef5415c9d51	Manufactured: Feb 2026  Expiry: Aug 2026  Batch: F221	tesseract-5.3	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.5726	completed	\N	2026-06-24 14:31:40.603416+00	2026-06-24 14:31:40.603416+00	2026-06-24 14:31:40.603416+00	\N	\N	\N	\N	\N
e9c54cc7-31b2-482c-8eee-4eaf54178d81	75fb6e6c-f93d-47ea-a855-52220cc25d90	87fa595e-3532-48d6-9bd0-34a27257cf5f	MFG: 01/03/2026  EXP: 01/09/2026  BATCH: LOT-221A	google-vision-v1	1.0	[]	0.8386	completed	\N	2026-06-24 14:31:40.605368+00	2026-06-24 14:31:40.605368+00	2026-06-24 14:31:40.605368+00	\N	\N	\N	\N	\N
2a94df59-2d98-4b37-abf4-bea2364d6092	6e20853b-250b-497f-8773-4c72c99551b0	001f1a1d-daa0-4414-bb6a-312768bd7ef3	Manufacturing Date: March 2026  Best Before: Sep 2026	aws-textract-v2	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	0.7578	completed	\N	2026-06-24 14:31:40.607131+00	2026-06-24 14:31:40.607131+00	2026-06-24 14:31:40.607131+00	\N	\N	\N	\N	\N
8fc02c7f-8537-4f44-a53c-f44e43753548	52576b9d-f0b8-476b-9717-7729ebb3e603	7b815279-b5e0-46ac-a0fd-d30d853e9573	Mfd: 15.02.2026  Use by: 15.08.2026  Batch No: B4421	tesseract-5.3	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	\N	failed	OCR engine timeout	\N	2026-06-24 14:31:40.608751+00	2026-06-24 14:31:40.608751+00	\N	\N	\N	\N	\N
00956f7b-fafd-4062-9fb0-12a55fa29af6	02aa98b5-6d3a-4412-89d5-0af64e29459b	785a3771-47c9-47ad-8832-5dcef7d65eac	PROD DATE: 20/04/26  EXP DATE: 20/10/26  MRP Rs.45	google-vision-v1	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	\N	pending	\N	\N	2026-06-24 14:31:40.610182+00	2026-06-24 14:31:40.610182+00	\N	\N	\N	\N	\N
f4096c83-be1f-47a5-a437-9b81ef00b2b2	848e4cda-fd67-4e30-a6bd-c842561470cf	f910442a-43ba-4734-8162-3022363bee47	Label torn -- partial: ...exp 06/2026...	aws-textract-v2	1.0	[]	0.9687	completed	\N	2026-06-24 14:31:40.611684+00	2026-06-24 14:31:40.611684+00	2026-06-24 14:31:40.611684+00	\N	\N	\N	\N	\N
7d4b237c-99bc-43e2-bca4-bfb8eeadcc74	ec843c28-fb18-42f0-9a52-bd893686b30c	5b8055e4-1113-4660-bfb7-b794dfa35e4c	MFG 2026-01-10  EXP 2026-07-10  LOT 9921B	tesseract-5.3	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	0.8846	completed	\N	2026-06-24 14:31:40.613363+00	2026-06-24 14:31:40.613363+00	2026-06-24 14:31:40.613363+00	\N	\N	\N	\N	\N
6d019115-27b9-458b-9797-4b0724fd7cf7	ce97e598-d347-4a36-886b-adaa7f664a28	1091fc23-0cbd-4522-b45b-999481193061	Manufactured: Feb 2026  Expiry: Aug 2026  Batch: F221	google-vision-v1	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	0.5935	completed	\N	2026-06-24 14:31:40.61483+00	2026-06-24 14:31:40.61483+00	2026-06-24 14:31:40.61483+00	\N	\N	\N	\N	\N
912c2db4-6aae-4395-9b9c-0205165d6360	9998ec8d-33da-4959-af3e-461f45a4613a	cf0e4b36-01db-4118-a3a4-5ba93c8ad80d	Manufacturing Date: March 2026  Best Before: Sep 2026	tesseract-5.3	1.0	[]	\N	pending	\N	\N	2026-06-24 14:31:40.616773+00	2026-06-24 14:31:40.616773+00	\N	\N	\N	\N	\N
f399805b-a484-461e-b4fa-91b7ed04e491	929baf10-1ef0-4661-91bb-2952886b10c4	90836731-ca74-4cc0-9ba0-586cbaa6e231	Mfd: 15.02.2026  Use by: 15.08.2026  Batch No: B4421	google-vision-v1	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	0.8251	completed	\N	2026-06-24 14:31:40.618737+00	2026-06-24 14:31:40.618737+00	2026-06-24 14:31:40.618737+00	\N	\N	\N	\N	\N
f3cbff9b-23d2-424b-bc2f-e3209724f287	2cb877ef-01a5-42a8-8437-83dd9e945d13	91465d53-29c8-42fe-8e9f-b3c09439d891	PROD DATE: 20/04/26  EXP DATE: 20/10/26  MRP Rs.45	aws-textract-v2	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	0.9492	completed	\N	2026-06-24 14:31:40.620088+00	2026-06-24 14:31:40.620088+00	2026-06-24 14:31:40.620088+00	\N	\N	\N	\N	\N
80426ab5-c98b-4bab-8a07-4c80d07795fc	79102a33-e969-4702-bf24-7571563b9268	e9eaa4b2-56cf-4fa0-8001-30bd56a910ba	Label torn -- partial: ...exp 06/2026...	tesseract-5.3	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.6497	completed	\N	2026-06-24 14:31:40.621544+00	2026-06-24 14:31:40.621544+00	2026-06-24 14:31:40.621544+00	\N	\N	\N	\N	\N
337d2e53-e051-4e9f-876c-2af89458b869	87f7dc52-24d4-437d-b014-3272110dbf59	f643b03b-7436-4300-9868-72f0148667f3	MFG 2026-01-10  EXP 2026-07-10  LOT 9921B	google-vision-v1	1.0	[]	\N	failed	OCR engine timeout	\N	2026-06-24 14:31:40.622959+00	2026-06-24 14:31:40.622959+00	\N	\N	\N	\N	\N
614e17d5-84a6-4b12-8170-1a16f55fd4b7	38fd88cd-d743-4824-8978-430602a05385	422f517d-ec7f-4857-aed5-a0d0d73f15e7	Manufactured: Feb 2026  Expiry: Aug 2026  Batch: F221	aws-textract-v2	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	\N	pending	\N	\N	2026-06-24 14:31:40.625022+00	2026-06-24 14:31:40.625022+00	\N	\N	\N	\N	\N
d49592cc-c187-4ddb-8b23-556b8585342d	4cfcbd0a-ff53-43e7-9841-18c263f27852	0e64e0e2-9d86-49b2-8075-9386e80cf21c	MFG: 01/03/2026  EXP: 01/09/2026  BATCH: LOT-221A	tesseract-5.3	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	0.8206	completed	\N	2026-06-24 14:31:40.626431+00	2026-06-24 14:31:40.626431+00	2026-06-24 14:31:40.626431+00	\N	\N	\N	\N	\N
93ba3e86-ad9b-4167-8c7b-0d5c30062f29	84c4995c-82dd-4d86-8bad-eb7161baafe7	f95afaa0-c93b-45ff-b280-6722cd1c724d	Manufacturing Date: March 2026  Best Before: Sep 2026	google-vision-v1	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.5771	completed	\N	2026-06-24 14:31:40.628047+00	2026-06-24 14:31:40.628047+00	2026-06-24 14:31:40.628047+00	\N	\N	\N	\N	\N
f6dbee2b-b68f-4b7c-aa96-e7812071251a	435bf16a-6e9a-47a8-b042-d33263e6e4c6	4b7c5b68-4bee-44fc-9a81-ba30dd8e876d	Mfd: 15.02.2026  Use by: 15.08.2026  Batch No: B4421	aws-textract-v2	1.0	[]	0.5619	completed	\N	2026-06-24 14:31:40.62994+00	2026-06-24 14:31:40.62994+00	2026-06-24 14:31:40.62994+00	\N	\N	\N	\N	\N
51804342-511b-4ac1-a277-c83066fb9a8f	089dace1-de1b-4f29-a8fe-7ba65377e834	64488bf3-4d52-41e7-9bd4-c6de6231caff	PROD DATE: 20/04/26  EXP DATE: 20/10/26  MRP Rs.45	tesseract-5.3	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	\N	failed	OCR engine timeout	\N	2026-06-24 14:31:40.631947+00	2026-06-24 14:31:40.631947+00	\N	\N	\N	\N	\N
fb1810c0-2866-41d9-81bd-1aab50f3d778	54bc505b-25fa-4a58-9dc4-a2da76c4f75d	b1d79f1e-b549-49a6-b88e-474a9e582e62	Label torn -- partial: ...exp 06/2026...	google-vision-v1	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	\N	pending	\N	\N	2026-06-24 14:31:40.633954+00	2026-06-24 14:31:40.633954+00	\N	\N	\N	\N	\N
b4e5c46e-333a-4c2d-95c0-4168bb68d912	b341bf88-2bb7-44e4-828a-e1a4da809f0e	876c3ed6-e32d-4e28-8b5b-ca44b1d2ec9e	MFG 2026-01-10  EXP 2026-07-10  LOT 9921B	aws-textract-v2	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.9450	completed	\N	2026-06-24 14:31:40.635822+00	2026-06-24 14:31:40.635822+00	2026-06-24 14:31:40.635822+00	\N	\N	\N	\N	\N
78d9bc5b-8d82-4517-9db0-dcb52540d0c7	71fa2e59-207b-4551-80c6-0dfbe3836504	72ac683e-2e41-435a-adc2-272c07144541	Manufactured: Feb 2026  Expiry: Aug 2026  Batch: F221	tesseract-5.3	1.0	[]	0.7320	completed	\N	2026-06-24 14:31:40.637841+00	2026-06-24 14:31:40.637841+00	2026-06-24 14:31:40.637841+00	\N	\N	\N	\N	\N
a2e32221-d633-4ecf-84f6-3f19c0868a7c	6751426b-04a3-4ef9-ace7-3dfc364e4f6e	7d794e28-dd45-43f1-9d10-b83ec8f8abd6	MFG: 01/03/2026  EXP: 01/09/2026  BATCH: LOT-221A	tesseract-5.3	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	\N	pending	\N	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
de175410-053d-402d-94b1-03aa85b91ee0	92cce1d4-fc8c-49ea-bb5d-d46bb2b33f64	ce64a18e-19e3-4fe8-9db9-dc1e7eab0dba	Manufacturing Date: March 2026  Best Before: Sep 2026	google-vision-v1	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	0.6194	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
a086bb10-365f-40ef-bb37-effa79016fa4	9e10fdb6-288d-41f6-8090-89de89d349b4	742f9e7e-b842-4e68-b9e2-d4f19cb89ed1	Mfd: 15.02.2026  Use by: 15.08.2026  Batch No: B4421	aws-textract-v2	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.6074	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
bd279d7a-27e6-46f5-bc33-b85a4ae1611d	e4b4283b-1779-46e8-b33c-0a6634383785	c3460235-b703-4b9a-92bc-edbad2e62924	PROD DATE: 20/04/26  EXP DATE: 20/10/26  MRP Rs.45	tesseract-5.3	1.0	[]	0.9640	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
a29275f2-b077-499a-aee1-476cd3d0d185	b7144a92-a59e-4bb7-8b4e-3385a2756d92	50fb6d07-6219-47f3-9f9f-878534c92fb5	Label torn -- partial text only: ...exp 06/2026...	google-vision-v1	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	\N	failed	OCR engine timeout	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
e15c9732-2dca-49d7-b807-80d990973313	4fc6147c-289b-4fff-959f-ffd995ef8c54	40569013-98ec-4da6-9be2-5a51744559fd	MFG 2026-01-10  EXP 2026-07-10  LOT 9921B	aws-textract-v2	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	\N	pending	\N	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
903ebad0-650d-4330-b596-48057cd95fee	f7b433ae-f422-419a-8b2c-156cc7e8dab6	d58109a8-b8fe-44d3-baa9-13e50c1c9a33	Manufactured: Feb 2026  Expiry: Aug 2026  Batch: F221	tesseract-5.3	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.9352	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
bc0ce169-890c-4e2f-9d87-078639f052e3	4fe3b41b-a423-4bbe-8830-745e36a36c46	007abc33-245d-470c-8e58-3014aacd36f2	MFG: 01/03/2026  EXP: 01/09/2026  BATCH: LOT-221A	google-vision-v1	1.0	[]	0.8229	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
e8d5b1ba-f8e8-439c-9378-70976ecc7516	efc630fb-5bd4-4cf9-948e-336b209ab708	8cc23309-11e7-43bb-81cf-0b47abe33505	Manufacturing Date: March 2026  Best Before: Sep 2026	aws-textract-v2	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	0.7459	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
d93d8193-38df-43db-b035-fb5a43a0ec36	2f179d5a-aa69-41b8-9de9-81d325fbf3af	8c0a3645-0118-4909-ac22-8aeebb844028	Mfd: 15.02.2026  Use by: 15.08.2026  Batch No: B4421	tesseract-5.3	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	\N	failed	OCR engine timeout	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
75e4b590-adc6-48ca-8385-69d95effab32	c87be580-174b-41ca-a566-e567d0453e2b	8816c74d-f540-4c87-b898-4952076cfe52	PROD DATE: 20/04/26  EXP DATE: 20/10/26  MRP Rs.45	google-vision-v1	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	\N	pending	\N	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
ca699f20-52f6-4fa3-a45a-8316246a00b3	179ea423-b6aa-40c1-bd07-51703839f7fd	973613c3-6985-40f7-99fe-59a17f56e043	Label torn -- partial text only: ...exp 06/2026...	aws-textract-v2	1.0	[]	0.8596	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
ac341a44-90d5-4f65-8e1f-481fb7c58c0b	d1761a4e-f230-4ee4-b2ce-f67ab05d2971	5e136600-e2ee-4ab7-ab30-68e788af7722	MFG 2026-01-10  EXP 2026-07-10  LOT 9921B	tesseract-5.3	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	0.9286	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
021831b0-0064-4130-8cf2-410b6392bd06	0ca79f27-7910-4170-8789-229746338c60	02a4ec16-a3c4-45d8-93af-c52745daebc9	Manufactured: Feb 2026  Expiry: Aug 2026  Batch: F221	google-vision-v1	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	0.8871	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
6bd98b10-a9b8-4186-a6a2-c93b0547b837	a03f10d6-6bc0-4486-9422-cf714b98bc92	fb05b148-bd2b-4f1d-937e-66513bc46ba8	MFG: 01/03/2026  EXP: 01/09/2026  BATCH: LOT-221A	aws-textract-v2	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	\N	failed	OCR engine timeout	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
cf57fff7-9f35-40fe-800a-0c53b549c032	e33f1288-034f-48a0-b928-6c64fb7c8e5b	af992d56-d7d5-4588-a643-6b283216cc59	Manufacturing Date: March 2026  Best Before: Sep 2026	tesseract-5.3	1.0	[]	\N	pending	\N	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
4a1055a1-9057-41d5-a22c-a5dd4db62238	92098502-fe67-4c79-91c0-959804e3abfe	ab240a4e-6caf-41d2-a793-ceef3d00131e	Mfd: 15.02.2026  Use by: 15.08.2026  Batch No: B4421	google-vision-v1	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	0.7443	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
90cfb6c0-621b-4200-8baa-ff0940b7fad2	1fc279a6-aa15-4c5e-8ee8-c344343f4095	79318c4c-0ee9-48e6-8b34-b9600fa345ef	PROD DATE: 20/04/26  EXP DATE: 20/10/26  MRP Rs.45	aws-textract-v2	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	0.5841	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
73405122-b879-49ce-9164-d5f508f13b2c	fb589bcf-45df-405a-ad67-c8fe272b191d	c7efe4b7-3c70-4fad-976c-542cef8fcc6c	Label torn -- partial text only: ...exp 06/2026...	tesseract-5.3	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.8209	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
5c0cea49-f523-40e5-87e2-bafea7705d49	e922a082-3003-4464-817d-926fc3b41428	2dc76abb-94d9-4416-8d88-6fce79af77ff	MFG 2026-01-10  EXP 2026-07-10  LOT 9921B	google-vision-v1	1.0	[]	\N	failed	OCR engine timeout	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
12bc26de-ad40-41e9-9705-0f89be733840	353d1039-dc0d-4429-a457-6289d204c009	7b151aec-98d0-4492-a3af-cefa373d4a0d	Manufactured: Feb 2026  Expiry: Aug 2026  Batch: F221	aws-textract-v2	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	\N	pending	\N	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
a4dce4e2-1837-4ae0-a918-2d92d4c1f4c9	0444318f-99cd-472c-924e-409e89a7e1c1	380df1be-e27b-473b-80bf-727c77184720	MFG: 01/03/2026  EXP: 01/09/2026  BATCH: LOT-221A	tesseract-5.3	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	0.8624	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
313287fe-5017-4bc2-bab2-f3d4b172743b	82ea9a1b-41a7-481e-a43a-463a3088c964	6097417e-6ae3-48f9-8d69-cd1841eac542	Manufacturing Date: March 2026  Best Before: Sep 2026	google-vision-v1	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.9826	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
dc6e19a1-711c-4c65-9d94-0a9e6d6ac369	518f7984-df45-4315-ba6c-f8016bda0e94	6ca3bed0-b39b-4b3d-8353-84cdf44f8d26	Mfd: 15.02.2026  Use by: 15.08.2026  Batch No: B4421	aws-textract-v2	1.0	[]	0.8327	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
7463369c-24b4-4b07-be76-2915d88c1c4f	f3b1f04c-f02f-4f02-a9db-6cd6042277c6	6fc21afd-93ec-458c-9ddc-5c53d61250d6	PROD DATE: 20/04/26  EXP DATE: 20/10/26  MRP Rs.45	tesseract-5.3	1.0	[{"label": "MFG", "value": "01/03/2026"}, {"label": "EXP", "value": "01/09/2026"}]	\N	failed	OCR engine timeout	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
81cd1c07-ad19-459e-86da-463b182f5294	9ed738b0-6529-4371-8285-71b863bfa606	7d794e28-dd45-43f1-9d10-b83ec8f8abd6	Label torn -- partial text only: ...exp 06/2026...	google-vision-v1	1.0	[{"label": "Best Before", "value": "Sep 2026"}]	\N	pending	\N	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
84993f30-bf44-422a-9b59-103eed2d94ff	1dd68e9a-925b-4ebc-a39f-458014578ac1	ce64a18e-19e3-4fe8-9db9-dc1e7eab0dba	MFG 2026-01-10  EXP 2026-07-10  LOT 9921B	aws-textract-v2	1.0	[{"label": "Mfd", "value": "15.02.2026"}, {"label": "Use by", "value": "15.08.2026"}]	0.6234	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
37d40599-4657-4643-80b8-38d60d4940f4	4d09a8fa-d4e3-496b-b81a-7236df5c2081	742f9e7e-b842-4e68-b9e2-d4f19cb89ed1	Manufactured: Feb 2026  Expiry: Aug 2026  Batch: F221	tesseract-5.3	1.0	[]	0.5897	completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	\N	\N	\N	\N	\N
\.


--
-- Data for Name: preservatives; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.preservatives (id, ingredient_id, name, code, preservative_type, expected_effect, risk_notes, created_at) FROM stdin;
\.


--
-- Data for Name: product_images; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.product_images (id, product_id, file_path, file_url, file_size_bytes, mime_type, image_type, processing_status, notes, uploaded_at, created_at, updated_at) FROM stdin;
1d7a938a-23c9-4762-bc7a-422fe70ea538	6bf38777-8241-442b-b443-8ed648f7ee8b	/uploads/8901262010011_0.jpg	https://cdn.expiry.io/8901262010011_0.jpg	328762	image/jpeg	front_label	uploaded	\N	2026-06-24 14:31:40.537268+00	2026-06-24 14:31:40.537268+00	2026-06-24 14:31:40.537268+00
e1e2dcc7-7e43-4ac2-a6fa-97e83e912dfa	d9d497a6-d070-43eb-a1a1-692a2977f4fa	/uploads/8901058850123_1.jpg	https://cdn.expiry.io/8901058850123_1.jpg	138588	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:31:40.540221+00	2026-06-24 14:31:40.540221+00	2026-06-24 14:31:40.540221+00
f5c5516b-c7fb-4e51-bab3-b6321337cfa3	0ca02492-67f1-43cb-979e-db3f38ba9dfc	/uploads/8901648004321_2.jpg	https://cdn.expiry.io/8901648004321_2.jpg	207103	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:31:40.541976+00	2026-06-24 14:31:40.541976+00	2026-06-24 14:31:40.541976+00
d72be797-dc25-4cce-97e6-66f21a3e75e5	1069962a-5fe1-4d05-8fce-cd0ed1d93ee7	/uploads/8901262030019_3.jpg	https://cdn.expiry.io/8901262030019_3.jpg	59027	image/jpeg	product_photo	failed	\N	2026-06-24 14:31:40.543659+00	2026-06-24 14:31:40.543659+00	2026-06-24 14:31:40.543659+00
2d74ecd4-cab0-433b-af91-7f1e41b90da1	8c9a25a7-71ec-4d1c-b613-5e20d1bcf839	/uploads/8901063160012_4.jpg	https://cdn.expiry.io/8901063160012_4.jpg	438531	image/jpeg	front_label	uploaded	\N	2026-06-24 14:31:40.545188+00	2026-06-24 14:31:40.545188+00	2026-06-24 14:31:40.545188+00
9ae59bdb-26ce-4f9a-8715-9665eeafd55d	12c9f1f0-5fc1-49c3-8f44-b05bc6e6eea7	/uploads/8901719101015_5.jpg	https://cdn.expiry.io/8901719101015_5.jpg	236804	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:31:40.546439+00	2026-06-24 14:31:40.546439+00	2026-06-24 14:31:40.546439+00
471e5967-9088-43af-bfe2-807096588f68	0ac0fa33-97f3-49d6-85a0-deb66cfe55f8	/uploads/8901491100226_6.jpg	https://cdn.expiry.io/8901491100226_6.jpg	208530	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:31:40.548151+00	2026-06-24 14:31:40.548151+00	2026-06-24 14:31:40.548151+00
75fb6e6c-f93d-47ea-a855-52220cc25d90	7207edd4-f970-4405-a801-bd7ad8c9f942	/uploads/8901491501221_7.jpg	https://cdn.expiry.io/8901491501221_7.jpg	398608	image/jpeg	product_photo	failed	\N	2026-06-24 14:31:40.549597+00	2026-06-24 14:31:40.549597+00	2026-06-24 14:31:40.549597+00
6e20853b-250b-497f-8773-4c72c99551b0	497607f1-92b2-43be-94c2-76823be5855a	/uploads/8901764012342_8.jpg	https://cdn.expiry.io/8901764012342_8.jpg	183604	image/jpeg	front_label	uploaded	\N	2026-06-24 14:31:40.551+00	2026-06-24 14:31:40.551+00	2026-06-24 14:31:40.551+00
52576b9d-f0b8-476b-9717-7729ebb3e603	bb457039-0100-4e72-973a-f44d04d88826	/uploads/8901207011123_9.jpg	https://cdn.expiry.io/8901207011123_9.jpg	309730	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:31:40.552347+00	2026-06-24 14:31:40.552347+00	2026-06-24 14:31:40.552347+00
02aa98b5-6d3a-4412-89d5-0af64e29459b	f5cbd3a0-6057-4c6a-8f22-e81546d59e3f	/uploads/8901491200452_10.jpg	https://cdn.expiry.io/8901491200452_10.jpg	165020	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:31:40.553933+00	2026-06-24 14:31:40.553933+00	2026-06-24 14:31:40.553933+00
848e4cda-fd67-4e30-a6bd-c842561470cf	e9efa9a4-d2e9-42a3-997a-73347fc47c60	/uploads/8901207040017_11.jpg	https://cdn.expiry.io/8901207040017_11.jpg	267684	image/jpeg	product_photo	failed	\N	2026-06-24 14:31:40.555668+00	2026-06-24 14:31:40.555668+00	2026-06-24 14:31:40.555668+00
ec843c28-fb18-42f0-9a52-bd893686b30c	b430351b-5c73-4dcf-8dd5-1dd23f0b0cef	/uploads/8901725180089_12.jpg	https://cdn.expiry.io/8901725180089_12.jpg	193067	image/jpeg	front_label	uploaded	\N	2026-06-24 14:31:40.557526+00	2026-06-24 14:31:40.557526+00	2026-06-24 14:31:40.557526+00
ce97e598-d347-4a36-886b-adaa7f664a28	3a8590ba-0daa-4477-967d-6b0cf8adcc3b	/uploads/8901063019870_13.jpg	https://cdn.expiry.io/8901063019870_13.jpg	475606	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:31:40.55919+00	2026-06-24 14:31:40.55919+00	2026-06-24 14:31:40.55919+00
9998ec8d-33da-4959-af3e-461f45a4613a	4706f11d-5ffe-4916-ba15-3328089a331c	/uploads/8901725123456_15.jpg	https://cdn.expiry.io/8901725123456_15.jpg	349639	image/jpeg	product_photo	failed	\N	2026-06-24 14:31:40.561664+00	2026-06-24 14:31:40.561664+00	2026-06-24 14:31:40.561664+00
929baf10-1ef0-4661-91bb-2952886b10c4	d955e05a-113a-42cf-9fb1-e9fc2ad21194	/uploads/8904043901017_16.jpg	https://cdn.expiry.io/8904043901017_16.jpg	157911	image/jpeg	front_label	uploaded	\N	2026-06-24 14:31:40.564631+00	2026-06-24 14:31:40.564631+00	2026-06-24 14:31:40.564631+00
2cb877ef-01a5-42a8-8437-83dd9e945d13	6791233c-112c-41fc-bd6f-ebf97e36a3ef	/uploads/8906007280012_17.jpg	https://cdn.expiry.io/8906007280012_17.jpg	87705	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:31:40.567761+00	2026-06-24 14:31:40.567761+00	2026-06-24 14:31:40.567761+00
79102a33-e969-4702-bf24-7571563b9268	835ab1c9-5fcc-4681-9a02-44dd4b4b48a4	/uploads/8901030865432_18.jpg	https://cdn.expiry.io/8901030865432_18.jpg	273683	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:31:40.569685+00	2026-06-24 14:31:40.569685+00	2026-06-24 14:31:40.569685+00
87f7dc52-24d4-437d-b014-3272110dbf59	d9660bec-3569-4ca4-9ef7-645ca44fcefe	/uploads/8901396389012_19.jpg	https://cdn.expiry.io/8901396389012_19.jpg	338556	image/jpeg	product_photo	failed	\N	2026-06-24 14:31:40.571373+00	2026-06-24 14:31:40.571373+00	2026-06-24 14:31:40.571373+00
38fd88cd-d743-4824-8978-430602a05385	6bf38777-8241-442b-b443-8ed648f7ee8b	/uploads/8901262010011_20.jpg	https://cdn.expiry.io/8901262010011_20.jpg	242622	image/jpeg	front_label	uploaded	\N	2026-06-24 14:31:40.57308+00	2026-06-24 14:31:40.57308+00	2026-06-24 14:31:40.57308+00
4cfcbd0a-ff53-43e7-9841-18c263f27852	d9d497a6-d070-43eb-a1a1-692a2977f4fa	/uploads/8901058850123_21.jpg	https://cdn.expiry.io/8901058850123_21.jpg	371654	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:31:40.574533+00	2026-06-24 14:31:40.574533+00	2026-06-24 14:31:40.574533+00
84c4995c-82dd-4d86-8bad-eb7161baafe7	0ca02492-67f1-43cb-979e-db3f38ba9dfc	/uploads/8901648004321_22.jpg	https://cdn.expiry.io/8901648004321_22.jpg	133990	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:31:40.576532+00	2026-06-24 14:31:40.576532+00	2026-06-24 14:31:40.576532+00
435bf16a-6e9a-47a8-b042-d33263e6e4c6	1069962a-5fe1-4d05-8fce-cd0ed1d93ee7	/uploads/8901262030019_23.jpg	https://cdn.expiry.io/8901262030019_23.jpg	138858	image/jpeg	product_photo	failed	\N	2026-06-24 14:31:40.57834+00	2026-06-24 14:31:40.57834+00	2026-06-24 14:31:40.57834+00
089dace1-de1b-4f29-a8fe-7ba65377e834	8c9a25a7-71ec-4d1c-b613-5e20d1bcf839	/uploads/8901063160012_24.jpg	https://cdn.expiry.io/8901063160012_24.jpg	169890	image/jpeg	front_label	uploaded	\N	2026-06-24 14:31:40.580177+00	2026-06-24 14:31:40.580177+00	2026-06-24 14:31:40.580177+00
54bc505b-25fa-4a58-9dc4-a2da76c4f75d	12c9f1f0-5fc1-49c3-8f44-b05bc6e6eea7	/uploads/8901719101015_25.jpg	https://cdn.expiry.io/8901719101015_25.jpg	206588	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:31:40.581641+00	2026-06-24 14:31:40.581641+00	2026-06-24 14:31:40.581641+00
b341bf88-2bb7-44e4-828a-e1a4da809f0e	0ac0fa33-97f3-49d6-85a0-deb66cfe55f8	/uploads/8901491100226_26.jpg	https://cdn.expiry.io/8901491100226_26.jpg	391498	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:31:40.58336+00	2026-06-24 14:31:40.58336+00	2026-06-24 14:31:40.58336+00
71fa2e59-207b-4551-80c6-0dfbe3836504	7207edd4-f970-4405-a801-bd7ad8c9f942	/uploads/8901491501221_27.jpg	https://cdn.expiry.io/8901491501221_27.jpg	295933	image/jpeg	product_photo	failed	\N	2026-06-24 14:31:40.584884+00	2026-06-24 14:31:40.584884+00	2026-06-24 14:31:40.584884+00
60fda319-1b57-4912-b6af-a19f9678ae82	497607f1-92b2-43be-94c2-76823be5855a	/uploads/8901764012342_28.jpg	https://cdn.expiry.io/8901764012342_28.jpg	362001	image/jpeg	front_label	uploaded	\N	2026-06-24 14:31:40.586377+00	2026-06-24 14:31:40.586377+00	2026-06-24 14:31:40.586377+00
31d57334-89a6-43c8-9756-6986b18ebb35	bb457039-0100-4e72-973a-f44d04d88826	/uploads/8901207011123_29.jpg	https://cdn.expiry.io/8901207011123_29.jpg	315002	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:31:40.58768+00	2026-06-24 14:31:40.58768+00	2026-06-24 14:31:40.58768+00
6751426b-04a3-4ef9-ace7-3dfc364e4f6e	bd4b5334-9134-48cf-bb3c-1d374d33063f	/uploads/8901058000027_0.jpg	https://cdn.expiry.io/8901058000027_0.jpg	332195	image/jpeg	front_label	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
92cce1d4-fc8c-49ea-bb5d-d46bb2b33f64	7e607917-5552-4d9c-9e38-49f5c326facb	/uploads/8901030789010_1.jpg	https://cdn.expiry.io/8901030789010_1.jpg	302433	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
9e10fdb6-288d-41f6-8090-89de89d349b4	6e5256ac-650d-4eb7-aee8-ff304e7778df	/uploads/8901063150245_2.jpg	https://cdn.expiry.io/8901063150245_2.jpg	476823	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
e4b4283b-1779-46e8-b33c-0a6634383785	425ad452-1999-416e-a374-f5004e137c5a	/uploads/8904117100018_3.jpg	https://cdn.expiry.io/8904117100018_3.jpg	197085	image/jpeg	product_photo	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
b7144a92-a59e-4bb7-8b4e-3385a2756d92	cdfb993f-640a-4116-8211-f53cd0326391	/uploads/8901088100015_4.jpg	https://cdn.expiry.io/8901088100015_4.jpg	140204	image/jpeg	side_label	failed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
4fc6147c-289b-4fff-959f-ffd995ef8c54	ced8ae36-7ee5-4774-983c-0fffa17fa16f	/uploads/0012000001086_5.jpg	https://cdn.expiry.io/0012000001086_5.jpg	406711	image/jpeg	front_label	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
f7b433ae-f422-419a-8b2c-156cc7e8dab6	1ea123c5-7ba8-478e-8a8a-3873d2803591	/uploads/0055100150002_6.jpg	https://cdn.expiry.io/0055100150002_6.jpg	206724	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
4fe3b41b-a423-4bbe-8830-745e36a36c46	f0ea470d-858d-41ef-9d88-6db353656f82	/uploads/0074780300018_7.jpg	https://cdn.expiry.io/0074780300018_7.jpg	152413	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
efc630fb-5bd4-4cf9-948e-336b209ab708	e41af519-9235-4eab-9b38-b5af49f22ced	/uploads/0028400589758_8.jpg	https://cdn.expiry.io/0028400589758_8.jpg	149667	image/jpeg	product_photo	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
2f179d5a-aa69-41b8-9de9-81d325fbf3af	5f8f150d-0310-44c2-946e-ac7c80f14dbe	/uploads/7622300441937_9.jpg	https://cdn.expiry.io/7622300441937_9.jpg	391825	image/jpeg	side_label	failed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
c87be580-174b-41ca-a566-e567d0453e2b	db7628e5-ac98-41a5-bc78-76e7ec086a5d	/uploads/8906017260093_10.jpg	https://cdn.expiry.io/8906017260093_10.jpg	50299	image/jpeg	front_label	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
179ea423-b6aa-40c1-bd07-51703839f7fd	f777457d-54d7-4ac1-b3a0-de8d7d0a7e59	/uploads/8906068110018_11.jpg	https://cdn.expiry.io/8906068110018_11.jpg	493800	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
d1761a4e-f230-4ee4-b2ce-f67ab05d2971	d02b9ab8-b73c-4cac-bb28-e839b11e9730	/uploads/8904265100012_12.jpg	https://cdn.expiry.io/8904265100012_12.jpg	200488	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
0ca79f27-7910-4170-8789-229746338c60	563c5830-dd37-4234-b574-7ae08c1586ab	/uploads/5000168003009_13.jpg	https://cdn.expiry.io/5000168003009_13.jpg	239616	image/jpeg	product_photo	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
a03f10d6-6bc0-4486-9422-cf714b98bc92	63f75a3d-078f-436c-9d0f-220c82c96c1c	/uploads/0011111019220_14.jpg	https://cdn.expiry.io/0011111019220_14.jpg	388849	image/jpeg	side_label	failed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
e33f1288-034f-48a0-b928-6c64fb7c8e5b	27fddffb-ab90-48a0-8b78-907ad0486d05	/uploads/8901176011339_15.jpg	https://cdn.expiry.io/8901176011339_15.jpg	153703	image/jpeg	front_label	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
92098502-fe67-4c79-91c0-959804e3abfe	282d231d-7e25-4f29-9134-0f5b4c650033	/uploads/0035000138637_16.jpg	https://cdn.expiry.io/0035000138637_16.jpg	391658	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
1fc279a6-aa15-4c5e-8ee8-c344343f4095	d2d51b3c-7006-4281-ab49-1d6309a36818	/uploads/8906000940019_17.jpg	https://cdn.expiry.io/8906000940019_17.jpg	144041	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
fb589bcf-45df-405a-ad67-c8fe272b191d	79d170f6-b0ec-452f-a1b6-c3aeb3ed61b8	/uploads/8901058504121_18.jpg	https://cdn.expiry.io/8901058504121_18.jpg	362670	image/jpeg	product_photo	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
e922a082-3003-4464-817d-926fc3b41428	120db931-d73e-4fd3-a206-e6ead5da207d	/uploads/0065251000188_19.jpg	https://cdn.expiry.io/0065251000188_19.jpg	454005	image/jpeg	side_label	failed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
353d1039-dc0d-4429-a457-6289d204c009	6bf38777-8241-442b-b443-8ed648f7ee8b	/uploads/8901262010011_20.jpg	https://cdn.expiry.io/8901262010011_20.jpg	403064	image/jpeg	front_label	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
0444318f-99cd-472c-924e-409e89a7e1c1	d9d497a6-d070-43eb-a1a1-692a2977f4fa	/uploads/8901058850123_21.jpg	https://cdn.expiry.io/8901058850123_21.jpg	236146	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
82ea9a1b-41a7-481e-a43a-463a3088c964	0ca02492-67f1-43cb-979e-db3f38ba9dfc	/uploads/8901648004321_22.jpg	https://cdn.expiry.io/8901648004321_22.jpg	204266	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
518f7984-df45-4315-ba6c-f8016bda0e94	1069962a-5fe1-4d05-8fce-cd0ed1d93ee7	/uploads/8901262030019_23.jpg	https://cdn.expiry.io/8901262030019_23.jpg	419748	image/jpeg	product_photo	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
f3b1f04c-f02f-4f02-a9db-6cd6042277c6	8c9a25a7-71ec-4d1c-b613-5e20d1bcf839	/uploads/8901063160012_24.jpg	https://cdn.expiry.io/8901063160012_24.jpg	480543	image/jpeg	side_label	failed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
9ed738b0-6529-4371-8285-71b863bfa606	bd4b5334-9134-48cf-bb3c-1d374d33063f	/uploads/8901058000027_25.jpg	https://cdn.expiry.io/8901058000027_25.jpg	336087	image/jpeg	front_label	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
1dd68e9a-925b-4ebc-a39f-458014578ac1	7e607917-5552-4d9c-9e38-49f5c326facb	/uploads/8901030789010_26.jpg	https://cdn.expiry.io/8901030789010_26.jpg	333716	image/jpeg	back_label	ocr_pending	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
4d09a8fa-d4e3-496b-b81a-7236df5c2081	6e5256ac-650d-4eb7-aee8-ff304e7778df	/uploads/8901063150245_27.jpg	https://cdn.expiry.io/8901063150245_27.jpg	391860	image/jpeg	barcode_close_up	ocr_completed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
87d1e9b3-42ac-4239-8e48-cbd290ff8d5b	425ad452-1999-416e-a374-f5004e137c5a	/uploads/8904117100018_28.jpg	https://cdn.expiry.io/8904117100018_28.jpg	336026	image/jpeg	product_photo	uploaded	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
2df96246-62f1-427a-a268-427cea012a69	cdfb993f-640a-4116-8211-f53cd0326391	/uploads/8901088100015_29.jpg	https://cdn.expiry.io/8901088100015_29.jpg	470498	image/jpeg	side_label	failed	\N	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
\.


--
-- Data for Name: product_ingredients; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.product_ingredients (id, product_id, ingredient_id, ingredient_order, percentage, source, confidence, raw_text, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: product_packaging; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.product_packaging (id, product_id, packaging_type, seal_type, is_resealable, light_exposure_level, oxygen_barrier_level, moisture_barrier_level, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.products (id, name, brand, sku, barcode, barcode_type, category, description, default_storage_type, image_url, is_active, created_at, updated_at, gtin, manufacturer_name, country_of_origin, net_quantity, ingredients_raw_text, nutrition_raw_text, allergen_info, product_form) FROM stdin;
bd4b5334-9134-48cf-bb3c-1d374d33063f	Full Cream Milk 1L	Amul	AMUL-MILK-1L	8901058000027	EAN13	Dairy	Pasteurised full cream milk in a 1-litre tetra pack.	refrigerated	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
7e607917-5552-4d9c-9e38-49f5c326facb	Low Fat Yogurt 400g	Nestle	NESTLE-YOG-400G	8901030789010	EAN13	Dairy	Low-fat plain yogurt with live cultures, 400g tub.	refrigerated	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
6e5256ac-650d-4eb7-aee8-ff304e7778df	Processed Cheese Slices 200g	Britannia	BRIT-CHEESE-200G	8901063150245	EAN13	Dairy	Individually wrapped processed cheese slices, 200g pack.	refrigerated	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
425ad452-1999-416e-a374-f5004e137c5a	Salted Butter 100g	Mother Dairy	MDAIRY-BUT-100G	8904117100018	EAN13	Dairy	Creamy salted butter, 100g block.	refrigerated	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
cdfb993f-640a-4116-8211-f53cd0326391	Mango Fruit Drink 200ml	Frooti	FROOTI-MANGO-200ML	8901088100015	EAN13	Beverages	Mango flavoured fruit drink, 200ml tetra pack.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
ced8ae36-7ee5-4774-983c-0fffa17fa16f	Orange Juice 1L	Tropicana	TROP-OJ-1L	0012000001086	EAN13	Beverages	100% pure pressed orange juice, 1-litre carton.	refrigerated	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
1ea123c5-7ba8-478e-8a8a-3873d2803591	Green Tea 25 Bags	Tetley	TETLEY-GT-25	0055100150002	EAN13	Beverages	Green tea bags, pack of 25. Store in cool dry place.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
f0ea470d-858d-41ef-9d88-6db353656f82	Sparkling Mineral Water 500ml	Perrier	PERRIER-500ML	0074780300018	EAN13	Beverages	Naturally sparkling mineral water, 500ml glass bottle.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
e41af519-9235-4eab-9b38-b5af49f22ced	Classic Salted Chips 100g	Lays	LAYS-SALT-100G	0028400589758	EAN13	Snacks	Classic salted potato chips, 100g bag.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
5f8f150d-0310-44c2-946e-ac7c80f14dbe	Dark Chocolate Bar 80g	Cadbury Bournville	CAD-BORN-80G	7622300441937	EAN13	Snacks	Rich dark chocolate 70% cocoa, 80g bar.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
db7628e5-ac98-41a5-bc78-76e7ec086a5d	Roasted Mixed Nuts 150g	Happilo	HAPPI-MNUTS-150G	8906017260093	EAN13	Snacks	Dry roasted mixed nuts ??? almonds, cashews, walnuts, 150g.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
f777457d-54d7-4ac1-b3a0-de8d7d0a7e59	Whole Wheat Bread 400g	Harvest Gold	HG-WWBREAD-400G	8906068110018	EAN13	Bakery	Whole wheat sandwich bread, 400g loaf (18 slices).	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
d02b9ab8-b73c-4cac-bb28-e839b11e9730	Butter Croissant 6-Pack	Monginis	MONG-CROIS-6PK	8904265100012	EAN13	Bakery	Freshly baked all-butter croissants, pack of 6.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
563c5830-dd37-4234-b574-7ae08c1586ab	Digestive Biscuits 400g	McVitie's	MCVIT-DIG-400G	5000168003009	EAN13	Bakery	Original digestive wheat biscuits, 400g pack.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
63f75a3d-078f-436c-9d0f-220c82c96c1c	Moisturising Shampoo 340ml	Dove	DOVE-SHAMP-340ML	0011111019220	EAN13	Personal Care	Intensive moisture repair shampoo for dry hair, 340ml.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
27fddffb-ab90-48a0-8b78-907ad0486d05	Sunscreen SPF 50 100ml	Lotus Herbals	LOTUS-SPF50-100ML	8901176011339	EAN13	Personal Care	Broad spectrum SPF 50 sunscreen, 100ml tube.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
282d231d-7e25-4f29-9134-0f5b4c650033	Toothpaste Whitening 150g	Colgate	COLG-WHITE-150G	0035000138637	EAN13	Personal Care	Advanced whitening toothpaste with fluoride, 150g.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
d2d51b3c-7006-4281-ab49-1d6309a36818	Basmati Rice 5kg	India Gate	IGATE-BASMATI-5KG	8906000940019	EAN13	Packaged Foods	Premium aged basmati rice, 5kg vacuum-sealed bag.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
79d170f6-b0ec-452f-a1b6-c3aeb3ed61b8	Masala Instant Noodles 70g	Maggi	MAGGI-MASALA-70G	8901058504121	EAN13	Packaged Foods	Instant noodles with masala tastemaker, 70g single serving.	ambient	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
120db931-d73e-4fd3-a206-e6ead5da207d	Frozen Peas 500g	McCain	MCCAIN-PEAS-500G	0065251000188	EAN13	Packaged Foods	Garden fresh frozen green peas, 500g resealable bag.	frozen	\N	t	2026-06-24 09:41:29.696175+00	2026-06-24 09:41:29.696175+00	\N	\N	\N	\N	\N	\N	\N	\N
6bf38777-8241-442b-b443-8ed648f7ee8b	Amul Taaza Milk 500ml	Amul	AMUL-TAAZA-500ML	8901262010011	EAN13	Dairy	Pasteurised toned milk pouch.	refrigerated	\N	t	2026-06-24 14:31:40.429255+00	2026-06-24 14:31:40.429255+00	\N	\N	\N	\N	\N	\N	\N	\N
d9d497a6-d070-43eb-a1a1-692a2977f4fa	Nestle Everyday Whitener 400g	Nestle	NESTLE-EW-400G	8901058850123	EAN13	Dairy	Dairy whitener powder for tea and coffee.	ambient	\N	t	2026-06-24 14:31:40.435322+00	2026-06-24 14:31:40.435322+00	\N	\N	\N	\N	\N	\N	\N	\N
0ca02492-67f1-43cb-979e-db3f38ba9dfc	Mother Dairy Classic Curd 400g	Mother Dairy	MD-CURD-400G	8901648004321	EAN13	Dairy	Fresh curd requiring cold storage.	refrigerated	\N	t	2026-06-24 14:31:40.437024+00	2026-06-24 14:31:40.437024+00	\N	\N	\N	\N	\N	\N	\N	\N
1069962a-5fe1-4d05-8fce-cd0ed1d93ee7	Amul Salted Butter 100g	Amul	AMUL-BUTTER-100G	8901262030019	EAN13	Dairy	Salted butter block, 100g.	refrigerated	\N	t	2026-06-24 14:31:40.438365+00	2026-06-24 14:31:40.438365+00	\N	\N	\N	\N	\N	\N	\N	\N
8c9a25a7-71ec-4d1c-b613-5e20d1bcf839	Britannia Good Day Cookies 200g	Britannia	BRIT-GD-200G	8901063160012	EAN13	Snacks	Cashew cookies packed for retail.	ambient	\N	t	2026-06-24 14:31:40.439468+00	2026-06-24 14:31:40.439468+00	\N	\N	\N	\N	\N	\N	\N	\N
12c9f1f0-5fc1-49c3-8f44-b05bc6e6eea7	Parle-G Glucose Biscuits 250g	Parle	PARLE-G-250G	8901719101015	EAN13	Snacks	Classic glucose biscuits.	ambient	\N	t	2026-06-24 14:31:40.440423+00	2026-06-24 14:31:40.440423+00	\N	\N	\N	\N	\N	\N	\N	\N
0ac0fa33-97f3-49d6-85a0-deb66cfe55f8	Lay''s Classic Salted Chips 52g	Lay's	LAYS-CLASSIC-52G	8901491100226	EAN13	Snacks	Classic salted potato chips.	ambient	\N	t	2026-06-24 14:31:40.441388+00	2026-06-24 14:31:40.441388+00	\N	\N	\N	\N	\N	\N	\N	\N
7207edd4-f970-4405-a801-bd7ad8c9f942	Kurkure Masala Munch 90g	Kurkure	KURKURE-MASALA-90G	8901491501221	EAN13	Snacks	Spicy crunchy corn snack.	ambient	\N	t	2026-06-24 14:31:40.442482+00	2026-06-24 14:31:40.442482+00	\N	\N	\N	\N	\N	\N	\N	\N
497607f1-92b2-43be-94c2-76823be5855a	Coca-Cola Original 750ml	Coca-Cola	COKE-750ML	8901764012342	EAN13	Beverages	Carbonated soft drink bottle.	ambient	\N	t	2026-06-24 14:31:40.443793+00	2026-06-24 14:31:40.443793+00	\N	\N	\N	\N	\N	\N	\N	\N
bb457039-0100-4e72-973a-f44d04d88826	Real Mixed Fruit Juice 1L	Real	REAL-MIXED-1L	8901207011123	EAN13	Beverages	Packaged mixed fruit juice carton.	ambient	\N	t	2026-06-24 14:31:40.44511+00	2026-06-24 14:31:40.44511+00	\N	\N	\N	\N	\N	\N	\N	\N
f5cbd3a0-6057-4c6a-8f22-e81546d59e3f	Tropicana Orange Delight 1L	Tropicana	TROP-ORANGE-1L	8901491200452	EAN13	Beverages	Packaged orange fruit beverage.	ambient	\N	t	2026-06-24 14:31:40.446227+00	2026-06-24 14:31:40.446227+00	\N	\N	\N	\N	\N	\N	\N	\N
e9efa9a4-d2e9-42a3-997a-73347fc47c60	Bisleri Mineral Water 1L	Bisleri	BISLERI-1L	8901207040017	EAN13	Beverages	Packaged drinking water 1-litre.	ambient	\N	t	2026-06-24 14:31:40.447151+00	2026-06-24 14:31:40.447151+00	\N	\N	\N	\N	\N	\N	\N	\N
b430351b-5c73-4dcf-8dd5-1dd23f0b0cef	Harvest Gold White Bread 400g	Harvest Gold	HG-WHITE-BREAD-400G	8901725180089	EAN13	Bakery	Packaged white bread loaf.	ambient	\N	t	2026-06-24 14:31:40.448352+00	2026-06-24 14:31:40.448352+00	\N	\N	\N	\N	\N	\N	\N	\N
3a8590ba-0daa-4477-967d-6b0cf8adcc3b	Britannia Brown Bread 400g	Britannia	BRIT-BROWN-BREAD-400G	8901063019870	EAN13	Bakery	Packaged brown bread loaf.	ambient	\N	t	2026-06-24 14:31:40.449545+00	2026-06-24 14:31:40.449545+00	\N	\N	\N	\N	\N	\N	\N	\N
4706f11d-5ffe-4916-ba15-3328089a331c	Aashirvaad Wheat Atta 1kg	Aashirvaad	AASHIRVAAD-ATTA-1KG	8901725123456	EAN13	Packaged Foods	Whole wheat flour pack.	ambient	\N	t	2026-06-24 14:31:40.451216+00	2026-06-24 14:31:40.451216+00	\N	\N	\N	\N	\N	\N	\N	\N
d955e05a-113a-42cf-9fb1-e9fc2ad21194	Tata Salt Iodized 1kg	Tata	TATA-SALT-1KG	8904043901017	EAN13	Packaged Foods	Iodized salt packet.	ambient	\N	t	2026-06-24 14:31:40.453106+00	2026-06-24 14:31:40.453106+00	\N	\N	\N	\N	\N	\N	\N	\N
6791233c-112c-41fc-bd6f-ebf97e36a3ef	Fortune Sunflower Oil 1L	Fortune	FORTUNE-SFO-1L	8906007280012	EAN13	Packaged Foods	Refined sunflower cooking oil.	ambient	\N	t	2026-06-24 14:31:40.454403+00	2026-06-24 14:31:40.454403+00	\N	\N	\N	\N	\N	\N	\N	\N
835ab1c9-5fcc-4681-9a02-44dd4b4b48a4	Dove Cream Beauty Bar 100g	Dove	DOVE-BAR-100G	8901030865432	EAN13	Personal Care	Moisturizing bathing soap bar.	ambient	\N	t	2026-06-24 14:31:40.455622+00	2026-06-24 14:31:40.455622+00	\N	\N	\N	\N	\N	\N	\N	\N
d9660bec-3569-4ca4-9ef7-645ca44fcefe	Dettol Antiseptic Liquid 250ml	Dettol	DETTOL-250ML	8901396389012	EAN13	Personal Care	Antiseptic disinfectant liquid.	ambient	\N	t	2026-06-24 14:31:40.45703+00	2026-06-24 14:31:40.45703+00	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: scan_sessions; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.scan_sessions (id, inventory_item_id, session_status, barcode_completed, ocr_completed, mfg_date_completed, expiry_date_completed, product_description_completed, ingredients_completed, blocking_reason, started_at, completed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: shelf_life_rules; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.shelf_life_rules (id, category, storage_type, packaging_type, ingredient_pattern, preservative_pattern, estimated_min_days, estimated_max_days, confidence, rule_source, notes, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: storage_contexts; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.storage_contexts (id, inventory_item_id, warehouse_id, zone, aisle, shelf, bin_location, storage_type, temperature_celsius, humidity_percent, notes, recorded_at, created_at, updated_at) FROM stdin;
69a5ef80-e29b-472d-8323-1ce555e42f2d	b1d79f1e-b549-49a6-b88e-474a9e582e62	WH-DELHI-01	Zone-A	A1	S1	BIN-100	refrigerated	3.59	49.57	Auto-recorded on intake.	2026-06-24 14:31:40.640518+00	2026-06-24 14:31:40.640518+00	2026-06-24 14:31:40.640518+00
589c5dbd-00ee-4107-89b9-75b7fdb99b11	876c3ed6-e32d-4e28-8b5b-ca44b1d2ec9e	WH-MUMBAI-02	Zone-B	A2	S2	BIN-101	ambient	18.10	51.19	Auto-recorded on intake.	2026-06-24 14:31:40.643561+00	2026-06-24 14:31:40.643561+00	2026-06-24 14:31:40.643561+00
366727ad-4bac-4078-ab5c-0cbab2eec0bd	72ac683e-2e41-435a-adc2-272c07144541	WH-BANGALORE-03	Cold-Room-1	A3	S3	BIN-102	refrigerated	7.47	52.68	Auto-recorded on intake.	2026-06-24 14:31:40.645156+00	2026-06-24 14:31:40.645156+00	2026-06-24 14:31:40.645156+00
2ba76401-96ae-4555-8225-515df2e1a320	04b2ecb8-4baf-4cbf-a9fa-3c354306b12e	WH-DELHI-01	Cold-Room-2	A4	S4	BIN-103	refrigerated	6.59	52.56	Auto-recorded on intake.	2026-06-24 14:31:40.647022+00	2026-06-24 14:31:40.647022+00	2026-06-24 14:31:40.647022+00
06eba890-3f69-4fe0-81b4-4ce807017466	84da942f-3099-4fca-9dd8-d419ecb47e1f	WH-MUMBAI-02	Frozen-Bay	A5	S1	BIN-104	ambient	25.85	52.11	Auto-recorded on intake.	2026-06-24 14:31:40.648379+00	2026-06-24 14:31:40.648379+00	2026-06-24 14:31:40.648379+00
37f3f7e8-da52-48f8-9ce7-3ccb18ab27cd	4ff66496-1a5f-48a1-8ed8-cef0aba666fa	WH-BANGALORE-03	Ambient-Rack-3	A1	S2	BIN-105	ambient	22.04	40.85	Auto-recorded on intake.	2026-06-24 14:31:40.649531+00	2026-06-24 14:31:40.649531+00	2026-06-24 14:31:40.649531+00
265b1dd9-e564-4305-96a1-fab4bfe3b130	e5c2a776-8a2c-4c08-b30f-bef5415c9d51	WH-DELHI-01	Zone-A	A2	S3	BIN-106	ambient	27.51	40.33	Auto-recorded on intake.	2026-06-24 14:31:40.65071+00	2026-06-24 14:31:40.65071+00	2026-06-24 14:31:40.65071+00
c9c501d7-70d6-463a-b6e5-6478fb0baacf	87fa595e-3532-48d6-9bd0-34a27257cf5f	WH-MUMBAI-02	Zone-B	A3	S4	BIN-107	ambient	25.59	62.05	Auto-recorded on intake.	2026-06-24 14:31:40.651993+00	2026-06-24 14:31:40.651993+00	2026-06-24 14:31:40.651993+00
ddf3d5db-320f-484e-9475-f53ff21b3200	001f1a1d-daa0-4414-bb6a-312768bd7ef3	WH-BANGALORE-03	Cold-Room-1	A4	S1	BIN-108	ambient	27.17	53.97	Auto-recorded on intake.	2026-06-24 14:31:40.653635+00	2026-06-24 14:31:40.653635+00	2026-06-24 14:31:40.653635+00
29c2025f-ae97-4e23-846f-98b87843d63f	7b815279-b5e0-46ac-a0fd-d30d853e9573	WH-DELHI-01	Cold-Room-2	A5	S2	BIN-109	ambient	27.11	68.59	Auto-recorded on intake.	2026-06-24 14:31:40.65498+00	2026-06-24 14:31:40.65498+00	2026-06-24 14:31:40.65498+00
d26e1cbd-f1e8-48de-970c-bee402719b21	785a3771-47c9-47ad-8832-5dcef7d65eac	WH-MUMBAI-02	Frozen-Bay	A1	S3	BIN-110	ambient	21.82	50.43	Auto-recorded on intake.	2026-06-24 14:31:40.656188+00	2026-06-24 14:31:40.656188+00	2026-06-24 14:31:40.656188+00
5fe9b718-997b-41b4-8f7a-e623dadeebe1	f910442a-43ba-4734-8162-3022363bee47	WH-BANGALORE-03	Ambient-Rack-3	A2	S4	BIN-111	ambient	25.44	42.45	Auto-recorded on intake.	2026-06-24 14:31:40.657514+00	2026-06-24 14:31:40.657514+00	2026-06-24 14:31:40.657514+00
9d4cd9f7-f076-4e20-b4cf-538e54b04861	5b8055e4-1113-4660-bfb7-b794dfa35e4c	WH-DELHI-01	Zone-A	A3	S1	BIN-112	ambient	21.73	40.60	Auto-recorded on intake.	2026-06-24 14:31:40.658941+00	2026-06-24 14:31:40.658941+00	2026-06-24 14:31:40.658941+00
a3f320f1-da9e-409a-a611-0f6cbda568e0	1091fc23-0cbd-4522-b45b-999481193061	WH-MUMBAI-02	Zone-B	A4	S2	BIN-113	ambient	25.15	67.42	Auto-recorded on intake.	2026-06-24 14:31:40.660561+00	2026-06-24 14:31:40.660561+00	2026-06-24 14:31:40.660561+00
46dea939-40c8-46a0-8d32-165e250770f6	cf0e4b36-01db-4118-a3a4-5ba93c8ad80d	WH-DELHI-01	Cold-Room-2	A1	S4	BIN-115	ambient	26.16	46.58	Auto-recorded on intake.	2026-06-24 14:31:40.662279+00	2026-06-24 14:31:40.662279+00	2026-06-24 14:31:40.662279+00
4b5ee6c4-c5ff-4814-9871-1694267770b4	90836731-ca74-4cc0-9ba0-586cbaa6e231	WH-MUMBAI-02	Frozen-Bay	A2	S1	BIN-116	ambient	18.96	65.68	Auto-recorded on intake.	2026-06-24 14:31:40.663609+00	2026-06-24 14:31:40.663609+00	2026-06-24 14:31:40.663609+00
d49cb916-2cb0-4c11-b65a-2d750e99a7dd	91465d53-29c8-42fe-8e9f-b3c09439d891	WH-BANGALORE-03	Ambient-Rack-3	A3	S2	BIN-117	ambient	23.81	46.01	Auto-recorded on intake.	2026-06-24 14:31:40.665206+00	2026-06-24 14:31:40.665206+00	2026-06-24 14:31:40.665206+00
271fba8f-0210-4982-b9e0-5955aac70237	e9eaa4b2-56cf-4fa0-8001-30bd56a910ba	WH-DELHI-01	Zone-A	A4	S3	BIN-118	ambient	21.18	40.16	Auto-recorded on intake.	2026-06-24 14:31:40.667121+00	2026-06-24 14:31:40.667121+00	2026-06-24 14:31:40.667121+00
e332a502-dccc-430e-b0cc-8c3072822f96	f643b03b-7436-4300-9868-72f0148667f3	WH-MUMBAI-02	Zone-B	A5	S4	BIN-119	ambient	22.13	61.82	Auto-recorded on intake.	2026-06-24 14:31:40.668788+00	2026-06-24 14:31:40.668788+00	2026-06-24 14:31:40.668788+00
f0939b0a-1d13-4101-ba6d-be33a983f17f	422f517d-ec7f-4857-aed5-a0d0d73f15e7	WH-BANGALORE-03	Cold-Room-1	A1	S1	BIN-120	refrigerated	7.43	59.71	Auto-recorded on intake.	2026-06-24 14:31:40.670408+00	2026-06-24 14:31:40.670408+00	2026-06-24 14:31:40.670408+00
3ecbdbea-0cc6-4a86-921d-cf7d6230dd09	0e64e0e2-9d86-49b2-8075-9386e80cf21c	WH-DELHI-01	Cold-Room-2	A2	S2	BIN-121	ambient	27.86	57.20	Auto-recorded on intake.	2026-06-24 14:31:40.671761+00	2026-06-24 14:31:40.671761+00	2026-06-24 14:31:40.671761+00
361004cb-0f3f-496c-892c-1de23e2110b8	f95afaa0-c93b-45ff-b280-6722cd1c724d	WH-MUMBAI-02	Frozen-Bay	A3	S3	BIN-122	refrigerated	5.63	68.99	Auto-recorded on intake.	2026-06-24 14:31:40.673139+00	2026-06-24 14:31:40.673139+00	2026-06-24 14:31:40.673139+00
40620fb7-7e80-4743-b0e6-d7f5056f7e1c	4b7c5b68-4bee-44fc-9a81-ba30dd8e876d	WH-BANGALORE-03	Ambient-Rack-3	A4	S4	BIN-123	refrigerated	2.11	45.00	Auto-recorded on intake.	2026-06-24 14:31:40.674618+00	2026-06-24 14:31:40.674618+00	2026-06-24 14:31:40.674618+00
4c8ead50-d019-4cb2-ab3d-1a64bc94907e	64488bf3-4d52-41e7-9bd4-c6de6231caff	WH-DELHI-01	Zone-A	A5	S1	BIN-124	ambient	23.18	56.29	Auto-recorded on intake.	2026-06-24 14:31:40.676284+00	2026-06-24 14:31:40.676284+00	2026-06-24 14:31:40.676284+00
b7cfc325-7922-4147-a4bf-21d8f65d6cef	7d794e28-dd45-43f1-9d10-b83ec8f8abd6	WH-DELHI-01	Zone-A	A1	S1	BIN-100	refrigerated	6.26	66.93	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
03a24a58-8e57-46b8-b37d-745e3f177074	ce64a18e-19e3-4fe8-9db9-dc1e7eab0dba	WH-MUMBAI-02	Zone-B	A2	S2	BIN-101	refrigerated	3.70	66.54	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
24bd8244-ee11-4bfa-bba5-c8469ea4bdba	742f9e7e-b842-4e68-b9e2-d4f19cb89ed1	WH-BANGALORE-03	Cold-Room-1	A3	S3	BIN-102	refrigerated	7.58	53.30	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
9989d099-84b9-4684-8320-2a9f6cddbb86	c3460235-b703-4b9a-92bc-edbad2e62924	WH-DELHI-01	Cold-Room-2	A4	S4	BIN-103	refrigerated	2.24	66.82	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
bcb487db-c7b0-4187-9262-834565a2b298	50fb6d07-6219-47f3-9f9f-878534c92fb5	WH-MUMBAI-02	Frozen-Bay	A5	S1	BIN-104	ambient	23.61	61.38	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
41626435-f47c-4ada-a8de-b13c3eb19a11	40569013-98ec-4da6-9be2-5a51744559fd	WH-BANGALORE-03	Ambient-Rack-3	A1	S2	BIN-105	refrigerated	4.29	60.84	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
2840ed33-d303-4f8b-9b26-a715f3fcc625	d58109a8-b8fe-44d3-baa9-13e50c1c9a33	WH-DELHI-01	Zone-A	A2	S3	BIN-106	ambient	21.10	56.37	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
8712aefa-cf5f-431f-8274-5cfc4a07f494	007abc33-245d-470c-8e58-3014aacd36f2	WH-MUMBAI-02	Zone-B	A3	S4	BIN-107	ambient	22.30	56.73	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
3172f13d-34f9-43cf-872e-2dd4f39416ec	8cc23309-11e7-43bb-81cf-0b47abe33505	WH-BANGALORE-03	Cold-Room-1	A4	S1	BIN-108	ambient	22.02	46.56	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
ab39fc31-6186-452f-ac23-93de6b4390a3	8c0a3645-0118-4909-ac22-8aeebb844028	WH-DELHI-01	Cold-Room-2	A5	S2	BIN-109	ambient	20.48	56.70	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
2361ad61-7565-4afa-8fb3-bacc2a610966	8816c74d-f540-4c87-b898-4952076cfe52	WH-MUMBAI-02	Frozen-Bay	A1	S3	BIN-110	ambient	19.97	64.42	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
438ca085-4dbf-4cee-b774-bd2d46cdb88e	973613c3-6985-40f7-99fe-59a17f56e043	WH-BANGALORE-03	Ambient-Rack-3	A2	S4	BIN-111	ambient	20.22	66.66	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
fff90644-5133-4798-8b70-679e48e41a8d	5e136600-e2ee-4ab7-ab30-68e788af7722	WH-DELHI-01	Zone-A	A3	S1	BIN-112	ambient	23.70	64.98	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
5c88d60e-48f8-4b2c-9585-e9ddb1a38ab5	02a4ec16-a3c4-45d8-93af-c52745daebc9	WH-MUMBAI-02	Zone-B	A4	S2	BIN-113	ambient	20.21	61.94	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
b75d7d28-64c2-4578-bd62-43ed886ea652	fb05b148-bd2b-4f1d-937e-66513bc46ba8	WH-BANGALORE-03	Cold-Room-1	A5	S3	BIN-114	ambient	21.49	57.83	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
cd64137a-c0c5-418a-94f8-9c69519a12a9	af992d56-d7d5-4588-a643-6b283216cc59	WH-DELHI-01	Cold-Room-2	A1	S4	BIN-115	ambient	20.29	51.23	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
51f9d294-8caa-44fa-b237-da60aaed9ffc	ab240a4e-6caf-41d2-a793-ceef3d00131e	WH-MUMBAI-02	Frozen-Bay	A2	S1	BIN-116	ambient	24.30	45.10	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
c51d2dae-43d1-47be-8ce8-4fc3dc0d3919	79318c4c-0ee9-48e6-8b34-b9600fa345ef	WH-BANGALORE-03	Ambient-Rack-3	A3	S2	BIN-117	ambient	27.00	57.17	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
fe79eeed-8566-4f89-9003-2613e89d23bd	c7efe4b7-3c70-4fad-976c-542cef8fcc6c	WH-DELHI-01	Zone-A	A4	S3	BIN-118	ambient	23.64	52.79	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
a0a7c60b-b4ee-4052-b66c-c162828f0e61	2dc76abb-94d9-4416-8d88-6fce79af77ff	WH-MUMBAI-02	Zone-B	A5	S4	BIN-119	frozen	-18.25	53.76	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
5d2431b9-1dcb-4468-9de7-629e04c613c2	7b151aec-98d0-4492-a3af-cefa373d4a0d	WH-BANGALORE-03	Cold-Room-1	A1	S1	BIN-120	refrigerated	3.01	41.73	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
7e4c72da-2cd2-43b2-a06f-2bf44f6574b6	380df1be-e27b-473b-80bf-727c77184720	WH-DELHI-01	Cold-Room-2	A2	S2	BIN-121	ambient	21.00	55.30	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
c4723d5b-2062-4c6b-8c5d-242f6f3ec233	6097417e-6ae3-48f9-8d69-cd1841eac542	WH-MUMBAI-02	Frozen-Bay	A3	S3	BIN-122	refrigerated	2.17	43.64	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
ecd38168-f48d-45d1-8557-e2119370f7c0	6ca3bed0-b39b-4b3d-8353-84cdf44f8d26	WH-BANGALORE-03	Ambient-Rack-3	A4	S4	BIN-123	refrigerated	7.19	57.49	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
8f0836ff-a23f-452a-8ae8-dde57ab60fd3	6fc21afd-93ec-458c-9ddc-5c53d61250d6	WH-DELHI-01	Zone-A	A5	S1	BIN-124	ambient	26.75	46.48	Auto-recorded on intake. Temp/humidity from IoT sensor.	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00	2026-06-24 14:38:06.817992+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: expiry_user
--

COPY public.users (id, email, name, hashed_password, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: barcode_scans barcode_scans_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.barcode_scans
    ADD CONSTRAINT barcode_scans_pkey PRIMARY KEY (id);


--
-- Name: data_quality_issues data_quality_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.data_quality_issues
    ADD CONSTRAINT data_quality_issues_pkey PRIMARY KEY (id);


--
-- Name: ingredients ingredients_name_key; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_name_key UNIQUE (name);


--
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: manual_reviews manual_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.manual_reviews
    ADD CONSTRAINT manual_reviews_pkey PRIMARY KEY (id);


--
-- Name: ml_predictions ml_predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.ml_predictions
    ADD CONSTRAINT ml_predictions_pkey PRIMARY KEY (id);


--
-- Name: ocr_results ocr_results_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.ocr_results
    ADD CONSTRAINT ocr_results_pkey PRIMARY KEY (id);


--
-- Name: preservatives preservatives_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.preservatives
    ADD CONSTRAINT preservatives_pkey PRIMARY KEY (id);


--
-- Name: product_images product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_pkey PRIMARY KEY (id);


--
-- Name: product_ingredients product_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_pkey PRIMARY KEY (id);


--
-- Name: product_ingredients product_ingredients_product_id_ingredient_id_key; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_product_id_ingredient_id_key UNIQUE (product_id, ingredient_id);


--
-- Name: product_packaging product_packaging_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.product_packaging
    ADD CONSTRAINT product_packaging_pkey PRIMARY KEY (id);


--
-- Name: products products_barcode_key; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_barcode_key UNIQUE (barcode);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: products products_sku_key; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_sku_key UNIQUE (sku);


--
-- Name: scan_sessions scan_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.scan_sessions
    ADD CONSTRAINT scan_sessions_pkey PRIMARY KEY (id);


--
-- Name: shelf_life_rules shelf_life_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.shelf_life_rules
    ADD CONSTRAINT shelf_life_rules_pkey PRIMARY KEY (id);


--
-- Name: storage_contexts storage_contexts_inventory_item_id_key; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.storage_contexts
    ADD CONSTRAINT storage_contexts_inventory_item_id_key UNIQUE (inventory_item_id);


--
-- Name: storage_contexts storage_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.storage_contexts
    ADD CONSTRAINT storage_contexts_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_logs_actor_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_audit_logs_actor_id ON public.audit_logs USING btree (actor_id);


--
-- Name: idx_audit_logs_entity_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_audit_logs_entity_id ON public.audit_logs USING btree (entity_id);


--
-- Name: idx_audit_logs_event_type; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_audit_logs_event_type ON public.audit_logs USING btree (event_type);


--
-- Name: idx_audit_logs_occurred_at; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_audit_logs_occurred_at ON public.audit_logs USING btree (occurred_at DESC);


--
-- Name: idx_barcode_scans_product_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_barcode_scans_product_id ON public.barcode_scans USING btree (product_id);


--
-- Name: idx_barcode_scans_raw_barcode; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_barcode_scans_raw_barcode ON public.barcode_scans USING btree (raw_barcode);


--
-- Name: idx_barcode_scans_scan_status; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_barcode_scans_scan_status ON public.barcode_scans USING btree (scan_status);


--
-- Name: idx_data_quality_issues_inventory_item_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_data_quality_issues_inventory_item_id ON public.data_quality_issues USING btree (inventory_item_id);


--
-- Name: idx_data_quality_issues_issue_type; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_data_quality_issues_issue_type ON public.data_quality_issues USING btree (issue_type);


--
-- Name: idx_data_quality_issues_resolution; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_data_quality_issues_resolution ON public.data_quality_issues USING btree (resolution_status);


--
-- Name: idx_data_quality_issues_severity; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_data_quality_issues_severity ON public.data_quality_issues USING btree (severity);


--
-- Name: idx_ingredients_name; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_ingredients_name ON public.ingredients USING btree (normalized_name);


--
-- Name: idx_ingredients_type; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_ingredients_type ON public.ingredients USING btree (ingredient_type);


--
-- Name: idx_inventory_items_batch_number; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_inventory_items_batch_number ON public.inventory_items USING btree (batch_number);


--
-- Name: idx_inventory_items_expiry_date; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_inventory_items_expiry_date ON public.inventory_items USING btree (expiry_date);


--
-- Name: idx_inventory_items_pipeline_status; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_inventory_items_pipeline_status ON public.inventory_items USING btree (pipeline_status);


--
-- Name: idx_inventory_items_product_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_inventory_items_product_id ON public.inventory_items USING btree (product_id);


--
-- Name: idx_manual_reviews_human_decision; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_manual_reviews_human_decision ON public.manual_reviews USING btree (human_decision);


--
-- Name: idx_manual_reviews_inventory_item_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_manual_reviews_inventory_item_id ON public.manual_reviews USING btree (inventory_item_id);


--
-- Name: idx_manual_reviews_review_status; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_manual_reviews_review_status ON public.manual_reviews USING btree (review_status);


--
-- Name: idx_ml_predictions_inventory_item_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_ml_predictions_inventory_item_id ON public.ml_predictions USING btree (inventory_item_id);


--
-- Name: idx_ml_predictions_predicted_decision; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_ml_predictions_predicted_decision ON public.ml_predictions USING btree (predicted_decision);


--
-- Name: idx_ml_predictions_prediction_status; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_ml_predictions_prediction_status ON public.ml_predictions USING btree (prediction_status);


--
-- Name: idx_ocr_results_inventory_item_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_ocr_results_inventory_item_id ON public.ocr_results USING btree (inventory_item_id);


--
-- Name: idx_ocr_results_ocr_status; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_ocr_results_ocr_status ON public.ocr_results USING btree (ocr_status);


--
-- Name: idx_ocr_results_product_image_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_ocr_results_product_image_id ON public.ocr_results USING btree (product_image_id);


--
-- Name: idx_preservatives_ingredient_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_preservatives_ingredient_id ON public.preservatives USING btree (ingredient_id);


--
-- Name: idx_preservatives_type; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_preservatives_type ON public.preservatives USING btree (preservative_type);


--
-- Name: idx_product_images_processing_status; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_product_images_processing_status ON public.product_images USING btree (processing_status);


--
-- Name: idx_product_images_product_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_product_images_product_id ON public.product_images USING btree (product_id);


--
-- Name: idx_product_ingredients_ingredient_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_product_ingredients_ingredient_id ON public.product_ingredients USING btree (ingredient_id);


--
-- Name: idx_product_ingredients_product_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_product_ingredients_product_id ON public.product_ingredients USING btree (product_id);


--
-- Name: idx_product_packaging_product_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_product_packaging_product_id ON public.product_packaging USING btree (product_id);


--
-- Name: idx_product_packaging_type; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_product_packaging_type ON public.product_packaging USING btree (packaging_type);


--
-- Name: idx_products_barcode; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_products_barcode ON public.products USING btree (barcode);


--
-- Name: idx_products_brand; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_products_brand ON public.products USING btree (brand);


--
-- Name: idx_products_category; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_products_category ON public.products USING btree (category);


--
-- Name: idx_products_sku; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_products_sku ON public.products USING btree (sku);


--
-- Name: idx_scan_sessions_inventory_item_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_scan_sessions_inventory_item_id ON public.scan_sessions USING btree (inventory_item_id);


--
-- Name: idx_scan_sessions_status; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_scan_sessions_status ON public.scan_sessions USING btree (session_status);


--
-- Name: idx_shelf_life_rules_category; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_shelf_life_rules_category ON public.shelf_life_rules USING btree (category);


--
-- Name: idx_shelf_life_rules_is_active; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_shelf_life_rules_is_active ON public.shelf_life_rules USING btree (is_active);


--
-- Name: idx_shelf_life_rules_storage_type; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_shelf_life_rules_storage_type ON public.shelf_life_rules USING btree (storage_type);


--
-- Name: idx_storage_contexts_inventory_item_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_storage_contexts_inventory_item_id ON public.storage_contexts USING btree (inventory_item_id);


--
-- Name: idx_storage_contexts_warehouse_id; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_storage_contexts_warehouse_id ON public.storage_contexts USING btree (warehouse_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: expiry_user
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: barcode_scans barcode_scans_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.barcode_scans
    ADD CONSTRAINT barcode_scans_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: data_quality_issues data_quality_issues_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.data_quality_issues
    ADD CONSTRAINT data_quality_issues_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: inventory_items inventory_items_barcode_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_barcode_scan_id_fkey FOREIGN KEY (barcode_scan_id) REFERENCES public.barcode_scans(id) ON DELETE SET NULL;


--
-- Name: inventory_items inventory_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: manual_reviews manual_reviews_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.manual_reviews
    ADD CONSTRAINT manual_reviews_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: ml_predictions ml_predictions_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.ml_predictions
    ADD CONSTRAINT ml_predictions_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: ocr_results ocr_results_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.ocr_results
    ADD CONSTRAINT ocr_results_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE SET NULL;


--
-- Name: ocr_results ocr_results_product_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.ocr_results
    ADD CONSTRAINT ocr_results_product_image_id_fkey FOREIGN KEY (product_image_id) REFERENCES public.product_images(id) ON DELETE CASCADE;


--
-- Name: preservatives preservatives_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.preservatives
    ADD CONSTRAINT preservatives_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE SET NULL;


--
-- Name: product_images product_images_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_ingredients product_ingredients_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE RESTRICT;


--
-- Name: product_ingredients product_ingredients_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_packaging product_packaging_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.product_packaging
    ADD CONSTRAINT product_packaging_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: scan_sessions scan_sessions_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.scan_sessions
    ADD CONSTRAINT scan_sessions_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE SET NULL;


--
-- Name: storage_contexts storage_contexts_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: expiry_user
--

ALTER TABLE ONLY public.storage_contexts
    ADD CONSTRAINT storage_contexts_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict OqwvJO6d63HS7gj9Wedt5hPufHsNYae3lSANMKck06yGaApKrfjemnBiH4kFZmZ



# AI-Powered Expiry Date Validation System — Development & Integration Guide

This document summarizes the current status of the project integration, the database architecture updates, and instructions for running and verifying the system.

---

## 🛠️ Work Accomplished So Far

### 1. Codebase Syncing
- Synced the workspace to track your teammate's remote branch (`origin/Harish`), containing updated database models (`catalog.py`, `operations.py`), Pydantic schemas, and the Next.js Frontend.
- Integrated the Docker container configurations seamlessly with these updates.

### 2. Teammate Model Database Reconstruction
- Rebuilt the PostgreSQL database schema from scratch matching the teammate's model schemas exactly.
- Re-initialized all **26 database tables** (such as `products`, `inventory_items`, `ocr_results`, `suppliers`, etc.).
- Pre-populated the catalog with **56 realistic grocery and regional products** (via `seed_products.py`, `seed_south_indian_products.py`, and `seed_mock_products.py`).

### 3. OCR Scanner Optimization
- Modified `paddle_ocr_service.py` (`use_textline_orientation=False`) to disable document layout warping correction (`UVDoc`).
- **Impact**: Bypassed heavy Hugging Face downloads and dynamic C++ compilation steps during initial scan, reducing scan initialization time from several minutes to under **3 seconds**.

### 4. Database Persistence Alignment
- Resolved relationship mapping conflicts (`ScanSession`, `Supplier`, `Warehouse`, `InventoryItem`, `ProductImage`) between the SQLAlchemy models and database tables to ensure clean `INSERT` / `UPDATE` queries.

---

## 🗄️ Database Table Structure (26 Tables)

The database schema is fully aligned with the application models:
```
 Schema |               Name               | Type  |    Owner    
--------+----------------------------------+-------+-------------
 public | audit_logs                       | table | expiry_user
 public | barcode_scans                    | table | expiry_user
 public | external_product_cache           | table | expiry_user
 public | external_product_enrichment_logs | table | expiry_user
 public | inventory_items                  | table | expiry_user
 public | inventory_movements              | table | expiry_user
 public | manual_reviews                   | table | expiry_user
 public | ml_predictions                   | table | expiry_user
 public | ocr_results                      | table | expiry_user
 public | product_allergens                | table | expiry_user
 public | product_identifiers              | table | expiry_user
 public | product_images                   | table | expiry_user
 public | product_ingredients              | table | expiry_user
 public | product_lookup_logs              | table | expiry_user
 public | product_nutrition                | table | expiry_user
 public | product_question_logs            | table | expiry_user
 public | product_storage_requirements     | table | expiry_user
 public | products                         | table | expiry_user
 public | scan_alerts                      | table | expiry_user
 public | scan_sessions                    | table | expiry_user
 public | storage_contexts                 | table | expiry_user
 public | storage_locations                | table | expiry_user
 public | suppliers                        | table | expiry_user
 public | unknown_product_requests         | table | expiry_user
 public | users                            | table | expiry_user
 public | warehouses                       | table | expiry_user
```

---

## 🚦 How to Run & Verify the Project

### 1. Show All Database Tables
Verify tables inside the PostgreSQL container:
```powershell
docker exec -i expiry_postgres psql -U expiry_user -d expiry_db -c "\dt"
```

### 2. Open the Web Scanner
Navigate to:
**`http://localhost:8050`** (Dash backend interactive scan interface)

*Note: The main Frontend runs at `http://localhost:3000`.*

### 3. Scan a Product Label
Upload a test label image (e.g., from your webcam or `AI_expiry_date/AI_expiry_date/backend_v2/uploads/labels/roi_crop_test.jpg`) and click **Scan/Upload**.

### 4. Query the Persisted Details in Database

Query OCR Results table:
```powershell
docker exec -i expiry_postgres psql -U expiry_user -d expiry_db -c "SELECT id, ocr_engine, raw_text, detected_mfg_text, detected_expiry_text, date_parse_confidence FROM ocr_results ORDER BY created_at DESC LIMIT 5;"
```

Query Inventory Items table:
```powershell
docker exec -i expiry_postgres psql -U expiry_user -d expiry_db -c "SELECT id, product_id, batch_number, manufacturing_date, expiry_date FROM inventory_items ORDER BY created_at DESC LIMIT 5;"
```

"""
dev_tools/view_latest_scans.py
Queries the local PostgreSQL database to display the latest scanned inventory items and OCR results.
"""

import sys
import os

# Add parent directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database import SessionLocal
from app.models.inventory_item import InventoryItem
from app.models.ocr_result import OCRResult
from app.models.product import Product

def format_date(d):
    return d.strftime('%Y-%m-%d') if d else "None"

def main():
    db = SessionLocal()
    try:
        print("\n" + "="*80)
        print("  LATEST DATABASE INVENTORY ITEMS & OCR EXTRACTION RESULTS  ")
        print("="*80)

        # Query latest 5 inventory items
        items = db.query(InventoryItem).order_by(InventoryItem.created_at.desc()).limit(5).all()

        if not items:
            print("\n No inventory items found in the database. Scans may not have been saved yet.")
            return

        for idx, item in enumerate(items, 1):
            product = db.query(Product).filter(Product.id == item.product_id).first()
            prod_name = product.name if product else "Unknown Product"
            sku = product.sku if product else "N/A"

            print(f"\n[{idx}] Product: {prod_name} (SKU: {sku})")
            print(f"    - Item ID:          {item.id}")
            print(f"    - Batch Number:     {item.batch_number}")
            print(f"    - Mfg Date:         {format_date(item.manufacturing_date)}")
            print(f"    - Expiry Date:      {format_date(item.expiry_date)}")
            print(f"    - Intake Source:    {item.intake_source}")
            print(f"    - Pipeline Status:  {item.pipeline_status}")
            print(f"    - Status Reason:    {item.status_reason or 'None'}")
            print(f"    - Created At:       {item.created_at}")

            # Associated OCR results
            ocr_res = db.query(OCRResult).filter(OCRResult.inventory_item_id == item.id).first()
            if ocr_res:
                print(f"    - OCR Status:       {ocr_res.ocr_status}")
                print(f"    - OCR Confidence:   {ocr_res.overall_confidence if ocr_res.overall_confidence else 0.0:.2f}")
                print(f"    - Raw OCR Text (Snippet):")
                snippet = ocr_res.raw_text[:120].replace('\n', ' ') if ocr_res.raw_text else ""
                print(f"        \"{snippet}...\"")
            else:
                print("    - OCR Results:      No OCR record linked to this item.")
            print("-"*80)

    except Exception as e:
        print(f"Error querying database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    main()

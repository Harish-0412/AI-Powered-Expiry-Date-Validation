"""
services/ocr_service.py — Interfaces with the OCR pipeline to retrieve raw labels text.
"""

from datetime import datetime
from typing import Optional, Dict, Any, List
from sqlalchemy.orm import Session
from app.models.ocr_result import OCRResult
from app.models.product_image import ProductImage
from app.models.inventory_item import InventoryItem


def trigger_ocr_processing(
    db: Session,
    product_image_id: Any,
    inventory_item_id: Optional[Any] = None,
    ocr_engine: str = "PaddleOCR",
) -> OCRResult:
    """
    Kicks off OCR extraction workflow for a specific product image.
    Updates ProductImage.processing_status to ocr_pending.
    Creates and returns a pending OCRResult record.
    NOW INTEGRATED: Runs the enhanced OCR pipeline using PaddleOCR,
    extracts dates and batch information, updates the inventory item,
    and handles success/failure states.
    """
    image = db.query(ProductImage).filter(ProductImage.id == product_image_id).first()
    if not image:
        raise ValueError(f"ProductImage with ID {product_image_id} not found")

    image.processing_status = "ocr_pending"
    db.commit()

    # Create a pending OCR record
    ocr_record = OCRResult(
        product_image_id=product_image_id,
        inventory_item_id=inventory_item_id,
        ocr_engine=ocr_engine,
        ocr_status="pending",
    )
    db.add(ocr_record)
    db.commit()
    db.refresh(ocr_record)

    # ── INTEGRATION OF OCR EXTRACTION AND STORAGE ────────────────────────────────
    try:
        import os
        import cv2
        from app.services.enhanced_ocr_pipeline import EnhancedOCRPipeline
        
        file_path = image.file_path
        if not file_path:
            raise ValueError("No file path specified for the product image")
            
        # Resolve absolute path
        if not os.path.isabs(file_path):
            file_path = os.path.abspath(file_path)
            
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Product image file not found at: {file_path}")
            
        img = cv2.imread(file_path)
        if img is None:
            raise ValueError(f"Failed to read image file from disk: {file_path}")
            
        pipeline = EnhancedOCRPipeline()
        pipeline_result = pipeline.process_image(img, file_path)
        
        # Prepare text blocks
        extracted_text_blocks = []
        if pipeline_result.mfg_date:
            extracted_text_blocks.append({"label": "MFG", "value": pipeline_result.mfg_date})
        if pipeline_result.expiry_date:
            extracted_text_blocks.append({"label": "EXP", "value": pipeline_result.expiry_date})
        if pipeline_result.batch_number:
            extracted_text_blocks.append({"label": "BATCH", "value": pipeline_result.batch_number})
            
        complete_ocr_processing(
            db=db,
            ocr_record_id=ocr_record.id,
            raw_text=pipeline_result.raw_text,
            extracted_text_blocks=extracted_text_blocks,
            overall_confidence=pipeline_result.confidence,
            ocr_engine_version="1.0"
        )
        
        # Update associated inventory item if present
        if inventory_item_id:
            item = db.query(InventoryItem).filter(InventoryItem.id == inventory_item_id).first()
            if item:
                from datetime import datetime
                
                # Helper to parse YYYY-MM-DD
                def parse_date(date_str: Optional[str]):
                    if not date_str:
                        return None
                    for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%m/%d/%Y", "%d-%m-%Y"):
                        try:
                            return datetime.strptime(date_str, fmt).date()
                        except ValueError:
                            pass
                    return None
                    
                mfg_date_obj = parse_date(pipeline_result.mfg_date)
                exp_date_obj = parse_date(pipeline_result.expiry_date)
                
                if mfg_date_obj:
                    item.manufacturing_date = mfg_date_obj
                    item.date_source = "ocr_vision"
                if exp_date_obj:
                    item.expiry_date = exp_date_obj
                    item.date_source = "ocr_vision"
                if pipeline_result.batch_number and not item.batch_number:
                    item.batch_number = pipeline_result.batch_number
                    
                # Run safety alerts check to determine status (MANUAL_REVIEW vs OCR_COMPLETED)
                if mfg_date_obj and exp_date_obj and exp_date_obj < mfg_date_obj:
                    item.pipeline_status = "MANUAL_REVIEW"
                    item.status_reason = "Date sequence alert: Expiry date is before manufacturing date."
                elif exp_date_obj and exp_date_obj < datetime.now().date():
                    item.pipeline_status = "MANUAL_REVIEW"
                    item.status_reason = f"Product is expired (Expiry date: {exp_date_obj})."
                elif pipeline_result.confidence < 0.5:
                    item.pipeline_status = "MANUAL_REVIEW"
                    item.status_reason = f"Low OCR extraction confidence: {pipeline_result.confidence:.2f}"
                else:
                    item.pipeline_status = "OCR_COMPLETED"
                    
                db.commit()
                
    except Exception as e:
        fail_ocr_processing(db=db, ocr_record_id=ocr_record.id, failure_reason=str(e))
        
    db.refresh(ocr_record)
    return ocr_record


def complete_ocr_processing(
    db: Session,
    ocr_record_id: Any,
    raw_text: str,
    extracted_text_blocks: Optional[List[Dict[str, Any]]] = None,
    overall_confidence: float = 1.0,
    ocr_engine_version: Optional[str] = None,
) -> OCRResult:
    """
    Called when OCR extraction finishes successfully.
    Saves extracted data, updates statuses on both OCRResult and ProductImage.
    """
    ocr_record = db.query(OCRResult).filter(OCRResult.id == ocr_record_id).first()
    if not ocr_record:
        raise ValueError(f"OCRResult record with ID {ocr_record_id} not found")

    ocr_record.raw_text = raw_text
    ocr_record.extracted_text_blocks = extracted_text_blocks or []
    ocr_record.overall_confidence = overall_confidence
    ocr_record.ocr_engine_version = ocr_engine_version
    ocr_record.ocr_status = "completed"
    ocr_record.processed_at = datetime.utcnow()

    # Update associated image state
    if ocr_record.product_image:
        ocr_record.product_image.processing_status = "ocr_completed"

    # Update associated inventory item state if applicable
    if ocr_record.inventory_item:
        ocr_record.inventory_item.pipeline_status = "OCR_COMPLETED"

    db.commit()
    db.refresh(ocr_record)
    return ocr_record


def fail_ocr_processing(
    db: Session,
    ocr_record_id: Any,
    failure_reason: str,
) -> OCRResult:
    """Handles marking OCR extraction as failed."""
    ocr_record = db.query(OCRResult).filter(OCRResult.id == ocr_record_id).first()
    if not ocr_record:
        raise ValueError(f"OCRResult record with ID {ocr_record_id} not found")

    ocr_record.ocr_status = "failed"
    ocr_record.failure_reason = failure_reason
    ocr_record.processed_at = datetime.utcnow()

    if ocr_record.product_image:
        ocr_record.product_image.processing_status = "failed"

    if ocr_record.inventory_item:
        ocr_record.inventory_item.pipeline_status = "MANUAL_REVIEW"
        ocr_record.inventory_item.status_reason = f"OCR Failed: {failure_reason}"

    db.commit()
    db.refresh(ocr_record)
    return ocr_record

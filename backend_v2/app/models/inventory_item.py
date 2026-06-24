"""
models/inventory_item.py — A single batch received during warehouse intake.

Status lifecycle (backend-only — no shelf-life decisions here):
  PENDING_OCR       → batch scanned in, waiting for image processing
  OCR_COMPLETED     → OCR text extracted, waiting for ML
  PENDING_ML_REVIEW → sent to ML team's queue
  ML_COMPLETED      → ML team returned a prediction
  MANUAL_REVIEW     → flagged for human inspection

Final decisions (ACCEPTED, REJECTED, PRIORITY_SALE) come from
the ML team and are stored in the ml_predictions table, NOT here.
"""

import uuid

from sqlalchemy import Column, String, Date, DateTime, ForeignKey, Text, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class InventoryItem(Base):
    __tablename__ = "inventory_items"

    id                  = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)

    # ── Source references ─────────────────────────────────────
    product_id          = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="RESTRICT"), nullable=False)
    barcode_scan_id     = Column(UUID(as_uuid=True), ForeignKey("barcode_scans.id", ondelete="SET NULL"), nullable=True)

    # ── Batch identity ────────────────────────────────────────
    batch_number        = Column(String(100), nullable=True, index=True)

    # ── Dates (entered by warehouse staff or extracted by OCR) ───────────
    # These are raw inputs. The ML team validates and uses them.
    manufacturing_date  = Column(Date, nullable=True)
    expiry_date         = Column(Date, nullable=True)

    # ── Backend pipeline status ───────────────────────────────
    # PENDING_OCR | OCR_COMPLETED | PENDING_ML_REVIEW | ML_COMPLETED | MANUAL_REVIEW
    pipeline_status     = Column(String(30), nullable=False, default="PENDING_OCR", index=True)
    status_reason       = Column(Text, nullable=True)  # reason for current status

    # ── Quantity ──────────────────────────────────────────────
    quantity            = Column(Integer, nullable=True, default=1)
    unit                = Column(String(20), nullable=True)  # units | cartons | pallets

    # ── Notes ─────────────────────────────────────────────────
    intake_notes        = Column(Text, nullable=True)

    # ── Timestamps ────────────────────────────────────────────
    intake_at           = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    created_at          = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at          = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # ── Relationships ─────────────────────────────────────────
    product             = relationship("Product",       back_populates="inventory_items")
    barcode_scan        = relationship("BarcodeScan",   back_populates="inventory_items")
    storage_context     = relationship("StorageContext", back_populates="inventory_item", uselist=False)
    ocr_results         = relationship("OCRResult",     back_populates="inventory_item")
    ml_predictions      = relationship("MLPrediction",  back_populates="inventory_item")
    manual_reviews      = relationship("ManualReview",  back_populates="inventory_item")

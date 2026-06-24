"""
models/ocr_result.py — Stores raw OCR extraction output.

OCR results are written here by the OCR pipeline (future phase).
The backend team stores whatever the OCR engine returns.
The ML team reads this table to extract manufacturing/expiry dates.
No date parsing or shelf-life logic here.
"""

import uuid

from sqlalchemy import Column, String, DateTime, ForeignKey, Text, Float, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class OCRResult(Base):
    __tablename__ = "ocr_results"

    id                  = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)

    # ── Source references ─────────────────────────────────────
    product_image_id    = Column(UUID(as_uuid=True), ForeignKey("product_images.id", ondelete="CASCADE"), nullable=False)
    inventory_item_id   = Column(UUID(as_uuid=True), ForeignKey("inventory_items.id", ondelete="SET NULL"), nullable=True)

    # ── Raw OCR output ────────────────────────────────────────
    raw_text            = Column(Text,    nullable=True)   # full text extracted from image
    ocr_engine          = Column(String(100), nullable=True)  # e.g. "tesseract-5.3", "google-vision"
    ocr_engine_version  = Column(String(50),  nullable=True)

    # ── Extracted date candidates (raw strings, not parsed dates) ──────────
    # These are raw strings found by OCR. The ML team parses them.
    extracted_text_blocks = Column(JSON, nullable=True)
    # e.g. [{"label": "MFG", "value": "01/05/2026"}, {"label": "EXP", "value": "01/11/2026"}]

    # ── Confidence ────────────────────────────────────────────
    overall_confidence  = Column(Float, nullable=True)   # 0.0–1.0

    # ── Processing status ─────────────────────────────────────
    # pending    = extraction not yet run
    # completed  = extraction finished
    # failed     = extraction failed (see failure_reason)
    ocr_status          = Column(String(30), nullable=False, default="pending")
    failure_reason      = Column(Text,   nullable=True)

    # ── Timestamps ────────────────────────────────────────────
    processed_at        = Column(DateTime(timezone=True), nullable=True)
    created_at          = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at          = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # ── Relationships ─────────────────────────────────────────
    product_image       = relationship("ProductImage", back_populates="ocr_results")
    inventory_item      = relationship("InventoryItem", back_populates="ocr_results")

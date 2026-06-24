"""
models/manual_review.py — Human review record for flagged batches.

Created when an inventory item is escalated to MANUAL_REVIEW status
either because OCR failed, ML confidence was too low, or a warehouse
supervisor overrides an automated decision.
"""

import uuid

from sqlalchemy import Column, String, Date, DateTime, ForeignKey, Text, Float
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class ManualReview(Base):
    __tablename__ = "manual_reviews"

    id                      = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    inventory_item_id       = Column(UUID(as_uuid=True), ForeignKey("inventory_items.id", ondelete="CASCADE"), nullable=False, index=True)

    # ── Reviewer ──────────────────────────────────────────────
    reviewer_id             = Column(String(200), nullable=True)   # user ID or name
    reviewer_role           = Column(String(100), nullable=True)   # warehouse_staff | supervisor | qa

    # ── Human-entered corrected dates ────────────────────────
    corrected_mfg_date      = Column(Date, nullable=True)
    corrected_expiry_date   = Column(Date, nullable=True)

    # ── Human decision ────────────────────────────────────────
    # ACCEPTED | PRIORITY_SALE | REJECTED | ESCALATE_TO_QA
    human_decision          = Column(String(30), nullable=True, index=True)
    review_notes            = Column(Text, nullable=True)

    # ── Reason for escalation ─────────────────────────────────
    escalation_reason       = Column(Text, nullable=True)
    # e.g. "OCR failed — label torn", "ML confidence 0.42 — below threshold"

    # ── Review status ─────────────────────────────────────────
    # pending | in_progress | completed | escalated
    review_status           = Column(String(20), nullable=False, default="pending", index=True)

    # ── Timestamps ────────────────────────────────────────────
    reviewed_at             = Column(DateTime(timezone=True), nullable=True)
    created_at              = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at              = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # ── Relationships ─────────────────────────────────────────
    inventory_item          = relationship("InventoryItem", back_populates="manual_reviews")

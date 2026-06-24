"""
models/product.py — Master product catalogue.

One Product can have many:
  - BarcodeScan records (each physical scan event)
  - ProductImage records (uploaded label / product photos)
  - InventoryItem records (each warehouse intake batch)
"""

import uuid

from sqlalchemy import Boolean, Column, String, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Product(Base):
    __tablename__ = "products"

    # ── Identity ─────────────────────────────────────────────
    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    name            = Column(String(255),  nullable=False)
    brand           = Column(String(255),  nullable=True)
    sku             = Column(String(100),  unique=True, index=True, nullable=False)
    barcode         = Column(String(100),  unique=True, index=True, nullable=False)
    barcode_type    = Column(String(20),   nullable=False, default="EAN13")
                   # EAN13 | EAN8 | UPC-A | QR | CODE128 | DATAMATRIX

    # ── Classification ────────────────────────────────────────
    category        = Column(String(100),  nullable=True)
    description     = Column(Text,         nullable=True)

    # ── Storage ───────────────────────────────────────────────
    default_storage_type = Column(String(50), nullable=True)
                   # ambient | refrigerated | frozen | controlled

    # ── Media ─────────────────────────────────────────────────
    image_url       = Column(String(500),  nullable=True)
                   # URL to primary product image (populated by image upload)

    # ── Status ────────────────────────────────────────────────
    is_active       = Column(Boolean, default=True, nullable=False)

    # ── Timestamps ────────────────────────────────────────────
    created_at      = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at      = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # ── Relationships ─────────────────────────────────────────
    barcode_scans   = relationship("BarcodeScan",  back_populates="product", cascade="all, delete-orphan")
    product_images  = relationship("ProductImage", back_populates="product", cascade="all, delete-orphan")
    inventory_items = relationship("InventoryItem", back_populates="product")

    def __repr__(self):
        return f"<Product sku={self.sku} name={self.name!r}>"

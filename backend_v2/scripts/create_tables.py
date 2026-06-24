"""
scripts/create_tables.py — Create all database tables.

Safe to run multiple times — SQLAlchemy's create_all uses
IF NOT EXISTS under the hood so existing tables are never dropped.

Usage:
    python scripts/create_tables.py
"""

import sys
import os

# Ensure the project root is on the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.database import Base, engine, check_db_connection
from app.models import (  # noqa: F401 — imports register models on Base.metadata
    Product, BarcodeScan, ProductImage, OCRResult,
    InventoryItem, StorageContext, MLPrediction,
    ManualReview, AuditLog,
)


def main():
    print("Checking database connection...")
    if not check_db_connection():
        print("ERROR: Cannot connect to the database.")
        print("Make sure Docker is running: docker-compose up -d")
        sys.exit(1)

    print("Creating tables (IF NOT EXISTS)...")
    Base.metadata.create_all(bind=engine)

    # List what was registered
    table_names = sorted(Base.metadata.tables.keys())
    print(f"\n✅ {len(table_names)} tables ready:")
    for name in table_names:
        print(f"   {name}")


if __name__ == "__main__":
    main()

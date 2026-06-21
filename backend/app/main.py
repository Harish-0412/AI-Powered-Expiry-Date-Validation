from fastapi import FastAPI
from app.config.database import Base, engine

# Import all models to register them on Base.metadata before create_all
from app.models.product import Product
from app.models.user import User
from app.models.inventory import InventoryItem

from app.routes import products, auth, inventory

# Ensure all database tables are created on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="AI-Powered Expiry Date Validation API",
    description="Backend service for validating products and expiry dates.",
    version="1.0.0"
)

@app.get("/health", tags=["health"])
def health_check():
    return {"status": "ok"}

app.include_router(products.router, prefix="/products", tags=["products"])
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(inventory.router, prefix="/inventory", tags=["inventory"])

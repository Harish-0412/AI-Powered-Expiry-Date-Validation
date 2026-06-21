from fastapi import FastAPI
from app.config.database import Base, engine
from app.models.product import Product # Critical for registering the model to Base.metadata
from app.routes import products

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

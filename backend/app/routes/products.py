from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.config.database import get_db
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductUpdate, ProductOut

router = APIRouter()

@router.post("/", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
def create_product(product_in: ProductCreate, db: Session = Depends(get_db)):
    # Check if SKU already exists
    existing_sku = db.query(Product).filter(Product.sku == product_in.sku).first()
    if existing_sku:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Product with SKU '{product_in.sku}' already exists."
        )

    # Check if barcode already exists
    if product_in.barcode:
        existing_barcode = db.query(Product).filter(Product.barcode == product_in.barcode).first()
        if existing_barcode:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Product with barcode '{product_in.barcode}' already exists."
            )

    new_product = Product(
        sku=product_in.sku,
        name=product_in.name,
        category=product_in.category,
        barcode=product_in.barcode,
        image_url=product_in.image_url
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return new_product

@router.get("/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with ID {product_id} not found."
        )
    return product

@router.put("/{product_id}", response_model=ProductOut)
def update_product(product_id: int, product_in: ProductUpdate, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with ID {product_id} not found."
        )

    # If barcode is updated, verify uniqueness
    if product_in.barcode:
        existing_barcode = db.query(Product).filter(
            Product.barcode == product_in.barcode,
            Product.id != product_id
        ).first()
        if existing_barcode:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Product with barcode '{product_in.barcode}' already exists."
            )

    # Update only fields that are provided in the request
    update_data = product_in.model_dump(exclude_unset=True) if hasattr(product_in, "model_dump") else product_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)

    db.commit()
    db.refresh(product)
    return product

@router.get("/", response_model=List[ProductOut])
def list_products(skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    products = db.query(Product).offset(skip).limit(limit).all()
    return products

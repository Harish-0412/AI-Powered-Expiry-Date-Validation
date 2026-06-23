from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.models.inventory import InventoryItem
from app.models.product import Product
from app.models.user import User
from app.schemas.inventory import InventoryItemCreate, InventoryItemOut
from app.services.auth import get_current_user

router = APIRouter()

@router.post("/", response_model=InventoryItemOut, status_code=status.HTTP_201_CREATED)
def create_inventory_item(
    item_in: InventoryItemCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify product exists
    product = db.query(Product).filter(Product.id == item_in.product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with ID {item_in.product_id} not found"
        )
        
    new_item = InventoryItem(
        product_id=item_in.product_id,
        batch_number=item_in.batch_number,
        manufacturing_date=item_in.manufacturing_date,
        expiry_date=item_in.expiry_date
    )
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item

@router.get("/{item_id}", response_model=InventoryItemOut)
def get_inventory_item(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(InventoryItem).filter(InventoryItem.id == item_id).first()
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Inventory item with ID {item_id} not found"
        )
    return item

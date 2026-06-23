from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

class InventoryItemBase(BaseModel):
    product_id: int
    batch_number: Optional[str] = None
    manufacturing_date: Optional[date] = None
    expiry_date: Optional[date] = None

class InventoryItemCreate(InventoryItemBase):
    pass

class InventoryItemOut(InventoryItemBase):
    id: int
    intake_timestamp: datetime
    current_status: str
    decision_reason: Optional[str] = None

    class Config:
        orm_mode = True
        from_attributes = True

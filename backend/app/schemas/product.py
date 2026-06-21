from pydantic import BaseModel
from typing import Optional

class ProductBase(BaseModel):
    sku: str
    name: str
    category: Optional[str] = None
    barcode: Optional[str] = None
    image_url: Optional[str] = None

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    barcode: Optional[str] = None
    image_url: Optional[str] = None

class ProductOut(ProductBase):
    id: int

    class Config:
        orm_mode = True
        from_attributes = True

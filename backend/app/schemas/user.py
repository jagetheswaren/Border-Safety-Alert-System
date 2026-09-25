from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import datetime

class UserBase(BaseModel):
    email: str
    role: Literal["FIELD_USER", "OPERATOR", "ADMIN"] = "FIELD_USER"
    is_active: Optional[bool] = True

class UserCreate(UserBase):
    password: str = Field(min_length=10, max_length=72)

class UserUpdate(BaseModel):
    email: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None

class UserInDB(UserBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.dependencies import get_db
from app.models.user import User
from app.schemas.user import UserInDB, UserCreate

router = APIRouter()

@router.get("/", response_model=List[UserInDB])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(User).offset(skip).limit(limit).all()
    return users

@router.post("/", response_model=UserInDB)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # Very basic mock creation
    db_user = User(email=user.email, hashed_password=user.password + "_hashed", role=user.role)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

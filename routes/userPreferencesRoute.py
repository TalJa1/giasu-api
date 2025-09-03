from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    DateTime,
    ForeignKey,
    select,
    text,
)
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import func
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from typing import Optional, List
from database import Base, get_db


# SQLAlchemy model for UserPreferences (matches script.sql)
class UserPreferences(Base):
    __tablename__ = "UserPreferences"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("Users.id"), nullable=False)
    preferred_major = Column(String)
    current_score = Column(Float)
    expected_score = Column(Float)
    created_at = Column(DateTime, server_default=func.now())


# Pydantic schemas
class UserPreferencesBase(BaseModel):
    user_id: int
    preferred_major: Optional[str] = None
    current_score: Optional[float] = None
    expected_score: Optional[float] = None


class UserPreferencesCreate(UserPreferencesBase):
    pass


class UserPreferencesUpdate(BaseModel):
    preferred_major: Optional[str] = None
    current_score: Optional[float] = None
    expected_score: Optional[float] = None


class UserPreferencesResponse(UserPreferencesBase):
    id: int

    class Config:
        from_attributes = True


router = APIRouter(
    prefix="/prefs",
    tags=["user-preferences"],
    responses={404: {"description": "Not found"}},
)


# Helper to check user exists
async def _ensure_user_exists(db: AsyncSession, user_id: int):
    # Use raw text to query Users table existence
    query = text("SELECT 1 FROM Users WHERE id = :id LIMIT 1")
    result = await db.execute(query, {"id": user_id})
    row = result.first()
    return row is not None


@router.post(
    "/", response_model=UserPreferencesResponse, status_code=status.HTTP_201_CREATED
)
async def create_pref(pref: UserPreferencesCreate, db: AsyncSession = Depends(get_db)):
    # Ensure user exists
    if not await _ensure_user_exists(db, pref.user_id):
        raise HTTPException(status_code=400, detail="Referenced user_id does not exist")

    try:
        db_pref = UserPreferences(
            user_id=pref.user_id,
            preferred_major=pref.preferred_major,
            current_score=pref.current_score,
            expected_score=pref.expected_score,
        )
        db.add(db_pref)
        await db.commit()
        await db.refresh(db_pref)
        return db_pref
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to create preference")


@router.get("/", response_model=List[UserPreferencesResponse])
async def list_prefs(
    skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(UserPreferences).offset(skip).limit(limit))
    items = result.scalars().all()
    return items


@router.get("/{pref_id}", response_model=UserPreferencesResponse)
async def get_pref(pref_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(UserPreferences).where(UserPreferences.id == pref_id)
    )
    item = result.scalars().first()
    if item is None:
        raise HTTPException(status_code=404, detail="Preference not found")
    return item


@router.put("/{pref_id}", response_model=UserPreferencesResponse)
async def update_pref(
    pref_id: int, pref_update: UserPreferencesUpdate, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(UserPreferences).where(UserPreferences.id == pref_id)
    )
    db_item = result.scalars().first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Preference not found")

    update_data = pref_update.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(db_item, k, v)

    try:
        await db.commit()
        await db.refresh(db_item)
        return db_item
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to update preference")


@router.delete("/{pref_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_pref(pref_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(UserPreferences).where(UserPreferences.id == pref_id)
    )
    db_item = result.scalars().first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Preference not found")

    await db.delete(db_item)
    await db.commit()
    return {"detail": "Preference deleted"}

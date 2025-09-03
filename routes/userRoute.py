from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import Column, Integer, String, select, update, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel, EmailStr
from typing import List, Optional
from database import get_db, Base


# User Model
class User(Base):
    __tablename__ = "Users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    image_url = Column(String, nullable=True)


# Pydantic Schemas
class UserBase(BaseModel):
    username: str
    email: EmailStr
    image_url: Optional[str] = None


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    image_url: Optional[str] = None


class UserResponse(UserBase):
    id: int

    class Config:
        from_attributes = True


# Router
router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(user: UserCreate, db: AsyncSession = Depends(get_db)):
    """Create a new user"""
    try:
        # Check if username or email already exists
        existing_user = await db.execute(
            select(User).where(
                (User.username == user.username) | (User.email == user.email)
            )
        )
        if existing_user.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username or email already exists",
            )

        db_user = User(
            username=user.username, email=user.email, image_url=user.image_url
        )
        db.add(db_user)
        await db.commit()
        await db.refresh(db_user)
        return db_user
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already exists",
        )


@router.get("/", response_model=List[UserResponse])
async def get_users(
    skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_db)
):
    """Get all users with pagination"""
    result = await db.execute(select(User).offset(skip).limit(limit))
    users = result.scalars().all()
    return users


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    """Get a specific user by ID"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int, user_update: UserUpdate, db: AsyncSession = Depends(get_db)
):
    """Update a user"""
    try:
        # Check if user exists
        result = await db.execute(select(User).where(User.id == user_id))
        db_user = result.scalars().first()
        if db_user is None:
            raise HTTPException(status_code=404, detail="User not found")

        # Check for unique constraints if updating username or email
        update_data = user_update.model_dump(exclude_unset=True)
        if "username" in update_data:
            existing = await db.execute(
                select(User).where(
                    (User.username == update_data["username"]) & (User.id != user_id)
                )
            )
            if existing.scalars().first():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username already exists",
                )

        if "email" in update_data:
            existing = await db.execute(
                select(User).where(
                    (User.email == update_data["email"]) & (User.id != user_id)
                )
            )
            if existing.scalars().first():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already exists",
                )

        # Update the user
        for field, value in update_data.items():
            setattr(db_user, field, value)

        await db.commit()
        await db.refresh(db_user)
        return db_user
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Update failed due to constraint violation",
        )


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a user"""
    result = await db.execute(select(User).where(User.id == user_id))
    db_user = result.scalars().first()
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")

    await db.delete(db_user)
    await db.commit()
    return {"detail": "User deleted successfully"}

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import Column, Integer, String, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from typing import List, Optional
from database import get_db, Base


# University SQLAlchemy model
class University(Base):
    __tablename__ = "Universities"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String, nullable=False)
    location = Column(String, nullable=True)
    type = Column(String, nullable=True)
    description = Column(String, nullable=True)


# Pydantic schemas
class UniversityBase(BaseModel):
    name: str
    location: Optional[str] = None
    type: Optional[str] = None
    description: Optional[str] = None


class UniversityCreate(UniversityBase):
    pass


class UniversityUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    type: Optional[str] = None
    description: Optional[str] = None


class UniversityResponse(UniversityBase):
    id: int

    class Config:
        from_attributes = True


router = APIRouter(
    prefix="/universities",
    tags=["universities"],
    responses={404: {"description": "Not found"}},
)


@router.post(
    "/", response_model=UniversityResponse, status_code=status.HTTP_201_CREATED
)
async def create_university(univ: UniversityCreate, db: AsyncSession = Depends(get_db)):
    """Create a new university"""
    try:
        db_univ = University(
            name=univ.name,
            location=univ.location,
            type=univ.type,
            description=univ.description,
        )
        db.add(db_univ)
        await db.commit()
        await db.refresh(db_univ)
        return db_univ
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create university",
        )


@router.get("/", response_model=List[UniversityResponse])
async def get_universities(
    skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_db)
):
    """Get list of universities with pagination"""
    result = await db.execute(select(University).offset(skip).limit(limit))
    return result.scalars().all()


@router.get("/{univ_id}", response_model=UniversityResponse)
async def get_university(univ_id: int, db: AsyncSession = Depends(get_db)):
    """Get a university by ID"""
    result = await db.execute(select(University).where(University.id == univ_id))
    univ = result.scalars().first()
    if univ is None:
        raise HTTPException(status_code=404, detail="University not found")
    return univ


@router.put("/{univ_id}", response_model=UniversityResponse)
async def update_university(
    univ_id: int, univ_update: UniversityUpdate, db: AsyncSession = Depends(get_db)
):
    """Update a university"""
    try:
        result = await db.execute(select(University).where(University.id == univ_id))
        db_univ = result.scalars().first()
        if db_univ is None:
            raise HTTPException(status_code=404, detail="University not found")

        update_data = univ_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_univ, field, value)

        await db.commit()
        await db.refresh(db_univ)
        return db_univ
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Update failed"
        )


@router.delete("/{univ_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_university(univ_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a university"""
    result = await db.execute(select(University).where(University.id == univ_id))
    db_univ = result.scalars().first()
    if db_univ is None:
        raise HTTPException(status_code=404, detail="University not found")

    await db.delete(db_univ)
    await db.commit()
    return {"detail": "University deleted successfully"}


@router.get("/count")
async def get_university_count(db: AsyncSession = Depends(get_db)):
    """Return total number of universities"""
    result = await db.execute(select(University))
    count = len(result.scalars().all())
    return {"count": count}

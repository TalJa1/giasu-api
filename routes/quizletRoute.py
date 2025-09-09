from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import func
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from database import Base, get_db


# SQLAlchemy model for Quizlet
class Quizlet(Base):
    __tablename__ = "Quizlet"

    id = Column(Integer, primary_key=True, autoincrement=True)
    lesson_id = Column(Integer, ForeignKey("Lessons.id"), nullable=False)
    question = Column(String, nullable=False)
    answer = Column(String, nullable=False)
    created_at = Column(DateTime, server_default=func.now())


# Pydantic schemas
class QuizletBase(BaseModel):
    lesson_id: int
    question: str
    answer: str


class QuizletCreate(QuizletBase):
    pass


class QuizletUpdate(BaseModel):
    question: Optional[str] = None
    answer: Optional[str] = None


class QuizletResponse(QuizletBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


router = APIRouter(
    prefix="/quizlets",
    tags=["quizlets"],
    responses={404: {"description": "Not found"}},
)


@router.post("/", response_model=QuizletResponse, status_code=status.HTTP_201_CREATED)
async def create_quizlet(item: QuizletCreate, db: AsyncSession = Depends(get_db)):
    try:
        db_item = Quizlet(
            lesson_id=item.lesson_id, question=item.question, answer=item.answer
        )
        db.add(db_item)
        await db.commit()
        await db.refresh(db_item)
        return db_item
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to create quizlet item")


@router.get("/", response_model=List[QuizletResponse])
async def list_quizlets(
    skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Quizlet).offset(skip).limit(limit))
    items = result.scalars().all()
    return items


@router.get("/lesson/{lesson_id}", response_model=List[QuizletResponse])
async def get_quizlets_for_lesson(lesson_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Quizlet).where(Quizlet.lesson_id == lesson_id))
    items = result.scalars().all()
    return items


@router.get("/{quizlet_id}", response_model=QuizletResponse)
async def get_quizlet(quizlet_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Quizlet).where(Quizlet.id == quizlet_id))
    item = result.scalars().first()
    if item is None:
        raise HTTPException(status_code=404, detail="Quizlet item not found")
    return item


@router.put("/{quizlet_id}", response_model=QuizletResponse)
async def update_quizlet(
    quizlet_id: int, update: QuizletUpdate, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Quizlet).where(Quizlet.id == quizlet_id))
    db_item = result.scalars().first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Quizlet item not found")

    update_data = update.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(db_item, k, v)

    try:
        await db.commit()
        await db.refresh(db_item)
        return db_item
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to update quizlet item")


@router.delete("/{quizlet_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_quizlet(quizlet_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Quizlet).where(Quizlet.id == quizlet_id))
    db_item = result.scalars().first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Quizlet item not found")

    await db.delete(db_item)
    await db.commit()
    return {"detail": "Quizlet item deleted"}

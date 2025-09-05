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
from pydantic import BaseModel, HttpUrl
from typing import Optional, List
from database import Base, get_db


# SQLAlchemy models
class Lesson(Base):
    __tablename__ = "Lessons"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String, nullable=False)
    description = Column(String)
    content = Column(String)
    subject = Column(String)
    content_url = Column(String)
    created_by = Column(Integer, ForeignKey("Users.id"))
    created_at = Column(DateTime, server_default=func.now())


class LessonTracking(Base):
    __tablename__ = "LessonTracking"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("Users.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("Lessons.id"), nullable=False)
    progress = Column(Float, default=0.0)
    status = Column(String, default="not_started")
    started_at = Column(DateTime)
    last_accessed = Column(DateTime, server_default=func.now())
    completed_at = Column(DateTime)


# Pydantic schemas
class LessonBase(BaseModel):
    title: str
    description: Optional[str] = None
    content: Optional[str] = None
    subject: Optional[str] = None
    content_url: Optional[HttpUrl] = None


class LessonCreate(LessonBase):
    created_by: Optional[int] = None


class LessonUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    content: Optional[str] = None
    subject: Optional[str] = None
    content_url: Optional[HttpUrl] = None


class LessonResponse(LessonBase):
    id: int
    created_by: Optional[int] = None

    class Config:
        from_attributes = True


class LessonTrackingBase(BaseModel):
    user_id: int
    lesson_id: int
    progress: Optional[float] = 0.0
    status: Optional[str] = "not_started"


class LessonTrackingCreate(LessonTrackingBase):
    pass


class LessonTrackingUpdate(BaseModel):
    progress: Optional[float] = None
    status: Optional[str] = None


class LessonTrackingResponse(LessonTrackingBase):
    id: int

    class Config:
        from_attributes = True


router = APIRouter(
    prefix="/lessons",
    tags=["lessons"],
    responses={404: {"description": "Not found"}},
)


# Lessons endpoints
@router.post("/", response_model=LessonResponse, status_code=status.HTTP_201_CREATED)
async def create_lesson(lesson: LessonCreate, db: AsyncSession = Depends(get_db)):
    try:
        db_lesson = Lesson(
            title=lesson.title,
            description=lesson.description,
            content=lesson.content,
            subject=lesson.subject,
            content_url=str(lesson.content_url) if lesson.content_url else None,
            created_by=lesson.created_by,
        )
        db.add(db_lesson)
        await db.commit()
        await db.refresh(db_lesson)
        return db_lesson
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to create lesson")


@router.get("/", response_model=List[LessonResponse])
async def list_lessons(
    skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Lesson).offset(skip).limit(limit))
    items = result.scalars().all()
    return items


@router.get("/{lesson_id}", response_model=LessonResponse)
async def get_lesson(lesson_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    item = result.scalars().first()
    if item is None:
        raise HTTPException(status_code=404, detail="Lesson not found")
    return item


@router.put("/{lesson_id}", response_model=LessonResponse)
async def update_lesson(
    lesson_id: int, lesson_update: LessonUpdate, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    db_item = result.scalars().first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Lesson not found")

    update_data = lesson_update.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(db_item, k, v)

    try:
        await db.commit()
        await db.refresh(db_item)
        return db_item
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to update lesson")


@router.delete("/{lesson_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_lesson(lesson_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    db_item = result.scalars().first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Lesson not found")

    await db.delete(db_item)
    await db.commit()
    return {"detail": "Lesson deleted"}


# Lesson tracking endpoints
tracking_router = APIRouter(
    prefix="/tracking",
    tags=["lesson-tracking"],
    responses={404: {"description": "Not found"}},
)


@tracking_router.post(
    "/", response_model=LessonTrackingResponse, status_code=status.HTTP_201_CREATED
)
async def create_tracking(
    entry: LessonTrackingCreate, db: AsyncSession = Depends(get_db)
):
    try:
        db_entry = LessonTracking(
            user_id=entry.user_id,
            lesson_id=entry.lesson_id,
            progress=entry.progress or 0.0,
            status=entry.status or "not_started",
        )
        db.add(db_entry)
        await db.commit()
        await db.refresh(db_entry)
        return db_entry
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to create tracking entry")


@tracking_router.get("/", response_model=List[LessonTrackingResponse])
async def list_tracking(
    skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(LessonTracking).offset(skip).limit(limit))
    items = result.scalars().all()
    return items


@tracking_router.get("/{tracking_id}", response_model=LessonTrackingResponse)
async def get_tracking(tracking_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(LessonTracking).where(LessonTracking.id == tracking_id)
    )
    item = result.scalars().first()
    if item is None:
        raise HTTPException(status_code=404, detail="Tracking entry not found")
    return item


@tracking_router.put("/{tracking_id}", response_model=LessonTrackingResponse)
async def update_tracking(
    tracking_id: int,
    track_update: LessonTrackingUpdate,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(LessonTracking).where(LessonTracking.id == tracking_id)
    )
    db_item = result.scalars().first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Tracking entry not found")

    update_data = track_update.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(db_item, k, v)

    try:
        await db.commit()
        await db.refresh(db_item)
        return db_item
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to update tracking entry")


@tracking_router.delete("/{tracking_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tracking(tracking_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(LessonTracking).where(LessonTracking.id == tracking_id)
    )
    db_item = result.scalars().first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Tracking entry not found")

    await db.delete(db_item)
    await db.commit()
    return {"detail": "Tracking entry deleted"}


# Include tracking router into main router for single import
router.include_router(tracking_router)

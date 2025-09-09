from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import Column, Integer, String, select, Float
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


# UniversityScores SQLAlchemy model
class UniversityScore(Base):
    __tablename__ = "UniversityScores"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    university_id = Column(Integer, nullable=False)
    year = Column(Integer, nullable=False)
    min_score = Column(Float, nullable=True)
    avg_score = Column(Float, nullable=True)
    max_score = Column(Float, nullable=True)


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


class UniversityScoreResponse(BaseModel):
    id: int
    university_id: int
    year: int
    min_score: Optional[float] = None
    avg_score: Optional[float] = None
    max_score: Optional[float] = None

    class Config:
        from_attributes = True


class UniversityWithScoresResponse(UniversityResponse):
    scores: List[UniversityScoreResponse] = []

    class Config:
        from_attributes = True


router = APIRouter(
    prefix="/universities",
    tags=["universities"],
    responses={404: {"description": "Not found"}},
)


@router.post(
    "/",
    response_model=UniversityWithScoresResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_university(univ: UniversityCreate, db: AsyncSession = Depends(get_db)):
    """Create a new university and return it with (empty) scores"""
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

        return {
            "id": db_univ.id,
            "name": db_univ.name,
            "location": db_univ.location,
            "type": db_univ.type,
            "description": db_univ.description,
            "scores": [],
        }
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create university",
        )


@router.get("/", response_model=List[UniversityWithScoresResponse])
async def get_universities(
    skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_db)
):
    """Get list of universities with their historical scores (pagination)"""
    result = await db.execute(select(University).offset(skip).limit(limit))
    universities = result.scalars().all()

    # collect ids and fetch all scores for those universities in one query
    univ_ids = [u.id for u in universities if u.id is not None]
    scores_map: dict[int, list[dict]] = {}
    if univ_ids:
        score_res = await db.execute(
            select(UniversityScore).where(UniversityScore.university_id.in_(univ_ids))
        )
        scores = score_res.scalars().all()
        for s in scores:
            scores_map.setdefault(s.university_id, []).append(
                {
                    "id": s.id,
                    "university_id": s.university_id,
                    "year": s.year,
                    "min_score": s.min_score,
                    "avg_score": s.avg_score,
                    "max_score": s.max_score,
                }
            )

    # build response combining university fields and their scores
    response = []
    for u in universities:
        response.append(
            {
                "id": u.id,
                "name": u.name,
                "location": u.location,
                "type": u.type,
                "description": u.description,
                "scores": scores_map.get(u.id, []),
            }
        )

    return response


@router.get("/{univ_id}", response_model=UniversityWithScoresResponse)
async def get_university(univ_id: int, db: AsyncSession = Depends(get_db)):
    """Get a university by ID with its historical scores"""
    result = await db.execute(select(University).where(University.id == univ_id))
    univ = result.scalars().first()
    if univ is None:
        raise HTTPException(status_code=404, detail="University not found")

    score_res = await db.execute(
        select(UniversityScore).where(UniversityScore.university_id == univ_id)
    )
    scores = score_res.scalars().all()
    scores_list = [
        {
            "id": s.id,
            "university_id": s.university_id,
            "year": s.year,
            "min_score": s.min_score,
            "avg_score": s.avg_score,
            "max_score": s.max_score,
        }
        for s in scores
    ]

    return {
        "id": univ.id,
        "name": univ.name,
        "location": univ.location,
        "type": univ.type,
        "description": univ.description,
        "scores": scores_list,
    }


@router.put("/{univ_id}", response_model=UniversityWithScoresResponse)
async def update_university(
    univ_id: int, univ_update: UniversityUpdate, db: AsyncSession = Depends(get_db)
):
    """Update a university and return it with its scores"""
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

        score_res = await db.execute(
            select(UniversityScore).where(UniversityScore.university_id == univ_id)
        )
        scores = score_res.scalars().all()
        scores_list = [
            {
                "id": s.id,
                "university_id": s.university_id,
                "year": s.year,
                "min_score": s.min_score,
                "avg_score": s.avg_score,
                "max_score": s.max_score,
            }
            for s in scores
        ]

        return {
            "id": db_univ.id,
            "name": db_univ.name,
            "location": db_univ.location,
            "type": db_univ.type,
            "description": db_univ.description,
            "scores": scores_list,
        }
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Update failed"
        )


@router.delete("/{univ_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_university(univ_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a university (no content returned)"""
    result = await db.execute(select(University).where(University.id == univ_id))
    db_univ = result.scalars().first()
    if db_univ is None:
        raise HTTPException(status_code=404, detail="University not found")

    await db.delete(db_univ)
    await db.commit()
    return None


@router.get("/count")
async def get_university_count(db: AsyncSession = Depends(get_db)):
    """Return total number of universities"""
    result = await db.execute(select(University))
    count = len(result.scalars().all())
    return {"count": count}

from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy import Column, Integer, Float, Text, Boolean, ForeignKey, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from typing import List, Optional, Any
import json

from database import get_db, Base


# SQLAlchemy models (map to existing tables)
class UserTestResult(Base):
    __tablename__ = "UserTestResults"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, nullable=False)
    test_id = Column(Integer, nullable=False)
    score = Column(Float)
    total_questions = Column(Integer)
    correct_answers = Column(Integer)
    points_earned = Column(Float, default=0.0)
    points_possible = Column(Float, default=0.0)
    taken_at = Column(Text)


class UserQuestionAnswer(Base):
    __tablename__ = "UserQuestionAnswers"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    test_result_id = Column(Integer, ForeignKey("UserTestResults.id"), nullable=False)
    question_id = Column(Integer, nullable=False)
    user_answer = Column(Text)
    is_correct = Column(Boolean, default=False)
    partial_credit = Column(Float, default=0.0)
    answered_at = Column(Text)


# Pydantic schemas
class AnswerBase(BaseModel):
    question_id: int
    user_answer: Optional[List[str]] = None
    is_correct: Optional[bool] = False
    partial_credit: Optional[float] = 0.0


class AnswerCreate(AnswerBase):
    pass


class AnswerUpdate(BaseModel):
    user_answer: Optional[List[str]] = None
    is_correct: Optional[bool] = None
    partial_credit: Optional[float] = None


class AnswerResponse(AnswerBase):
    id: int

    class Config:
        from_attributes = True


class ResultBase(BaseModel):
    user_id: int
    test_id: int
    score: Optional[float] = None
    total_questions: Optional[int] = None
    correct_answers: Optional[int] = None
    points_earned: Optional[float] = 0.0
    points_possible: Optional[float] = 0.0


class ResultCreate(ResultBase):
    answers: Optional[List[AnswerCreate]] = []


class ResultUpdate(BaseModel):
    score: Optional[float] = None
    total_questions: Optional[int] = None
    correct_answers: Optional[int] = None
    points_earned: Optional[float] = None
    points_possible: Optional[float] = None
    answers: Optional[List[AnswerCreate]] = None


class ResultResponse(ResultBase):
    id: int
    taken_at: Optional[str] = None
    answers: List[AnswerResponse] = []

    class Config:
        from_attributes = True


router = APIRouter(prefix="/results", tags=["results"])


def _serialize_answer(a: Optional[List[str]]) -> Optional[str]:
    if a is None:
        return None
    try:
        return json.dumps(a)
    except Exception:
        return None


def _deserialize_answer(text: Optional[str]) -> List[str]:
    if not text:
        return []
    try:
        data = json.loads(text)
        if isinstance(data, list):
            return [str(x) for x in data]
    except Exception:
        return [p.strip() for p in str(text).split(",") if p.strip()]
    return []


@router.post("/", response_model=ResultResponse, status_code=status.HTTP_201_CREATED)
async def create_result(
    payload: ResultCreate = Body(
        ...,
        example={
            "user_id": 0,
            "test_id": 0,
            "score": 0,
            "total_questions": 0,
            "correct_answers": 0,
            "points_earned": 0,
            "points_possible": 10.0,
            "answers": [
                {
                    "question_id": 0,
                    "user_answer": ["B"],
                    "is_correct": True,
                    "partial_credit": 1.0,
                },
            ],
        },
    ),
    db: AsyncSession = Depends(get_db),
):
    # Create test result and nested answers atomically
    db_result = UserTestResult(
        user_id=payload.user_id,
        test_id=payload.test_id,
        score=payload.score,
        total_questions=payload.total_questions,
        correct_answers=payload.correct_answers,
        points_earned=payload.points_earned,
        points_possible=payload.points_possible,
    )
    try:
        db.add(db_result)
        await db.commit()
        await db.refresh(db_result)

        created_answers = []
        for a in payload.answers or []:
            ua = _serialize_answer(a.user_answer)
            db_a = UserQuestionAnswer(
                test_result_id=db_result.id,
                question_id=a.question_id,
                user_answer=ua,
                is_correct=bool(a.is_correct),
                partial_credit=a.partial_credit or 0.0,
            )
            db.add(db_a)
            await db.commit()
            await db.refresh(db_a)
            created_answers.append(db_a)

        # build response
        answers_resp = [
            {
                "id": ans.id,
                "question_id": ans.question_id,
                "user_answer": _deserialize_answer(ans.user_answer),
                "is_correct": bool(ans.is_correct),
                "partial_credit": ans.partial_credit,
            }
            for ans in created_answers
        ]

        return {
            "id": db_result.id,
            "user_id": db_result.user_id,
            "test_id": db_result.test_id,
            "score": db_result.score,
            "total_questions": db_result.total_questions,
            "correct_answers": db_result.correct_answers,
            "points_earned": db_result.points_earned,
            "points_possible": db_result.points_possible,
            "taken_at": db_result.taken_at,
            "answers": answers_resp,
        }
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to create result")


@router.get("/", response_model=List[ResultResponse])
async def get_results(
    user_id: Optional[int] = None, db: AsyncSession = Depends(get_db)
):
    # Get results optionally filtered by user_id, include nested answers
    stmt = select(UserTestResult)
    if user_id is not None:
        stmt = stmt.where(UserTestResult.user_id == user_id)

    res = await db.execute(stmt)
    results = res.scalars().all()
    result_ids = [r.id for r in results]

    # fetch all answers for these results
    answers = []
    if result_ids:
        ares = await db.execute(
            select(UserQuestionAnswer).where(
                UserQuestionAnswer.test_result_id.in_(result_ids)
            )
        )
        answers = ares.scalars().all()

    a_by_result = {}
    for a in answers:
        a_by_result.setdefault(a.test_result_id, []).append(a)

    out = []
    for r in results:
        ans = [
            {
                "id": a.id,
                "question_id": a.question_id,
                "user_answer": _deserialize_answer(a.user_answer),
                "is_correct": bool(a.is_correct),
                "partial_credit": a.partial_credit,
            }
            for a in a_by_result.get(r.id, [])
        ]
        out.append(
            {
                "id": r.id,
                "user_id": r.user_id,
                "test_id": r.test_id,
                "score": r.score,
                "total_questions": r.total_questions,
                "correct_answers": r.correct_answers,
                "points_earned": r.points_earned,
                "points_possible": r.points_possible,
                "taken_at": r.taken_at,
                "answers": ans,
            }
        )

    return out


@router.get("/{result_id}", response_model=ResultResponse)
async def get_result(result_id: int, db: AsyncSession = Depends(get_db)):
    rres = await db.execute(
        select(UserTestResult).where(UserTestResult.id == result_id)
    )
    r = rres.scalars().first()
    if r is None:
        raise HTTPException(status_code=404, detail="Result not found")

    ares = await db.execute(
        select(UserQuestionAnswer).where(UserQuestionAnswer.test_result_id == result_id)
    )
    answers = ares.scalars().all()
    ans_out = [
        {
            "id": a.id,
            "question_id": a.question_id,
            "user_answer": _deserialize_answer(a.user_answer),
            "is_correct": bool(a.is_correct),
            "partial_credit": a.partial_credit,
        }
        for a in answers
    ]

    return {
        "id": r.id,
        "user_id": r.user_id,
        "test_id": r.test_id,
        "score": r.score,
        "total_questions": r.total_questions,
        "correct_answers": r.correct_answers,
        "points_earned": r.points_earned,
        "points_possible": r.points_possible,
        "taken_at": r.taken_at,
        "answers": ans_out,
    }


@router.put("/{result_id}", response_model=ResultResponse)
async def update_result(
    result_id: int, payload: ResultUpdate, db: AsyncSession = Depends(get_db)
):
    rres = await db.execute(
        select(UserTestResult).where(UserTestResult.id == result_id)
    )
    r = rres.scalars().first()
    if r is None:
        raise HTTPException(status_code=404, detail="Result not found")

    data = payload.model_dump(exclude_unset=True)
    answers_payload = data.pop("answers", None)
    for k, v in data.items():
        setattr(r, k, v)

    await db.commit()
    await db.refresh(r)

    # If answers provided, replace existing answers for this result
    if answers_payload is not None:
        # delete existing answers
        existing = await db.execute(
            select(UserQuestionAnswer).where(
                UserQuestionAnswer.test_result_id == result_id
            )
        )
        for ex in existing.scalars().all():
            await db.delete(ex)
        await db.commit()

        created_answers = []
        for a in answers_payload:
            ua = _serialize_answer(a.user_answer)
            db_a = UserQuestionAnswer(
                test_result_id=result_id,
                question_id=a.question_id,
                user_answer=ua,
                is_correct=bool(a.is_correct),
                partial_credit=a.partial_credit or 0.0,
            )
            db.add(db_a)
            await db.commit()
            await db.refresh(db_a)
            created_answers.append(db_a)

    # return updated
    return await get_result(result_id, db)


@router.delete("/{result_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_result(result_id: int, db: AsyncSession = Depends(get_db)):
    rres = await db.execute(
        select(UserTestResult).where(UserTestResult.id == result_id)
    )
    r = rres.scalars().first()
    if r is None:
        raise HTTPException(status_code=404, detail="Result not found")

    # delete associated answers
    ares = await db.execute(
        select(UserQuestionAnswer).where(UserQuestionAnswer.test_result_id == result_id)
    )
    for a in ares.scalars().all():
        await db.delete(a)
    await db.commit()

    await db.delete(r)
    await db.commit()
    return {"detail": "Result deleted"}

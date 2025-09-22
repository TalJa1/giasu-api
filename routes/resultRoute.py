from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy import (
    Column,
    Integer,
    Float,
    Text,
    Boolean,
    ForeignKey,
    select,
    text,
    func,
)
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from typing import List, Optional, Any
import json
import os
import sqlite3
from starlette.concurrency import run_in_threadpool

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
    # Note: we perform INSERTs in a synchronous worker to avoid aiosqlite/greenlet issues.
    # Do not create ORM objects here (they are unused) to avoid accidental ORM side-effects.

    # To avoid async driver/greenlet issues with aiosqlite in some environments,
    # perform the INSERT operations synchronously in a threadpool using sqlite3.
    def _create_result_sync(payload: ResultCreate):
        db_path = os.path.join(os.getcwd(), "giasu.db")
        conn = sqlite3.connect(db_path)
        try:
            cur = conn.cursor()
            # enforce foreign keys and acquire lock to avoid concurrent dup inserts
            cur.execute("PRAGMA foreign_keys = ON")
            cur.execute("BEGIN IMMEDIATE")

            # Deduplication: check latest result for this user/test and compare answers.
            try:
                cur.execute(
                    "SELECT id FROM UserTestResults WHERE user_id = ? AND test_id = ? ORDER BY id DESC LIMIT 1",
                    (payload.user_id, payload.test_id),
                )
                existing = cur.fetchone()
                if existing is not None:
                    existing_id = existing[0]
                    cur.execute(
                        "SELECT id, question_id, user_answer, is_correct, partial_credit FROM UserQuestionAnswers WHERE test_result_id = ? ORDER BY id",
                        (existing_id,),
                    )
                    existing_answers_rows = cur.fetchall()
                    existing_answers = [
                        json.loads(r[2]) if r[2] else [] for r in existing_answers_rows
                    ]
                    incoming_answers = [
                        a.user_answer or [] for a in (payload.answers or [])
                    ]
                    if existing_answers == incoming_answers:
                        # build response from existing records
                        cur.execute(
                            "SELECT id, user_id, test_id, score, total_questions, correct_answers, points_earned, points_possible, taken_at FROM UserTestResults WHERE id = ?",
                            (existing_id,),
                        )
                        row = cur.fetchone()
                        (
                            rid,
                            uid,
                            tid,
                            score,
                            total_q,
                            correct_a,
                            p_earned,
                            p_possible,
                            taken_at,
                        ) = row
                        answers_resp_local = []
                        for aid, qid, utext, is_corr, pcredit in existing_answers_rows:
                            try:
                                ua = json.loads(utext) if utext else []
                            except Exception:
                                ua = [
                                    p.strip()
                                    for p in str(utext).split(",")
                                    if p.strip()
                                ]
                            answers_resp_local.append(
                                {
                                    "id": aid,
                                    "question_id": qid,
                                    "user_answer": ua,
                                    "is_correct": (
                                        bool(is_corr) if is_corr is not None else None
                                    ),
                                    "partial_credit": (
                                        float(pcredit) if pcredit is not None else 0.0
                                    ),
                                }
                            )
                        conn.commit()
                        return {
                            "id": rid,
                            "user_id": uid,
                            "test_id": tid,
                            "score": score,
                            "total_questions": total_q,
                            "correct_answers": correct_a,
                            "points_earned": p_earned,
                            "points_possible": p_possible,
                            "taken_at": taken_at,
                            "answers": answers_resp_local,
                        }
            except Exception:
                pass

            # Insert new result
            cur.execute(
                "INSERT INTO UserTestResults (user_id, test_id, score, total_questions, correct_answers, points_earned, points_possible) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (
                    payload.user_id,
                    payload.test_id,
                    payload.score,
                    payload.total_questions,
                    payload.correct_answers,
                    payload.points_earned,
                    payload.points_possible,
                ),
            )
            result_id = cur.lastrowid

            for a in payload.answers or []:
                ua = json.dumps(a.user_answer) if a.user_answer is not None else None
                cur.execute(
                    "INSERT INTO UserQuestionAnswers (test_result_id, question_id, user_answer, is_correct, partial_credit) VALUES (?, ?, ?, ?, ?)",
                    (
                        result_id,
                        a.question_id,
                        ua,
                        1 if a.is_correct else 0,
                        a.partial_credit or 0.0,
                    ),
                )

            conn.commit()

            # Read back answers
            cur.execute(
                "SELECT id, question_id, user_answer, is_correct, partial_credit FROM UserQuestionAnswers WHERE test_result_id = ?",
                (result_id,),
            )
            rows = cur.fetchall()
            answers_resp_local = []
            for aid, qid, user_answer_text, is_corr, pcredit in rows:
                try:
                    ua = json.loads(user_answer_text) if user_answer_text else []
                except Exception:
                    ua = [
                        p.strip() for p in str(user_answer_text).split(",") if p.strip()
                    ]
                answers_resp_local.append(
                    {
                        "id": aid,
                        "question_id": qid,
                        "user_answer": ua,
                        "is_correct": bool(is_corr),
                        "partial_credit": (
                            float(pcredit) if pcredit is not None else 0.0
                        ),
                    }
                )

            return {
                "id": result_id,
                "user_id": payload.user_id,
                "test_id": payload.test_id,
                "score": payload.score,
                "total_questions": payload.total_questions,
                "correct_answers": payload.correct_answers,
                "points_earned": payload.points_earned,
                "points_possible": payload.points_possible,
                "taken_at": None,
                "answers": answers_resp_local,
            }
        finally:
            try:
                conn.close()
            except Exception:
                pass

    try:
        result = await run_in_threadpool(_create_result_sync, payload)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to create result: {e}")


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


@router.get("/user/{user_id}", response_model=List[ResultResponse])
async def get_results_by_user(user_id: int, db: AsyncSession = Depends(get_db)):
    """Return a list of results for the given user_id including nested answers."""
    # fetch results for user
    rres = await db.execute(
        select(UserTestResult).where(UserTestResult.user_id == user_id)
    )
    results = rres.scalars().all()

    if not results:
        return []

    result_ids = [r.id for r in results]

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


@router.get("/progress/{user_id}")
async def get_user_progress(user_id: int, db: AsyncSession = Depends(get_db)):
    """Return how many distinct tests the user has taken vs total tests available"""
    # count distinct test_id in UserTestResults for this user
    res = await db.execute(
        select(UserTestResult).where(UserTestResult.user_id == user_id)
    )
    results = res.scalars().all()
    tests_taken = len({r.test_id for r in results})

    # count total tests using ORM Test model to avoid textual SQL
    try:
        from routes.testRoute import Test
        from sqlalchemy import func

        cnt_res = await db.execute(select(func.count(Test.id)))
        total_tests = int(cnt_res.scalar() or 0)
    except Exception:
        total_tests = 0

    percent = (tests_taken / total_tests * 100.0) if total_tests else 0.0
    return {
        "user_id": user_id,
        "tests_taken": tests_taken,
        "total_tests": total_tests,
        "percent": percent,
    }


@router.get("/user/result/{user_id}/mean")
async def get_user_mean_score(user_id: int, db: AsyncSession = Depends(get_db)):
    """Return the mean (average) score for the given user_id across all their results. (as percentage)"""
    try:
        # Use SQL aggregation to compute average and count
        stmt = select(
            func.avg(UserTestResult.score), func.count(UserTestResult.id)
        ).where(UserTestResult.user_id == user_id)
        res = await db.execute(stmt)
        avg_score, cnt = res.fetchone() or (None, 0)

        # Normalize types
        mean_score = float(avg_score) if (avg_score is not None) else None
        count = int(cnt or 0)

        return {"user_id": user_id, "mean_score": mean_score, "count": count}
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to compute mean score: {e}"
        )


@router.delete("/user/{user_id}/{result_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_result_for_user(
    user_id: int, result_id: int, db: AsyncSession = Depends(get_db)
):
    """Delete a specific result if it belongs to the provided user_id. Also deletes associated answers."""
    rres = await db.execute(
        select(UserTestResult).where(UserTestResult.id == result_id)
    )
    r = rres.scalars().first()
    if r is None:
        raise HTTPException(status_code=404, detail="Result not found")

    if r.user_id != user_id:
        raise HTTPException(
            status_code=403, detail="Result does not belong to the user"
        )

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

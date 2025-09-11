from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import Column, Integer, String, Float, Text, ForeignKey, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from typing import List, Optional, Any
import json

from database import get_db, Base


# SQLAlchemy models
class Test(Base):
    __tablename__ = "Tests"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String, nullable=False)
    description = Column(Text)
    created_by = Column(Integer)
    created_at = Column(String)
    supports_multiple_answers = Column(Integer, default=0)


class TestQuestion(Base):
    __tablename__ = "TestQuestions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    test_id = Column(Integer, ForeignKey("Tests.id"), nullable=False)
    question_text = Column(Text, nullable=False)
    option_a = Column(Text)
    option_b = Column(Text)
    option_c = Column(Text)
    option_d = Column(Text)
    question_type = Column(String, default="single")
    correct_options = Column(Text)
    points = Column(Float, default=1.0)


# Pydantic schemas
class QuestionBase(BaseModel):
    question_text: str
    option_a: Optional[str] = None
    option_b: Optional[str] = None
    option_c: Optional[str] = None
    option_d: Optional[str] = None
    question_type: Optional[str] = "single"
    correct_options: Optional[List[str]] = None
    points: Optional[float] = 1.0


class QuestionCreate(QuestionBase):
    pass


class QuestionUpdate(BaseModel):
    question_text: Optional[str] = None
    option_a: Optional[str] = None
    option_b: Optional[str] = None
    option_c: Optional[str] = None
    option_d: Optional[str] = None
    question_type: Optional[str] = None
    correct_options: Optional[List[str]] = None
    points: Optional[float] = None


class QuestionResponse(QuestionBase):
    id: int

    class Config:
        from_attributes = True


class TestBase(BaseModel):
    title: str
    description: Optional[str] = None
    created_by: Optional[int] = None
    supports_multiple_answers: Optional[bool] = False


class TestCreate(TestBase):
    pass


class TestUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    supports_multiple_answers: Optional[bool] = None


class TestResponse(TestBase):
    id: int
    created_at: Optional[str] = None
    questions: List[QuestionResponse] = []

    class Config:
        from_attributes = True


router = APIRouter(prefix="/tests", tags=["tests"])


def _serialize_options(options: Optional[List[str]]) -> Optional[str]:
    if options is None:
        return None
    try:
        return json.dumps(options)
    except Exception:
        return None


def _deserialize_options(text: Optional[str]) -> Optional[List[str]]:
    if not text:
        return []
    try:
        data = json.loads(text)
        if isinstance(data, list):
            return [str(x) for x in data]
    except Exception:
        # fallback to comma separated
        return [p.strip() for p in str(text).split(",") if p.strip()]
    return []


@router.post("/", response_model=TestResponse, status_code=status.HTTP_201_CREATED)
async def create_test(test: TestCreate, db: AsyncSession = Depends(get_db)):
    db_test = Test(
        title=test.title,
        description=test.description,
        created_by=test.created_by,
        supports_multiple_answers=1 if test.supports_multiple_answers else 0,
    )
    try:
        db.add(db_test)
        await db.commit()
        await db.refresh(db_test)
        # return with empty questions list
        return {
            **test.model_dump(),
            "id": db_test.id,
            "questions": [],
            "created_at": db_test.created_at,
        }
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Failed to create test")


@router.get("/", response_model=List[TestResponse])
async def get_tests(db: AsyncSession = Depends(get_db)):
    # Retrieve all tests and their questions, then assemble nested structure
    tests_res = await db.execute(select(Test))
    tests = tests_res.scalars().all()

    questions_res = await db.execute(select(TestQuestion))
    questions = questions_res.scalars().all()

    q_by_test = {}
    for q in questions:
        q_by_test.setdefault(q.test_id, []).append(q)

    out = []
    for t in tests:
        qs = []
        for q in q_by_test.get(t.id, []):
            qs.append(
                {
                    "id": q.id,
                    "question_text": q.question_text,
                    "option_a": q.option_a,
                    "option_b": q.option_b,
                    "option_c": q.option_c,
                    "option_d": q.option_d,
                    "question_type": q.question_type,
                    "correct_options": _deserialize_options(q.correct_options),
                    "points": q.points,
                }
            )

        out.append(
            {
                "id": t.id,
                "title": t.title,
                "description": t.description,
                "created_by": t.created_by,
                "supports_multiple_answers": bool(t.supports_multiple_answers),
                "created_at": t.created_at,
                "questions": qs,
            }
        )
    return out


@router.get("/{test_id}", response_model=TestResponse)
async def get_test(test_id: int, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(Test).where(Test.id == test_id))
    t = res.scalars().first()
    if t is None:
        raise HTTPException(status_code=404, detail="Test not found")

    qres = await db.execute(select(TestQuestion).where(TestQuestion.test_id == test_id))
    qlist = qres.scalars().all()
    qs = []
    for q in qlist:
        qs.append(
            {
                "id": q.id,
                "question_text": q.question_text,
                "option_a": q.option_a,
                "option_b": q.option_b,
                "option_c": q.option_c,
                "option_d": q.option_d,
                "question_type": q.question_type,
                "correct_options": _deserialize_options(q.correct_options),
                "points": q.points,
            }
        )

    return {
        "id": t.id,
        "title": t.title,
        "description": t.description,
        "created_by": t.created_by,
        "supports_multiple_answers": bool(t.supports_multiple_answers),
        "created_at": t.created_at,
        "questions": qs,
    }


@router.put("/{test_id}", response_model=TestResponse)
async def update_test(
    test_id: int, test_update: TestUpdate, db: AsyncSession = Depends(get_db)
):
    res = await db.execute(select(Test).where(Test.id == test_id))
    db_test = res.scalars().first()
    if db_test is None:
        raise HTTPException(status_code=404, detail="Test not found")

    data = test_update.model_dump(exclude_unset=True)
    for k, v in data.items():
        if k == "supports_multiple_answers":
            setattr(db_test, k, 1 if v else 0)
        else:
            setattr(db_test, k, v)

    await db.commit()
    await db.refresh(db_test)
    # reuse get_test for response
    return await get_test(test_id, db)


@router.delete("/{test_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_test(test_id: int, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(Test).where(Test.id == test_id))
    db_test = res.scalars().first()
    if db_test is None:
        raise HTTPException(status_code=404, detail="Test not found")

    await db.delete(db_test)
    await db.commit()
    return {"detail": "Test deleted"}


@router.post(
    "/{test_id}/questions",
    response_model=QuestionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_question(
    test_id: int, q: QuestionCreate, db: AsyncSession = Depends(get_db)
):
    # make sure test exists
    tres = await db.execute(select(Test).where(Test.id == test_id))
    if tres.scalars().first() is None:
        raise HTTPException(status_code=404, detail="Test not found")

    correct_text = _serialize_options(q.correct_options)
    db_q = TestQuestion(
        test_id=test_id,
        question_text=q.question_text,
        option_a=q.option_a,
        option_b=q.option_b,
        option_c=q.option_c,
        option_d=q.option_d,
        question_type=q.question_type,
        correct_options=correct_text,
        points=q.points,
    )
    db.add(db_q)
    await db.commit()
    await db.refresh(db_q)
    return {
        "id": db_q.id,
        "question_text": db_q.question_text,
        "option_a": db_q.option_a,
        "option_b": db_q.option_b,
        "option_c": db_q.option_c,
        "option_d": db_q.option_d,
        "question_type": db_q.question_type,
        "correct_options": _deserialize_options(db_q.correct_options),
        "points": db_q.points,
    }


@router.get("/questions/{question_id}", response_model=QuestionResponse)
async def get_question(question_id: int, db: AsyncSession = Depends(get_db)):
    qres = await db.execute(select(TestQuestion).where(TestQuestion.id == question_id))
    q = qres.scalars().first()
    if q is None:
        raise HTTPException(status_code=404, detail="Question not found")
    return {
        "id": q.id,
        "question_text": q.question_text,
        "option_a": q.option_a,
        "option_b": q.option_b,
        "option_c": q.option_c,
        "option_d": q.option_d,
        "question_type": q.question_type,
        "correct_options": _deserialize_options(q.correct_options),
        "points": q.points,
    }


@router.put("/questions/{question_id}", response_model=QuestionResponse)
async def update_question(
    question_id: int, q_update: QuestionUpdate, db: AsyncSession = Depends(get_db)
):
    qres = await db.execute(select(TestQuestion).where(TestQuestion.id == question_id))
    db_q = qres.scalars().first()
    if db_q is None:
        raise HTTPException(status_code=404, detail="Question not found")

    data = q_update.model_dump(exclude_unset=True)
    if "correct_options" in data:
        data["correct_options"] = _serialize_options(data["correct_options"])

    for k, v in data.items():
        setattr(db_q, k, v)

    await db.commit()
    await db.refresh(db_q)
    return await get_question(question_id, db)


@router.delete("/questions/{question_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_question(question_id: int, db: AsyncSession = Depends(get_db)):
    qres = await db.execute(select(TestQuestion).where(TestQuestion.id == question_id))
    db_q = qres.scalars().first()
    if db_q is None:
        raise HTTPException(status_code=404, detail="Question not found")

    await db.delete(db_q)
    await db.commit()
    return {"detail": "Question deleted"}

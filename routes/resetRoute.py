from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from database import get_db
import os
import logging
import sqlite3
from starlette.concurrency import run_in_threadpool

router = APIRouter(
    prefix="/reset",
    tags=["reset"],
    responses={404: {"description": "Not found"}},
)

logger = logging.getLogger(__name__)


@router.post("/", status_code=status.HTTP_200_OK)
async def reset_database(db: AsyncSession = Depends(get_db)):
    """
    Reset the database by executing the script.sql file.
    This will drop all tables and recreate them with sample data.
    WARNING: This will delete all existing data!
    """
    try:
        # Get the path to the script.sql file
        script_path = os.path.join(os.path.dirname(__file__), "..", "script.sql")

        # Check if script.sql exists
        if not os.path.exists(script_path):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="script.sql file not found",
            )

        # Read the SQL script
        with open(script_path, "r", encoding="utf-8") as file:
            sql_script = file.read()

        # Try executing the whole script using the AsyncSession.
        # Some SQLite dialects/drivers don't allow executing multiple statements at once,
        # so we fallback to a synchronous sqlite3 execution in a threadpool if needed.
        try:
            await db.execute(text(sql_script))
            await db.commit()
            logger.info("Executed script.sql via AsyncSession")
            return {"message": "Database reset completed successfully (async)"}
        except Exception as async_err:
            logger.warning(
                f"Async execution failed, falling back to sqlite3: {async_err}"
            )

        # Fallback: run the SQL script synchronously with sqlite3 inside a threadpool
        def _run_script_sync(path: str):
            db_file = os.path.join(os.getcwd(), "giasu.db")
            conn = sqlite3.connect(db_file)
            try:
                cur = conn.cursor()
                cur.executescript(sql_script)
                conn.commit()
            finally:
                conn.close()

        try:
            await run_in_threadpool(_run_script_sync, script_path)
            logger.info("Executed script.sql via sqlite3 fallback")
            return {
                "message": "Database reset completed successfully (sqlite3 fallback)"
            }
        except Exception as fallback_err:
            logger.error(f"Fallback sqlite3 execution failed: {fallback_err}")
            raise

        logger.info("Database reset completed successfully")
        return {
            "message": "Database reset completed successfully",
            "details": "All tables dropped and recreated with sample data",
        }

    except Exception as e:
        logger.error(f"Database reset failed: {e}")
        try:
            await db.rollback()
        except Exception:
            pass
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database reset failed: {str(e)}",
        )

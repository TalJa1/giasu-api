from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from database import get_db
import os
import logging

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

        # Split the script into individual statements
        # Remove comments and empty lines
        statements = []
        for line in sql_script.split("\n"):
            line = line.strip()
            # Skip comments and empty lines
            if line and not line.startswith("--"):
                statements.append(line)

        # Join back and split by semicolons
        sql_content = "\n".join(statements)
        sql_statements = [
            stmt.strip() for stmt in sql_content.split(";") if stmt.strip()
        ]

        # Execute each SQL statement
        for statement in sql_statements:
            if statement:  # Skip empty statements
                try:
                    await db.execute(text(statement))
                    logger.info(f"Executed SQL statement: {statement[:50]}...")
                except Exception as stmt_error:
                    logger.error(
                        f"Error executing statement: {statement[:50]}... - {stmt_error}"
                    )
                    # Continue with other statements even if one fails
                    continue

        # Commit all changes
        await db.commit()

        logger.info("Database reset completed successfully")
        return {
            "message": "Database reset completed successfully",
            "details": "All tables dropped and recreated with sample data",
        }

    except Exception as e:
        logger.error(f"Database reset failed: {e}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database reset failed: {str(e)}",
        )

from datetime import datetime
from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import HTTPAuthorizationCredentials

from ..auth import get_current_user
from ..database import get_pool
from ..models import (
    WorkoutSessionCreate,
    WorkoutSessionResponse,
    WorkoutSessionListResponse,
    SessionExerciseCreate,
    SessionExerciseResponse,
    SessionSetCreate,
    SessionSetResponse,
)

router = APIRouter(prefix="/sessions", tags=["sessions"])


async def get_session_with_exercises(
    session_id: UUID,
    user_id: UUID
) -> WorkoutSessionResponse:
    pool = await get_pool()
    async with pool.acquire() as conn:
        session_row = await conn.fetchrow(
            """
            SELECT id, user_id, plan_id, date, week_number
            FROM workout_sessions
            WHERE id = $1 AND user_id = $2
            """,
            session_id, user_id
        )
        if not session_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found"
            )

        exercise_rows = await conn.fetch(
            """
            SELECT id, exercise_name, note, order_index
            FROM session_exercises
            WHERE session_id = $1
            ORDER BY order_index
            """,
            session_id
        )

        exercises = []
        for exercise_row in exercise_rows:
            set_rows = await conn.fetch(
                """
                SELECT id, reps, weight, rpe, set_order
                FROM session_sets
                WHERE session_exercise_id = $1
                ORDER BY set_order
                """,
                exercise_row["id"]
            )

            sets = [
                SessionSetResponse(
                    id=row["id"],
                    reps=row["reps"],
                    weight=float(row["weight"]),
                    rpe=row["rpe"],
                    set_order=row["set_order"]
                )
                for row in set_rows
            ]

            exercises.append(SessionExerciseResponse(
                id=exercise_row["id"],
                exercise_name=exercise_row["exercise_name"],
                note=exercise_row["note"],
                order_index=exercise_row["order_index"],
                sets=sets
            ))

        return WorkoutSessionResponse(
            id=session_row["id"],
            user_id=session_row["user_id"],
            plan_id=session_row["plan_id"],
            date=session_row["date"],
            week_number=session_row["week_number"],
            exercises=exercises
        )


@router.get("", response_model=List[WorkoutSessionListResponse])
async def list_sessions(
    current_user: HTTPAuthorizationCredentials = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        session_rows = await conn.fetch(
            """
            SELECT ws.id, ws.user_id, ws.plan_id, ws.date, ws.week_number, wp.name as plan_name
            FROM workout_sessions ws
            LEFT JOIN workout_plans wp ON ws.plan_id = wp.id
            WHERE ws.user_id = $1
            ORDER BY ws.date DESC
            """,
            current_user.user_id
        )

        return [
            WorkoutSessionListResponse(
                id=row["id"],
                user_id=row["user_id"],
                plan_id=row["plan_id"],
                date=row["date"],
                week_number=row["week_number"],
                plan_name=row["plan_name"]
            )
            for row in session_rows
        ]


@router.post("", response_model=WorkoutSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(
    session: WorkoutSessionCreate,
    current_user: HTTPAuthorizationCredentials = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            session_id = await conn.fetchval(
                """
                INSERT INTO workout_sessions (user_id, plan_id, date, week_number)
                VALUES ($1, $2, $3, $4)
                RETURNING id
                """,
                current_user.user_id,
                session.plan_id,
                session.date or datetime.utcnow(),
                session.week_number
            )

            for ex_idx, exercise in enumerate(session.exercises):
                exercise_id = await conn.fetchval(
                    """
                    INSERT INTO session_exercises (session_id, exercise_name, note, order_index)
                    VALUES ($1, $2, $3, $4)
                    RETURNING id
                    """,
                    session_id,
                    exercise.exercise_name,
                    exercise.note,
                    ex_idx
                )

                for set_idx, set_data in enumerate(exercise.sets):
                    await conn.execute(
                        """
                        INSERT INTO session_sets (session_exercise_id, reps, weight, rpe, set_order)
                        VALUES ($1, $2, $3, $4, $5)
                        """,
                        exercise_id,
                        set_data.reps,
                        set_data.weight,
                        set_data.rpe,
                        set_idx
                    )

    return await get_session_with_exercises(session_id, current_user.user_id)


@router.get("/{session_id}", response_model=WorkoutSessionResponse)
async def get_session(
    session_id: UUID,
    current_user: HTTPAuthorizationCredentials = Depends(get_current_user)
):
    return await get_session_with_exercises(session_id, current_user.user_id)


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(
    session_id: UUID,
    current_user: HTTPAuthorizationCredentials = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        result = await conn.execute(
            "DELETE FROM workout_sessions WHERE id = $1 AND user_id = $2",
            session_id, current_user.user_id
        )
        if result == "DELETE 0":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found"
            )

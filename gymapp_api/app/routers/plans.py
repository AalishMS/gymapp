from datetime import datetime
from typing import List
from uuid import UUID
from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import HTTPAuthorizationCredentials

from ..auth import get_current_user
from ..database import get_pool
from ..models import (
    WorkoutPlanCreate,
    WorkoutPlanUpdate,
    WorkoutPlanResponse,
    PlanExerciseCreate,
    PlanExerciseResponse,
)

router = APIRouter(prefix="/plans", tags=["plans"])


async def get_plan_with_exercises(plan_id: UUID, user_id: UUID) -> WorkoutPlanResponse:
    pool = await get_pool()
    async with pool.acquire() as conn:
        plan_row = await conn.fetchrow(
            """
            SELECT id, user_id, name, created_at 
            FROM workout_plans 
            WHERE id = $1 AND user_id = $2
            """,
            plan_id, user_id
        )
        if not plan_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plan not found"
            )

        exercise_rows = await conn.fetch(
            """
            SELECT id, exercise_name, sets, order_index
            FROM plan_exercises
            WHERE plan_id = $1
            ORDER BY order_index
            """,
            plan_id
        )

        exercises = [
            PlanExerciseResponse(
                id=row["id"],
                exercise_name=row["exercise_name"],
                sets=row["sets"],
                order_index=row["order_index"]
            )
            for row in exercise_rows
        ]

        return WorkoutPlanResponse(
            id=plan_row["id"],
            user_id=plan_row["user_id"],
            name=plan_row["name"],
            created_at=plan_row["created_at"],
            exercises=exercises
        )


@router.get("", response_model=List[WorkoutPlanResponse])
async def list_plans(
    current_user: HTTPAuthorizationCredentials = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        plan_rows = await conn.fetch(
            """
            SELECT id, user_id, name, created_at
            FROM workout_plans
            WHERE user_id = $1
            ORDER BY created_at DESC
            """,
            current_user.user_id
        )

        plans = []
        for plan_row in plan_rows:
            exercise_rows = await conn.fetch(
                """
                SELECT id, exercise_name, sets, order_index
                FROM plan_exercises
                WHERE plan_id = $1
                ORDER BY order_index
                """,
                plan_row["id"]
            )

            exercises = [
                PlanExerciseResponse(
                    id=row["id"],
                    exercise_name=row["exercise_name"],
                    sets=row["sets"],
                    order_index=row["order_index"]
                )
                for row in exercise_rows
            ]

            plans.append(WorkoutPlanResponse(
                id=plan_row["id"],
                user_id=plan_row["user_id"],
                name=plan_row["name"],
                created_at=plan_row["created_at"],
                exercises=exercises
            ))

        return plans


@router.post("", response_model=WorkoutPlanResponse, status_code=status.HTTP_201_CREATED)
async def create_plan(
    plan: WorkoutPlanCreate,
    current_user: HTTPAuthorizationCredentials = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            plan_id = await conn.fetchval(
                """
                INSERT INTO workout_plans (user_id, name)
                VALUES ($1, $2)
                RETURNING id
                """,
                current_user.user_id, plan.name
            )

            exercises = []
            for idx, exercise in enumerate(plan.exercises):
                exercise_id = await conn.fetchval(
                    """
                    INSERT INTO plan_exercises (plan_id, exercise_name, sets, order_index)
                    VALUES ($1, $2, $3, $4)
                    RETURNING id
                    """,
                    plan_id,
                    exercise.exercise_name,
                    exercise.sets,
                    idx
                )
                exercises.append(PlanExerciseResponse(
                    id=exercise_id,
                    exercise_name=exercise.exercise_name,
                    sets=exercise.sets,
                    order_index=idx
                ))

            created_at = await conn.fetchval(
                "SELECT created_at FROM workout_plans WHERE id = $1",
                plan_id
            )

            return WorkoutPlanResponse(
                id=plan_id,
                user_id=current_user.user_id,
                name=plan.name,
                created_at=created_at,
                exercises=exercises
            )


@router.put("/{plan_id}", response_model=WorkoutPlanResponse)
async def update_plan(
    plan_id: UUID,
    plan_update: WorkoutPlanUpdate,
    current_user: HTTPAuthorizationCredentials = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        existing = await conn.fetchrow(
            "SELECT id FROM workout_plans WHERE id = $1 AND user_id = $2",
            plan_id, current_user.user_id
        )
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plan not found"
            )

        async with conn.transaction():
            if plan_update.name is not None:
                await conn.execute(
                    "UPDATE workout_plans SET name = $1 WHERE id = $2",
                    plan_update.name, plan_id
                )

            if plan_update.exercises is not None:
                await conn.execute(
                    "DELETE FROM plan_exercises WHERE plan_id = $1",
                    plan_id
                )

                for idx, exercise in enumerate(plan_update.exercises):
                    await conn.execute(
                        """
                        INSERT INTO plan_exercises (plan_id, exercise_name, sets, order_index)
                        VALUES ($1, $2, $3, $4)
                        """,
                        plan_id,
                        exercise.exercise_name,
                        exercise.sets,
                        idx
                    )

    return await get_plan_with_exercises(plan_id, current_user.user_id)


@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_plan(
    plan_id: UUID,
    current_user: HTTPAuthorizationCredentials = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        result = await conn.execute(
            "DELETE FROM workout_plans WHERE id = $1 AND user_id = $2",
            plan_id, current_user.user_id
        )
        if result == "DELETE 0":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plan not found"
            )

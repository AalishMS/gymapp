from datetime import datetime
from typing import Optional, List
from uuid import UUID
from pydantic import BaseModel


# Plan Exercise schemas
class PlanSetDefault(BaseModel):
    reps: int = 8
    weight: float = 0.0
    rpe: Optional[int] = None
    note: Optional[str] = None
    set_order: int = 0


class PlanExerciseBase(BaseModel):
    exercise_name: str
    sets: int = 3
    order_index: int = 0
    set_defaults: List[PlanSetDefault] = []


class PlanExerciseCreate(PlanExerciseBase):
    pass


class PlanExerciseResponse(PlanExerciseBase):
    id: UUID

    class Config:
        from_attributes = True


# Workout Plan schemas
class WorkoutPlanBase(BaseModel):
    name: str


class WorkoutPlanCreate(WorkoutPlanBase):
    exercises: List[PlanExerciseCreate] = []


class WorkoutPlanUpdate(BaseModel):
    name: Optional[str] = None
    exercises: Optional[List[PlanExerciseCreate]] = None


class WorkoutPlanResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    created_at: datetime
    exercises: List[PlanExerciseResponse] = []

    class Config:
        from_attributes = True


# Session Set schemas
class SessionSetBase(BaseModel):
    reps: int
    weight: float
    rpe: Optional[int] = None
    set_order: int = 0


class SessionSetCreate(SessionSetBase):
    pass


class SessionSetResponse(SessionSetBase):
    id: UUID

    class Config:
        from_attributes = True


# Session Exercise schemas
class SessionExerciseBase(BaseModel):
    exercise_name: str
    note: Optional[str] = None
    order_index: int = 0


class SessionExerciseCreate(SessionExerciseBase):
    sets: List[SessionSetCreate] = []


class SessionExerciseResponse(SessionExerciseBase):
    id: UUID
    sets: List[SessionSetResponse] = []

    class Config:
        from_attributes = True


# Workout Session schemas
class WorkoutSessionBase(BaseModel):
    plan_id: Optional[UUID] = None
    date: Optional[datetime] = None
    week_number: int = 1


class WorkoutSessionCreate(WorkoutSessionBase):
    exercises: List[SessionExerciseCreate] = []


class WorkoutSessionResponse(BaseModel):
    id: UUID
    user_id: UUID
    plan_id: Optional[UUID]
    date: datetime
    week_number: int
    exercises: List[SessionExerciseResponse] = []

    class Config:
        from_attributes = True


class WorkoutSessionListResponse(BaseModel):
    id: UUID
    user_id: UUID
    plan_id: Optional[UUID]
    date: datetime
    week_number: int
    plan_name: Optional[str] = None

    class Config:
        from_attributes = True

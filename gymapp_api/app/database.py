import os
from typing import Optional
from uuid import UUID
import asyncpg
from pydantic import BaseModel


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/opengym")

_pool: Optional[asyncpg.Pool] = None


async def get_pool() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(DATABASE_URL, min_size=2, max_size=10)
    return _pool


async def close_pool():
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None


class UserResponse(BaseModel):
    id: UUID
    email: str

    class Config:
        from_attributes = True


async def get_user_by_id(user_id: UUID) -> Optional[UserResponse]:
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, email FROM users WHERE id = $1",
            user_id
        )
        if row:
            return UserResponse(id=row["id"], email=row["email"])
        return None


async def get_user_by_email(email: str) -> Optional[UserResponse]:
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, email FROM users WHERE email = $1",
            email
        )
        if row:
            return UserResponse(id=row["id"], email=row["email"])
        return None

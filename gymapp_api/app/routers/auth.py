from datetime import datetime
from typing import Optional
from uuid import UUID
from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr
import asyncpg
from passlib.hash import bcrypt

from ..database import get_pool
from ..auth import create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


class UserCreate(BaseModel):
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    user_id: UUID
    email: str
    access_token: str
    token_type: str = "bearer"


@router.post("/register", response_model=AuthResponse)
async def register(user: UserCreate):
    pool = await get_pool()
    async with pool.acquire() as conn:
        existing = await conn.fetchrow(
            "SELECT id FROM users WHERE email = $1",
            user.email
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )

        user_id = await conn.fetchval(
            """
            INSERT INTO users (email, password_hash)
            VALUES ($1, $2)
            RETURNING id
            """,
            user.email,
            bcrypt.hash(user.password)
        )

    access_token = create_access_token(user_id, user.email)
    return AuthResponse(
        user_id=user_id,
        email=user.email,
        access_token=access_token
    )


@router.post("/login", response_model=AuthResponse)
async def login(user: UserLogin):
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, email, password_hash FROM users WHERE email = $1",
            user.email
        )
        if not row:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )

        if not bcrypt.verify(user.password, row["password_hash"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )

    access_token = create_access_token(row["id"], row["email"])
    return AuthResponse(
        user_id=row["id"],
        email=row["email"],
        access_token=access_token
    )


@router.get("/me")
async def get_me(current_user: Depends = Depends(get_current_user)):
    return {
        "user_id": current_user.user_id,
        "email": current_user.email
    }

import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import close_pool
from .routers import plans, sessions, auth


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await close_pool()


app = FastAPI(
    title="OpenGym API",
    description="Backend API for OpenGym workout tracking app",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(plans.router)
app.include_router(sessions.router)
app.include_router(auth.router)


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.get("/version")
async def app_version():
    return {
        "version": "1.0.1",
        "apk_url": "https://github.com/AalishMS/gymapp/releases/latest/download/app-release.apk",
        "release_notes": "Fix workout dialog crashes, improve startup stability, and polish themed dialogs.",
    }

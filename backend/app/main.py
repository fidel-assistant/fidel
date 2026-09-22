from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.exceptions import register_exception_handlers
from app.routers import (
    aidants,
    auth,
    devices,
    health,
    horaires,
    internal_jobs,
    medicaments,
    notifications,
    onboarding,
    patient_suivi,
    patients,
    prises,
    sos,
    sync,
    traitements,
)
from app.web.paths import STATIC_DIR
from app.web.router import router as web_router


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    # Startup / shutdown hooks (DB pool, etc.) — à compléter
    yield


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_exception_handlers(app)

app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")
app.include_router(web_router)

app.include_router(health.router, prefix=settings.api_v1_prefix, tags=["health"])
app.include_router(auth.router, prefix=settings.api_v1_prefix)
app.include_router(onboarding.router, prefix=settings.api_v1_prefix)
app.include_router(patients.router, prefix=settings.api_v1_prefix)
app.include_router(patient_suivi.router, prefix=settings.api_v1_prefix)
app.include_router(traitements.router, prefix=settings.api_v1_prefix)
app.include_router(medicaments.router, prefix=settings.api_v1_prefix)
app.include_router(horaires.router, prefix=settings.api_v1_prefix)
app.include_router(prises.router, prefix=settings.api_v1_prefix)
app.include_router(sync.router, prefix=settings.api_v1_prefix)
app.include_router(sos.router, prefix=settings.api_v1_prefix)
app.include_router(aidants.router, prefix=settings.api_v1_prefix)
app.include_router(devices.router, prefix=settings.api_v1_prefix)
app.include_router(notifications.router, prefix=settings.api_v1_prefix)
app.include_router(internal_jobs.router, prefix=settings.api_v1_prefix)

"""Photo de profil patient — stockage local sous MEDIA_ROOT."""

from __future__ import annotations

from pathlib import Path
from uuid import uuid4

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppException
from app.core.image_validation import validate_profile_photo
from app.models import User
from app.services.onboarding_service import _require_patient, _serialize_patient


def _media_root() -> Path:
    root = Path(settings.media_root)
    if not root.is_absolute():
        root = Path.cwd() / root
    root.mkdir(parents=True, exist_ok=True)
    return root


def _absolute_path(relative: str) -> Path:
    path = _media_root() / relative
    try:
        path.resolve().relative_to(_media_root().resolve())
    except ValueError as exc:
        raise AppException(
            "PHOTO_NOT_FOUND",
            "Fichier photo introuvable.",
            status_code=404,
        ) from exc
    return path


def public_photo_url() -> str:
    base = settings.public_base_url.rstrip("/")
    prefix = settings.api_v1_prefix.rstrip("/")
    return f"{base}{prefix}/patients/me/photo"


def photo_url_for_client(stored: str | None) -> str | None:
    """Réécrit un chemin relatif `photos/…` en URL API ; laisse les URL externes."""
    if not stored:
        return None
    if stored.startswith("photos/"):
        return public_photo_url()
    return stored


def _delete_file_quiet(relative: str | None) -> None:
    if not relative or not relative.startswith("photos/"):
        return
    try:
        path = _absolute_path(relative)
        if path.is_file():
            path.unlink()
    except AppException:
        return
    except OSError:
        return


def _patient_out(patient) -> dict:
    data = _serialize_patient(patient)
    data["photo_url"] = photo_url_for_client(patient.photo_url)
    return data


async def upload_photo(
    db: AsyncSession,
    *,
    user: User,
    filename: str | None,
    content_type: str | None,
    data: bytes,
) -> dict:
    patient = _require_patient(user)
    validated = validate_profile_photo(
        filename=filename, content_type=content_type, data=data
    )
    old = patient.photo_url
    relative = f"photos/{patient.user_id}/{uuid4()}.{validated.extension}"
    dest = _absolute_path(relative)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)

    patient.photo_url = relative
    await db.commit()
    await db.refresh(patient)
    if old and old != relative:
        _delete_file_quiet(old)
    return _patient_out(patient)


async def delete_photo(db: AsyncSession, *, user: User) -> dict:
    patient = _require_patient(user)
    old = patient.photo_url
    patient.photo_url = None
    await db.commit()
    await db.refresh(patient)
    _delete_file_quiet(old)
    return _patient_out(patient)


async def resolve_photo_file(db: AsyncSession, *, user: User) -> tuple[Path, str]:
    patient = _require_patient(user)
    stored = patient.photo_url
    if not stored or not stored.startswith("photos/"):
        raise AppException(
            "PHOTO_NOT_FOUND",
            "Aucune photo de profil n'est configurée.",
            status_code=404,
        )
    path = _absolute_path(stored)
    if not path.is_file():
        raise AppException(
            "PHOTO_NOT_FOUND",
            "Le fichier photo est introuvable sur le serveur.",
            status_code=404,
        )
    ext = path.suffix.lstrip(".").lower()
    media = {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
    }.get(ext, "application/octet-stream")
    return path, media

"""Validation stricte des photos de profil patient."""

from __future__ import annotations

from dataclasses import dataclass

from app.core.config import settings
from app.core.exceptions import AppException

ALLOWED_EXTENSIONS = frozenset({"jpg", "jpeg", "png", "webp"})
ALLOWED_CONTENT_TYPES = frozenset(
    {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "application/octet-stream",
    }
)


def raise_too_large(max_bytes: int | None = None) -> None:
    limit = max_bytes if max_bytes is not None else settings.patient_photo_max_bytes
    max_mo = limit / (1024 * 1024)
    raise AppException(
        "FICHIER_PHOTO_TROP_LOURD",
        f"Fichier trop lourd. Maximum autorisé : {max_mo:.0f} Mo.",
        status_code=413,
    )


async def read_photo_upload_limited(upload, *, max_bytes: int | None = None) -> bytes:
    """Lit un UploadFile en flux ; coupe dès que la limite photo est dépassée."""
    limit = max_bytes if max_bytes is not None else settings.patient_photo_max_bytes
    chunks: list[bytes] = []
    total = 0
    while True:
        chunk = await upload.read(64 * 1024)
        if not chunk:
            break
        total += len(chunk)
        if total > limit:
            raise_too_large(limit)
        chunks.append(chunk)
    return b"".join(chunks)


@dataclass(frozen=True)
class ImageValidationResult:
    extension: str
    content_type: str


def validate_profile_photo(
    *,
    filename: str | None,
    content_type: str | None,
    data: bytes,
) -> ImageValidationResult:
    max_bytes = settings.patient_photo_max_bytes
    if len(data) == 0:
        raise AppException(
            "FICHIER_PHOTO_INVALIDE",
            "Le fichier photo est vide.",
            status_code=400,
        )
    if len(data) > max_bytes:
        raise_too_large(max_bytes)

    ext = _extension(filename)
    if ext not in ALLOWED_EXTENSIONS:
        raise AppException(
            "FICHIER_PHOTO_INVALIDE",
            "Format non autorisé. Utilise jpeg, png ou webp.",
            status_code=400,
        )

    kind = _detect_kind(data)
    if kind is None:
        raise AppException(
            "FICHIER_PHOTO_INVALIDE",
            "Le contenu du fichier n'est pas une image valide (jpeg/png/webp).",
            status_code=400,
        )

    if not _extension_matches_kind(ext, kind):
        raise AppException(
            "FICHIER_PHOTO_INVALIDE",
            "L'extension du fichier ne correspond pas à son contenu image.",
            status_code=400,
        )

    ct = (content_type or "").split(";")[0].strip().lower()
    if ct and ct not in ALLOWED_CONTENT_TYPES:
        raise AppException(
            "FICHIER_PHOTO_INVALIDE",
            "Type MIME non autorisé pour une photo de profil.",
            status_code=400,
        )

    # Normalise jpeg → jpg pour le stockage
    stored_ext = "jpg" if kind == "jpeg" else kind
    return ImageValidationResult(
        extension=stored_ext,
        content_type=ct or _default_content_type(kind),
    )


def _extension(filename: str | None) -> str:
    if not filename or "." not in filename:
        return ""
    return filename.rsplit(".", 1)[-1].strip().lower()


def _detect_kind(data: bytes) -> str | None:
    if len(data) < 12:
        return None
    if data[:3] == b"\xff\xd8\xff":
        return "jpeg"
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "webp"
    return None


def _extension_matches_kind(ext: str, kind: str) -> bool:
    if kind == "jpeg":
        return ext in {"jpg", "jpeg"}
    if kind == "png":
        return ext == "png"
    if kind == "webp":
        return ext == "webp"
    return False


def _default_content_type(kind: str) -> str:
    return {
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
    }.get(kind, "application/octet-stream")

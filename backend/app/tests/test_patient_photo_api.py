"""API photo de profil patient."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

from app.tests.test_voix_rappel_api import _onboard_patient


def _fake_jpeg(size: int = 256) -> bytes:
    # Minimal JPEG SOI + APP0-ish + EOI padding
    body = b"\xff\xd8\xff\xe0" + b"\x00" * 8 + b"\xff\xd9"
    if size <= len(body):
        return body[:size]
    return body + b"\x00" * (size - len(body))


def _fake_png(size: int = 256) -> bytes:
    body = b"\x89PNG\r\n\x1a\n" + b"\x00" * 16
    if size <= len(body):
        return body[:size]
    return body + b"\x00" * (size - len(body))


@pytest.mark.asyncio
async def test_patient_photo_upload_download_delete(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    tmp_path,
    monkeypatch,
) -> None:
    from app.core.config import settings

    monkeypatch.setattr(settings, "media_root", str(tmp_path / "media"))
    monkeypatch.setattr(settings, "patient_photo_max_bytes", 2 * 1024 * 1024)

    api = settings.api_v1_prefix
    headers = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="photo.patient@example.com",
    )

    r = await client.get(f"{api}/patients/me", headers=headers)
    assert r.status_code == 200
    assert r.json().get("photo_url") in (None, "")

    jpeg = _fake_jpeg(512)
    r = await client.put(
        f"{api}/patients/me/photo",
        headers=headers,
        files={"fichier": ("avatar.jpg", jpeg, "image/jpeg")},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["photo_url"]
    assert body["photo_url"].endswith("/patients/me/photo")

    r = await client.get(f"{api}/patients/me/photo", headers=headers)
    assert r.status_code == 200
    assert r.content.startswith(b"\xff\xd8\xff")
    assert "image/jpeg" in r.headers.get("content-type", "")

    r = await client.delete(f"{api}/patients/me/photo", headers=headers)
    assert r.status_code == 200
    assert r.json().get("photo_url") is None

    r = await client.get(f"{api}/patients/me/photo", headers=headers)
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "PHOTO_NOT_FOUND"


@pytest.mark.asyncio
async def test_patient_photo_rejects_bad_type_and_oversize(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    tmp_path,
    monkeypatch,
) -> None:
    from app.core.config import settings

    monkeypatch.setattr(settings, "media_root", str(tmp_path / "media"))
    monkeypatch.setattr(settings, "patient_photo_max_bytes", 1024)

    api = settings.api_v1_prefix
    headers = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="photo.bad@example.com",
    )

    r = await client.put(
        f"{api}/patients/me/photo",
        headers=headers,
        files={"fichier": ("note.txt", b"not an image", "text/plain")},
    )
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "FICHIER_PHOTO_INVALIDE"

    r = await client.put(
        f"{api}/patients/me/photo",
        headers=headers,
        files={"fichier": ("big.jpg", _fake_jpeg(2048), "image/jpeg")},
    )
    assert r.status_code == 413
    assert r.json()["error"]["code"] == "FICHIER_PHOTO_TROP_LOURD"

    r = await client.put(
        f"{api}/patients/me/photo",
        headers=headers,
        files={"fichier": ("ok.png", _fake_png(200), "image/png")},
    )
    assert r.status_code == 200, r.text

"""Formulaire contact landing — validation + envoi."""

from __future__ import annotations

import logging
import re

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.services.email_service import send_contact_message

logger = logging.getLogger(__name__)

_NAME_RE = re.compile(r"^[\w\s\-'.àâäéèêëïîôùûüçÀÂÄÉÈÊËÏÎÔÙÛÜÇ]{2,80}$", re.UNICODE)


class ContactFormIn(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    email: EmailStr
    message: str = Field(min_length=10, max_length=4000)
    # Honeypot — doit rester vide
    company: str = ""

    @field_validator("name")
    @classmethod
    def name_ok(cls, v: str) -> str:
        cleaned = v.strip()
        if not _NAME_RE.match(cleaned):
            raise ValueError("Nom invalide")
        return cleaned

    @field_validator("message")
    @classmethod
    def message_ok(cls, v: str) -> str:
        return v.strip()


async def submit_contact(form: ContactFormIn) -> None:
    if form.company.strip():
        logger.info("Contact honeypot rempli — ignoré")
        return
    await send_contact_message(
        name=form.name,
        reply_email=str(form.email),
        message=form.message,
    )

"""Schémas API — gestion aidants (côté patient + vue aidant)."""

from __future__ import annotations

from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field


class NiveauPermission(BaseModel):
    observance: bool = True
    constantes: bool = False


class AidantRelationOut(BaseModel):
    aidant_id: UUID
    nom: str | None
    statut: str
    niveau_permission: NiveauPermission


class AidantPermissionsIn(BaseModel):
    niveau_permission: NiveauPermission


class MessageOut(BaseModel):
    message: str


class AidantPatientOut(BaseModel):
    patient_id: UUID
    prenom: str
    niveau_permission: NiveauPermission


class ObservanceOut(BaseModel):
    patient_id: UUID
    patient_prenom: str
    depuis: date
    jusqu_a: date
    total: int
    confirmees: int
    manquees: int
    en_attente: int
    taux_observance: float | None = Field(
        default=None,
        description="confirmees / (confirmees + manquees), null si aucune prise passée",
    )


class AidantNotificationPrefs(BaseModel):
    mute_prise_confirmee: bool = False
    mute_prise_non_confirmee: bool = False
    mute_sos: bool = False


class AidantNotificationPrefsPatch(BaseModel):
    mute_prise_confirmee: bool | None = None
    mute_prise_non_confirmee: bool | None = None
    mute_sos: bool | None = None

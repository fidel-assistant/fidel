"""Gestion des relations patient ↔ aidant et vue observance."""

from __future__ import annotations

from datetime import UTC, date, datetime, time, timedelta
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import AppException
from app.models import (
    Medicament,
    MedicamentHoraire,
    Patient,
    PatientAidant,
    PatientTraitement,
    Prise,
    User,
)
from app.services.onboarding_service import (
    _require_patient,
    get_user_with_capabilities,
    is_aidant,
)
from app.services.patient_suivi_service import _combine_local, _patient_tz

DEFAULT_PERMISSIONS = {"observance": True, "constantes": False}
DEFAULT_NOTIFICATION_PREFS = {
    "mute_prise_confirmee": False,
    "mute_prise_non_confirmee": False,
    "mute_sos": False,
}
OBSERVANCE_WINDOW_DAYS = 7


def _normalize_permissions(raw: dict | None) -> dict:
    base = dict(DEFAULT_PERMISSIONS)
    if not raw:
        return base
    if "observance" in raw:
        base["observance"] = bool(raw["observance"])
    if "constantes" in raw:
        base["constantes"] = bool(raw["constantes"])
    return base


def _normalize_notification_prefs(raw: dict | None) -> dict:
    base = dict(DEFAULT_NOTIFICATION_PREFS)
    if not raw:
        return base
    for key in DEFAULT_NOTIFICATION_PREFS:
        if key in raw:
            base[key] = bool(raw[key])
    return base


def _prenom(nom_complet: str | None, fallback: str = "Patient") -> str:
    if not nom_complet or not nom_complet.strip():
        return fallback
    return nom_complet.strip().split()[0]


async def list_patient_aidants(db: AsyncSession, *, user: User) -> list[dict]:
    patient = _require_patient(user)
    result = await db.execute(
        select(PatientAidant)
        .where(
            PatientAidant.patient_id == patient.user_id,
            PatientAidant.statut == "actif",
            PatientAidant.revoked_at.is_(None),
        )
        .options(selectinload(PatientAidant.aidant))
        .order_by(PatientAidant.created_at.desc())
    )
    rows = []
    for rel in result.scalars().all():
        aidant = rel.aidant
        rows.append(
            {
                "aidant_id": rel.aidant_id,
                "nom": aidant.nom_complet if aidant else None,
                "statut": rel.statut,
                "niveau_permission": _normalize_permissions(rel.niveau_permission),
            }
        )
    return rows


async def update_aidant_permissions(
    db: AsyncSession,
    *,
    user: User,
    aidant_id: UUID,
    niveau_permission: dict,
) -> dict:
    patient = _require_patient(user)
    rel = await _active_relation_for_patient(
        db, patient_id=patient.user_id, aidant_id=aidant_id
    )
    perms = _normalize_permissions(niveau_permission)
    rel.niveau_permission = perms
    await db.commit()

    await db.refresh(rel, attribute_names=["aidant"])
    aidant = rel.aidant
    return {
        "aidant_id": rel.aidant_id,
        "nom": aidant.nom_complet if aidant else None,
        "statut": rel.statut,
        "niveau_permission": perms,
    }


async def revoke_aidant(db: AsyncSession, *, user: User, aidant_id: UUID) -> dict:
    patient = _require_patient(user)
    rel = await _active_relation_for_patient(
        db, patient_id=patient.user_id, aidant_id=aidant_id
    )
    rel.statut = "revoque"
    rel.revoked_at = datetime.now(UTC)
    await db.commit()
    return {"message": "L'aidant n'a plus accès à ton suivi."}


async def list_aidant_patients(db: AsyncSession, *, user: User) -> list[dict]:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    if not is_aidant(refreshed):
        raise AppException(
            "NOT_AN_AIDANT",
            "Tu n'accompagnes encore personne. Scanne un code depuis l'accueil.",
            status_code=403,
        )

    result = await db.execute(
        select(PatientAidant)
        .where(
            PatientAidant.aidant_id == refreshed.id,
            PatientAidant.statut == "actif",
            PatientAidant.revoked_at.is_(None),
        )
        .options(selectinload(PatientAidant.patient))
        .order_by(PatientAidant.created_at.desc())
    )
    rows = []
    for rel in result.scalars().all():
        patient = rel.patient
        rows.append(
            {
                "patient_id": rel.patient_id,
                "prenom": _prenom(patient.nom_complet if patient else None),
                "niveau_permission": _normalize_permissions(rel.niveau_permission),
            }
        )
    return rows


async def get_patient_observance(
    db: AsyncSession,
    *,
    user: User,
    patient_id: UUID,
    depuis: date | None = None,
    jusqu_a: date | None = None,
) -> dict:
    rel = await assert_aidant_permission(
        db, user=user, patient_id=patient_id, permission="observance"
    )
    # relation déjà validée ; on garde le patient pour le prénom
    _ = rel

    patient = await db.get(Patient, patient_id)
    if patient is None:
        raise AppException(
            "PATIENT_NOT_FOUND",
            "Ce suivi patient est introuvable.",
            status_code=404,
        )

    today = datetime.now(UTC).date()
    end = jusqu_a or today
    start = depuis or (end - timedelta(days=OBSERVANCE_WINDOW_DAYS - 1))
    if start > end:
        raise AppException(
            "TYPE_INVALIDE",
            "La date de début doit être avant la date de fin.",
            status_code=400,
        )

    day_start = datetime(start.year, start.month, start.day, tzinfo=UTC)
    day_end = datetime(end.year, end.month, end.day, 23, 59, 59, tzinfo=UTC)

    result = await db.execute(
        select(Prise.statut, func.count())
        .join(MedicamentHoraire, Prise.medicament_horaire_id == MedicamentHoraire.id)
        .join(Medicament, MedicamentHoraire.medicament_id == Medicament.id)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(
            PatientTraitement.patient_id == patient_id,
            Prise.heure_prevue >= day_start,
            Prise.heure_prevue <= day_end,
        )
        .group_by(Prise.statut)
    )
    counts = {statut: count for statut, count in result.all()}
    confirmees = int(counts.get("confirmee", 0))
    manquees = int(counts.get("manquee", 0))
    en_attente = int(counts.get("en_attente", 0))
    total = confirmees + manquees + en_attente
    denom = confirmees + manquees
    taux = round(confirmees / denom, 2) if denom else None

    return {
        "patient_id": patient_id,
        "patient_prenom": _prenom(patient.nom_complet),
        "depuis": start,
        "jusqu_a": end,
        "total": total,
        "confirmees": confirmees,
        "manquees": manquees,
        "en_attente": en_attente,
        "taux_observance": taux,
    }


async def list_patient_prises(
    db: AsyncSession,
    *,
    user: User,
    patient_id: UUID,
    target_date: date | None = None,
) -> list[dict]:
    """Prises du jour déjà créées — lecture seule, sans ensure."""
    await assert_aidant_permission(
        db, user=user, patient_id=patient_id, permission="observance"
    )
    patient_user = await db.get(User, patient_id)
    if patient_user is None:
        raise AppException(
            "PATIENT_NOT_FOUND",
            "Ce suivi patient est introuvable.",
            status_code=404,
        )

    tz = _patient_tz(patient_user)
    day = target_date or datetime.now(tz).date()
    day_start = _combine_local(day, time.min, tz)
    day_end = _combine_local(day, time(23, 59, 59), tz)

    result = await db.execute(
        select(Prise, Medicament, PatientTraitement)
        .join(MedicamentHoraire, Prise.medicament_horaire_id == MedicamentHoraire.id)
        .join(Medicament, MedicamentHoraire.medicament_id == Medicament.id)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(
            PatientTraitement.patient_id == patient_id,
            PatientTraitement.statut == "actif",
            Medicament.actif.is_(True),
            Prise.heure_prevue >= day_start,
            Prise.heure_prevue <= day_end,
        )
        .options(selectinload(PatientTraitement.maladie))
        .order_by(Prise.heure_prevue)
    )
    rows = []
    for prise, med, traitement in result.all():
        maladie = traitement.maladie
        rows.append(
            {
                "id": prise.id,
                "medicament_id": med.id,
                "medicament_nom": med.nom,
                "dosage": med.dosage,
                "heure_prevue": prise.heure_prevue,
                "statut": prise.statut,
                "confirmee_at": prise.confirmee_at,
                "canal": prise.canal,
                "traitement_id": traitement.id,
                "maladie_id": traitement.maladie_id,
                "maladie_nom": maladie.nom
                if maladie
                else (traitement.maladie_libelle or ""),
            }
        )
    return rows


async def get_notification_prefs(
    db: AsyncSession, *, user: User, patient_id: UUID
) -> dict:
    rel = await require_aidant_of_patient(
        db, aidant_id=user.id, patient_id=patient_id
    )
    return _normalize_notification_prefs(rel.notification_prefs)


async def patch_notification_prefs(
    db: AsyncSession,
    *,
    user: User,
    patient_id: UUID,
    patch: dict,
) -> dict:
    rel = await require_aidant_of_patient(
        db, aidant_id=user.id, patient_id=patient_id
    )
    current = _normalize_notification_prefs(rel.notification_prefs)
    for key in DEFAULT_NOTIFICATION_PREFS:
        if key in patch and patch[key] is not None:
            current[key] = bool(patch[key])
    rel.notification_prefs = current
    await db.commit()
    await db.refresh(rel)
    return _normalize_notification_prefs(rel.notification_prefs)


async def assert_aidant_permission(
    db: AsyncSession,
    *,
    user: User,
    patient_id: UUID,
    permission: str,
) -> PatientAidant:
    """Vérifie relation active + permission (`observance` / `constantes`)."""
    rel = await _active_relation_for_aidant(
        db, aidant_id=user.id, patient_id=patient_id
    )
    perms = _normalize_permissions(rel.niveau_permission)
    if not perms.get(permission):
        raise AppException(
            "PERMISSION_REFUSEE",
            f"Tu n'as pas l'autorisation « {permission} » pour cette personne.",
            status_code=403,
        )
    return rel


async def require_aidant_of_patient(
    db: AsyncSession, *, aidant_id: UUID, patient_id: UUID
) -> PatientAidant:
    """Relation active aidant↔patient ou PERMISSION_REFUSEE / NOT_AN_AIDANT."""
    return await _active_relation_for_aidant(
        db, aidant_id=aidant_id, patient_id=patient_id
    )


async def _active_relation_for_patient(
    db: AsyncSession, *, patient_id: UUID, aidant_id: UUID
) -> PatientAidant:
    result = await db.execute(
        select(PatientAidant)
        .where(
            PatientAidant.patient_id == patient_id,
            PatientAidant.aidant_id == aidant_id,
            PatientAidant.statut == "actif",
            PatientAidant.revoked_at.is_(None),
        )
        .options(selectinload(PatientAidant.aidant))
    )
    rel = result.scalar_one_or_none()
    if rel is None:
        raise AppException(
            "AIDANT_NOT_FOUND",
            "Cet aidant n'est pas lié à ton suivi.",
            status_code=404,
        )
    return rel


async def _active_relation_for_aidant(
    db: AsyncSession, *, aidant_id: UUID, patient_id: UUID
) -> PatientAidant:
    result = await db.execute(
        select(PatientAidant).where(
            PatientAidant.aidant_id == aidant_id,
            PatientAidant.patient_id == patient_id,
            PatientAidant.statut == "actif",
            PatientAidant.revoked_at.is_(None),
        )
    )
    rel = result.scalar_one_or_none()
    if rel is None:
        raise AppException(
            "PATIENT_NOT_FOUND",
            "Tu n'accompagnes pas cette personne, ou l'accès a été révoqué.",
            status_code=404,
        )
    return rel

"""Logique métier onboarding (capacités) + sync aidant."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from secrets import randbelow
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.exceptions import AppException
from app.models import (
    Maladie,
    Patient,
    PatientAidant,
    PatientTraitement,
    PatientTraitementAttribut,
    SyncCode,
    User,
)

VALID_PHASES = {"debut", "en_cours", "maintenance", "inconnu"}


def has_patient_profile(user: User) -> bool:
    return user.patient is not None


def is_aidant(user: User) -> bool:
    return any(r.statut == "actif" and r.revoked_at is None for r in (user.aidant_relations or []))


def capabilities(user: User) -> dict:
    return {
        "has_patient_profile": has_patient_profile(user),
        "is_aidant": is_aidant(user),
    }


async def get_user_with_capabilities(db: AsyncSession, user_id: UUID) -> User | None:
    result = await db.execute(
        select(User)
        .where(User.id == user_id, User.deleted_at.is_(None))
        .options(
            selectinload(User.patient),
            selectinload(User.aidant_relations),
            selectinload(User.cgu_acceptances),
            selectinload(User.consentement_sante),
        )
    )
    return result.scalar_one_or_none()


def _require_patient(user: User) -> Patient:
    if user.patient is None:
        raise AppException(
            "NOT_A_PATIENT",
            "Active d'abord ton suivi personnel depuis l'accueil (« Activer mon suivi »).",
            status_code=400,
        )
    return user.patient


def create_patient_from_user(user: User) -> Patient:
    return Patient(
        user_id=user.id,
        nom_complet=user.nom_complet,
        date_naissance=user.date_naissance,
        sexe=user.sexe,
        localisation=user.localisation,
        notifications_accordees=False,
        batterie_exemptee=False,
    )


async def status(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    return {
        "onboarding_step": refreshed.onboarding_step,
        **capabilities(refreshed),
    }


async def save_infos(
    db: AsyncSession,
    *,
    user: User,
    nom_complet: str,
    date_naissance: date,
    sexe: str,
    localisation: str,
    phone: str | None,
) -> dict:
    user.nom_complet = nom_complet.strip()
    user.date_naissance = date_naissance
    user.sexe = sexe.strip()
    user.localisation = localisation.strip()
    if phone is not None:
        user.phone = phone.strip() or None
    user.onboarding_step = "besoin_suivi"
    await db.commit()
    return {"onboarding_step": user.onboarding_step}


async def set_besoin_suivi(db: AsyncSession, *, user: User, actif: bool) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None

    if actif:
        if refreshed.patient is None:
            if not refreshed.nom_complet:
                raise AppException(
                    "ONBOARDING_INCOMPLETE",
                    "Complète d'abord ton profil (nom, date de naissance…).",
                    status_code=400,
                )
            patient = create_patient_from_user(refreshed)
            db.add(patient)
            refreshed.patient = patient
        refreshed.onboarding_step = "patient_traitement"
    else:
        refreshed.onboarding_step = "besoin_suivi"

    await db.commit()
    return {
        "onboarding_step": refreshed.onboarding_step,
        "has_patient_profile": refreshed.patient is not None,
    }


async def list_maladies(db: AsyncSession) -> list[dict]:
    from app.services.catalog_seed_service import list_maladies_payload

    return await list_maladies_payload(db)


async def save_traitement(
    db: AsyncSession,
    *,
    user: User,
    en_traitement: bool,
    traitements: list[dict] | None,
) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    patient = _require_patient(refreshed)

    if en_traitement:
        items = traitements or []
        if not items:
            raise AppException(
                "ONBOARDING_INCOMPLETE",
                "Indique au moins une maladie et sa phase, ou choisis « pas en traitement ».",
                status_code=400,
            )
        for item in items:
            phase = item["phase"]
            if phase not in VALID_PHASES:
                raise AppException(
                    "TYPE_INVALIDE",
                    "Cette phase de traitement n'est pas reconnue. Choisis-en une dans la liste.",
                    status_code=400,
                )
            maladie = await db.get(Maladie, item["maladie_id"])
            if maladie is None or not maladie.actif:
                raise AppException(
                    "TYPE_INVALIDE",
                    "Cette maladie n'est pas dans notre liste. Actualise et réessaie.",
                    status_code=400,
                )
            traitement_row = PatientTraitement(
                patient_id=patient.user_id,
                maladie_id=item["maladie_id"],
                protocole_id=item.get("protocole_id"),
                phase=phase,
                en_traitement=True,
                date_debut=item.get("date_debut"),
                date_fin_prevue=item.get("date_fin_prevue"),
                maladie_libelle=item.get("maladie_libelle"),
                lieu_suivi=item.get("lieu_suivi"),
                statut="actif",
            )
            db.add(traitement_row)
            await db.flush()
            attributs = item.get("attributs") or {}
            for code, val in attributs.items():
                db.add(
                    PatientTraitementAttribut(
                        patient_traitement_id=traitement_row.id,
                        code=str(code),
                        valeur={"value": val},
                    )
                )
    # Onboarding initial : avancer ; post-home (déjà termine) : garder termine
    if refreshed.onboarding_step != "termine":
        refreshed.onboarding_step = "patient_permissions"
    await db.commit()
    return {"onboarding_step": refreshed.onboarding_step}


async def save_permissions(
    db: AsyncSession,
    *,
    user: User,
    notifications_accordees: bool,
    batterie_exemptee: bool,
) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    patient = _require_patient(refreshed)
    patient.notifications_accordees = notifications_accordees
    patient.batterie_exemptee = batterie_exemptee
    if refreshed.onboarding_step != "termine":
        refreshed.onboarding_step = "patient_permissions"
    await db.commit()
    return {"onboarding_step": refreshed.onboarding_step}


async def complete(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    step = refreshed.onboarding_step

    if step in (None, "infos"):
        raise AppException(
            "ONBOARDING_INCOMPLETE",
            "Complète d'abord ton profil (nom, date de naissance, etc.).",
            status_code=400,
        )

    if has_patient_profile(refreshed):
        if step not in ("patient_permissions", "termine"):
            raise AppException(
                "ONBOARDING_INCOMPLETE",
                "Il reste une étape : indique ton traitement, puis autorise les rappels.",
                status_code=400,
            )
    elif step not in ("besoin_suivi", "termine"):
        raise AppException(
            "ONBOARDING_INCOMPLETE",
            "Dis-nous si tu veux un suivi pour toi, puis continue.",
            status_code=400,
        )

    refreshed.onboarding_step = "termine"
    await db.commit()
    return {"onboarding_step": "termine"}


async def activate_patient(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    if refreshed.patient is not None:
        raise AppException(
            "PATIENT_ALREADY_ACTIVE",
            "Ton suivi personnel est déjà activé.",
            status_code=409,
        )
    if not refreshed.nom_complet:
        raise AppException(
            "ONBOARDING_INCOMPLETE",
            "Complète d'abord ton profil (nom, date de naissance…).",
            status_code=400,
        )
    patient = create_patient_from_user(refreshed)
    db.add(patient)
    refreshed.patient = patient
    # Guide le client vers traitement + permissions sans reset l'onboarding terminé
    await db.commit()
    return {"has_patient_profile": True, "onboarding_hint": "patient_traitement"}


async def create_sync_code(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    patient = _require_patient(refreshed)

    # Invalider les codes non utilisés précédents
    now = datetime.now(UTC)
    old = await db.execute(
        select(SyncCode).where(
            SyncCode.patient_id == patient.user_id,
            SyncCode.used_at.is_(None),
        )
    )
    for row in old.scalars().all():
        row.used_at = now

    code = f"{randbelow(1_000_000):06d}"
    expires = now + timedelta(minutes=settings.sync_code_expire_minutes)
    db.add(SyncCode(patient_id=patient.user_id, code=code, expires_at=expires))
    await db.commit()
    return {
        "code": code,
        "qr_payload": f"fidel://sync/{code}",
        "expires_at": expires,
    }


async def sync_aidant(db: AsyncSession, *, user: User, code: str) -> dict:
    from app.models import NotificationLog

    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None

    result = await db.execute(
        select(SyncCode)
        .where(SyncCode.code == code.strip(), SyncCode.used_at.is_(None))
        .options(selectinload(SyncCode.patient))
        .order_by(SyncCode.created_at.desc())
        .limit(1)
    )
    sync = result.scalar_one_or_none()
    if sync is None:
        raise AppException(
            "SYNC_CODE_INVALID",
            "Ce code ne fonctionne pas. Demande un nouveau code à la personne que tu accompagnes.",
            status_code=400,
        )

    expires = sync.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=UTC)
    if expires < datetime.now(UTC):
        raise AppException(
            "SYNC_CODE_EXPIRED",
            "Ce code a expiré. Demande-en un nouveau (valable quelques minutes).",
            status_code=400,
        )

    if sync.patient_id == refreshed.id:
        raise AppException(
            "SYNC_SELF_NOT_ALLOWED",
            "Tu ne peux pas t'associer à ton propre suivi. Utilise le code d'une autre personne.",
            status_code=400,
        )

    existing = await db.execute(
        select(PatientAidant).where(
            PatientAidant.patient_id == sync.patient_id,
            PatientAidant.aidant_id == refreshed.id,
            PatientAidant.statut == "actif",
            PatientAidant.revoked_at.is_(None),
        )
    )
    if existing.scalar_one_or_none() is None:
        db.add(
            PatientAidant(
                patient_id=sync.patient_id,
                aidant_id=refreshed.id,
                statut="actif",
                niveau_permission={"observance": True, "constantes": False},
            )
        )

    sync.used_at = datetime.now(UTC)

    aidant_prenom = (refreshed.nom_complet or "Quelqu'un").split()[0]
    patient_prenom = (sync.patient.nom_complet or "Patient").split()[0]
    contenu = f"{aidant_prenom} est maintenant connecté(e) à ton suivi sur {settings.app_name}."
    db.add(
        NotificationLog(
            destinataire_id=sync.patient_id,
            type="aidant_sync",
            contenu=contenu,
            declencheur={
                "aidant_id": str(refreshed.id),
                "patient_id": str(sync.patient_id),
                "event": "patient_aidant_linked",
            },
        )
    )

    await db.commit()

    return {
        "patient_id": sync.patient_id,
        "patient_prenom": patient_prenom,
        "is_aidant": True,
        "message": f"Tu accompagnes désormais {patient_prenom}.",
    }


async def get_patient_me(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    patient = _require_patient(refreshed)
    return _serialize_patient(patient)


async def update_patient_me(db: AsyncSession, *, user: User, data: dict) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    patient = _require_patient(refreshed)

    for field in (
        "nom_complet",
        "localisation",
        "photo_url",
        "notifications_accordees",
        "batterie_exemptee",
        "notifications_discretes",
    ):
        if field not in data:
            continue
        value = data[field]
        if field in ("nom_complet", "localisation") and isinstance(value, str):
            value = value.strip()
        setattr(patient, field, value)

    _apply_fiche_sante(patient, data)

    await db.commit()
    await db.refresh(patient)
    return _serialize_patient(patient)


GROUPE_SANGUIN_VALUES = frozenset({"A", "B", "AB", "O"})
RHESUS_VALUES = frozenset({"+", "-"})
ELECTROPHORESE_VALUES = frozenset(
    {"AA", "AS", "AC", "SS", "SC", "CC", "ne_sait_pas"}
)
TAILLE_CM_MIN = 120
TAILLE_CM_MAX = 220


def _apply_fiche_sante(patient: Patient, data: dict) -> None:
    wants_groupe = "groupe_sanguin" in data or "rhesus" in data
    wants_electro = "electrophorese" in data
    wants_taille = "taille_cm" in data

    if wants_groupe:
        if data.get("confirm_groupe_rhesus") is not True:
            raise AppException(
                "FICHE_SANTE_CONFIRMATION_REQUISE",
                "Confirme le groupe sanguin et le rhésus avant d’enregistrer.",
                status_code=400,
            )
        groupe = data.get("groupe_sanguin", patient.groupe_sanguin)
        rhesus = data.get("rhesus", patient.rhesus)
        if groupe is None or rhesus is None:
            raise AppException(
                "FICHE_SANTE_INCOMPLETE",
                "Groupe sanguin et rhésus sont tous les deux requis.",
                status_code=400,
            )
        if groupe not in GROUPE_SANGUIN_VALUES:
            raise AppException(
                "FICHE_SANTE_INVALIDE",
                "Groupe sanguin invalide.",
                status_code=400,
            )
        if rhesus not in RHESUS_VALUES:
            raise AppException(
                "FICHE_SANTE_INVALIDE",
                "Rhésus invalide.",
                status_code=400,
            )
        now = datetime.now(UTC)
        patient.groupe_sanguin = groupe
        patient.rhesus = rhesus
        patient.groupe_sanguin_confirmed_at = now
        patient.rhesus_confirmed_at = now

    if wants_electro:
        if data.get("confirm_electrophorese") is not True:
            raise AppException(
                "FICHE_SANTE_CONFIRMATION_REQUISE",
                "Confirme l’électrophorèse avant d’enregistrer.",
                status_code=400,
            )
        electro = data["electrophorese"]
        if electro not in ELECTROPHORESE_VALUES:
            raise AppException(
                "FICHE_SANTE_INVALIDE",
                "Électrophorèse invalide.",
                status_code=400,
            )
        patient.electrophorese = electro
        patient.electrophorese_confirmed_at = datetime.now(UTC)

    if wants_taille:
        if data.get("confirm_taille") is not True:
            raise AppException(
                "FICHE_SANTE_CONFIRMATION_REQUISE",
                "Confirme la taille avant d’enregistrer.",
                status_code=400,
            )
        taille = data["taille_cm"]
        if not isinstance(taille, int) or not (TAILLE_CM_MIN <= taille <= TAILLE_CM_MAX):
            raise AppException(
                "FICHE_SANTE_INVALIDE",
                f"Taille invalide (entre {TAILLE_CM_MIN} et {TAILLE_CM_MAX} cm).",
                status_code=400,
            )
        patient.taille_cm = taille
        patient.taille_cm_confirmed_at = datetime.now(UTC)


def _serialize_patient(patient: Patient) -> dict:
    photo = patient.photo_url
    if photo and photo.startswith("photos/"):
        from app.services.patient_photo_service import public_photo_url

        photo = public_photo_url()
    return {
        "user_id": patient.user_id,
        "nom_complet": patient.nom_complet,
        "date_naissance": patient.date_naissance,
        "sexe": patient.sexe,
        "localisation": patient.localisation,
        "photo_url": photo,
        "notifications_accordees": patient.notifications_accordees,
        "batterie_exemptee": patient.batterie_exemptee,
        "notifications_discretes": patient.notifications_discretes,
        "groupe_sanguin": patient.groupe_sanguin,
        "rhesus": patient.rhesus,
        "electrophorese": patient.electrophorese,
        "taille_cm": patient.taille_cm,
        "groupe_sanguin_confirmed_at": patient.groupe_sanguin_confirmed_at,
        "rhesus_confirmed_at": patient.rhesus_confirmed_at,
        "electrophorese_confirmed_at": patient.electrophorese_confirmed_at,
        "taille_cm_confirmed_at": patient.taille_cm_confirmed_at,
    }


async def ensure_default_maladies(db: AsyncSession) -> None:
    from app.services.catalog_seed_service import ensure_catalogue

    await ensure_catalogue(db)


DEFAULT_MALADIES = [
    ("Tuberculose", "Traitement antituberculeux"),
    ("Diabète", "Suivi glycémique et traitement"),
    ("Hypertension", "Suivi tensionnel"),
    ("VIH", "Traitement antirétroviral"),
    ("Autre", "Autre pathologie chronique"),
]

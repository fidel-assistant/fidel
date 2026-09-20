"""FCM + journal vers aidants (observance) — opt-in PreferenceConsentement."""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Medicament,
    MedicamentHoraire,
    NotificationLog,
    PatientAidant,
    PatientTraitement,
    PreferenceConsentement,
    Prise,
    User,
)
from app.services import device_push_service, fcm_service, notification_service
from app.services.aidant_service import _normalize_notification_prefs, _prenom

logger = logging.getLogger(__name__)

TYPE_PRISE_CONFIRMEE = "prise_confirmee_aidant"
TYPE_PRISE_NON_CONFIRMEE = "prise_non_confirmee_aidant"
DEFAULT_DELAI_HEURES = 2
CHANNEL_AIDANT = "fidel_sos_aidant"  # canal natif déjà créé (SOS)

_MUTE_KEY_BY_KIND = {
    "prise_confirmee": "mute_prise_confirmee",
    "prise_non_confirmee": "mute_prise_non_confirmee",
}


def _aware(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt


async def _opt_in_pref(
    db: AsyncSession, *, user_id: UUID, type_alerte: str
) -> PreferenceConsentement | None:
    """Opt-in = toujours_demander False + regle_auto non null."""
    pref = await notification_service._get_preference(
        db, user_id=user_id, type_alerte=type_alerte
    )
    if pref is None:
        return None
    if pref.toujours_demander or pref.regle_auto is None:
        return None
    return pref


async def _already_notified(
    db: AsyncSession, *, type_alerte: str, prise_id: UUID
) -> bool:
    prise_key = str(prise_id)
    result = await db.execute(
        select(NotificationLog).where(NotificationLog.type == type_alerte)
    )
    for log in result.scalars().all():
        if (log.declencheur or {}).get("prise_id") == prise_key:
            return True
    return False


async def _observance_aidant_ids(
    db: AsyncSession, *, patient_id: UUID, mute_key: str | None = None
) -> list[UUID]:
    rows = (
        await db.execute(
            select(PatientAidant).where(
                PatientAidant.patient_id == patient_id,
                PatientAidant.statut == "actif",
                PatientAidant.revoked_at.is_(None),
            )
        )
    ).scalars().all()
    out: list[UUID] = []
    for rel in rows:
        perms = rel.niveau_permission or {}
        if perms.get("observance", True) is not True:
            continue
        if mute_key:
            prefs = _normalize_notification_prefs(rel.notification_prefs)
            if prefs.get(mute_key) is True:
                continue
        out.append(rel.aidant_id)
    return out


async def _prise_context(
    db: AsyncSession, *, prise: Prise, patient_id: UUID
) -> dict[str, str]:
    med_nom = "médicament"
    result = await db.execute(
        select(Medicament)
        .join(MedicamentHoraire, MedicamentHoraire.medicament_id == Medicament.id)
        .where(MedicamentHoraire.id == prise.medicament_horaire_id)
    )
    med = result.scalar_one_or_none()
    if med is not None and med.nom:
        med_nom = med.nom

    patient_user = await db.get(User, patient_id)
    prenom = _prenom(patient_user.nom_complet if patient_user else None)
    heure = _aware(prise.heure_prevue).strftime("%H:%M")
    return {
        "prise_id": str(prise.id),
        "patient_id": str(patient_id),
        "patient_prenom": prenom,
        "medicament": med_nom,
        "heure": heure,
    }


async def _push_to_aidants(
    db: AsyncSession,
    *,
    patient_id: UUID,
    type_alerte: str,
    kind: str,
    title: str,
    body_aidant: str,
    contexte: dict[str, str],
) -> bool:
    """Journalise + FCM. Retourne True si une notif a été créée (dédup sinon False)."""
    if await _already_notified(db, type_alerte=type_alerte, prise_id=UUID(contexte["prise_id"])):
        return False

    aidant_ids = await _observance_aidant_ids(
        db,
        patient_id=patient_id,
        mute_key=_MUTE_KEY_BY_KIND.get(kind),
    )
    log = await notification_service.trigger(
        db,
        type_alerte=type_alerte,
        user_id=patient_id,
        contexte={**contexte, "aidants": [str(a) for a in aidant_ids]},
        force_proposition=False,
    )

    for aidant_id in aidant_ids:
        db.add(
            NotificationLog(
                destinataire_id=aidant_id,
                type=f"{type_alerte}_tiers",
                contenu=body_aidant,
                declencheur={
                    "prise_id": contexte["prise_id"],
                    "patient_id": contexte["patient_id"],
                    "type_source": type_alerte,
                    "source_notification_id": str(log.id),
                },
                proposition=False,
            )
        )

    log.action_declenchee = bool(aidant_ids)
    await db.commit()

    if aidant_ids:
        tokens = await device_push_service.tokens_for_users(db, user_ids=aidant_ids)
        sent = await fcm_service.send_data_message(
            tokens=tokens,
            data={
                "kind": kind,
                "prise_id": contexte["prise_id"],
                "patient_id": contexte["patient_id"],
                "patient_prenom": contexte["patient_prenom"],
                "medicament": contexte["medicament"],
                "heure": contexte["heure"],
            },
            title=title,
            body=body_aidant,
            channel_id=CHANNEL_AIDANT,
        )
        logger.info(
            "aidant_push type=%s prise=%s aidants=%s sent=%s",
            type_alerte,
            contexte["prise_id"],
            len(aidant_ids),
            sent,
        )
    return True


async def notify_prise_confirmee(
    db: AsyncSession, *, patient_id: UUID, prise: Prise
) -> bool:
    pref = await _opt_in_pref(
        db, user_id=patient_id, type_alerte=TYPE_PRISE_CONFIRMEE
    )
    if pref is None:
        return False

    ctx = await _prise_context(db, prise=prise, patient_id=patient_id)
    body = (
        f"{ctx['patient_prenom']} a confirmé sa prise de {ctx['medicament']} "
        f"({ctx['heure']})."
    )
    return await _push_to_aidants(
        db,
        patient_id=patient_id,
        type_alerte=TYPE_PRISE_CONFIRMEE,
        kind="prise_confirmee",
        title="Prise confirmée",
        body_aidant=body,
        contexte=ctx,
    )


async def notify_prise_non_confirmee(
    db: AsyncSession, *, patient_id: UUID, prise: Prise
) -> bool:
    pref = await _opt_in_pref(
        db, user_id=patient_id, type_alerte=TYPE_PRISE_NON_CONFIRMEE
    )
    if pref is None:
        return False

    ctx = await _prise_context(db, prise=prise, patient_id=patient_id)
    body = (
        f"Pas de confirmation pour {ctx['medicament']} de {ctx['patient_prenom']} "
        f"({ctx['heure']}). Tu peux le contacter pour te rassurer."
    )
    return await _push_to_aidants(
        db,
        patient_id=patient_id,
        type_alerte=TYPE_PRISE_NON_CONFIRMEE,
        kind="prise_non_confirmee",
        title="Prise non confirmée",
        body_aidant=body,
        contexte=ctx,
    )


def _delai_heures(regle_auto: dict | None) -> int:
    if not regle_auto:
        return DEFAULT_DELAI_HEURES
    raw = regle_auto.get("delai_heures", DEFAULT_DELAI_HEURES)
    try:
        val = int(raw)
    except (TypeError, ValueError):
        return DEFAULT_DELAI_HEURES
    return max(1, min(val, 168))


async def scan_prises_non_confirmees(db: AsyncSession) -> dict:
    """Job cron : alerte aidants si prise encore en_attente après délai opt-in."""
    prefs = (
        await db.execute(
            select(PreferenceConsentement).where(
                PreferenceConsentement.type_alerte == TYPE_PRISE_NON_CONFIRMEE,
                PreferenceConsentement.toujours_demander.is_(False),
                PreferenceConsentement.regle_auto.is_not(None),
            )
        )
    ).scalars().all()

    scanned = 0
    notified = 0
    skipped = 0
    now = datetime.now(UTC)

    for pref in prefs:
        delay = timedelta(hours=_delai_heures(pref.regle_auto))
        cutoff = now - delay

        prises = (
            await db.execute(
                select(Prise)
                .join(
                    MedicamentHoraire,
                    Prise.medicament_horaire_id == MedicamentHoraire.id,
                )
                .join(Medicament, MedicamentHoraire.medicament_id == Medicament.id)
                .join(
                    PatientTraitement,
                    Medicament.patient_traitement_id == PatientTraitement.id,
                )
                .where(
                    PatientTraitement.patient_id == pref.user_id,
                    Prise.statut == "en_attente",
                    Prise.heure_prevue <= cutoff,
                )
            )
        ).scalars().all()

        for prise in prises:
            scanned += 1
            if await _already_notified(
                db, type_alerte=TYPE_PRISE_NON_CONFIRMEE, prise_id=prise.id
            ):
                skipped += 1
                continue
            did = await notify_prise_non_confirmee(
                db, patient_id=pref.user_id, prise=prise
            )
            if did:
                notified += 1
            else:
                skipped += 1

    return {"scanned": scanned, "notified": notified, "skipped": skipped}

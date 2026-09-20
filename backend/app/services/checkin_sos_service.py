"""Check-in quotidien et alerte SOS (fenêtre d'annulation 30s)."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppException
from app.models import CheckIn, ContactUrgence, PatientAidant, SosAlerte, User
from app.services import device_push_service, fcm_service, notification_service
from app.services.aidant_service import _normalize_notification_prefs, _prenom
from app.services.onboarding_service import _require_patient, get_user_with_capabilities, is_aidant

VALID_CHECKIN = {"tres_mal", "pas_top", "ca_va", "super"}


def _patient_tz(user: User) -> ZoneInfo:
    try:
        return ZoneInfo(user.fuseau_horaire or "UTC")
    except Exception:
        return ZoneInfo("UTC")


def _aware(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt


async def create_check_in(
    db: AsyncSession,
    *,
    user: User,
    statut: str,
    client_mutation_id: UUID | None = None,
) -> dict:
    from app.services import patient_suivi_service as suivi

    if client_mutation_id is not None:
        existing = await suivi._get_client_mutation(db, mutation_id=client_mutation_id)
        if existing is not None:
            return _replay_check_in(existing.result_snapshot)

    if statut not in VALID_CHECKIN:
        raise AppException(
            "TYPE_INVALIDE",
            "Statut de check-in invalide. Choisis un niveau parmi les quatre proposés.",
            status_code=400,
        )
    patient = _require_patient(user)
    today = datetime.now(_patient_tz(user)).date()

    existing = await db.execute(
        select(CheckIn).where(CheckIn.patient_id == patient.user_id, CheckIn.date == today)
    )
    if existing.scalar_one_or_none() is not None:
        raise AppException(
            "CHECK_IN_DEJA_FAIT_AUJOURDHUI",
            "Tu as déjà fait ton check-in aujourd'hui. Reviens demain.",
            status_code=409,
        )

    row = CheckIn(patient_id=patient.user_id, date=today, statut=statut)
    db.add(row)
    await db.flush()
    result = _serialize_check_in(row)
    if client_mutation_id is not None:
        await suivi._record_client_mutation(
            db,
            mutation_id=client_mutation_id,
            user_id=user.id,
            entity="check_in",
            entity_id=row.id,
            op="create_check_in",
            result=_snapshot_check_in(result),
        )
    await db.commit()
    await db.refresh(row)
    return _serialize_check_in(row)


def _snapshot_check_in(result: dict) -> dict:
    out: dict = {}
    for k, v in result.items():
        if isinstance(v, UUID):
            out[k] = str(v)
        elif isinstance(v, datetime):
            out[k] = v.isoformat()
        elif isinstance(v, date) and not isinstance(v, datetime):
            out[k] = v.isoformat()
        else:
            out[k] = v
    return out


def _replay_check_in(snapshot: dict | None) -> dict:
    if not snapshot:
        return {}
    out: dict = {}
    for k, v in snapshot.items():
        if k == "id" and isinstance(v, str):
            try:
                out[k] = UUID(v)
            except ValueError:
                out[k] = v
        elif k == "date" and isinstance(v, str):
            try:
                out[k] = date.fromisoformat(v)
            except ValueError:
                out[k] = v
        elif k == "created_at" and isinstance(v, str):
            try:
                out[k] = datetime.fromisoformat(v)
            except ValueError:
                out[k] = v
        else:
            out[k] = v
    return out


async def list_check_ins(
    db: AsyncSession, *, user: User, depuis: date | None = None
) -> list[dict]:
    patient = _require_patient(user)
    stmt = select(CheckIn).where(CheckIn.patient_id == patient.user_id)
    if depuis is not None:
        stmt = stmt.where(CheckIn.date >= depuis)
    stmt = stmt.order_by(CheckIn.date.desc())
    result = await db.execute(stmt)
    return [_serialize_check_in(r) for r in result.scalars().all()]


def _serialize_check_in(row: CheckIn) -> dict:
    return {
        "id": row.id,
        "date": row.date,
        "statut": row.statut,
        "created_at": row.created_at,
    }


async def trigger_sos(db: AsyncSession, *, user: User) -> dict:
    patient = _require_patient(user)
    contacts = (
        await db.execute(
            select(ContactUrgence).where(ContactUrgence.patient_id == patient.user_id)
        )
    ).scalars().all()
    if not contacts:
        raise AppException(
            "AUCUN_CONTACT_URGENCE",
            "Ajoute au moins un contact d'urgence avant d'utiliser le SOS.",
            status_code=400,
        )

    now = datetime.now(UTC)
    window = timedelta(seconds=settings.sos_cancel_window_seconds)
    sos = SosAlerte(
        patient_id=patient.user_id,
        statut="en_attente",
        annulable_jusqu_a=now + window,
    )
    db.add(sos)
    await db.commit()
    await db.refresh(sos)
    return {"sos_id": sos.id, "annulable_jusqu_a": sos.annulable_jusqu_a}


async def cancel_sos(db: AsyncSession, *, user: User, sos_id: UUID) -> dict:
    patient = _require_patient(user)
    sos = await db.get(SosAlerte, sos_id)
    if sos is None or sos.patient_id != patient.user_id:
        raise AppException(
            "SOS_NOT_FOUND",
            "Cette alerte SOS est introuvable.",
            status_code=404,
        )

    if sos.statut == "annule":
        return {"message": "Alerte SOS déjà annulée."}

    if sos.statut == "envoye" or sos.acked_at is not None:
        raise AppException(
            "SOS_TROP_TARD",
            "La fenêtre d'annulation est passée : l'alerte a déjà été envoyée.",
            status_code=409,
        )

    now = datetime.now(UTC)
    if now >= _aware(sos.annulable_jusqu_a):
        await _finalize_sos(db, sos=sos)
        raise AppException(
            "SOS_TROP_TARD",
            "La fenêtre d'annulation est passée : l'alerte a déjà été envoyée.",
            status_code=409,
        )

    sos.statut = "annule"
    sos.annule_at = now
    await db.commit()
    return {"message": "Alerte SOS annulée. Aucun contact n'a été prévenu."}


async def confirm_sos(db: AsyncSession, *, user: User, sos_id: UUID) -> dict:
    """Fin de countdown patient — finalise et pousse les aidants."""
    patient = _require_patient(user)
    sos = await db.get(SosAlerte, sos_id)
    if sos is None or sos.patient_id != patient.user_id:
        raise AppException(
            "SOS_NOT_FOUND",
            "Cette alerte SOS est introuvable.",
            status_code=404,
        )
    if sos.statut == "annule":
        raise AppException(
            "SOS_ANNULE",
            "Cette alerte SOS a déjà été annulée.",
            status_code=409,
        )

    return await _finalize_sos(db, sos=sos, force=True)


async def get_sos_status(db: AsyncSession, *, user: User, sos_id: UUID) -> dict:
    patient = _require_patient(user)
    sos = await db.get(SosAlerte, sos_id)
    if sos is None or sos.patient_id != patient.user_id:
        raise AppException(
            "SOS_NOT_FOUND",
            "Cette alerte SOS est introuvable.",
            status_code=404,
        )
    return {
        "sos_id": sos.id,
        "statut": sos.statut,
        "acked": sos.acked_at is not None,
        "envoye_at": sos.envoye_at,
        "acked_at": sos.acked_at,
    }


async def ack_sos_aidant(db: AsyncSession, *, user: User, sos_id: UUID) -> dict:
    refreshed = await get_user_with_capabilities(db, user_id=user.id)
    if refreshed is None or not is_aidant(refreshed):
        raise AppException(
            "NOT_AN_AIDANT",
            "Seul un aidant lié peut acquitter un SOS.",
            status_code=403,
        )
    sos = await db.get(SosAlerte, sos_id)
    if sos is None:
        raise AppException(
            "SOS_NOT_FOUND",
            "Cette alerte SOS est introuvable.",
            status_code=404,
        )
    link = (
        await db.execute(
            select(PatientAidant).where(
                PatientAidant.patient_id == sos.patient_id,
                PatientAidant.aidant_id == user.id,
                PatientAidant.statut == "actif",
                PatientAidant.revoked_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if link is None:
        raise AppException(
            "PERMISSION_REFUSEE",
            "Tu n'accompagnes pas ce patient.",
            status_code=403,
        )
    if sos.statut != "envoye":
        raise AppException(
            "SOS_NON_ACTIF",
            "Cette alerte SOS n'est plus active.",
            status_code=409,
        )
    if sos.acked_at is None:
        sos.acked_at = datetime.now(UTC)
        sos.acked_by_aidant_id = user.id
        await db.commit()
    return {"message": "SOS acquitté. Le patient est informé."}


async def list_active_sos_for_aidant(db: AsyncSession, *, user: User) -> list[dict]:
    refreshed = await get_user_with_capabilities(db, user_id=user.id)
    if refreshed is None or not is_aidant(refreshed):
        return []
    links = (
        await db.execute(
            select(PatientAidant.patient_id).where(
                PatientAidant.aidant_id == user.id,
                PatientAidant.statut == "actif",
                PatientAidant.revoked_at.is_(None),
            )
        )
    ).scalars().all()
    if not links:
        return []
    rows = (
        await db.execute(
            select(SosAlerte)
            .where(
                SosAlerte.patient_id.in_(list(links)),
                SosAlerte.statut == "envoye",
                SosAlerte.acked_at.is_(None),
            )
            .order_by(SosAlerte.envoye_at.desc())
        )
    ).scalars().all()
    out: list[dict] = []
    for sos in rows:
        user_row = await db.get(User, sos.patient_id)
        out.append(
            {
                "sos_id": sos.id,
                "patient_id": sos.patient_id,
                "patient_prenom": _prenom(user_row.nom_complet if user_row else None),
                "envoye_at": sos.envoye_at,
            }
        )
    return out


async def _finalize_sos(
    db: AsyncSession,
    *,
    sos: SosAlerte,
    force: bool = False,
) -> dict:
    """Passe en envoye, journalise, pousse FCM aux aidants."""
    if sos.statut == "envoye":
        aidant_count = await _aidant_count(db, patient_id=sos.patient_id)
        tokens_hint = await _aidant_token_count(db, patient_id=sos.patient_id)
        return {
            "sos_id": sos.id,
            "statut": sos.statut,
            "aidants_notifies": tokens_hint,
            "fallback_call_recommended": aidant_count == 0 and sos.acked_at is None,
            "acked": sos.acked_at is not None,
        }
    if sos.statut != "en_attente":
        return {
            "sos_id": sos.id,
            "statut": sos.statut,
            "aidants_notifies": 0,
            "fallback_call_recommended": True,
            "acked": False,
        }

    now = datetime.now(UTC)
    if not force and now < _aware(sos.annulable_jusqu_a):
        return {
            "sos_id": sos.id,
            "statut": sos.statut,
            "aidants_notifies": 0,
            "fallback_call_recommended": False,
            "acked": False,
        }

    contacts = (
        await db.execute(
            select(ContactUrgence).where(ContactUrgence.patient_id == sos.patient_id)
        )
    ).scalars().all()
    contacts_payload = [
        {"id": str(c.id), "nom": c.nom, "telephone": c.telephone, "relation": c.relation}
        for c in contacts
    ]

    aidant_rows = (
        await db.execute(
            select(PatientAidant).where(
                PatientAidant.patient_id == sos.patient_id,
                PatientAidant.statut == "actif",
                PatientAidant.revoked_at.is_(None),
            )
        )
    ).scalars().all()
    aidant_ids_list = [
        rel.aidant_id
        for rel in aidant_rows
        if _normalize_notification_prefs(rel.notification_prefs).get("mute_sos")
        is not True
    ]

    patient_user = await db.get(User, sos.patient_id)
    prenom = _prenom(patient_user.nom_complet if patient_user else None)

    await notification_service.trigger(
        db,
        type_alerte="sos_declenche",
        user_id=sos.patient_id,
        contexte={
            "sos_id": str(sos.id),
            "patient_id": str(sos.patient_id),
            "contacts": contacts_payload,
            "aidants": [str(a) for a in aidant_ids_list],
            "event": "sos_envoye",
        },
    )

    sos.statut = "envoye"
    sos.envoye_at = now
    await db.commit()
    await db.refresh(sos)

    tokens = await device_push_service.tokens_for_users(db, user_ids=aidant_ids_list)
    sent = await fcm_service.send_data_message(
        tokens=tokens,
        data={
            "kind": "sos",
            "sos_id": str(sos.id),
            "patient_id": str(sos.patient_id),
            "patient_prenom": prenom,
        },
        title="SOS Fidel",
        body=f"{prenom} a déclenché un SOS — ouvre Fidel.",
    )

    # Appel immédiat seulement s'il n'y a aucun aidant lié (pas si FCM a échoué).
    fallback = len(aidant_ids_list) == 0
    return {
        "sos_id": sos.id,
        "statut": sos.statut,
        "aidants_notifies": sent if tokens else 0,
        "fallback_call_recommended": fallback,
        "acked": False,
    }


async def _aidant_count(db: AsyncSession, *, patient_id: UUID) -> int:
    rows = (
        await db.execute(
            select(PatientAidant.aidant_id).where(
                PatientAidant.patient_id == patient_id,
                PatientAidant.statut == "actif",
                PatientAidant.revoked_at.is_(None),
            )
        )
    ).scalars().all()
    return len(list(rows))


async def _aidant_token_count(db: AsyncSession, *, patient_id: UUID) -> int:
    aidant_ids = (
        await db.execute(
            select(PatientAidant.aidant_id).where(
                PatientAidant.patient_id == patient_id,
                PatientAidant.statut == "actif",
                PatientAidant.revoked_at.is_(None),
            )
        )
    ).scalars().all()
    tokens = await device_push_service.tokens_for_users(db, user_ids=list(aidant_ids))
    return len(tokens)


async def _finalize_sos_if_due(db: AsyncSession, *, sos: SosAlerte) -> None:
    await _finalize_sos(db, sos=sos, force=False)

"""Sync V2 — push / pull (Phases 4–5)."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from uuid import UUID

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import AppException
from app.models import (
    CheckIn,
    Constante,
    Medicament,
    MedicamentHoraire,
    PatientTraitement,
    Prise,
    User,
)
from app.services import checkin_sos_service as checkin_svc
from app.services import constante_service as constante_svc
from app.services import patient_suivi_service as suivi


def _cursor(ts: datetime, entity_type: str, entity_id: UUID | str) -> str:
    return f"{ts.astimezone(UTC).isoformat()}|{entity_type}|{entity_id}"


def _parse_cursor(
    since: str | None,
) -> tuple[datetime | None, str | None, UUID | None]:
    """Cursor Phase 5: `{ts}|{type}|{id}`. Phase 4 legacy: `{ts}|{id}` → type=prise."""
    if not since:
        return None, None, None
    parts = since.split("|")
    try:
        if len(parts) == 3:
            return datetime.fromisoformat(parts[0]), parts[1], UUID(parts[2])
        if len(parts) == 2:
            return datetime.fromisoformat(parts[0]), "prise", UUID(parts[1])
    except (ValueError, TypeError):
        return None, None, None
    return None, None, None


def _after_cursor(
    ts: datetime,
    entity_type: str,
    entity_id: UUID,
    since_ts: datetime | None,
    since_type: str | None,
    since_id: UUID | None,
) -> bool:
    if since_ts is None or since_type is None or since_id is None:
        return True
    key = (ts.astimezone(UTC), entity_type, str(entity_id))
    since_key = (since_ts.astimezone(UTC), since_type, str(since_id))
    return key > since_key


async def push_mutations(
    db: AsyncSession, *, user: User, mutations: list[dict]
) -> dict:
    results: list[dict] = []
    for raw in mutations:
        mutation_id = raw["mutation_id"]
        entity = raw.get("entity") or ""
        op = raw.get("op") or ""
        entity_id = raw.get("entity_id")
        payload = raw.get("payload") or {}

        existing = await suivi._get_client_mutation(db, mutation_id=mutation_id)
        if existing is not None:
            results.append(
                {
                    "mutation_id": mutation_id,
                    "status": "duplicate",
                    "reason": None,
                }
            )
            continue

        try:
            if entity == "prise" and entity_id is not None:
                await _push_prise(
                    db,
                    user=user,
                    mutation_id=mutation_id,
                    entity_id=entity_id,
                    op=op,
                    payload=payload,
                    client_ts=raw.get("client_ts"),
                    results=results,
                )
            elif entity == "constante" and op == "create_constante":
                await constante_svc.create_constante(
                    db,
                    user=user,
                    type_=str(payload.get("type") or ""),
                    valeur=payload.get("valeur"),
                    unite=str(payload.get("unite") or ""),
                    mesure_at=_as_dt(payload.get("mesure_at")),
                    source=str(payload.get("source") or "manuel"),
                    client_mutation_id=mutation_id,
                )
                results.append(
                    {
                        "mutation_id": mutation_id,
                        "status": "applied",
                        "reason": None,
                    }
                )
            elif entity == "check_in" and op == "create_check_in":
                await checkin_svc.create_check_in(
                    db,
                    user=user,
                    statut=str(payload.get("statut") or ""),
                    client_mutation_id=mutation_id,
                )
                results.append(
                    {
                        "mutation_id": mutation_id,
                        "status": "applied",
                        "reason": None,
                    }
                )
            else:
                results.append(
                    {
                        "mutation_id": mutation_id,
                        "status": "rejected",
                        "reason": "MUTATION_REJECTED",
                    }
                )
        except AppException as exc:
            reason = exc.code
            if exc.code == "PRISE_DEJA_CONFIRMEE":
                reason = "SYNC_CONFLICT"
            results.append(
                {
                    "mutation_id": mutation_id,
                    "status": "rejected",
                    "reason": reason,
                }
            )
        except Exception:
            results.append(
                {
                    "mutation_id": mutation_id,
                    "status": "rejected",
                    "reason": "MUTATION_REJECTED",
                }
            )

    return {"results": results}


def _as_dt(raw: object) -> datetime:
    if isinstance(raw, datetime):
        return raw
    if raw is None:
        return datetime.now(UTC)
    return datetime.fromisoformat(str(raw))


def _as_utc(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


def _parse_client_ts(raw: object) -> datetime | None:
    if raw is None:
        return None
    try:
        return _as_utc(_as_dt(raw))
    except (ValueError, TypeError):
        return None


_STATUT_RANK = {
    "confirmee": 3,
    "manquee": 2,
    "en_attente": 1,
}


def _client_wins(
    *, client_ts: datetime | None, updated_at: datetime | None
) -> bool | None:
    """True = intention locale gagne ; False = serveur ; None = pas de gate ts."""
    if client_ts is None:
        return None
    server = _as_utc(updated_at)
    if server is None:
        return True
    if client_ts > server:
        return True
    if client_ts < server:
        return False
    return None  # égalité → hiérarchie


def _intention_rank(op: str) -> int:
    if op == "confirm":
        return _STATUT_RANK["confirmee"]
    # report ne downgrade pas le statut ; rang « neutre » pour la hiérarchie
    return _STATUT_RANK["en_attente"]


def _should_apply_prise_op(
    *, op: str, statut: str, updated_at: datetime | None, client_ts: datetime | None
) -> bool:
    """Matrice offline-sync §F pour confirm / report."""
    # Serveur manquee + confirm → toujours appliquer (confirmation tardive).
    if op == "confirm" and statut == "manquee":
        return True
    # Anti-downgrade : report sur confirmee.
    if op == "report" and statut == "confirmee":
        return False
    # Confirm sur déjà confirmee → idempotent (confirmer_prise).
    if op == "confirm" and statut == "confirmee":
        return True

    wins = _client_wins(client_ts=client_ts, updated_at=updated_at)
    if wins is True:
        return True
    if wins is False:
        return False
    # Pas de client_ts → comportement historique.
    if client_ts is None:
        return True
    # Égalité horloge → hiérarchie d'intention.
    server_rank = _STATUT_RANK.get(statut, 0)
    intent = _intention_rank(op)
    if intent > server_rank:
        return True
    if intent < server_rank:
        return False
    return True


def _reject_conflict(results: list[dict], mutation_id: UUID) -> None:
    results.append(
        {
            "mutation_id": mutation_id,
            "status": "rejected",
            "reason": "SYNC_CONFLICT",
        }
    )


async def _push_prise(
    db: AsyncSession,
    *,
    user: User,
    mutation_id: UUID,
    entity_id: UUID,
    op: str,
    payload: dict,
    client_ts: object,
    results: list[dict],
) -> None:
    if op not in ("confirm", "report"):
        results.append(
            {
                "mutation_id": mutation_id,
                "status": "rejected",
                "reason": "MUTATION_REJECTED",
            }
        )
        return

    patient = suivi._require_patient(user)
    prise = await suivi._prise_for_patient(
        db, patient_id=patient.user_id, prise_id=entity_id
    )
    parsed_ts = _parse_client_ts(client_ts)
    if not _should_apply_prise_op(
        op=op,
        statut=prise.statut,
        updated_at=prise.updated_at,
        client_ts=parsed_ts,
    ):
        _reject_conflict(results, mutation_id)
        return

    if op == "confirm":
        await suivi.confirmer_prise(
            db,
            user=user,
            prise_id=entity_id,
            canal=str(payload.get("canal") or "app"),
            client_mutation_id=mutation_id,
        )
        results.append(
            {
                "mutation_id": mutation_id,
                "status": "applied",
                "reason": None,
            }
        )
        return

    # report
    raw_heure = payload.get("nouvelle_heure")
    if not raw_heure:
        results.append(
            {
                "mutation_id": mutation_id,
                "status": "rejected",
                "reason": "MUTATION_REJECTED",
            }
        )
        return
    when = _as_dt(raw_heure)
    await suivi.reporter_prise(
        db,
        user=user,
        prise_id=entity_id,
        nouvelle_heure=when,
        client_mutation_id=mutation_id,
    )
    results.append(
        {
            "mutation_id": mutation_id,
            "status": "applied",
            "reason": None,
        }
    )


async def pull_delta(
    db: AsyncSession, *, user: User, since: str | None = None
) -> dict:
    patient = suivi._require_patient(user)
    since_ts, since_type, since_id = _parse_cursor(since)
    now = datetime.now(UTC)
    horizon_start = now - timedelta(days=30)
    horizon_end = now + timedelta(days=7)
    today = now.date()
    checkin_since = today - timedelta(days=30)

    scored: list[tuple[str, dict]] = []

    # --- Prises (30j passés → 7j futurs) ---
    prise_q = (
        select(Prise, Medicament, PatientTraitement)
        .join(MedicamentHoraire, Prise.medicament_horaire_id == MedicamentHoraire.id)
        .join(Medicament, MedicamentHoraire.medicament_id == Medicament.id)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(
            PatientTraitement.patient_id == patient.user_id,
            Prise.heure_prevue >= horizon_start,
            Prise.heure_prevue <= horizon_end,
        )
        .options(selectinload(PatientTraitement.maladie))
    )
    result = await db.execute(prise_q)
    for prise, med, traitement in result.all():
        ts = prise.updated_at.astimezone(UTC)
        if not _after_cursor(ts, "prise", prise.id, since_ts, since_type, since_id):
            continue
        cur = _cursor(ts, "prise", prise.id)
        maladie = traitement.maladie
        scored.append(
            (
                cur,
                {
                    "type": "prise",
                    "id": str(prise.id),
                    "server_version": int(prise.server_version or 1),
                    "updated_at": ts.isoformat(),
                    "medicament_id": str(med.id),
                    "medicament_nom": med.nom,
                    "dosage": med.dosage,
                    "heure_prevue": prise.heure_prevue.astimezone(UTC).isoformat(),
                    "statut": prise.statut,
                    "confirmee_at": (
                        prise.confirmee_at.astimezone(UTC).isoformat()
                        if prise.confirmee_at
                        else None
                    ),
                    "canal": prise.canal,
                    "traitement_id": str(traitement.id),
                    "maladie_id": str(traitement.maladie_id)
                    if traitement.maladie_id
                    else None,
                    "maladie_nom": maladie.nom
                    if maladie
                    else (traitement.maladie_libelle or ""),
                },
            )
        )

    # --- Constantes (30 j) ---
    const_q = select(Constante).where(
        Constante.patient_id == patient.user_id,
        or_(
            Constante.created_at >= horizon_start,
            Constante.mesure_at >= horizon_start,
        ),
    )
    const_result = await db.execute(const_q)
    for row in const_result.scalars().all():
        ts = (row.created_at or row.mesure_at).astimezone(UTC)
        if not _after_cursor(ts, "constante", row.id, since_ts, since_type, since_id):
            continue
        cur = _cursor(ts, "constante", row.id)
        scored.append(
            (
                cur,
                {
                    "type": "constante",
                    "id": str(row.id),
                    "server_version": 1,
                    "updated_at": ts.isoformat(),
                    "created_at": ts.isoformat(),
                    "constante_type": row.type,
                    "type_constante": row.type,
                    "valeur": constante_svc._public_valeur(row.type, row.valeur),
                    "unite": row.unite,
                    "mesure_at": row.mesure_at.astimezone(UTC).isoformat()
                    if row.mesure_at.tzinfo
                    else row.mesure_at.replace(tzinfo=UTC).isoformat(),
                    "source": row.source,
                },
            )
        )

    # --- Check-ins (30 j) ---
    ci_q = select(CheckIn).where(
        CheckIn.patient_id == patient.user_id,
        CheckIn.date >= checkin_since,
    )
    ci_result = await db.execute(ci_q)
    for row in ci_result.scalars().all():
        ts = row.created_at.astimezone(UTC)
        if not _after_cursor(ts, "check_in", row.id, since_ts, since_type, since_id):
            continue
        cur = _cursor(ts, "check_in", row.id)
        scored.append(
            (
                cur,
                {
                    "type": "check_in",
                    "id": str(row.id),
                    "server_version": 1,
                    "updated_at": ts.isoformat(),
                    "created_at": ts.isoformat(),
                    "date": row.date.isoformat()
                    if isinstance(row.date, date)
                    else str(row.date),
                    "statut": row.statut,
                },
            )
        )

    # Traitements actifs — full snapshot when since absent
    if since is None:
        tr_result = await db.execute(
            select(PatientTraitement)
            .where(
                PatientTraitement.patient_id == patient.user_id,
                PatientTraitement.statut == "actif",
            )
            .options(
                selectinload(PatientTraitement.maladie),
                selectinload(PatientTraitement.medicaments),
            )
        )
        for t in tr_result.scalars().all():
            ts = (
                t.updated_at.astimezone(UTC)
                if getattr(t, "updated_at", None)
                else now
            )
            scored.append(
                (
                    _cursor(ts, "traitement", t.id),
                    {
                        "type": "traitement",
                        "id": str(t.id),
                        "server_version": 1,
                        "updated_at": ts.isoformat(),
                        "payload": {
                            "id": str(t.id),
                            "date_debut": t.date_debut.isoformat()
                            if t.date_debut
                            else None,
                            "date_fin_prevue": (
                                t.date_fin_prevue.isoformat()
                                if t.date_fin_prevue
                                else None
                            ),
                            "jour_traitement": getattr(t, "jour_traitement", None),
                        },
                    },
                )
            )

    scored.sort(key=lambda x: x[0])
    entities = [e for _, e in scored]
    next_cursor = scored[-1][0] if scored else since

    return {
        "entities": entities,
        "next_cursor": next_cursor,
        "server_time": now,
    }

"""Batterie API aidants — liste, permissions, révocation, observance."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

from app.tests.test_onboarding_api import _auth, _infos, _register_login


async def _patient_and_aidant(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    *,
    patient_email: str = "aidant.patient@example.com",
    aidant_email: str = "aidant.viewer@example.com",
) -> tuple[dict, dict, str]:
    from app.core.config import settings

    api = settings.api_v1_prefix

    tokens_p = await _register_login(
        client, auth_prefix, otp_inbox, cgu_version, email=patient_email
    )
    headers_p = _auth(tokens_p["access_token"])
    await _infos(client, onboarding_prefix, headers_p)
    await client.post(
        f"{onboarding_prefix}/besoin-suivi", headers=headers_p, json={"actif": True}
    )
    r = await client.get(f"{onboarding_prefix}/maladies")
    maladie_id = r.json()[0]["id"]
    await client.post(
        f"{onboarding_prefix}/patient/traitement",
        headers=headers_p,
        json={
            "en_traitement": True,
            "traitements": [{"maladie_id": maladie_id, "phase": "en_cours"}],
        },
    )
    await client.post(
        f"{onboarding_prefix}/patient/permissions",
        headers=headers_p,
        json={"notifications_accordees": True, "batterie_exemptee": True},
    )
    await client.post(f"{onboarding_prefix}/complete", headers=headers_p)

    r = await client.post(f"{api}/patients/me/sync-code", headers=headers_p)
    code = r.json()["code"]

    tokens_a = await _register_login(
        client, auth_prefix, otp_inbox, cgu_version, email=aidant_email
    )
    headers_a = _auth(tokens_a["access_token"])
    await client.post(
        f"{onboarding_prefix}/infos",
        headers=headers_a,
        json={
            "nom_complet": "Paul Mbarga",
            "date_naissance": "1990-01-01",
            "sexe": "M",
            "localisation": "Yaoundé",
        },
    )
    await client.post(
        f"{onboarding_prefix}/besoin-suivi", headers=headers_a, json={"actif": False}
    )
    await client.post(f"{onboarding_prefix}/complete", headers=headers_a)

    r = await client.post(
        f"{api}/aidants/me/sync", headers=headers_a, json={"code": code}
    )
    assert r.status_code == 200, r.text
    patient_id = r.json()["patient_id"]

    return headers_p, headers_a, patient_id


@pytest.mark.asyncio
async def test_aidant_list_permissions_revoke_observance(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    headers_p, headers_a, patient_id = await _patient_and_aidant(
        client, auth_prefix, onboarding_prefix, otp_inbox, cgu_version
    )

    r = await client.get(f"{api}/patients/me/aidants", headers=headers_p)
    assert r.status_code == 200, r.text
    aidants = r.json()
    assert len(aidants) == 1
    assert aidants[0]["nom"] == "Paul Mbarga"
    assert aidants[0]["statut"] == "actif"
    assert aidants[0]["niveau_permission"]["observance"] is True
    assert aidants[0]["niveau_permission"]["constantes"] is False
    aidant_id = aidants[0]["aidant_id"]

    r = await client.get(f"{api}/aidants/me/patients", headers=headers_a)
    assert r.status_code == 200, r.text
    patients = r.json()
    assert len(patients) == 1
    assert patients[0]["patient_id"] == patient_id
    assert patients[0]["prenom"] == "Amina"

    r = await client.get(
        f"{api}/aidants/me/patients/{patient_id}/observance", headers=headers_a
    )
    assert r.status_code == 200, r.text
    obs = r.json()
    assert obs["patient_id"] == patient_id
    assert obs["total"] == 0
    assert obs["taux_observance"] is None

    r = await client.get(
        f"{api}/aidants/me/patients/{patient_id}/prises", headers=headers_a
    )
    assert r.status_code == 200, r.text
    assert r.json() == []

    r = await client.get(
        f"{api}/aidants/me/patients/{patient_id}/notification-prefs",
        headers=headers_a,
    )
    assert r.status_code == 200, r.text
    prefs = r.json()
    assert prefs == {
        "mute_prise_confirmee": False,
        "mute_prise_non_confirmee": False,
        "mute_sos": False,
    }

    r = await client.patch(
        f"{api}/aidants/me/patients/{patient_id}/notification-prefs",
        headers=headers_a,
        json={"mute_prise_confirmee": True, "mute_sos": True},
    )
    assert r.status_code == 200, r.text
    assert r.json()["mute_prise_confirmee"] is True
    assert r.json()["mute_prise_non_confirmee"] is False
    assert r.json()["mute_sos"] is True

    r = await client.patch(
        f"{api}/patients/me/aidants/{aidant_id}/permissions",
        headers=headers_p,
        json={"niveau_permission": {"observance": False, "constantes": True}},
    )
    assert r.status_code == 200, r.text
    assert r.json()["niveau_permission"]["observance"] is False
    assert r.json()["niveau_permission"]["constantes"] is True

    r = await client.get(
        f"{api}/aidants/me/patients/{patient_id}/observance", headers=headers_a
    )
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "PERMISSION_REFUSEE"

    r = await client.get(
        f"{api}/aidants/me/patients/{patient_id}/prises", headers=headers_a
    )
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "PERMISSION_REFUSEE"

    # Prefs restent accessibles sans observance (relation active).
    r = await client.get(
        f"{api}/aidants/me/patients/{patient_id}/notification-prefs",
        headers=headers_a,
    )
    assert r.status_code == 200, r.text
    assert r.json()["mute_sos"] is True

    r = await client.patch(
        f"{api}/patients/me/aidants/{aidant_id}/permissions",
        headers=headers_p,
        json={"niveau_permission": {"observance": True, "constantes": False}},
    )
    assert r.status_code == 200

    r = await client.delete(
        f"{api}/patients/me/aidants/{aidant_id}", headers=headers_p
    )
    assert r.status_code == 200, r.text

    r = await client.get(f"{api}/patients/me/aidants", headers=headers_p)
    assert r.status_code == 200
    assert r.json() == []

    r = await client.get(f"{api}/aidants/me/patients", headers=headers_a)
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "NOT_AN_AIDANT"


@pytest.mark.asyncio
async def test_aidant_patients_requires_relation(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    tokens = await _register_login(
        client,
        auth_prefix,
        otp_inbox,
        cgu_version,
        email="no.aidant@example.com",
    )
    headers = _auth(tokens["access_token"])
    await _infos(client, onboarding_prefix, headers)
    await client.post(
        f"{onboarding_prefix}/besoin-suivi", headers=headers, json={"actif": False}
    )
    await client.post(f"{onboarding_prefix}/complete", headers=headers)

    r = await client.get(
        f"{settings.api_v1_prefix}/aidants/me/patients", headers=headers
    )
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "NOT_AN_AIDANT"

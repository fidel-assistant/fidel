"""Smoke site marketing (Jinja2) — hors /api/v1."""

from fastapi.testclient import TestClient

from app.main import app


def test_home_and_static() -> None:
    with TestClient(app) as client:
        r = client.get("/")
        assert r.status_code == 200
        assert "text/html" in r.headers["content-type"]
        assert "Parce que personne ne devrait affronter la maladie seul." in r.text
        assert "Fidél connecte patients" in r.text
        assert "hero-kicker" not in r.text
        assert "/static/img/mockup_accueil.png" in r.text
        assert "id=\"telecharger\"" in r.text
        assert "btn-download" not in r.text
        assert "Un cercle qui reste là." in r.text
        assert "cercle-reseau.jpg" in r.text
        assert "google-play.svg" in r.text
        assert "apple-store.svg" in r.text

        css = client.get("/static/css/site.css")
        assert css.status_code == 200
        assert "--primary" in css.text


def test_contact_get_and_post_dev() -> None:
    with TestClient(app) as client:
        g = client.get("/contact")
        assert g.status_code == 200
        assert "Contact" in g.text

        p = client.post(
            "/contact",
            data={
                "name": "Amina Test",
                "email": "amina@example.com",
                "message": "Bonjour, message de test landing.",
                "company": "",
            },
        )
        assert p.status_code == 200
        assert "bien été reçu" in p.text


def test_legal_and_health_untouched() -> None:
    with TestClient(app) as client:
        assert client.get("/confidentialite").status_code == 200
        assert client.get("/cgu").status_code == 200
        h = client.get("/api/v1/health")
        assert h.status_code == 200

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from pydantic import ValidationError

from app.core.config import settings
from app.web.contact_service import ContactFormIn, submit_contact
from app.web.paths import TEMPLATES_DIR

router = APIRouter(tags=["web"])
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))


def _ctx(**extra: object) -> dict:
    return {
        "app_name": settings.app_name,
        **extra,
    }


@router.get("/", response_class=HTMLResponse)
async def home(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        "index.html",
        _ctx(request=request, title="Accueil", current_path=request.url.path),
    )


@router.get("/contact", response_class=HTMLResponse)
async def contact_get(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        "contact.html",
        _ctx(
            request=request,
            title="Contact",
            current_path=request.url.path,
            sent=False,
            error=None,
            form={},
        ),
    )


@router.post("/contact", response_class=HTMLResponse)
async def contact_post(
    request: Request,
    name: Annotated[str, Form()],
    email: Annotated[str, Form()],
    message: Annotated[str, Form()],
    company: Annotated[str, Form()] = "",
) -> HTMLResponse:
    raw = {"name": name, "email": email, "message": message, "company": company}
    try:
        form = ContactFormIn.model_validate(raw)
    except ValidationError:
        return templates.TemplateResponse(
            request,
            "contact.html",
            _ctx(
                request=request,
                title="Contact",
                current_path=request.url.path,
                sent=False,
                error="Vérifie les champs (nom, email valide, message d’au moins 10 caractères).",
                form=raw,
            ),
            status_code=400,
        )

    try:
        await submit_contact(form)
    except Exception:
        return templates.TemplateResponse(
            request,
            "contact.html",
            _ctx(
                request=request,
                title="Contact",
                current_path=request.url.path,
                sent=False,
                error="Envoi impossible pour le moment. Réessaie plus tard.",
                form=raw,
            ),
            status_code=500,
        )

    return templates.TemplateResponse(
        request,
        "contact.html",
        _ctx(
            request=request,
            title="Contact",
            current_path=request.url.path,
            sent=True,
            error=None,
            form={},
        ),
    )


@router.get("/confidentialite", response_class=HTMLResponse)
async def privacy(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        "legal_privacy.html",
        _ctx(
            request=request,
            title="Confidentialité",
            current_path=request.url.path,
        ),
    )


@router.get("/cgu", response_class=HTMLResponse)
async def cgu(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        "legal_cgu.html",
        _ctx(
            request=request,
            title="Conditions d’utilisation",
            current_path=request.url.path,
        ),
    )


@router.get("/favicon.ico", include_in_schema=False)
async def favicon() -> RedirectResponse:
    return RedirectResponse(url="/static/img/favicon.svg", status_code=307)

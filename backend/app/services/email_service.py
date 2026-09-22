import asyncio
import html as html_lib
import logging

import resend

from app.core.config import settings

logger = logging.getLogger(__name__)

_PURPOSE_LABELS = {
    "inscription": "vérifier ton adresse email",
    "reset_password": "réinitialiser ton mot de passe",
    "change_email": "confirmer ton nouvel email",
}


def _otp_html(*, code: str, purpose: str, minutes: int) -> str:
    label = _PURPOSE_LABELS.get(purpose, purpose)
    app = settings.app_name
    # HTML email : lignes longues volontaires (styles inline)
    return f"""\
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="utf-8" /></head>
<body style="margin:0;padding:0;background:#f3f4f6;">
<table width="100%" cellspacing="0" cellpadding="0" style="padding:32px 12px;">
<tr><td align="center">
<table width="100%" style="max-width:480px;background:#fff;border-radius:12px;padding:28px 24px;
font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
<tr><td>
<p style="margin:0 0 8px;font-size:13px;color:#6b7280;">{app}</p>
<h1 style="margin:0 0 16px;font-size:22px;color:#111827;">Ton code de vérification</h1>
<p style="margin:0 0 20px;font-size:16px;color:#374151;">
Utilise ce code pour <strong>{label}</strong>.
</p>
<p style="margin:0 0 24px;text-align:center;font-size:32px;letter-spacing:10px;font-weight:700;">
{code}
</p>
<p style="margin:0;font-size:14px;color:#6b7280;">
Valable <strong>{minutes} minutes</strong>.
Si tu n'as pas fait cette demande, ignore cet email.
</p>
<p style="margin:24px 0 0;font-size:13px;color:#9ca3af;">— L'équipe {app}</p>
</td></tr></table>
</td></tr></table>
</body>
</html>
"""


def _otp_text(*, code: str, purpose: str, minutes: int) -> str:
    label = _PURPOSE_LABELS.get(purpose, purpose)
    return (
        f"{settings.app_name}\n\n"
        f"Ton code pour {label} : {code}\n"
        f"Valable {minutes} minutes.\n"
        f"Si tu n'es pas à l'origine de cette demande, ignore ce message.\n"
    )


def _send_via_resend(*, to_email: str, subject: str, text: str, html: str) -> str:
    resend.api_key = settings.resend_api_key
    result = resend.Emails.send(
        {
            "from": settings.email_from,
            "to": [to_email],
            "subject": subject,
            "text": text,
            "html": html,
        }
    )
    return str(result.get("id", ""))


async def send_otp_email(*, to_email: str, code: str, purpose: str) -> None:
    """Envoie l'OTP via Resend. Sans clé API : log en console (dev only)."""
    subject = f"{settings.app_name} — ton code ({settings.otp_expire_minutes} min)"
    text = _otp_text(code=code, purpose=purpose, minutes=settings.otp_expire_minutes)
    html = _otp_html(code=code, purpose=purpose, minutes=settings.otp_expire_minutes)

    if not settings.resend_api_key:
        logger.warning(
            "RESEND_API_KEY manquant — OTP %s pour %s : %s (dev only)",
            purpose,
            to_email,
            code,
        )
        return

    try:
        email_id = await asyncio.to_thread(
            _send_via_resend,
            to_email=to_email,
            subject=subject,
            text=text,
            html=html,
        )
        logger.info("OTP %s envoyé à %s via Resend (id=%s)", purpose, to_email, email_id)
    except Exception:
        logger.exception("Échec envoi OTP Resend vers %s", to_email)
        if settings.app_env == "development" or settings.debug:
            logger.warning(
                "Fallback dev — OTP %s pour %s : %s",
                purpose,
                to_email,
                code,
            )
            return
        raise


async def send_contact_message(
    *,
    name: str,
    reply_email: str,
    message: str,
) -> None:
    """Envoie un message du formulaire contact. Sans clé API : log (dev)."""
    to = settings.contact_to_email.strip()
    subject = f"[Contact Fidel] Message de {name}"
    text = (
        f"Nom : {name}\n"
        f"Email : {reply_email}\n\n"
        f"{message}\n"
    )
    safe_name = html_lib.escape(name)
    safe_email = html_lib.escape(reply_email)
    safe_message = html_lib.escape(message)
    html = f"""\
<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8" /></head>
<body style="font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#0f172a;">
<p><strong>Nom :</strong> {safe_name}</p>
<p><strong>Email :</strong> <a href="mailto:{safe_email}">{safe_email}</a></p>
<pre style="white-space:pre-wrap;font-family:inherit;">{safe_message}</pre>
</body></html>
"""

    if not settings.resend_api_key:
        logger.warning(
            "RESEND_API_KEY manquant — contact de %s <%s> : %s",
            name,
            reply_email,
            message[:200],
        )
        return

    try:
        email_id = await asyncio.to_thread(
            _send_via_resend,
            to_email=to,
            subject=subject,
            text=text,
            html=html,
        )
        logger.info("Contact de %s envoyé à %s (id=%s)", reply_email, to, email_id)
    except Exception:
        logger.exception("Échec envoi contact Resend de %s", reply_email)
        if settings.app_env == "development" or settings.debug:
            logger.warning(
                "Fallback dev — contact de %s <%s> : %s",
                name,
                reply_email,
                message[:200],
            )
            return
        raise

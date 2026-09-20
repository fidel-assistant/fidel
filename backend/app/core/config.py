from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Toujours résoudre .env depuis backend/, même si le CWD uvicorn change.
_BACKEND_ROOT = Path(__file__).resolve().parents[2]
_ENV_FILE = _BACKEND_ROOT / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "Fidel Assistant"
    app_env: str = "development"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"
    public_base_url: str = "http://localhost:8000"

    database_url: str = "postgresql+asyncpg://localhost/fidel"

    jwt_secret: str = "change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30

    otp_expire_minutes: int = 10
    otp_max_attempts: int = 5
    otp_resend_max_per_hour: int = 5
    temp_token_expire_minutes: int = 15
    password_min_length: int = 8
    cgu_current_version: str = "v1.0"
    sync_code_expire_minutes: int = 10
    sos_cancel_window_seconds: int = 30
    sos_aidant_ack_timeout_seconds: int = 45
    # FCM HTTP legacy (optionnel) — si vide, finalize journalise sans push.
    fcm_server_key: str = ""
    # Cron interne (POST /internal/jobs/…) — header X-Cron-Secret
    cron_secret: str = ""
    # en_attente → manquee après heure_prevue + grâce (doit rester > délai aidant typique)
    prise_manquee_grace_hours: int = 12
    media_root: str = "media"
    voix_rappel_max_bytes: int = 2 * 1024 * 1024  # 2 Mo
    patient_photo_max_bytes: int = 2 * 1024 * 1024  # 2 Mo
    login_max_attempts: int = 8
    login_window_minutes: int = 15
    # Rate limits /auth — par IP
    auth_ip_max_per_minute: int = 90
    auth_sensitive_max_attempts: int = 30
    auth_sensitive_window_minutes: int = 15

    google_client_id_android: str = ""
    google_client_id_ios: str = ""
    google_client_id_web: str = ""

    cors_origins: str = "http://localhost:3000,https://educampro.edu.cm"

    # Resend (OTP / emails transactionnels) — prioritaire sur SMTP
    resend_api_key: str = ""
    email_from: str = "Fidel Assistant <noreply@educampro.edu.cm>"

    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def google_client_ids(self) -> list[str]:
        return [
            cid.strip()
            for cid in (
                self.google_client_id_android,
                self.google_client_id_ios,
                self.google_client_id_web,
            )
            if cid and cid.strip()
        ]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

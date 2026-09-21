# Index

| Document | Emplacement |
|---|---|
| Architecture Cursor | [`.cursor/architecture.md`](../.cursor/architecture.md) |
| Specs & contrats | [`skills/README.md`](../skills/README.md) |
| Backend | [`backend/README.md`](../backend/README.md) |
| Google Sign-In setup | [`google-auth-setup.md`](google-auth-setup.md) |
| Emails Resend | [`email-resend.md`](email-resend.md) |
| Batterie tests auth | [`auth-test-battery.md`](auth-test-battery.md) |
| Runbook sync offline | [`sync-runbook.md`](sync-runbook.md) |
| Jobs cron (prises / aidant) | [`cron-jobs.md`](cron-jobs.md) |
| Scénario onboarding | [`onboarding-scenario.md`](onboarding-scenario.md) |
| Contribution | [`CONTRIBUTING.md`](../CONTRIBUTING.md) |
| Sécurité | [`SECURITY.md`](../SECURITY.md) |

## Roadmap V1

| # | Étape | Statut |
|---|---|---|
| 1a | Auth API (OTP, Google IdP, sessions, Resend) | **Fait** |
| 1b | Onboarding capacités + API dashboard / médicaments / prises | **Fait** |
| 1c | Auth + onboarding Flutter + alarmes locales patient | **Fait** (socle) |
| 2 | Rappels offline-first + sync V2 (Drift / push-pull) | **Fait** (Phase 6 + polish A–D) |
| 3 | Constantes de santé (API + onglet Santé) | **Fait** |
| 4a | Réseau aidant + check-in + SOS (API / FCM) | **Fait** |
| 4b | UI aidant — phases A→D | **Fait** |
| 5 | Moteur notification / consentement + cron manquée | **Fait** (jobs + opt-in) |
| 6 | UI patient — phases 1→5 | **Fait** |

Détail : [`.cursor/architecture.md`](../.cursor/architecture.md) (UI aidant A→D, UI patient 1→5, sync offline).

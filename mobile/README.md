# Application Flutter — Fidel Assistant

Structure conforme à `skills/mobile-flutter/SKILL.md` (feature-first, offline-first).

## Prérequis

- Flutter SDK 3.5+
- Backend local : `make backend-run` (port 8000)

## Démarrage

Depuis `mobile/` :

```bash
flutter run
```

L’URL API et Google Sign-In se lisent dans `assets/config/app.json` (IP LAN du PC + Client IDs). Pas besoin de `--dart-define` au quotidien.

## Socle en place

- `core/config` — `AppConfig` + dart-defines
- `core/storage` — JWT dans `flutter_secure_storage`
- `core/network` — Dio + refresh Bearer automatique
- `core/theme` — palette (`#0494D0` / `#037299`) + police **Satoshi**
- `l10n` — EN / FR (`gen-l10n`), choix de langue au premier lancement
- Auth UI — login (header `assets/images/brand_header_v2.png` + `logo_mark_white.svg`) + `POST /auth/login`
- Features dossiers : auth, onboarding, medicaments, constantes, reseau, home
- Permissions Android : Internet, notifs, alarmes exactes, boot

## Prochaine étape

Onboarding initial (`infos` → besoin suivi → …) + mot de passe oublié + Google Sign-In.

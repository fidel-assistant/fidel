# Logos Fidel

Sources livrées ici ; **copies appliquées** dans l’app via `scripts/apply_brand_assets.py`.

| Usage | Emplacement app |
|---|---|
| Marque in-app | `mobile/assets/images/logo_mark*.svg`, `brand_header_v2.png` |
| Launcher Android | `AppIcon-Android.png` → `mobile/android/.../mipmap-*/` + adaptive |
| Notifs Android | `mobile/android/.../drawable*/ic_stat_*.png` |
| Splash | `launch_image` + `fidel_primary` |
| iOS | `mobile/ios/.../AppIcon.appiconset/` |

Couleurs marque : `#0494D0` (primary) · `#037299` (primary dark) — voir `AppColors`.

Pour régénérer après un nouveau drop dans ce dossier :

```bash
backend/.venv/Scripts/python.exe scripts/apply_brand_assets.py
```

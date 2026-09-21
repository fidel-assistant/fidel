# Runbook sync offline (Phase 6 + polish A–D)

Diagnostic rapide des pannes SyncEngine / outbox / pull — contexte connexion instable.

## Prérequis

- App Flutter avec Drift + prefs
- Backend `POST /api/v1/sync/push` + `GET /api/v1/sync/pull` (chemin flush app V1)
- Logs debug : filtre `SyncMetrics` / `NetworkStatus` / `SyncEngine`
- `POST /api/v1/prises/sync-offline` = API **legacy** (statut-batch) — hors flush `SyncEngine` ; ne pas s’en servir pour diagnostiquer l’app V1

## Clés prefs utiles

| Clé | Rôle |
|---|---|
| `sync_last_pass_v1` | JSON dernière passe (pass_id, pushed, applied, duplicate, rejected, pulled, outbox_remaining, skipped_reason, error) |
| `sync_pull_cursor_v1` | Cursor opaque pull `{ts}\|{type}\|{id}` |
| `server_clock_offset_ms_v1` | Offset horloge serveur (ms) |

## Symptômes → actions

### Outbox qui ne se vide pas

1. Lire `sync_last_pass_v1` : `error` ? `skipped_reason` (`offline` / `circuit` / `cooldown`) ?
2. Si `circuit` : attendre 2 min (breaker) ou redémarrer après résolution 5xx backend.
3. Si `offline` / `degraded` : vérifier `/health` et Wi‑Fi réel (pas seulement connectivité OS).
4. Entrées `failed_permanent` : conflit métier (ex. report sur prise déjà `confirmee`) — ne bloquent pas le reste. **UI** : bandeau Accueil (`SyncStatusBanner`) affiche le compteur ; tap (si plus de pending) → sheet **Effacer** / **Réessayer** (`requeue` → flush).

### Doublons perçus côté UI

- Rejeu du même `mutation_id` → serveur `duplicate` (un seul effet). Vérifier tests `test_sync_push_mutation_id_replay_x3`.
- Constante append-only : deux saisies = deux lignes normales.

### Check-in refusé

- `CHECK_IN_DEJA_FAIT_AUJOURDHUI` : déjà un check-in ce jour (autre device ou retry). Pull pour réhydrater.

### Horloge device fausse

- `client_ts` doit venir de `ServerClock.now()` (header HTTP `Date`), pas de l’horloge locale brute.
- Vérifier `server_clock_offset_ms_v1` après une requête API réussie.

### Accueil pas à jour après sync autre device

1. Flush a-t-il fait un pull ? (`pulled` > 0 dans `sync_last_pass_v1`)
2. Cursor corrompu : effacer `sync_pull_cursor_v1` → prochain pull full fenêtre.
3. Outbox pending sur la même `entity_id` protège le snapshot local (volontaire).

## Checklist QA automatisée (Phase 6 + polish A–C)

| # | Critère | Test |
|---|---|---|
| 1 | Rejeu `mutation_id` ×3 | `backend/app/tests/test_sync_api.py::test_sync_push_mutation_id_replay_x3` |
| 2 | Coupure mid-push + retry | `mobile/test/sync_engine_test.dart` QA#2 |
| 3 | Flapping ≤2 flush / 60s | `mobile/test/sync_flapping_test.dart` |
| 4 | Horloge device −3 h | `mobile/test/sync_engine_test.dart` QA#4 |
| 5 | Anti-downgrade `confirmee` | `test_sync_offline_no_downgrade_confirmee` |
| 6 | §F manquee + confirm `client_ts` stale → applied | `test_sync_push_manquee_confirm_stale_client_ts_applied` |
| 7 | §F confirm stale → `SYNC_CONFLICT` | `test_sync_push_stale_confirm_rejected` |
| 8 | §F report stale / fresh | `test_sync_push_report_stale_client_ts_rejected`, `test_sync_push_report_fresh_client_ts_applied` |
| 9 | Dead letters outbox requeue | `mobile/test/sync_outbox_test.dart` |
| 10 | Bandeau dead letters visible | `mobile/test/sync_status_banner_test.dart` |

```bash
# Backend
cd backend && .venv/Scripts/python.exe -m pytest app/tests/test_sync_api.py -q

# Mobile
cd mobile && flutter test \
  test/sync_engine_test.dart \
  test/sync_flapping_test.dart \
  test/sync_pull_merge_test.dart \
  test/sync_outbox_test.dart \
  test/sync_status_banner_test.dart
```

**Dernière exécution locale (Phase D)** : suites ci-dessus **vertes** (à rejouer après changement SyncEngine / push).

## Checklist device (Phase D)

À cocher manuellement sur téléphone / émulateur (Accueil patient authentifié, au moins une prise du jour) :

- [ ] **1. Offline** — Mode avion ON → bandeau offline ; confirmer une prise → compteur « en attente » (ou pending au retour)
- [ ] **2. Flush** — Mode avion OFF → tap bandeau → toast sync OK ; bandeau disparaît si outbox vide
- [ ] **3. Dead letter** — Forcer un conflit (ex. report après prise déjà confirmée, ou rejouer une mutation rejetée) → bandeau dead letters (« Voir ») → sheet Effacer **ou** Réessayer
- [ ] **4. Accueil** — Pull-to-refresh après flush → doses / statuts à jour
- [ ] **5. (Optionnel) Horloge −3 h** — Confirmer une prise puis sync ; pas de doublon ni conflit absurde

## Commandes support (device)

- Hot restart après clear prefs de sync (cursor / last_pass) si état incohérent.
- Ne pas supprimer l’outbox Drift manuellement hors debug — risque de perdre des mutations non poussées.

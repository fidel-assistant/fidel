# Architecture — Fidel Assistant

Quand ce fichier est mentionné via `@architecture`, **lire le dossier `skills/`** avant toute décision technique ou produit.

## Ordre de lecture obligatoire

1. Toujours commencer par `skills/project-overview/SKILL.md`
2. Ensuite, charger les skills pertinentes selon la tâche (liste ci-dessous)
3. Les fichiers `data-model` et `api-contract` sont des **contrats** : les respecter à la lettre ; si un champ ou une route manque, modifier d’abord le skill concerné, puis coder

## Décision produit clé — Capacités (pas de rôle exclusif)

Un compte n’est **pas** « patient **ou** aidant ».

| Capacité | Activation |
|---|---|
| Profil patient (suivi pour soi) | Onboarding (« Tu veux un suivi pour toi ? ») **ou** plus tard depuis l’accueil |
| Aidant (accompagner quelqu’un) | Depuis l’accueil via code / QR — **pas** pendant l’onboarding initial |

Les deux sont **cumulables** sur le même compte. Détail : `skills/auth-onboarding/SKILL.md`.

Onboarding initial : infos communes → besoin de suivi ? → (si oui) **step C léger** (maladie, phase, date début, attributs optionnels — **pas** de médicaments/horaires) + permissions device → home.  
Médicaments + horaires : wizard **après** la home, via `GET /patients/me/dashboard` (`prochaine_action: configurer_medicaments`).  
Permissions notifs/batterie : seulement si branche suivi perso (option A).

## Avancement V1 (backend sur `main`)

| Bloc | Statut | Notes |
|---|---|---|
| Auth (OTP, Google IdP, JWT, sessions, Resend, rate limits `/auth`) | **Fait** | Tests verts |
| Onboarding capacités + sync aidant + activer suivi depuis home | **Fait** | Step C léger ; pas de rôle exclusif |
| Catalogue maladies / protocoles (seed) + schéma 4 couches | **Fait** | Migration `b4e8c1a29f3d` appliquée sur Neon |
| API dashboard, traitements, médicaments, horaires, prises + `POST /prises/sync-offline` | **Fait** | Prises pré-générées à la création d’horaire |
| Aidants, contacts urgence, check-in / SOS, constantes, préférences consentement, voix de rappel, réglages patient | **Fait** | API + FCM ; UI aidant = phases ci-dessous |
| App Flutter (auth, onboarding, alarmes locales patient) | **Fait** (socle) | Préavis H0−Δ + alarme H0 + notif marquage H+5 |
| UI patient (Accueil doses, Santé, manquée, confirm) | **Avancé** | Focus V1 patient |
| UI aidant (Accueil accompagnement, détail, deep links) | **Prochaine** | Phases A → C ci-dessous |
| Sync offline V2 (outbox, Drift, push/pull) | **Fait** (Phase 6) | Voir `offline-sync` — contrat + runbook |

**Rappels médicaments** : 100 % **locaux** sur le téléphone (offline, même avion). Timeline par prise : **préavis** (notif H0−Δ, défaut 5 min) → **H0** = alarme applicative Fidel (son insistent + UI) **et** notif en parallèle → **H0+5 min** = notif de marquage (actions). Les notifs ne sont **pas** remplacées par l’alarme : elles s’ajoutent. FastAPI ne sonne pas et ne poll pas les doses. Pas de Celery/Redis en V1. **FCM aidant** : SOS + observance (`prise_confirmee_aidant` à la sync confirm, `prise_non_confirmee_aidant` via cron `POST /internal/jobs/scan-prises-non-confirmees`) — uniquement via `engagement-principle` (`regle_auto` opt-in — jamais d’alerte tiers automatique). **Marquage manqué** : cron distinct `POST /internal/jobs/mark-prises-manquees` (`en_attente` → `manquee` après grâce 12 h) — pas de FCM. Confirmation tardive OK. Détail : `skills/engagement-principle/SKILL.md` + `skills/mobile-flutter/SKILL.md`.

## Directive UI — Interface aidant (prochaine itération mobile)

**Constat** : l’UI V1 a surtout avancé le **côté patient** (Accueil doses, Santé, manquée, confirm). Côté **aidant**, la coque est partagée ; l’entrée est Cercle → détail lecture (observance 7 j + constantes) + SOS. Pas d’Accueil accompagnement dédié.

**Règles** (inchangées) :

- Capacités cumulables — **jamais** d’écran / nav « Je suis patient **ou** aidant »
- Même shell (Accueil / Santé / Cercle / Profil) — adapter le **contenu**, pas forker l’app
- Aidant = **observer / accompagner** — pas d’alarme locale patient, pas de confirmation de prise à sa place en V1
- Respect strict de `niveau_permission` (`observance`, `constantes`) — masquer les blocs non autorisés
- Ton bienveillant (copy engagement) — pas d’alarmisme médical

**Modes Accueil** selon `has_patient_profile` × `is_aidant` :

| Mode | Contenu Accueil |
|---|---|
| Patient seul | Accueil personnel actuel (doses, check-in…) |
| Aidant seul | Accueil **accompagnement** : patients suivis + alertes (SOS / prise non confirmée) + CTA sync code — **pas** le CTA « activer mon suivi » comme seul message |
| Cumul | Accueil **personnel** + bandeau / section « Personnes que j’accompagne » → détail |

### Phases d’implémentation — UI aidant

Ordre strict : terminer une phase (critères de done) avant de démarrer la suivante. Toute route / champ manquant → d’abord `api-contract` (+ `data-model` si besoin), puis code.

| Phase | Objectif | Livrables | Done quand |
|---|---|---|---|
| **A — Accueil & navigation** | L’aidant-only (et le cumul) a un Accueil compréhensible | Modes Accueil (tableau ci-dessus) ; bandeau / section « Personnes que j’accompagne » si cumul ; Santé reste patient-only (empty si pas de profil) ; CTA sync code visible sans forcer « activer mon suivi » | Aidant-only : Accueil utile en &lt; 5 s ; cumul : mes doses **et** mes patients sans confusion |
| **B — Détail & alertes** | Observer un patient + agir sur les push | Deep link FCM (observance / SOS) → détail du **bon** patient ; **tap notif SOS → `/sos-aidant`** (FCM + locale, sans rejouer l’alarme) ; résumé **du jour** (si `observance`) + empty / permissions visibles ; SOS non régressé | Tap notif SOS → écran acquitter ; tap notif observance → bon patient ; `observance=false` → zéro chiffre de prise |
| **C — Cercle & actions** | Hub réseau + accompagnement concret | Cartes Cercle avec signal d’état ; upload voix depuis le détail (API existante) ; liste SOS actifs depuis Accueil aidant | Cercle lisible multi-patients ; voix uploadable ; SOS listés |
| **D — Parité soft (optionnel)** | Enrichir sans devenir un Accueil patient | Timeline doses **lecture seule** (contrat API d’abord si manquant) ; préférences notif aidant (mute / par patient) | Spec API mergée **avant** UI ; pas de confirmation de prise par l’aidant |

**API réutilisable dès A–C** : `GET /aidants/me/patients`, `…/observance`, `…/constantes`, voix, SOS. **Phase D** : documenter d’abord tout endpoint « état du jour » / timeline manquant. Skills : `auth-onboarding`, `engagement-principle`, `mobile-flutter`, `api-contract`.

## Index des skills

| Skill | Chemin | Quand la lire |
|---|---|---|
| Vue d’ensemble | `skills/project-overview/SKILL.md` | **Toujours en premier** — mission, stack, capacités, consentement |
| Auth & onboarding | `skills/auth-onboarding/SKILL.md` | Inscription, OTP, Google, JWT, onboarding capacités, sync aidant |
| Backend FastAPI | `skills/backend-fastapi/SKILL.md` | Routes, structure `app/`, erreurs, sécurité |
| Base Neon | `skills/database-neon/SKILL.md` | Migrations, conventions, usage MCP Neon |
| Modèle de données | `skills/data-model/SKILL.md` | Entités, champs, relations (contrat) |
| Contrat API | `skills/api-contract/SKILL.md` | Endpoints méthode/entrée/sortie/erreurs (contrat) |
| Mobile Flutter | `skills/mobile-flutter/SKILL.md` | Alarmes locales, préavis / H0 / marquage, Riverpod, UI |
| Offline sync | `skills/offline-sync/SKILL.md` | **Contrat** — outbox, SyncEngine, Drift, conflits, hystérésis réseau |
| Moteur d’engagement | `skills/engagement-principle/SKILL.md` | Notifications, consentement, types d’alerte |

## Stack (rappel)

| Couche | Techno |
|---|---|
| Backend | Python + FastAPI (`/api/v1`) — prod : **`https://educampro.edu.cm`** |
| Base de données | Neon (Postgres) + Alembic + MCP Neon |
| Mobile | Flutter (offline-first) |
| Auth | Maison — JWT + OTP + **Google OAuth** (IdP uniquement ; pas Firebase Auth / Auth0 / Supabase Auth) |
| Emails | Resend (`@educampro.edu.cm`) |

## Règle produit absolue

```
OBSERVER → ENCOURAGER / INFORMER → PROPOSER → ATTENDRE LE CONSENTEMENT EXPLICITE
```

Aucun contact automatique d’un tiers (aidant, médecin, urgence) sans consentement explicite préalable, sauf SOS (consentement = geste SOS) et `regle_auto` opt-in configurée par le patient.

## Offline-first (rappel)

- Critique (rappels, confirmations de prise) : **côté app** + sync. Contrat : `skills/offline-sync/SKILL.md` (Phases 0–6 livrées). API : `POST /prises/sync-offline`, `POST /sync/push`, `GET /sync/pull`.
- Auth (inscription, OTP, login, refresh) : **online**. Session locale via JWT sécurisés après login.
- Sync offline V2 — **Phase 6 livrée** (`offline-sync`) ; pas de bascule réseau sans hystérésis (connexion instable).

## Instructions pour l’agent

- Avant de coder : lire `project-overview`, puis les skills du module touché
- Avant une table / migration : `data-model` + `database-neon`
- Avant une route API ou un appel Flutter : `api-contract`
- Avant une notification / alerte : `engagement-principle`
- Avant file de sync / base locale / pull-push : `offline-sync` + `api-contract` (Sync V2)
- Ne jamais inventer un endpoint, une entité ou un type d’alerte absents des contrats — les documenter d’abord dans le skill concerné
- Ne jamais réintroduire un choix de rôle exclusif `patient|aidant` dans l’UI ou l’API
- Avant de personnaliser l’UI aidant : lire **Directive UI — Interface aidant** + phases A→D ; ne pas sauter de phase ; skills `mobile-flutter` / `engagement-principle` / `api-contract`

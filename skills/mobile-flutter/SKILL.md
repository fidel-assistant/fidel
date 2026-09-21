---
name: mobile-flutter
description: Architecture de l'application mobile Flutter, gestion d'état, mode offline-first (voir aussi offline-sync), notifications locales + alarme applicative (préavis H0−Δ, alarme H0, marquage H+5), garde-fous OS, réglages alarme in-app, sécurité des tokens, et conventions UI/accessibilité. À consulter par tout agent IA avant d'écrire ou modifier un écran, un provider/state, une intégration API, ou toute logique de rappel/alarme côté app. Lire project-overview/SKILL.md, offline-sync/SKILL.md et auth-onboarding/SKILL.md en complément.
---

# Mobile — Flutter

## Principes non négociables

1. **Offline-first** : toute fonctionnalité critique (rappels de médicaments, confirmation de prise) doit fonctionner sans connexion internet, avec synchronisation automatique au retour du réseau. Ce n'est pas une optimisation ajoutée après coup, c'est une contrainte d'architecture dès le départ.
2. **Fiabilité des rappels avant tout** : un rappel de médicament qui ne se déclenche pas est le pire bug possible sur ce projet. Toute décision technique douteuse doit être tranchée en faveur de la fiabilité du rappel plutôt que de l'esthétique ou de la simplicité de code.
3. **Accessibilité par défaut** : gros boutons, contraste suffisant, tailles de police ajustables, compatibilité lecteur d'écran — le public cible inclut des personnes âgées ou peu à l'aise avec la technologie.

## Structure de dossiers (feature-first)

```
lib/
├── main.dart
├── core/
│   ├── config/                # variables d'environnement, endpoints API
│   ├── network/                # client Dio + intercepteurs (auth, refresh, retry offline)
│   ├── storage/                 # flutter_secure_storage (tokens), base locale (sync/cache)
│   └── theme/                   # thème, typographie, tokens de design
├── features/
│   ├── auth/                    # inscription, OTP, login, Google Sign-In, mot de passe oublié
│   ├── onboarding/               # infos communes, besoin suivi?, branche patient, permissions
│   ├── medicaments/               # ajout traitement, rappels, confirmation de prise
│   ├── constantes/                 # saisie et suivi poids/tension/etc.
│   ├── reseau/                     # aidants, contacts d'urgence, check-in, SOS
│   └── home/                       # accueil + activer suivi / accompagner (sync)
├── shared/
│   ├── widgets/                    # composants réutilisables
│   └── l10n/                        # fichiers de traduction (intl)
└── services/
    ├── notification_service.dart     # planification des rappels locaux
    ├── sync_engine.dart              # SyncEngine — outbox → POST /sync/push + pull
    ├── sync_outbox.dart              # outbox Drift + migration legacy
    └── network_status.dart           # hystérésis / probe / circuit breaker
```

Chaque feature suit le même découpage interne : `presentation/` (écrans, widgets), `application/` (state/providers), `domain/` (modèles), `data/` (repository, appels API).

## Gestion d'état

- **Riverpod** recommandé (testable, pas de `BuildContext` requis pour la logique métier, bon support offline/async)
- Un provider par responsabilité claire (ex : `authStateProvider`, `onboardingStateProvider`, `medicamentsProvider`) plutôt que des providers fourre-tout
- Toute donnée qui doit survivre à un redémarrage de l'app (état d'onboarding en cours, file de sync en attente) passe par le stockage local, pas seulement par le state en mémoire

## Réseau et authentification

- Client HTTP : `dio`, avec un intercepteur dédié qui :
  - ajoute l'access token sur chaque requête authentifiée
  - détecte un 401, tente un refresh automatique via le refresh token, rejoue la requête originale, et déconnecte l'utilisateur seulement si le refresh échoue aussi
  - met les requêtes en échec réseau (pas d'auth) en **file d'attente locale** plutôt que de simplement afficher une erreur, quand l'action concernée doit être synchronisée plus tard (ex : confirmation de prise faite hors-ligne)
- **Stockage des tokens** : `flutter_secure_storage` uniquement (Keychain iOS / Keystore Android). Jamais dans `SharedPreferences` en clair, jamais en variable statique persistée sur disque non chiffré.

## Mode offline-first et synchronisation

> **Contrat détaillé** : `offline-sync/SKILL.md` (invariants, outbox, NetworkStatus, conflits, roadmap). Ce paragraphe ne fait que le rappel mobile.

- Base locale = **Drift** (source de vérité locale pour traitements, horaires, prises récentes / 48 h). Pas Hive comme store métier relationnel.
- Toute action critique (confirmer une prise, reporter, saisir une constante en P1) s’écrit **d’abord en local** (`snapshot ⊕ outbox`), puis le `SyncEngine` pousse au serveur. L’UI ne bloque jamais sur le réseau pour ces actions.
- Résolution de conflit : **matrice par entité** dans `offline-sync` — **pas** de last-write-wins générique.
- **Phase 3 livrée** : Drift snapshot P0 + projection Accueil (`snapshot ⊕ outbox`) ; outbox migrée depuis SharedPreferences. Les alarmes locales (préavis / H0 / H+5) et caches `reminder_*` restent inchangés.
- Sync au retour réseau uniquement après **hystérésis** (éviter le flapping sur connexion instable) — détail dans `offline-sync` § NetworkStatus.

## Notifications et alarmes locales — le cœur du produit

C'est la partie la plus critique techniquement. **Tout est local** (offline, même avion) : FastAPI ne sonne pas et ne poll pas les doses. Les notifications push serveur (FCM) réveillent l’**aidant** pour SOS / engagement — **ne pas confondre** avec l’alarme patient.

**Check-in quotidien (15:00 local)** : si le patient a au moins une maladie **active**, `CheckInReminderService` planifie une notif récurrente (`DateTimeComponents.time`) avec 4 actions (`tres_mal` → `super`). Réponse → Drift + outbox `create_check_in` + flush (immédiat si online). Distinct des alarmes doses (`DoseSlot`). Annulé quand plus aucun `PatientTraitement` actif (après « Marquer terminé » / auto-expire `date_fin_prevue`).

**Fin de traitement** : `PATCH /patients/me/traitements/{id}` `{statut: termine}` — cascade meds/horaires + prises `en_attente` → `manquee` ; dashboard vide pour ce traitement → `rescheduleAll` annule les DoseSlots ; check-in si dernier actif.

**Prise manquée (serveur)** : après `heure_prevue + 12 h`, job `mark-prises-manquees` passe `en_attente` → `manquee`. L’UI Accueil traite `manquee` comme **encore confirmable** (`isConfirmable` / `DoseSlot.confirmablePriseIds`) — confirmation tardive → `confirmee`. Les alarmes locales ne replanifient que les `en_attente` (`pendingPriseIds`).

**SOS (lock + aidants + fallback appel)** :
- Notif persistante Android (`cm.fidel.assistant/sos`) + Cercle → `SosService.startSosFlow` → countdown 30 s (annulable).
- Online : `POST /patients/me/sos` puis `…/confirm` → FCM aidants liés ; attente ack 45 s (`SosEscalationService`) sinon `ACTION_CALL` 1er contact (cache `EmergencyContactCache`).
- Offline : après countdown → `ACTION_CALL` / `ACTION_DIAL` (permission `CALL_PHONE`).
- Aidant : FCM / poll `GET /aidants/me/sos/active` → notif + `/sos-aidant` → `POST …/ack`.

### Trois moments distincts par **DoseSlot** (maladie × heure)

L’unité de planification n’est **pas** la prise individuelle, mais le **créneau thérapeutique** :

- même `heure_prevue` (minute locale) + même `traitement_id` / maladie → **1 DoseSlot**
- 2 maladies à la même heure → **2 slots** (2 alarmes)
- 1 préavis + 1 alarme H0 + 1 marquage H+5 **par slot** (ex. 5 medocs tuberculose à 08:00 → 3 notifications au total, pas 15)
- Copy maladie-first (non-discret) : préavis « Dans Δ min — {maladie} », H0 « {maladie} — c’est l’heure », mark « Avez-vous pris vos médicaments ({maladie}) ? » + liste medocs (si > 6 : « N médicaments »)
- **Cancel auto du préavis** du slot dès que l’alarme H0 sonne / `AlarmRingScreen` s’ouvre
- Confirm / snooze H+5 et Accueil : **tout le slot** (N mutations outbox)

Les **notifications** (préavis + marquage + bandeau H0) et l’**alarme applicative** (H0) se **complètent** : on n’enlève pas le système de notifs pour « remplacer » par une alarme.

| Instant | Canal | Rôle | Comportement |
|---|---|---|---|
| **H0 − Δ** (préavis) | Notif locale | Avertir avant la prise | Texte du type « dans Δ min — {maladie} ». **Pas** d’alarme sonore. Δ configurable dans l’app (**défaut 5 min** ; options typiques 2 / 5 / 10). Annulé automatiquement à H0. |
| **H0** (`heure_prevue`) | **Alarme app** + notif locale | Réveil effectif | L’alarme **lancée par Fidel** (écran plein / Activity, son en boucle jusqu’à action utilisateur) **et** une notification en parallèle. **Sans** boutons « J’ai pris » sur ce moment (le marquage vient à H+5). |
| **H0 + 5 min** | Notif locale (marquage) | Confirmer la prise | Ancrée sur **l’instant réel de sonnerie** (pas l’heure prévue initiale). Actions **« J’ai pris »** / **« Plus tard »**. Un **Plus tard** (snooze) **annule** ce marquage ; il ne revient qu’après la **prochaine** sonnerie (+5 min). File offline → N confirms/reports outbox. |

> Une notif canal « alarm » **ne suffit pas** : H0 doit être une **expérience alarme** (son insistent, UI Fidel, pas un simple bandeau type messagerie).

### Planification technique

- `DoseSlot` (`lib/services/dose_slot.dart`) : groupement + `slotId` stable ; ids notif/alarme dérivés du `slotId`
- `flutter_local_notifications` pour **préavis**, **bandeau H0** et **marquage H+5**
- Mode **alarme exacte** (`AndroidScheduleMode.exactAllowWhileIdle`) — ne pas soumettre au Doze standard
- Alarme H0 : mécanisme natif dédié (ex. `AlarmManager` / Activity plein écran / service audio) en plus de la notif — le détail d’implémentation peut évoluer, le contrat produit ci-dessus non
- **Reschedule différentiel** : à chaque sync home, ne replanifier que les **slots** ajoutés / modifiés / retirés (snapshot local). **Ne jamais** `Alarm.stop` / re-set une alarme **en cours de sonnerie** — le ring UI / Arrêter gère la fin.
- **Cache local + restore au démarrage** : les doses planifiées sont persistées (`reminder_doses_cache_v1`, liste plate de `ScheduledDose`). Au cold start / après reboot, `restoreFromLocalCache()` (dans `main.dart`, après `Alarm.init`) réarme préavis + H0 + mark **sans attendre** le load Accueil ni le réseau. Les receivers `BOOT_COMPLETED` (package `alarm` + FLN) restent en place ; le restore Flutter couvre le cas où l’utilisateur rouvre l’app.
- **Perf / batterie** : horizon de planification **48 h** (`ReminderSyncPerf`) ; skip de `syncRemindersFromHome` si fingerprint dashboard+prefs inchangé ; ne re-télécharger la voix personnalisée que si meta (`id` / url) a changé ou fichier local absent.
- Confirm / snooze annule **préavis restant + alarme H0 + notif H+5** pour le **slot** ; snooze replanifie H0' = now+snooze prefs pour **toutes** les prises du créneau

### Garde-fous (l’OS ne doit pas étouffer l’alarme)

Objectif produit : l’alarme sonne **écran éteint, app tuée, Doze, batterie faible** (pas téléphone **éteint / batterie à 0 %** — impossible). Pendant onboarding suivi perso / activation patient (voir `auth-onboarding/SKILL.md`), parcours explicatif puis demandes :

| Permission / réglage | Pourquoi |
|---|---|
| Notifications | Préavis, bandeau H0, marquage |
| Alarmes exactes (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`) | Déclenchement à l’heure prévue |
| Exemption optimisation batterie | OEM / Doze qui tuent les wakeups |
| Full-screen intent / overlay si requis | Afficher l’UI alarme par-dessus l’écran de verrouillage |
| Reboot receivers | Replanifier après redémarrage |

Écran **Santé des alarmes** (`/home/profile/alarm-health`) : checklist notif / exact / batterie / FSI + deep-links réglages, et intents OEM (Xiaomi, Samsung, Tecno…). À proposer depuis Profil / Réglages alarme — ne pas se contenter de `openAppSettings()` générique.

Ne jamais « silence » l’alarme via le seul mode **discret** (voir ci-dessous).

### Réglages alarme **dans l’app** (pas seulement réglages système)

L’utilisateur configure dans Fidel (écran Réglages / Alarmes), au minimum V1 :

- Son de l’alarme (son système Fidel **ou** voix de rappel déjà prévue API — `voix-rappel`)
- Volume / vibration (comportement type horloge : alarme audible même si le média est bas — dans les limites OS)
- Délai de **préavis** Δ (défaut 5 min)
- Snooze (durée, défaut 15 min — cohérent avec le flux actuel)

### Mode discret et copie

- Mode **discret** : pas de nom de maladie / médicament (confidentialité), **heure toujours visible** ; l’alarme **sonne toujours** (discret ≠ silencieux)
- Mode normal : titre = **maladie** (puis liste medocs), corps = détail + heure prévue
- Accueil Aujourd’hui : Matin / Après-midi / Soir → **cartes créneau** (heure + maladie + état N/M) → sous-lignes medocs ; confirm rapide = **créneau entier**
- **Onglet Santé** (`HealthScreen`) : gestion des **constantes** (poids, tension, glycémie, etc.) — grille par type, hero dernière mesure, historique, détail `/home/sante/:typeCode`. Priorités selon `maladieCode` actif (`HealthPriorities`). **Pas** de traitements ni prises sur cet onglet.
- **Onglet Accueil** : action du jour (DoseSlot), KPIs, aperçu constantes → lien « Voir dans Santé », traitements / médicaments
- **Voix personnalisée** : lue au moment de l’**alarme H0** (pas sur le préavis)

## Onboarding et auth (référence)

Suivre exactement le flux décrit dans `auth-onboarding/SKILL.md` — écran par écran, y compris :
- bouton **Continuer avec Google** (`google_sign_in`) → envoi de l'`id_token` à `POST /api/v1/auth/google` → stockage des JWT maison dans `flutter_secure_storage`
- **pas** d’écran « Je suis patient / aidant » — infos communes puis « Tu veux un suivi pour toi ? »
- reprise automatique via `onboarding_step` serveur
- depuis la **home** : activer mon suivi (`/patients/me/activate`) et/ou accompagner quelqu’un (`/aidants/me/sync` + scan QR)
- écran explicatif avant chaque demande de permission système (branche suivi perso uniquement à l’onboarding initial)

En production, `AppConfig.apiBaseUrl` pointe vers `https://educampro.edu.cm`.

## Internationalisation et accessibilité

- `flutter_localizations` + `intl`, langue choisie dès le tout premier écran (avant même l'email, cf. `auth-onboarding/SKILL.md`)
- Respecter les tailles de police système (pas de tailles fixes qui ignorent les réglages d'accessibilité du téléphone)
- Contrastes suffisants (WCAG AA minimum) même pour les thèmes personnalisés

## Thème (Material 3)

- **Défaut** : `ThemeMode.system` (suit Android / iOS) via `ThemeController` (`fa_theme_mode` dans SharedPreferences)
- **Light + dark** : `AppTheme.light` / `AppTheme.dark` — primary brand `#2563EB`, Satoshi, surfaces dark slate (pas noir pur)
- Dans les écrans : préférer `Theme.of(context).colorScheme` / `ThemeTokens.of(context)` — **ne pas** hardcoder `AppColors.surface` / `textPrimary` light-only
- Header auth bleu + `head.png` : chrome brand volontaire (OK en clair et sombre)
- Override clair/sombre prévu pour un futur écran Réglages (`ThemeController.setThemeMode`)

## Onboarding UI

- Feature `features/onboarding/` — reprise via `onboarding_step` serveur
- Shell aligné sur l’auth (`head.png` + feuille) + progression 4 étapes + player **LottieFiles** (`dotlottie_flutter`) avec JSON officiels (`assets/lottie/`) et fallback icône
- Pas d’écran « patient / aidant » : infos → besoin suivi → (traitement + permissions si oui) → complete

## Tests

- Tests unitaires sur les providers/state (Riverpod se prête bien aux tests sans UI)
- Tests de widget sur les écrans critiques (confirmation de prise, onboarding)
- Test manuel obligatoire sur un appareil Android réel avec optimisation batterie activée avant toute mise en production d'une fonctionnalité touchant aux rappels — un simulateur ne reproduit pas fidèlement le comportement de Doze mode
- Vérifier manuellement la **chaîne complète** : préavis → alarme H0 (son + UI Fidel, pas seulement bandeau) → notif marquage H+5 ; et après reboot / app tuée

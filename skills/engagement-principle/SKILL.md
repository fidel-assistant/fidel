---
name: engagement-principle
description: Spécification technique du moteur de notification centralisé qui implémente la règle produit absolue "Observer → Encourager/Informer → Proposer → Attendre le consentement" (Volet 7 des specs fonctionnelles). C'est la pièce qui relie data-model (PreferenceConsentement, NotificationLog), api-contract (/notifications/{id}/reponse) et backend-fastapi (notification_service.py). À consulter par tout agent IA avant de coder une fonctionnalité qui envoie une alerte, un rappel, ou une proposition à un utilisateur — quel que soit le volet concerné (médicament, constantes, check-in, SOS, éducation).
---

# Moteur de notification centralisé

## Pourquoi ce fichier existe

La règle produit absolue du projet est simple à énoncer mais facile à violer par petits bouts de code dispersés :

```
OBSERVER → ENCOURAGER / INFORMER → PROPOSER → ATTENDRE LE CONSENTEMENT EXPLICITE
```

Si chaque module (médicament, constantes, SOS...) implémente sa propre logique de notification, le ton et le comportement divergent avec le temps, et le risque qu'un agent code un envoi automatique "juste pour cette fois" devient réel. **Ce moteur est donc un point de passage obligé unique** : aucun module ne doit appeler directement un service d'envoi d'email/SMS/push, tout passe par lui.

## Architecture

Un seul service, `services/notification_service.py` (cf. `backend-fastapi/SKILL.md`), exposant une interface stable que tous les modules métier appellent :

```
NotificationEngine.trigger(
    type_alerte: str,       # clé stable, ex: "rappel_medicament", "contact_medecin_tension"
    user_id: UUID,          # destinataire principal (le patient, en général)
    contexte: dict,         # données nécessaires au template (ex: nom du médicament, heure)
    tiers_potentiel: UUID | None = None,  # destinataire d'une éventuelle action proposée (médecin, aidant...)
)
```

Aucun autre point d'entrée pour envoyer une notification produit. Un job planifié (rappel à heure fixe) et une route API (ex: saisie d'une constante) appellent tous les deux `trigger()`, jamais un envoi direct.

## Cycle de vie d'une notification

```
1. DÉTECTION
   → un module métier détecte un événement ou une absence de donnée
   → appelle NotificationEngine.trigger(type_alerte, user_id, contexte)

2. CLASSIFICATION
   → le moteur détermine le ton : positive / neutre / à surveiller / préoccupante
   → basé sur des règles fournies par le module appelant (le moteur ne réinvente pas la logique métier de chaque volet, il orchestre)

3. RÉSOLUTION DU TEMPLATE
   → le moteur va chercher le template de message correspondant à (type_alerte, ton, langue de l'utilisateur)
   → génère le message final avec le contexte

4. VÉRIFICATION DE LA PRÉFÉRENCE DE CONSENTEMENT
   → lookup PreferenceConsentement(user_id, type_alerte)
   → si absente : comportement par défaut = TOUJOURS demander (jamais d'action auto par défaut)
   → si toujours_demander = true : le message est envoyé avec une simple info OU une proposition à réponse (oui/non/reporter)
   → si regle_auto est définie ET que sa condition est remplie (ex: absence de check-in depuis 48h) : le moteur peut déclencher l'action envers le tiers directement — c'est la SEULE voie qui contourne l'attente de réponse, et elle n'existe que parce que l'utilisateur l'a explicitement configurée en amont

5. ENVOI
   → notification push / SMS (fallback Volet 4) au destinataire principal
   → si une action tiers a été déclenchée automatiquement (étape 4, cas regle_auto), notification également envoyée au tiers

6. JOURNALISATION (obligatoire, sans exception)
   → écriture dans NotificationLog : destinataire_id, type, contenu, declencheur, envoye_at
   → si une proposition a été faite, elle reste "en attente de réponse" jusqu'à ce que l'utilisateur réponde (ou timeout, voir plus bas)

7. RÉPONSE DE L'UTILISATEUR (si une proposition a été faite)
   → via la route api-contract POST /notifications/{id}/reponse (oui / non / reporter)
   → "oui" → le moteur déclenche l'action vers le tiers (notification, partage de résumé, etc.) et journalise
   → "non" → le moteur journalise le refus, ne relance pas immédiatement, peut reproposer plus tard si la situation évolue (ex : dégradation qui continue)
   → "reporter" → le moteur reprogramme une relance à un délai défini par le module appelant
   → pas de réponse après un délai propre à chaque type_alerte → comportement défini par le module appelant (ex : simple relance douce pour un rappel médicament ; pour une alerte de check-in avec regle_auto pré-configurée, c'est la regle_auto elle-même qui gère le timeout, pas une action générique du moteur)
```

## Registre des types d'alerte (V1)

Chaque `type_alerte` est déclaré une seule fois, avec son comportement par défaut. Un agent qui ajoute une nouvelle alerte doit l'ajouter ici avant de coder.

| type_alerte | Déclencheur | Ton par défaut | Proposition faite | Tiers potentiel |
|---|---|---|---|---|
| `rappel_medicament` | Échéance d'une `Prise` | neutre → insistant selon palier (Volet 1) | Confirmation de prise, puis proposition de prévenir un contact après 2h sans réponse | Aidant / contact d'urgence |
| `stock_medicament_bas` | `stock_restant` ≤ `seuil_alerte_stock` | informatif | Proposer de trouver une pharmacie (lien Volet 4) | — |
| `constante_amelioration` | Analyse tendance positive (Volet 2) | positif | Aucune (juste encouragement), option de partager quand même | Médecin / agent de santé (optionnel) |
| `constante_degradation` | Analyse tendance négative (Volet 2) | à surveiller / préoccupant | Proposer de partager un résumé avec le professionnel choisi | Médecin / agent de santé |
| `checkin_absence` | Pas de check-in après délai configuré | neutre puis préoccupant | Selon `regle_auto` du patient — peut déclencher automatiquement si pré-configuré | Cercle de soutien |
| `sos_declenche` | Bouton SOS activé (confirm post-30s) | urgent ; alarme + push FCM chez **aidants liés** | Aucune (le geste SOS *est* le consentement) | Aidants liés (`PatientAidant`) ; fallback local = appel `ACTION_CALL` 1er contact d’urgence si offline / 0 token / pas d’ack sous 45 s |
| `prise_confirmee_aidant` | `Prise` passée à `confirmee` côté serveur (confirm API / sync-offline / sync push) | positif / informatif | Aucune — FCM direct aux aidants **si** `regle_auto` opt-in (`toujours_demander=false`) | Aidants liés avec `niveau_permission.observance=true` |
| `prise_non_confirmee_aidant` | Job cron `scan-prises-non-confirmees` : prise encore `en_attente` après `heure_prevue + delai_heures` (`regle_auto.delai_heures`, défaut 2) — **notif seulement**, ne passe pas en `manquee` | neutre, jamais alarmiste | Aucune — FCM direct aux aidants **si** opt-in ; message « pas de confirmation reçue, tu peux vérifier auprès de {prenom} » | Aidants liés avec `observance=true` |
| `education_contextuelle` | Ajout d'un traitement correspondant à une fiche existante | informatif | Aucune, contenu informatif poussé une seule fois | — |
| `depistage_recommande` | Échéance calendaire de prévention (Volet 6) | informatif | Proposer d'orienter vers un centre proche | — |

> **Patient — alarme & notifs locales** : le préavis (H0−Δ), l’alarme applicative H0 et la notif de marquage H+5 sont **planifiés et joués sur le téléphone** (`mobile-flutter/SKILL.md`). Ce n’est **pas** un envoi via `NotificationEngine` / FCM. Le moteur ci-dessus sert aux alertes **serveur** (aidant, consentement, SOS, etc.). Ne pas router l’alarme patient par le backend.

> **Cas particulier `sos_declenche`** : consentement = geste SOS. Fenêtre d’annulation 30 s (`POST /sos/{id}/annuler`). Après `POST /patients/me/sos/{id}/confirm`, le moteur journalise + pousse FCM aux aidants liés. Côté patient : si offline ou `fallback_call_recommended` / timeout ack 45 s → appel système vers le 1er `ContactUrgence` (cache local).

> **Observance aidant (FCM)** : `prise_confirmee_aidant` et `prise_non_confirmee_aidant` ne partent **jamais** par défaut. Opt-in patient via `PreferenceConsentement` (`toujours_demander=false` + `regle_auto`). Dédup 1 notif / `prise_id` via `NotificationLog.declencheur.prise_id`. Envoi via `aidant_push_service` (journal + FCM), pas d’appel FCM brut depuis un router. Job absence : `POST /internal/jobs/scan-prises-non-confirmees` (header `X-Cron-Secret`) — pas de Celery ; le serveur ne ping pas l’app.

> **Mute aidant (recipient)** : après l’opt-in patient et le filtre `observance=true`, exclure tout aidant dont `PatientAidant.notification_prefs` mute le type (`mute_prise_confirmee` / `mute_prise_non_confirmee`). Pour SOS (`sos_declenche`), exclure `mute_sos` au moment de `_finalize_sos`. Le mute est **par relation** (aidant × patient), pas un `PreferenceConsentement` global.

> **Marquage `manquee` (métier, pas alerte tiers)** : job distinct `POST /internal/jobs/mark-prises-manquees` — `en_attente` → `manquee` après `heure_prevue + PRISE_MANQUEE_GRACE_HOURS` (défaut 12 h, typiquement **après** le délai aidant). Aucun FCM / `NotificationEngine` à la bascule. Timeline attendue : H0 → (opt-in) notif aidant à H0+`delai_heures` → `manquee` à H0+12 h → confirmation tardive possible.

## Templates de messages

- Centralisés (pas de chaîne de caractères codée en dur dans un module métier), organisés par `(type_alerte, ton, langue)`.
- Contexte injecté via des variables nommées (ex: `{prenom}`, `{medicament}`, `{heure}`) — jamais de concaténation manuelle de chaînes dans le code métier.
- Un template doit toujours pouvoir être ajusté (formulation, ton) sans toucher à la logique de déclenchement — les deux sont découplés par design.
- Exemples de formulation à respecter (cohérents avec les specs fonctionnelles) :
  - Positif : *"On remarque que ton poids a augmenté de {valeur}, c'est bon signe. Continue comme ça !"*
  - À surveiller, jamais alarmiste par défaut : *"On observe {changement} depuis {periode}. Ce n'est pas forcément grave, mais veux-tu qu'on en parle à {destinataire} ?"*

## Ce qu'un agent IA ne doit jamais faire

1. Appeler un service d'envoi (email, SMS, push) directement depuis un router ou un module métier — toujours passer par `NotificationEngine.trigger()`.
2. Coder une action vers un tiers sans vérifier `PreferenceConsentement` au préalable, même "temporairement" ou "pour tester".
3. Omettre l'écriture dans `NotificationLog` — une notification non journalisée est considérée comme un bug, pas un détail.
4. Ajouter un nouveau `type_alerte` sans l'ajouter d'abord à ce fichier.
5. Donner à `regle_auto` un comportement par défaut activé — elle doit toujours être **opt-in**, configurée explicitement par l'utilisateur, jamais pré-cochée.

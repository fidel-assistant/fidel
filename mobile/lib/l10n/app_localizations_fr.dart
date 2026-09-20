// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Fidel';

  @override
  String get languageTitle => 'Choisis ta langue';

  @override
  String get languageSubtitle =>
      'Tu pourras la changer plus tard dans les réglages.';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageContinue => 'Continuer';

  @override
  String get loginTitle => 'Connecte-toi à ton compte';

  @override
  String get loginSubtitle =>
      'Entre ton email et ton mot de passe pour te connecter';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get orLoginWith => 'Ou connecte-toi avec';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'nom@email.com';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordHint => '••••••••';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get logIn => 'Se connecter';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get haveAccount => 'Tu as déjà un compte ?';

  @override
  String get loginFailed => 'Connexion impossible. Vérifie tes identifiants.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire';

  @override
  String get invalidEmail => 'Entre un email valide';

  @override
  String passwordTooShort(int min) {
    return 'Au moins $min caractères';
  }

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get registerTitle => 'Crée ton compte';

  @override
  String get registerSubtitle => 'Entre ton email pour commencer';

  @override
  String get registerContinue => 'Continuer';

  @override
  String get otpTitle => 'Vérifie ton email';

  @override
  String otpSubtitle(String email) {
    return 'On t\'a envoyé un code à 6 chiffres à $email';
  }

  @override
  String get otpLabel => 'Code de vérification';

  @override
  String get otpHint => '123456';

  @override
  String get otpInvalid => 'Entre le code à 6 chiffres';

  @override
  String get otpVerify => 'Vérifier';

  @override
  String get otpResend => 'Renvoyer le code';

  @override
  String get otpResent => 'Un nouveau code a été envoyé';

  @override
  String get passwordTitle => 'Choisis un mot de passe';

  @override
  String get passwordSubtitle => 'Au moins 8 caractères';

  @override
  String get passwordContinue => 'Continuer';

  @override
  String get legalTitle => 'Dernière étape';

  @override
  String get legalSubtitle => 'Accepte pour finaliser ton inscription';

  @override
  String legalCgu(String version) {
    return 'J\'accepte les Conditions d\'utilisation (version $version)';
  }

  @override
  String get legalConsent =>
      'Je consens au traitement de mes données de santé pour l\'accompagnement (pas de diagnostic médical)';

  @override
  String get legalRequired => 'Accepte les deux cases pour continuer';

  @override
  String get legalFinish => 'Créer mon compte';

  @override
  String get emailAlreadyVerified =>
      'Cet email est déjà inscrit. Essaie de te connecter.';

  @override
  String get genericError => 'Une erreur est survenue. Réessaie.';

  @override
  String get successEmailTitle => 'Email vérifié !';

  @override
  String get successEmailSubtitle =>
      'Ton email est confirmé. Choisis maintenant un mot de passe sécurisé.';

  @override
  String get successEmailCta => 'Continuer';

  @override
  String get successAccountTitle => 'C\'est réussi !';

  @override
  String get successAccountSubtitle =>
      'Ton compte est créé et prêt. Bienvenue sur Fidel.';

  @override
  String get successAccountCta => 'Continuer la configuration';

  @override
  String get forgotTitle => 'Mot de passe oublié ?';

  @override
  String get forgotSubtitle =>
      'Entre ton email, on t’envoie un code de réinitialisation';

  @override
  String get forgotContinue => 'Envoyer le code';

  @override
  String get forgotOtpSent => 'Code de réinitialisation envoyé';

  @override
  String get forgotResetTitle => 'Nouveau mot de passe';

  @override
  String get forgotResetSubtitle => 'Choisis un nouveau mot de passe sécurisé';

  @override
  String get forgotResetCta => 'Mettre à jour';

  @override
  String get forgotResetSuccess =>
      'Mot de passe mis à jour. Tu peux te connecter.';

  @override
  String get googleFailed => 'Échec de la connexion Google';

  @override
  String get googleCancelled => 'Connexion Google annulée';

  @override
  String get googleNotConfigured =>
      'Google Sign-In n’est pas configuré sur ce build';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String onboardingStepOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboardingStepProfil => 'Toi';

  @override
  String get onboardingStepSuivi => 'Suivi';

  @override
  String get onboardingStepTraitement => 'Soins';

  @override
  String get onboardingStepRappels => 'Rappels';

  @override
  String get onboardingGateLoading => 'On prépare ton espace…';

  @override
  String get onboardingRetry => 'Réessayer';

  @override
  String get onboardingInfosTitle => 'Comment on t’appelle ?';

  @override
  String get onboardingInfosSubtitle =>
      'Quelques infos pour personnaliser Fidel. Rien n’est figé.';

  @override
  String get onboardingNameLabel => 'Nom complet';

  @override
  String get onboardingBirthLabel => 'Date de naissance';

  @override
  String get onboardingBirthHint => 'Choisir une date';

  @override
  String get onboardingBirthRequired => 'Indique ta date de naissance';

  @override
  String get onboardingSexLabel => 'Sexe';

  @override
  String get onboardingSexF => 'Femme';

  @override
  String get onboardingSexM => 'Homme';

  @override
  String get onboardingSexOther => 'Autre';

  @override
  String get onboardingLocationLabel => 'Ville / quartier';

  @override
  String get onboardingLocationHint => 'Ex. Douala, Akwa';

  @override
  String get onboardingPhoneLabel => 'Téléphone';

  @override
  String get onboardingPhoneHint => '+237 6…';

  @override
  String get onboardingPhoneOptional =>
      'Optionnel — tu pourras l’ajouter plus tard';

  @override
  String get onboardingBesoinTitle => 'Tu veux un suivi pour toi ?';

  @override
  String get onboardingBesoinSubtitle =>
      'Tu pourras aussi accompagner un proche depuis l’accueil. Les deux sont possibles, sans second compte.';

  @override
  String get onboardingBesoinYesTitle => 'Oui, un suivi pour moi';

  @override
  String get onboardingBesoinYesSubtitle =>
      'Rappels de médicaments, constantes et accompagnement personnel';

  @override
  String get onboardingBesoinNoTitle => 'Pas pour l’instant';

  @override
  String get onboardingBesoinNoSubtitle =>
      'Je veux surtout accompagner quelqu’un plus tard';

  @override
  String get onboardingChoiceRequired => 'Choisis une option pour continuer';

  @override
  String get onboardingTraitementTitle => 'Es-tu en traitement ?';

  @override
  String get onboardingTraitementSubtitle =>
      'Si oui, coche ce que tu suis. Les médicaments et horaires viennent après, sans pression.';

  @override
  String get onboardingTraitementYes => 'Oui, je suis un traitement';

  @override
  String get onboardingTraitementYesSubtitle =>
      'On note la maladie et la phase, rien d’autre pour l’instant';

  @override
  String get onboardingTraitementNo => 'Non, pas maintenant';

  @override
  String get onboardingTraitementNoSubtitle =>
      'Tu pourras l’ajouter plus tard depuis l’accueil';

  @override
  String get onboardingTraitementNoHint =>
      'Pas de souci — tu pourras activer un suivi plus tard.';

  @override
  String get onboardingMaladiesLabel => 'Qu’est-ce que tu suis ?';

  @override
  String get onboardingMaladieRequired => 'Sélectionne au moins une maladie';

  @override
  String get onboardingMaladiesEmpty =>
      'Impossible de charger le catalogue. Vérifie ta connexion.';

  @override
  String get onboardingPhaseLabel => 'Où en es-tu ?';

  @override
  String get onboardingPhaseDebut => 'Je commence';

  @override
  String get onboardingPhaseEnCours => 'C’est en cours';

  @override
  String get onboardingPhaseMaintenance => 'Maintenance';

  @override
  String get onboardingPhaseInconnu => 'Je ne sais pas trop';

  @override
  String get onboardingPermsTitle => 'Pour que les rappels sonnent vraiment';

  @override
  String get onboardingPermsSubtitle =>
      'On t’explique avant la demande du téléphone. Tu peux aussi continuer sans — à tes risques.';

  @override
  String get onboardingPermsNotifTitle => 'Notifications';

  @override
  String get onboardingPermsNotifBody =>
      'Pour te prévenir avant la prise, et pour confirmer après.';

  @override
  String get onboardingPermsExactTitle => 'Alarmes exactes (Android)';

  @override
  String get onboardingPermsExactBody =>
      'Pour que l’alarme sonne à l’heure prévue, même si le téléphone est en veille.';

  @override
  String get onboardingPermsBatteryTitle => 'Batterie (Android)';

  @override
  String get onboardingPermsBatteryBody =>
      'Sans exemption, certains téléphones coupent les rappels pendant la nuit.';

  @override
  String get onboardingPermsAllow => 'Autoriser les rappels';

  @override
  String get onboardingPermsLater => 'Plus tard';

  @override
  String get onboardingDoneToast => 'C’est bon — bienvenue sur Fidel';

  @override
  String get navHome => 'Accueil';

  @override
  String get navCare => 'Santé';

  @override
  String get healthSubtitle => 'Tes indicateurs — poids, tension, glycémie…';

  @override
  String get healthRecommended => 'Recommandé pour toi';

  @override
  String get healthAllMetrics => 'Tous tes indicateurs';

  @override
  String get healthRecent => 'Mesures récentes';

  @override
  String get healthRecentEmpty =>
      'Aucune mesure pour l’instant. Commence par en ajouter une.';

  @override
  String get healthAddCta => 'Ajouter une mesure';

  @override
  String get healthEmptyHero =>
      'Commence par une mesure. Une fois de temps en temps suffit.';

  @override
  String get healthNoData => 'Pas encore de mesure';

  @override
  String healthDaysAgo(int count) {
    return 'il y a $count j';
  }

  @override
  String get healthViewAll => 'Voir dans Santé';

  @override
  String get healthRecommendedBadge => 'Recommandé';

  @override
  String get healthLatestMeasure => 'Dernière mesure';

  @override
  String get healthHistory => 'Historique';

  @override
  String healthNoDataForType(String type) {
    return 'Aucune mesure de $type pour l’instant.';
  }

  @override
  String get navPeople => 'Cercle';

  @override
  String get navYou => 'Profil';

  @override
  String homeHelloMorning(String name) {
    return 'Bonjour $name';
  }

  @override
  String homeHelloAfternoon(String name) {
    return 'Bon après-midi $name';
  }

  @override
  String homeHelloEvening(String name) {
    return 'Bonsoir $name';
  }

  @override
  String get homeHelloMorningAnon => 'Bonjour !';

  @override
  String get homeHelloAfternoonAnon => 'Bon après-midi !';

  @override
  String get homeHelloEveningAnon => 'Bonsoir !';

  @override
  String get homeTagline => 'Fidel veille sur tes prises — sans te juger.';

  @override
  String get homeNotifA11y => 'Rappels';

  @override
  String get homeSettingsA11y => 'Réglages';

  @override
  String get homeMoreA11y => 'Plus d’options';

  @override
  String get homeNotifTitle => 'Rappels';

  @override
  String get homeNotifBody =>
      'Les rappels sonnent sur ce téléphone, même hors ligne. Rien n’est envoyé à un proche sans ton accord.';

  @override
  String get homeNotifReadyTitle => 'Les rappels sont prêts';

  @override
  String get homeNotifReadyBody =>
      'Fidel te préviendra ici, sur l’appareil — pas de score, pas de jugement.';

  @override
  String get homeTodayTitle => 'Aujourd’hui';

  @override
  String get homeNextDoseLabel => 'Prochaine prise';

  @override
  String homeSlotMedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médicaments',
      one: '1 médicament',
    );
    return '$_temp0';
  }

  @override
  String get homeAllClearTitle => 'Tu es à jour';

  @override
  String get homeAllClearBody =>
      'Aucune prise en attente pour le moment. Repose-toi.';

  @override
  String get homeStatPending => 'À prendre';

  @override
  String get homeStatTaken => 'Prises';

  @override
  String get homeStatLate => 'En retard';

  @override
  String get homeMissedCanStillConfirm => 'Manquée — tu peux encore confirmer';

  @override
  String get homeNoDoses =>
      'Pas encore d’horaire aujourd’hui. Ajoute un médicament pour commencer.';

  @override
  String get homeTakeCta => 'J’ai pris';

  @override
  String get homeTakenBadge => 'Pris';

  @override
  String get homeTakenToast => 'Noté — bravo.';

  @override
  String get homeActivateTitle => 'Activer mon suivi';

  @override
  String get homeActivateBody =>
      'Rappels, traitements et prises pour toi, sur ce compte.';

  @override
  String get homeAccompanyTitle => 'Accompagner quelqu’un';

  @override
  String get homeAccompanyBody =>
      'Entre le code d’un proche pour le suivre, avec son accord.';

  @override
  String get homeAccompaniedSection => 'Personnes que j’accompagne';

  @override
  String get homeActiveSosSection => 'SOS en cours';

  @override
  String get aidantSignalSos => 'SOS actif';

  @override
  String get aidantSignalMissed => 'Prise manquée aujourd’hui';

  @override
  String get aidantSignalPending => 'Prise en attente';

  @override
  String get aidantSignalOk => 'Prises confirmées';

  @override
  String get aidantSignalNothing => 'Rien de prévu aujourd’hui';

  @override
  String get aidantVoixSection => 'Voix de rappel';

  @override
  String get aidantVoixBody =>
      'Enregistre une voix pour les rappels de cette personne.';

  @override
  String get aidantVoixCta => 'Ajouter une voix';

  @override
  String get aidantVoixUploaded => 'Voix envoyée';

  @override
  String get aidantNotifSection => 'Notifications';

  @override
  String get aidantMutePriseConfirmee => 'Couper les prises confirmées';

  @override
  String get aidantMutePriseNonConfirmee => 'Couper les prises non confirmées';

  @override
  String get aidantMuteSos => 'Couper les SOS';

  @override
  String get aidantMuteSosHint =>
      'Tu ne seras plus alerté si cette personne déclenche un SOS.';

  @override
  String get healthAidantOnlyTitle => 'La santé, c’est ton suivi';

  @override
  String get healthAidantOnlyBody =>
      'Les mesures ici concernent ton propre suivi. Tu peux l’activer quand tu veux. Les personnes que tu accompagnes restent sur l’Accueil.';

  @override
  String get homeShareCodeTitle => 'Inviter un aidant';

  @override
  String get homeShareCodeBody =>
      'Ce code expire vite. Partage-le seulement à la personne que tu choisis.';

  @override
  String get homeAidantsTitle => 'Tes aidants';

  @override
  String get homeAidantsIntro =>
      'Tu peux inviter quelqu’un à t’accompagner sur Fidel — toujours avec ton accord.';

  @override
  String get homeAidantsSection => 'Statut des aidants';

  @override
  String get homeAidantsSectionHint =>
      'Appuie sur un aidant pour gérer l’accès ou le retirer.';

  @override
  String get homeAidantsEmpty => 'Aucun aidant pour l’instant.';

  @override
  String get homeAidantsEmptyTitle => 'Pas encore d’aidant';

  @override
  String get homeAidantsEmptyBody =>
      'Invite quelqu’un de confiance pour t’accompagner sur tes prises — tu gardes le contrôle de ce qu’il voit.';

  @override
  String get homeAidantsInviteCta => 'Inviter un aidant';

  @override
  String get homeAidantsTrust =>
      'L’accès est limité à ce que tu autorises. Tu peux révoquer à tout moment —';

  @override
  String get homeAidantsTrustHighlight => 'toujours avec ton consentement.';

  @override
  String get homeAidantsManageTitle => 'Gérer l’accès';

  @override
  String get homeAidantsPermObservance => 'Voir les prises';

  @override
  String get homeAidantsPermConstantes => 'Voir les constantes';

  @override
  String get homeAidantsRevoke => 'Retirer l’accès';

  @override
  String get homeAidantsRevoked => 'L’aidant n’a plus accès à ton suivi.';

  @override
  String get homeAidantsPermObservanceOnly => 'Observance';

  @override
  String get homeAidantsPermBoth => 'Observance et constantes';

  @override
  String get homeAidantsPermNone => 'Accès limité';

  @override
  String get homeInviteCopy => 'Copier le code';

  @override
  String get homeInviteCopied => 'Code copié';

  @override
  String get homeInviteAltLink => 'Tu as un code ? Accompagner quelqu’un';

  @override
  String get homeInviteHint =>
      'Partage ce code avec la personne que tu invites. Elle l’entre dans Fidel pour se connecter à ton suivi.';

  @override
  String get homeActionNotifTitle => 'Autoriser les rappels';

  @override
  String get homeActionNotifBody =>
      'Sans ça, le téléphone peut couper les alarmes la nuit.';

  @override
  String get homeActionMedsTitle => 'Configurer tes médicaments';

  @override
  String get homeActionMedsBody =>
      'Nom, dose et heures — c’est ce qui fait sonner les rappels.';

  @override
  String homeActionMedsFor(String maladie) {
    return 'Pour $maladie';
  }

  @override
  String get homeActionTraitementTitle => 'Ajouter un traitement';

  @override
  String get homeActionTraitementBody =>
      'On note d’abord la maladie, les médicaments viennent juste après.';

  @override
  String get homeSoftChecklistTitle => 'Pour aller plus loin';

  @override
  String get homeSoftPhoneTitle => 'Ajouter ton téléphone';

  @override
  String get homeSoftPhoneBody => 'Utile pour le SOS et te joindre si besoin.';

  @override
  String get homeSoftContactTitle => 'Ajouter un contact d’urgence';

  @override
  String get homeSoftContactBody =>
      'Une personne de confiance pour les moments critiques.';

  @override
  String get homeSoftVoixTitle => 'Personnaliser la voix de rappel';

  @override
  String get homeSoftVoixBody => 'Un message à ta voix pour les alarmes.';

  @override
  String get homeSoftPhotoTitle => 'Ajouter une photo';

  @override
  String get homeSoftPhotoBody =>
      'Pour que ton cercle te reconnaisse facilement.';

  @override
  String get homeSoftDismissA11y => 'Masquer cette suggestion';

  @override
  String get homeCareSubtitle =>
      'Mesures, prises et journal — le détail de ton suivi.';

  @override
  String get homeNetworkSubtitle =>
      'Qui t’aide, qui tu accompagnes, et le SOS — au même endroit.';

  @override
  String get homeCareMedsReady => 'Médicaments enregistrés';

  @override
  String get homeCareTreatments => 'Tes traitements';

  @override
  String get homeCareWeek => 'Observance de la semaine';

  @override
  String get homeCareAddMed => 'Ajouter un médicament';

  @override
  String get homeCareConfigureMeds => 'Configurer les médicaments';

  @override
  String get homeCareManageStock => 'Gérer le stock';

  @override
  String get homeCareEmptyPatientTitle => 'Active ton suivi';

  @override
  String get homeCareActionTraitement => 'Traitement';

  @override
  String get homeCareActionMeds => 'Médicament';

  @override
  String get homeCareActionMedsSetup => 'Configurer';

  @override
  String get homeCareActionVital => 'Mesure';

  @override
  String get homeCareJournal => 'Journal du suivi';

  @override
  String get homeCareJournalEmpty =>
      'Rien à afficher pour l’instant. Confirme une prise ou ajoute une mesure.';

  @override
  String get homeCareProgressPrises => 'Prises';

  @override
  String get homeCareProgressLate => 'Retards';

  @override
  String get homeCareProgressCheckIn => 'Check-in';

  @override
  String get homeCareProgressCheckInTodo => 'À faire';

  @override
  String get homeCareProgressCheckInOk => 'Ça va';

  @override
  String get homeCareProgressCheckInBad => 'Pas top';

  @override
  String get homeCareHeroDosesLabel => 'Prises du jour';

  @override
  String homeCareHeroDosesValue(int taken, int total) {
    return '$taken / $total';
  }

  @override
  String get homeCareHeroNoVital =>
      'Ajoute une mesure pour voir ta courbe ici.';

  @override
  String get homeCareFeedPriseTaken => 'Confirmée';

  @override
  String get homeCareFeedPriseMissed => 'Manquée';

  @override
  String get homeCareFeedPrisePending => 'En attente';

  @override
  String homeCareOfValue(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get homeThemeLabel => 'Apparence';

  @override
  String get homeThemeLight => 'Clair';

  @override
  String get homeThemeDark => 'Sombre';

  @override
  String get homeThemeSystem => 'Système';

  @override
  String get homeSyncHint =>
      'Le code à 6 chiffres que la personne a généré dans Fidel.';

  @override
  String get homeSyncCodeLabel => 'Code';

  @override
  String get homeSyncCta => 'Me connecter à son suivi';

  @override
  String get homeSyncOk => 'Tu es maintenant connecté(e) à son suivi.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get homeSnoozeCta => 'Plus tard';

  @override
  String get homeSnoozeTitle => 'Reporter la prise';

  @override
  String get homeSnoozeBody => 'On décale le rappel, rien n’est effacé.';

  @override
  String homeSnoozeDone(String heure) {
    return 'Reporté à $heure';
  }

  @override
  String homeCountdownIn(String value) {
    return 'dans $value';
  }

  @override
  String homeCountdownLate(String value) {
    return 'en retard de $value';
  }

  @override
  String get homeCountdownNow => 'maintenant';

  @override
  String homeDurationHm(String h, String m) {
    return '$h h $m';
  }

  @override
  String homeDurationH(int h) {
    return '$h h';
  }

  @override
  String homeDurationM(int m) {
    return '$m min';
  }

  @override
  String get homeDayProgressLabel => 'Prises du jour';

  @override
  String get homeDayProgressTitle => 'Progression du jour';

  @override
  String get homeDayProgressHint =>
      'Nombre de prises confirmées sur celles prévues aujourd’hui. Ce n’est pas un score de santé.';

  @override
  String get homeDayProgressDone => 'Terminé';

  @override
  String get homeDayProgressOngoing => 'En cours';

  @override
  String get homeDayProgressUpcoming => 'À venir';

  @override
  String get homeDayProgressLate => 'Des prises attendent';

  @override
  String homeDayProgressPendingCount(int count) {
    return '$count à venir';
  }

  @override
  String homeDayProgressLateCount(int count) {
    return '$count en retard';
  }

  @override
  String get homeTodaySummaryTitle => 'Résumé du jour';

  @override
  String get homeTodaySummaryViewAll => 'Tout voir';

  @override
  String get homeTodaySummaryBody => 'Tes dernières mesures enregistrées.';

  @override
  String get homeTodaySummaryEmpty =>
      'Aucune mesure pour l’instant. Ajoute-en une quand tu veux.';

  @override
  String get homeDayDoneTitle => 'Journée bouclée';

  @override
  String get homeDayDoneBody =>
      'Toutes tes prises sont confirmées. Beau travail.';

  @override
  String get homeWeekTitle => 'Ta semaine';

  @override
  String homeWeekSummary(int confirmed, int total) {
    return '$confirmed prises confirmées sur $total';
  }

  @override
  String get homeWeekEmpty => 'Tes prises de la semaine s’afficheront ici.';

  @override
  String homeWeekPerfect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours complets',
      one: '$count jour complet',
    );
    return '$_temp0';
  }

  @override
  String homeRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count restantes',
      one: '$count restante',
    );
    return '$_temp0';
  }

  @override
  String get homeCheckInTitle => 'Comment tu te sens aujourd’hui ?';

  @override
  String get homeCheckInBody => 'Un geste par jour, pour garder une trace.';

  @override
  String get homeCheckInOk => 'Ça va';

  @override
  String get homeCheckInBad => 'Pas top';

  @override
  String get homeCheckInDoneOk => 'Aujourd’hui : ça va';

  @override
  String get homeCheckInDoneBad => 'Aujourd’hui : pas top';

  @override
  String get homeCheckInThanks => 'Merci, c’est noté.';

  @override
  String get homeCheckInLevelTresMal => 'Très mal';

  @override
  String get homeCheckInLevelPasTop => 'Pas top';

  @override
  String get homeCheckInLevelCaVa => 'Ça va';

  @override
  String get homeCheckInLevelSuper => 'Super';

  @override
  String get homeCheckInDoneTresMal => 'Aujourd’hui : très mal';

  @override
  String get homeCheckInDonePasTop => 'Aujourd’hui : pas top';

  @override
  String get homeCheckInDoneCaVa => 'Aujourd’hui : ça va';

  @override
  String get homeCheckInDoneSuper => 'Aujourd’hui : super';

  @override
  String get homeCheckInReminderTitle => 'Comment tu te sens aujourd’hui ?';

  @override
  String get homeCheckInReminderBody =>
      'Un geste, quatre choix — ça aide à suivre ton suivi.';

  @override
  String get homeCheckInActionTresMal => 'Très mal';

  @override
  String get homeCheckInActionPasTop => 'Pas top';

  @override
  String get homeCheckInActionCaVa => 'Ça va';

  @override
  String get homeCheckInActionSuper => 'Super';

  @override
  String homeTreatmentDay(int day) {
    return 'Jour $day';
  }

  @override
  String homeTreatmentDayOf(int day, int total) {
    return 'Jour $day sur $total';
  }

  @override
  String get homeTreatmentDayUnit => 'jour';

  @override
  String get homeTreatmentOngoing => 'Traitement en cours';

  @override
  String get homeTreatmentEndAction => 'Marquer terminé';

  @override
  String get homeTreatmentEndTitle => 'Terminer ce traitement ?';

  @override
  String get homeTreatmentEndBody =>
      'Les rappels médicaments pour cette maladie s’arrêtent. Tu pourras toujours en ajouter un nouveau plus tard.';

  @override
  String get homeTreatmentEndConfirm => 'Oui, terminer';

  @override
  String get homeTreatmentEndedToast => 'Traitement terminé — rappels arrêtés.';

  @override
  String get configDateFinLabel => 'Date de fin prévue (optionnel)';

  @override
  String get configDateFinHint =>
      'Si tu la connais, on arrêtera automatiquement les rappels après cette date.';

  @override
  String get configDateFinClear => 'Pas de date de fin';

  @override
  String get homePhaseDebut => 'Début';

  @override
  String get homePhaseEnCours => 'En cours';

  @override
  String get homePhaseMaintenance => 'Entretien';

  @override
  String get homeMomentMorning => 'Matin';

  @override
  String get homeMomentAfternoon => 'Après-midi';

  @override
  String get homeMomentEvening => 'Soir';

  @override
  String get homeVitalsTitle => 'Ton suivi';

  @override
  String get homeVitalsAdd => 'Ajouter';

  @override
  String get homeVitalsFirst =>
      'Première mesure enregistrée. La courbe apparaîtra dès la suivante.';

  @override
  String get homeVitalsSystolic => 'Systolique';

  @override
  String get homeVitalsDiastolic => 'Diastolique';

  @override
  String get homeVitalsSaved => 'Mesure enregistrée.';

  @override
  String get homeVitalsEmptyTitle => 'Suivre une constante';

  @override
  String get homeVitalsEmptyBody =>
      'Poids, tension, glycémie… une mesure de temps en temps suffit.';

  @override
  String get constantePoids => 'Poids';

  @override
  String get constanteTension => 'Tension';

  @override
  String get constanteGlycemie => 'Glycémie';

  @override
  String get constanteTemperature => 'Température';

  @override
  String get constanteSommeil => 'Sommeil';

  @override
  String get constanteHumeur => 'Humeur';

  @override
  String get addVitalTitle => 'Nouvelle mesure';

  @override
  String get addVitalValue => 'Valeur';

  @override
  String get addVitalSystolic => 'Systolique';

  @override
  String get addVitalDiastolic => 'Diastolique';

  @override
  String get addVitalDate => 'Mesurée le';

  @override
  String get addVitalSave => 'Enregistrer';

  @override
  String get addVitalInvalid => 'Entre une valeur chiffrée valide.';

  @override
  String get medsWizardTitle => 'Tes médicaments';

  @override
  String get medsWizardSubtitle =>
      'Une ligne suffit pour commencer. Tu pourras en ajouter d’autres plus tard.';

  @override
  String get medsSuggestions => 'Suggestions';

  @override
  String get medsNameLabel => 'Nom du médicament';

  @override
  String get medsDoseLabel => 'Dosage';

  @override
  String get medsDoseHint => 'Ex. 500 mg';

  @override
  String get medsTimesLabel => 'Heures de prise';

  @override
  String get medsAddTime => 'Ajouter une heure';

  @override
  String get medsNeedTime => 'Ajoute au moins une heure';

  @override
  String get medsNeedDays => 'Choisis au moins un jour';

  @override
  String get medsSaveCta => 'Enregistrer';

  @override
  String get medsSaved =>
      'Médicament enregistré. Les prises du jour sont prêtes.';

  @override
  String get medsAddAnother => 'Ajouter un autre médicament';

  @override
  String get medsSaveAndAddAnother => 'Enregistrer et ajouter un autre';

  @override
  String get medsFinishCta => 'Terminer et rentrer';

  @override
  String medsConfiguredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médicaments déjà sur ce suivi',
      one: '$count médicament déjà sur ce suivi',
    );
    return '$_temp0';
  }

  @override
  String get medsMultiHint =>
      'Tu peux en ajouter autant que nécessaire pour ce traitement, un par un.';

  @override
  String get configStepMaladie => 'Maladie';

  @override
  String get configStepContexte => 'Contexte';

  @override
  String get configStepIdentite => 'Identité';

  @override
  String get configStepHoraires => 'Horaires';

  @override
  String get configStepRecap => 'Récap';

  @override
  String get configTraitementTitle => 'Quel traitement suis-tu ?';

  @override
  String get configTraitementSubtitle =>
      'Choisis la maladie suivie. Les médicaments viennent juste après.';

  @override
  String get configPhaseTitle => 'Où en es-tu ?';

  @override
  String get configPhaseSubtitle =>
      'La phase et la date de début aident Fidel à contextualiser ton suivi.';

  @override
  String get configTraitementCreate => 'Configurer les médicaments';

  @override
  String get configDateDebutLabel => 'Date de début';

  @override
  String get configDateDebutHint =>
      'Si tu n’es pas sûr, laisse la date d’aujourd’hui.';

  @override
  String get medsStepIdentiteTitle => 'Ton médicament';

  @override
  String get medsStepIdentiteSubtitle =>
      'Une suggestion du protocole, ou saisie libre — tu restes maître.';

  @override
  String get medsStepHorairesTitle => 'Quand le prendre ?';

  @override
  String get medsStepHorairesSubtitle =>
      'Les heures et les jours déclenchent tes rappels.';

  @override
  String get medsStepRecapTitle => 'Tout est bon ?';

  @override
  String get medsStepRecapSubtitle =>
      'Enregistre puis ajoute le suivant, ou termine si c’est le dernier.';

  @override
  String get medsFormeLabel => 'Forme';

  @override
  String get medsFormeComprime => 'Comprimé';

  @override
  String get medsFormeSirop => 'Sirop';

  @override
  String get medsFormeInjection => 'Injection';

  @override
  String get medsFormeAutre => 'Autre';

  @override
  String get medsDaysLabel => 'Jours';

  @override
  String get medsDaysEvery => 'Tous les jours';

  @override
  String get medsDaysCustom => 'Certains jours';

  @override
  String get medsDayMon => 'L';

  @override
  String get medsDayTue => 'M';

  @override
  String get medsDayWed => 'Me';

  @override
  String get medsDayThu => 'J';

  @override
  String get medsDayFri => 'V';

  @override
  String get medsDaySat => 'S';

  @override
  String get medsDaySun => 'D';

  @override
  String get medsRepasLabel => 'Par rapport aux repas';

  @override
  String get medsRepasNone => 'Pas précisé';

  @override
  String get medsRepasAvant => 'Avant le repas';

  @override
  String get medsRepasApres => 'Après le repas';

  @override
  String get medsRepasIndifferent => 'Indifférent';

  @override
  String get medsRecapTraitementHint => 'Lié à ce traitement';

  @override
  String get medsRecapTrust =>
      'Tu pourras ajuster plus tard. Fidel ne donne pas de conseil médical — seulement des rappels selon ce que tu configures.';

  @override
  String get medsStockSection => 'Stock (optionnel)';

  @override
  String get medsStockHint =>
      'Pour t’alerter avant la rupture. Ajustable plus tard dans Soins.';

  @override
  String get medsStockLabel => 'Unités restantes';

  @override
  String get medsStockSeuilLabel => 'Alerter quand ≤';

  @override
  String get medsStockSeuilHint => 'Défaut 5 si tu indiques un stock';

  @override
  String get medsStockRecap => 'Stock';

  @override
  String get medsStockSheetTitle => 'Stock des médicaments';

  @override
  String get medsStockSheetEmpty =>
      'Aucun médicament configuré pour ce traitement.';

  @override
  String get medsStockSave => 'Enregistrer le stock';

  @override
  String get medsStockSaved => 'Stock mis à jour';

  @override
  String get medsStockAlertTriggered =>
      'Stock bas — une alerte a été enregistrée.';

  @override
  String get medsStockInvalid => 'Indique un nombre entier ≥ 0.';

  @override
  String get profileSubtitle =>
      'Compte, préférences et suivi — tout au même endroit.';

  @override
  String get profileFallbackName => 'Compte Fidel';

  @override
  String get profileChipPatient => 'Suivi actif';

  @override
  String get profileChipAidant => 'Aidant';

  @override
  String get profileChipAccount => 'Compte';

  @override
  String get profileSectionPrefs => 'Préférences';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get profileSectionFollowUp => 'Suivi & alertes';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileNotificationsHint => 'Rappels et alertes';

  @override
  String get profileAidantsHint => 'Gérer les personnes qui t’aident';

  @override
  String get profileAidantsLocked => 'Active d’abord ton suivi patient';

  @override
  String get profileActivateOk => 'Suivi activé';

  @override
  String get profileSectionLegal => 'Légal';

  @override
  String get profileCgu => 'Conditions d’utilisation';

  @override
  String profileCguVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileLogoutConfirm =>
      'Tu quitteras ton compte sur cet appareil. Tes données restent en sécurité.';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get profileSaved => 'Enregistré';

  @override
  String get profileSectionAccount => 'Compte';

  @override
  String get profileAccountTitle => 'Informations du compte';

  @override
  String get profileAccountTileHint => 'Téléphone, fuseau horaire';

  @override
  String get profileAccountHint =>
      'Coordonnées liées à ton compte Fidel — pas de conseil médical ici.';

  @override
  String get profilePhone => 'Téléphone';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileTimezone => 'Fuseau horaire';

  @override
  String get profilePatientSettingsTitle => 'Réglages du suivi';

  @override
  String get profilePatientSettingsTileHint =>
      'Notifications, batterie, mode discret';

  @override
  String get profileFicheSanteTitle => 'Fiche santé';

  @override
  String get profileFicheSanteTileHint =>
      'Groupe sanguin, électrophorèse, taille';

  @override
  String get profileFicheSanteHint =>
      'Choisis parmi les propositions, puis confirme. Aucune saisie libre — pour éviter une erreur.';

  @override
  String get profileFicheSanteSection => 'Identité médicale';

  @override
  String get profileFicheSanteGroupe => 'Groupe sanguin';

  @override
  String get profileFicheSanteElectro => 'Électrophorèse';

  @override
  String get profileFicheSanteTaille => 'Taille';

  @override
  String get profileFicheSanteGroupeShort => 'Groupe';

  @override
  String get profileFicheSanteElectroShort => 'Electro';

  @override
  String get profileFicheSanteTailleShort => 'Taille';

  @override
  String get profileFicheSanteUnset => 'À renseigner';

  @override
  String get profileFicheSanteNeSaitPas => 'Je ne sais pas';

  @override
  String get profileFicheSanteGroupePick => 'Choisis ton groupe';

  @override
  String get profileFicheSanteRhesusPick => 'Choisis le rhésus';

  @override
  String get profileFicheSanteElectroPick => 'Choisis ton électrophorèse';

  @override
  String get profileFicheSanteTaillePick => 'Choisis ta taille';

  @override
  String profileFicheSanteTailleValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileFicheSanteConfirmTitle => 'Tu confirmes ?';

  @override
  String profileFicheSanteConfirmBody(String value) {
    return 'Enregistrer « $value » sur ton profil.';
  }

  @override
  String get profileFicheSanteConfirmAction => 'Confirmer';

  @override
  String get profileFicheSanteCorrectAction => 'Corriger';

  @override
  String get profilePatientSettingsHint =>
      'Ces options concernent uniquement ton suivi patient sur cet appareil et ce compte.';

  @override
  String get profileNotifGranted => 'Notifications autorisées';

  @override
  String get profileNotifGrantedHint =>
      'Indique si Fidel peut te rappeler les prises';

  @override
  String get profileBatteryExempt => 'Batterie non restreinte';

  @override
  String get profileBatteryExemptHint =>
      'Évite que le téléphone coupe les rappels la nuit';

  @override
  String get profileDiscreteNotif => 'Notifications discrètes';

  @override
  String get profileDiscreteNotifHint =>
      'Formulations sobres, sans détail sensible visible';

  @override
  String get alarmSettingsTitle => 'Réglages alarme';

  @override
  String get alarmSettingsTileHint => 'Préavis, son, snooze et permissions';

  @override
  String get alarmSettingsHint =>
      'Configure l’alarme de prise directement dans Fidel. Les notifications de préavis et de confirmation restent actives.';

  @override
  String get alarmSettingsPreavis => 'Préavis';

  @override
  String get alarmSettingsPreavisHint => 'Notification avant l’heure de prise';

  @override
  String get alarmSettingsSnooze => 'Reporter (snooze)';

  @override
  String get alarmSettingsSnoozeHint => 'Délai quand tu choisis « Plus tard »';

  @override
  String alarmSettingsMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get alarmSettingsVibrate => 'Vibration';

  @override
  String get alarmSettingsVibrateHint => 'Vibrer pendant l’alarme H0';

  @override
  String get alarmSettingsCustomVoice => 'Utiliser ma voix de rappel';

  @override
  String get alarmSettingsCustomVoiceHint => 'Sinon, le son Fidel par défaut';

  @override
  String get alarmSettingsCustomVoiceMissing =>
      'Enregistre d’abord une voix personnalisée.';

  @override
  String get alarmSettingsExactTitle => 'Alarmes exactes requises';

  @override
  String get alarmSettingsExactHint =>
      'Sans cette autorisation, Android peut retarder ou bloquer tes alarmes de médicaments.';

  @override
  String get alarmSettingsExactCta => 'Autoriser les alarmes exactes';

  @override
  String get alarmHealthTitle => 'Santé des alarmes';

  @override
  String get alarmHealthTileHint => 'Permissions et réglages constructeur';

  @override
  String get alarmHealthHint =>
      'Vérifie que le téléphone laisse Fidel sonner à l’heure — surtout sur Xiaomi, Samsung, Tecno et marques similaires.';

  @override
  String get alarmHealthRefresh => 'Actualiser';

  @override
  String get alarmHealthAllOk => 'Tout est en ordre pour les alarmes';

  @override
  String get alarmHealthNeedsAttention =>
      'Certains réglages bloquent encore les alarmes';

  @override
  String get alarmHealthNotifTitle => 'Notifications';

  @override
  String get alarmHealthNotifHint => 'Préavis, bandeau H0 et marquage H+5';

  @override
  String get alarmHealthExactTitle => 'Alarmes exactes';

  @override
  String get alarmHealthExactHint =>
      'Déclenchement à l’heure prévue, même en Doze';

  @override
  String get alarmHealthBatteryTitle => 'Batterie non restreinte';

  @override
  String get alarmHealthBatteryHint =>
      'Évite que l’OS tue Fidel en arrière-plan';

  @override
  String get alarmHealthFsiTitle => 'Plein écran (verrouillage)';

  @override
  String get alarmHealthFsiHint =>
      'Afficher l’alarme par-dessus l’écran verrouillé';

  @override
  String get alarmHealthFixCta => 'Corriger';

  @override
  String get alarmHealthOemTitle => 'Réglages constructeur';

  @override
  String get alarmHealthOemCta => 'Ouvrir le réglage auto-démarrage';

  @override
  String get alarmHealthOemXiaomi =>
      'Sur Xiaomi / Redmi / POCO : autorise l’auto-démarrage et mets Fidel en « Sans restriction » dans Batterie.';

  @override
  String get alarmHealthOemHuawei =>
      'Sur Huawei / Honor : autorise le démarrage automatique et la mise en arrière-plan manuelle pour Fidel.';

  @override
  String get alarmHealthOemSamsung =>
      'Sur Samsung : dans Batterie, désactive l’optimisation pour Fidel et autorise l’activité en arrière-plan.';

  @override
  String get alarmHealthOemOppo =>
      'Sur Oppo / Realme / OnePlus : autorise le démarrage automatique et retire Fidel des apps mises en veille.';

  @override
  String get alarmHealthOemVivo =>
      'Sur Vivo / iQOO : autorise le démarrage en arrière-plan et l’auto-démarrage pour Fidel.';

  @override
  String get alarmHealthOemTranssion =>
      'Sur Tecno / Infinix / Itel : autorise l’auto-démarrage et l’activité en arrière-plan pour Fidel.';

  @override
  String get alarmHealthOemGeneric =>
      'Sur certains téléphones, active l’auto-démarrage / activité en arrière-plan pour Fidel dans les réglages constructeur.';

  @override
  String get alarmHealthAppDetailsCta => 'Ouvrir la fiche de l’app';

  @override
  String get alarmRingStop => 'Arrêter';

  @override
  String get alarmRingSnooze => 'Plus tard';

  @override
  String alarmRingBody(String clock) {
    return 'C’est l’heure de ta prise (prévue à $clock).';
  }

  @override
  String alarmRingBodyDiscreet(String clock) {
    return 'C’est l’heure de ton rappel de $clock.';
  }

  @override
  String alarmRingTitleFallback(String clock) {
    return 'Prise · $clock';
  }

  @override
  String get profileContactsTitle => 'Contacts d’urgence';

  @override
  String get profileContactsTileHint => 'Pour le SOS et l’escalade';

  @override
  String get profileContactsHint =>
      'Ces personnes peuvent être jointes si tu déclenches un SOS. Tu restes maître du geste.';

  @override
  String get profileContactsEmpty => 'Aucun contact pour l’instant.';

  @override
  String get profileContactAdd => 'Ajouter un contact';

  @override
  String get profileContactName => 'Nom';

  @override
  String get profileContactRelation => 'Lien (ex. fils, voisin)';

  @override
  String get profileContactDelete => 'Supprimer le contact';

  @override
  String profileContactDeleteConfirm(String name) {
    return 'Retirer $name de tes contacts d’urgence ?';
  }

  @override
  String get profileVoixTitle => 'Voix de rappel';

  @override
  String get profileVoixTileHint => 'Système ou message personnalisé';

  @override
  String get profileVoixHint =>
      'Le son du rappel local. Enregistre un message court ou importe un fichier (mp3, m4a…), max 2 Mo.';

  @override
  String get profileVoixSystem => 'Voix système';

  @override
  String get profileVoixSystemHint => 'Notification standard du téléphone';

  @override
  String get profileVoixCustom => 'Voix personnalisée';

  @override
  String get profileVoixCustomHint => 'Enregistrer ou importer un audio';

  @override
  String get profileVoixCustomActive => 'Voix personnalisée active';

  @override
  String get profileVoixPickFailed =>
      'Impossible de lire ce fichier. Réessaie avec un mp3 ou m4a.';

  @override
  String get profileVoixTooLarge => 'Fichier trop lourd — maximum 2 Mo.';

  @override
  String get profileVoixChooseTitle => 'Comment ajouter ta voix ?';

  @override
  String get profileVoixRecord => 'Enregistrer';

  @override
  String get profileVoixRecordHint => 'Parler au micro (max 60 s)';

  @override
  String get profileVoixImport => 'Importer un fichier';

  @override
  String get profileVoixImportHint => 'Choisir un audio déjà sur le téléphone';

  @override
  String get profileVoixMicDenied =>
      'Autorise le micro pour enregistrer ta voix de rappel.';

  @override
  String get profileVoixRecording => 'Enregistrement…';

  @override
  String get profileVoixRecordReady => 'Appuie pour démarrer';

  @override
  String get profileVoixStop => 'Arrêter';

  @override
  String get profileVoixStart => 'Démarrer';

  @override
  String get profileVoixUseRecording => 'Utiliser cet enregistrement';

  @override
  String get profileVoixRecordAgain => 'Reprendre';

  @override
  String get profileVoixRecordFailed => 'Enregistrement impossible. Réessaie.';

  @override
  String profileVoixSecondsLeft(int seconds) {
    return '$seconds s restantes';
  }

  @override
  String get profileContactsEmptyHint =>
      'Ajoute au moins une personne de confiance pour le SOS.';

  @override
  String get profileContactAddHint =>
      'Nom, numéro et lien — utilisés seulement si tu déclenches un SOS.';

  @override
  String get profileSectionAlerts => 'Alertes & consentement';

  @override
  String get profileConsentTitle => 'Préférences d’alerte';

  @override
  String get profileConsentTileHint =>
      'Toujours demander avant d’alerter un tiers';

  @override
  String get profileConsentHint =>
      'Par défaut, Fidel demande toujours ton accord avant de prévenir quelqu’un. Désactiver « toujours demander » active une règle auto opt-in (ex. 48 h) — jamais pré-cochée.';

  @override
  String get profileConsentAlwaysAsk => 'Toujours me demander';

  @override
  String get profileConsentAutoHint => 'Règle auto opt-in (délai 48 h)';

  @override
  String get profileAlertRappelMed => 'Rappel médicament';

  @override
  String get profileAlertStock => 'Stock bas';

  @override
  String get profileAlertConstanteUp => 'Constante en amélioration';

  @override
  String get profileAlertConstanteDown => 'Constante à surveiller';

  @override
  String get profileAlertCheckin => 'Absence de check-in';

  @override
  String get profileAlertPriseConfirmee =>
      'Informer mes aidants quand je confirme une prise';

  @override
  String get profileAlertPriseNonConfirmee =>
      'Prévenir mes aidants si je ne confirme pas (2 h)';

  @override
  String get profileAlertDepistage => 'Dépistage recommandé';

  @override
  String get profileSectionCaregiver => 'Accompagner quelqu’un';

  @override
  String get profileSyncTileHint => 'Entrer un code pour devenir aidant';

  @override
  String get profileDeleteTitle => 'Supprimer mon compte';

  @override
  String get profileDeleteTileHint => 'Désactivation définitive de l’accès';

  @override
  String get profileDeleteHint =>
      'Ton compte sera désactivé (soft delete). Tu pourras te reconnecter seulement si le support te réactive.';

  @override
  String get profileDeleteConfirm =>
      'Confirmer la suppression de ton compte Fidel ?';

  @override
  String get profileDeleteAction => 'Supprimer le compte';

  @override
  String get cercleMyPatients => 'J’accompagne';

  @override
  String get cercleMyPatientsEmptyTitle =>
      'Personne accompagnée pour l’instant';

  @override
  String get cercleMyPatientsEmptyBody =>
      'Entre un code Fidel pour rejoindre le suivi d’un proche qui t’a donné son accord.';

  @override
  String get cercleMyCircle => 'Mon cercle';

  @override
  String get cercleMyCircleHint =>
      'Ton réseau de confiance pour le suivi et les situations urgentes.';

  @override
  String get cercleQuickLinks => 'Liens rapides';

  @override
  String get cercleLinkSyncHint => 'Entrer un nouveau code de suivi';

  @override
  String get cercleLinkAidantsHint => 'Gérer les personnes qui t’accompagnent';

  @override
  String get cercleEmptyTitle => 'Commencer ton cercle';

  @override
  String get cercleEmptyBody =>
      'Active ton suivi personnel ou connecte-toi au suivi d’un proche. Les deux capacités peuvent vivre sur le même compte.';

  @override
  String get cercleSosTitle => 'Déclencher le SOS';

  @override
  String get cercleAddEmergencyContact => 'Ajouter un contact d’urgence';

  @override
  String get cercleSosSent => 'SOS déclenché';

  @override
  String get cercleSosCancel => 'Annuler l’alerte';

  @override
  String get cercleSosCancelled => 'SOS annulé';

  @override
  String cercleSosCountdown(int seconds) {
    return 'Tu peux encore annuler pendant $seconds s.';
  }

  @override
  String get cercleDetailAdherence => 'Observance';

  @override
  String get cercleTodaySection => 'Aujourd’hui';

  @override
  String get cercleDetailVitals => 'Constantes';

  @override
  String cercleAdherenceWindow(String from, String to) {
    return 'Fenêtre suivie : du $from au $to';
  }

  @override
  String get cercleAdherenceRate => 'Taux';

  @override
  String get cercleAdherenceConfirmed => 'Confirmées';

  @override
  String get cercleAdherenceMissed => 'Manquées';

  @override
  String get cercleAdherencePending => 'En attente';

  @override
  String get cerclePermissionLocked =>
      'Cette donnée n’est pas partagée avec toi.';

  @override
  String get cerclePermissionLimited => 'Accès limité';

  @override
  String get cercleNoVitals => 'Aucune constante partagée pour le moment.';

  @override
  String get cerclePatientUnavailable =>
      'Cette personne n’est plus dans ton cercle.';

  @override
  String get reminderNotifTitle => 'Metformine · 500 mg';

  @override
  String get reminderNotifTitleDiscreet => 'Fidel · 08:00';

  @override
  String get reminderNotifBodyDiscreet =>
      'C\'est l\'heure de ton rappel de 08:00.';

  @override
  String get reminderMarkTitle => 'Metformine · 500 mg';

  @override
  String get reminderMarkBodyDiscreet =>
      'As-tu bien fait ton rappel de 08:00 ?';

  @override
  String get reminderActionTaken => 'J\'ai pris';

  @override
  String get reminderActionSnooze => 'Plus tard';
}

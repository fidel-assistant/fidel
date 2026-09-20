// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Fidel';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change this later in settings.';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageContinue => 'Continue';

  @override
  String get loginTitle => 'Sign in to your Account';

  @override
  String get loginSubtitle => 'Enter your email and password to log in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orLoginWith => 'Or login with';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'name@email.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot Password ?';

  @override
  String get logIn => 'Log In';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get loginFailed => 'Unable to sign in. Check your credentials.';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String passwordTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get homeTitle => 'Home';

  @override
  String get logout => 'Log out';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Enter your email to get started';

  @override
  String get registerContinue => 'Continue';

  @override
  String get otpTitle => 'Check your email';

  @override
  String otpSubtitle(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get otpLabel => 'Verification code';

  @override
  String get otpHint => '123456';

  @override
  String get otpInvalid => 'Enter the 6-digit code';

  @override
  String get otpVerify => 'Verify';

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpResent => 'A new code was sent';

  @override
  String get passwordTitle => 'Choose a password';

  @override
  String get passwordSubtitle => 'At least 8 characters';

  @override
  String get passwordContinue => 'Continue';

  @override
  String get legalTitle => 'Almost done';

  @override
  String get legalSubtitle => 'Review and accept to finish signup';

  @override
  String legalCgu(String version) {
    return 'I accept the Terms of Use (version $version)';
  }

  @override
  String get legalConsent =>
      'I consent to the processing of my health data for accompaniment (not medical diagnosis)';

  @override
  String get legalRequired => 'Please accept both to continue';

  @override
  String get legalFinish => 'Create account';

  @override
  String get emailAlreadyVerified =>
      'This email is already registered. Try signing in.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get successEmailTitle => 'Email verified!';

  @override
  String get successEmailSubtitle =>
      'Your email is confirmed. Next, choose a secure password.';

  @override
  String get successEmailCta => 'Continue';

  @override
  String get successAccountTitle => 'Successful!';

  @override
  String get successAccountSubtitle =>
      'Your account is created and ready. Welcome to Fidel.';

  @override
  String get successAccountCta => 'Continue setup';

  @override
  String get forgotTitle => 'Forgot password?';

  @override
  String get forgotSubtitle => 'Enter your email and we’ll send a reset code';

  @override
  String get forgotContinue => 'Send code';

  @override
  String get forgotOtpSent => 'Reset code sent';

  @override
  String get forgotResetTitle => 'New password';

  @override
  String get forgotResetSubtitle => 'Choose a new secure password';

  @override
  String get forgotResetCta => 'Update password';

  @override
  String get forgotResetSuccess => 'Password updated. You can sign in now.';

  @override
  String get googleFailed => 'Google sign-in failed';

  @override
  String get googleCancelled => 'Google sign-in cancelled';

  @override
  String get googleNotConfigured =>
      'Google Sign-In is not configured on this build';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String onboardingStepOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboardingStepProfil => 'You';

  @override
  String get onboardingStepSuivi => 'Care';

  @override
  String get onboardingStepTraitement => 'Treatment';

  @override
  String get onboardingStepRappels => 'Reminders';

  @override
  String get onboardingGateLoading => 'Preparing your space…';

  @override
  String get onboardingRetry => 'Try again';

  @override
  String get onboardingInfosTitle => 'What should we call you?';

  @override
  String get onboardingInfosSubtitle =>
      'A few details to personalize Fidel. Nothing is locked in.';

  @override
  String get onboardingNameLabel => 'Full name';

  @override
  String get onboardingBirthLabel => 'Date of birth';

  @override
  String get onboardingBirthHint => 'Pick a date';

  @override
  String get onboardingBirthRequired => 'Please enter your date of birth';

  @override
  String get onboardingSexLabel => 'Sex';

  @override
  String get onboardingSexF => 'Woman';

  @override
  String get onboardingSexM => 'Man';

  @override
  String get onboardingSexOther => 'Other';

  @override
  String get onboardingLocationLabel => 'City / neighborhood';

  @override
  String get onboardingLocationHint => 'e.g. Douala, Akwa';

  @override
  String get onboardingPhoneLabel => 'Phone';

  @override
  String get onboardingPhoneHint => '+237 6…';

  @override
  String get onboardingPhoneOptional => 'Optional — you can add it later';

  @override
  String get onboardingBesoinTitle => 'Do you want follow-up for yourself?';

  @override
  String get onboardingBesoinSubtitle =>
      'You can also support someone from home. Both are possible, without a second account.';

  @override
  String get onboardingBesoinYesTitle => 'Yes, follow-up for me';

  @override
  String get onboardingBesoinYesSubtitle =>
      'Medication reminders, vitals, and personal accompaniment';

  @override
  String get onboardingBesoinNoTitle => 'Not for now';

  @override
  String get onboardingBesoinNoSubtitle =>
      'I mostly want to support someone later';

  @override
  String get onboardingChoiceRequired => 'Choose an option to continue';

  @override
  String get onboardingTraitementTitle => 'Are you in treatment?';

  @override
  String get onboardingTraitementSubtitle =>
      'If yes, tick what you follow. Medicines and schedules come later — no pressure.';

  @override
  String get onboardingTraitementYes => 'Yes, I’m in treatment';

  @override
  String get onboardingTraitementYesSubtitle =>
      'We only note the condition and phase for now';

  @override
  String get onboardingTraitementNo => 'Not right now';

  @override
  String get onboardingTraitementNoSubtitle =>
      'You can add this later from home';

  @override
  String get onboardingTraitementNoHint =>
      'No problem — you can activate follow-up later.';

  @override
  String get onboardingMaladiesLabel => 'What are you following?';

  @override
  String get onboardingMaladieRequired => 'Select at least one condition';

  @override
  String get onboardingMaladiesEmpty =>
      'Couldn’t load the catalog. Check your connection.';

  @override
  String get onboardingPhaseLabel => 'Where are you in it?';

  @override
  String get onboardingPhaseDebut => 'Just starting';

  @override
  String get onboardingPhaseEnCours => 'Ongoing';

  @override
  String get onboardingPhaseMaintenance => 'Maintenance';

  @override
  String get onboardingPhaseInconnu => 'I’m not sure';

  @override
  String get onboardingPermsTitle => 'So reminders actually ring';

  @override
  String get onboardingPermsSubtitle =>
      'We explain before the phone asks. You can skip — reminders may then be unreliable.';

  @override
  String get onboardingPermsNotifTitle => 'Notifications';

  @override
  String get onboardingPermsNotifBody =>
      'So we can warn you before a dose and confirm afterwards.';

  @override
  String get onboardingPermsExactTitle => 'Exact alarms (Android)';

  @override
  String get onboardingPermsExactBody =>
      'So the alarm rings on time even when the phone is asleep.';

  @override
  String get onboardingPermsBatteryTitle => 'Battery (Android)';

  @override
  String get onboardingPermsBatteryBody =>
      'Without an exemption, some phones kill reminders overnight.';

  @override
  String get onboardingPermsAllow => 'Allow reminders';

  @override
  String get onboardingPermsLater => 'Later';

  @override
  String get onboardingDoneToast => 'You’re all set — welcome to Fidel';

  @override
  String get navHome => 'Home';

  @override
  String get navCare => 'Health';

  @override
  String get healthSubtitle =>
      'Your vitals — weight, blood pressure, blood sugar…';

  @override
  String get healthRecommended => 'Recommended for you';

  @override
  String get healthAllMetrics => 'All your vitals';

  @override
  String get healthRecent => 'Recent measurements';

  @override
  String get healthRecentEmpty => 'No measurements yet. Add your first one.';

  @override
  String get healthAddCta => 'Add a measurement';

  @override
  String get healthEmptyHero =>
      'Start with one measurement. Now and then is enough.';

  @override
  String get healthNoData => 'No measurement yet';

  @override
  String healthDaysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get healthViewAll => 'View in Health';

  @override
  String get healthRecommendedBadge => 'Recommended';

  @override
  String get healthLatestMeasure => 'Latest measurement';

  @override
  String get healthHistory => 'History';

  @override
  String healthNoDataForType(String type) {
    return 'No $type measurements yet.';
  }

  @override
  String get navPeople => 'Circle';

  @override
  String get navYou => 'Profile';

  @override
  String homeHelloMorning(String name) {
    return 'Good morning $name';
  }

  @override
  String homeHelloAfternoon(String name) {
    return 'Good afternoon $name';
  }

  @override
  String homeHelloEvening(String name) {
    return 'Good evening $name';
  }

  @override
  String get homeHelloMorningAnon => 'Good morning!';

  @override
  String get homeHelloAfternoonAnon => 'Good afternoon!';

  @override
  String get homeHelloEveningAnon => 'Good evening!';

  @override
  String get homeTagline => 'Fidel watches your doses — never judges.';

  @override
  String get homeNotifA11y => 'Reminders';

  @override
  String get homeSettingsA11y => 'Settings';

  @override
  String get homeMoreA11y => 'More options';

  @override
  String get homeNotifTitle => 'Reminders';

  @override
  String get homeNotifBody =>
      'Reminders ring on this phone, even offline. Nothing is sent to a relative without your say-so.';

  @override
  String get homeNotifReadyTitle => 'Reminders are ready';

  @override
  String get homeNotifReadyBody =>
      'Fidel will ping you here, on this device — no score, no judgment.';

  @override
  String get homeTodayTitle => 'Today';

  @override
  String get homeNextDoseLabel => 'Next dose';

  @override
  String homeSlotMedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medications',
      one: '1 medication',
    );
    return '$_temp0';
  }

  @override
  String get homeAllClearTitle => 'You’re up to date';

  @override
  String get homeAllClearBody => 'No pending doses right now. Rest a little.';

  @override
  String get homeStatPending => 'Due';

  @override
  String get homeStatTaken => 'Taken';

  @override
  String get homeStatLate => 'Late';

  @override
  String get homeMissedCanStillConfirm => 'Missed — you can still confirm';

  @override
  String get homeNoDoses => 'No schedule yet today. Add a medication to start.';

  @override
  String get homeTakeCta => 'I took it';

  @override
  String get homeTakenBadge => 'Taken';

  @override
  String get homeTakenToast => 'Noted — well done.';

  @override
  String get homeActivateTitle => 'Start my follow-up';

  @override
  String get homeActivateBody =>
      'Reminders, treatments and doses for you, on this account.';

  @override
  String get homeAccompanyTitle => 'Support someone';

  @override
  String get homeAccompanyBody =>
      'Enter a relative’s code to follow them, with their consent.';

  @override
  String get homeAccompaniedSection => 'People I support';

  @override
  String get homeActiveSosSection => 'Active SOS';

  @override
  String get aidantSignalSos => 'Active SOS';

  @override
  String get aidantSignalMissed => 'Missed dose today';

  @override
  String get aidantSignalPending => 'Dose pending';

  @override
  String get aidantSignalOk => 'Doses confirmed';

  @override
  String get aidantSignalNothing => 'Nothing planned today';

  @override
  String get aidantVoixSection => 'Reminder voice';

  @override
  String get aidantVoixBody => 'Record a voice for this person’s reminders.';

  @override
  String get aidantVoixCta => 'Add a voice';

  @override
  String get aidantVoixUploaded => 'Voice sent';

  @override
  String get aidantNotifSection => 'Notifications';

  @override
  String get aidantMutePriseConfirmee => 'Mute confirmed doses';

  @override
  String get aidantMutePriseNonConfirmee => 'Mute unconfirmed doses';

  @override
  String get aidantMuteSos => 'Mute SOS';

  @override
  String get aidantMuteSosHint =>
      'You won’t be alerted if this person triggers an SOS.';

  @override
  String get healthAidantOnlyTitle => 'Health is your own follow-up';

  @override
  String get healthAidantOnlyBody =>
      'Measurements here are for your own follow-up. You can start it whenever you want. The people you support stay on Home.';

  @override
  String get homeShareCodeTitle => 'Invite a caregiver';

  @override
  String get homeShareCodeBody =>
      'This code expires quickly. Share it only with someone you choose.';

  @override
  String get homeAidantsTitle => 'Your caregivers';

  @override
  String get homeAidantsIntro =>
      'You can invite someone to support you on Fidel — always with your consent.';

  @override
  String get homeAidantsSection => 'Caregiver status';

  @override
  String get homeAidantsSectionHint =>
      'Tap a caregiver to manage access or remove them.';

  @override
  String get homeAidantsEmpty => 'No caregivers yet.';

  @override
  String get homeAidantsEmptyTitle => 'No caregivers yet';

  @override
  String get homeAidantsEmptyBody =>
      'Invite someone you trust to support your doses — you stay in control of what they can see.';

  @override
  String get homeAidantsInviteCta => 'Invite a caregiver';

  @override
  String get homeAidantsTrust =>
      'Access is limited to what you allow. You can revoke anytime —';

  @override
  String get homeAidantsTrustHighlight => 'always with your consent.';

  @override
  String get homeAidantsManageTitle => 'Manage access';

  @override
  String get homeAidantsPermObservance => 'See doses';

  @override
  String get homeAidantsPermConstantes => 'See vitals';

  @override
  String get homeAidantsRevoke => 'Remove access';

  @override
  String get homeAidantsRevoked =>
      'This caregiver no longer has access to your follow-up.';

  @override
  String get homeAidantsPermObservanceOnly => 'Adherence';

  @override
  String get homeAidantsPermBoth => 'Adherence and vitals';

  @override
  String get homeAidantsPermNone => 'Limited access';

  @override
  String get homeInviteCopy => 'Copy code';

  @override
  String get homeInviteCopied => 'Code copied';

  @override
  String get homeInviteAltLink => 'Have a code? Support someone';

  @override
  String get homeInviteHint =>
      'Share this code with the person you invite. They enter it in Fidel to join your follow-up.';

  @override
  String get homeActionNotifTitle => 'Allow reminders';

  @override
  String get homeActionNotifBody =>
      'Without this, the phone may kill alarms overnight.';

  @override
  String get homeActionMedsTitle => 'Set up your medicines';

  @override
  String get homeActionMedsBody =>
      'Name, dose and times — that’s what makes reminders ring.';

  @override
  String homeActionMedsFor(String maladie) {
    return 'For $maladie';
  }

  @override
  String get homeActionTraitementTitle => 'Add a treatment';

  @override
  String get homeActionTraitementBody =>
      'We note the condition first; medicines come right after.';

  @override
  String get homeSoftChecklistTitle => 'A few optional steps';

  @override
  String get homeSoftPhoneTitle => 'Add your phone number';

  @override
  String get homeSoftPhoneBody => 'Helpful for SOS and reaching you if needed.';

  @override
  String get homeSoftContactTitle => 'Add an emergency contact';

  @override
  String get homeSoftContactBody => 'Someone you trust for critical moments.';

  @override
  String get homeSoftVoixTitle => 'Personalize your reminder voice';

  @override
  String get homeSoftVoixBody => 'A short message in your voice for alarms.';

  @override
  String get homeSoftPhotoTitle => 'Add a profile photo';

  @override
  String get homeSoftPhotoBody => 'So your circle can recognize you easily.';

  @override
  String get homeSoftDismissA11y => 'Dismiss this suggestion';

  @override
  String get homeCareSubtitle =>
      'Vitals, doses and log — the detail of your follow-up.';

  @override
  String get homeNetworkSubtitle =>
      'Who supports you, who you support, and SOS — in one place.';

  @override
  String get homeCareMedsReady => 'Medicines saved';

  @override
  String get homeCareTreatments => 'Your treatments';

  @override
  String get homeCareWeek => 'This week’s adherence';

  @override
  String get homeCareAddMed => 'Add a medicine';

  @override
  String get homeCareConfigureMeds => 'Set up medicines';

  @override
  String get homeCareManageStock => 'Manage stock';

  @override
  String get homeCareEmptyPatientTitle => 'Activate your follow-up';

  @override
  String get homeCareActionTraitement => 'Treatment';

  @override
  String get homeCareActionMeds => 'Medicine';

  @override
  String get homeCareActionMedsSetup => 'Set up';

  @override
  String get homeCareActionVital => 'Measure';

  @override
  String get homeCareJournal => 'Follow-up log';

  @override
  String get homeCareJournalEmpty =>
      'Nothing here yet. Confirm a dose or add a measurement.';

  @override
  String get homeCareProgressPrises => 'Doses';

  @override
  String get homeCareProgressLate => 'Late';

  @override
  String get homeCareProgressCheckIn => 'Check-in';

  @override
  String get homeCareProgressCheckInTodo => 'To do';

  @override
  String get homeCareProgressCheckInOk => 'OK';

  @override
  String get homeCareProgressCheckInBad => 'Not great';

  @override
  String get homeCareHeroDosesLabel => 'Today’s doses';

  @override
  String homeCareHeroDosesValue(int taken, int total) {
    return '$taken / $total';
  }

  @override
  String get homeCareHeroNoVital => 'Add a measurement to see your curve here.';

  @override
  String get homeCareFeedPriseTaken => 'Taken';

  @override
  String get homeCareFeedPriseMissed => 'Missed';

  @override
  String get homeCareFeedPrisePending => 'Pending';

  @override
  String homeCareOfValue(int current, int total) {
    return '$current of $total';
  }

  @override
  String get homeThemeLabel => 'Appearance';

  @override
  String get homeThemeLight => 'Light';

  @override
  String get homeThemeDark => 'Dark';

  @override
  String get homeThemeSystem => 'System';

  @override
  String get homeSyncHint => 'The 6-digit code they generated in Fidel.';

  @override
  String get homeSyncCodeLabel => 'Code';

  @override
  String get homeSyncCta => 'Connect to their follow-up';

  @override
  String get homeSyncOk => 'You’re now connected to their follow-up.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get homeSnoozeCta => 'Later';

  @override
  String get homeSnoozeTitle => 'Push this dose back';

  @override
  String get homeSnoozeBody => 'We move the reminder, nothing is erased.';

  @override
  String homeSnoozeDone(String heure) {
    return 'Moved to $heure';
  }

  @override
  String homeCountdownIn(String value) {
    return 'in $value';
  }

  @override
  String homeCountdownLate(String value) {
    return '$value late';
  }

  @override
  String get homeCountdownNow => 'now';

  @override
  String homeDurationHm(String h, String m) {
    return '${h}h $m';
  }

  @override
  String homeDurationH(int h) {
    return '${h}h';
  }

  @override
  String homeDurationM(int m) {
    return '$m min';
  }

  @override
  String get homeDayProgressLabel => 'Today’s doses';

  @override
  String get homeDayProgressTitle => 'Today’s progress';

  @override
  String get homeDayProgressHint =>
      'Doses confirmed out of those scheduled today. This is not a health score.';

  @override
  String get homeDayProgressDone => 'Done';

  @override
  String get homeDayProgressOngoing => 'In progress';

  @override
  String get homeDayProgressUpcoming => 'Upcoming';

  @override
  String get homeDayProgressLate => 'Some doses are waiting';

  @override
  String homeDayProgressPendingCount(int count) {
    return '$count upcoming';
  }

  @override
  String homeDayProgressLateCount(int count) {
    return '$count late';
  }

  @override
  String get homeTodaySummaryTitle => 'Today’s summary';

  @override
  String get homeTodaySummaryViewAll => 'View all';

  @override
  String get homeTodaySummaryBody => 'Your latest recorded measurements.';

  @override
  String get homeTodaySummaryEmpty =>
      'No measurements yet. Add one whenever you like.';

  @override
  String get homeDayDoneTitle => 'Day complete';

  @override
  String get homeDayDoneBody => 'Every dose is confirmed. Nicely done.';

  @override
  String get homeWeekTitle => 'Your week';

  @override
  String homeWeekSummary(int confirmed, int total) {
    return '$confirmed doses confirmed out of $total';
  }

  @override
  String get homeWeekEmpty => 'Your doses for the week will show up here.';

  @override
  String homeWeekPerfect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count full days',
      one: '$count full day',
    );
    return '$_temp0';
  }

  @override
  String homeRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left',
      one: '$count left',
    );
    return '$_temp0';
  }

  @override
  String get homeCheckInTitle => 'How are you feeling today?';

  @override
  String get homeCheckInBody => 'One tap a day, just to keep track.';

  @override
  String get homeCheckInOk => 'I’m okay';

  @override
  String get homeCheckInBad => 'Not great';

  @override
  String get homeCheckInDoneOk => 'Today: okay';

  @override
  String get homeCheckInDoneBad => 'Today: not great';

  @override
  String get homeCheckInThanks => 'Thanks, noted.';

  @override
  String get homeCheckInLevelTresMal => 'Very bad';

  @override
  String get homeCheckInLevelPasTop => 'Not great';

  @override
  String get homeCheckInLevelCaVa => 'Okay';

  @override
  String get homeCheckInLevelSuper => 'Great';

  @override
  String get homeCheckInDoneTresMal => 'Today: very bad';

  @override
  String get homeCheckInDonePasTop => 'Today: not great';

  @override
  String get homeCheckInDoneCaVa => 'Today: okay';

  @override
  String get homeCheckInDoneSuper => 'Today: great';

  @override
  String get homeCheckInReminderTitle => 'How are you feeling today?';

  @override
  String get homeCheckInReminderBody =>
      'One tap, four choices — helps keep your follow-up on track.';

  @override
  String get homeCheckInActionTresMal => 'Very bad';

  @override
  String get homeCheckInActionPasTop => 'Not great';

  @override
  String get homeCheckInActionCaVa => 'Okay';

  @override
  String get homeCheckInActionSuper => 'Great';

  @override
  String homeTreatmentDay(int day) {
    return 'Day $day';
  }

  @override
  String homeTreatmentDayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String get homeTreatmentDayUnit => 'day';

  @override
  String get homeTreatmentOngoing => 'Treatment in progress';

  @override
  String get homeTreatmentEndAction => 'Mark as finished';

  @override
  String get homeTreatmentEndTitle => 'End this treatment?';

  @override
  String get homeTreatmentEndBody =>
      'Medicine reminders for this condition will stop. You can always add a new treatment later.';

  @override
  String get homeTreatmentEndConfirm => 'Yes, end it';

  @override
  String get homeTreatmentEndedToast => 'Treatment ended — reminders stopped.';

  @override
  String get manageTraitementTitle => 'Manage treatment';

  @override
  String get manageTraitementSection => 'Treatment';

  @override
  String get manageTraitementEditMeta => 'Edit phase and end date';

  @override
  String get manageTraitementPhaseLabel => 'Phase';

  @override
  String get manageTraitementSuspend => 'Pause';

  @override
  String get manageTraitementResume => 'Resume';

  @override
  String get manageTraitementSuspendTitle => 'Pause this treatment?';

  @override
  String get manageTraitementSuspendBody =>
      'Reminders stop for now. You can resume anytime from this screen.';

  @override
  String get manageTraitementSuspendConfirm => 'Yes, pause it';

  @override
  String get manageTraitementSuspendedBadge => 'Paused';

  @override
  String get manageTraitementSuspendedToast =>
      'Treatment paused — reminders on hold.';

  @override
  String get manageTraitementResumedToast =>
      'Treatment resumed — reminders back on.';

  @override
  String get manageTraitementUpdatedToast => 'Treatment updated.';

  @override
  String manageTraitementEndDate(String date) {
    return 'Ends $date';
  }

  @override
  String get manageMedsSection => 'Medicines';

  @override
  String get manageMedsEmpty => 'No active medicines on this treatment.';

  @override
  String get manageMedAdd => 'Add';

  @override
  String get manageMedEdit => 'Edit';

  @override
  String get manageMedDeactivate => 'Deactivate';

  @override
  String get manageMedDeactivateTitle => 'Deactivate this medicine?';

  @override
  String manageMedDeactivateBody(String name) {
    return '“$name” will no longer trigger reminders. You can add another later.';
  }

  @override
  String get manageMedDeactivateConfirm => 'Yes, deactivate';

  @override
  String get manageMedDeactivatedToast => 'Medicine deactivated.';

  @override
  String get manageMedUpdatedToast => 'Medicine updated.';

  @override
  String get manageMedNeedIdentity => 'Enter the name and dosage.';

  @override
  String get configDateFinLabel => 'Expected end date (optional)';

  @override
  String get configDateFinHint =>
      'If you know it, we’ll stop reminders automatically after that day.';

  @override
  String get configDateFinClear => 'No end date';

  @override
  String get homePhaseDebut => 'Start';

  @override
  String get homePhaseEnCours => 'Ongoing';

  @override
  String get homePhaseMaintenance => 'Maintenance';

  @override
  String get homeMomentMorning => 'Morning';

  @override
  String get homeMomentAfternoon => 'Afternoon';

  @override
  String get homeMomentEvening => 'Evening';

  @override
  String get homeVitalsTitle => 'Your tracking';

  @override
  String get homeVitalsAdd => 'Add';

  @override
  String get homeVitalsFirst =>
      'First measurement saved. The curve shows up from the next one.';

  @override
  String get homeVitalsSystolic => 'Systolic';

  @override
  String get homeVitalsDiastolic => 'Diastolic';

  @override
  String get homeVitalsSaved => 'Measurement saved.';

  @override
  String get homeVitalsEmptyTitle => 'Track a measurement';

  @override
  String get homeVitalsEmptyBody =>
      'Weight, blood pressure, blood sugar… now and then is enough.';

  @override
  String get constantePoids => 'Weight';

  @override
  String get constanteTension => 'Blood pressure';

  @override
  String get constanteGlycemie => 'Blood sugar';

  @override
  String get constanteTemperature => 'Temperature';

  @override
  String get constanteSommeil => 'Sleep';

  @override
  String get constanteHumeur => 'Mood';

  @override
  String get addVitalTitle => 'New measurement';

  @override
  String get addVitalValue => 'Value';

  @override
  String get addVitalSystolic => 'Systolic';

  @override
  String get addVitalDiastolic => 'Diastolic';

  @override
  String get addVitalDate => 'Measured on';

  @override
  String get addVitalSave => 'Save';

  @override
  String get addVitalInvalid => 'Enter a valid number.';

  @override
  String get medsWizardTitle => 'Your medicines';

  @override
  String get medsWizardSubtitle =>
      'One line is enough to start. You can add more later.';

  @override
  String get medsSuggestions => 'Suggestions';

  @override
  String get medsNameLabel => 'Medicine name';

  @override
  String get medsDoseLabel => 'Dosage';

  @override
  String get medsDoseHint => 'e.g. 500 mg';

  @override
  String get medsTimesLabel => 'Dose times';

  @override
  String get medsAddTime => 'Add a time';

  @override
  String get medsNeedTime => 'Add at least one time';

  @override
  String get medsNeedDays => 'Pick at least one day';

  @override
  String get medsSaveCta => 'Save';

  @override
  String get medsSaved => 'Medicine saved. Today’s doses are ready.';

  @override
  String get medsAddAnother => 'Add another medicine';

  @override
  String get medsSaveAndAddAnother => 'Save and add another';

  @override
  String get medsFinishCta => 'Done — go home';

  @override
  String medsConfiguredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medicines already on this treatment',
      one: '$count medicine already on this treatment',
    );
    return '$_temp0';
  }

  @override
  String get medsMultiHint =>
      'Add as many as you need for this treatment, one at a time.';

  @override
  String get configStepMaladie => 'Condition';

  @override
  String get configStepContexte => 'Context';

  @override
  String get configStepIdentite => 'Identity';

  @override
  String get configStepHoraires => 'Schedule';

  @override
  String get configStepRecap => 'Review';

  @override
  String get configTraitementTitle => 'Which treatment are you on?';

  @override
  String get configTraitementSubtitle =>
      'Pick the condition you follow. Medicines come right after.';

  @override
  String get configPhaseTitle => 'Where are you in it?';

  @override
  String get configPhaseSubtitle =>
      'Phase and start date help Fidel contextualize your follow-up.';

  @override
  String get configTraitementCreate => 'Set up medicines';

  @override
  String get configDateDebutLabel => 'Start date';

  @override
  String get configDateDebutHint => 'If you’re unsure, leave today’s date.';

  @override
  String get medsStepIdentiteTitle => 'Your medicine';

  @override
  String get medsStepIdentiteSubtitle =>
      'A protocol suggestion, or free entry — you’re in control.';

  @override
  String get medsStepHorairesTitle => 'When to take it?';

  @override
  String get medsStepHorairesSubtitle => 'Times and days drive your reminders.';

  @override
  String get medsStepRecapTitle => 'Looking good?';

  @override
  String get medsStepRecapSubtitle =>
      'Save then add the next one, or finish if this is the last.';

  @override
  String get medsFormeLabel => 'Form';

  @override
  String get medsFormeComprime => 'Tablet';

  @override
  String get medsFormeSirop => 'Syrup';

  @override
  String get medsFormeInjection => 'Injection';

  @override
  String get medsFormeAutre => 'Other';

  @override
  String get medsDaysLabel => 'Days';

  @override
  String get medsDaysEvery => 'Every day';

  @override
  String get medsDaysCustom => 'Specific days';

  @override
  String get medsDayMon => 'M';

  @override
  String get medsDayTue => 'T';

  @override
  String get medsDayWed => 'W';

  @override
  String get medsDayThu => 'T';

  @override
  String get medsDayFri => 'F';

  @override
  String get medsDaySat => 'S';

  @override
  String get medsDaySun => 'S';

  @override
  String get medsRepasLabel => 'With meals';

  @override
  String get medsRepasNone => 'Not specified';

  @override
  String get medsRepasAvant => 'Before meals';

  @override
  String get medsRepasApres => 'After meals';

  @override
  String get medsRepasIndifferent => 'Doesn’t matter';

  @override
  String get medsRecapTraitementHint => 'Linked to this treatment';

  @override
  String get medsRecapTrust =>
      'You can adjust later. Fidel doesn’t give medical advice — only reminders based on what you set.';

  @override
  String get medsStockSection => 'Stock (optional)';

  @override
  String get medsStockHint =>
      'So we can warn you before you run out. Adjust later in Care.';

  @override
  String get medsStockLabel => 'Units left';

  @override
  String get medsStockSeuilLabel => 'Alert when ≤';

  @override
  String get medsStockSeuilHint => 'Defaults to 5 if you set a stock';

  @override
  String get medsStockRecap => 'Stock';

  @override
  String get medsStockSheetTitle => 'Medicine stock';

  @override
  String get medsStockSheetEmpty =>
      'No medicines configured for this treatment.';

  @override
  String get medsStockSave => 'Save stock';

  @override
  String get medsStockSaved => 'Stock updated';

  @override
  String get medsStockAlertTriggered => 'Low stock — an alert was logged.';

  @override
  String get medsStockInvalid => 'Enter a whole number ≥ 0.';

  @override
  String get profileSubtitle =>
      'Account, preferences and follow-up — all in one place.';

  @override
  String get profileFallbackName => 'Fidel account';

  @override
  String get profileChipPatient => 'Follow-up on';

  @override
  String get profileChipAidant => 'Caregiver';

  @override
  String get profileChipAccount => 'Account';

  @override
  String get profileSectionPrefs => 'Preferences';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileSectionFollowUp => 'Follow-up & alerts';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileNotificationsHint => 'Reminders and alerts';

  @override
  String get profileAidantsHint => 'Manage people who help you';

  @override
  String get profileAidantsLocked => 'Activate your patient follow-up first';

  @override
  String get profileActivateOk => 'Follow-up activated';

  @override
  String get profileSectionLegal => 'Legal';

  @override
  String get profileCgu => 'Terms of use';

  @override
  String profileCguVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileLogoutConfirm =>
      'You’ll sign out on this device. Your data stays safe.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get profileSaved => 'Saved';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileAccountTitle => 'Account details';

  @override
  String get profileAccountTileHint => 'Phone, time zone';

  @override
  String get profileAccountHint =>
      'Details linked to your Fidel account — no medical advice here.';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileTimezone => 'Time zone';

  @override
  String get profilePatientSettingsTitle => 'Follow-up settings';

  @override
  String get profilePatientSettingsTileHint =>
      'Notifications, battery, discreet mode';

  @override
  String get profileFicheSanteTitle => 'Health profile';

  @override
  String get profileFicheSanteTileHint => 'Blood type, electrophoresis, height';

  @override
  String get profileFicheSanteHint =>
      'Pick from the list, then confirm. No free typing — to avoid mistakes.';

  @override
  String get profileFicheSanteSection => 'Medical identity';

  @override
  String get profileFicheSanteGroupe => 'Blood type';

  @override
  String get profileFicheSanteElectro => 'Electrophoresis';

  @override
  String get profileFicheSanteTaille => 'Height';

  @override
  String get profileFicheSanteGroupeShort => 'Blood';

  @override
  String get profileFicheSanteElectroShort => 'Hb type';

  @override
  String get profileFicheSanteTailleShort => 'Height';

  @override
  String get profileFicheSanteUnset => 'Not set yet';

  @override
  String get profileFicheSanteNeSaitPas => 'I don’t know';

  @override
  String get profileFicheSanteGroupePick => 'Choose your blood group';

  @override
  String get profileFicheSanteRhesusPick => 'Choose Rh factor';

  @override
  String get profileFicheSanteElectroPick => 'Choose electrophoresis';

  @override
  String get profileFicheSanteTaillePick => 'Choose your height';

  @override
  String profileFicheSanteTailleValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileFicheSanteConfirmTitle => 'Confirm?';

  @override
  String profileFicheSanteConfirmBody(String value) {
    return 'Save “$value” on your profile.';
  }

  @override
  String get profileFicheSanteConfirmAction => 'Confirm';

  @override
  String get profileFicheSanteCorrectAction => 'Correct';

  @override
  String get profilePatientSettingsHint =>
      'These options only apply to your patient follow-up on this device and account.';

  @override
  String get profileNotifGranted => 'Notifications allowed';

  @override
  String get profileNotifGrantedHint =>
      'Whether Fidel may remind you about doses';

  @override
  String get profileBatteryExempt => 'Unrestricted battery';

  @override
  String get profileBatteryExemptHint =>
      'Helps keep reminders working overnight';

  @override
  String get profileDiscreteNotif => 'Discreet notifications';

  @override
  String get profileDiscreteNotifHint =>
      'Sobriety-friendly wording without sensitive detail';

  @override
  String get alarmSettingsTitle => 'Alarm settings';

  @override
  String get alarmSettingsTileHint =>
      'Pre-alert, sound, snooze and permissions';

  @override
  String get alarmSettingsHint =>
      'Configure the dose alarm in Fidel. Pre-alert and confirmation notifications stay enabled.';

  @override
  String get alarmSettingsPreavis => 'Pre-alert';

  @override
  String get alarmSettingsPreavisHint => 'Notification before dose time';

  @override
  String get alarmSettingsSnooze => 'Snooze';

  @override
  String get alarmSettingsSnoozeHint => 'Delay when you choose “Later”';

  @override
  String alarmSettingsMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get alarmSettingsVibrate => 'Vibration';

  @override
  String get alarmSettingsVibrateHint => 'Vibrate during the H0 alarm';

  @override
  String get alarmSettingsCustomVoice => 'Use my reminder voice';

  @override
  String get alarmSettingsCustomVoiceHint =>
      'Otherwise Fidel’s default alarm sound';

  @override
  String get alarmSettingsCustomVoiceMissing => 'Record a custom voice first.';

  @override
  String get alarmSettingsExactTitle => 'Exact alarms required';

  @override
  String get alarmSettingsExactHint =>
      'Without this permission, Android may delay or block your medication alarms.';

  @override
  String get alarmSettingsExactCta => 'Allow exact alarms';

  @override
  String get alarmHealthTitle => 'Alarm health';

  @override
  String get alarmHealthTileHint => 'Permissions and OEM settings';

  @override
  String get alarmHealthHint =>
      'Make sure your phone lets Fidel ring on time — especially on Xiaomi, Samsung, Tecno and similar brands.';

  @override
  String get alarmHealthRefresh => 'Refresh';

  @override
  String get alarmHealthAllOk => 'Everything looks good for alarms';

  @override
  String get alarmHealthNeedsAttention => 'Some settings still block alarms';

  @override
  String get alarmHealthNotifTitle => 'Notifications';

  @override
  String get alarmHealthNotifHint =>
      'Pre-alert, H0 banner and H+5 confirmation';

  @override
  String get alarmHealthExactTitle => 'Exact alarms';

  @override
  String get alarmHealthExactHint => 'Fire at the scheduled time, even in Doze';

  @override
  String get alarmHealthBatteryTitle => 'Unrestricted battery';

  @override
  String get alarmHealthBatteryHint =>
      'Stops the OS from killing Fidel in the background';

  @override
  String get alarmHealthFsiTitle => 'Full-screen (lock screen)';

  @override
  String get alarmHealthFsiHint => 'Show the alarm over the lock screen';

  @override
  String get alarmHealthFixCta => 'Fix';

  @override
  String get alarmHealthOemTitle => 'Manufacturer settings';

  @override
  String get alarmHealthOemCta => 'Open autostart settings';

  @override
  String get alarmHealthOemXiaomi =>
      'On Xiaomi / Redmi / POCO: allow autostart and set Fidel to “No restrictions” in Battery.';

  @override
  String get alarmHealthOemHuawei =>
      'On Huawei / Honor: allow autostart and manual background activity for Fidel.';

  @override
  String get alarmHealthOemSamsung =>
      'On Samsung: in Battery, turn off optimization for Fidel and allow background activity.';

  @override
  String get alarmHealthOemOppo =>
      'On Oppo / Realme / OnePlus: allow autostart and remove Fidel from sleeping apps.';

  @override
  String get alarmHealthOemVivo =>
      'On Vivo / iQOO: allow background start and autostart for Fidel.';

  @override
  String get alarmHealthOemTranssion =>
      'On Tecno / Infinix / Itel: allow autostart and background activity for Fidel.';

  @override
  String get alarmHealthOemGeneric =>
      'On some phones, enable autostart / background activity for Fidel in manufacturer settings.';

  @override
  String get alarmHealthAppDetailsCta => 'Open app details';

  @override
  String get alarmRingStop => 'Stop';

  @override
  String get alarmRingSnooze => 'Later';

  @override
  String alarmRingBody(String clock) {
    return 'Time to take your dose (scheduled $clock).';
  }

  @override
  String alarmRingBodyDiscreet(String clock) {
    return 'It\'s time for your $clock reminder.';
  }

  @override
  String alarmRingTitleFallback(String clock) {
    return 'Dose · $clock';
  }

  @override
  String get profileContactsTitle => 'Emergency contacts';

  @override
  String get profileContactsTileHint => 'For SOS and escalation';

  @override
  String get profileContactsHint =>
      'These people may be reached if you trigger SOS. You stay in control of that gesture.';

  @override
  String get profileContactsEmpty => 'No contacts yet.';

  @override
  String get profileContactAdd => 'Add a contact';

  @override
  String get profileContactName => 'Name';

  @override
  String get profileContactRelation => 'Relation (e.g. son, neighbour)';

  @override
  String get profileContactDelete => 'Remove contact';

  @override
  String profileContactDeleteConfirm(String name) {
    return 'Remove $name from your emergency contacts?';
  }

  @override
  String get profileVoixTitle => 'Reminder voice';

  @override
  String get profileVoixTileHint => 'System or custom message';

  @override
  String get profileVoixHint =>
      'Sound for the local reminder. Record a short message or import a file (mp3, m4a…), max 2 MB.';

  @override
  String get profileVoixSystem => 'System voice';

  @override
  String get profileVoixSystemHint => 'Standard phone notification';

  @override
  String get profileVoixCustom => 'Custom voice';

  @override
  String get profileVoixCustomHint => 'Record or import audio';

  @override
  String get profileVoixCustomActive => 'Custom voice active';

  @override
  String get profileVoixPickFailed =>
      'Couldn’t read that file. Try again with mp3 or m4a.';

  @override
  String get profileVoixTooLarge => 'File too large — 2 MB max.';

  @override
  String get profileVoixChooseTitle => 'How do you want to add your voice?';

  @override
  String get profileVoixRecord => 'Record';

  @override
  String get profileVoixRecordHint => 'Speak into the mic (max 60 s)';

  @override
  String get profileVoixImport => 'Import a file';

  @override
  String get profileVoixImportHint => 'Pick audio already on the phone';

  @override
  String get profileVoixMicDenied =>
      'Allow the microphone to record your reminder voice.';

  @override
  String get profileVoixRecording => 'Recording…';

  @override
  String get profileVoixRecordReady => 'Tap to start';

  @override
  String get profileVoixStop => 'Stop';

  @override
  String get profileVoixStart => 'Start';

  @override
  String get profileVoixUseRecording => 'Use this recording';

  @override
  String get profileVoixRecordAgain => 'Record again';

  @override
  String get profileVoixRecordFailed => 'Recording failed. Try again.';

  @override
  String profileVoixSecondsLeft(int seconds) {
    return '$seconds s left';
  }

  @override
  String get profileContactsEmptyHint =>
      'Add at least one trusted person for SOS.';

  @override
  String get profileContactAddHint =>
      'Name, number and relation — used only if you trigger SOS.';

  @override
  String get profileSectionAlerts => 'Alerts & consent';

  @override
  String get profileConsentTitle => 'Alert preferences';

  @override
  String get profileConsentTileHint =>
      'Always ask before alerting a third party';

  @override
  String get profileConsentHint =>
      'By default, Fidel always asks before notifying someone. Turning off “always ask” enables an opt-in auto rule (e.g. 48h) — never pre-checked.';

  @override
  String get profileConsentAlwaysAsk => 'Always ask me';

  @override
  String get profileConsentAutoHint => 'Opt-in auto rule (48h delay)';

  @override
  String get profileAlertRappelMed => 'Medication reminder';

  @override
  String get profileAlertStock => 'Low stock';

  @override
  String get profileAlertConstanteUp => 'Improving vitals';

  @override
  String get profileAlertConstanteDown => 'Vitals to watch';

  @override
  String get profileAlertCheckin => 'Missed check-in';

  @override
  String get profileAlertPriseConfirmee =>
      'Notify caregivers when I confirm a dose';

  @override
  String get profileAlertPriseNonConfirmee =>
      'Alert caregivers if I don’t confirm (2 h)';

  @override
  String get profileAlertDepistage => 'Screening recommended';

  @override
  String get profileSectionCaregiver => 'Support someone';

  @override
  String get profileSyncTileHint => 'Enter a code to become a caregiver';

  @override
  String get profileDeleteTitle => 'Delete my account';

  @override
  String get profileDeleteTileHint => 'Permanently disable access';

  @override
  String get profileDeleteHint =>
      'Your account will be deactivated (soft delete). You can only sign back in if support reactivates you.';

  @override
  String get profileDeleteConfirm => 'Confirm deleting your Fidel account?';

  @override
  String get profileDeleteAction => 'Delete account';

  @override
  String get cercleMyPatients => 'People I support';

  @override
  String get cercleMyPatientsEmptyTitle => 'No one linked yet';

  @override
  String get cercleMyPatientsEmptyBody =>
      'Enter a Fidel code to join the follow-up of someone who shared it with you.';

  @override
  String get cercleMyCircle => 'My circle';

  @override
  String get cercleMyCircleHint =>
      'Your trusted network for follow-up and urgent situations.';

  @override
  String get cercleQuickLinks => 'Quick links';

  @override
  String get cercleLinkSyncHint => 'Enter another follow-up code';

  @override
  String get cercleLinkAidantsHint => 'Manage people who support you';

  @override
  String get cercleEmptyTitle => 'Start your circle';

  @override
  String get cercleEmptyBody =>
      'Activate your personal follow-up or connect to a loved one’s follow-up. Both capabilities can live on the same account.';

  @override
  String get cercleSosTitle => 'Trigger SOS';

  @override
  String get cercleAddEmergencyContact => 'Add an emergency contact';

  @override
  String get cercleSosSent => 'SOS triggered';

  @override
  String get cercleSosCancel => 'Cancel alert';

  @override
  String get cercleSosCancelled => 'SOS cancelled';

  @override
  String cercleSosCountdown(int seconds) {
    return 'You can still cancel for ${seconds}s.';
  }

  @override
  String get cercleDetailAdherence => 'Adherence';

  @override
  String get cercleTodaySection => 'Today';

  @override
  String get cercleDetailVitals => 'Vitals';

  @override
  String cercleAdherenceWindow(String from, String to) {
    return 'Observed window: $from to $to';
  }

  @override
  String get cercleAdherenceRate => 'Rate';

  @override
  String get cercleAdherenceConfirmed => 'Confirmed';

  @override
  String get cercleAdherenceMissed => 'Missed';

  @override
  String get cercleAdherencePending => 'Pending';

  @override
  String get cerclePermissionLocked => 'This data is not shared with you.';

  @override
  String get cerclePermissionLimited => 'Limited access';

  @override
  String get cercleNoVitals => 'No vitals shared yet.';

  @override
  String get cerclePatientUnavailable =>
      'This person is no longer in your circle.';

  @override
  String get reminderNotifTitle => 'Metformin · 500 mg';

  @override
  String get reminderNotifTitleDiscreet => 'Fidel · 08:00';

  @override
  String get reminderNotifBodyDiscreet => 'It\'s time for your 08:00 reminder.';

  @override
  String get reminderMarkTitle => 'Metformin · 500 mg';

  @override
  String get reminderMarkBodyDiscreet =>
      'Did you complete your 08:00 reminder?';

  @override
  String get reminderActionTaken => 'Taken';

  @override
  String get reminderActionSnooze => 'Later';
}

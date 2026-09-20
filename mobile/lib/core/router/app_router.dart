import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/auth_navigation.dart';
import '../../features/auth/presentation/forgot_password_email_screen.dart';
import '../../features/auth/presentation/forgot_password_otp_screen.dart';
import '../../features/auth/presentation/forgot_password_reset_screen.dart';
import '../../features/auth/presentation/google_legal_screen.dart';
import '../../features/auth/presentation/language_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_account_success_screen.dart';
import '../../features/auth/presentation/register_email_screen.dart';
import '../../features/auth/presentation/register_legal_screen.dart';
import '../../features/auth/presentation/register_otp_screen.dart';
import '../../features/auth/presentation/register_password_screen.dart';
import '../../features/home/presentation/add_traitement_screen.dart';
import '../../features/home/presentation/aidant_patient_detail_screen.dart';
import '../../features/home/presentation/aidants_invite_screen.dart';
import '../../features/home/presentation/aidants_list_screen.dart';
import '../../features/home/presentation/home_device_permissions_screen.dart';
import '../../features/home/presentation/home_notifications_screen.dart';
import '../../features/home/presentation/health_detail_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/manage_traitement_screen.dart';
import '../../features/home/presentation/profile_account_screen.dart';
import '../../features/home/presentation/alarm_health_screen.dart';
import '../../features/home/presentation/profile_alarm_settings_screen.dart';
import '../../features/home/presentation/profile_consent_screen.dart';
import '../../features/home/presentation/profile_contacts_urgence_screen.dart';
import '../../features/home/presentation/profile_delete_account_screen.dart';
import '../../features/home/presentation/profile_fiche_sante_screen.dart';
import '../../features/home/presentation/profile_patient_settings_screen.dart';
import '../../features/home/presentation/profile_voix_screen.dart';
import '../../features/home/presentation/alarm_ring_screen.dart';
import '../../features/home/presentation/sos_aidant_alarm_screen.dart';
import '../../features/home/domain/aidant_models.dart';
import '../../features/home/domain/dashboard_models.dart';
import '../../features/home/presentation/sync_screens.dart';
import '../../features/medicaments/presentation/medicament_wizard_screen.dart';
import '../../features/onboarding/presentation/onboarding_besoin_suivi_screen.dart';
import '../../features/onboarding/presentation/onboarding_gate_screen.dart';
import '../../features/onboarding/presentation/onboarding_infos_screen.dart';
import '../../features/onboarding/presentation/onboarding_permissions_screen.dart';
import '../../features/onboarding/presentation/onboarding_traitement_screen.dart';
import '../locale/locale_controller.dart';
import '../network/providers.dart';

/// Notifie go_router sans recréer l'instance (évite le flash noir).
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefresh>((ref) {
  final refresh = _RouterRefresh();
  // Uniquement au 1er choix de langue (null → fr/en), pas à chaque switch Profil.
  ref.listen<Locale?>(localeControllerProvider, (prev, next) {
    if (prev == null && next != null) refresh.ping();
  });
  ref.listen<AuthSession?>(authSessionProvider, (_, __) => refresh.ping());
  ref.onDispose(refresh.dispose);
  return refresh;
});

String _bootLocation({required bool hasLocale, AuthSession? session}) {
  if (!hasLocale) return '/language';
  if (session != null) return routeAfterAuth(session);
  return '/login';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: _bootLocation(
      hasLocale: ref.read(localeControllerProvider) != null,
      session: ref.read(authSessionProvider),
    ),
    refreshListenable: refresh,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final hasLocale = ref.read(localeControllerProvider) != null;
      final session = ref.read(authSessionProvider);

      if (!hasLocale && loc != '/language') {
        return '/language';
      }
      if (hasLocale && loc == '/language') {
        return session != null ? routeAfterAuth(session) : '/login';
      }

      final needsSession = loc == '/home' ||
          loc.startsWith('/home/') ||
          loc == '/alarm-ring' ||
          loc == '/auth/google-legal' ||
          loc.startsWith('/onboarding');
      if (needsSession) {
        final hasSession = await ref.read(tokenStorageProvider).hasSession();
        if (!hasSession) return '/login';
      }

      if (loc == '/login' && session != null) {
        return routeAfterAuth(session);
      }

      if (loc.startsWith('/home') &&
          session != null &&
          session.onboardingStep != 'termine') {
        return '/onboarding';
      }

      if (loc == '/' || loc.isEmpty) {
        if (!hasLocale) return '/language';
        if (session != null) return routeAfterAuth(session);
        final hasSession = await ref.read(tokenStorageProvider).hasSession();
        return hasSession ? '/onboarding' : '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/language',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: LanguageScreen(
            onContinue: (chosen) async {
              await ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(chosen);
            },
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: LoginScreen(
            onLoggedIn: () {
              final session = ref.read(authSessionProvider);
              if (session != null) {
                navigateAfterAuth(context, session);
              } else {
                context.go('/onboarding');
              }
            },
            onSignUp: () => context.push('/register'),
            onForgotPassword: () => context.push('/forgot-password'),
          ),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ForgotPasswordEmailScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password/otp',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ForgotPasswordOtpScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password/reset',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ForgotPasswordResetScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const RegisterEmailScreen(),
        ),
      ),
      GoRoute(
        path: '/register/otp',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const RegisterOtpScreen(),
        ),
      ),
      GoRoute(
        path: '/register/password',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const RegisterPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/register/legal',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const RegisterLegalScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/google-legal',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const GoogleLegalScreen(),
        ),
      ),
      GoRoute(
        path: '/register/account-success',
        pageBuilder: (context, state) => _successPage(
          state: state,
          child: const RegisterAccountSuccessScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingGateScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/infos',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingInfosScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/besoin-suivi',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingBesoinSuiviScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/traitement',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingTraitementScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/permissions',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const OnboardingPermissionsScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const HomeShell(),
        ),
      ),
      GoRoute(
        path: '/home/medicaments',
        pageBuilder: (context, state) {
          final id = state.extra as String? ?? '';
          return _softPage(
            state: state,
            child: MedicamentWizardScreen(traitementId: id),
          );
        },
      ),
      GoRoute(
        path: '/home/traitement',
        pageBuilder: (context, state) {
          final fromActivate = state.extra == true;
          return _softPage(
            state: state,
            child: AddTraitementScreen(fromActivate: fromActivate),
          );
        },
      ),
      GoRoute(
        path: '/home/traitement/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final initial = state.extra is DashboardTraitement
              ? state.extra as DashboardTraitement
              : null;
          return _softPage(
            state: state,
            child: ManageTraitementScreen(
              traitementId: id,
              initial: initial,
            ),
          );
        },
      ),
      GoRoute(
        path: '/home/permissions',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const HomeDevicePermissionsScreen(),
        ),
      ),
      GoRoute(
        path: '/home/sante/:typeCode',
        pageBuilder: (context, state) {
          final typeCode = state.pathParameters['typeCode'] ?? '';
          return _softPage(
            state: state,
            child: HealthDetailScreen(typeCode: typeCode),
          );
        },
      ),
      GoRoute(
        path: '/home/sync',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const SyncAidantScreen(),
        ),
      ),
      GoRoute(
        path: '/home/aidants',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const AidantsListScreen(),
        ),
      ),
      GoRoute(
        path: '/home/aidants/invite',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const AidantsInviteScreen(),
        ),
      ),
      GoRoute(
        path: '/home/share-code',
        redirect: (context, state) => '/home/aidants',
      ),
      GoRoute(
        path: '/home/notifications',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const HomeNotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/home/cercle/patient/:id',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final patient = extra is AidantPatient ? extra : null;
          return _softPage(
            state: state,
            child: AidantPatientDetailScreen(
              patientId: state.pathParameters['id'] ?? '',
              patient: patient,
              prenomHint: state.uri.queryParameters['prenom'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/alarm-ring',
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is AlarmRingArgs) {
            return _softPage(
              state: state,
              child: AlarmRingScreen(
                slot: extra.slot,
                alarmId: extra.alarmId,
              ),
            );
          }
          final q = state.uri.queryParameters;
          return _softPage(
            state: state,
            child: AlarmRingScreen.legacy(
              priseId: q['priseId'] ?? '',
              medicamentNom: q['nom'] ?? '',
              dosage: q['dosage'] ?? '',
              heurePrevueIso: q['heure'],
              alarmId: int.tryParse(q['alarmId'] ?? ''),
              maladieNom: q['maladie'],
              slotId: q['slotId'],
              traitementId: q['traitementId'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/sos-aidant',
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is ActiveSosAlert) {
            return _softPage(
              state: state,
              child: SosAidantAlarmScreen.fromAlert(extra),
            );
          }
          final q = state.uri.queryParameters;
          return _softPage(
            state: state,
            child: SosAidantAlarmScreen(
              sosId: q['sosId'] ?? '',
              patientId: q['patientId'] ?? '',
              patientPrenom: q['prenom'] ?? 'Patient',
            ),
          );
        },
      ),
      GoRoute(
        path: '/home/profile/account',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ProfileAccountScreen(),
        ),
      ),
      GoRoute(
        path: '/home/profile/patient-settings',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ProfilePatientSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/home/profile/fiche-sante',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ProfileFicheSanteScreen(),
        ),
      ),
      GoRoute(
        path: '/home/profile/alarm-settings',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ProfileAlarmSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/home/profile/alarm-health',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const AlarmHealthScreen(),
        ),
      ),
      GoRoute(
        path: '/home/profile/contacts',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ProfileContactsUrgenceScreen(),
        ),
      ),
      GoRoute(
        path: '/home/profile/voix',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ProfileVoixScreen(),
        ),
      ),
      GoRoute(
        path: '/home/profile/consent',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ProfileConsentScreen(),
        ),
      ),
      GoRoute(
        path: '/home/profile/delete',
        pageBuilder: (context, state) => _softPage(
          state: state,
          child: const ProfileDeleteAccountScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Text(state.error?.toString() ?? 'Not found'),
      ),
    ),
  );
});

CustomTransitionPage<void> _softPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _successPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 560),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

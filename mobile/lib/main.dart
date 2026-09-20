import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/locale/locale_controller.dart';
import 'core/network/api_client.dart';
import 'core/network/providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/home/presentation/alarm_ring_screen.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'services/check_in_reminder_service.dart';
import 'services/live_alarm_test.dart';
import 'services/push_messaging_service.dart';
import 'services/reminder_sync.dart';
import 'services/server_clock.dart';
import 'services/sos_aidant_alarm.dart';
import 'services/sync_lifecycle_binder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  // DateFormat (Accueil / Soins) exige les symboles FR+EN avant tout switch.
  await ensureDateFormatting('fr');
  await ensureDateFormatting('en');
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStorage();
  final clock = ServerClock(prefs)..load();
  final api = ApiClient(
    tokenStorage: tokens,
    onResponseHeaders: (headers) {
      clock.observeHttpDate(headers.value('date'));
    },
  );
  final restored = await AuthRepository(
    apiClient: api,
    tokenStorage: tokens,
  ).restoreSession();

  await Alarm.init();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tokenStorageProvider.overrideWithValue(tokens),
      serverClockProvider.overrideWithValue(clock),
      apiClientProvider.overrideWithValue(api),
      restoredAuthSessionProvider.overrideWithValue(restored),
    ],
  );

  final alarms = container.read(reminderAlarmServiceProvider);
  await alarms.init(
    onResponse: (response) {
      unawaited(ReminderActionDispatcher(container).handle(response));
    },
  );
  await SosAidantAlarm.bindPlugin(alarms.plugin);
  // Réarme H0 / préavis / mark depuis le cache local (reboot / kill),
  // sans attendre le load home ni le réseau.
  try {
    await alarms.restoreFromLocalCache();
  } catch (e, st) {
    debugPrint('main: restoreFromLocalCache failed: $e\n$st');
  }
  try {
    final dispatcher = ReminderActionDispatcher(container);
    void dispatchCheckInAction(String actionId) {
      unawaited(
        dispatcher.handle(
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: actionId,
            payload: CheckInReminderService.payloadJson(),
          ),
        ),
      );
    }

    CheckInReminderService.bindNativeActionHandler(dispatchCheckInAction);
    final pending = await CheckInReminderService.consumePendingNativeAction();
    if (pending != null) {
      dispatchCheckInAction(pending);
    }

    final checkIn = container.read(checkInReminderServiceProvider);
    await checkIn.ensureChannel();
    // Retire une éventuelle notif debug forcée des builds précédents.
    await checkIn.dismissDebugNotification();
  } catch (e, st) {
    debugPrint('main: checkIn channel init failed: $e\n$st');
  }
  unawaited(maybeRunLiveAlarmTest(alarms));

  try {
    await container.read(pushMessagingServiceProvider).init();
    unawaited(container.read(pushMessagingServiceProvider).pollActiveSos());
  } catch (e, st) {
    debugPrint('main: push messaging init failed: $e\n$st');
  }

  final router = container.read(appRouterProvider);
  bindAlarmRingingNavigation(router);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FidelApp(),
    ),
  );
}

class FidelApp extends ConsumerWidget {
  const FidelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return SyncLifecycleBinder(
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        themeAnimationDuration: const Duration(milliseconds: 350),
        themeAnimationCurve: Curves.easeOutCubic,
        locale: locale ?? const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          // Fond bleu pendant les transitions (évite le flash noir Android).
          return ColoredBox(
            color: AppColors.primary,
            child: MediaQuery(
              data: media.copyWith(
                textScaler: media.textScaler.clamp(
                  minScaleFactor: 1.0,
                  maxScaleFactor: 1.6,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../features/home/domain/aidant_models.dart';

/// Alarme / notif haute priorité côté aidant quand un SOS arrive.
class SosAidantAlarm {
  static const channelId = 'fidel_sos_aidant';
  static const channelName = 'SOS patient';
  static const notificationIdBase = 92002000;

  /// Plugin principal (rappels) — taps routés via [ReminderActionDispatcher].
  static FlutterLocalNotificationsPlugin? _boundPlugin;

  /// Fallback isolate background (pas d’accès au plugin main).
  static final FlutterLocalNotificationsPlugin _backgroundPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _backgroundInitialized = false;

  static String? _lastPushedSosId;

  /// Lie le plugin initialisé par [ReminderAlarmService] (appel depuis `main`).
  static Future<void> bindPlugin(FlutterLocalNotificationsPlugin plugin) async {
    _boundPlugin = plugin;
    await ensureChannel(plugin);
  }

  static Future<void> _ensureBackgroundPlugin() async {
    if (_backgroundInitialized) return;
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _backgroundPlugin.initialize(initSettings);
    await ensureChannel(_backgroundPlugin);
    _backgroundInitialized = true;
  }

  static Future<FlutterLocalNotificationsPlugin> _pluginForShow() async {
    final bound = _boundPlugin;
    if (bound != null) return bound;
    await _ensureBackgroundPlugin();
    return _backgroundPlugin;
  }

  static Future<void> ensureChannel(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    const android = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Alertes SOS des patients accompagnés',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(android);
  }

  static Future<void> show(ActiveSosAlert alert) async {
    final plugin = await _pluginForShow();

    final id = notificationIdBase + (alert.sosId.hashCode.abs() % 1000);
    await plugin.show(
      id,
      'SOS — ${alert.patientPrenom}',
      'Ton proche a besoin d’aide. Ouvre Fidel pour acquitter.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Alertes SOS des patients accompagnés',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
          playSound: true,
          onlyAlertOnce: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'sos:${alert.sosId}:${alert.patientId}:${alert.patientPrenom}',
    );
    debugPrint('SosAidantAlarm shown for ${alert.sosId}');
  }

  static Future<void> cancel(String sosId) async {
    final plugin = await _pluginForShow();
    final id = notificationIdBase + (sosId.hashCode.abs() % 1000);
    await plugin.cancel(id);
  }
}

/// Ouvre `/sos-aidant` sans rejouer l’alarme. Anti-doublon si déjà sur cet SOS.
void openSosAidantScreen(GoRouter router, ActiveSosAlert alert) {
  if (alert.sosId.isEmpty) return;

  void push() {
    final path = router.state.uri.path;
    if (path == '/sos-aidant' && SosAidantAlarm._lastPushedSosId == alert.sosId) {
      return;
    }
    SosAidantAlarm._lastPushedSosId = alert.sosId;
    router.push('/sos-aidant', extra: alert);
  }

  // Cold start : attendre une frame pour que le navigator soit monté.
  WidgetsBinding.instance.addPostFrameCallback((_) => push());
}

/// Parse payload `sos:id:patientId:prenom`.
ActiveSosAlert? parseSosPayload(String? payload) {
  if (payload == null || !payload.startsWith('sos:')) return null;
  final parts = payload.split(':');
  if (parts.length < 4) return null;
  return ActiveSosAlert(
    sosId: parts[1],
    patientId: parts[2],
    patientPrenom: parts.sublist(3).join(':'),
  );
}

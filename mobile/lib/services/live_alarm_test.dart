import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_alarm_service.dart';

/// Test live Pixel — activer avec `--dart-define=LIVE_ALARM_TEST=1`.
///
/// Timeline : préavis ~45 s → alarme H0 ~90 s → mark H0+5 min.
Future<void> maybeRunLiveAlarmTest(ReminderAlarmService alarms) async {
  const enabled = bool.fromEnvironment('LIVE_ALARM_TEST');
  if (!enabled) return;

  // Laisser le premier sync home se terminer, sans être écrasé par stopAll.
  await Future<void>.delayed(const Duration(seconds: 12));

  const priseId = 'live-alarm-test-prise';
  final now = DateTime.now();
  final h0 = now.add(const Duration(seconds: 90));
  final preavisAt = now.add(const Duration(seconds: 45));
  final markAt = h0.add(ReminderAlarmService.markDelay);

  await alarms.cancelPrise(priseId);
  await alarms.ensureNotificationPermission();
  await alarms.ensureExactAlarmPermission();

  final plugin = FlutterLocalNotificationsPlugin();
  final preavisId = ReminderAlarmService.preavisNotificationId(priseId);
  final alarmId = ReminderAlarmService.alarmNotificationId(priseId);
  final markId = ReminderAlarmService.markNotificationId(priseId);

  await plugin.zonedSchedule(
    preavisId,
    'Dans ~45 s',
    'Test Fidel · 1 cp — prise à ${_fmt(h0)}',
    tz.TZDateTime.from(preavisAt, tz.local),
    NotificationDetails(
      android: AndroidNotificationDetails(
        ReminderAlarmService.preavisChannelId,
        ReminderAlarmService.preavisChannelName,
        icon: 'ic_stat_rappel',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: jsonEncode({
      'kind': ReminderAlarmService.kindPreavis,
      'priseId': priseId,
    }),
  );

  final audio = await alarms.alarmPrefs.resolveAudioPath();
  await Alarm.set(
    alarmSettings: AlarmSettings(
      id: alarmId,
      dateTime: h0,
      assetAudioPath: audio,
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        fadeDuration: const Duration(seconds: 3),
        volume: 0.95,
        volumeEnforced: true,
      ),
      notificationSettings: const NotificationSettings(
        title: 'Test Fidel · 1 cp',
        body: 'Alarme live test — Arrêter pour stopper',
        stopButton: 'Arrêter',
      ),
      payload: jsonEncode({
        'kind': ReminderAlarmService.kindAlarm,
        'priseId': priseId,
        'medicamentNom': 'Test Fidel',
        'dosage': '1 cp',
        'heurePrevue': h0.toIso8601String(),
      }),
      warningNotificationOnKill: Platform.isIOS,
    ),
  );

  await plugin.zonedSchedule(
    markId,
    'Test Fidel · 1 cp',
    'Confirme si tu as pris cette dose (test live).',
    tz.TZDateTime.from(markAt, tz.local),
    NotificationDetails(
      android: AndroidNotificationDetails(
        ReminderAlarmService.markChannelId,
        ReminderAlarmService.markChannelName,
        icon: 'ic_stat_rappel',
        importance: Importance.high,
        priority: Priority.high,
        actions: ReminderAlarmService.markAndroidActions(en: false),
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: jsonEncode({
      'kind': ReminderAlarmService.kindMark,
      'priseId': priseId,
      'medicamentNom': 'Test Fidel',
      'dosage': '1 cp',
    }),
  );

  // ignore: avoid_print
  print(
    'LIVE_ALARM_TEST scheduled: preavis@$preavisAt H0@$h0 mark@$markAt '
    '(ids preavis=$preavisId alarm=$alarmId mark=$markId)',
  );
}

String _fmt(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

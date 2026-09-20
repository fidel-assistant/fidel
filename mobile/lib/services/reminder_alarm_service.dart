import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/database/app_database.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/home/data/home_repository.dart';
import 'alarm_prefs.dart';
import 'check_in_reminder_service.dart';
import 'dose_slot.dart';
import 'reminder_sync_perf.dart';
import 'scheduled_dose.dart';
import 'sync_engine.dart';
import 'sync_outbox.dart';

typedef ReminderNotificationCallback = void Function(NotificationResponse);

/// Rappels médicaments — préavis H0−Δ + alarme package H0 + marquage H0+5.
class ReminderAlarmService {
  ReminderAlarmService(this._prefs);

  static const preavisChannelId = 'fidel_med_preavis';
  static const preavisChannelName = 'Préavis médicaments';
  static const markChannelId = 'fidel_med_mark';
  static const markChannelName = 'Confirmation de prise';

  static const kindPreavis = 'preavis';
  static const kindAlarm = 'alarm';
  static const kindMark = 'mark';
  static const markDelay = Duration(minutes: 5);

  static const actionConfirm = 'prise_confirm';
  static const actionSnooze = 'prise_snooze';
  static const iosCategory = 'fidel_prise';
  static const _idsKey = 'reminder_notif_ids_v3';
  static const _alarmPkgIdsKey = 'reminder_alarm_pkg_ids_v1';
  static const _snapshotKey = 'reminder_dose_snapshot_v1';
  static const _doseCacheKey = 'reminder_doses_cache_v1';
  static const discreetPrefsKey = 'notifications_discretes';

  static const _labelConfirmFr = "J'ai pris";
  static const _labelSnoozeFr = 'Plus tard';
  static const _labelConfirmEn = 'Taken';
  static const _labelSnoozeEn = 'Later';
  static const _labelStopFr = 'Arrêter';
  static const _labelStopEn = 'Stop';

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Exposé pour le rappel check-in (même plugin / même init).
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  late final AlarmPrefs alarmPrefs = AlarmPrefs(_prefs);

  bool _ready = false;
  ReminderNotificationCallback? onResponse;

  bool get isReady => _ready;

  bool get _en => (_prefs.getString('fa_locale_code') ?? 'fr') == 'en';

  /// Hash stable pour ids notif/alarme — passer [slotId] (legacy: priseId).
  static int alarmNotificationId(String slotId) {
    var hash = 0;
    for (final cu in slotId.codeUnits) {
      hash = 0x7fffffff & (hash * 31 + cu);
    }
    return hash == 0 ? 1 : hash;
  }

  static int markNotificationId(String slotId) {
    final alarm = alarmNotificationId(slotId);
    final mark = 0x7fffffff & (alarm ^ 0x5f5f5f5f);
    return mark == 0 || mark == alarm ? (alarm == 1 ? 2 : 1) : mark;
  }

  static int preavisNotificationId(String slotId) {
    final alarm = alarmNotificationId(slotId);
    var preavis = 0x7fffffff & (alarm ^ 0x11111111);
    if (preavis == 0 || preavis == alarm) {
      preavis = alarm == 1 ? 3 : 1;
    }
    final mark = markNotificationId(slotId);
    if (preavis == mark) {
      preavis = 0x7fffffff & (preavis ^ 0x22222222);
      if (preavis == 0 || preavis == alarm || preavis == mark) {
        preavis = alarm == 1 ? 4 : (alarm == 2 ? 4 : 2);
      }
    }
    return preavis;
  }

  /// @deprecated Prefer [alarmNotificationId] / [markNotificationId].
  static int notificationIdFor(String slotId) => alarmNotificationId(slotId);

  static List<AndroidNotificationAction> markAndroidActions({
    required bool en,
  }) =>
      [
        AndroidNotificationAction(
          actionConfirm,
          en ? _labelConfirmEn : _labelConfirmFr,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze,
          en ? _labelSnoozeEn : _labelSnoozeFr,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ];

  String _formatClock(DateTime when) {
    final local = when.isUtc ? when.toLocal() : when;
    return DateFormat.Hm(_en ? 'en' : 'fr').format(local);
  }

  ({String title, String body}) _copyForSlot({
    required DoseSlot slot,
    required String kind,
  }) {
    final clock = _formatClock(slot.heurePrevue);
    final maladie = slot.maladieNom.trim();
    final meds = slot.medsBody(en: _en);
    final delta = alarmPrefs.preavisMinutes;

    if (kind == kindPreavis) {
      if (discreet) {
        return (
          title: _en ? 'Soon · $clock' : 'Bientôt · $clock',
          body: _en
              ? 'Reminder in $delta min ($clock).'
              : 'Rappel dans $delta min ($clock).',
        );
      }
      final head = maladie.isNotEmpty ? maladie : clock;
      return (
        title: _en ? 'In $delta min — $head' : 'Dans $delta min — $head',
        body: meds.isEmpty
            ? (_en ? 'Dose at $clock.' : 'Prise à $clock.')
            : (_en
                ? '$meds\nScheduled $clock.'
                : '$meds\nPrévu à $clock.'),
      );
    }

    if (kind == kindAlarm) {
      if (discreet) {
        return (
          title: 'Fidel · $clock',
          body: _en
              ? "It's time for your $clock reminder."
              : "C'est l'heure de ton rappel de $clock.",
        );
      }
      final title = maladie.isNotEmpty
          ? (_en ? '$maladie — it\'s time' : '$maladie — c’est l’heure')
          : (_en ? 'Dose · $clock' : 'Prise · $clock');
      return (
        title: title,
        body: meds.isEmpty
            ? (_en
                ? 'Time to take your dose (scheduled $clock).'
                : 'C’est l’heure de ta prise (prévue à $clock).')
            : meds,
      );
    }

    // mark
    if (discreet) {
      return (
        title: _en ? 'Confirm · $clock' : 'Confirmer · $clock',
        body: _en
            ? 'Did you complete your $clock reminder?'
            : 'As-tu bien fait ton rappel de $clock ?',
      );
    }
    final label = maladie.isNotEmpty ? maladie : clock;
    return (
      title: _en
          ? 'Have you taken your medication ($label)?'
          : 'Avez-vous pris vos médicaments ($label) ?',
      body: meds.isEmpty
          ? (_en
              ? 'Confirm if you took this dose (scheduled $clock).'
              : 'Confirme si tu as pris cette dose (prévue à $clock).')
          : meds,
    );
  }

  Future<void> init({ReminderNotificationCallback? onResponse}) async {
    this.onResponse = onResponse;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_fidel');
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          iosCategory,
          actions: [
            DarwinNotificationAction.plain(actionConfirm, _labelConfirmFr),
            DarwinNotificationAction.plain(actionSnooze, _labelSnoozeFr),
          ],
        ),
        DarwinNotificationCategory(
          CheckInReminderService.iosCategory,
          actions: CheckInReminderService.iosActions(en: false),
        ),
      ],
    );

    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (r) => this.onResponse?.call(r),
      onDidReceiveBackgroundNotificationResponse: reminderBackgroundHandler,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        preavisChannelId,
        preavisChannelName,
        description: 'Avertissement avant l’heure de prise',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        markChannelId,
        markChannelName,
        description: 'Confirmation de prise (H+5)',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    _ready = true;
  }

  Future<void> setDiscreet(bool value) async {
    await _prefs.setBool(discreetPrefsKey, value);
  }

  bool get discreet => _prefs.getBool(discreetPrefsKey) ?? false;

  Future<bool> ensureNotificationPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == false) {
        await android?.requestNotificationsPermission();
      }
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final next = await Permission.notification.request();
    return next.isGranted;
  }

  Future<bool> ensureExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;
    final next = await Permission.scheduleExactAlarm.request();
    return next.isGranted;
  }

  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    return Permission.scheduleExactAlarm.isGranted;
  }

  Future<void> cancelAllTracked() async {
    final ringingIds = _currentRingingIds();
    final ids = _trackedIds();
    for (final id in ids) {
      await _plugin.cancel(id);
    }
    await _prefs.setString(_idsKey, '[]');

    final alarmIds = _trackedAlarmPkgIds();
    for (final id in alarmIds) {
      if (ScheduledDose.shouldProtectRingingAlarm(
        alarmId: id,
        ringingIds: ringingIds,
      )) {
        continue;
      }
      try {
        await Alarm.stop(id);
      } catch (e) {
        debugPrint('ReminderAlarmService: Alarm.stop($id) failed: $e');
      }
    }
    // Conserve les ids encore en train de sonner.
    final kept = alarmIds
        .where(
          (id) => ScheduledDose.shouldProtectRingingAlarm(
            alarmId: id,
            ringingIds: ringingIds,
          ),
        )
        .toList();
    await _prefs.setString(_alarmPkgIdsKey, jsonEncode(kept));
    await _prefs.setString(_snapshotKey, '{}');
    await _prefs.setString(_doseCacheKey, '[]');
  }

  /// Cold start / après reboot : réarme depuis le cache local **sans** API home.
  ///
  /// [force] contourne le early-return fingerprint pour replanifier même si
  /// les signatures n’ont pas changé (AlarmManager / FLN peuvent avoir été
  /// perdus alors que le snapshot prefs est intact).
  Future<void> restoreFromLocalCache() async {
    if (!_ready) return;
    final cached = _loadDoseCache();
    if (cached.isEmpty) {
      debugPrint('ReminderAlarmService: restoreFromLocalCache empty');
      return;
    }
    final now = DateTime.now();
    final future = ReminderSyncPerf.filterHorizon(cached, now);
    debugPrint(
      'ReminderAlarmService: restoreFromLocalCache '
      '${future.length}/${cached.length} doses '
      '(horizon=${ReminderSyncPerf.scheduleHorizon.inHours}h)',
    );
    await rescheduleAll(future, force: true);
  }

  /// Reschedule différentiel par [DoseSlot] (maladie × heure).
  ///
  /// [force] : réarme toutes les doses non-ringing (boot / cold start).
  Future<void> rescheduleAll(
    List<ScheduledDose> doses, {
    bool force = false,
  }) async {
    if (!_ready) return;
    await ensureNotificationPermission();
    await ensureExactAlarmPermission();

    final audioKey = await alarmPrefs.resolveAudioPath();
    final preavisMin = alarmPrefs.preavisMinutes;
    final isDiscreet = discreet;

    // Toujours rafraîchir le cache doses plates (restore cold start).
    await _saveDoseCache(doses);

    final slots = DoseSlot.groupScheduled(doses);
    final desiredSigs = <String, String>{};
    final desired = <String, DoseSlot>{};
    for (final s in slots) {
      desired[s.slotId] = s;
      desiredSigs[s.slotId] = DoseSlot.signature(
        slot: s,
        preavisMinutes: preavisMin,
        discreet: isDiscreet,
        audioKey: audioKey,
      );
    }

    final previous = _loadSnapshot();
    if (!force &&
        ScheduledDose.globalFingerprint(previous) ==
            ScheduledDose.globalFingerprint(desiredSigs)) {
      debugPrint(
        'ReminderAlarmService: rescheduleAll skip (unchanged, '
        '${desiredSigs.length} slots / ${doses.length} doses)',
      );
      return;
    }

    final ringingIds = _currentRingingIds();
    final ids = _trackedIds();
    final alarmIds = _trackedAlarmPkgIds();
    final now = tz.TZDateTime.now(tz.local);

    var removed = 0;
    var updated = 0;
    var skipped = 0;
    var protectedRinging = 0;

    // Retraits (anciens priseId ou slotId absents).
    for (final key in previous.keys.toList()) {
      if (desired.containsKey(key)) continue;
      final alarmId = alarmNotificationId(key);
      if (ScheduledDose.shouldProtectRingingAlarm(
        alarmId: alarmId,
        ringingIds: ringingIds,
      )) {
        await _cancelFlnOnly(key, ids);
        protectedRinging++;
      } else {
        await _cancelSlotLocal(key, ids, alarmIds, stopAlarm: true);
        removed++;
      }
    }

    // Ajouts / mises à jour.
    for (final entry in desired.entries) {
      final slotId = entry.key;
      final slot = entry.value;
      final sig = desiredSigs[slotId]!;
      final alarmId = alarmNotificationId(slotId);
      final preavisId = preavisNotificationId(slotId);
      final markId = markNotificationId(slotId);
      final unchanged = previous[slotId] == sig;
      final stillTracked = alarmIds.contains(alarmId) ||
          ids.contains(preavisId) ||
          ids.contains(markId);

      if (!force && unchanged && stillTracked) {
        skipped++;
        continue;
      }

      if (ScheduledDose.shouldProtectRingingAlarm(
        alarmId: alarmId,
        ringingIds: ringingIds,
      )) {
        if (!alarmIds.contains(alarmId)) alarmIds.add(alarmId);
        protectedRinging++;
        continue;
      }

      await _cancelSlotLocal(slotId, ids, alarmIds, stopAlarm: true);
      await _scheduleTriple(
        slot,
        now: now,
        track: ids,
        trackAlarms: alarmIds,
      );
      updated++;
    }

    await _prefs.setString(_idsKey, jsonEncode(ids));
    await _prefs.setString(_alarmPkgIdsKey, jsonEncode(alarmIds));
    await _saveSnapshot(desiredSigs);

    debugPrint(
      'ReminderAlarmService: rescheduleAll diff '
      'force=$force desired=${desired.length} updated=$updated '
      'removed=$removed skipped=$skipped protectRing=$protectedRinging '
      '(tz=${tz.local.name}, now=$now, Δ=$preavisMin)',
    );
  }

  /// Snooze / one-shot : H0' = [slot.heurePrevue], préavis = H0'−Δ.
  /// Le marquage H+5 est ancré à la sonnerie réelle ([scheduleMarkAfterRing]).
  Future<void> scheduleOneShotSlot(DoseSlot slot) async {
    if (!_ready) return;
    await ensureExactAlarmPermission();
    final now = tz.TZDateTime.now(tz.local);
    final ids = _trackedIds();
    final alarmIds = _trackedAlarmPkgIds();
    await _cancelSlotLocal(slot.slotId, ids, alarmIds, stopAlarm: true);

    await _scheduleTriple(
      slot,
      now: now,
      track: ids,
      trackAlarms: alarmIds,
    );
    await _prefs.setString(_idsKey, jsonEncode(ids));
    await _prefs.setString(_alarmPkgIdsKey, jsonEncode(alarmIds));

    final snap = _loadSnapshot();
    snap[slot.slotId] = DoseSlot.signature(
      slot: slot,
      preavisMinutes: alarmPrefs.preavisMinutes,
      discreet: discreet,
      audioKey: await alarmPrefs.resolveAudioPath(),
    );
    await _saveSnapshot(snap);

    final cache = _loadDoseCache();
    final priseSet = slot.priseIds.toSet();
    final next = [
      for (final d in cache)
        if (!priseSet.contains(d.priseId)) d,
      for (final item in slot.items)
        ScheduledDose(
          priseId: item.priseId,
          medicamentNom: item.medicamentNom,
          dosage: item.dosage,
          heurePrevue: slot.heurePrevue,
          traitementId: slot.traitementId,
          maladieNom: slot.maladieNom,
        ),
    ];
    await _saveDoseCache(next);
  }

  /// Compat : one-shot pour une seule prise.
  Future<void> scheduleOneShot(ScheduledDose dose) async {
    final slot = DoseSlot.groupScheduled([dose]).first;
    await scheduleOneShotSlot(slot);
  }

  Future<void> cancelSlot(String slotId) async {
    final ids = _trackedIds();
    final alarmIds = _trackedAlarmPkgIds();
    await _cancelSlotLocal(slotId, ids, alarmIds, stopAlarm: true);
    await _prefs.setString(_idsKey, jsonEncode(ids));
    await _prefs.setString(_alarmPkgIdsKey, jsonEncode(alarmIds));
    final snap = _loadSnapshot()..remove(slotId);
    await _saveSnapshot(snap);
  }

  /// Annule le préavis du slot dès que l’alarme H0 sonne.
  Future<void> cancelPreavisForSlot(String slotId) async {
    if (slotId.isEmpty) return;
    final ids = _trackedIds();
    final preavisId = preavisNotificationId(slotId);
    await _plugin.cancel(preavisId);
    ids.remove(preavisId);
    await _prefs.setString(_idsKey, jsonEncode(ids));
  }

  /// Compat legacy (annule en traitant l’id comme clé snapshot).
  Future<void> cancelPrise(String priseOrSlotId) async {
    await cancelSlot(priseOrSlotId);
    await _saveDoseCache(
      _loadDoseCache().where((d) => d.priseId != priseOrSlotId).toList(),
    );
  }

  Future<void> _cancelFlnOnly(String slotId, List<int> ids) async {
    final markId = markNotificationId(slotId);
    final preavisId = preavisNotificationId(slotId);
    await _plugin.cancel(preavisId);
    await _plugin.cancel(markId);
    ids
      ..remove(preavisId)
      ..remove(markId);
  }

  Future<void> _cancelSlotLocal(
    String slotId,
    List<int> ids,
    List<int> alarmIds, {
    required bool stopAlarm,
  }) async {
    final alarmId = alarmNotificationId(slotId);
    final markId = markNotificationId(slotId);
    final preavisId = preavisNotificationId(slotId);
    await _plugin.cancel(preavisId);
    await _plugin.cancel(markId);
    ids
      ..remove(preavisId)
      ..remove(markId)
      ..remove(alarmId);
    alarmIds.remove(alarmId);
    if (stopAlarm) {
      try {
        await Alarm.stop(alarmId);
      } catch (e) {
        debugPrint('ReminderAlarmService: Alarm.stop($alarmId) failed: $e');
      }
    }
  }

  Set<int> _currentRingingIds() {
    try {
      return Alarm.ringing.value.alarms.map((a) => a.id).toSet();
    } catch (_) {
      return {};
    }
  }

  Map<String, String> _loadSnapshot() {
    final raw = _prefs.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveSnapshot(Map<String, String> snapshot) async {
    await _prefs.setString(_snapshotKey, jsonEncode(snapshot));
  }

  List<ScheduledDose> _loadDoseCache() =>
      ScheduledDose.decodeList(_prefs.getString(_doseCacheKey));

  Future<void> _saveDoseCache(List<ScheduledDose> doses) async {
    await _prefs.setString(_doseCacheKey, ScheduledDose.encodeList(doses));
  }

  /// Annule préavis + alarme package + mark (isolate background).
  static Future<void> cancelBothForSlot(String slotId) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(preavisNotificationId(slotId));
    await plugin.cancel(markNotificationId(slotId));
    try {
      await Alarm.stop(alarmNotificationId(slotId));
    } catch (_) {}
  }

  /// @deprecated Prefer [cancelBothForSlot].
  static Future<void> cancelBothForPrise(String priseOrSlotId) =>
      cancelBothForSlot(priseOrSlotId);

  static Future<void> cancelNotificationId(int id) async {
    await FlutterLocalNotificationsPlugin().cancel(id);
  }

  /// Annule uniquement la notif de marquage H+5 du slot.
  static Future<void> cancelMarkStatic(String slotId) async {
    if (slotId.isEmpty) return;
    await FlutterLocalNotificationsPlugin().cancel(markNotificationId(slotId));
  }

  /// Annule uniquement le préavis (appelable hors instance, isolate / ring).
  static Future<void> cancelPreavisStatic(String slotId) async {
    if (slotId.isEmpty) return;
    await FlutterLocalNotificationsPlugin().cancel(preavisNotificationId(slotId));
  }

  /// Quand H0 sonne : ancre le marquage à now+5 (pas à l’ancienne heure prévue).
  ///
  /// Si l’utilisateur reporte (« Plus tard »), [cancelSlot] / snooze annule ce mark
  /// avant de replanifier la prochaine sonnerie.
  Future<void> scheduleMarkAfterRing(DoseSlot slot) async {
    if (!_ready || slot.slotId.isEmpty) return;
    final ids = _trackedIds();
    final markId = markNotificationId(slot.slotId);
    await _plugin.cancel(markId);
    ids.remove(markId);

    final when = tz.TZDateTime.now(tz.local).add(markDelay);
    final ok = await _scheduleMark(slot, when: when);
    if (ok) {
      ids.add(markId);
      await _prefs.setString(_idsKey, jsonEncode(ids));
      debugPrint(
        'ReminderAlarmService: mark after ring slot=${slot.slotId} at $when',
      );
    }
  }

  /// Compat pour isolate / navigation sans instance prête.
  static Future<void> scheduleMarkAfterRingStatic(DoseSlot slot) async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = ReminderAlarmService(prefs);
    await alarms.init();
    await alarms.scheduleMarkAfterRing(slot);
  }

  Future<({int preavis, int alarms, int marks})> _scheduleTriple(
    DoseSlot slot, {
    required tz.TZDateTime now,
    required List<int> track,
    required List<int> trackAlarms,
  }) async {
    final h0 = tz.TZDateTime.from(slot.heurePrevue.toLocal(), tz.local);
    final preavisAt = h0.subtract(Duration(minutes: alarmPrefs.preavisMinutes));
    var preavis = 0;
    var alarms = 0;
    const marks = 0;

    if (preavisAt.isAfter(now) && preavisAt.isBefore(h0)) {
      final ok = await _schedulePreavis(slot, when: preavisAt);
      if (ok) {
        track.add(preavisNotificationId(slot.slotId));
        preavis = 1;
      }
    }

    if (h0.isAfter(now)) {
      final ok = await _scheduleAlarmRing(slot, when: h0);
      if (ok) {
        trackAlarms.add(alarmNotificationId(slot.slotId));
        alarms = 1;
      }
    }

    // Mark H+5 : planifié uniquement quand l’alarme sonne vraiment
    // (voir [scheduleMarkAfterRing]) — sinon un « Plus tard » laisse
    // apparaître la notif de l’ancienne H0.
    return (preavis: preavis, alarms: alarms, marks: marks);
  }

  Future<bool> _schedulePreavis(
    DoseSlot slot, {
    required tz.TZDateTime when,
  }) async {
    final id = preavisNotificationId(slot.slotId);
    final copy = _copyForSlot(slot: slot, kind: kindPreavis);
    final payload = jsonEncode(slot.toPayload(kind: kindPreavis));

    try {
      await _plugin.zonedSchedule(
        id,
        copy.title,
        copy.body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            preavisChannelId,
            preavisChannelName,
            channelDescription: 'Avertissement avant l’heure de prise',
            icon: 'ic_stat_rappel',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      return true;
    } catch (e, st) {
      debugPrint('ReminderAlarmService: preavis schedule failed $id: $e\n$st');
      return false;
    }
  }

  Future<bool> _scheduleAlarmRing(
    DoseSlot slot, {
    required tz.TZDateTime when,
  }) async {
    final id = alarmNotificationId(slot.slotId);
    final copy = _copyForSlot(slot: slot, kind: kindAlarm);
    final audioPath = await alarmPrefs.resolveAudioPath();
    final payload = jsonEncode(slot.toPayload(kind: kindAlarm));

    try {
      final settings = AlarmSettings(
        id: id,
        dateTime: when.toLocal(),
        assetAudioPath: audioPath,
        loopAudio: true,
        vibrate: alarmPrefs.vibrate,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          fadeDuration: const Duration(seconds: 4),
          volume: 0.95,
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: copy.title,
          body: copy.body,
          stopButton: _en ? _labelStopEn : _labelStopFr,
        ),
        payload: payload,
      );
      await Alarm.set(alarmSettings: settings);
      return true;
    } catch (e, st) {
      debugPrint('ReminderAlarmService: Alarm.set failed $id: $e\n$st');
      return false;
    }
  }

  Future<bool> _scheduleMark(
    DoseSlot slot, {
    required tz.TZDateTime when,
  }) async {
    final id = markNotificationId(slot.slotId);
    final copy = _copyForSlot(slot: slot, kind: kindMark);
    final payload = jsonEncode(slot.toPayload(kind: kindMark));

    try {
      await _plugin.zonedSchedule(
        id,
        copy.title,
        copy.body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            markChannelId,
            markChannelName,
            channelDescription: 'Confirmation de prise (H+5)',
            icon: 'ic_stat_rappel',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            actions: markAndroidActions(en: _en),
          ),
          iOS: const DarwinNotificationDetails(
            categoryIdentifier: iosCategory,
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      return true;
    } catch (e, st) {
      debugPrint('ReminderAlarmService: mark schedule failed $id: $e\n$st');
      return false;
    }
  }

  List<int> _trackedIds() {
    return _decodeIdList(_prefs.getString(_idsKey));
  }

  List<int> _trackedAlarmPkgIds() {
    return _decodeIdList(_prefs.getString(_alarmPkgIdsKey));
  }

  List<int> _decodeIdList(String? raw) {
    if (raw == null || raw.isEmpty) {
      // Migration depuis v2 : nettoyer d’anciennes notifs FLN H0.
      if (raw == null) {
        final legacy = _prefs.getString('reminder_notif_ids_v2');
        if (legacy != null) {
          try {
            final decoded = jsonDecode(legacy);
            if (decoded is List) {
              for (final e in decoded) {
                _plugin.cancel((e as num).toInt());
              }
            }
          } catch (_) {}
          _prefs.remove('reminder_notif_ids_v2');
        }
      }
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map((e) => (e as num).toInt()).toList();
    } catch (_) {
      return [];
    }
  }
}

Map<String, dynamic> parseReminderPayload(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return {};
}

/// Handler background — top-level + async pour laisser finir le travail.
@pragma('vm:entry-point')
Future<void> reminderBackgroundHandler(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final payload = parseReminderPayload(response.payload);
    if (CheckInReminderService.isCheckInPayload(payload)) {
      await _handleCheckInBackground(response);
      return;
    }

    final slot = DoseSlot.fromPayload(payload);
    if (slot.priseIds.isEmpty) return;

    final action = response.actionId;
    if (action == null || action.isEmpty) return;

    await ReminderAlarmService.cancelBothForSlot(slot.slotId);

    final prefs = await SharedPreferences.getInstance();
    final alarmPrefs = AlarmPrefs(prefs);
    final db = AppDatabase();
    final outbox = SyncOutbox(db, prefs: prefs);
    final engine = SyncEngine(
      outbox: outbox,
      gatewayFactory: () => HomeSyncPriseGateway(
        HomeRepository(apiClient: ApiClient(tokenStorage: TokenStorage())),
      ),
    );

    if (action == ReminderAlarmService.actionConfirm) {
      await db.transaction(() async {
        for (final priseId in slot.priseIds) {
          await db.updatePriseLocal(id: priseId, statut: 'confirmee');
          await engine.enqueueConfirm(priseId: priseId);
        }
      });
      try {
        await engine.flush(force: true);
      } catch (e) {
        debugPrint('reminderBackgroundHandler confirm: $e');
      }
      await db.close();
      return;
    }
    if (action == ReminderAlarmService.actionSnooze) {
      final when =
          DateTime.now().add(Duration(minutes: alarmPrefs.snoozeMinutes));
      await db.transaction(() async {
        for (final priseId in slot.priseIds) {
          await db.updatePriseLocal(
            id: priseId,
            heurePrevue: when,
            statut: 'en_attente',
          );
          await engine.enqueueReport(priseId: priseId, nouvelleHeure: when);
        }
      });
      try {
        await engine.flush(force: true);
      } catch (e) {
        debugPrint('reminderBackgroundHandler snooze: $e');
      }
      await db.close();
      final alarms = ReminderAlarmService(prefs);
      await alarms.init();
      await alarms.scheduleOneShotSlot(slot.copyWithHeure(when));
    }
  } catch (e, st) {
    debugPrint('reminderBackgroundHandler: $e\n$st');
  }
}

Future<void> _handleCheckInBackground(NotificationResponse response) async {
  final statut = CheckInReminderService.statutFromAction(response.actionId);
  if (statut == null) return;

  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();
  final outbox = SyncOutbox(db, prefs: prefs);
  final engine = SyncEngine(
    outbox: outbox,
    gatewayFactory: () => HomeSyncPriseGateway(
      HomeRepository(apiClient: ApiClient(tokenStorage: TokenStorage())),
    ),
  );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final key =
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';

  final existing = await db.getCheckInForDateKey(key);
  if (existing != null) {
    await db.close();
    return;
  }

  final clientId = DateTime.now().microsecondsSinceEpoch.toString();
  await db.transaction(() async {
    await db.upsertCheckInLocal(id: clientId, date: today, statut: statut);
    await engine.enqueueCreateCheckIn(dateKey: key, statut: statut);
  });
  try {
    await engine.flush(force: true);
  } catch (e) {
    debugPrint('reminderBackgroundHandler check-in: $e');
  }
  await db.close();

  final alarms = ReminderAlarmService(prefs);
  await alarms.init();
  final checkIn = CheckInReminderService(prefs, alarms.plugin);
  await checkIn.syncSchedule(
    hasMaladie: true,
    alreadyCheckedInToday: true,
  );
}

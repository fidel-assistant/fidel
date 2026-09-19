import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/providers.dart';
import '../core/locale/locale_controller.dart';
import '../features/home/application/home_controller.dart';
import '../features/home/data/home_repository.dart';
import '../features/home/domain/dashboard_models.dart';
import 'alarm_prefs.dart';
import 'check_in_reminder_service.dart';
import 'dose_slot.dart';
import 'reminder_alarm_service.dart';
import 'reminder_sync_perf.dart';
import 'scheduled_dose.dart';
import 'sos_aidant_alarm.dart';
import 'sync_engine.dart';
import '../core/router/app_router.dart';

final reminderAlarmServiceProvider = Provider<ReminderAlarmService>((ref) {
  return ReminderAlarmService(ref.watch(sharedPreferencesProvider));
});

final checkInReminderServiceProvider = Provider<CheckInReminderService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final alarms = ref.watch(reminderAlarmServiceProvider);
  return CheckInReminderService(prefs, alarms.plugin);
});

final alarmPrefsProvider = Provider<AlarmPrefs>((ref) {
  return AlarmPrefs(ref.watch(sharedPreferencesProvider));
});

const _syncGateKey = 'reminder_sync_gate_v1';
const _voixMetaPrefsKey = 'reminder_voix_meta_v1';

/// Traite une réponse notif (foreground) : check-in / confirm / snooze / tap.
class ReminderActionDispatcher {
  ReminderActionDispatcher(this._container);

  final ProviderContainer _container;

  Future<void> handle(NotificationResponse response) async {
    final payload = parseReminderPayload(response.payload);
    final kind = payload['kind'] as String?;

    if (CheckInReminderService.isCheckInPayload(payload)) {
      await _handleCheckIn(response);
      return;
    }

    final sosAlert = parseSosPayload(response.payload);
    if (sosAlert != null) {
      openSosAidantScreen(_container.read(appRouterProvider), sosAlert);
      return;
    }

    final slot = DoseSlot.fromPayload(payload);
    final alarms = _container.read(reminderAlarmServiceProvider);
    final engine = _container.read(syncEngineProvider);
    final snoozeMin = _container.read(alarmPrefsProvider).snoozeMinutes;

    debugPrint(
      'ReminderAction: actionId=${response.actionId} kind=$kind '
      'type=${response.notificationResponseType} slotId=${slot.slotId} '
      'prises=${slot.priseIds.length}',
    );

    if (response.actionId == null || response.actionId!.isEmpty) {
      if (response.notificationResponseType ==
          NotificationResponseType.selectedNotification) {
        _container.read(homeTabIndexProvider.notifier).state = 0;
      }
      return;
    }

    if (slot.priseIds.isEmpty) return;

    await alarms.cancelSlot(slot.slotId);

    if (response.actionId == ReminderAlarmService.actionConfirm) {
      for (final priseId in slot.priseIds) {
        await engine.enqueueConfirm(priseId: priseId);
      }
      try {
        await engine.flush(force: true);
      } catch (e) {
        debugPrint('ReminderAction confirm: $e');
      }
      try {
        await _container
            .read(homeControllerProvider.notifier)
            .reloadProjection();
      } catch (_) {}
      return;
    }

    if (response.actionId == ReminderAlarmService.actionSnooze) {
      final when = DateTime.now().add(Duration(minutes: snoozeMin));
      try {
        await _container
            .read(homeControllerProvider.notifier)
            .reportPrises(slot.priseIds, when);
      } catch (e) {
        debugPrint('ReminderAction snooze report: $e');
        for (final priseId in slot.priseIds) {
          await engine.enqueueReport(priseId: priseId, nouvelleHeure: when);
        }
      }
      await alarms.scheduleOneShotSlot(slot.copyWithHeure(when));
      try {
        await _container
            .read(homeControllerProvider.notifier)
            .reloadProjection();
      } catch (_) {}
    }
  }

  Future<void> _handleCheckIn(NotificationResponse response) async {
    debugPrint(
      'ReminderAction check-in: actionId=${response.actionId} '
      'type=${response.notificationResponseType}',
    );

    final statut = CheckInReminderService.statutFromAction(response.actionId);
    if (statut == null) {
      if (response.notificationResponseType ==
          NotificationResponseType.selectedNotification) {
        _container.read(homeTabIndexProvider.notifier).state = 0;
      }
      return;
    }

    try {
      await _container
          .read(homeControllerProvider.notifier)
          .submitCheckIn(statut);
    } catch (e) {
      debugPrint('ReminderAction check-in submit: $e');
    }
  }
}

/// Flush file + replanifie les alarmes (horizon [ReminderSyncPerf.scheduleHorizon]).
///
/// [dashboard] doit être passé par l’appelant : ne pas relire
/// [homeControllerProvider] depuis [HomeController] (cycle Riverpod).
///
/// Compatible [Ref.read] et [WidgetRef.read].
///
/// [force] : ignore le skip fingerprint (réglages alarme / tests).
Future<void> syncRemindersFromHome(
  T Function<T>(ProviderListenable<T> provider) read,
  PatientDashboard dashboard, {
  bool force = false,
}) async {
  if (!dashboard.notificationsAccordees) return;

  final repo = read(homeRepositoryProvider);
  final engine = read(syncEngineProvider);
  final alarms = read(reminderAlarmServiceProvider);
  final alarmPrefs = read(alarmPrefsProvider);
  final prefs = read(sharedPreferencesProvider);
  final db = read(appDatabaseProvider);

  try {
    await engine.flush();
  } catch (_) {}

  final dashFp = ReminderSyncPerf.dashboardPendingFingerprint(
    dashboard.prisesAujourdhui,
  );
  final gate = ReminderSyncPerf.syncGateKey(
    dashboardFingerprint: dashFp,
    preavisMinutes: alarmPrefs.preavisMinutes,
    discreet: alarms.discreet,
    useCustomVoice: alarmPrefs.useCustomVoice,
    customVoiceExt: alarmPrefs.customVoiceExt,
  );

  if (!force && prefs.getString(_syncGateKey) == gate) {
    debugPrint('syncRemindersFromHome skip (unchanged gate)');
    return;
  }

  try {
    final settings = await repo.fetchPatientSettings();
    await alarms.setDiscreet(settings.notificationsDiscretes);
  } catch (_) {}

  await _refreshVoixCacheIfNeeded(
    repo: repo,
    prefs: prefs,
    alarmPrefs: alarmPrefs,
  );

  final now = DateTime.now();
  final today = homeDateOnly(now);
  final byId = <String, ScheduledDose>{};

  void addPrises(List<PriseDuJour> prises, {bool overwrite = true}) {
    for (final p in prises) {
      if (!p.isPending) continue;
      if (!ReminderSyncPerf.isWithinHorizon(p.heurePrevue, now)) continue;
      if (!overwrite && byId.containsKey(p.id)) continue;
      byId[p.id] = ScheduledDose(
        priseId: p.id,
        medicamentNom: p.medicamentNom,
        dosage: p.dosage,
        heurePrevue: p.heurePrevue,
        traitementId: p.traitementId,
        maladieNom: p.maladieNom,
      );
    }
  }

  // Dashboard projeté (snapshot ⊕ outbox) gagne toujours sur le serveur.
  addPrises(dashboard.prisesAujourdhui, overwrite: true);
  try {
    await db.upsertPrises(dashboard.prisesAujourdhui);
  } catch (_) {}

  final extraDays = ReminderSyncPerf.extraDaysToFetch(now);
  for (var i = 1; i <= extraDays; i++) {
    try {
      final list = await repo.listPrises(date: today.add(Duration(days: i)));
      try {
        await db.upsertPrises(list);
      } catch (_) {}
      // Ne pas écraser une heure déjà reportée localement / outbox.
      addPrises(list, overwrite: false);
    } catch (_) {}
  }

  await alarms.rescheduleAll(byId.values.toList(), force: force);

  // Gate après sync réussi (prefs discreet peuvent avoir changé).
  final gateAfter = ReminderSyncPerf.syncGateKey(
    dashboardFingerprint: dashFp,
    preavisMinutes: alarmPrefs.preavisMinutes,
    discreet: alarms.discreet,
    useCustomVoice: alarmPrefs.useCustomVoice,
    customVoiceExt: alarmPrefs.customVoiceExt,
  );
  await prefs.setString(_syncGateKey, gateAfter);
}

Future<void> _refreshVoixCacheIfNeeded({
  required HomeRepository repo,
  required SharedPreferences prefs,
  required AlarmPrefs alarmPrefs,
}) async {
  try {
    final voix = await repo.fetchVoixRappel();
    final meta = ReminderSyncPerf.voixMetaKey(
      id: voix.id,
      fichierAudioUrl: voix.fichierAudioUrl,
      isPersonnalisee: voix.isPersonnalisee,
    );
    final last = prefs.getString(_voixMetaPrefsKey);
    if (!voix.isPersonnalisee) {
      if (last != meta) await prefs.setString(_voixMetaPrefsKey, meta);
      return;
    }

    final audioPath = await alarmPrefs.resolveAudioPath();
    final hasLocalCustom = audioPath != AlarmPrefs.defaultAssetAudio;
    if (last == meta && hasLocalCustom) {
      debugPrint('syncRemindersFromHome: voix cache hit');
      return;
    }

    final bytes = await repo.downloadVoixRappelFichier();
    if (bytes != null && bytes.isNotEmpty) {
      await alarmPrefs.storeCustomVoiceBytes(
        bytes: bytes,
        filename: 'voix_rappel.m4a',
      );
      await prefs.setString(_voixMetaPrefsKey, meta);
    }
  } catch (_) {}
}

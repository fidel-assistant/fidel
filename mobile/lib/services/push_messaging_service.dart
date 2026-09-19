import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/home/application/home_controller.dart';
import '../features/home/data/home_repository.dart';
import '../features/home/domain/aidant_models.dart';
import 'aidant_observance_notif.dart';
import 'sos_aidant_alarm.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  final data = message.data;
  final kind = data['kind']?.toString() ?? '';
  if (kind == 'sos') {
    final sosId = data['sos_id']?.toString() ?? '';
    if (sosId.isEmpty) return;
    await SosAidantAlarm.show(
      ActiveSosAlert(
        sosId: sosId,
        patientId: data['patient_id']?.toString() ?? '',
        patientPrenom: data['patient_prenom']?.toString() ?? 'Patient',
      ),
    );
    return;
  }
  if (kind == 'prise_confirmee' || kind == 'prise_non_confirmee') {
    await AidantObservanceNotif.show(
      kind: kind,
      patientPrenom: data['patient_prenom']?.toString() ?? 'Patient',
      medicament: data['medicament']?.toString() ?? 'médicament',
      heure: data['heure']?.toString() ?? '',
      priseId: data['prise_id']?.toString() ?? '',
      patientId: data['patient_id']?.toString() ?? '',
    );
  }
}

/// FCM + enregistrement token + poll SOS actifs.
class PushMessagingService {
  PushMessagingService(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _tokenSub;
  bool _initialized = false;

  /// SOS déjà signalés localement (évite re-alarme à chaque cold start).
  final Set<String> _shownSosIds = {};

  HomeRepository get _repo => _ref.read(homeRepositoryProvider);

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint(
        'PushMessaging: Firebase.initializeApp failed (add google-services.json): $e',
      );
      return;
    }
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, sound: true, badge: true);

    FirebaseMessaging.onMessage.listen((msg) {
      unawaited(handleMessage(msg, fromUserTap: false));
    });
    // Tap sur notif : ouvrir l’écran SOS (sans re-poster l’alarme).
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      unawaited(handleMessage(msg, fromUserTap: true));
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      unawaited(handleMessage(initial, fromUserTap: true));
    }

    final token = await messaging.getToken();
    await registerTokenIfPossible(token);
    _tokenSub = messaging.onTokenRefresh.listen(registerTokenIfPossible);
  }

  Future<void> registerTokenIfPossible(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _repo.registerPushToken(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (e) {
      debugPrint('PushMessaging registerToken: $e');
    }
  }

  ActiveSosAlert? _alertFromData(Map<String, dynamic> data) {
    final sosId = data['sos_id']?.toString() ?? '';
    if (sosId.isEmpty) return null;
    return ActiveSosAlert(
      sosId: sosId,
      patientId: data['patient_id']?.toString() ?? '',
      patientPrenom: data['patient_prenom']?.toString() ?? 'Patient',
    );
  }

  Future<void> handleMessage(
    RemoteMessage message, {
    bool fromUserTap = false,
  }) async {
    final data = message.data;
    final kind = data['kind']?.toString() ?? '';
    if (kind == 'sos') {
      final alert = _alertFromData(data);
      if (alert == null) return;
      if (fromUserTap) {
        openSosAidantScreen(_ref.read(appRouterProvider), alert);
        return;
      }
      if (!_shownSosIds.add(alert.sosId)) return;
      await SosAidantAlarm.show(alert);
      return;
    }
    if (kind == 'prise_confirmee' || kind == 'prise_non_confirmee') {
      await AidantObservanceNotif.show(
        kind: kind,
        patientPrenom: data['patient_prenom']?.toString() ?? 'Patient',
        medicament: data['medicament']?.toString() ?? 'médicament',
        heure: data['heure']?.toString() ?? '',
        priseId: data['prise_id']?.toString() ?? '',
        patientId: data['patient_id']?.toString() ?? '',
      );
    }
  }

  Future<void> pollActiveSos() async {
    try {
      final session = _ref.read(authSessionProvider);
      if (session?.isAidant != true) return;

      final active = await _repo.listActiveSosForAidant();
      for (final alert in active) {
        if (!_shownSosIds.add(alert.sosId)) continue;
        await SosAidantAlarm.show(alert);
      }
    } catch (e) {
      debugPrint('PushMessaging pollActiveSos: $e');
    }
  }

  void markSosHandled(String sosId) {
    _shownSosIds.add(sosId);
  }

  void dispose() {
    _tokenSub?.cancel();
  }
}

final pushMessagingServiceProvider = Provider<PushMessagingService>((ref) {
  final s = PushMessagingService(ref);
  ref.onDispose(s.dispose);
  return s;
});

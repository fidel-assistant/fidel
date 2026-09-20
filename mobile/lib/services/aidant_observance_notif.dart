import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import 'sos_aidant_alarm.dart';

/// Cible d’un tap notif observance (prise confirmée / absente).
class ObservanceNotifTarget {
  const ObservanceNotifTarget({
    required this.patientId,
    required this.prenom,
  });

  final String patientId;
  final String prenom;
}

/// Notif locale aidant pour observance (prise confirmée / absente).
class AidantObservanceNotif {
  static const channelId = 'fidel_sos_aidant';
  static const channelName = 'SOS patient';
  static const notificationIdBase = 92003000;

  static Future<void> show({
    required String kind,
    required String patientPrenom,
    required String medicament,
    required String heure,
    required String priseId,
    required String patientId,
  }) async {
    final plugin = await SosAidantAlarm.notificationPlugin();
    await SosAidantAlarm.ensureChannel(plugin);

    final confirmed = kind == 'prise_confirmee';
    final title = confirmed ? 'Prise confirmée' : 'Prise non confirmée';
    final body = confirmed
        ? '$patientPrenom a confirmé $medicament ($heure).'
        : 'Pas de confirmation pour $medicament de $patientPrenom ($heure).';

    final id = notificationIdBase + (priseId.hashCode.abs() % 1000);
    await plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Alertes des patients accompagnés',
          icon: 'ic_stat_observance',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload:
          'observance:$kind:$priseId:$patientId:$patientPrenom',
    );
  }
}

/// Parse `observance:kind:priseId:patientId:prenom`.
ObservanceNotifTarget? parseObservancePayload(String? payload) {
  if (payload == null || !payload.startsWith('observance:')) return null;
  final parts = payload.split(':');
  if (parts.length < 5) return null;
  final patientId = parts[3];
  if (patientId.isEmpty) return null;
  return ObservanceNotifTarget(
    patientId: patientId,
    prenom: parts.sublist(4).join(':'),
  );
}

/// Ouvre le détail du patient accompagné. Anti-doublon si déjà sur cet écran.
void openAidantPatientDetail(
  GoRouter router, {
  required String patientId,
  String prenom = 'Patient',
}) {
  if (patientId.isEmpty) return;

  void push() {
    if (router.state.uri.path == '/home/cercle/patient/$patientId') return;
    final location = Uri(
      path: '/home/cercle/patient/$patientId',
      queryParameters: prenom.isEmpty ? null : {'prenom': prenom},
    ).toString();
    router.push(location);
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => push());
}

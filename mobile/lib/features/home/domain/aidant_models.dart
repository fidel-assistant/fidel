class AidantPermissions {
  const AidantPermissions({
    required this.observance,
    required this.constantes,
  });

  final bool observance;
  final bool constantes;

  factory AidantPermissions.fromJson(Map<String, dynamic>? json) {
    return AidantPermissions(
      observance: json?['observance'] as bool? ?? true,
      constantes: json?['constantes'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'observance': observance,
        'constantes': constantes,
      };

  AidantPermissions copyWith({bool? observance, bool? constantes}) {
    return AidantPermissions(
      observance: observance ?? this.observance,
      constantes: constantes ?? this.constantes,
    );
  }
}

class AidantRelation {
  const AidantRelation({
    required this.id,
    required this.nom,
    required this.statut,
    required this.permissions,
  });

  final String id;
  final String? nom;
  final String statut;
  final AidantPermissions permissions;

  String get displayName {
    final n = nom?.trim();
    if (n == null || n.isEmpty) return '—';
    return n;
  }

  String get initial {
    final n = displayName.trim();
    if (n.isEmpty || n == '—') return '?';
    return n[0].toUpperCase();
  }

  factory AidantRelation.fromJson(Map<String, dynamic> json) {
    return AidantRelation(
      id: json['aidant_id']?.toString() ?? '',
      nom: json['nom'] as String?,
      statut: json['statut'] as String? ?? 'actif',
      permissions: AidantPermissions.fromJson(
        json['niveau_permission'] is Map
            ? Map<String, dynamic>.from(json['niveau_permission'] as Map)
            : null,
      ),
    );
  }
}

class AidantPatient {
  const AidantPatient({
    required this.id,
    required this.prenom,
    required this.permissions,
  });

  final String id;
  final String prenom;
  final AidantPermissions permissions;

  String get displayName {
    final value = prenom.trim();
    return value.isEmpty ? 'Patient' : value;
  }

  String get initial {
    final value = displayName.trim();
    return value.isEmpty ? '?' : value[0].toUpperCase();
  }

  factory AidantPatient.fromJson(Map<String, dynamic> json) {
    return AidantPatient(
      id: json['patient_id']?.toString() ?? '',
      prenom: json['prenom'] as String? ?? '',
      permissions: AidantPermissions.fromJson(
        json['niveau_permission'] is Map
            ? Map<String, dynamic>.from(json['niveau_permission'] as Map)
            : null,
      ),
    );
  }
}

/// Signal affiché sur les cartes Accueil / Cercle (dérivé SOS + observance du jour).
enum AidantPatientSignal {
  sosActive,
  missedToday,
  pendingToday,
  okToday,
  nothingToday,
  /// Pas de signal dose — l’UI garde le libellé permission.
  permissionLimited,
}

AidantPatientSignal deriveAidantPatientSignal({
  required bool hasActiveSos,
  required bool canSeeObservance,
  AidantObservance? today,
}) {
  if (hasActiveSos) return AidantPatientSignal.sosActive;
  if (!canSeeObservance || today == null) {
    return AidantPatientSignal.permissionLimited;
  }
  if (today.manquees > 0) return AidantPatientSignal.missedToday;
  if (today.enAttente > 0) return AidantPatientSignal.pendingToday;
  if (today.confirmees > 0) return AidantPatientSignal.okToday;
  return AidantPatientSignal.nothingToday;
}

class AidantObservance {
  const AidantObservance({
    required this.patientId,
    required this.patientPrenom,
    required this.depuis,
    required this.jusquA,
    required this.total,
    required this.confirmees,
    required this.manquees,
    required this.enAttente,
    required this.tauxObservance,
  });

  final String patientId;
  final String patientPrenom;
  final DateTime depuis;
  final DateTime jusquA;
  final int total;
  final int confirmees;
  final int manquees;
  final int enAttente;
  final double? tauxObservance;

  int get percent => ((tauxObservance ?? 0) * 100).round().clamp(0, 100);

  factory AidantObservance.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String key) =>
        DateTime.tryParse(json[key]?.toString() ?? '')?.toLocal() ??
        DateTime.now();
    return AidantObservance(
      patientId: json['patient_id']?.toString() ?? '',
      patientPrenom: json['patient_prenom'] as String? ?? '',
      depuis: parseDate('depuis'),
      jusquA: parseDate('jusqu_a'),
      total: (json['total'] as num?)?.toInt() ?? 0,
      confirmees: (json['confirmees'] as num?)?.toInt() ?? 0,
      manquees: (json['manquees'] as num?)?.toInt() ?? 0,
      enAttente: (json['en_attente'] as num?)?.toInt() ?? 0,
      tauxObservance: (json['taux_observance'] as num?)?.toDouble(),
    );
  }
}

class SosTicket {
  const SosTicket({
    required this.id,
    required this.annulableJusquA,
  });

  final String id;
  final DateTime annulableJusquA;

  factory SosTicket.fromJson(Map<String, dynamic> json) {
    return SosTicket(
      id: json['sos_id']?.toString() ?? '',
      annulableJusquA:
          DateTime.tryParse(json['annulable_jusqu_a']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }
}

class SosConfirmResult {
  const SosConfirmResult({
    required this.sosId,
    required this.statut,
    required this.aidantsNotifies,
    required this.fallbackCallRecommended,
    required this.acked,
  });

  final String sosId;
  final String statut;
  final int aidantsNotifies;
  final bool fallbackCallRecommended;
  final bool acked;

  factory SosConfirmResult.fromJson(Map<String, dynamic> json) {
    return SosConfirmResult(
      sosId: json['sos_id']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      aidantsNotifies: (json['aidants_notifies'] as num?)?.toInt() ?? 0,
      fallbackCallRecommended:
          json['fallback_call_recommended'] as bool? ?? true,
      acked: json['acked'] as bool? ?? false,
    );
  }
}

class SosStatusResult {
  const SosStatusResult({
    required this.sosId,
    required this.statut,
    required this.acked,
  });

  final String sosId;
  final String statut;
  final bool acked;

  factory SosStatusResult.fromJson(Map<String, dynamic> json) {
    return SosStatusResult(
      sosId: json['sos_id']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      acked: json['acked'] as bool? ?? false,
    );
  }
}

class ActiveSosAlert {
  const ActiveSosAlert({
    required this.sosId,
    required this.patientId,
    required this.patientPrenom,
    this.envoyeAt,
  });

  final String sosId;
  final String patientId;
  final String patientPrenom;
  final DateTime? envoyeAt;

  factory ActiveSosAlert.fromJson(Map<String, dynamic> json) {
    return ActiveSosAlert(
      sosId: json['sos_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientPrenom: json['patient_prenom']?.toString() ?? 'Patient',
      envoyeAt: DateTime.tryParse(json['envoye_at']?.toString() ?? '')?.toLocal(),
    );
  }
}

class AidantNotificationPrefs {
  const AidantNotificationPrefs({
    this.mutePriseConfirmee = false,
    this.mutePriseNonConfirmee = false,
    this.muteSos = false,
  });

  final bool mutePriseConfirmee;
  final bool mutePriseNonConfirmee;
  final bool muteSos;

  factory AidantNotificationPrefs.fromJson(Map<String, dynamic> json) {
    return AidantNotificationPrefs(
      mutePriseConfirmee: json['mute_prise_confirmee'] as bool? ?? false,
      mutePriseNonConfirmee: json['mute_prise_non_confirmee'] as bool? ?? false,
      muteSos: json['mute_sos'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toPatchJson({
    bool? mutePriseConfirmee,
    bool? mutePriseNonConfirmee,
    bool? muteSos,
  }) {
    return {
      if (mutePriseConfirmee != null)
        'mute_prise_confirmee': mutePriseConfirmee,
      if (mutePriseNonConfirmee != null)
        'mute_prise_non_confirmee': mutePriseNonConfirmee,
      if (muteSos != null) 'mute_sos': muteSos,
    };
  }

  AidantNotificationPrefs copyWith({
    bool? mutePriseConfirmee,
    bool? mutePriseNonConfirmee,
    bool? muteSos,
  }) {
    return AidantNotificationPrefs(
      mutePriseConfirmee: mutePriseConfirmee ?? this.mutePriseConfirmee,
      mutePriseNonConfirmee:
          mutePriseNonConfirmee ?? this.mutePriseNonConfirmee,
      muteSos: muteSos ?? this.muteSos,
    );
  }
}

/// Modèles réglages Profil — contrats api-contract / data-model.
class PatientSettings {
  const PatientSettings({
    required this.notificationsAccordees,
    required this.batterieExemptee,
    required this.notificationsDiscretes,
    this.localisation,
    this.nomComplet,
    this.photoUrl,
    this.groupeSanguin,
    this.rhesus,
    this.electrophorese,
    this.tailleCm,
  });

  final bool notificationsAccordees;
  final bool batterieExemptee;
  final bool notificationsDiscretes;
  final String? localisation;
  final String? nomComplet;
  final String? photoUrl;
  final String? groupeSanguin;
  final String? rhesus;
  final String? electrophorese;
  final int? tailleCm;

  factory PatientSettings.fromJson(Map<String, dynamic> json) {
    return PatientSettings(
      notificationsAccordees: json['notifications_accordees'] as bool? ?? false,
      batterieExemptee: json['batterie_exemptee'] as bool? ?? false,
      notificationsDiscretes: json['notifications_discretes'] as bool? ?? false,
      localisation: json['localisation'] as String?,
      nomComplet: json['nom_complet'] as String?,
      photoUrl: json['photo_url'] as String?,
      groupeSanguin: json['groupe_sanguin'] as String?,
      rhesus: json['rhesus'] as String?,
      electrophorese: json['electrophorese'] as String?,
      tailleCm: (json['taille_cm'] as num?)?.toInt(),
    );
  }
}

/// Enums fermés fiche santé (alignés API).
abstract final class FicheSanteOptions {
  static const groupes = ['A', 'B', 'AB', 'O'];
  static const rhesus = ['+', '-'];
  static const electrophoreses = [
    'AA',
    'AS',
    'AC',
    'SS',
    'SC',
    'CC',
    'ne_sait_pas',
  ];
  static const tailleMinCm = 120;
  static const tailleMaxCm = 220;
  static List<int> get taillesCm =>
      List.generate(tailleMaxCm - tailleMinCm + 1, (i) => tailleMinCm + i);
}

class ContactUrgence {
  const ContactUrgence({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.relation,
  });

  final String id;
  final String nom;
  final String telephone;
  final String relation;

  factory ContactUrgence.fromJson(Map<String, dynamic> json) {
    return ContactUrgence(
      id: json['id'] as String,
      nom: json['nom'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
    );
  }
}

class PreferenceConsentement {
  const PreferenceConsentement({
    required this.typeAlerte,
    required this.toujoursDemander,
    this.id,
    this.regleAuto,
  });

  final String? id;
  final String typeAlerte;
  final bool toujoursDemander;
  final Map<String, dynamic>? regleAuto;

  factory PreferenceConsentement.fromJson(Map<String, dynamic> json) {
    final raw = json['regle_auto'];
    return PreferenceConsentement(
      id: json['id'] as String?,
      typeAlerte: json['type_alerte'] as String? ?? '',
      toujoursDemander: json['toujours_demander'] as bool? ?? true,
      regleAuto: raw is Map
          ? Map<String, dynamic>.from(raw)
          : null,
    );
  }

  /// Types où une règle auto opt-in a du sens produit (tiers).
  static const configurableAutoTypes = {
    'checkin_absence',
    'constante_degradation',
    'rappel_medicament',
    'prise_confirmee_aidant',
    'prise_non_confirmee_aidant',
  };
}

class VoixRappel {
  const VoixRappel({
    required this.patientId,
    required this.type,
    this.id,
    this.fichierAudioUrl,
  });

  final String? id;
  final String patientId;
  final String type; // systeme | personnalisee
  final String? fichierAudioUrl;

  bool get isPersonnalisee => type == 'personnalisee';

  factory VoixRappel.fromJson(Map<String, dynamic> json) {
    return VoixRappel(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String? ?? '',
      type: json['type'] as String? ?? 'systeme',
      fichierAudioUrl: json['fichier_audio_url'] as String?,
    );
  }
}

class HomeProfile {
  const HomeProfile({
    required this.nomComplet,
    required this.hasPatientProfile,
    required this.isAidant,
    this.email = '',
    this.phone,
    this.langue,
    this.fuseauHoraire,
    this.hasPassword = false,
    this.groupeSanguin,
    this.rhesus,
    this.electrophorese,
    this.tailleCm,
    this.photoUrl,
  });

  final String nomComplet;
  final bool hasPatientProfile;
  final bool isAidant;
  final String email;
  final String? phone;
  final String? langue;
  final String? fuseauHoraire;
  final bool hasPassword;
  final String? groupeSanguin;
  final String? rhesus;
  final String? electrophorese;
  final int? tailleCm;
  final String? photoUrl;

  /// Chip « O+ » si groupe + rhésus confirmés.
  String? get groupeRhesusLabel {
    final g = groupeSanguin;
    final r = rhesus;
    if (g == null || g.isEmpty || r == null || r.isEmpty) return null;
    return '$g$r';
  }

  /// Chip électrophorèse (masque ne_sait_pas).
  String? get electrophoreseChip {
    final e = electrophorese;
    if (e == null || e.isEmpty || e == 'ne_sait_pas') return null;
    return e;
  }

  String? get tailleChip {
    final t = tailleCm;
    if (t == null) return null;
    return '$t cm';
  }

  List<String> get ficheSanteChips {
    return [
      if (groupeRhesusLabel != null) groupeRhesusLabel!,
      if (electrophoreseChip != null) electrophoreseChip!,
      if (tailleChip != null) tailleChip!,
    ];
  }

  String get firstName {
    final parts = nomComplet.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    final raw = parts.first;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  String get initial {
    if (firstName.isEmpty) {
      if (email.isNotEmpty) return email[0].toUpperCase();
      return 'F';
    }
    return firstName[0];
  }

  /// Prénom + nom, deux mots max — pour l’entête sans débordement.
  String get headerName {
    final parts = nomComplet
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      if (email.isNotEmpty) return email;
      return '';
    }
    String cap(String raw) =>
        raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    if (parts.length == 1) return cap(parts.first);
    return '${cap(parts[0])} ${cap(parts[1])}';
  }

  HomeProfile copyWith({
    String? nomComplet,
    bool? hasPatientProfile,
    bool? isAidant,
    String? email,
    String? phone,
    String? langue,
    String? fuseauHoraire,
    bool? hasPassword,
    String? groupeSanguin,
    String? rhesus,
    String? electrophorese,
    int? tailleCm,
    String? photoUrl,
    bool clearFicheSante = false,
    bool clearPhoto = false,
  }) {
    return HomeProfile(
      nomComplet: nomComplet ?? this.nomComplet,
      hasPatientProfile: hasPatientProfile ?? this.hasPatientProfile,
      isAidant: isAidant ?? this.isAidant,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      langue: langue ?? this.langue,
      fuseauHoraire: fuseauHoraire ?? this.fuseauHoraire,
      hasPassword: hasPassword ?? this.hasPassword,
      groupeSanguin:
          clearFicheSante ? null : (groupeSanguin ?? this.groupeSanguin),
      rhesus: clearFicheSante ? null : (rhesus ?? this.rhesus),
      electrophorese:
          clearFicheSante ? null : (electrophorese ?? this.electrophorese),
      tailleCm: clearFicheSante ? null : (tailleCm ?? this.tailleCm),
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
    );
  }

  factory HomeProfile.fromMeJson(Map<String, dynamic> json) {
    return HomeProfile(
      nomComplet: json['nom_complet'] as String? ?? '',
      hasPatientProfile: json['has_patient_profile'] as bool? ?? false,
      isAidant: json['is_aidant'] as bool? ?? false,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      langue: json['langue'] as String?,
      fuseauHoraire: json['fuseau_horaire'] as String?,
      hasPassword: json['has_password'] as bool? ?? false,
      groupeSanguin: json['groupe_sanguin'] as String?,
      rhesus: json['rhesus'] as String?,
      electrophorese: json['electrophorese'] as String?,
      tailleCm: (json['taille_cm'] as num?)?.toInt(),
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toCacheJson() => {
        'nom_complet': nomComplet,
        'has_patient_profile': hasPatientProfile,
        'is_aidant': isAidant,
        'email': email,
        'phone': phone,
        'langue': langue,
        'fuseau_horaire': fuseauHoraire,
        'has_password': hasPassword,
        'groupe_sanguin': groupeSanguin,
        'rhesus': rhesus,
        'electrophorese': electrophorese,
        'taille_cm': tailleCm,
        'photo_url': photoUrl,
      };
}

class DoseSuggestion {
  const DoseSuggestion({
    required this.nom,
    required this.dosage,
    required this.forme,
    this.horaires = const [],
  });

  final String nom;
  final String dosage;
  final String forme;
  final List<String> horaires;

  factory DoseSuggestion.fromJson(Map<String, dynamic> json) {
    final raw = json['horaires_suggestion'];
    final hours = <String>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map && item['heure'] != null) {
          hours.add(item['heure'].toString());
        } else if (item is String) {
          hours.add(item);
        }
      }
    }
    return DoseSuggestion(
      nom: json['nom'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      forme: json['forme'] as String? ?? 'comprime',
      horaires: hours,
    );
  }
}

class DashboardTraitement {
  const DashboardTraitement({
    required this.id,
    required this.maladieCode,
    required this.maladieNom,
    required this.phase,
    required this.medicamentsConfigures,
    this.dateDebut,
    this.jourTraitement,
    this.suggestions = const [],
  });

  final String id;
  final String maladieCode;
  final String maladieNom;
  final String phase;
  final bool medicamentsConfigures;
  final DateTime? dateDebut;
  final int? jourTraitement;
  final List<DoseSuggestion> suggestions;

  factory DashboardTraitement.fromJson(Map<String, dynamic> json) {
    final raw = json['suggestions_medicaments'];
    return DashboardTraitement(
      id: json['id'].toString(),
      maladieCode: json['maladie_code'] as String? ?? '',
      maladieNom: json['maladie_nom'] as String? ?? '',
      phase: json['phase'] as String? ?? '',
      medicamentsConfigures: json['medicaments_configures'] as bool? ?? false,
      dateDebut: DateTime.tryParse(json['date_debut']?.toString() ?? ''),
      jourTraitement: json['jour_traitement'] as int?,
      suggestions: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => DoseSuggestion.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// `GET /patients/me/traitements` — apporte `date_fin_prevue` / `statut` / `phase`.
class TraitementDetail {
  const TraitementDetail({
    required this.id,
    this.dateDebut,
    this.dateFinPrevue,
    this.jourTraitement,
    this.statut = 'actif',
    this.phase = '',
    this.maladieNom,
    this.maladieCode,
  });

  final String id;
  final DateTime? dateDebut;
  final DateTime? dateFinPrevue;
  final int? jourTraitement;
  final String statut;
  final String phase;
  final String? maladieNom;
  final String? maladieCode;

  bool get isActif => statut == 'actif';
  bool get isSuspendu => statut == 'suspendu';
  bool get isTermine => statut == 'termine';

  /// Durée totale prévue en jours, `null` si la fin n’est pas connue.
  int? get dureeTotale {
    final debut = dateDebut;
    final fin = dateFinPrevue;
    if (debut == null || fin == null) return null;
    final days = fin.difference(debut).inDays + 1;
    return days > 0 ? days : null;
  }

  TraitementDetail copyWith({
    DateTime? dateDebut,
    DateTime? dateFinPrevue,
    int? jourTraitement,
    String? statut,
    String? phase,
    String? maladieNom,
    String? maladieCode,
    bool clearDateFin = false,
  }) {
    return TraitementDetail(
      id: id,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFinPrevue:
          clearDateFin ? null : (dateFinPrevue ?? this.dateFinPrevue),
      jourTraitement: jourTraitement ?? this.jourTraitement,
      statut: statut ?? this.statut,
      phase: phase ?? this.phase,
      maladieNom: maladieNom ?? this.maladieNom,
      maladieCode: maladieCode ?? this.maladieCode,
    );
  }

  factory TraitementDetail.fromJson(Map<String, dynamic> json) {
    return TraitementDetail(
      id: json['id'].toString(),
      dateDebut: DateTime.tryParse(json['date_debut']?.toString() ?? ''),
      dateFinPrevue: DateTime.tryParse(json['date_fin_prevue']?.toString() ?? ''),
      jourTraitement: json['jour_traitement'] as int?,
      statut: json['statut'] as String? ?? 'actif',
      phase: json['phase'] as String? ?? '',
      maladieNom: json['maladie_nom'] as String?,
      maladieCode: json['maladie_code'] as String?,
    );
  }

  Map<String, dynamic> toCacheJson() => {
        'id': id,
        if (dateDebut != null) 'date_debut': dateDebut!.toIso8601String(),
        if (dateFinPrevue != null)
          'date_fin_prevue': dateFinPrevue!.toIso8601String(),
        if (jourTraitement != null) 'jour_traitement': jourTraitement,
        'statut': statut,
        'phase': phase,
        if (maladieNom != null) 'maladie_nom': maladieNom,
        if (maladieCode != null) 'maladie_code': maladieCode,
      };
}

/// Check-in du jour — `tres_mal` | `pas_top` | `ca_va` | `super`.
class CheckInEntry {
  const CheckInEntry({required this.date, required this.statut});

  static const levels = ['tres_mal', 'pas_top', 'ca_va', 'super'];

  final DateTime date;
  final String statut;

  bool get isPositive => statut == 'ca_va' || statut == 'super';

  /// @deprecated Prefer [isPositive] / level helpers.
  bool get isOk => isPositive;

  int get levelIndex {
    final i = levels.indexOf(statut);
    return i < 0 ? 2 : i;
  }

  factory CheckInEntry.fromJson(Map<String, dynamic> json) {
    return CheckInEntry(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      statut: json['statut'] as String? ?? 'ca_va',
    );
  }
}

/// Agrégat local d’une journée — le backend n’expose pas d’observance patient.
class DayAdherence {
  const DayAdherence({
    required this.day,
    required this.total,
    required this.confirmed,
    required this.missed,
    required this.pending,
  });

  const DayAdherence.empty(this.day)
      : total = 0,
        confirmed = 0,
        missed = 0,
        pending = 0;

  final DateTime day;
  final int total;
  final int confirmed;
  final int missed;
  final int pending;

  bool get hasDoses => total > 0;

  bool get isComplete => total > 0 && confirmed == total;

  /// Part des prises confirmées, `null` si rien n’était prévu ce jour-là.
  double? get ratio => total == 0 ? null : confirmed / total;

  factory DayAdherence.fromPrises(DateTime day, List<PriseDuJour> prises) {
    var confirmed = 0;
    var missed = 0;
    var pending = 0;
    for (final p in prises) {
      if (p.isTaken) {
        confirmed++;
      } else if (p.isMissed) {
        missed++;
      } else {
        pending++;
      }
    }
    return DayAdherence(
      day: day,
      total: prises.length,
      confirmed: confirmed,
      missed: missed,
      pending: pending,
    );
  }
}

class PriseDuJour {
  const PriseDuJour({
    required this.id,
    required this.medicamentNom,
    required this.dosage,
    required this.heurePrevue,
    required this.statut,
    this.traitementId,
    this.maladieId,
    this.maladieNom,
  });

  final String id;
  final String medicamentNom;
  final String dosage;
  final DateTime heurePrevue;
  final String statut;
  final String? traitementId;
  final String? maladieId;
  final String? maladieNom;

  bool get isPending => statut == 'en_attente';
  bool get isTaken => statut == 'confirmee';
  bool get isMissed => statut == 'manquee';

  /// Confirmable côté UI / sync : encore `en_attente` ou déjà `manquee` (tardif OK).
  bool get isConfirmable => isPending || isMissed;

  bool isLate(DateTime now) =>
      isMissed || (isPending && heurePrevue.isBefore(now));

  PriseDuJour copyWith({
    String? id,
    String? medicamentNom,
    String? dosage,
    DateTime? heurePrevue,
    String? statut,
    String? traitementId,
    String? maladieId,
    String? maladieNom,
  }) {
    return PriseDuJour(
      id: id ?? this.id,
      medicamentNom: medicamentNom ?? this.medicamentNom,
      dosage: dosage ?? this.dosage,
      heurePrevue: heurePrevue ?? this.heurePrevue,
      statut: statut ?? this.statut,
      traitementId: traitementId ?? this.traitementId,
      maladieId: maladieId ?? this.maladieId,
      maladieNom: maladieNom ?? this.maladieNom,
    );
  }

  factory PriseDuJour.fromJson(Map<String, dynamic> json) {
    return PriseDuJour(
      id: json['id'].toString(),
      medicamentNom: json['medicament_nom'] as String? ??
          json['medicamentNom'] as String? ??
          '',
      dosage: json['dosage'] as String? ?? '',
      heurePrevue:
          DateTime.tryParse(json['heure_prevue']?.toString() ??
                  json['heurePrevue']?.toString() ??
                  '') ??
              DateTime.now(),
      statut: json['statut'] as String? ?? 'en_attente',
      traitementId: json['traitement_id']?.toString() ??
          json['traitementId']?.toString(),
      maladieId:
          json['maladie_id']?.toString() ?? json['maladieId']?.toString(),
      maladieNom: json['maladie_nom'] as String? ??
          json['maladieNom'] as String?,
    );
  }
}

class PatientDashboard {
  const PatientDashboard({
    required this.prochaineAction,
    required this.medicamentsConfigures,
    required this.notificationsAccordees,
    required this.traitements,
    required this.prisesAujourdhui,
  });

  final String prochaineAction;
  final bool medicamentsConfigures;
  final bool notificationsAccordees;
  final List<DashboardTraitement> traitements;
  final List<PriseDuJour> prisesAujourdhui;

  int pendingCount(DateTime now) =>
      prisesAujourdhui.where((p) => p.isPending && !p.isLate(now)).length;

  int takenCount() => prisesAujourdhui.where((p) => p.isTaken).length;

  int lateCount(DateTime now) =>
      prisesAujourdhui.where((p) => p.isLate(now)).length;

  PriseDuJour? nextDose(DateTime now) {
    final pending = prisesAujourdhui.where((p) => p.isPending).toList()
      ..sort((a, b) => a.heurePrevue.compareTo(b.heurePrevue));
    for (final p in pending) {
      if (!p.heurePrevue.isBefore(now)) return p;
    }
    return pending.isEmpty ? null : pending.first;
  }

  DashboardTraitement? get firstUnconfigured {
    for (final t in traitements) {
      if (!t.medicamentsConfigures) return t;
    }
    return null;
  }

  factory PatientDashboard.fromJson(Map<String, dynamic> json) {
    final traitements = json['traitements'];
    final prises = json['prises_aujourdhui'];
    return PatientDashboard(
      prochaineAction: json['prochaine_action'] as String? ?? 'aucune',
      medicamentsConfigures: json['medicaments_configures'] as bool? ?? false,
      notificationsAccordees:
          json['notifications_accordees'] as bool? ?? false,
      traitements: traitements is List
          ? traitements
              .whereType<Map>()
              .map(
                (e) => DashboardTraitement.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
      prisesAujourdhui: prises is List
          ? prises
              .whereType<Map>()
              .map((e) => PriseDuJour.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

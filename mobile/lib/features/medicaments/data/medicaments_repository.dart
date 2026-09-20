import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../onboarding/domain/onboarding_models.dart';

final medicamentsRepositoryProvider = Provider<MedicamentsRepository>((ref) {
  return MedicamentsRepository(apiClient: ref.watch(apiClientProvider));
});

class MedicamentHoraire {
  const MedicamentHoraire({
    required this.id,
    required this.heure,
    required this.jours,
    required this.actif,
  });

  final String id;
  final String heure;
  final List<String> jours;
  final bool actif;

  factory MedicamentHoraire.fromJson(Map<String, dynamic> json) {
    final rawJours = json['jours'];
    return MedicamentHoraire(
      id: json['id']?.toString() ?? '',
      heure: _normalizeHeure(json['heure']?.toString() ?? ''),
      jours: rawJours is List
          ? rawJours.map((e) => e.toString()).toList()
          : const ['tous'],
      actif: json['actif'] as bool? ?? true,
    );
  }

  static String _normalizeHeure(String raw) {
    final t = raw.trim();
    if (t.length >= 5) return t.substring(0, 5);
    return t;
  }
}

class ConfiguredMedicament {
  const ConfiguredMedicament({
    required this.id,
    required this.traitementId,
    required this.nom,
    required this.dosage,
    this.forme = 'comprime',
    this.priseAvecRepas,
    this.instructions,
    this.actif = true,
    this.stockRestant,
    this.seuilAlerteStock,
    this.horaires = const [],
  });

  final String id;
  final String traitementId;
  final String nom;
  final String dosage;
  final String forme;
  final String? priseAvecRepas;
  final String? instructions;
  final bool actif;
  final int? stockRestant;
  final int? seuilAlerteStock;
  final List<MedicamentHoraire> horaires;

  List<MedicamentHoraire> get activeHoraires =>
      horaires.where((h) => h.actif).toList();

  factory ConfiguredMedicament.fromJson(Map<String, dynamic> json) {
    final rawHoraires = json['horaires'];
    return ConfiguredMedicament(
      id: json['id']?.toString() ?? '',
      traitementId: json['patient_traitement_id']?.toString() ?? '',
      nom: json['nom'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      forme: json['forme'] as String? ?? 'comprime',
      priseAvecRepas: json['prise_avec_repas'] as String?,
      instructions: json['instructions'] as String?,
      actif: json['actif'] as bool? ?? true,
      stockRestant: (json['stock_restant'] as num?)?.toInt(),
      seuilAlerteStock: (json['seuil_alerte_stock'] as num?)?.toInt(),
      horaires: rawHoraires is List
          ? rawHoraires
              .whereType<Map>()
              .map(
                (e) => MedicamentHoraire.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
    );
  }

  ConfiguredMedicament copyWith({
    String? nom,
    String? dosage,
    String? forme,
    String? priseAvecRepas,
    String? instructions,
    bool? actif,
    int? stockRestant,
    int? seuilAlerteStock,
    List<MedicamentHoraire>? horaires,
    bool clearStock = false,
    bool clearSeuil = false,
    bool clearPriseAvecRepas = false,
    bool clearInstructions = false,
  }) {
    return ConfiguredMedicament(
      id: id,
      traitementId: traitementId,
      nom: nom ?? this.nom,
      dosage: dosage ?? this.dosage,
      forme: forme ?? this.forme,
      priseAvecRepas: clearPriseAvecRepas
          ? null
          : (priseAvecRepas ?? this.priseAvecRepas),
      instructions:
          clearInstructions ? null : (instructions ?? this.instructions),
      actif: actif ?? this.actif,
      stockRestant: clearStock ? null : (stockRestant ?? this.stockRestant),
      seuilAlerteStock:
          clearSeuil ? null : (seuilAlerteStock ?? this.seuilAlerteStock),
      horaires: horaires ?? this.horaires,
    );
  }
}

class StockUpdateResult {
  const StockUpdateResult({
    required this.stockRestant,
    required this.alerteDeclenchee,
  });

  final int stockRestant;
  final bool alerteDeclenchee;
}

/// Résumé renvoyé par PATCH /patients/me/traitements/{id}.
class TraitementPatchResult {
  const TraitementPatchResult({
    required this.id,
    required this.statut,
    required this.phase,
    this.dateFinPrevue,
    this.maladieNom,
  });

  final String id;
  final String statut;
  final String phase;
  final DateTime? dateFinPrevue;
  final String? maladieNom;

  factory TraitementPatchResult.fromJson(Map<String, dynamic> json) {
    return TraitementPatchResult(
      id: json['id']?.toString() ?? '',
      statut: json['statut'] as String? ?? 'actif',
      phase: json['phase'] as String? ?? '',
      dateFinPrevue:
          DateTime.tryParse(json['date_fin_prevue']?.toString() ?? ''),
      maladieNom: json['maladie_nom'] as String?,
    );
  }
}

class MedicamentsRepository {
  MedicamentsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<MaladieCatalogItem>> listMaladies() async {
    try {
      final res = await _api.get<dynamic>('/onboarding/maladies');
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => MaladieCatalogItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> createTraitement({
    required String maladieId,
    required String phase,
    DateTime? dateDebut,
    DateTime? dateFinPrevue,
  }) async {
    try {
      String? fmt(DateTime? d) {
        if (d == null) return null;
        return '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
      }

      final res = await _api.post<Map<String, dynamic>>(
        '/patients/me/traitements',
        data: {
          'maladie_id': maladieId,
          'phase': phase,
          if (dateDebut != null) 'date_debut': fmt(dateDebut),
          if (dateFinPrevue != null) 'date_fin_prevue': fmt(dateFinPrevue),
        },
      );
      return res.data?['id']?.toString() ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<TraitementPatchResult> updateTraitement({
    required String traitementId,
    String? statut,
    String? phase,
    DateTime? dateFinPrevue,
    bool clearDateFin = false,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (statut != null) data['statut'] = statut;
      if (phase != null) data['phase'] = phase;
      if (clearDateFin) {
        data['date_fin_prevue'] = null;
      } else if (dateFinPrevue != null) {
        data['date_fin_prevue'] =
            '${dateFinPrevue.year.toString().padLeft(4, '0')}-'
            '${dateFinPrevue.month.toString().padLeft(2, '0')}-'
            '${dateFinPrevue.day.toString().padLeft(2, '0')}';
      }
      final res = await _api.patch<Map<String, dynamic>>(
        '/patients/me/traitements/$traitementId',
        data: data,
      );
      return TraitementPatchResult.fromJson(res.data ?? {'id': traitementId});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<ConfiguredMedicament>> listMedicaments({
    String? traitementId,
    bool actifsOnly = false,
  }) async {
    try {
      final res = await _api.get<dynamic>('/patients/me/medicaments');
      final data = res.data;
      if (data is! List) return const [];
      var all = data
          .whereType<Map>()
          .map((e) => ConfiguredMedicament.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (traitementId != null && traitementId.isNotEmpty) {
        all = all.where((m) => m.traitementId == traitementId).toList();
      }
      if (actifsOnly) {
        all = all.where((m) => m.actif).toList();
      }
      return all;
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> createMedicament({
    required String traitementId,
    required String nom,
    required String dosage,
    String forme = 'comprime',
    String? priseAvecRepas,
    required List<String> heures,
    List<String> jours = const ['tous'],
    int? stockRestant,
    int? seuilAlerteStock,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/traitements/$traitementId/medicaments',
        data: {
          'nom': nom.trim(),
          'dosage': dosage.trim(),
          'forme': forme,
          if (priseAvecRepas != null) 'prise_avec_repas': priseAvecRepas,
          if (stockRestant != null) 'stock_restant': stockRestant,
          if (seuilAlerteStock != null) 'seuil_alerte_stock': seuilAlerteStock,
          'horaires': [
            for (final h in heures)
              {
                'heure': _asApiTime(h),
                'jours': jours,
              },
          ],
        },
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<ConfiguredMedicament> updateMedicament({
    required String medicamentId,
    String? nom,
    String? dosage,
    String? forme,
    String? priseAvecRepas,
    String? instructions,
    bool? actif,
    int? seuilAlerteStock,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nom != null) data['nom'] = nom.trim();
      if (dosage != null) data['dosage'] = dosage.trim();
      if (forme != null) data['forme'] = forme;
      if (priseAvecRepas != null) data['prise_avec_repas'] = priseAvecRepas;
      if (instructions != null) data['instructions'] = instructions;
      if (actif != null) data['actif'] = actif;
      if (seuilAlerteStock != null) data['seuil_alerte_stock'] = seuilAlerteStock;
      final res = await _api.patch<Map<String, dynamic>>(
        '/medicaments/$medicamentId',
        data: data,
      );
      return ConfiguredMedicament.fromJson(res.data ?? {'id': medicamentId});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<ConfiguredMedicament> deactivateMedicament(String medicamentId) {
    return updateMedicament(medicamentId: medicamentId, actif: false);
  }

  Future<MedicamentHoraire> addHoraire({
    required String medicamentId,
    required String heure,
    List<String> jours = const ['tous'],
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/medicaments/$medicamentId/horaires',
        data: {
          'heure': _asApiTime(heure),
          'jours': jours,
        },
      );
      return MedicamentHoraire.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> deleteHoraire(String horaireId) async {
    try {
      await _api.delete<Map<String, dynamic>>('/horaires/$horaireId');
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  /// Remplace les horaires actifs : DELETE chacun puis POST les nouveaux.
  Future<void> replaceHoraires({
    required String medicamentId,
    required List<MedicamentHoraire> currentActive,
    required List<String> newHeures,
    List<String> jours = const ['tous'],
  }) async {
    for (final h in currentActive) {
      await deleteHoraire(h.id);
    }
    for (final heure in newHeures) {
      await addHoraire(
        medicamentId: medicamentId,
        heure: heure,
        jours: jours,
      );
    }
  }

  Future<StockUpdateResult> updateStock({
    required String medicamentId,
    required int stockRestant,
  }) async {
    try {
      final res = await _api.patch<Map<String, dynamic>>(
        '/medicaments/$medicamentId/stock',
        data: {'stock_restant': stockRestant},
      );
      final data = res.data ?? {};
      return StockUpdateResult(
        stockRestant: (data['stock_restant'] as num?)?.toInt() ?? stockRestant,
        alerteDeclenchee: data['alerte_declenchee'] as bool? ?? false,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> updateSeuil({
    required String medicamentId,
    required int seuilAlerteStock,
  }) async {
    try {
      await _api.patch<Map<String, dynamic>>(
        '/medicaments/$medicamentId',
        data: {'seuil_alerte_stock': seuilAlerteStock},
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  static String _asApiTime(String raw) {
    final t = raw.trim();
    if (t.length >= 8 && t.contains(':')) {
      return t.length == 5 ? '$t:00' : t;
    }
    if (t.length == 5) return '$t:00';
    return '$t:00';
  }
}

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/aidant_models.dart';
import '../domain/constante_models.dart';
import '../domain/dashboard_models.dart';
import '../domain/profile_settings_models.dart';

class HomeRepository {
  HomeRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<HomeProfile> fetchProfile() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/auth/me');
      return HomeProfile.fromMeJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<HomeProfile> patchMe({
    String? langue,
    String? phone,
    String? fuseauHoraire,
  }) async {
    try {
      final res = await _api.patch<Map<String, dynamic>>(
        '/auth/me',
        data: {
          if (langue != null && langue.isNotEmpty) 'langue': langue,
          if (phone != null) 'phone': phone,
          if (fuseauHoraire != null && fuseauHoraire.isNotEmpty)
            'fuseau_horaire': fuseauHoraire,
        },
      );
      return HomeProfile.fromMeJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> deleteAccount({String? password}) async {
    try {
      await _api.delete<Map<String, dynamic>>(
        '/auth/me',
        data: {
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<PatientSettings> fetchPatientSettings() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/patients/me');
      return PatientSettings.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<PatientSettings> patchPatientSettings({
    bool? notificationsAccordees,
    bool? batterieExemptee,
    bool? notificationsDiscretes,
    String? localisation,
    String? groupeSanguin,
    String? rhesus,
    String? electrophorese,
    int? tailleCm,
    bool? confirmGroupeRhesus,
    bool? confirmElectrophorese,
    bool? confirmTaille,
  }) async {
    try {
      final res = await _api.patch<Map<String, dynamic>>(
        '/patients/me',
        data: {
          if (notificationsAccordees != null)
            'notifications_accordees': notificationsAccordees,
          if (batterieExemptee != null) 'batterie_exemptee': batterieExemptee,
          if (notificationsDiscretes != null)
            'notifications_discretes': notificationsDiscretes,
          if (localisation != null) 'localisation': localisation,
          if (groupeSanguin != null) 'groupe_sanguin': groupeSanguin,
          if (rhesus != null) 'rhesus': rhesus,
          if (electrophorese != null) 'electrophorese': electrophorese,
          if (tailleCm != null) 'taille_cm': tailleCm,
          if (confirmGroupeRhesus != null)
            'confirm_groupe_rhesus': confirmGroupeRhesus,
          if (confirmElectrophorese != null)
            'confirm_electrophorese': confirmElectrophorese,
          if (confirmTaille != null) 'confirm_taille': confirmTaille,
        },
      );
      return PatientSettings.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<ContactUrgence>> listContactsUrgence() async {
    try {
      final res = await _api.get<dynamic>('/patients/me/contacts-urgence');
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => ContactUrgence.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<ContactUrgence> addContactUrgence({
    required String nom,
    required String telephone,
    required String relation,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/patients/me/contacts-urgence',
        data: {
          'nom': nom,
          'telephone': telephone,
          'relation': relation,
        },
      );
      return ContactUrgence.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> deleteContactUrgence(String id) async {
    try {
      await _api.delete<Map<String, dynamic>>(
        '/patients/me/contacts-urgence/$id',
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<PreferenceConsentement>> listPreferencesConsentement() async {
    try {
      final res = await _api.get<dynamic>('/users/me/preferences-consentement');
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map(
            (e) => PreferenceConsentement.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<PreferenceConsentement> patchPreferenceConsentement({
    required String typeAlerte,
    required bool toujoursDemander,
    Map<String, dynamic>? regleAuto,
  }) async {
    try {
      final res = await _api.patch<Map<String, dynamic>>(
        '/users/me/preferences-consentement/$typeAlerte',
        data: {
          'toujours_demander': toujoursDemander,
          if (regleAuto != null) 'regle_auto': regleAuto,
        },
      );
      return PreferenceConsentement.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<VoixRappel> fetchVoixRappel() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/patients/me/voix-rappel');
      return VoixRappel.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  /// Télécharge le binaire de la voix personnalisée (null si absente / erreur).
  Future<List<int>?> downloadVoixRappelFichier() async {
    try {
      final res = await _api.raw.get<List<int>>(
        '/patients/me/voix-rappel/fichier',
        options: Options(responseType: ResponseType.bytes),
      );
      final data = res.data;
      if (data == null || data.isEmpty) return null;
      return data;
    } on DioException {
      return null;
    }
  }

  Future<VoixRappel> putVoixRappelSysteme() async {
    try {
      final form = FormData.fromMap({'type': 'systeme'});
      final res = await _api.raw.put<Map<String, dynamic>>(
        '/patients/me/voix-rappel',
        data: form,
        options: Options(
          // Override BaseOptions application/json — Dio ajoute le boundary.
          contentType: Headers.multipartFormDataContentType,
        ),
      );
      return VoixRappel.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<VoixRappel> putVoixRappelPersonnalisee({
    required String filename,
    required List<int> bytes,
    String? filePath,
  }) async {
    try {
      final MultipartFile fichier;
      if (bytes.isNotEmpty) {
        fichier = MultipartFile.fromBytes(bytes, filename: filename);
      } else if (filePath != null && filePath.isNotEmpty) {
        fichier = await MultipartFile.fromFile(filePath, filename: filename);
      } else {
        throw ApiException(
          code: 'FICHIER_AUDIO_INVALIDE',
          message: 'Fichier audio introuvable.',
          statusCode: 400,
        );
      }
      final form = FormData.fromMap({
        'type': 'personnalisee',
        'fichier': fichier,
      });
      final res = await _api.raw.put<Map<String, dynamic>>(
        '/patients/me/voix-rappel',
        data: form,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
        ),
      );
      return VoixRappel.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<PatientDashboard?> fetchDashboard() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/patients/me/dashboard');
      return PatientDashboard.fromJson(res.data ?? {});
    } on DioException catch (e) {
      final parsed = ApiException.fromResponse(
        e.response?.statusCode,
        e.response?.data,
      );
      if (parsed.code == 'NOT_A_PATIENT') return null;
      ApiClient.throwApi(e);
    }
  }

  Future<void> activatePatient() async {
    try {
      await _api.post<Map<String, dynamic>>('/patients/me/activate');
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<PriseDuJour>> listPrises({required DateTime date}) async {
    try {
      final res = await _api.get<dynamic>(
        '/patients/me/prises',
        queryParameters: {'date': _isoDate(date)},
      );
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => PriseDuJour.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> confirmPrise(
    String priseId, {
    String? clientMutationId,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/prises/$priseId/confirmer',
        data: {
          'canal': 'app',
          if (clientMutationId != null) 'client_mutation_id': clientMutationId,
        },
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> reportPrise(
    String priseId,
    DateTime nouvelleHeure, {
    String? clientMutationId,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/prises/$priseId/reporter',
        data: {
          'nouvelle_heure': nouvelleHeure.toUtc().toIso8601String(),
          if (clientMutationId != null) 'client_mutation_id': clientMutationId,
        },
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  /// POST /sync/push — batch ordonné (Phase 4).
  Future<SyncPushResponse> syncPush(List<Map<String, dynamic>> mutations) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/sync/push',
        data: {'mutations': mutations},
      );
      return SyncPushResponse.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  /// GET /sync/pull — delta cursor (Phase 4).
  Future<SyncPullResponse> syncPull({String? since}) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/sync/pull',
        queryParameters: {
          if (since != null && since.isNotEmpty) 'since': since,
        },
      );
      return SyncPullResponse.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> syncPrisesOffline(List<Map<String, dynamic>> items) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/prises/sync-offline',
        data: items,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<TraitementDetail>> listTraitements() async {
    try {
      final res = await _api.get<dynamic>('/patients/me/traitements');
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => TraitementDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<CheckInEntry>> listCheckIns({required DateTime depuis}) async {
    try {
      final res = await _api.get<dynamic>(
        '/patients/me/check-in',
        queryParameters: {'depuis': _isoDate(depuis)},
      );
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => CheckInEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<CheckInEntry> submitCheckIn(
    String statut, {
    String? clientMutationId,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/patients/me/check-in',
        data: {
          'statut': statut,
          if (clientMutationId != null) 'client_mutation_id': clientMutationId,
        },
      );
      return CheckInEntry.fromJson(res.data ?? {'statut': statut});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<Constante>> listConstantes({required DateTime depuis}) async {
    try {
      final res = await _api.get<dynamic>(
        '/patients/me/constantes',
        queryParameters: {'depuis': depuis.toUtc().toIso8601String()},
      );
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => Constante.tryParse(Map<String, dynamic>.from(e)))
          .whereType<Constante>()
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<ConstanteCreated> createConstante({
    required ConstanteType type,
    required Object valeur,
    required String unite,
    required DateTime mesureAt,
    String? clientMutationId,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/patients/me/constantes',
        data: {
          'type': type.code,
          'valeur': valeur,
          'unite': unite,
          'mesure_at': mesureAt.toUtc().toIso8601String(),
          'source': 'manuel',
          if (clientMutationId != null) 'client_mutation_id': clientMutationId,
        },
      );
      return ConstanteCreated.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  /// Variante string pour SyncEngine (fallback unitaire).
  Future<void> createConstanteRaw({
    required String type,
    required Object valeur,
    required String unite,
    required DateTime mesureAt,
    String source = 'manuel',
    String? clientMutationId,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/patients/me/constantes',
        data: {
          'type': type,
          'valeur': valeur,
          'unite': unite,
          'mesure_at': mesureAt.toUtc().toIso8601String(),
          'source': source,
          if (clientMutationId != null) 'client_mutation_id': clientMutationId,
        },
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<String> createSyncCode() async {
    try {
      final res = await _api.post<Map<String, dynamic>>('/patients/me/sync-code');
      return res.data?['code'] as String? ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> syncAsAidant(String code) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/aidants/me/sync',
        data: {'code': code.trim()},
      );
      return res.data?['message'] as String? ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<AidantRelation>> listAidants() async {
    try {
      final res = await _api.get<dynamic>('/patients/me/aidants');
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => AidantRelation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<AidantRelation> updateAidantPermissions({
    required String aidantId,
    required AidantPermissions permissions,
  }) async {
    try {
      final res = await _api.patch<Map<String, dynamic>>(
        '/patients/me/aidants/$aidantId/permissions',
        data: {'niveau_permission': permissions.toJson()},
      );
      return AidantRelation.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> revokeAidant(String aidantId) async {
    try {
      final res = await _api.delete<Map<String, dynamic>>(
        '/patients/me/aidants/$aidantId',
      );
      return res.data?['message'] as String? ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<AidantPatient>> listAccompaniedPatients() async {
    try {
      final res = await _api.get<dynamic>('/aidants/me/patients');
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => AidantPatient.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      final parsed = ApiException.fromResponse(
        e.response?.statusCode,
        e.response?.data,
      );
      if (parsed.code == 'NOT_AN_AIDANT') return const [];
      ApiClient.throwApi(e);
    }
  }

  Future<AidantObservance> fetchPatientObservance(
    String patientId, {
    DateTime? depuis,
    DateTime? jusquA,
  }) async {
    try {
      String ymd(DateTime d) {
        final y = d.year.toString().padLeft(4, '0');
        final m = d.month.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        return '$y-$m-$day';
      }

      final query = <String, dynamic>{};
      if (depuis != null) query['depuis'] = ymd(depuis);
      if (jusquA != null) query['jusqu_a'] = ymd(jusquA);
      final res = await _api.get<Map<String, dynamic>>(
        '/aidants/me/patients/$patientId/observance',
        queryParameters: query.isEmpty ? null : query,
      );
      return AidantObservance.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<Constante>> listAidantConstantes(String patientId) async {
    try {
      final res = await _api.get<dynamic>(
        '/aidants/me/patients/$patientId/constantes',
      );
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => Constante.tryParse(Map<String, dynamic>.from(e)))
          .whereType<Constante>()
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<SosTicket> triggerSos() async {
    try {
      final res = await _api.post<Map<String, dynamic>>('/patients/me/sos');
      return SosTicket.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<SosConfirmResult> confirmSos(String sosId) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/patients/me/sos/$sosId/confirm',
      );
      return SosConfirmResult.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<SosStatusResult> getSosStatus(String sosId) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/patients/me/sos/$sosId',
      );
      return SosStatusResult.fromJson(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> cancelSos(String sosId) async {
    try {
      final res = await _api.post<Map<String, dynamic>>('/sos/$sosId/annuler');
      return res.data?['message'] as String? ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> registerPushToken({
    required String token,
    String platform = 'android',
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/devices/push-token',
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<List<ActiveSosAlert>> listActiveSosForAidant() async {
    try {
      final res = await _api.get<List<dynamic>>('/aidants/me/sos/active');
      return (res.data ?? [])
          .whereType<Map>()
          .map((e) => ActiveSosAlert.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> ackSosAsAidant(String sosId) async {
    try {
      final res =
          await _api.post<Map<String, dynamic>>('/aidants/me/sos/$sosId/ack');
      return res.data?['message'] as String? ?? '';
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }
}

class SyncPushResultItem {
  const SyncPushResultItem({
    required this.mutationId,
    required this.status,
    this.reason,
  });

  final String mutationId;
  final String status; // applied | duplicate | rejected
  final String? reason;

  factory SyncPushResultItem.fromJson(Map<String, dynamic> json) {
    return SyncPushResultItem(
      mutationId: '${json['mutation_id'] ?? ''}',
      status: '${json['status'] ?? 'rejected'}',
      reason: json['reason'] as String?,
    );
  }
}

class SyncPushResponse {
  const SyncPushResponse({required this.results});

  final List<SyncPushResultItem> results;

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['results'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => SyncPushResultItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <SyncPushResultItem>[];
    return SyncPushResponse(results: list);
  }
}

class SyncPullResponse {
  const SyncPullResponse({
    required this.entities,
    this.nextCursor,
    this.serverTime,
  });

  final List<Map<String, dynamic>> entities;
  final String? nextCursor;
  final DateTime? serverTime;

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['entities'];
    final entities = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    final st = json['server_time'];
    return SyncPullResponse(
      entities: entities,
      nextCursor: json['next_cursor'] as String?,
      serverTime: st is String ? DateTime.tryParse(st)?.toUtc() : null,
    );
  }
}

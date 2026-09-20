import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../../services/reminder_sync.dart';
import '../../../services/sync_engine.dart';
import '../../../services/sync_outbox.dart';
import '../../medicaments/data/medicaments_repository.dart';
import '../data/home_profile_cache.dart';
import '../data/home_repository.dart';
import '../domain/constante_models.dart';
import '../domain/dashboard_models.dart';
import 'home_projection.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(apiClient: ref.watch(apiClientProvider));
});

/// Onglet du shell accueil — Accueil, Soins, Proches, Toi.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

DateTime homeDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool homeSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String homeDayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Lundi de la semaine contenant [d].
DateTime homeWeekStart(DateTime d) {
  final day = homeDateOnly(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

class HomeUiState {
  const HomeUiState({
    this.loading = true,
    this.busy = false,
    this.error,
    this.profile,
    this.dashboard,
    this.selectedDay,
    this.dayPrises,
    this.weekDays = const {},
    this.weekLoading = false,
    this.traitementDetails = const {},
    this.todayCheckIn,
    this.checkInKnown = false,
    this.checkInBusy = false,
    this.constantes = const [],
    this.constantesKnown = false,
  });

  final bool loading;
  final bool busy;
  final String? error;
  final HomeProfile? profile;
  final PatientDashboard? dashboard;
  final DateTime? selectedDay;
  final List<PriseDuJour>? dayPrises;

  /// Observance agrégée localement, clé `YYYY-MM-DD`. Aujourd’hui exclu :
  /// il est recalculé depuis le dashboard pour rester à jour après confirmation.
  final Map<String, DayAdherence> weekDays;
  final bool weekLoading;

  /// `date_fin_prevue` par traitement — absent du dashboard.
  final Map<String, TraitementDetail> traitementDetails;

  final CheckInEntry? todayCheckIn;
  final bool checkInKnown;
  final bool checkInBusy;

  /// Mesures des 30 derniers jours, tous types confondus.
  final List<Constante> constantes;
  final bool constantesKnown;

  List<ConstanteSeries> get constanteSeries =>
      ConstanteSeries.group(constantes);

  bool get hasPatient {
    if (profile?.hasPatientProfile == true) return true;
    final dash = dashboard;
    if (dash == null) return false;
    return dash.traitements.isNotEmpty || dash.prisesAujourdhui.isNotEmpty;
  }

  DateTime get day => homeDateOnly(selectedDay ?? DateTime.now());

  bool get isTodaySelected => homeSameDay(day, DateTime.now());

  List<PriseDuJour> get visiblePrises {
    if (!isTodaySelected && dayPrises != null) return dayPrises!;
    return dashboard?.prisesAujourdhui ?? const [];
  }

  PatientDashboard? get dashboardForDay {
    final d = dashboard;
    if (d == null) return null;
    if (isTodaySelected) return d;
    return PatientDashboard(
      prochaineAction: 'aucune',
      medicamentsConfigures: d.medicamentsConfigures,
      notificationsAccordees: d.notificationsAccordees,
      traitements: d.traitements,
      prisesAujourdhui: visiblePrises,
    );
  }

  /// Les 7 jours lundi → dimanche, aujourd’hui recalculé en direct.
  List<DayAdherence> get week {
    final today = homeDateOnly(DateTime.now());
    final start = homeWeekStart(today);
    return [
      for (var i = 0; i < 7; i++)
        () {
          final d = start.add(Duration(days: i));
          if (homeSameDay(d, today)) {
            return DayAdherence.fromPrises(
              d,
              dashboard?.prisesAujourdhui ?? const [],
            );
          }
          return weekDays[homeDayKey(d)] ?? DayAdherence.empty(d);
        }(),
    ];
  }

  bool get needsCheckIn => checkInKnown && todayCheckIn == null;

  /// Au moins une maladie configurée (traitement actif sur le dashboard).
  bool get hasConfiguredMaladie =>
      (dashboard?.traitements.isNotEmpty ?? false);

  HomeUiState copyWith({
    bool? loading,
    bool? busy,
    String? error,
    HomeProfile? profile,
    PatientDashboard? dashboard,
    DateTime? selectedDay,
    List<PriseDuJour>? dayPrises,
    Map<String, DayAdherence>? weekDays,
    bool? weekLoading,
    Map<String, TraitementDetail>? traitementDetails,
    CheckInEntry? todayCheckIn,
    bool? checkInKnown,
    bool? checkInBusy,
    List<Constante>? constantes,
    bool? constantesKnown,
    bool clearError = false,
    bool clearDashboard = false,
    bool clearDayPrises = false,
    bool clearCheckIn = false,
  }) {
    return HomeUiState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      profile: profile ?? this.profile,
      dashboard: clearDashboard ? null : (dashboard ?? this.dashboard),
      selectedDay: selectedDay ?? this.selectedDay,
      dayPrises: clearDayPrises ? null : (dayPrises ?? this.dayPrises),
      weekDays: weekDays ?? this.weekDays,
      weekLoading: weekLoading ?? this.weekLoading,
      traitementDetails: traitementDetails ?? this.traitementDetails,
      todayCheckIn: clearCheckIn ? null : (todayCheckIn ?? this.todayCheckIn),
      checkInKnown: checkInKnown ?? this.checkInKnown,
      checkInBusy: checkInBusy ?? this.checkInBusy,
      constantes: constantes ?? this.constantes,
      constantesKnown: constantesKnown ?? this.constantesKnown,
    );
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeUiState>((ref) {
  return HomeController(ref);
});

class HomeController extends StateNotifier<HomeUiState> {
  HomeController(this._ref) : super(const HomeUiState());

  final Ref _ref;
  bool _ensureLoadInFlight = false;

  HomeRepository get _repo => _ref.read(homeRepositoryProvider);
  AppDatabase get _db => _ref.read(appDatabaseProvider);
  SyncOutbox get _outbox => _ref.read(syncOutboxProvider);
  SyncEngine get _engine => _ref.read(syncEngineProvider);

  Future<PatientDashboard?> _projectFromLocal() async {
    final base = await _db.readDashboardMeta();
    if (base == null) return null;
    final pending = await _outbox.listPendingForProjection();
    return HomeProjection.projectDashboard(base: base, outbox: pending);
  }

  Future<void> reloadProjection() async {
    final projected = await _projectFromLocal();
    if (projected == null || !mounted) return;
    final profile = state.profile ?? _offlineProfile(projected);
    state = state.copyWith(
      loading: false,
      profile: profile,
      dashboard: projected,
      selectedDay: homeDateOnly(DateTime.now()),
      clearDayPrises: true,
      clearError: true,
    );
    unawaited(syncRemindersFromHome(_ref.read, projected));
  }

  HomeProfile? _offlineProfile(PatientDashboard? dashboard) {
    final prefs = _ref.read(sharedPreferencesProvider);
    final cached = HomeProfileCache.read(prefs);
    if (cached != null) return cached;
    final session = _ref.read(authSessionProvider);
    if (session == null && dashboard == null) return null;

    final hasPatient = session?.hasPatientProfile == true ||
        (dashboard != null &&
            (dashboard.traitements.isNotEmpty ||
                dashboard.prisesAujourdhui.isNotEmpty));

    return HomeProfile(
      nomComplet: '',
      hasPatientProfile: hasPatient,
      isAidant: session?.isAidant ?? false,
    );
  }

  Future<void> _persistProfile(HomeProfile profile) async {
    await HomeProfileCache.save(_ref.read(sharedPreferencesProvider), profile);
  }

  void _scheduleSecondaryLoad() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) unawaited(_loadSecondary());
      });
    });
  }

  Future<void> load({bool secondary = true}) async {
    // Peindre immédiatement depuis caches locaux (profil + Drift).
    final cachedProfile = HomeProfileCache.read(
      _ref.read(sharedPreferencesProvider),
    );
    if (cachedProfile != null && state.profile == null && mounted) {
      state = state.copyWith(profile: cachedProfile, clearError: true);
    }

    final hadCache = state.dashboard != null;
    if (!hadCache) {
      state = state.copyWith(loading: true, clearError: true);
    }

    PatientDashboard? localDashboard;

    try {
      final local = await _projectFromLocal();
      if (local != null && mounted) {
        localDashboard = local;
        final profile =
            state.profile ?? cachedProfile ?? _offlineProfile(local);
        state = state.copyWith(
          loading: false,
          profile: profile,
          dashboard: local,
          selectedDay: homeDateOnly(DateTime.now()),
          clearDayPrises: true,
          clearError: true,
        );
      }
    } catch (_) {}

    try {
      final profile = await _repo.fetchProfile();
      var merged = profile;
      if (profile.hasPatientProfile) {
        try {
          final settings = await _repo.fetchPatientSettings();
          merged = profile.copyWith(
            groupeSanguin: settings.groupeSanguin,
            rhesus: settings.rhesus,
            electrophorese: settings.electrophorese,
            tailleCm: settings.tailleCm,
            photoUrl: settings.photoUrl,
          );
        } catch (_) {}
      }
      await _persistProfile(merged);
      final session = _ref.read(authSessionProvider);
      if (session != null) {
        _ref.read(authSessionProvider.notifier).updateOnboarding(
              step: session.onboardingStep,
              hasPatientProfile: merged.hasPatientProfile,
            );
      }
      PatientDashboard? dashboard;
      if (merged.hasPatientProfile) {
        final fetched = await _repo.fetchDashboard();
        if (fetched != null) {
          await _db.upsertDashboard(fetched);
          final pending = await _outbox.listPendingForProjection();
          dashboard = HomeProjection.projectDashboard(
            base: fetched,
            outbox: pending,
          );
        }
      }
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        profile: merged,
        dashboard: dashboard ?? localDashboard,
        selectedDay: homeDateOnly(DateTime.now()),
        clearDashboard: dashboard == null && localDashboard == null,
        clearDayPrises: true,
        clearError: true,
      );
      final dash = state.dashboard;
      if (dash != null) {
        unawaited(syncRemindersFromHome(_ref.read, dash));
      }
      if (secondary && dash != null) {
        _scheduleSecondaryLoad();
      }
    } catch (e) {
      // Garde projection + profil locaux si le réseau échoue.
      final profile = state.profile ??
          cachedProfile ??
          _offlineProfile(localDashboard);
      if (state.dashboard != null || localDashboard != null) {
        state = state.copyWith(
          loading: false,
          profile: profile,
          dashboard: state.dashboard ?? localDashboard,
          clearError: true,
        );
        final dash = state.dashboard;
        if (dash != null) {
          unawaited(syncRemindersFromHome(_ref.read, dash));
        }
        if (secondary && dash != null) {
          _scheduleSecondaryLoad();
        }
        return;
      }
      state = state.copyWith(
        loading: false,
        profile: profile,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  /// Recharge si l’UI est vide après hot-reload / race auth (anti-boucle).
  Future<void> ensureLoaded() async {
    if (_ensureLoadInFlight) return;
    final s = state;
    final session = _ref.read(authSessionProvider);
    final needsPatientData = session?.hasPatientProfile == true ||
        s.profile?.hasPatientProfile == true;
    if (s.loading) return;
    if (s.dashboard != null && s.profile != null) return;
    if (!needsPatientData && s.profile != null) return;
    _ensureLoadInFlight = true;
    try {
      await load();
    } finally {
      _ensureLoadInFlight = false;
    }
  }

  /// Semaine, traitements et check-in — jamais bloquants, jamais d’erreur
  /// affichée : l’accueil doit rester lisible sur un réseau faible.
  Future<void> _loadSecondary() async {
    state = state.copyWith(weekLoading: true);
    await Future.wait([
      _loadWeek(),
      _loadTraitements(),
      _loadCheckIn(),
      _loadConstantes(),
    ]);
    unawaited(_syncCheckInReminder());
  }

  Future<void> _syncCheckInReminder() async {
    try {
      await _ref.read(checkInReminderServiceProvider).syncSchedule(
            hasMaladie: state.hasConfiguredMaladie,
            alreadyCheckedInToday: state.todayCheckIn != null,
          );
    } catch (e) {
      debugPrint('HomeController: check-in reminder sync failed: $e');
    }
  }

  static const _constantesWindow = Duration(days: 30);

  Future<void> _loadConstantes() async {
    final depuis = DateTime.now().subtract(_constantesWindow);
    try {
      final local = await _db.listConstantesSince(depuis);
      if (mounted && local.isNotEmpty) {
        state = state.copyWith(constantes: local, constantesKnown: true);
      }
    } catch (_) {}
    try {
      final values = await _repo.listConstantes(depuis: depuis);
      if (!mounted) return;
      await _db.replaceConstantes(values);
      state = state.copyWith(constantes: values, constantesKnown: true);
    } catch (_) {
      if (!mounted) return;
      if (!state.constantesKnown) {
        try {
          final local = await _db.listConstantesSince(depuis);
          state = state.copyWith(
            constantes: local,
            constantesKnown: local.isNotEmpty,
          );
        } catch (_) {}
      }
    }
  }

  Future<ConstanteCreated> addConstante({
    required ConstanteType type,
    required Object valeur,
    required String unite,
    required DateTime mesureAt,
  }) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final clientId = const Uuid().v4();
      await _db.transaction(() async {
        await _db.upsertConstanteLocal(
          id: clientId,
          typeCode: type.code,
          valeur: valeur,
          unite: unite,
          mesureAt: mesureAt,
        );
        await _engine.enqueueCreateConstante(
          clientId: clientId,
          type: type.code,
          valeur: valeur,
          unite: unite,
          mesureAt: mesureAt,
        );
      });
      final local = await _db.listConstantesSince(
        DateTime.now().subtract(_constantesWindow),
      );
      state = state.copyWith(
        busy: false,
        constantes: local,
        constantesKnown: true,
      );
      unawaited(_engine.flush(force: true));
      return const ConstanteCreated(
        tendance: 'stable',
        message: 'Mesure enregistrée. Elle sera synchronisée dès que possible.',
      );
    } catch (e) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> _loadWeek() async {
    final today = homeDateOnly(DateTime.now());
    final start = homeWeekStart(today);
    final targets = [
      for (var i = 0; i < 7; i++) start.add(Duration(days: i)),
    ].where((d) => !d.isAfter(today)).toList();

    if (targets.isEmpty) {
      state = state.copyWith(weekLoading: false);
      return;
    }

    final merged = Map<String, DayAdherence>.from(state.weekDays);
    for (final d in targets) {
      if (homeSameDay(d, today)) continue;
      try {
        final local = await _db.listPrisesForDate(homeDayKey(d));
        if (local.isNotEmpty) {
          merged[homeDayKey(d)] = DayAdherence.fromPrises(d, local);
        }
      } catch (_) {}
    }
    if (mounted) {
      state = state.copyWith(weekDays: merged);
    }

    final results = await Future.wait(
      targets.map((d) async {
        if (homeSameDay(d, today)) return null;
        try {
          final prises = await _repo.listPrises(date: d);
          try {
            await _db.upsertPrises(prises);
          } catch (_) {}
          return MapEntry(homeDayKey(d), DayAdherence.fromPrises(d, prises));
        } catch (_) {
          return null;
        }
      }),
    );

    for (final entry in results) {
      if (entry != null) merged[entry.key] = entry.value;
    }
    if (!mounted) return;
    state = state.copyWith(weekDays: merged, weekLoading: false);
  }

  Future<void> _loadTraitements() async {
    try {
      final details = await _repo.listTraitements();
      await _db.upsertTraitements(details);
      if (!mounted) return;
      state = state.copyWith(
        traitementDetails: {for (final t in details) t.id: t},
      );
    } catch (_) {
      try {
        final cached = await _db.readTraitementDetails();
        if (cached.isNotEmpty && mounted) {
          state = state.copyWith(traitementDetails: cached);
        }
      } catch (_) {}
    }
  }

  Future<void> _loadCheckIn() async {
    final today = homeDateOnly(DateTime.now());
    final key = homeDayKey(today);
    try {
      final local = await _db.getCheckInForDateKey(key);
      if (mounted && local != null) {
        state = state.copyWith(
          todayCheckIn: local,
          checkInKnown: true,
        );
      }
    } catch (_) {}
    try {
      final entries = await _repo.listCheckIns(depuis: today);
      if (!mounted) return;
      CheckInEntry? todays;
      for (final e in entries) {
        if (homeSameDay(e.date, today)) todays = e;
      }
      if (todays != null) {
        await _db.upsertCheckInLocal(
          id: 'server-$key',
          date: todays.date,
          statut: todays.statut,
        );
      }
      state = state.copyWith(
        todayCheckIn: todays,
        checkInKnown: true,
        clearCheckIn: todays == null,
      );
    } catch (_) {
      if (!mounted) return;
      if (!state.checkInKnown) {
        try {
          final local = await _db.getCheckInForDateKey(key);
          state = state.copyWith(
            todayCheckIn: local,
            checkInKnown: local != null,
            clearCheckIn: local == null,
          );
        } catch (_) {}
      }
    }
  }

  Future<void> submitCheckIn(String statut) async {
    state = state.copyWith(checkInBusy: true, clearError: true);
    try {
      final today = homeDateOnly(DateTime.now());
      final key = homeDayKey(today);
      final existing = await _db.getCheckInForDateKey(key);
      if (existing != null || state.todayCheckIn != null) {
        state = state.copyWith(
          checkInBusy: false,
          todayCheckIn: existing ?? state.todayCheckIn,
          checkInKnown: true,
        );
        return;
      }
      final clientId = const Uuid().v4();
      await _db.transaction(() async {
        await _db.upsertCheckInLocal(
          id: clientId,
          date: today,
          statut: statut,
        );
        await _engine.enqueueCreateCheckIn(dateKey: key, statut: statut);
      });
      state = state.copyWith(
        checkInBusy: false,
        todayCheckIn: CheckInEntry(date: today, statut: statut),
        checkInKnown: true,
      );
      unawaited(_engine.flush(force: true));
      unawaited(_syncCheckInReminder());
    } catch (e) {
      state = state.copyWith(checkInBusy: false);
      if (e is ApiException && e.code == 'CHECK_IN_DEJA_FAIT_AUJOURDHUI') {
        await _loadCheckIn();
        return;
      }
      rethrow;
    }
  }

  Future<void> activateFollowUp() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _repo.activatePatient();
      await load();
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  /// Marque un traitement terminé (API) puis resync alarmes / check-in.
  Future<void> terminateTraitement(String traitementId) async {
    await _patchTraitementStatut(traitementId, 'termine');
  }

  /// Suspend un traitement (plus de rappels) — disparaît du dashboard actifs.
  Future<void> suspendTraitement(String traitementId) async {
    await _patchTraitementStatut(traitementId, 'suspendu');
  }

  /// Reprend un traitement suspendu.
  Future<void> resumeTraitement(String traitementId) async {
    await _patchTraitementStatut(traitementId, 'actif');
  }

  Future<void> _patchTraitementStatut(String traitementId, String statut) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _ref.read(medicamentsRepositoryProvider).updateTraitement(
            traitementId: traitementId,
            statut: statut,
          );
      await load();
      state = state.copyWith(busy: false);
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  /// Après mutation médoc / horaires / phase — recharge dashboard + alarmes.
  Future<void> refreshAfterMedMutation() async {
    await load();
  }

  Future<void> updateProfile(HomeProfile profile) async {
    state = state.copyWith(profile: profile);
  }

  Future<void> confirmPrise(String id) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _db.transaction(() async {
        await _db.updatePriseLocal(id: id, statut: 'confirmee');
        await _engine.enqueueConfirm(priseId: id);
      });
      await reloadProjection();
      state = state.copyWith(busy: false);
      unawaited(_engine.flush(force: true));
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  /// Confirme les prises encore confirmables d’un créneau (`en_attente` ou `manquee`).
  Future<void> confirmPrises(List<String> ids) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (unique.isEmpty) return;
    if (unique.length == 1) {
      await confirmPrise(unique.first);
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _db.transaction(() async {
        for (final id in unique) {
          await _db.updatePriseLocal(id: id, statut: 'confirmee');
          await _engine.enqueueConfirm(priseId: id);
        }
      });
      await reloadProjection();
      state = state.copyWith(busy: false);
      unawaited(_engine.flush(force: true));
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<void> reportPrise(String id, DateTime nouvelleHeure) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _db.transaction(() async {
        await _db.updatePriseLocal(
          id: id,
          heurePrevue: nouvelleHeure,
          statut: 'en_attente',
        );
        await _engine.enqueueReport(priseId: id, nouvelleHeure: nouvelleHeure);
      });
      await reloadProjection();
      state = state.copyWith(busy: false);
      unawaited(_engine.flush(force: true));
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  /// Reporte toutes les prises d’un créneau à la même heure (DoseSlot).
  Future<void> reportPrises(List<String> ids, DateTime nouvelleHeure) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (unique.isEmpty) return;
    if (unique.length == 1) {
      await reportPrise(unique.first, nouvelleHeure);
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _db.transaction(() async {
        for (final id in unique) {
          await _db.updatePriseLocal(
            id: id,
            heurePrevue: nouvelleHeure,
            statut: 'en_attente',
          );
          await _engine.enqueueReport(
            priseId: id,
            nouvelleHeure: nouvelleHeure,
          );
        }
      });
      await reloadProjection();
      state = state.copyWith(busy: false);
      unawaited(_engine.flush(force: true));
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<void> selectDay(DateTime day) async {
    final d = homeDateOnly(day);
    if (homeSameDay(d, state.day)) return;
    if (homeSameDay(d, DateTime.now())) {
      state = state.copyWith(selectedDay: d, clearDayPrises: true);
      return;
    }
    state = state.copyWith(selectedDay: d, busy: true, clearError: true);
    try {
      final local = await _db.listPrisesForDate(homeDayKey(d));
      final pending = await _outbox.listPendingForProjection();
      final projected = HomeProjection.applyOutbox(
        snapshot: local,
        outbox: pending,
      );
      if (projected.isNotEmpty && mounted) {
        state = state.copyWith(busy: false, dayPrises: projected);
      }
      final prises = await _repo.listPrises(date: d);
      await _db.upsertPrises(prises);
      final pending2 = await _outbox.listPendingForProjection();
      final merged = HomeProjection.applyOutbox(
        snapshot: prises,
        outbox: pending2,
      );
      if (!mounted) return;
      state = state.copyWith(busy: false, dayPrises: merged);
    } catch (e) {
      if (state.dayPrises != null) {
        state = state.copyWith(busy: false);
        return;
      }
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<String> createShareCode() => _repo.createSyncCode();

  Future<String> joinWithCode(String code) => _repo.syncAsAidant(code);
}

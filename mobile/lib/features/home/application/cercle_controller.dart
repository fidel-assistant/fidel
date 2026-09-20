import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../services/sos_service.dart';
import '../../auth/application/auth_providers.dart';
import '../data/home_repository.dart';
import '../domain/aidant_models.dart';
import '../domain/profile_settings_models.dart';
import 'home_controller.dart';

class CercleUiState {
  const CercleUiState({
    this.accompaniedPatients = const [],
    this.aidants = const [],
    this.contactsCount = 0,
    this.activeSos = const [],
    this.patientSignals = const {},
    this.loading = false,
    this.busy = false,
    this.error,
    this.sosTicket,
    this.hasPatient = false,
    this.isAidant = false,
    this.loadedOnce = false,
  });

  final List<AidantPatient> accompaniedPatients;
  final List<AidantRelation> aidants;
  final int contactsCount;
  final List<ActiveSosAlert> activeSos;
  final Map<String, AidantPatientSignal> patientSignals;
  final bool loading;
  final bool busy;
  final String? error;
  final SosTicket? sosTicket;

  /// Capacités résolues (session ∪ profil home) — source pour l’UI.
  final bool hasPatient;
  final bool isAidant;
  final bool loadedOnce;

  bool get hasContacts => contactsCount > 0;

  AidantPatientSignal? signalFor(String patientId) => patientSignals[patientId];

  CercleUiState copyWith({
    List<AidantPatient>? accompaniedPatients,
    List<AidantRelation>? aidants,
    int? contactsCount,
    List<ActiveSosAlert>? activeSos,
    Map<String, AidantPatientSignal>? patientSignals,
    bool? loading,
    bool? busy,
    String? error,
    SosTicket? sosTicket,
    bool? hasPatient,
    bool? isAidant,
    bool? loadedOnce,
    bool clearError = false,
    bool clearSos = false,
  }) {
    return CercleUiState(
      accompaniedPatients: accompaniedPatients ?? this.accompaniedPatients,
      aidants: aidants ?? this.aidants,
      contactsCount: contactsCount ?? this.contactsCount,
      activeSos: activeSos ?? this.activeSos,
      patientSignals: patientSignals ?? this.patientSignals,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      sosTicket: clearSos ? null : (sosTicket ?? this.sosTicket),
      hasPatient: hasPatient ?? this.hasPatient,
      isAidant: isAidant ?? this.isAidant,
      loadedOnce: loadedOnce ?? this.loadedOnce,
    );
  }
}

class CercleController extends StateNotifier<CercleUiState> {
  CercleController(this._ref) : super(const CercleUiState());

  final Ref _ref;
  int _loadGen = 0;
  bool _persistentShortcutPosted = false;

  HomeRepository get _repo => _ref.read(homeRepositoryProvider);

  ({bool hasPatient, bool isAidant}) _caps() {
    final profile = _ref.read(homeControllerProvider).profile;
    final session = _ref.read(authSessionProvider);
    return (
      hasPatient: profile?.hasPatientProfile == true ||
          session?.hasPatientProfile == true,
      isAidant: profile?.isAidant == true || session?.isAidant == true,
    );
  }

  /// Attend jusqu’à ~2 s que le profil home soit peuplé (boot / hot restart).
  Future<void> _waitForHomeProfile() async {
    for (var i = 0; i < 8; i++) {
      final home = _ref.read(homeControllerProvider);
      if (home.profile != null) return;
      if (!home.loading && home.profile == null && i >= 3) {
        // Home a fini sans profil → on continue avec la session.
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<({List<ActiveSosAlert> sos, Map<String, AidantPatientSignal> signals})>
      _loadAidantSignals(List<AidantPatient> patients) async {
    if (patients.isEmpty) {
      return (sos: const <ActiveSosAlert>[], signals: const <String, AidantPatientSignal>{});
    }

    List<ActiveSosAlert> activeSos = const [];
    try {
      activeSos = await _repo.listActiveSosForAidant();
    } catch (_) {
      activeSos = const [];
    }
    final sosPatientIds = {
      for (final alert in activeSos)
        if (alert.patientId.isNotEmpty) alert.patientId,
    };

    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final signals = <String, AidantPatientSignal>{};

    await Future.wait(
      patients.map((patient) async {
        if (sosPatientIds.contains(patient.id)) {
          signals[patient.id] = AidantPatientSignal.sosActive;
          return;
        }
        if (!patient.permissions.observance) {
          signals[patient.id] = AidantPatientSignal.permissionLimited;
          return;
        }
        try {
          final today = await _repo.fetchPatientObservance(
            patient.id,
            depuis: day,
            jusquA: day,
          );
          signals[patient.id] = deriveAidantPatientSignal(
            hasActiveSos: false,
            canSeeObservance: true,
            today: today,
          );
        } catch (_) {
          signals[patient.id] = AidantPatientSignal.permissionLimited;
        }
      }),
    );

    return (sos: activeSos, signals: signals);
  }

  Future<void> load({bool force = false}) async {
    // Évite de recharger + re-poster la notif SOS à chaque resume / tab switch.
    if (!force && state.loadedOnce && !state.loading) {
      return;
    }

    final gen = ++_loadGen;
    state = state.copyWith(loading: true, clearError: true);

    await _waitForHomeProfile();
    if (gen != _loadGen) return;

    final caps = _caps();
    state = state.copyWith(
      hasPatient: caps.hasPatient,
      isAidant: caps.isAidant,
    );

    if (!caps.hasPatient && !caps.isAidant) {
      if (!mounted) return;
      if (_persistentShortcutPosted) {
        unawaited(_ref.read(sosServiceProvider).hidePersistentNotification());
        _persistentShortcutPosted = false;
      }
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        accompaniedPatients: const [],
        aidants: const [],
        contactsCount: 0,
        activeSos: const [],
        patientSignals: const {},
      );
      return;
    }

    try {
      final futures = await Future.wait([
        caps.isAidant
            ? _repo.listAccompaniedPatients()
            : Future.value(const <AidantPatient>[]),
        caps.hasPatient
            ? _repo.listAidants()
            : Future.value(const <AidantRelation>[]),
        caps.hasPatient
            ? _repo.listContactsUrgence()
            : Future.value(const []),
      ]);
      if (!mounted || gen != _loadGen) return;
      final contacts = futures[2] as List<ContactUrgence>;
      final patients = futures[0] as List<AidantPatient>;
      unawaited(_ref.read(sosServiceProvider).cacheContacts(contacts));

      // Raccourci lock-screen : uniquement profil patient, une seule fois
      // par session process (pas à chaque ouverture / resume).
      if (caps.hasPatient) {
        if (!_persistentShortcutPosted) {
          _persistentShortcutPosted = true;
          unawaited(
            _ref.read(sosServiceProvider).ensurePersistentNotification(
                  title: 'SOS Fidel',
                  body: 'Appuie pour alerter tes aidants',
                ),
          );
        }
      } else if (_persistentShortcutPosted) {
        _persistentShortcutPosted = false;
        unawaited(_ref.read(sosServiceProvider).hidePersistentNotification());
      }

      final aidantExtras = caps.isAidant
          ? await _loadAidantSignals(patients)
          : (
              sos: const <ActiveSosAlert>[],
              signals: const <String, AidantPatientSignal>{},
            );
      if (!mounted || gen != _loadGen) return;

      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        hasPatient: caps.hasPatient,
        isAidant: caps.isAidant,
        accompaniedPatients: patients,
        aidants: futures[1] as List<AidantRelation>,
        contactsCount: contacts.length,
        activeSos: aidantExtras.sos,
        patientSignals: aidantExtras.signals,
        clearError: true,
      );
    } catch (e) {
      if (!mounted || gen != _loadGen) return;
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  /// Retire un SOS acquitté et recalcule les signaux carte.
  Future<void> onSosAcked(String sosId) async {
    final remaining =
        state.activeSos.where((s) => s.sosId != sosId).toList(growable: false);
    state = state.copyWith(activeSos: remaining);
    if (!state.isAidant) return;
    try {
      final refreshed = await _loadAidantSignals(state.accompaniedPatients);
      if (!mounted) return;
      state = state.copyWith(
        activeSos: refreshed.sos,
        patientSignals: refreshed.signals,
      );
    } catch (_) {}
  }

  Future<SosTicket> triggerSos() async {
    state = state.copyWith(busy: true, clearError: true, clearSos: true);
    try {
      final ticket = await _repo.triggerSos();
      state = state.copyWith(busy: false, sosTicket: ticket);
      return ticket;
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<String> cancelSos(String sosId) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final msg = await _repo.cancelSos(sosId);
      state = state.copyWith(busy: false, clearSos: true);
      return msg;
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  void clearSosState() {
    state = state.copyWith(clearSos: true);
  }
}

/// KeepAlive : IndexedStack garde l’onglet monté, mais on évite de perdre
/// l’état au moindre unwatch.
final cercleControllerProvider =
    StateNotifierProvider<CercleController, CercleUiState>((ref) {
  return CercleController(ref);
});

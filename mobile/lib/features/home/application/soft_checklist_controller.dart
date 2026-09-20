import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/locale/locale_controller.dart';
import '../domain/profile_settings_models.dart';
import 'home_controller.dart';

/// Compléments soft Accueil (§4.3 auth-onboarding) — jamais bloquants.
enum SoftChecklistKind {
  phone,
  contactUrgence,
  voixRappel,
  photo,
}

class SoftChecklistState {
  const SoftChecklistState({
    this.loading = false,
    this.known = false,
    this.missing = const [],
  });

  final bool loading;
  final bool known;
  final List<SoftChecklistKind> missing;

  SoftChecklistState copyWith({
    bool? loading,
    bool? known,
    List<SoftChecklistKind>? missing,
  }) {
    return SoftChecklistState(
      loading: loading ?? this.loading,
      known: known ?? this.known,
      missing: missing ?? this.missing,
    );
  }
}

final softChecklistControllerProvider =
    StateNotifierProvider<SoftChecklistController, SoftChecklistState>((ref) {
  return SoftChecklistController(ref);
});

class SoftChecklistController extends StateNotifier<SoftChecklistState> {
  SoftChecklistController(this._ref) : super(const SoftChecklistState());

  static const _dismissedKey = 'soft_checklist_dismissed_v1';

  final Ref _ref;

  SharedPreferences get _prefs => _ref.read(sharedPreferencesProvider);

  Set<String> _dismissedIds() {
    return _prefs.getStringList(_dismissedKey)?.toSet() ?? {};
  }

  Future<void> refresh() async {
    final home = _ref.read(homeControllerProvider);
    if (!home.hasPatient) {
      state = const SoftChecklistState(known: true, missing: []);
      return;
    }

    state = state.copyWith(loading: !state.known);
    final repo = _ref.read(homeRepositoryProvider);
    final phone = home.profile?.phone?.trim() ?? '';
    final dismissed = _dismissedIds();

    var hasContact = true;
    var hasCustomVoix = true;
    var hasPhoto = true;

    try {
      late final List<ContactUrgence> contacts;
      late final VoixRappel voix;
      late final PatientSettings settings;
      await Future.wait([
        repo.listContactsUrgence().then((v) => contacts = v),
        repo.fetchVoixRappel().then((v) => voix = v),
        repo.fetchPatientSettings().then((v) => settings = v),
      ]);
      hasContact = contacts.isNotEmpty;
      hasCustomVoix = voix.isPersonnalisee;
      final photoUrl = settings.photoUrl?.trim() ?? '';
      hasPhoto = photoUrl.isNotEmpty;
    } catch (_) {
      // Soft : téléphone seul si le réseau échoue.
    }

    final missing = <SoftChecklistKind>[
      if (phone.isEmpty && !dismissed.contains(SoftChecklistKind.phone.name))
        SoftChecklistKind.phone,
      if (!hasContact &&
          !dismissed.contains(SoftChecklistKind.contactUrgence.name))
        SoftChecklistKind.contactUrgence,
      if (!hasCustomVoix &&
          !dismissed.contains(SoftChecklistKind.voixRappel.name))
        SoftChecklistKind.voixRappel,
      if (!hasPhoto && !dismissed.contains(SoftChecklistKind.photo.name))
        SoftChecklistKind.photo,
    ];

    if (!mounted) return;
    state = SoftChecklistState(
      loading: false,
      known: true,
      missing: missing.take(4).toList(),
    );
  }

  Future<void> dismiss(SoftChecklistKind kind) async {
    final ids = _dismissedIds()..add(kind.name);
    await _prefs.setStringList(_dismissedKey, ids.toList());
    if (!mounted) return;
    state = state.copyWith(
      missing: state.missing.where((k) => k != kind).toList(),
    );
  }

  void clear() {
    state = const SoftChecklistState();
  }
}

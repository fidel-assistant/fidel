import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../medicaments/data/medicaments_repository.dart';
import '../../medicaments/presentation/widgets/med_days_selector.dart';
import '../../medicaments/presentation/widgets/med_forme_selector.dart';
import '../../medicaments/presentation/widgets/med_times_editor.dart';
import '../application/home_controller.dart';
import '../domain/dashboard_models.dart';
import 'widgets/home_skeleton.dart';

/// Détail / gestion d’un traitement — éditer médocs, horaires, suspendre, phase.
class ManageTraitementScreen extends ConsumerStatefulWidget {
  const ManageTraitementScreen({
    super.key,
    required this.traitementId,
    this.initial,
  });

  final String traitementId;
  final DashboardTraitement? initial;

  @override
  ConsumerState<ManageTraitementScreen> createState() =>
      _ManageTraitementScreenState();
}

class _ManageTraitementScreenState
    extends ConsumerState<ManageTraitementScreen> {
  bool _loading = true;
  bool _busy = false;
  String _maladieNom = '';
  String _phase = 'en_cours';
  String _statut = 'actif';
  DateTime? _dateFinPrevue;
  List<ConfiguredMedicament> _meds = const [];

  @override
  void initState() {
    super.initState();
    final dash = widget.initial;
    if (dash != null) {
      _maladieNom = dash.maladieNom;
      _phase = dash.phase.isEmpty ? 'en_cours' : dash.phase;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final home = ref.read(homeControllerProvider);
      final detail = home.traitementDetails[widget.traitementId];
      final fromDash = home.dashboard?.traitements
          .where((t) => t.id == widget.traitementId)
          .firstOrNull;

      final repo = ref.read(medicamentsRepositoryProvider);
      final meds = await repo.listMedicaments(
        traitementId: widget.traitementId,
        actifsOnly: true,
      );

      if (!mounted) return;
      setState(() {
        if (fromDash != null) {
          _maladieNom = fromDash.maladieNom;
          _phase = fromDash.phase.isEmpty ? _phase : fromDash.phase;
        }
        if (detail != null) {
          _dateFinPrevue = detail.dateFinPrevue;
          if (detail.phase.isNotEmpty) _phase = detail.phase;
          if (detail.statut.isNotEmpty) _statut = detail.statut;
          if (detail.maladieNom != null && detail.maladieNom!.isNotEmpty) {
            _maladieNom = detail.maladieNom!;
          }
        }
        if (_maladieNom.isEmpty && widget.initial != null) {
          _maladieNom = widget.initial!.maladieNom;
        }
        _meds = meds;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.error(
        context,
        e is ApiException
            ? e.message
            : AppLocalizations.of(context).genericError,
      );
    }
  }

  Future<void> _afterMutation() async {
    await ref.read(homeControllerProvider.notifier).refreshAfterMedMutation();
    if (!mounted) return;
    await _load();
  }

  Future<void> _setStatut(String statut) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(medicamentsRepositoryProvider).updateTraitement(
                traitementId: widget.traitementId,
                statut: statut,
              );
      await ref.read(homeControllerProvider.notifier).refreshAfterMedMutation();
      if (!mounted) return;
      setState(() {
        _statut = result.statut;
        if (result.phase.isNotEmpty) _phase = result.phase;
        if (result.dateFinPrevue != null) {
          _dateFinPrevue = result.dateFinPrevue;
        }
        if (result.maladieNom != null && result.maladieNom!.isNotEmpty) {
          _maladieNom = result.maladieNom!;
        }
        _busy = false;
      });
      final toast = switch (statut) {
        'suspendu' => l10n.manageTraitementSuspendedToast,
        'actif' => l10n.manageTraitementResumedToast,
        'termine' => l10n.homeTreatmentEndedToast,
        _ => l10n.profileSaved,
      };
      AppToast.success(context, toast);
      if (statut == 'termine' && mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  Future<void> _savePhaseAndDate({
    required String phase,
    DateTime? dateFin,
    bool clearDateFin = false,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(medicamentsRepositoryProvider).updateTraitement(
                traitementId: widget.traitementId,
                phase: phase,
                dateFinPrevue: clearDateFin ? null : dateFin,
                clearDateFin: clearDateFin,
              );
      await ref.read(homeControllerProvider.notifier).refreshAfterMedMutation();
      if (!mounted) return;
      setState(() {
        _phase = result.phase.isNotEmpty ? result.phase : phase;
        _dateFinPrevue = clearDateFin ? null : (result.dateFinPrevue ?? dateFin);
        _busy = false;
      });
      AppToast.success(context, l10n.manageTraitementUpdatedToast);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  Future<void> _confirmSuspend() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.manageTraitementSuspendTitle),
        content: Text(l10n.manageTraitementSuspendBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.manageTraitementSuspendConfirm),
          ),
        ],
      ),
    );
    if (ok == true) await _setStatut('suspendu');
  }

  Future<void> _confirmTerminate() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homeTreatmentEndTitle),
        content: Text('$_maladieNom\n\n${l10n.homeTreatmentEndBody}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.homeTreatmentEndConfirm),
          ),
        ],
      ),
    );
    if (ok == true) await _setStatut('termine');
  }

  Future<void> _confirmDeactivate(ConfiguredMedicament med) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.manageMedDeactivateTitle),
        content: Text(l10n.manageMedDeactivateBody(med.nom)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.manageMedDeactivateConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(medicamentsRepositoryProvider)
          .deactivateMedicament(med.id);
      await _afterMutation();
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.success(context, l10n.manageMedDeactivatedToast);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  Future<void> _openEditMed(ConfiguredMedicament med) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _EditMedSheet(medicament: med),
    );
    if (updated == true) {
      await _afterMutation();
    }
  }

  Future<void> _openEditTraitementMeta() async {
    final result = await showModalBottomSheet<_TraitementMetaDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _EditTraitementMetaSheet(
        phase: _phase,
        dateFinPrevue: _dateFinPrevue,
      ),
    );
    if (result == null) return;
    await _savePhaseAndDate(
      phase: result.phase,
      dateFin: result.dateFin,
      clearDateFin: result.clearDateFin,
    );
  }

  String? _phaseLabel(AppLocalizations l10n, String phase) {
    return switch (phase) {
      'debut' => l10n.homePhaseDebut,
      'en_cours' => l10n.homePhaseEnCours,
      'maintenance' => l10n.homePhaseMaintenance,
      'inconnu' => l10n.onboardingPhaseInconnu,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMd(locale);
    final suspended = _statut == 'suspendu';

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n.manageTraitementTitle,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: const Icon(IconsaxPlusLinear.arrow_left),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: _loading
            ? const SafeArea(child: ProfilePageSkeleton(rows: 6))
            : Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Text(
                        _maladieNom.isEmpty
                            ? l10n.manageTraitementTitle
                            : _maladieNom,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_phaseLabel(l10n, _phase) != null)
                            _MetaChip(
                              label: _phaseLabel(l10n, _phase)!,
                              tokens: tokens,
                            ),
                          if (suspended)
                            _MetaChip(
                              label: l10n.manageTraitementSuspendedBadge,
                              tokens: tokens,
                              emphasize: true,
                            ),
                          if (_dateFinPrevue != null)
                            _MetaChip(
                              label: l10n.manageTraitementEndDate(
                                dateFmt.format(_dateFinPrevue!),
                              ),
                              tokens: tokens,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      PremiumCard(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.manageTraitementSection,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _openEditTraitementMeta,
                              icon: const Icon(IconsaxPlusLinear.edit, size: 18),
                              label: Text(l10n.manageTraitementEditMeta),
                            ),
                            const SizedBox(height: 8),
                            if (suspended)
                              FilledButton.icon(
                                onPressed:
                                    _busy ? null : () => _setStatut('actif'),
                                icon: const Icon(
                                  IconsaxPlusLinear.play,
                                  size: 18,
                                ),
                                label: Text(l10n.manageTraitementResume),
                              )
                            else ...[
                              OutlinedButton.icon(
                                onPressed: _busy ? null : _confirmSuspend,
                                icon: const Icon(
                                  IconsaxPlusLinear.pause,
                                  size: 18,
                                ),
                                label: Text(l10n.manageTraitementSuspend),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _busy ? null : _confirmTerminate,
                                child: Text(l10n.homeTreatmentEndAction),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.manageMedsSection,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _busy
                                ? null
                                : () async {
                                    await context.push(
                                      '/home/medicaments',
                                      extra: widget.traitementId,
                                    );
                                    if (mounted) await _load();
                                  },
                            icon: const Icon(IconsaxPlusLinear.add, size: 18),
                            label: Text(l10n.manageMedAdd),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_meds.isEmpty)
                        PremiumCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.manageMedsEmpty,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: tokens.textSecondary,
                            ),
                          ),
                        )
                      else
                        for (final med in _meds) ...[
                          PremiumCard(
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med.nom,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              med.dosage,
                                              if (med.activeHoraires.isNotEmpty)
                                                med.activeHoraires
                                                    .map((h) => h.heure)
                                                    .join(' · '),
                                            ].where((s) => s.isNotEmpty).join(' · '),
                                            style: TextStyle(
                                              fontFamily: AppTheme.fontFamily,
                                              fontSize: 13,
                                              color: tokens.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n.manageMedEdit,
                                      onPressed:
                                          _busy ? null : () => _openEditMed(med),
                                      icon: const Icon(
                                        IconsaxPlusLinear.edit,
                                        size: 20,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n.manageMedDeactivate,
                                      onPressed: _busy
                                          ? null
                                          : () => _confirmDeactivate(med),
                                      icon: Icon(
                                        IconsaxPlusLinear.trash,
                                        size: 20,
                                        color: tokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                  if (_busy)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x33000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.tokens,
    this.emphasize = false,
  });

  final String label;
  final ThemeTokens tokens;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasize
            ? AppColors.primary.withValues(alpha: 0.12)
            : tokens.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: emphasize ? AppColors.primary : tokens.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: emphasize ? AppColors.primary : tokens.textSecondary,
        ),
      ),
    );
  }
}

class _TraitementMetaDraft {
  const _TraitementMetaDraft({
    required this.phase,
    this.dateFin,
    this.clearDateFin = false,
  });

  final String phase;
  final DateTime? dateFin;
  final bool clearDateFin;
}

class _EditTraitementMetaSheet extends StatefulWidget {
  const _EditTraitementMetaSheet({
    required this.phase,
    this.dateFinPrevue,
  });

  final String phase;
  final DateTime? dateFinPrevue;

  @override
  State<_EditTraitementMetaSheet> createState() =>
      _EditTraitementMetaSheetState();
}

class _EditTraitementMetaSheetState extends State<_EditTraitementMetaSheet> {
  late String _phase;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _phase = widget.phase.isEmpty ? 'en_cours' : widget.phase;
    _dateFin = widget.dateFinPrevue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMMd(locale);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.manageTraitementEditMeta,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.manageTraitementPhaseLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in [
                ('debut', l10n.onboardingPhaseDebut),
                ('en_cours', l10n.onboardingPhaseEnCours),
                ('maintenance', l10n.onboardingPhaseMaintenance),
                ('inconnu', l10n.onboardingPhaseInconnu),
              ])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: _phase == entry.$1,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _phase = entry.$1);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.configDateFinLabel),
            subtitle: Text(
              _dateFin == null
                  ? l10n.configDateFinClear
                  : dateFmt.format(_dateFin!),
            ),
            trailing: const Icon(IconsaxPlusLinear.calendar),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateFin ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) setState(() => _dateFin = picked);
            },
          ),
          if (_dateFin != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _dateFin = null),
                child: Text(l10n.configDateFinClear),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final cleared = widget.dateFinPrevue != null && _dateFin == null;
              Navigator.pop(
                context,
                _TraitementMetaDraft(
                  phase: _phase,
                  dateFin: _dateFin,
                  clearDateFin: cleared,
                ),
              );
            },
            child: Text(l10n.medsSaveCta),
          ),
        ],
      ),
    );
  }
}

class _EditMedSheet extends ConsumerStatefulWidget {
  const _EditMedSheet({required this.medicament});

  final ConfiguredMedicament medicament;

  @override
  ConsumerState<_EditMedSheet> createState() => _EditMedSheetState();
}

class _EditMedSheetState extends ConsumerState<_EditMedSheet> {
  late final TextEditingController _nom;
  late final TextEditingController _dosage;
  late String _forme;
  String? _priseAvecRepas;
  late List<TimeOfDay> _times;
  late bool _everyDay;
  late Set<String> _days;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final m = widget.medicament;
    _nom = TextEditingController(text: m.nom);
    _dosage = TextEditingController(text: m.dosage);
    _forme = m.forme.isEmpty ? 'comprime' : m.forme;
    _priseAvecRepas = m.priseAvecRepas;
    final active = m.activeHoraires;
    _times = active
        .map(_parseTime)
        .whereType<TimeOfDay>()
        .toList();
    if (_times.isEmpty) {
      _times = [const TimeOfDay(hour: 8, minute: 0)];
    }
    final jours = active.isNotEmpty ? active.first.jours : const ['tous'];
    _everyDay = jours.contains('tous') || jours.isEmpty;
    _days = _everyDay
        ? {}
        : jours.map((e) => e.toString()).toSet();
  }

  @override
  void dispose() {
    _nom.dispose();
    _dosage.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(MedicamentHoraire h) {
    final parts = h.heure.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<String> _joursPayload() {
    if (_everyDay) return const ['tous'];
    return _days.toList();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final nom = _nom.text.trim();
    final dosage = _dosage.text.trim();
    if (nom.isEmpty || dosage.isEmpty) {
      AppToast.error(context, l10n.manageMedNeedIdentity);
      return;
    }
    if (_times.isEmpty) {
      AppToast.error(context, l10n.medsNeedTime);
      return;
    }
    if (!_everyDay && _days.isEmpty) {
      AppToast.error(context, l10n.medsNeedDays);
      return;
    }

    setState(() => _busy = true);
    try {
      final repo = ref.read(medicamentsRepositoryProvider);
      await repo.updateMedicament(
        medicamentId: widget.medicament.id,
        nom: nom,
        dosage: dosage,
        forme: _forme,
        priseAvecRepas: _priseAvecRepas,
      );
      await repo.replaceHoraires(
        medicamentId: widget.medicament.id,
        currentActive: widget.medicament.activeHoraires,
        newHeures: _times.map(_fmt).toList(),
        jours: _joursPayload(),
      );
      if (!mounted) return;
      AppToast.success(context, l10n.manageMedUpdatedToast);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.manageMedEdit,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nom,
              decoration: InputDecoration(labelText: l10n.medsNameLabel),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dosage,
              decoration: InputDecoration(
                labelText: l10n.medsDoseLabel,
                hintText: l10n.medsDoseHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.medsFormeLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            MedFormeSelector(
              value: _forme,
              onChanged: (v) => setState(() => _forme = v),
            ),
            const SizedBox(height: 16),
            Text(l10n.medsRepasLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in [
                  (null, l10n.medsRepasNone),
                  ('avant_repas', l10n.medsRepasAvant),
                  ('apres_repas', l10n.medsRepasApres),
                  ('indifferent', l10n.medsRepasIndifferent),
                ])
                  ChoiceChip(
                    label: Text(entry.$2),
                    selected: _priseAvecRepas == entry.$1,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _priseAvecRepas = entry.$1);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.medsTimesLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            MedTimesEditor(
              times: _times,
              onChanged: (t) => setState(() => _times = t),
            ),
            const SizedBox(height: 16),
            Text(l10n.medsDaysLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            MedDaysSelector(
              everyDay: _everyDay,
              selectedDays: _days,
              onEveryDayChanged: (v) => setState(() {
                _everyDay = v;
                if (v) _days = {};
              }),
              onDaysChanged: (d) => setState(() => _days = d),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.medsSaveCta),
            ),
          ],
        ),
      ),
    );
  }
}

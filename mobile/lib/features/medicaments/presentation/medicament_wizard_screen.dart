import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart' show ThemeTokens, AppColors;
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/application/home_controller.dart';
import '../../home/domain/dashboard_models.dart';
import '../../onboarding/presentation/widgets/onboarding_option_tile.dart';
import '../data/medicaments_repository.dart';
import 'widgets/home_config_shell.dart';
import 'widgets/med_days_selector.dart';
import 'widgets/med_forme_selector.dart';
import 'widgets/med_stock_sheet.dart';
import 'widgets/med_suggestion_card.dart';
import 'widgets/med_times_editor.dart';

class MedicamentWizardScreen extends ConsumerStatefulWidget {
  const MedicamentWizardScreen({super.key, required this.traitementId});

  final String traitementId;

  @override
  ConsumerState<MedicamentWizardScreen> createState() =>
      _MedicamentWizardScreenState();
}

class _MedicamentWizardScreenState extends ConsumerState<MedicamentWizardScreen> {
  final _nom = TextEditingController();
  final _dosage = TextEditingController();
  final _stock = TextEditingController();
  final _seuil = TextEditingController();
  final _times = <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)];
  String _forme = 'comprime';
  bool _everyDay = true;
  Set<String> _days = {};
  String? _priseAvecRepas;
  String? _selectedSuggestionKey;
  int _step = 0;
  bool _busy = false;
  List<ConfiguredMedicament> _configured = const [];

  @override
  void initState() {
    super.initState();
    if (widget.traitementId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfigured());
  }

  @override
  void dispose() {
    _nom.dispose();
    _dosage.dispose();
    _stock.dispose();
    _seuil.dispose();
    super.dispose();
  }

  Future<void> _loadConfigured() async {
    try {
      final items = await ref
          .read(medicamentsRepositoryProvider)
          .listMedicaments(
            traitementId: widget.traitementId,
            actifsOnly: true,
          );
      if (!mounted) return;
      setState(() => _configured = items);
    } catch (_) {
      // Non bloquant — la liste s’enrichit à chaque enregistrement local.
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  void _applySuggestion(DoseSuggestion s) {
    _nom.text = s.nom;
    _dosage.text = s.dosage;
    _forme = s.forme.isEmpty ? 'comprime' : s.forme;
    final parsed =
        s.horaires.map(_parseTime).whereType<TimeOfDay>().toList();
    setState(() {
      _selectedSuggestionKey = '${s.nom}|${s.dosage}|${s.forme}';
      if (parsed.isNotEmpty) {
        _times
          ..clear()
          ..addAll(parsed);
      }
    });
  }

  void _resetDraft() {
    _nom.clear();
    _dosage.clear();
    _stock.clear();
    _seuil.clear();
    _forme = 'comprime';
    _everyDay = true;
    _days = {};
    _priseAvecRepas = null;
    _selectedSuggestionKey = null;
    _times
      ..clear()
      ..add(const TimeOfDay(hour: 8, minute: 0));
    setState(() => _step = 0);
  }

  (int?, int?) _stockPayload(AppLocalizations l10n) {
    final stockRaw = _stock.text.trim();
    final seuilRaw = _seuil.text.trim();
    if (stockRaw.isEmpty && seuilRaw.isEmpty) return (null, null);
    if (stockRaw.isEmpty) {
      AppToast.error(context, l10n.medsStockInvalid);
      throw StateError('stock_invalid');
    }
    final stock = int.tryParse(stockRaw);
    if (stock == null || stock < 0) {
      AppToast.error(context, l10n.medsStockInvalid);
      throw StateError('stock_invalid');
    }
    int? seuil;
    if (seuilRaw.isNotEmpty) {
      seuil = int.tryParse(seuilRaw);
      if (seuil == null || seuil < 0) {
        AppToast.error(context, l10n.medsStockInvalid);
        throw StateError('stock_invalid');
      }
    } else {
      seuil = 5;
    }
    return (stock, seuil);
  }

  List<String> _joursPayload() {
    if (_everyDay) return const ['tous'];
    final ordered = MedDaysSelector.weekdays
        .where((d) => _days.contains(d))
        .toList();
    return ordered.isEmpty ? const ['tous'] : ordered;
  }

  DashboardTraitement? _traitement(HomeUiState state) {
    for (final item in state.dashboard?.traitements ?? const []) {
      if (item.id == widget.traitementId) return item;
    }
    return null;
  }

  void _onBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _onPrimary(AppLocalizations l10n) {
    if (_step == 0) {
      if (_nom.text.trim().isEmpty || _dosage.text.trim().isEmpty) {
        AppToast.error(context, l10n.fieldRequired);
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (_times.isEmpty) {
        AppToast.error(context, l10n.medsNeedTime);
        return;
      }
      if (!_everyDay && _days.isEmpty) {
        AppToast.error(context, l10n.medsNeedDays);
        return;
      }
      setState(() => _step = 2);
      return;
    }
    // Récap : primary = enregistrer + ajouter un autre
    _submit(l10n, addAnother: true);
  }

  Future<void> _submit(
    AppLocalizations l10n, {
    required bool addAnother,
  }) async {
    late final int? stockRestant;
    late final int? seuilAlerte;
    try {
      final parsed = _stockPayload(l10n);
      stockRestant = parsed.$1;
      seuilAlerte = parsed.$2;
    } catch (_) {
      return;
    }

    setState(() => _busy = true);
    final savedNom = _nom.text.trim();
    final savedDosage = _dosage.text.trim();
    try {
      await ref.read(medicamentsRepositoryProvider).createMedicament(
            traitementId: widget.traitementId,
            nom: savedNom,
            dosage: savedDosage,
            forme: _forme,
            priseAvecRepas: _priseAvecRepas,
            heures: _times.map(_fmt).toList(),
            jours: _joursPayload(),
            stockRestant: stockRestant,
            seuilAlerteStock: seuilAlerte,
          );
      await ref.read(homeControllerProvider.notifier).load();
      if (!mounted) return;
      setState(() {
        _configured = [
          ..._configured,
          ConfiguredMedicament(
            id: 'local-${_configured.length}',
            traitementId: widget.traitementId,
            nom: savedNom,
            dosage: savedDosage,
            stockRestant: stockRestant,
            seuilAlerteStock: seuilAlerte,
          ),
        ];
      });
      AppToast.success(context, l10n.medsSaved);
      if (addAnother) {
        _resetDraft();
      } else {
        context.go('/home');
      }
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

  String _formeLabel(AppLocalizations l10n) => switch (_forme) {
        'comprime' => l10n.medsFormeComprime,
        'sirop' => l10n.medsFormeSirop,
        'injection' => l10n.medsFormeInjection,
        _ => l10n.medsFormeAutre,
      };

  String _joursLabel(AppLocalizations l10n) {
    if (_everyDay) return l10n.medsDaysEvery;
    final map = {
      'lundi': l10n.medsDayMon,
      'mardi': l10n.medsDayTue,
      'mercredi': l10n.medsDayWed,
      'jeudi': l10n.medsDayThu,
      'vendredi': l10n.medsDayFri,
      'samedi': l10n.medsDaySat,
      'dimanche': l10n.medsDaySun,
    };
    return MedDaysSelector.weekdays
        .where(_days.contains)
        .map((d) => map[d] ?? d)
        .join(', ');
  }

  String _repasLabel(AppLocalizations l10n) => switch (_priseAvecRepas) {
        'avant_repas' => l10n.medsRepasAvant,
        'apres_repas' => l10n.medsRepasApres,
        'indifferent' => l10n.medsRepasIndifferent,
        _ => l10n.medsRepasNone,
      };

  Widget _configuredBanner(AppLocalizations l10n, ThemeData theme) {
    if (_configured.isEmpty) return const SizedBox.shrink();
    final tokens = ThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  IconsaxPlusLinear.tick_circle,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.medsConfiguredCount(_configured.length),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in _configured)
                  Chip(
                    label: Text('${m.nom} ${m.dosage}'.trim()),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: tokens.elevated,
                    side: BorderSide(color: tokens.border),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            if (_step == 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.medsMultiHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => MedStockSheet.show(
                    context,
                    traitementId: widget.traitementId,
                  ),
                  icon: const Icon(IconsaxPlusLinear.box, size: 18),
                  label: Text(l10n.homeCareManageStock),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final theme = Theme.of(context);
    final t = _traitement(ref.watch(homeControllerProvider));
    final labels = [
      l10n.configStepIdentite,
      l10n.configStepHoraires,
      l10n.configStepRecap,
    ];

    final titles = [
      l10n.medsStepIdentiteTitle,
      l10n.medsStepHorairesTitle,
      l10n.medsStepRecapTitle,
    ];
    final subtitles = [
      l10n.medsStepIdentiteSubtitle,
      l10n.medsStepHorairesSubtitle,
      l10n.medsStepRecapSubtitle,
    ];

    return HomeConfigShell(
      stepIndex: _step,
      totalSteps: 3,
      stepLabels: labels,
      title: titles[_step],
      subtitle: subtitles[_step],
      onBack: _onBack,
      // Sur le récap : primary = sauver + enchaîner un autre médicament
      primaryLabel:
          _step == 2 ? l10n.medsSaveAndAddAnother : l10n.onboardingContinue,
      primaryEnabled: true,
      busy: _busy,
      onPrimary: () => _onPrimary(l10n),
      secondaryLabel: _step == 2 ? l10n.medsFinishCta : null,
      secondaryOutlined: _step == 2,
      onSecondary: _step == 2
          ? () => _submit(l10n, addAnother: false)
          : null,
      child: switch (_step) {
        0 => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _configuredBanner(l10n, theme),
              if (t != null && t.suggestions.isNotEmpty) ...[
                Text(
                  l10n.medsSuggestions,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final s in t.suggestions)
                  MedSuggestionCard(
                    suggestion: s,
                    selected: _selectedSuggestionKey ==
                        '${s.nom}|${s.dosage}|${s.forme}',
                    onTap: () => _applySuggestion(s),
                  ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _nom,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.medsNameLabel),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _dosage,
                decoration: InputDecoration(
                  labelText: l10n.medsDoseLabel,
                  hintText: l10n.medsDoseHint,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.medsFormeLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              MedFormeSelector(
                value: _forme,
                onChanged: (v) => setState(() => _forme = v),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.medsStockSection,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.medsStockHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.medsStockLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _seuil,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.medsStockSeuilLabel,
                        hintText: l10n.medsStockSeuilHint,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        1 => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.medsTimesLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              MedTimesEditor(
                times: _times,
                onChanged: (v) => setState(() {
                  _times
                    ..clear()
                    ..addAll(v);
                }),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.medsDaysLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              MedDaysSelector(
                everyDay: _everyDay,
                selectedDays: _days,
                onEveryDayChanged: (v) => setState(() {
                  _everyDay = v;
                  if (v) _days = {};
                }),
                onDaysChanged: (v) => setState(() => _days = v),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.medsRepasLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              OnboardingOptionTile(
                selected: _priseAvecRepas == null,
                title: l10n.medsRepasNone,
                onTap: () => setState(() => _priseAvecRepas = null),
              ),
              OnboardingOptionTile(
                selected: _priseAvecRepas == 'avant_repas',
                title: l10n.medsRepasAvant,
                onTap: () => setState(() => _priseAvecRepas = 'avant_repas'),
              ),
              OnboardingOptionTile(
                selected: _priseAvecRepas == 'apres_repas',
                title: l10n.medsRepasApres,
                onTap: () => setState(() => _priseAvecRepas = 'apres_repas'),
              ),
              OnboardingOptionTile(
                selected: _priseAvecRepas == 'indifferent',
                title: l10n.medsRepasIndifferent,
                onTap: () => setState(() => _priseAvecRepas = 'indifferent'),
              ),
            ],
          ),
        _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _configuredBanner(l10n, theme),
              if (t != null) ...[
                Text(
                  t.maladieNom,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.medsRecapTraitementHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nom.text.trim(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_dosage.text.trim()} · ${_formeLabel(l10n)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _RecapRow(
                      label: l10n.medsTimesLabel,
                      value: _times.map(_fmt).join(' · '),
                    ),
                    const SizedBox(height: 8),
                    _RecapRow(
                      label: l10n.medsDaysLabel,
                      value: _joursLabel(l10n),
                    ),
                    const SizedBox(height: 8),
                    _RecapRow(
                      label: l10n.medsRepasLabel,
                      value: _repasLabel(l10n),
                    ),
                    if (_stock.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _RecapRow(
                        label: l10n.medsStockRecap,
                        value:
                            '${_stock.text.trim()} (≤ ${_seuil.text.trim().isEmpty ? '5' : _seuil.text.trim()})',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.medsRecapTrust,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
      },
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

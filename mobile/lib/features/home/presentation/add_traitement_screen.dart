import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/application/home_controller.dart';
import '../../medicaments/data/medicaments_repository.dart';
import '../../medicaments/presentation/widgets/home_config_shell.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/widgets/onboarding_option_tile.dart';
import 'widgets/home_skeleton.dart';

class AddTraitementScreen extends ConsumerStatefulWidget {
  const AddTraitementScreen({super.key, this.fromActivate = false});

  /// Après « Activer mon suivi » : enchaîne sur les permissions device (step D).
  final bool fromActivate;

  @override
  ConsumerState<AddTraitementScreen> createState() => _AddTraitementScreenState();
}

class _AddTraitementScreenState extends ConsumerState<AddTraitementScreen> {
  List<MaladieCatalogItem> _maladies = const [];
  String? _maladieId;
  String _phase = 'en_cours';
  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin;
  int _step = 0;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final items =
          await ref.read(medicamentsRepositoryProvider).listMaladies();
      if (!mounted) return;
      setState(() {
        _maladies = items;
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

  Future<void> _pickDate({required bool fin}) async {
    final now = DateTime.now();
    final initial = fin ? (_dateFin ?? _dateDebut) : _dateDebut;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: fin ? _dateDebut : DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (fin) {
        _dateFin = picked;
      } else {
        _dateDebut = picked;
        if (_dateFin != null && _dateFin!.isBefore(_dateDebut)) {
          _dateFin = null;
        }
      }
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_maladieId == null) {
      AppToast.error(context, l10n.onboardingMaladieRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await ref.read(medicamentsRepositoryProvider).createTraitement(
            maladieId: _maladieId!,
            phase: _phase,
            dateDebut: _dateDebut,
            dateFinPrevue: _dateFin,
          );
      await ref.read(homeControllerProvider.notifier).load();
      if (!mounted) return;
      if (widget.fromActivate) {
        context.pushReplacement('/home/permissions');
        return;
      }
      context.pushReplacement('/home/medicaments', extra: id);
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

  void _onBack() {
    if (_step > 0) {
      setState(() => _step = 0);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _onPrimary() {
    if (_step == 0) {
      if (_maladieId == null) {
        AppToast.error(
          context,
          AppLocalizations.of(context).onboardingMaladieRequired,
        );
        return;
      }
      setState(() => _step = 1);
      return;
    }
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMMd(locale);

    if (_loading) {
      return DawnBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const SafeArea(child: ProfilePageSkeleton(rows: 5)),
        ),
      );
    }

    final labels = [l10n.configStepMaladie, l10n.configStepContexte];

    return HomeConfigShell(
      stepIndex: _step,
      totalSteps: 2,
      stepLabels: labels,
      title: _step == 0 ? l10n.configTraitementTitle : l10n.configPhaseTitle,
      subtitle:
          _step == 0 ? l10n.configTraitementSubtitle : l10n.configPhaseSubtitle,
      onBack: _onBack,
      primaryLabel:
          _step == 0 ? l10n.onboardingContinue : l10n.configTraitementCreate,
      primaryEnabled: _step == 0 ? _maladieId != null : true,
      busy: _busy,
      onPrimary: _onPrimary,
      child: _step == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final m in _maladies)
                  OnboardingOptionTile(
                    selected: _maladieId == m.id,
                    title: m.nom,
                    onTap: () => setState(() => _maladieId = m.id),
                  ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in [
                  ('debut', l10n.onboardingPhaseDebut),
                  ('en_cours', l10n.onboardingPhaseEnCours),
                  ('maintenance', l10n.onboardingPhaseMaintenance),
                  ('inconnu', l10n.onboardingPhaseInconnu),
                ])
                  OnboardingOptionTile(
                    selected: _phase == entry.$1,
                    title: entry.$2,
                    onTap: () => setState(() => _phase = entry.$1),
                  ),
                const SizedBox(height: 8),
                Text(
                  l10n.configDateDebutLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _pickDate(fin: false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(dateFmt.format(_dateDebut)),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.configDateDebutHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeTokens.of(context).textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.configDateFinLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _pickDate(fin: true),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _dateFin == null
                        ? l10n.configDateFinClear
                        : dateFmt.format(_dateFin!),
                  ),
                ),
                if (_dateFin != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _dateFin = null),
                      child: Text(l10n.configDateFinClear),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  l10n.configDateFinHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeTokens.of(context).textSecondary,
                      ),
                ),
              ],
            ),
    );
  }
}

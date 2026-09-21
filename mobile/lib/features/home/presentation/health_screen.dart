import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../application/home_controller.dart';
import '../domain/constante_models.dart';
import '../domain/dashboard_models.dart';
import '../domain/health_view_model.dart';
import 'widgets/add_constante_sheet.dart';
import 'widgets/health_hero_card.dart';
import 'widgets/health_metric_tile.dart';
import 'widgets/health_recent_list.dart';
import 'widgets/health_skeleton.dart';
import 'widgets/sticky_tab_header.dart';
import '../../../l10n/app_localizations.dart';

/// Onglet Santé — suivi des constantes (poids, tension, glycémie…).
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeControllerProvider);
    final dash = state.dashboard;
    final vm = HealthViewModel(
      constantes: state.constantes,
      traitements: dash?.traitements ?? const [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StickyTabHeader(
          title: l10n.navCare,
          subtitle: l10n.healthSubtitle,
        ),
        Expanded(
          child: Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    ref.read(homeControllerProvider.notifier).load(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    Premium.screenPad,
                    8,
                    Premium.screenPad,
                    Premium.navClearance + 72,
                  ),
                  children: _body(context, ref, state, vm, l10n),
                ),
              ),
              Positioned(
                left: Premium.screenPad,
                right: Premium.screenPad,
                bottom: 8,
                child: _BottomAddBar(
                  onAdd: () => AddConstanteSheet.show(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _body(
    BuildContext context,
    WidgetRef ref,
    HomeUiState state,
    HealthViewModel vm,
    AppLocalizations l10n,
  ) {
    if (state.loading && state.profile == null) {
      return const [HealthSkeleton()];
    }
    if (!state.hasPatient) {
      final aidantOnly = state.profile?.isAidant == true;
      return [
        _EmptyPatientCard(
          l10n: l10n,
          aidantOnly: aidantOnly,
          onTap: () => ref.read(homeTabIndexProvider.notifier).state = 0,
        ),
      ];
    }
    if (state.loading && !state.constantesKnown) {
      return const [HealthSkeleton()];
    }

    final latest = vm.latestOverall;
    final heroSeries = latest != null ? vm.seriesFor(latest.type) : null;
    final recommended = vm.recommendedOrdered;
    final dash = state.dashboard;
    final traitements = dash?.traitements ?? const <DashboardTraitement>[];
    final unconfigured = dash?.firstUnconfigured;
    final medsTargetId = unconfigured?.id ??
        (traitements.isNotEmpty ? traitements.first.id : null);

    return [
      RepaintBoundary(
        child: HealthHeroCard(
          latest: latest,
          series: heroSeries,
          onTap: latest != null
              ? () => context.push('/home/sante/${latest.type.code}')
              : null,
          onAdd: () => AddConstanteSheet.show(context),
        ),
      ),
      const SizedBox(height: 20),
      if (recommended.isNotEmpty) ...[
        _SectionLabel(title: l10n.healthRecommended),
        const SizedBox(height: 10),
        _MetricGrid(
          types: recommended,
          vm: vm,
          onTypeTap: (type) => context.push('/home/sante/${type.code}'),
        ),
        const SizedBox(height: 20),
      ],
      _SectionLabel(title: l10n.healthAllMetrics),
      const SizedBox(height: 10),
      RepaintBoundary(
        child: _MetricGrid(
          types: vm.displayOrder,
          vm: vm,
          onTypeTap: (type) => context.push('/home/sante/${type.code}'),
        ),
      ),
      const SizedBox(height: 22),
      _SectionLabel(title: l10n.healthRecent),
      const SizedBox(height: 8),
      PremiumCard(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: HealthRecentList(
          items: vm.recentConstantes,
          onItemTap: (type) => context.push('/home/sante/${type.code}'),
        ),
      ),
      const SizedBox(height: 22),
      _SectionLabel(title: l10n.healthMoreSection),
      const SizedBox(height: 10),
      _CareQuickActions(
        onTraitement: () => context.push('/home/traitement'),
        onMeds: medsTargetId == null
            ? null
            : () => context.push(
                  '/home/medicaments',
                  extra: medsTargetId,
                ),
        onVital: () => AddConstanteSheet.show(context),
        medsNeedsConfig: unconfigured != null,
      ),
    ];
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.types,
    required this.vm,
    required this.onTypeTap,
  });

  final List<ConstanteType> types;
  final HealthViewModel vm;
  final ValueChanged<ConstanteType> onTypeTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final type in types)
              SizedBox(
                width: tileWidth,
                child: HealthMetricTile(
                  type: type,
                  series: vm.seriesFor(type),
                  recommended: vm.recommended.contains(type),
                  onTap: () => onTypeTap(type),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: tokens.textSecondary,
      ),
    );
  }
}

/// 3 pastilles : traitement, médicaments, mesure.
class _CareQuickActions extends StatelessWidget {
  const _CareQuickActions({
    required this.onTraitement,
    required this.onMeds,
    required this.onVital,
    required this.medsNeedsConfig,
  });

  final VoidCallback onTraitement;
  final VoidCallback? onMeds;
  final VoidCallback onVital;
  final bool medsNeedsConfig;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _QuickActionChip(
            icon: IconsaxPlusLinear.hospital,
            label: l10n.homeCareActionTraitement,
            onTap: onTraitement,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionChip(
            icon: IconsaxPlusLinear.health,
            label: medsNeedsConfig
                ? l10n.homeCareActionMedsSetup
                : l10n.homeCareActionMeds,
            onTap: onMeds,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionChip(
            icon: IconsaxPlusLinear.activity,
            label: l10n.homeCareActionVital,
            onTap: onVital,
          ),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final enabled = onTap != null;

    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: tokens.isDark ? 0.16 : 0.07)
          : tokens.elevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled ? AppColors.primary : tokens.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: enabled ? tokens.textPrimary : tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPatientCard extends StatelessWidget {
  const _EmptyPatientCard({
    required this.l10n,
    required this.onTap,
    this.aidantOnly = false,
  });

  final AppLocalizations l10n;
  final VoidCallback onTap;
  final bool aidantOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(IconsaxPlusLinear.health, size: 28, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            aidantOnly
                ? l10n.healthAidantOnlyTitle
                : l10n.homeCareEmptyPatientTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            aidantOnly ? l10n.healthAidantOnlyBody : l10n.homeActivateBody,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(l10n.navHome),
          ),
        ],
      ),
    );
  }
}

class _BottomAddBar extends StatelessWidget {
  const _BottomAddBar({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FilledButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onAdd();
        },
        icon: const Icon(IconsaxPlusLinear.add, size: 20),
        label: Text(l10n.healthAddCta),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Premium.radiusSm),
          ),
        ),
    );
  }
}

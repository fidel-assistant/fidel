import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/cercle_controller.dart';
import '../../application/home_controller.dart';
import '../activate_suivi_flow.dart';
import 'accompanied_patient_tile.dart';
import 'active_sos_section.dart';

/// Liste des patients suivis — Accueil aidant seul ou bandeau de cumul.
class AccompaniedSection extends ConsumerWidget {
  const AccompaniedSection({
    super.key,
    this.showActions = false,
  });

  /// CTA sync (principal) + activer mon suivi (secondaire). Aidant seul.
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final cercle = ref.watch(cercleControllerProvider);
    final patients = cercle.accompaniedPatients;
    final waiting = !cercle.loadedOnce || (cercle.loading && patients.isEmpty);
    final failed = cercle.error != null && patients.isEmpty && cercle.loadedOnce;
    final homeBusy = ref.watch(homeControllerProvider.select((s) => s.busy));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActiveSosSection(),
        Text(
          l10n.homeAccompaniedSection,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        if (waiting)
          const PremiumCard(
            child: SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          )
        else if (failed)
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  cercle.error!,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    height: 1.4,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref
                      .read(cercleControllerProvider.notifier)
                      .load(force: true),
                  child: Text(l10n.onboardingRetry),
                ),
              ],
            ),
          )
        else if (patients.isEmpty)
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cercleMyPatientsEmptyTitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.cercleMyPatientsEmptyBody,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    height: 1.4,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          PremiumCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < patients.length; i++) ...[
                  AccompaniedPatientTile(
                    patient: patients[i],
                    signal: cercle.signalFor(patients[i].id),
                    onTap: () => context.push(
                      '/home/cercle/patient/${patients[i].id}',
                      extra: patients[i],
                    ),
                  ),
                  if (i < patients.length - 1)
                    Divider(height: 1, indent: 72, color: tokens.border),
                ],
              ],
            ),
          ),
        if (showActions) ...[
          const SizedBox(height: 16),
          _ActionBanner(
            icon: IconsaxPlusLinear.people,
            title: l10n.homeAccompanyTitle,
            subtitle: l10n.homeAccompanyBody,
            onTap: () => context.push('/home/sync'),
          ),
          const SizedBox(height: 10),
          _ActionBanner(
            icon: IconsaxPlusLinear.health,
            title: l10n.homeActivateTitle,
            subtitle: l10n.homeActivateBody,
            onTap: homeBusy
                ? null
                : () => startActivateSuiviFlow(
                      context: context,
                      ref: ref,
                      l10n: l10n,
                    ),
          ),
        ],
      ],
    );
  }
}

class _ActionBanner extends StatelessWidget {
  const _ActionBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Material(
      color: AppColors.primary.withValues(alpha: tokens.isDark ? 0.14 : 0.06),
      borderRadius: BorderRadius.circular(Premium.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Premium.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        height: 1.35,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

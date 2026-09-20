import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../core/ui/app_toast.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/cercle_controller.dart';
import '../../application/home_controller.dart';
import '../../domain/aidant_models.dart';

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
                  _PatientRow(
                    patient: patients[i],
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
            onTap: homeBusy ? null : () => _activate(context, ref, l10n),
          ),
        ],
      ],
    );
  }

  Future<void> _activate(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final busy = ref.read(homeControllerProvider).busy;
    if (busy) return;
    try {
      await ref.read(homeControllerProvider.notifier).activateFollowUp();
      if (context.mounted) context.push('/home/traitement');
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          e is ApiException ? e.message : l10n.genericError,
        );
      }
    }
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient, required this.onTap});

  final AidantPatient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final String subtitle;
    if (patient.permissions.observance && patient.permissions.constantes) {
      subtitle = l10n.homeAidantsPermBoth;
    } else if (patient.permissions.observance) {
      subtitle = l10n.homeAidantsPermObservanceOnly;
    } else if (patient.permissions.constantes) {
      subtitle = l10n.homeAidantsPermConstantes;
    } else {
      subtitle = l10n.cerclePermissionLimited;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(
                    alpha: tokens.isDark ? 0.2 : 0.1,
                  ),
                ),
                child: Text(
                  patient.initial,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.displayName,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
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
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 18,
                color: tokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
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

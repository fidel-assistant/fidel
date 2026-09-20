import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/sos_aidant_alarm.dart';
import '../../application/cercle_controller.dart';
import '../../domain/aidant_models.dart';

/// SOS non acquittés — Accueil aidant (absent si liste vide).
class ActiveSosSection extends ConsumerWidget {
  const ActiveSosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final alerts = ref.watch(
      cercleControllerProvider.select((s) => s.activeSos),
    );
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.homeActiveSosSection,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < alerts.length; i++) ...[
                _SosRow(alert: alerts[i]),
                if (i < alerts.length - 1)
                  Divider(height: 1, indent: 72, color: tokens.border),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SosRow extends ConsumerWidget {
  const _SosRow({required this.alert});

  final ActiveSosAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final prenom = alert.patientPrenom.trim().isEmpty
        ? 'Patient'
        : alert.patientPrenom;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openSosAidantScreen(
          ref.read(appRouterProvider),
          alert,
        ),
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
                  color: AppColors.error.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  IconsaxPlusLinear.warning_2,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prenom,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aidantSignalSos,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(IconsaxPlusLinear.arrow_right_3, color: tokens.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

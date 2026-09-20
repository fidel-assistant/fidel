import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dashboard_models.dart';

/// Ligne de check-in — 4 niveaux SVG premium dans le panneau Aujourd’hui.
class CheckInRow extends StatelessWidget {
  const CheckInRow({
    super.key,
    required this.answer,
    required this.busy,
    required this.onAnswer,
  });

  final CheckInEntry? answer;
  final bool busy;
  final ValueChanged<String> onAnswer;

  static const _levels = CheckInEntry.levels;

  static String assetFor(String statut) {
    return switch (statut) {
      'tres_mal' => 'assets/images/mood/mood_tres_mal.svg',
      'pas_top' => 'assets/images/mood/mood_pas_top.svg',
      'ca_va' => 'assets/images/mood/mood_ca_va.svg',
      'super' => 'assets/images/mood/mood_super.svg',
      _ => 'assets/images/mood/mood_ca_va.svg',
    };
  }

  static Color colorFor(String statut) {
    return switch (statut) {
      'tres_mal' => const Color(0xFFDC2626),
      'pas_top' => const Color(0xFFF59E0B),
      'ca_va' => const Color(0xFF0494D0),
      'super' => const Color(0xFF16A34A),
      _ => const Color(0xFF64748B),
    };
  }

  static String labelFor(AppLocalizations l10n, String statut) {
    return switch (statut) {
      'tres_mal' => l10n.homeCheckInLevelTresMal,
      'pas_top' => l10n.homeCheckInLevelPasTop,
      'ca_va' => l10n.homeCheckInLevelCaVa,
      'super' => l10n.homeCheckInLevelSuper,
      _ => l10n.homeCheckInLevelCaVa,
    };
  }

  static String doneLabelFor(AppLocalizations l10n, String statut) {
    return switch (statut) {
      'tres_mal' => l10n.homeCheckInDoneTresMal,
      'pas_top' => l10n.homeCheckInDonePasTop,
      'ca_va' => l10n.homeCheckInDoneCaVa,
      'super' => l10n.homeCheckInDoneSuper,
      _ => l10n.homeCheckInDoneCaVa,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    if (answer != null) {
      final statut = answer!.statut;
      return Row(
        children: [
          SvgPicture.asset(
            assetFor(statut),
            width: 22,
            height: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              doneLabelFor(l10n, statut),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ),
          Icon(
            IconsaxPlusLinear.tick_circle,
            size: 18,
            color: AppColors.success,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.homeCheckInTitle,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < _levels.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _MoodChoice(
                  asset: assetFor(_levels[i]),
                  semanticLabel: labelFor(l10n, _levels[i]),
                  onTap: busy ? null : () => onAnswer(_levels[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MoodChoice extends StatelessWidget {
  const _MoodChoice({
    required this.asset,
    required this.semanticLabel,
    required this.onTap,
  });

  final String asset;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final radius = BorderRadius.circular(Premium.radiusSm);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: tokens.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F9),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: SvgPicture.asset(asset, width: 28, height: 28),
            ),
          ),
        ),
      ),
    );
  }
}

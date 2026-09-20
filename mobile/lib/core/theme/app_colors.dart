import 'package:flutter/material.dart';

/// Palette Fidel — `#0494D0` / `#037299` (docs/logo).
///
/// Les écrans doivent préférer `Theme.of(context).colorScheme` /
/// [ThemeTokens.of] plutôt que les tokens light hardcodés.
abstract final class AppColors {
  static const Color primary = Color(0xFF0494D0);
  static const Color primaryDark = Color(0xFF037299);
  static const Color primarySoft = Color(0xFF2AA8DB);

  // Light
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF0494D0);
  static const Color divider = Color(0xFFCBD5E1);

  // Dark (slate premium, pas noir pur)
  static const Color surfaceDark = Color(0xFF0B1220);
  static const Color surfaceElevatedDark = Color(0xFF151E2E);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF1E293B);
  static const Color dividerDark = Color(0xFF334155);

  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF15803D);
  static const Color warning = Color(0xFFF59E0B);

  // Toasts — light
  static const Color toastSuccessBg = Color(0xFFECFDF5);
  static const Color toastSuccessFg = Color(0xFF047857);
  static const Color toastErrorBg = Color(0xFFFEF2F2);
  static const Color toastErrorFg = Color(0xFFB91C1C);
  static const Color toastInfoBg = Color(0xFFE8F7FC);
  static const Color toastInfoFg = Color(0xFF037299);

  // Toasts — dark
  static const Color toastSuccessBgDark = Color(0xFF064E3B);
  static const Color toastSuccessFgDark = Color(0xFF6EE7B7);
  static const Color toastErrorBgDark = Color(0xFF7F1D1D);
  static const Color toastErrorFgDark = Color(0xFFFCA5A5);
  static const Color toastInfoBgDark = Color(0xFF024A63);
  static const Color toastInfoFgDark = Color(0xFF7DD3F0);
}

/// Tokens résolus selon la luminosité du thème courant.
@immutable
class ThemeTokens {
  const ThemeTokens({
    required this.surface,
    required this.background,
    required this.elevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.isDark,
  });

  final Color surface;
  final Color background;
  final Color elevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color divider;
  final bool isDark;

  factory ThemeTokens.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    if (dark) {
      return const ThemeTokens(
        surface: AppColors.surfaceDark,
        background: AppColors.backgroundDark,
        elevated: AppColors.surfaceElevatedDark,
        textPrimary: AppColors.textPrimaryDark,
        textSecondary: AppColors.textSecondaryDark,
        border: AppColors.borderDark,
        divider: AppColors.dividerDark,
        isDark: true,
      );
    }
    return const ThemeTokens(
      surface: AppColors.surface,
      background: AppColors.background,
      elevated: AppColors.background,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      border: AppColors.border,
      divider: AppColors.divider,
      isDark: false,
    );
  }
}

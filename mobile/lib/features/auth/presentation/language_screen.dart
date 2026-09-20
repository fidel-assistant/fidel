import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Sélecteur de langue — premier écran (avant email), EN / FR.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, required this.onContinue});

  final ValueChanged<Locale> onContinue;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  Locale _selected = const Locale('fr');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/brand_header_v2.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.primary),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  Text(
                    l10n.languageTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.languageSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  _LangTile(
                    label: l10n.languageFrench,
                    selected: _selected.languageCode == 'fr',
                    onTap: () => setState(() => _selected = const Locale('fr')),
                  ),
                  const SizedBox(height: 12),
                  _LangTile(
                    label: l10n.languageEnglish,
                    selected: _selected.languageCode == 'en',
                    onTap: () => setState(() => _selected = const Locale('en')),
                  ),
                  const Spacer(flex: 2),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () => widget.onContinue(_selected),
                    child: Text(l10n.languageContinue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.surface
          : AppColors.surface.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? AppColors.primary
                    : AppColors.textOnPrimary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

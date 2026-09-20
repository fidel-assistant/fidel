import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Shell wizard home (traitement / médicaments) — chrome onboarding,
/// labels de progression configurables. Sans Lottie.
class HomeConfigShell extends StatelessWidget {
  const HomeConfigShell({
    super.key,
    required this.stepIndex,
    required this.totalSteps,
    required this.stepLabels,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.primaryEnabled = true,
    this.busy = false,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryOutlined = false,
  });

  final int stepIndex;
  final int totalSteps;
  final List<String> stepLabels;
  final String title;
  final String subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool primaryEnabled;
  final bool busy;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool secondaryOutlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final stepLabel =
        stepIndex < stepLabels.length ? stepLabels[stepIndex] : '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: tokens.surface,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            ColoredBox(
              color: AppColors.primary,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/brand_header_v2.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => const SizedBox.expand(),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (onBack != null)
                                IconButton(
                                  onPressed: busy ? null : onBack,
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: AppColors.textOnPrimary,
                                    size: 20,
                                  ),
                                )
                              else
                                const SizedBox(width: 48, height: 48),
                              Expanded(
                                child: Text(
                                  l10n.onboardingStepOf(
                                    stepIndex + 1,
                                    totalSteps,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.textOnPrimary
                                        .withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 88,
                                child: Text(
                                  stepLabel,
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.textOnPrimary
                                        .withValues(alpha: 0.78),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: List.generate(totalSteps, (i) {
                                final active = i <= stepIndex;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: i == totalSteps - 1 ? 0 : 6,
                                    ),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 280),
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.28),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Material(
                color: tokens.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: tokens.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 22),
                          child,
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        8,
                        24,
                        16 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed:
                                (!primaryEnabled || busy) ? null : onPrimary,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(primaryLabel),
                          ),
                          if (secondaryLabel != null &&
                              onSecondary != null) ...[
                            const SizedBox(height: 8),
                            if (secondaryOutlined)
                              OutlinedButton(
                                onPressed: busy ? null : onSecondary,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.45),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Text(secondaryLabel!),
                              )
                            else
                              TextButton(
                                onPressed: busy ? null : onSecondary,
                                child: Text(secondaryLabel!),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_lottie.dart';

/// Point d’entrée `/onboarding` — sync step serveur puis redirection.
class OnboardingGateScreen extends ConsumerStatefulWidget {
  const OnboardingGateScreen({super.key});

  @override
  ConsumerState<OnboardingGateScreen> createState() =>
      _OnboardingGateScreenState();
}

class _OnboardingGateScreenState extends ConsumerState<OnboardingGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    await ref.read(onboardingControllerProvider.notifier).syncFromSessionOrServer();
    if (!mounted) return;
    final step = ref.read(onboardingControllerProvider).step;
    final sessionStep = ref.read(authSessionProvider)?.onboardingStep;
    final effective = step.isNotEmpty ? step : (sessionStep ?? 'infos');

    switch (effective) {
      case 'besoin_suivi':
        context.go('/onboarding/besoin-suivi');
        return;
      case 'patient_traitement':
        context.go('/onboarding/traitement');
        return;
      case 'patient_permissions':
        context.go('/onboarding/permissions');
        return;
      case 'termine':
        context.go('/home');
        return;
      case 'infos':
      default:
        context.go('/onboarding/infos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/brand_header_v2.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: AppColors.primary,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  const OnboardingLottie(
                    asset: 'assets/lottie/welcome.json',
                    fallbackIcon: Icons.favorite_rounded,
                    size: 160,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.onboardingGateLoading,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

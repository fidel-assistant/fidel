import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../medicaments/presentation/widgets/home_config_shell.dart';
import '../application/home_controller.dart';

/// Permissions device post-home (activer suivi / CTA `activer_notifications`).
///
/// Persiste via `PATCH /patients/me` — pas d’`onboarding/complete`.
class HomeDevicePermissionsScreen extends ConsumerStatefulWidget {
  const HomeDevicePermissionsScreen({super.key});

  @override
  ConsumerState<HomeDevicePermissionsScreen> createState() =>
      _HomeDevicePermissionsScreenState();
}

class _HomeDevicePermissionsScreenState
    extends ConsumerState<HomeDevicePermissionsScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _finish({required bool requestOs}) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    var notifications = false;
    var batterie = false;

    if (requestOs) {
      final notif = await Permission.notification.request();
      notifications = notif.isGranted;
      if (Platform.isAndroid) {
        await Permission.scheduleExactAlarm.request();
        final batt = await Permission.ignoreBatteryOptimizations.request();
        batterie = batt.isGranted;
      }
    }

    try {
      await ref.read(homeRepositoryProvider).patchPatientSettings(
            notificationsAccordees: notifications,
            batterieExemptee: batterie,
          );
      await ref.read(homeControllerProvider.notifier).load();
      if (!mounted) return;
      AppToast.success(context, l10n.onboardingDoneToast);
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.genericError;
      });
      AppToast.error(context, l10n.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return HomeConfigShell(
      stepIndex: 0,
      totalSteps: 1,
      stepLabels: [l10n.homeNotifTitle],
      title: l10n.onboardingPermsTitle,
      subtitle: l10n.onboardingPermsSubtitle,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      primaryLabel: l10n.onboardingPermsAllow,
      secondaryLabel: l10n.onboardingPermsLater,
      busy: _busy,
      onPrimary: () => _finish(requestOs: true),
      onSecondary: () => _finish(requestOs: false),
      child: Column(
        children: [
          _PermCard(
            icon: Icons.notifications_outlined,
            title: l10n.onboardingPermsNotifTitle,
            body: l10n.onboardingPermsNotifBody,
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 12),
            _PermCard(
              icon: Icons.alarm_outlined,
              title: l10n.onboardingPermsExactTitle,
              body: l10n.onboardingPermsExactBody,
            ),
            const SizedBox(height: 12),
            _PermCard(
              icon: Icons.battery_saver_outlined,
              title: l10n.onboardingPermsBatteryTitle,
              body: l10n.onboardingPermsBatteryBody,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermCard extends StatelessWidget {
  const _PermCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = ThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.elevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

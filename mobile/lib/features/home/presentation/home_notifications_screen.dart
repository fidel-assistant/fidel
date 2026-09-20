import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/premium.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';

class HomeNotificationsScreen extends ConsumerWidget {
  const HomeNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dash = ref.watch(homeControllerProvider).dashboard;
    final needsPerms = dash != null &&
        (dash.prochaineAction == 'activer_notifications' ||
            !dash.notificationsAccordees);

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
                    title: Text(l10n.homeNotifTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
          children: [
            Text(
              l10n.homeNotifBody,
              style: TextStyle(
                color: ThemeTokens.of(context).textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (dash != null)
              PremiumCard(
              onTap: needsPerms
                  ? () => context.push('/home/permissions')
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      needsPerms
                          ? IconsaxPlusBold.notification
                          : IconsaxPlusBold.tick_circle,
                      color: needsPerms ? AppColors.primary : AppColors.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          needsPerms
                              ? l10n.homeActionNotifTitle
                              : l10n.homeNotifReadyTitle,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          needsPerms
                              ? l10n.homeActionNotifBody
                              : l10n.homeNotifReadyBody,
                          style: TextStyle(
                            color: ThemeTokens.of(context).textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

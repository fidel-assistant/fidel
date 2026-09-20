import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/home_controller.dart';
import '../../application/soft_checklist_controller.dart';
import '../profile_photo_flow.dart';

/// Nudges Accueil non bloquants — téléphone, contact, voix, photo.
class SoftChecklistSection extends ConsumerStatefulWidget {
  const SoftChecklistSection({super.key});

  @override
  ConsumerState<SoftChecklistSection> createState() =>
      _SoftChecklistSectionState();
}

class _SoftChecklistSectionState extends ConsumerState<SoftChecklistSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(softChecklistControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final soft = ref.watch(softChecklistControllerProvider);
    final items = soft.missing;
    if (!soft.known || items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.homeSoftChecklistTitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ThemeTokens.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _SoftNudgeCard(
              kind: items[i],
              l10n: l10n,
              onOpen: () => _open(items[i]),
              onDismiss: () {
                HapticFeedback.selectionClick();
                ref
                    .read(softChecklistControllerProvider.notifier)
                    .dismiss(items[i]);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _open(SoftChecklistKind kind) {
    HapticFeedback.selectionClick();
    final Future<dynamic>? nav;
    switch (kind) {
      case SoftChecklistKind.phone:
        nav = context.push('/home/profile/account');
      case SoftChecklistKind.contactUrgence:
        nav = context.push('/home/profile/contacts');
      case SoftChecklistKind.voixRappel:
        nav = context.push('/home/profile/voix');
      case SoftChecklistKind.photo:
        ref.read(homeTabIndexProvider.notifier).state = 3;
        // Ouvre directement le flux photo via un event léger sur le tab Profil.
        ref.read(profilePhotoPromptProvider.notifier).state =
            DateTime.now().millisecondsSinceEpoch;
        nav = null;
    }
    nav?.then((_) {
      if (mounted) {
        ref.read(softChecklistControllerProvider.notifier).refresh();
      }
    });
  }
}

class _SoftNudgeCard extends StatelessWidget {
  const _SoftNudgeCard({
    required this.kind,
    required this.l10n,
    required this.onOpen,
    required this.onDismiss,
  });

  final SoftChecklistKind kind;
  final AppLocalizations l10n;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final (icon, title, body) = switch (kind) {
      SoftChecklistKind.phone => (
          IconsaxPlusLinear.call,
          l10n.homeSoftPhoneTitle,
          l10n.homeSoftPhoneBody,
        ),
      SoftChecklistKind.contactUrgence => (
          IconsaxPlusLinear.people,
          l10n.homeSoftContactTitle,
          l10n.homeSoftContactBody,
        ),
      SoftChecklistKind.voixRappel => (
          IconsaxPlusLinear.microphone_2,
          l10n.homeSoftVoixTitle,
          l10n.homeSoftVoixBody,
        ),
      SoftChecklistKind.photo => (
          IconsaxPlusLinear.user,
          l10n.homeSoftPhotoTitle,
          l10n.homeSoftPhotoBody,
        ),
    };

    return Material(
      color: tokens.elevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        height: 1.3,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.homeSoftDismissA11y,
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

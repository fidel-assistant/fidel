import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../core/ui/app_toast.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/network_status.dart';
import '../../../../services/sync_engine.dart';
import 'sync_dead_letters_sheet.dart';

/// Compteur outbox active — se rafraîchit au tick pull + périodiquement.
final outboxPendingCountProvider = StreamProvider<int>((ref) async* {
  final outbox = ref.watch(syncOutboxProvider);
  ref.watch(syncPullTickProvider);
  while (true) {
    try {
      final list = await outbox.listPendingForProjection();
      yield list.length;
    } catch (_) {
      yield 0;
    }
    await Future<void>.delayed(const Duration(seconds: 4));
  }
});

/// Compteur dead letters (`failed_permanent`).
final outboxDeadLetterCountProvider = StreamProvider<int>((ref) async* {
  final outbox = ref.watch(syncOutboxProvider);
  ref.watch(syncPullTickProvider);
  while (true) {
    try {
      final list = await outbox.listFailedPermanent();
      yield list.length;
    } catch (_) {
      yield 0;
    }
    await Future<void>.delayed(const Duration(seconds: 4));
  }
});

/// Bandeau offline / sync en attente / dead letters.
class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  ConsumerState<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner> {
  bool _flushing = false;

  Future<void> _flush() async {
    if (_flushing) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _flushing = true);
    HapticFeedback.selectionClick();
    try {
      await ref.read(syncEngineProvider).flush(force: true);
      if (!mounted) return;
      AppToast.success(context, l10n.syncBannerFlushed);
      ref.invalidate(outboxPendingCountProvider);
      ref.invalidate(outboxDeadLetterCountProvider);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.syncBannerFlushFailed);
    } finally {
      if (mounted) setState(() => _flushing = false);
    }
  }

  Future<void> _onTap({
    required int pending,
    required int deadLetters,
  }) async {
    if (_flushing) return;
    if (pending > 0) {
      await _flush();
      return;
    }
    if (deadLetters > 0) {
      HapticFeedback.selectionClick();
      await showSyncDeadLettersSheet(context);
      if (!mounted) return;
      ref.invalidate(outboxPendingCountProvider);
      ref.invalidate(outboxDeadLetterCountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final net = ref.watch(networkStatusProvider);
    final pending = ref.watch(outboxPendingCountProvider).valueOrNull ?? 0;
    final deadLetters =
        ref.watch(outboxDeadLetterCountProvider).valueOrNull ?? 0;

    final offline = net.state == NetworkLinkState.offline;
    final degraded = net.state == NetworkLinkState.degraded;
    if (!offline && !degraded && pending == 0 && deadLetters == 0) {
      return const SizedBox.shrink();
    }

    final String label;
    final IconData icon;
    final String actionLabel;
    if (offline) {
      label = pending > 0
          ? l10n.syncBannerOfflinePending(pending)
          : deadLetters > 0
              ? l10n.syncBannerDeadLetters(deadLetters)
              : l10n.syncBannerOffline;
      icon = IconsaxPlusLinear.wifi_square;
      actionLabel = pending > 0
          ? l10n.syncBannerRetry
          : (deadLetters > 0 ? l10n.syncBannerView : l10n.syncBannerRetry);
    } else if (degraded) {
      label = pending > 0
          ? l10n.syncBannerDegradedPending(pending)
          : deadLetters > 0
              ? l10n.syncBannerDeadLetters(deadLetters)
              : l10n.syncBannerDegraded;
      icon = IconsaxPlusLinear.info_circle;
      actionLabel = pending > 0
          ? l10n.syncBannerRetry
          : (deadLetters > 0 ? l10n.syncBannerView : l10n.syncBannerRetry);
    } else if (pending > 0) {
      label = deadLetters > 0
          ? l10n.syncBannerPendingAndDead(pending, deadLetters)
          : l10n.syncBannerPending(pending);
      icon = IconsaxPlusLinear.refresh;
      actionLabel = l10n.syncBannerRetry;
    } else {
      label = l10n.syncBannerDeadLetters(deadLetters);
      icon = IconsaxPlusLinear.warning_2;
      actionLabel = l10n.syncBannerView;
    }

    final isDeadOnly = !offline && !degraded && pending == 0 && deadLetters > 0;
    final bannerColor = offline
        ? const Color(0xFFFEF3C7)
        : isDeadOnly
            ? const Color(0xFFFEE2E2)
            : AppColors.primary.withValues(alpha: tokens.isDark ? 0.18 : 0.1);
    final iconColor = offline
        ? const Color(0xFFB45309)
        : isDeadOnly
            ? const Color(0xFFDC2626)
            : AppColors.primary;
    final textColor = offline
        ? const Color(0xFF92400E)
        : isDeadOnly
            ? const Color(0xFF991B1B)
            : tokens.textPrimary;

    return Material(
      color: bannerColor,
      child: SafeArea(
        top: false,
        bottom: false,
        child: InkWell(
          onTap: _flushing
              ? null
              : () => _onTap(pending: pending, deadLetters: deadLetters),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                if (_flushing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Text(
                  actionLabel,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

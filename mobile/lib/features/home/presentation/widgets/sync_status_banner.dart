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

/// Compteur outbox — se rafraîchit au tick pull + périodiquement.
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

/// Bandeau offline / sync en attente — masqué si online et outbox vide.
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
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.syncBannerFlushFailed);
    } finally {
      if (mounted) setState(() => _flushing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final net = ref.watch(networkStatusProvider);
    final pendingAsync = ref.watch(outboxPendingCountProvider);
    final pending = pendingAsync.valueOrNull ?? 0;

    final offline = net.state == NetworkLinkState.offline;
    final degraded = net.state == NetworkLinkState.degraded;
    if (!offline && !degraded && pending == 0) {
      return const SizedBox.shrink();
    }

    final String label;
    final IconData icon;
    if (offline) {
      label = pending > 0
          ? l10n.syncBannerOfflinePending(pending)
          : l10n.syncBannerOffline;
      icon = IconsaxPlusLinear.wifi_square;
    } else if (degraded) {
      label = pending > 0
          ? l10n.syncBannerDegradedPending(pending)
          : l10n.syncBannerDegraded;
      icon = IconsaxPlusLinear.info_circle;
    } else {
      label = l10n.syncBannerPending(pending);
      icon = IconsaxPlusLinear.refresh;
    }

    return Material(
      color: offline
          ? const Color(0xFFFEF3C7)
          : AppColors.primary.withValues(alpha: tokens.isDark ? 0.18 : 0.1),
      child: SafeArea(
        top: false,
        bottom: false,
        child: InkWell(
          onTap: _flushing ? null : _flush,
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
                  Icon(
                    icon,
                    size: 18,
                    color: offline
                        ? const Color(0xFFB45309)
                        : AppColors.primary,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: offline
                          ? const Color(0xFF92400E)
                          : tokens.textPrimary,
                    ),
                  ),
                ),
                Text(
                  l10n.syncBannerRetry,
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

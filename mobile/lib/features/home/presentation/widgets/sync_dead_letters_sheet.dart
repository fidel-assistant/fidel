import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../core/ui/app_toast.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/sync_engine.dart';
import '../../../../services/sync_outbox.dart';
import 'sync_status_banner.dart';

Future<void> showSyncDeadLettersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const SyncDeadLettersSheet(),
  );
}

class SyncDeadLettersSheet extends ConsumerStatefulWidget {
  const SyncDeadLettersSheet({super.key});

  @override
  ConsumerState<SyncDeadLettersSheet> createState() =>
      _SyncDeadLettersSheetState();
}

class _SyncDeadLettersSheetState extends ConsumerState<SyncDeadLettersSheet> {
  bool _loading = true;
  List<SyncOutboxEntry> _items = const [];
  String? _busyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final list =
          await ref.read(syncOutboxProvider).listFailedPermanent();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  void _invalidateCounts() {
    ref.invalidate(outboxPendingCountProvider);
    ref.invalidate(outboxDeadLetterCountProvider);
  }

  Future<void> _discard(SyncOutboxEntry e) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busyId = e.mutationId);
    try {
      await ref.read(syncOutboxProvider).markDone(e.mutationId);
      _invalidateCounts();
      if (!mounted) return;
      AppToast.success(context, l10n.syncDeadLetterDiscarded);
      await _reload();
      if (!mounted) return;
      if (_items.isEmpty) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.genericError);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _requeue(SyncOutboxEntry e) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busyId = e.mutationId);
    try {
      await ref.read(syncOutboxProvider).requeue(e.mutationId);
      _invalidateCounts();
      try {
        await ref.read(syncEngineProvider).flush(force: true);
      } catch (_) {
        // Best-effort flush; entry is already pending.
      }
      if (!mounted) return;
      AppToast.success(context, l10n.syncDeadLetterRequeued);
      await _reload();
      if (!mounted) return;
      if (_items.isEmpty) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.genericError);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _opLabel(AppLocalizations l10n, String op) {
    return switch (op) {
      'confirm' => l10n.syncDeadLetterOpConfirm,
      'report' => l10n.syncDeadLetterOpReport,
      'create_constante' => l10n.syncDeadLetterOpConstante,
      'create_check_in' => l10n.syncDeadLetterOpCheckIn,
      _ => op,
    };
  }

  String _subtitle(SyncOutboxEntry e) {
    final id = e.entityId;
    final short = id.length <= 8 ? id : '${id.substring(0, 8)}…';
    return '${e.entity} · $short';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.syncDeadLettersTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.syncDeadLettersSubtitle,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? Center(
                            child: Text(
                              l10n.syncDeadLettersEmpty,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: tokens.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: tokens.border),
                            itemBuilder: (context, i) {
                              final e = _items[i];
                              final busy = _busyId == e.mutationId;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  _opLabel(l10n, e.op),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  _subtitle(e),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                                trailing: busy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(
                                            onPressed: () => _discard(e),
                                            child: Text(
                                              l10n.syncDeadLetterDiscard,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _requeue(e),
                                            child: Text(
                                              l10n.syncDeadLetterRetry,
                                            ),
                                          ),
                                        ],
                                      ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

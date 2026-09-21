import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../core/ui/app_toast.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/home_controller.dart';
import '../../domain/dashboard_models.dart';
import 'check_in_card.dart';

/// Historique check-in (30 jours) — chargé à la demande.
Future<void> showCheckInHistorySheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _CheckInHistorySheet(),
  );
}

class _CheckInHistorySheet extends ConsumerStatefulWidget {
  const _CheckInHistorySheet();

  @override
  ConsumerState<_CheckInHistorySheet> createState() =>
      _CheckInHistorySheetState();
}

class _CheckInHistorySheetState extends ConsumerState<_CheckInHistorySheet> {
  bool _loading = true;
  List<CheckInEntry> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final depuis = DateTime.now().subtract(const Duration(days: 30));
      final items = await ref
          .read(homeRepositoryProvider)
          .listCheckIns(depuis: depuis);
      items.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = DateFormat.yMMMd(locale);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.homeCheckInHistoryTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeCheckInHistorySubtitle,
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
                              l10n.homeCheckInHistoryEmpty,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: tokens.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: tokens.border,
                            ),
                            itemBuilder: (context, i) {
                              final e = _items[i];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: SvgPicture.asset(
                                  CheckInRow.assetFor(e.statut),
                                  width: 28,
                                  height: 28,
                                ),
                                title: Text(
                                  CheckInRow.labelFor(l10n, e.statut),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  fmt.format(e.date),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: tokens.textSecondary,
                                  ),
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

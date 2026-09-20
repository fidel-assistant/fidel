import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/sos_service.dart';
import '../../../services/sync_engine.dart';
import '../../auth/application/auth_providers.dart';
import '../application/cercle_controller.dart';
import '../application/home_controller.dart';
import '../domain/aidant_models.dart';
import 'health_screen.dart';
import 'home_dashboard_screen.dart';
import 'home_network_screen.dart';
import 'home_profile_screen.dart';
import 'widgets/fidel_nav_bar.dart';
import 'widgets/sync_status_banner.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  var _emptyRetryDone = false;
  Timer? _sosTicker;
  SosService? _sos;
  bool _sosSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).load();
      ref.read(cercleControllerProvider.notifier).load(force: true);
      _bindSos();
    });
  }

  void _bindSos() {
    final sos = ref.read(sosServiceProvider);
    _sos = sos;
    sos.bindUi((
      onCountdownStarted: (ticket) {
        if (!mounted) return;
        unawaited(_showSosSheet(ticket));
      },
      onCancelled: (msg) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        AppToast.success(
          context,
          msg.isEmpty ? l10n.cercleSosCancelled : msg,
        );
      },
      onEscalatedCall: (_) {
        if (!mounted) return;
        AppToast.success(context, 'Appel d’urgence lancé');
      },
      onAidantAcked: (msg) {
        if (!mounted) return;
        AppToast.success(context, msg);
      },
      onError: (err) {
        if (!mounted) return;
        AppToast.error(context, err);
      },
      onFlowUiClose: _closeSosSheet,
    ));
    unawaited(sos.drainPendingAction());
  }

  void _closeSosSheet() {
    if (!_sosSheetOpen || !mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  Future<void> _showSosSheet(SosTicket ticket) async {
    if (_sosSheetOpen || !mounted) return;
    final sos = ref.read(sosServiceProvider);
    final notifier = ref.read(cercleControllerProvider.notifier);
    _sosTicker?.cancel();
    _sosSheetOpen = true;
    _sosTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    try {
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModalState) {
            final remaining = ticket.annulableJusquA.difference(DateTime.now());
            _sosTicker?.cancel();
            _sosTicker = Timer.periodic(const Duration(seconds: 1), (_) {
              if (!mounted) return;
              setState(() {});
              if (ctx.mounted) setModalState(() {});
            });
            final seconds = remaining.isNegative ? 0 : remaining.inSeconds + 1;
            return _SosCountdownSheet(
              secondsLeft: seconds,
              onCancel: () async {
                final l10n = AppLocalizations.of(context);
                try {
                  await sos.cancelCountdown(ticket);
                } catch (e) {
                  if (!mounted) return;
                  AppToast.error(
                    context,
                    e is ApiException ? e.message : l10n.genericError,
                  );
                }
              },
            );
          },
        ),
      );
    } finally {
      _sosSheetOpen = false;
      _sosTicker?.cancel();
      notifier.clearSosState();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sosTicker?.cancel();
    _sos?.unbindUi();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(homeControllerProvider.notifier).ensureLoaded();
      // Pas de force : évite rechargement + re-notif SOS à chaque retour app.
      ref.read(cercleControllerProvider.notifier).load();
      unawaited(ref.read(sosServiceProvider).drainPendingAction());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncPullTickProvider, (prev, next) {
      if (prev == next) return;
      ref.read(homeControllerProvider.notifier).reloadProjection();
    });

    ref.listen(authSessionProvider, (prev, next) {
      if (next == null) return;
      if (prev?.hasPatientProfile == next.hasPatientProfile &&
          prev?.sessionId == next.sessionId &&
          prev?.isAidant == next.isAidant) {
        return;
      }
      _emptyRetryDone = false;
      ref.read(homeControllerProvider.notifier).ensureLoaded();
      ref.read(cercleControllerProvider.notifier).load(force: true);
    });

    ref.listen(homeControllerProvider, (prev, next) {
      final session = ref.read(authSessionProvider);
      final needsData = session?.hasPatientProfile == true ||
          next.profile?.hasPatientProfile == true;
      if (prev?.profile == null && next.profile != null) {
        ref.read(cercleControllerProvider.notifier).load(force: true);
      }
      if (!needsData) return;
      if (next.loading) return;
      if (next.dashboard != null) {
        _emptyRetryDone = false;
        return;
      }
      if (_emptyRetryDone) return;
      if (prev?.loading == true && !next.loading) {
        _emptyRetryDone = true;
        ref.read(homeControllerProvider.notifier).ensureLoaded();
      }
    });

    ref.listen(homeTabIndexProvider, (prev, next) {
      if (next == 2) {
        ref.read(cercleControllerProvider.notifier).load(force: true);
      }
    });

    final index = ref.watch(homeTabIndexProvider);
    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: IndexedStack(
                index: index,
                children: const [
                  HomeDashboardScreen(),
                  HealthScreen(),
                  HomeNetworkScreen(),
                  HomeProfileScreen(),
                ],
              ),
            ),
            const SyncStatusBanner(),
          ],
        ),
        bottomNavigationBar: FidelNavBar(
          index: index,
          onChanged: (i) =>
              ref.read(homeTabIndexProvider.notifier).state = i,
        ),
      ),
    );
  }
}

class _SosCountdownSheet extends StatelessWidget {
  const _SosCountdownSheet({
    required this.secondsLeft,
    required this.onCancel,
  });

  final int secondsLeft;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: tokens.elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.cercleSosSent,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.cercleSosCountdown(secondsLeft),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onCancel,
            child: Text(l10n.cercleSosCancel),
          ),
        ],
      ),
    );
  }
}

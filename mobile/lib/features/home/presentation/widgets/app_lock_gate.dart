import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/local_lock_service.dart';

/// Overlay PIN / biométrie au cold start et au resume (hors alarm-ring).
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
    required this.locked,
  });

  final Widget child;
  final bool locked;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _prompting = false;
  final _pin = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pin.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locked && !oldWidget.locked) {
      _unlocked = false;
      _maybeLock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final lock = ref.read(localLockServiceProvider);
      if (lock.isEnabled && widget.locked) {
        setState(() => _unlocked = false);
        _maybeLock();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final lock = ref.read(localLockServiceProvider);
      if (lock.isEnabled) {
        setState(() => _unlocked = false);
      }
    }
  }

  Future<void> _maybeLock() async {
    if (!widget.locked || _unlocked || _prompting) return;
    final lock = ref.read(localLockServiceProvider);
    if (!lock.isEnabled) {
      setState(() => _unlocked = true);
      return;
    }
    if (lock.biometricsEnabled) {
      _prompting = true;
      final l10n = AppLocalizations.of(context);
      final ok = await lock.authenticateBiometrics(
        reason: l10n.profileLockBiometricsReason,
      );
      _prompting = false;
      if (ok && mounted) setState(() => _unlocked = true);
    }
  }

  Future<void> _submitPin() async {
    final l10n = AppLocalizations.of(context);
    final ok =
        await ref.read(localLockServiceProvider).verifyPin(_pin.text.trim());
    if (ok) {
      _pin.clear();
      if (mounted) setState(() => _unlocked = true);
    } else {
      _pin.clear();
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileLockWrongPin)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(localLockServiceProvider);
    final needGate = widget.locked && lock.isEnabled && !_unlocked;
    if (!needGate) return widget.child;

    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Material(
            color: tokens.surface,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      l10n.profileLockEnterPin,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.profileLockPinLabel,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _submitPin(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitPin,
                      child: Text(l10n.profileLockUnlock),
                    ),
                    if (lock.biometricsEnabled) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _maybeLock,
                        child: Text(l10n.profileLockUseBiometrics),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

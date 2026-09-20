import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/local_lock_service.dart';

/// Réglages verrouillage local PIN / biométrie.
class ProfileLockScreen extends ConsumerStatefulWidget {
  const ProfileLockScreen({super.key});

  @override
  ConsumerState<ProfileLockScreen> createState() => _ProfileLockScreenState();
}

class _ProfileLockScreenState extends ConsumerState<ProfileLockScreen> {
  bool _busy = false;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok =
          await ref.read(localLockServiceProvider).canCheckBiometrics();
      if (mounted) setState(() => _bioAvailable = ok);
    });
  }

  Future<void> _setupPin() async {
    final pin = await _askPin(confirm: true);
    if (pin == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(localLockServiceProvider).enablePin(pin);
      if (mounted) {
        setState(() {});
        AppToast.success(context, l10n.profileLockEnabledToast);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          e is ApiException ? e.message : l10n.genericError,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final l10n = AppLocalizations.of(context);
    final pin = await _askPin(confirm: false, title: l10n.profileLockDisable);
    if (pin == null) return;
    final ok = await ref.read(localLockServiceProvider).verifyPin(pin);
    if (!ok) {
      if (mounted) AppToast.error(context, l10n.profileLockWrongPin);
      return;
    }
    await ref.read(localLockServiceProvider).disable();
    if (mounted) {
      setState(() {});
      AppToast.success(context, l10n.profileLockDisabledToast);
    }
  }

  Future<void> _toggleBio(bool value) async {
    final l10n = AppLocalizations.of(context);
    final lock = ref.read(localLockServiceProvider);
    if (value) {
      final ok = await lock.authenticateBiometrics(
        reason: l10n.profileLockBiometricsReason,
      );
      if (!ok) return;
    }
    await lock.setBiometrics(value);
    if (mounted) setState(() {});
  }

  Future<String?> _askPin({
    required bool confirm,
    String? title,
  }) async {
    final l10n = AppLocalizations.of(context);
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title ??
                    (confirm
                        ? l10n.profileLockSetupTitle
                        : l10n.profileLockEnterPin),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: c1,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.profileLockPinLabel,
                  counterText: '',
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: c2,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.profileLockPinConfirm,
                    counterText: '',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final a = c1.text.trim();
                  if (a.length < 4 || a.length > 6) {
                    AppToast.error(ctx, l10n.profileLockPinInvalid);
                    return;
                  }
                  if (confirm && a != c2.text.trim()) {
                    AppToast.error(ctx, l10n.profileLockPinMismatch);
                    return;
                  }
                  Navigator.pop(ctx, a);
                },
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final lock = ref.watch(localLockServiceProvider);
    final enabled = lock.isEnabled;

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l10n.profileLockTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              l10n.profileLockHint,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: tokens.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            PremiumCard(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                children: [
                  SwitchListTile(
                    value: enabled,
                    onChanged: _busy
                        ? null
                        : (v) async {
                            if (v) {
                              await _setupPin();
                            } else {
                              await _disable();
                            }
                          },
                    title: Text(l10n.profileLockEnable),
                    secondary: const Icon(IconsaxPlusLinear.lock_1),
                  ),
                  if (enabled && _bioAvailable)
                    SwitchListTile(
                      value: lock.biometricsEnabled,
                      onChanged: _busy ? null : _toggleBio,
                      title: Text(l10n.profileLockBiometrics),
                      secondary: const Icon(Icons.fingerprint),
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

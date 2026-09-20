import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/widgets/otp_pin_input.dart';
import '../application/home_controller.dart';
import 'widgets/profile_settings_tile.dart';

const _timezones = [
  'Africa/Douala',
  'Africa/Lagos',
  'Africa/Kinshasa',
  'Africa/Abidjan',
  'UTC',
  'Europe/Paris',
];

/// Téléphone, fuseau, email, mot de passe.
class ProfileAccountScreen extends ConsumerStatefulWidget {
  const ProfileAccountScreen({super.key});

  @override
  ConsumerState<ProfileAccountScreen> createState() =>
      _ProfileAccountScreenState();
}

class _ProfileAccountScreenState extends ConsumerState<ProfileAccountScreen> {
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(homeControllerProvider).profile;
    _phone = TextEditingController(text: p?.phone ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _savePhone() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(homeRepositoryProvider)
          .patchMe(phone: _phone.text.trim());
      ref.read(homeControllerProvider.notifier).updateProfile(updated);
      if (mounted) AppToast.success(context, l10n.profileSaved);
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          e is ApiException ? e.message : l10n.genericError,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTimezone() async {
    final l10n = AppLocalizations.of(context);
    final current =
        ref.read(homeControllerProvider).profile?.fuseauHoraire ?? 'Africa/Douala';
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final tz in _timezones)
                ListTile(
                  title: Text(tz),
                  trailing: tz == current
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, tz),
                ),
            ],
          ),
        );
      },
    );
    if (chosen == null || chosen == current) return;
    try {
      final updated = await ref
          .read(homeRepositoryProvider)
          .patchMe(fuseauHoraire: chosen);
      ref.read(homeControllerProvider.notifier).updateProfile(updated);
      if (mounted) AppToast.success(context, l10n.profileSaved);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  Future<void> _changePassword() async {
    final profile = ref.read(homeControllerProvider).profile;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ChangePasswordSheet(
        hasPassword: profile?.hasPassword ?? false,
      ),
    );
    if (ok == true && mounted) {
      final current = ref.read(homeControllerProvider).profile;
      if (current != null && !current.hasPassword) {
        ref.read(homeControllerProvider.notifier).updateProfile(
              current.copyWith(hasPassword: true),
            );
      }
    }
  }

  Future<void> _changeEmail() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _ChangeEmailSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final profile = ref.watch(homeControllerProvider).profile;

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.profileAccountTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              l10n.profileAccountHint,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: tokens.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            PremiumCard(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.profilePhone,
                      prefixIcon: const Icon(IconsaxPlusLinear.call),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _savePhone,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.commonSave),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ProfileSectionCard(
              title: l10n.profileTimezone,
              children: [
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.clock,
                  title: l10n.profileTimezone,
                  subtitle: profile?.fuseauHoraire ?? 'Africa/Douala',
                  onTap: _pickTimezone,
                  showDivider: false,
                ),
              ],
            ),
            if (profile?.email.isNotEmpty == true) ...[
              const SizedBox(height: 18),
              ProfileSectionCard(
                title: l10n.profileEmail,
                children: [
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.sms,
                    title: profile!.email,
                    subtitle: l10n.profileEmailChangeHint,
                    onTap: _changeEmail,
                    showDivider: false,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            ProfileSectionCard(
              title: l10n.profilePasswordSection,
              children: [
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.lock_1,
                  title: (profile?.hasPassword ?? false)
                      ? l10n.profilePasswordChange
                      : l10n.profilePasswordSet,
                  subtitle: (profile?.hasPassword ?? false)
                      ? l10n.profilePasswordChangeHint
                      : l10n.profilePasswordSetHint,
                  onTap: _changePassword,
                  showDivider: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet({required this.hasPassword});

  final bool hasPassword;

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final next = _next.text;
    if (next.length < 8) {
      AppToast.error(context, l10n.profilePasswordTooShort);
      return;
    }
    if (next != _confirm.text) {
      AppToast.error(context, l10n.profilePasswordMismatch);
      return;
    }
    if (widget.hasPassword && _current.text.isEmpty) {
      AppToast.error(context, l10n.profilePasswordCurrentRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: widget.hasPassword ? _current.text : null,
            nouveauPassword: next,
          );
      if (!mounted) return;
      AppToast.success(context, l10n.profilePasswordSaved);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.hasPassword
                  ? l10n.profilePasswordChange
                  : l10n.profilePasswordSet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            if (widget.hasPassword) ...[
              TextField(
                controller: _current,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l10n.profilePasswordCurrent,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _next,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.profilePasswordNew,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? IconsaxPlusLinear.eye
                        : IconsaxPlusLinear.eye_slash,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.profilePasswordConfirm,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeEmailSheet extends ConsumerStatefulWidget {
  const _ChangeEmailSheet();

  @override
  ConsumerState<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends ConsumerState<_ChangeEmailSheet> {
  final _email = TextEditingController();
  final _otpKey = GlobalKey<OtpPinInputState>();
  bool _otpSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!email.contains('@')) {
      AppToast.error(context, l10n.profileEmailInvalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .requestEmailChange(nouvelEmail: email);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _busy = false;
      });
      AppToast.success(context, l10n.profileEmailOtpSent);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  Future<void> _confirm(String code) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final email = await ref.read(authRepositoryProvider).confirmEmailChange(
            nouvelEmail: _email.text.trim(),
            code: code,
          );
      final profile = ref.read(homeControllerProvider).profile;
      if (profile != null) {
        ref.read(homeControllerProvider.notifier).updateProfile(
              profile.copyWith(email: email),
            );
      }
      if (!mounted) return;
      AppToast.success(context, l10n.profileEmailChanged);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _otpKey.currentState?.clear();
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileEmailChange,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            enabled: !_otpSent,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.profileEmailNew,
            ),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 16),
            Text(l10n.profileEmailOtpHint),
            const SizedBox(height: 12),
            OtpPinInput(
              key: _otpKey,
              onCompleted: _confirm,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : (_otpSent
                    ? () {
                        HapticFeedback.selectionClick();
                        final code = _otpKey.currentState?.code ?? '';
                        if (code.length == 6) _confirm(code);
                      }
                    : _request),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _otpSent ? l10n.profileEmailConfirm : l10n.profileEmailSendOtp,
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../application/home_controller.dart';
import 'activate_suivi_flow.dart';
import 'profile_photo_flow.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_settings_tile.dart';
import 'widgets/sticky_tab_header.dart';

class HomeProfileScreen extends ConsumerWidget {
  const HomeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final profile = state.profile;

    ref.listen<int>(profilePhotoPromptProvider, (prev, next) {
      if (next == 0 || next == prev) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          promptProfilePhotoFlow(context: context, ref: ref);
        }
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StickyTabHeader(
          title: l10n.navYou,
          subtitle: l10n.profileSubtitle,
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(homeControllerProvider.notifier).load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Premium.screenPad,
                8,
                Premium.screenPad,
                Premium.navClearance,
              ),
              children: [
          if (state.loading && profile == null)
            const HomeProfileSkeleton()
          else ...[
            if (profile != null) ...[
              ProfileHeaderCard(profile: profile),
              const SizedBox(height: 22),
            ],
            ProfileSectionCard(
              title: l10n.profileSectionAccount,
              children: [
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.user,
                  title: l10n.profileAccountTitle,
                  subtitle: l10n.profileAccountTileHint,
                  onTap: () => context.push('/home/profile/account'),
                  showDivider: true,
                ),
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.lock_1,
                  title: l10n.profileLockTitle,
                  subtitle: l10n.profileLockTileHint,
                  onTap: () => context.push('/home/profile/lock'),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ProfileSectionCard(
              title: l10n.profileSectionPrefs,
              children: [
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.language_circle,
                  title: l10n.profileLanguage,
                  subtitle: _languageLabel(l10n, locale),
                  onTap: () => _pickLanguage(context, ref),
                ),
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.brush_2,
                  title: l10n.homeThemeLabel,
                  subtitle: _themeLabel(l10n, themeMode),
                  onTap: () => _pickTheme(context, ref, themeMode),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ProfileSectionCard(
              title: l10n.profileSectionFollowUp,
              children: [
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.notification,
                  title: l10n.profileNotifications,
                  subtitle: l10n.profileNotificationsHint,
                  onTap: () => context.push('/home/notifications'),
                ),
                if (state.hasPatient) ...[
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.heart,
                    title: l10n.profileFicheSanteTitle,
                    subtitle: l10n.profileFicheSanteTileHint,
                    onTap: () => context.push('/home/profile/fiche-sante'),
                  ),
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.setting_2,
                    title: l10n.profilePatientSettingsTitle,
                    subtitle: l10n.profilePatientSettingsTileHint,
                    onTap: () =>
                        context.push('/home/profile/patient-settings'),
                  ),
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.alarm,
                    title: l10n.alarmSettingsTitle,
                    subtitle: l10n.alarmSettingsTileHint,
                    onTap: () =>
                        context.push('/home/profile/alarm-settings'),
                  ),
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.security_safe,
                    title: l10n.alarmHealthTitle,
                    subtitle: l10n.alarmHealthTileHint,
                    onTap: () => context.push('/home/profile/alarm-health'),
                  ),
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.call,
                    title: l10n.profileContactsTitle,
                    subtitle: l10n.profileContactsTileHint,
                    onTap: () => context.push('/home/profile/contacts'),
                  ),
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.microphone_2,
                    title: l10n.profileVoixTitle,
                    subtitle: l10n.profileVoixTileHint,
                    onTap: () => context.push('/home/profile/voix'),
                  ),
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.people,
                    title: l10n.homeShareCodeTitle,
                    subtitle: l10n.profileAidantsHint,
                    onTap: () => context.push('/home/aidants'),
                    showDivider: false,
                  ),
                ] else
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.health,
                    title: l10n.homeActivateTitle,
                    subtitle: l10n.homeActivateBody,
                    onTap: () => startActivateSuiviFlow(
                      context: context,
                      ref: ref,
                      l10n: l10n,
                      showSuccessToast: true,
                    ),
                    showDivider: false,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            ProfileSectionCard(
              title: l10n.profileSectionAlerts,
              children: [
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.shield_tick,
                  title: l10n.profileConsentTitle,
                  subtitle: l10n.profileConsentTileHint,
                  onTap: () => context.push('/home/profile/consent'),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ProfileSectionCard(
              title: l10n.profileSectionCaregiver,
              children: [
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.scan_barcode,
                  title: l10n.homeAccompanyTitle,
                  subtitle: l10n.profileSyncTileHint,
                  onTap: () => context.push('/home/sync'),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ProfileSectionCard(
              title: l10n.profileSectionLegal,
              children: [
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.document_text,
                  title: l10n.profileCgu,
                  subtitle:
                      l10n.profileCguVersion(AppConfig.cguCurrentVersion),
                  onTap: () => context.push('/home/profile/cgu'),
                ),
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.trash,
                  title: l10n.profileDeleteTitle,
                  subtitle: l10n.profileDeleteTileHint,
                  destructive: true,
                  onTap: () => context.push('/home/profile/delete'),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => _confirmLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  l10n.logout,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.homeThemeLight,
      ThemeMode.dark => l10n.homeThemeDark,
      ThemeMode.system => l10n.homeThemeSystem,
    };
  }

  static String _languageLabel(AppLocalizations l10n, Locale? locale) {
    final code = locale?.languageCode ?? 'fr';
    return code == 'en' ? l10n.languageEnglish : l10n.languageFrench;
  }

  static Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.homeThemeSystem),
                trailing: current == ThemeMode.system
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, ThemeMode.system),
              ),
              ListTile(
                title: Text(l10n.homeThemeLight),
                trailing: current == ThemeMode.light
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, ThemeMode.light),
              ),
              ListTile(
                title: Text(l10n.homeThemeDark),
                trailing: current == ThemeMode.dark
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, ThemeMode.dark),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (chosen != null) {
      await ref.read(themeControllerProvider.notifier).setThemeMode(chosen);
    }
  }

  static Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(localeControllerProvider)?.languageCode ?? 'fr';
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.languageFrench),
                trailing: current == 'fr'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, 'fr'),
              ),
              ListTile(
                title: Text(l10n.languageEnglish),
                trailing: current == 'en'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, 'en'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (chosen == null || chosen == current) return;
    if (!context.mounted) return;

    try {
      await ref
          .read(localeControllerProvider.notifier)
          .setLocale(Locale(chosen));
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(context, AppLocalizations.of(context).genericError);
      return;
    }

    try {
      final updated = await ref
          .read(homeRepositoryProvider)
          .patchMe(langue: chosen);
      ref.read(homeControllerProvider.notifier).updateProfile(updated);
    } catch (_) {
      // Langue UI déjà appliquée ; sync API best-effort.
    }
  }

  static Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.profileLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(authSessionProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}

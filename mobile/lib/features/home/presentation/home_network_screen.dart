import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/cercle_controller.dart';
import '../application/home_controller.dart';
import '../../../services/sos_service.dart';
import 'widgets/accompanied_patient_tile.dart';
import 'widgets/sticky_tab_header.dart';

class HomeNetworkScreen extends ConsumerStatefulWidget {
  const HomeNetworkScreen({super.key});

  @override
  ConsumerState<HomeNetworkScreen> createState() => _HomeNetworkScreenState();
}

class _HomeNetworkScreenState extends ConsumerState<HomeNetworkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cercleControllerProvider.notifier).load(force: true);
    });
  }

  Future<void> _triggerSos() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(sosServiceProvider).ensureCallPermission();
      await ref.read(sosServiceProvider).startSosFlow();
    } catch (e) {
      if (!mounted) return;
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
    final cercle = ref.watch(cercleControllerProvider);

    // Profil home arrivé après le 1er paint → recharge Cercle.
    ref.listen(homeControllerProvider, (prev, next) {
      final wasNull = prev?.profile == null;
      final nowReady = next.profile != null;
      final capsChanged =
          prev?.profile?.hasPatientProfile != next.profile?.hasPatientProfile ||
              prev?.profile?.isAidant != next.profile?.isAidant;
      if ((wasNull && nowReady) || capsChanged) {
        ref.read(cercleControllerProvider.notifier).load(force: true);
      }
    });

    // Onglet Cercle sélectionné → s’assurer que les données sont là.
    ref.listen(homeTabIndexProvider, (prev, next) {
      if (next == 2) {
        final s = ref.read(cercleControllerProvider);
        if (!s.loadedOnce || (!s.loading && s.error != null)) {
          ref.read(cercleControllerProvider.notifier).load(force: true);
        } else if (!s.loading &&
            s.hasPatient &&
            s.aidants.isEmpty &&
            s.contactsCount == 0 &&
            !s.isAidant) {
          // Capacités OK mais listes vides après race — un reload.
          ref.read(cercleControllerProvider.notifier).load(force: true);
        }
      }
    });

    final hasPatient = cercle.hasPatient;
    final isAidant = cercle.isAidant;
    final showSkeleton = cercle.loading && !cercle.loadedOnce;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StickyTabHeader(
          title: l10n.navPeople,
          subtitle: l10n.homeNetworkSubtitle,
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(cercleControllerProvider.notifier).load(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Premium.screenPad,
                8,
                Premium.screenPad,
                Premium.navClearance,
              ),
              children: [
                if (showSkeleton)
                  const _CercleSkeleton()
                else ...[
                  if (cercle.error != null) ...[
                    PremiumCard(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            cercle.error!,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => ref
                                .read(cercleControllerProvider.notifier)
                                .load(force: true),
                            child: Text(l10n.onboardingRetry),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (hasPatient || isAidant) ...[
                    _CercleHeroCard(
                      aidantsCount: cercle.aidants.length,
                      contactsCount: cercle.contactsCount,
                      patientsCount: cercle.accompaniedPatients.length,
                      hasPatient: hasPatient,
                      isAidant: isAidant,
                    ),
                    const SizedBox(height: 14),
                    _CercleQuickActions(
                      hasPatient: hasPatient,
                      isAidant: isAidant,
                      onAidants: () => context.push('/home/aidants'),
                      onSync: () => context.push('/home/sync'),
                      onContacts: () => context.push('/home/profile/contacts'),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (isAidant) ...[
                    _SectionLabel(title: l10n.cercleMyPatients),
                    const SizedBox(height: 10),
                    if (cercle.accompaniedPatients.isEmpty)
                      _EmptyCard(
                        title: l10n.cercleMyPatientsEmptyTitle,
                        body: l10n.cercleMyPatientsEmptyBody,
                        cta: l10n.homeAccompanyTitle,
                        onTap: () => context.push('/home/sync'),
                      )
                    else
                      PremiumCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0;
                                i < cercle.accompaniedPatients.length;
                                i++) ...[
                              AccompaniedPatientTile(
                                patient: cercle.accompaniedPatients[i],
                                signal: cercle.signalFor(
                                  cercle.accompaniedPatients[i].id,
                                ),
                                onTap: () => context.push(
                                  '/home/cercle/patient/${cercle.accompaniedPatients[i].id}',
                                  extra: cercle.accompaniedPatients[i],
                                ),
                              ),
                              if (i < cercle.accompaniedPatients.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 72,
                                  color: tokens.border,
                                ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  if (hasPatient) ...[
                    _SectionLabel(title: l10n.cercleMyCircle),
                    const SizedBox(height: 10),
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cercleMyCircleHint,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              height: 1.4,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (cercle.aidants.isEmpty)
                            Text(
                              l10n.cercleLinkAidantsHint,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                color: tokens.textSecondary,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final aidant in cercle.aidants)
                                  _NameChip(label: aidant.displayName),
                              ],
                            ),
                          const SizedBox(height: 14),
                          TextButton.icon(
                            onPressed: () => context.push('/home/aidants'),
                            icon: const Icon(IconsaxPlusLinear.people, size: 18),
                            label: Text(l10n.homeAidantsTitle),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(title: l10n.cercleSosTitle),
                    const SizedBox(height: 10),
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            cercle.hasContacts
                                ? l10n.cercleMyCircleHint
                                : l10n.cercleAddEmergencyContact,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              height: 1.4,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: cercle.busy
                                  ? null
                                  : (cercle.hasContacts
                                      ? _triggerSos
                                      : () => context
                                          .push('/home/profile/contacts')),
                              style: FilledButton.styleFrom(
                                backgroundColor: cercle.hasContacts
                                    ? Theme.of(context).colorScheme.error
                                    : AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              icon: Icon(
                                cercle.hasContacts
                                    ? IconsaxPlusLinear.warning_2
                                    : IconsaxPlusLinear.add_circle,
                              ),
                              label: Text(
                                cercle.hasContacts
                                    ? l10n.cercleSosTitle
                                    : l10n.cercleAddEmergencyContact,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (!hasPatient && !isAidant)
                    _EmptyCercleState(
                      onActivate: () =>
                          ref.read(homeTabIndexProvider.notifier).state = 0,
                      onSync: () => context.push('/home/sync'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CercleHeroCard extends StatelessWidget {
  const _CercleHeroCard({
    required this.aidantsCount,
    required this.contactsCount,
    required this.patientsCount,
    required this.hasPatient,
    required this.isAidant,
  });

  final int aidantsCount;
  final int contactsCount;
  final int patientsCount;
  final bool hasPatient;
  final bool isAidant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(
                    alpha: tokens.isDark ? 0.22 : 0.12,
                  ),
                ),
                child: const Icon(
                  IconsaxPlusLinear.people,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navPeople,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.homeNetworkSubtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        height: 1.35,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (hasPatient) ...[
                Expanded(
                  child: _HeroStat(
                    value: '$aidantsCount',
                    label: l10n.homeAidantsTitle,
                  ),
                ),
                Expanded(
                  child: _HeroStat(
                    value: '$contactsCount',
                    label: l10n.profileContactsTitle,
                  ),
                ),
              ],
              if (isAidant)
                Expanded(
                  child: _HeroStat(
                    value: '$patientsCount',
                    label: l10n.cercleMyPatients,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CercleQuickActions extends StatelessWidget {
  const _CercleQuickActions({
    required this.hasPatient,
    required this.isAidant,
    required this.onAidants,
    required this.onSync,
    required this.onContacts,
  });

  final bool hasPatient;
  final bool isAidant;
  final VoidCallback onAidants;
  final VoidCallback onSync;
  final VoidCallback onContacts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        if (hasPatient) ...[
          Expanded(
            child: _QuickChip(
              icon: IconsaxPlusLinear.people,
              label: l10n.homeAidantsTitle,
              onTap: onAidants,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickChip(
              icon: IconsaxPlusLinear.call,
              label: l10n.profileContactsTitle,
              onTap: onContacts,
            ),
          ),
        ],
        if (isAidant) ...[
          if (hasPatient) const SizedBox(width: 8),
          Expanded(
            child: _QuickChip(
              icon: IconsaxPlusLinear.scan_barcode,
              label: l10n.homeAccompanyTitle,
              onTap: onSync,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Material(
      color: AppColors.primary.withValues(alpha: tokens.isDark ? 0.16 : 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: tokens.textSecondary,
      ),
    );
  }
}

class _CercleSkeleton extends StatelessWidget {
  const _CercleSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    Widget bar({double h = 14, double w = double.infinity}) {
      return Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: tokens.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE8EEF5),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE8EEF5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(h: 16, w: 120),
                        const SizedBox(height: 8),
                        bar(h: 12, w: 200),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: bar(h: 36)),
                  const SizedBox(width: 12),
                  Expanded(child: bar(h: 36)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: bar(h: 64)),
            const SizedBox(width: 8),
            Expanded(child: bar(h: 64)),
            const SizedBox(width: 8),
            Expanded(child: bar(h: 64)),
          ],
        ),
      ],
    );
  }
}

class _NameChip extends StatelessWidget {
  const _NameChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: tokens.isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.textPrimary,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.body,
    required this.cta,
    required this.onTap,
  });

  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onTap, child: Text(cta)),
        ],
      ),
    );
  }
}

class _EmptyCercleState extends StatelessWidget {
  const _EmptyCercleState({required this.onActivate, required this.onSync});

  final VoidCallback onActivate;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(IconsaxPlusLinear.people, size: 28, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            l10n.cercleEmptyTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.cercleEmptyBody,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onActivate, child: Text(l10n.navHome)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onSync,
            child: Text(l10n.homeAccompanyTitle),
          ),
        ],
      ),
    );
  }
}

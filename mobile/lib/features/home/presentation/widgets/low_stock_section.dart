import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../medicaments/data/medicaments_repository.dart';
import '../../../medicaments/presentation/widgets/med_stock_sheet.dart';
import '../../application/home_controller.dart';

/// Médocs actifs dont le stock est ≤ seuil.
final lowStockMedsProvider =
    FutureProvider.autoDispose<List<ConfiguredMedicament>>((ref) async {
  final profile = ref.watch(homeControllerProvider).profile;
  if (profile?.hasPatientProfile != true) return const [];
  final meds = await ref
      .watch(medicamentsRepositoryProvider)
      .listMedicaments(actifsOnly: true);
  return meds
      .where((m) {
        final stock = m.stockRestant;
        final seuil = m.seuilAlerteStock;
        if (stock == null || seuil == null) return false;
        return stock <= seuil;
      })
      .toList(growable: false);
});

/// Bandeau Accueil — stock bas.
class LowStockSection extends ConsumerWidget {
  const LowStockSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lowStockMedsProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (meds) {
        if (meds.isEmpty) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context);
        final tokens = ThemeTokens.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              l10n.homeLowStockTitle,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            PremiumCard(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Column(
                children: [
                  for (var i = 0; i < meds.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: tokens.border),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(
                        IconsaxPlusLinear.warning_2,
                        color: const Color(0xFFD97706),
                        size: 22,
                      ),
                      title: Text(
                        meds[i].nom,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        l10n.homeLowStockLine(
                          meds[i].stockRestant ?? 0,
                          meds[i].seuilAlerteStock ?? 0,
                        ),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          color: tokens.textSecondary,
                        ),
                      ),
                      trailing: const Icon(IconsaxPlusLinear.arrow_right_3, size: 18),
                      onTap: () async {
                        await MedStockSheet.show(
                          context,
                          traitementId: meds[i].traitementId,
                        );
                        ref.invalidate(lowStockMedsProvider);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

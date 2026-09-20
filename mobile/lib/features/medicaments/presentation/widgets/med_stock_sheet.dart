import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../core/ui/app_toast.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/medicaments_repository.dart';

/// Bottom sheet pour mettre à jour stock + seuil d’un traitement.
class MedStockSheet extends ConsumerStatefulWidget {
  const MedStockSheet({super.key, required this.traitementId});

  final String traitementId;

  static Future<void> show(BuildContext context, {required String traitementId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedStockSheet(traitementId: traitementId),
    );
  }

  @override
  ConsumerState<MedStockSheet> createState() => _MedStockSheetState();
}

class _MedStockSheetState extends ConsumerState<MedStockSheet> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<ConfiguredMedicament> _meds = const [];
  final _stockCtrls = <String, TextEditingController>{};
  final _seuilCtrls = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _stockCtrls.values) {
      c.dispose();
    }
    for (final c in _seuilCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(medicamentsRepositoryProvider)
          .listMedicaments(
            traitementId: widget.traitementId,
            actifsOnly: true,
          );
      for (final c in _stockCtrls.values) {
        c.dispose();
      }
      for (final c in _seuilCtrls.values) {
        c.dispose();
      }
      _stockCtrls.clear();
      _seuilCtrls.clear();
      for (final m in items) {
        _stockCtrls[m.id] = TextEditingController(
          text: m.stockRestant?.toString() ?? '',
        );
        _seuilCtrls[m.id] = TextEditingController(
          text: m.seuilAlerteStock?.toString() ?? '',
        );
      }
      if (!mounted) return;
      setState(() {
        _meds = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : l10n.genericError;
      });
    }
  }

  Future<void> _saveOne(ConfiguredMedicament med) async {
    final l10n = AppLocalizations.of(context);
    final stockRaw = _stockCtrls[med.id]?.text.trim() ?? '';
    final seuilRaw = _seuilCtrls[med.id]?.text.trim() ?? '';

    if (stockRaw.isEmpty) {
      AppToast.error(context, l10n.medsStockInvalid);
      return;
    }
    final stock = int.tryParse(stockRaw);
    if (stock == null || stock < 0) {
      AppToast.error(context, l10n.medsStockInvalid);
      return;
    }

    int? seuil;
    if (seuilRaw.isNotEmpty) {
      seuil = int.tryParse(seuilRaw);
      if (seuil == null || seuil < 0) {
        AppToast.error(context, l10n.medsStockInvalid);
        return;
      }
    } else {
      seuil = 5;
      _seuilCtrls[med.id]?.text = '5';
    }

    setState(() => _busy = true);
    try {
      final repo = ref.read(medicamentsRepositoryProvider);
      if (seuil != med.seuilAlerteStock) {
        await repo.updateSeuil(medicamentId: med.id, seuilAlerteStock: seuil);
      }
      final result = await repo.updateStock(
        medicamentId: med.id,
        stockRestant: stock,
      );
      if (!mounted) return;
      AppToast.success(context, l10n.medsStockSaved);
      if (result.alerteDeclenchee) {
        AppToast.info(context, l10n.medsStockAlertTriggered);
      }
      await _load();
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
    final tokens = ThemeTokens.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: tokens.elevated,
          borderRadius: BorderRadius.circular(Premium.radius),
          border: Border.all(color: tokens.border),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(IconsaxPlusLinear.box, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.medsStockSheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.medsStockHint,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: tokens.textSecondary,
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, style: TextStyle(color: tokens.textSecondary)),
                )
              else if (_meds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.medsStockSheetEmpty,
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _meds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final m = _meds[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Premium.radiusSm),
                          border: Border.all(color: tokens.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${m.nom} ${m.dosage}'.trim(),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _stockCtrls[m.id],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    enabled: !_busy,
                                    decoration: InputDecoration(
                                      labelText: l10n.medsStockLabel,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _seuilCtrls[m.id],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    enabled: !_busy,
                                    decoration: InputDecoration(
                                      labelText: l10n.medsStockSeuilLabel,
                                      hintText: '5',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: _busy ? null : () => _saveOne(m),
                                child: Text(l10n.medsStockSave),
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
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/aidant_models.dart';

/// Ligne patient partagée Accueil / Cercle (nom + signal ou permissions).
class AccompaniedPatientTile extends StatelessWidget {
  const AccompaniedPatientTile({
    super.key,
    required this.patient,
    required this.onTap,
    this.signal,
  });

  final AidantPatient patient;
  final VoidCallback onTap;
  final AidantPatientSignal? signal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final subtitle = _subtitle(l10n);
    final pill = _pillColor(signal);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(
                    alpha: tokens.isDark ? 0.2 : 0.1,
                  ),
                ),
                child: Text(
                  patient.initial,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.displayName,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (pill != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pill,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(IconsaxPlusLinear.arrow_right_3, color: tokens.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) {
    switch (signal) {
      case AidantPatientSignal.sosActive:
        return l10n.aidantSignalSos;
      case AidantPatientSignal.missedToday:
        return l10n.aidantSignalMissed;
      case AidantPatientSignal.pendingToday:
        return l10n.aidantSignalPending;
      case AidantPatientSignal.okToday:
        return l10n.aidantSignalOk;
      case AidantPatientSignal.nothingToday:
        return l10n.aidantSignalNothing;
      case AidantPatientSignal.permissionLimited:
      case null:
        break;
    }
    if (patient.permissions.observance && patient.permissions.constantes) {
      return l10n.homeAidantsPermBoth;
    }
    if (patient.permissions.observance) {
      return l10n.homeAidantsPermObservanceOnly;
    }
    if (patient.permissions.constantes) {
      return l10n.homeAidantsPermConstantes;
    }
    return l10n.cerclePermissionLimited;
  }

  Color? _pillColor(AidantPatientSignal? signal) {
    switch (signal) {
      case AidantPatientSignal.sosActive:
        return AppColors.error;
      case AidantPatientSignal.missedToday:
        return const Color(0xFFE07A3D);
      case AidantPatientSignal.pendingToday:
        return const Color(0xFFD4A017);
      case AidantPatientSignal.okToday:
        return const Color(0xFF2F9E6E);
      case AidantPatientSignal.nothingToday:
        return AppColors.primary.withValues(alpha: 0.45);
      case AidantPatientSignal.permissionLimited:
      case null:
        return null;
    }
  }
}

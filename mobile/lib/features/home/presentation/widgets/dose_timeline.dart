import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/dose_slot.dart';
import '../../domain/dashboard_models.dart';

enum _Moment { morning, afternoon, evening }

/// Timeline des prises — groupée maladie × heure sous Matin / Après-midi / Soir.
/// [embedded] : pas de carte autour (défaut true pour le panneau Aujourd’hui).
class DoseTimeline extends StatelessWidget {
  const DoseTimeline({
    super.key,
    required this.prises,
    required this.now,
    required this.busy,
    this.onConfirmSlot,
    this.embedded = true,
    this.heroHandlesNext = false,
    this.readOnly = false,
  }) : assert(
          readOnly || onConfirmSlot != null,
          'onConfirmSlot is required when readOnly is false',
        );

  final List<PriseDuJour> prises;
  final DateTime now;
  final bool busy;

  /// Confirm V1 = tout le créneau (prises encore `en_attente`).
  final ValueChanged<DoseSlot>? onConfirmSlot;
  final bool embedded;

  /// Si true, le hero Accueil gère le CTA du prochain slot (pas de doublon).
  final bool heroHandlesNext;

  /// Observation seule — aucun bouton confirmer (vue aidant).
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    if (prises.isEmpty) {
      final empty = Row(
        children: [
          Icon(
            IconsaxPlusLinear.calendar_1,
            color: tokens.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.homeNoDoses,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.35,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ],
      );
      if (embedded) return empty;
      return PremiumCard(child: empty);
    }

    final slots = DoseSlot.groupPrises(prises);
    final nextSlotId = DoseSlot.findNextUntaken(prises, now)?.slotId;

    final groups = <_Moment, List<DoseSlot>>{};
    for (final s in slots) {
      groups.putIfAbsent(_momentOf(s.heurePrevue), () => []).add(s);
    }

    final rows = <Widget>[];
    var index = 0;
    final lastIndex = slots.length - 1;

    for (final moment in _Moment.values) {
      final items = groups[moment];
      if (items == null || items.isEmpty) continue;
      rows.add(_MomentHeader(moment: moment, l10n: l10n, tokens: tokens));
      for (final slot in items) {
        final pendingIds = DoseSlot.confirmablePriseIds(slot, prises);
        final isNext = slot.slotId == nextSlotId;
        rows.add(
          _SlotCard(
            slot: slot,
            prises: prises,
            now: now,
            busy: busy,
            isFirst: index == 0,
            isLast: index == lastIndex,
            isNext: isNext,
            readOnly: readOnly,
            onConfirm: readOnly ||
                    pendingIds.isEmpty ||
                    (heroHandlesNext && isNext) ||
                    onConfirmSlot == null
                ? null
                : () => onConfirmSlot!(slot),
          ),
        );
        index++;
      }
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
    if (embedded) return body;
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: body,
    );
  }

  static _Moment _momentOf(DateTime time) {
    if (time.hour < 12) return _Moment.morning;
    if (time.hour < 18) return _Moment.afternoon;
    return _Moment.evening;
  }
}

class _MomentHeader extends StatelessWidget {
  const _MomentHeader({
    required this.moment,
    required this.l10n,
    required this.tokens,
  });

  final _Moment moment;
  final AppLocalizations l10n;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (moment) {
      _Moment.morning => (IconsaxPlusLinear.sun_1, l10n.homeMomentMorning),
      _Moment.afternoon => (IconsaxPlusLinear.sun, l10n.homeMomentAfternoon),
      _Moment.evening => (IconsaxPlusLinear.moon, l10n.homeMomentEvening),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(icon, size: 14, color: tokens.textSecondary),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.prises,
    required this.now,
    required this.busy,
    required this.isFirst,
    required this.isLast,
    required this.isNext,
    required this.onConfirm,
    this.readOnly = false,
  });

  final DoseSlot slot;
  final List<PriseDuJour> prises;
  final DateTime now;
  final bool busy;
  final bool isFirst;
  final bool isLast;
  final bool isNext;
  final VoidCallback? onConfirm;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final byId = {for (final p in prises) p.id: p};
    final allTaken = slot.items.every((i) => byId[i.priseId]?.isTaken == true);
    final anyLate = slot.items.any((i) {
      final p = byId[i.priseId];
      return p != null && !p.isTaken && p.isLate(now);
    });
    final anyMissed = slot.items.any((i) => byId[i.priseId]?.isMissed == true);
    final takenCount = slot.items
        .where((i) => byId[i.priseId]?.isTaken == true)
        .length;
    final total = slot.items.length;

    final accent = allTaken
        ? AppColors.success
        : anyLate
            ? AppColors.warning
            : AppColors.primary;

    final maladie = slot.maladieNom.trim();
    final title = maladie.isNotEmpty
        ? maladie
        : (slot.items.length == 1
            ? slot.items.first.medicamentNom
            : (l10n.localeName.startsWith('en')
                ? '$total medications'
                : '$total médicaments'));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.primary.withValues(alpha: tokens.isDark ? 0.12 : 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Premium.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56.0 + (slot.items.length > 1 ? (slot.items.length - 1) * 18.0 : 0),
            child: _Rail(
              accent: accent,
              filled: allTaken,
              emphasized: isNext,
              isFirst: isFirst,
              isLast: isLast,
              tokens: tokens,
            ),
          ),
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                DateFormat.Hm().format(slot.heurePrevue),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: allTaken
                      ? tokens.textSecondary
                      : isNext
                          ? AppColors.primary
                          : tokens.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          fontWeight:
                              isNext ? FontWeight.w700 : FontWeight.w600,
                          height: 1.2,
                          color: allTaken
                              ? tokens.textSecondary
                              : tokens.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '$takenCount/$total',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: allTaken
                            ? AppColors.success
                            : tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (anyLate && !allTaken)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      anyMissed
                          ? l10n.homeMissedCanStillConfirm
                          : l10n.homeStatLate,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                for (final item in slot.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: byId[item.priseId]?.isTaken == true
                            ? tokens.textSecondary
                            : tokens.textPrimary.withValues(alpha: 0.85),
                        decoration: byId[item.priseId]?.isTaken == true
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: allTaken
                  ? Text(
                      l10n.homeTakenBadge,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    )
                  : _ConfirmButton(
                      accent: accent,
                      tooltip: l10n.homeTakeCta,
                      onTap: busy || onConfirm == null ? null : onConfirm,
                    ),
            )
          else if (allTaken)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.homeTakenBadge,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.accent,
    required this.filled,
    required this.emphasized,
    required this.isFirst,
    required this.isLast,
    required this.tokens,
  });

  final Color accent;
  final bool filled;
  final bool emphasized;
  final bool isFirst;
  final bool isLast;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final line = tokens.isDark
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFFD6DEE8);
    final dotSize = emphasized ? 14.0 : 12.0;

    return SizedBox(
      width: 26,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 2,
              color: isFirst ? Colors.transparent : line,
            ),
          ),
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? accent : Colors.transparent,
              border: Border.all(
                color: accent,
                width: emphasized ? 2.2 : 1.8,
              ),
              boxShadow: emphasized && !filled
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.28),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : line,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.accent,
    required this.tooltip,
    required this.onTap,
  });

  final Color accent;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Premium.radiusSm);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent.withValues(alpha: 0.08),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onTap!();
                },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(IconsaxPlusLinear.tick_circle, size: 18, color: accent),
          ),
        ),
      ),
    );
  }
}

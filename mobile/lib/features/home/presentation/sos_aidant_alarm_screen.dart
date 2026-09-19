import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/sos_aidant_alarm.dart';
import '../application/home_controller.dart';
import '../domain/aidant_models.dart';

/// Écran plein écran aidant : SOS patient + bouton Acquitter.
class SosAidantAlarmScreen extends ConsumerStatefulWidget {
  const SosAidantAlarmScreen({
    super.key,
    required this.sosId,
    required this.patientId,
    required this.patientPrenom,
  });

  final String sosId;
  final String patientId;
  final String patientPrenom;

  factory SosAidantAlarmScreen.fromAlert(ActiveSosAlert alert) {
    return SosAidantAlarmScreen(
      sosId: alert.sosId,
      patientId: alert.patientId,
      patientPrenom: alert.patientPrenom,
    );
  }

  @override
  ConsumerState<SosAidantAlarmScreen> createState() =>
      _SosAidantAlarmScreenState();
}

class _SosAidantAlarmScreenState extends ConsumerState<SosAidantAlarmScreen> {
  var _busy = false;

  bool get _valid => widget.sosId.trim().isNotEmpty;

  Future<void> _ack() async {
    if (!_valid) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final msg = await ref
          .read(homeRepositoryProvider)
          .ackSosAsAidant(widget.sosId);
      await SosAidantAlarm.cancel(widget.sosId);
      if (!mounted) return;
      AppToast.success(context, msg.isEmpty ? 'SOS acquitté' : msg);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prenom = widget.patientPrenom.trim().isEmpty
        ? 'Patient'
        : widget.patientPrenom;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.sos, size: 72, color: AppColors.error),
              const SizedBox(height: 24),
              Text(
                'SOS',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _valid
                    ? '$prenom a besoin d’aide'
                    : 'Alerte SOS incomplète. Réessaie depuis la notification.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const Spacer(),
              if (_valid)
                FilledButton(
                  onPressed: _busy ? null : _ack,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('J’ai pris en charge'),
                )
              else
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Retour'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  'Plus tard',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

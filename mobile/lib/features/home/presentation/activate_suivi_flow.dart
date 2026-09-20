import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';

/// Démarre « Activer mon suivi » : `POST /patients/me/activate` puis step C
/// (`/home/traitement` avec `fromActivate`), puis permissions device.
Future<void> startActivateSuiviFlow({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  bool showSuccessToast = false,
}) async {
  final busy = ref.read(homeControllerProvider).busy;
  if (busy) return;

  try {
    await ref.read(homeControllerProvider.notifier).activateFollowUp();
    if (!context.mounted) return;
    if (showSuccessToast) {
      AppToast.success(context, l10n.profileActivateOk);
    }
    context.push('/home/traitement', extra: true);
  } on ApiException catch (e) {
    if (!context.mounted) return;
    if (e.code == 'PATIENT_ALREADY_ACTIVE') {
      context.push('/home/traitement', extra: true);
      return;
    }
    AppToast.error(context, e.message);
  } catch (_) {
    if (!context.mounted) return;
    AppToast.error(context, l10n.genericError);
  }
}

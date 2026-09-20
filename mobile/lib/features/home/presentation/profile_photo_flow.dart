import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';

/// Timestamp ping — soft checklist photo → ouvrir le picker sur l’onglet Profil.
final profilePhotoPromptProvider = StateProvider<int>((ref) => 0);

Future<void> promptProfilePhotoFlow({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final profile = ref.read(homeControllerProvider).profile;
  if (profile == null || !profile.hasPatientProfile) return;
  final l10n = AppLocalizations.of(context);
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.profilePhotoGallery),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.profilePhotoCamera),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          if ((profile.photoUrl ?? '').isNotEmpty)
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(l10n.profilePhotoRemove),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
        ],
      ),
    ),
  );
  if (!context.mounted || action == null) return;
  if (action == 'remove') {
    try {
      await ref.read(homeRepositoryProvider).deletePatientPhoto();
      final p = ref.read(homeControllerProvider).profile;
      if (p != null) {
        ref.read(homeControllerProvider.notifier).updateProfile(
              p.copyWith(clearPhoto: true),
            );
      }
      if (context.mounted) {
        AppToast.success(context, l10n.profilePhotoRemoved);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          e is ApiException ? e.message : l10n.genericError,
        );
      }
    }
    return;
  }

  try {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;
    final lower = file.name.toLowerCase();
    final name = lower.endsWith('.png')
        ? 'avatar.png'
        : lower.endsWith('.webp')
            ? 'avatar.webp'
            : 'avatar.jpg';
    final settings = await ref.read(homeRepositoryProvider).uploadPatientPhoto(
          filename: name,
          bytes: bytes,
        );
    final p = ref.read(homeControllerProvider).profile;
    if (p != null) {
      ref.read(homeControllerProvider.notifier).updateProfile(
            p.copyWith(photoUrl: settings.photoUrl),
          );
    }
    if (context.mounted) {
      AppToast.success(context, l10n.profilePhotoSaved);
    }
  } catch (e) {
    if (context.mounted) {
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }
}

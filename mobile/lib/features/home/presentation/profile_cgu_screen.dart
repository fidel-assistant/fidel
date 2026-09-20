import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../l10n/app_localizations.dart';

/// CGU versionnées — lecture seule depuis Profil.
class ProfileCguScreen extends ConsumerWidget {
  const ProfileCguScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final version = AppConfig.cguCurrentVersion;
    final locale = Localizations.localeOf(context).languageCode;
    final body = locale.startsWith('fr') ? _cguFr(version) : _cguEn(version);

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.profileCgu),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              l10n.profileCguVersion(version),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            PremiumCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                body,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _cguFr(String version) => '''
Conditions générales d’utilisation — Fidel Assistant ($version)

1. Objet
Fidel Assistant est un compagnon d’accompagnement (rappels de prises, suivi personnel, cercle d’aidants). Il ne remplace pas un avis médical professionnel.

2. Compte
Tu es responsable de la confidentialité de tes identifiants. Tu peux supprimer ton compte depuis l’application (droit à l’oubli).

3. Données de santé
Les informations de suivi que tu saisis sont traitées pour te fournir le service. Les alertes vers des tiers (aidants) ne partent qu’avec ton consentement selon tes préférences.

4. Rappels locaux
Les alarmes médicaments sont déclenchées sur ton appareil. Un usage hors ligne est prévu ; la synchronisation reprend quand le réseau revient.

5. Acceptation
En utilisant Fidel, tu acceptes ces conditions dans leur version affichée. Une nouvelle version pourra te être proposée à la connexion.

Pour toute question : support via le canal communiqué par Fidel.
''';

String _cguEn(String version) => '''
Terms of use — Fidel Assistant ($version)

1. Purpose
Fidel Assistant is a care companion (dose reminders, personal follow-up, caregiver circle). It does not replace professional medical advice.

2. Account
You are responsible for keeping your credentials private. You can delete your account from the app (right to erasure).

3. Health data
Follow-up information you enter is processed to provide the service. Alerts to third parties (caregivers) are sent only with your consent according to your preferences.

4. Local reminders
Medicine alarms run on your device. Offline use is supported; sync resumes when the network returns.

5. Acceptance
By using Fidel, you accept these terms in the displayed version. A newer version may be offered at sign-in.

Questions: contact Fidel through the channel provided by the product.
''';

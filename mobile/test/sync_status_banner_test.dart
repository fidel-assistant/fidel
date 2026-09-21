import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/features/home/presentation/widgets/sync_status_banner.dart';
import 'package:fidel_assistant/l10n/app_localizations.dart';
import 'package:fidel_assistant/services/network_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows dead-letters banner when online and pending empty',
      (tester) async {
    final net = NetworkStatus(
      probe: () async => true,
      stabilityWindow: Duration.zero,
      oksToOnline: 1,
    );
    await net.runProbe();
    expect(net.state, NetworkLinkState.online);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkStatusProvider.overrideWith((ref) => net),
          outboxPendingCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
          outboxDeadLetterCountProvider.overrideWith(
            (ref) => Stream.value(1),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SyncStatusBanner()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('failed to sync'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidel_assistant/core/database/app_database.dart';
import 'package:fidel_assistant/features/home/domain/dashboard_models.dart';
import 'package:fidel_assistant/services/sync_outbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test('enqueue preserves FIFO in Drift', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final outbox = SyncOutbox(db, prefs: prefs);

    await outbox.enqueue(
      entity: 'prise',
      entityId: 'a',
      op: 'report',
      payload: {'nouvelle_heure': '2026-09-10T10:00:00Z'},
    );
    await outbox.enqueue(
      entity: 'prise',
      entityId: 'a',
      op: 'confirm',
      payload: {},
    );

    final ready = await outbox.listReady();
    expect(ready.map((e) => e.op).toList(), ['report', 'confirm']);
  });

  test('migrates sync_outbox_v1 prefs into Drift', () async {
    SharedPreferences.setMockInitialValues({
      SyncOutbox.prefsKey: jsonEncode([
        {
          'mutation_id': 'mid-1',
          'entity': 'prise',
          'entity_id': 'p1',
          'op': 'confirm',
          'payload': {'canal': 'app'},
          'client_ts': '2026-09-10T08:00:00.000Z',
          'attempts': 0,
          'next_attempt_at': '2026-09-10T08:00:00.000Z',
          'state': 'pending',
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final outbox = SyncOutbox(db, prefs: prefs);
    final ready = await outbox.listReady();
    expect(ready.single.mutationId, 'mid-1');
    expect(prefs.getString(SyncOutbox.prefsKey), isNull);
  });

  test('upsert dashboard then read projects prises', () async {
    final dash = PatientDashboard(
      prochaineAction: 'prise',
      medicamentsConfigures: true,
      notificationsAccordees: true,
      traitements: const [],
      prisesAujourdhui: [
        PriseDuJour(
          id: 'p1',
          medicamentNom: 'Aspi',
          dosage: '100mg',
          heurePrevue: DateTime.now(),
          statut: 'en_attente',
        ),
      ],
    );
    await db.upsertDashboard(dash);
    final read = await db.readDashboardMeta();
    expect(read, isNotNull);
    expect(read!.prisesAujourdhui.single.id, 'p1');
  });

  test('markPermanent then listFailedPermanent; requeue restores pending',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final outbox = SyncOutbox(db, prefs: prefs);

    final entry = await outbox.enqueue(
      entity: 'prise',
      entityId: 'p-dead',
      op: 'report',
      payload: {'nouvelle_heure': '2026-09-10T12:00:00Z'},
    );
    await outbox.markPermanent(entry.mutationId);

    final failed = await outbox.listFailedPermanent();
    expect(failed.single.mutationId, entry.mutationId);
    expect(failed.single.state, SyncOutboxState.failedPermanent);

    final active = await outbox.listPendingForProjection();
    expect(active, isEmpty);

    await outbox.requeue(entry.mutationId);
    final pending = await outbox.listPendingForProjection();
    expect(pending.single.mutationId, entry.mutationId);
    expect(pending.single.state, SyncOutboxState.pending);
    expect(pending.single.attempts, 0);
    expect(await outbox.listFailedPermanent(), isEmpty);
  });
}

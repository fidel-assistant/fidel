import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/home/domain/constante_models.dart';
import '../../features/home/domain/dashboard_models.dart';
import '../../services/sync_outbox.dart';
import 'connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PriseSnapshots,
    TraitementMirrors,
    SyncOutboxEntries,
    DashboardSnapshots,
    ConstanteSnapshots,
    CheckInSnapshots,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openAppConnection());

  /// DB mémoire pour tests.
  AppDatabase.memory() : super(openMemoryConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(priseSnapshots, priseSnapshots.serverVersion);
          }
          if (from < 3) {
            await m.createTable(constanteSnapshots);
            await m.createTable(checkInSnapshots);
          }
        },
      );

  // --- Prises ---

  Future<List<PriseDuJour>> listPrisesForDate(String dateKey) async {
    final rows = await (select(priseSnapshots)
          ..where((t) => t.dateKey.equals(dateKey))
          ..orderBy([(t) => OrderingTerm.asc(t.heurePrevue)]))
        .get();
    return rows.map(_priseFromRow).toList();
  }

  Future<PriseSnapshot?> getPrise(String id) {
    return (select(priseSnapshots)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertPrises(List<PriseDuJour> prises) async {
    if (prises.isEmpty) return;
    await batch((b) {
      for (final p in prises) {
        final dateKey =
            '${p.heurePrevue.toLocal().year.toString().padLeft(4, '0')}-'
            '${p.heurePrevue.toLocal().month.toString().padLeft(2, '0')}-'
            '${p.heurePrevue.toLocal().day.toString().padLeft(2, '0')}';
        b.insert(
          priseSnapshots,
          PriseSnapshotsCompanion.insert(
            id: p.id,
            dateKey: dateKey,
            heurePrevue: p.heurePrevue.toUtc(),
            statut: p.statut,
            medicamentNom: Value(p.medicamentNom),
            dosage: Value(p.dosage),
            updatedAt: Value(DateTime.now().toUtc()),
            serverVersion: const Value(1),
            payloadJson: Value(
              jsonEncode({
                'id': p.id,
                'medicament_nom': p.medicamentNom,
                'dosage': p.dosage,
                'heure_prevue': p.heurePrevue.toUtc().toIso8601String(),
                'statut': p.statut,
                if (p.traitementId != null) 'traitement_id': p.traitementId,
                if (p.maladieId != null) 'maladie_id': p.maladieId,
                if (p.maladieNom != null) 'maladie_nom': p.maladieNom,
              }),
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> updatePriseLocal({
    required String id,
    String? statut,
    DateTime? heurePrevue,
  }) async {
    final existing = await getPrise(id);
    if (existing == null) {
      if (statut == null && heurePrevue == null) return;
      final when = (heurePrevue ?? DateTime.now()).toUtc();
      final dateKey =
          '${when.toLocal().year.toString().padLeft(4, '0')}-'
          '${when.toLocal().month.toString().padLeft(2, '0')}-'
          '${when.toLocal().day.toString().padLeft(2, '0')}';
      await into(priseSnapshots).insert(
        PriseSnapshotsCompanion.insert(
          id: id,
          dateKey: dateKey,
          heurePrevue: when,
          statut: statut ?? 'en_attente',
          updatedAt: Value(DateTime.now().toUtc()),
        ),
        mode: InsertMode.insertOrReplace,
      );
      return;
    }
    await (update(priseSnapshots)..where((t) => t.id.equals(id))).write(
      PriseSnapshotsCompanion(
        statut: statut != null ? Value(statut) : const Value.absent(),
        heurePrevue:
            heurePrevue != null ? Value(heurePrevue.toUtc()) : const Value.absent(),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  PriseDuJour _priseFromRow(PriseSnapshot row) {
    if (row.payloadJson != null && row.payloadJson!.isNotEmpty) {
      try {
        return PriseDuJour.fromJson(
          jsonDecode(row.payloadJson!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return PriseDuJour(
      id: row.id,
      medicamentNom: row.medicamentNom,
      dosage: row.dosage,
      heurePrevue: row.heurePrevue.toLocal(),
      statut: row.statut,
    );
  }

  // --- Dashboard meta ---

  Future<void> upsertDashboard(PatientDashboard dashboard) async {
    await upsertPrises(dashboard.prisesAujourdhui);
    await into(dashboardSnapshots).insert(
      DashboardSnapshotsCompanion.insert(
        id: const Value(1),
        prochaineAction: dashboard.prochaineAction,
        medicamentsConfigures: dashboard.medicamentsConfigures,
        notificationsAccordees: dashboard.notificationsAccordees,
        traitementsJson: jsonEncode(
          dashboard.traitements
              .map(
                (t) => {
                  'id': t.id,
                  'maladie_code': t.maladieCode,
                  'maladie_nom': t.maladieNom,
                  'phase': t.phase,
                  'medicaments_configures': t.medicamentsConfigures,
                  if (t.dateDebut != null)
                    'date_debut': t.dateDebut!.toIso8601String(),
                  if (t.jourTraitement != null)
                    'jour_traitement': t.jourTraitement,
                },
              )
              .toList(),
        ),
        updatedAt: DateTime.now().toUtc(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<PatientDashboard?> readDashboardMeta() async {
    final meta = await (select(dashboardSnapshots)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (meta == null) return null;
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final prises = await listPrisesForDate(dateKey);
    List<DashboardTraitement> traitements = const [];
    try {
      final decoded = jsonDecode(meta.traitementsJson);
      if (decoded is List) {
        traitements = decoded
            .whereType<Map>()
            .map(
              (e) => DashboardTraitement.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (_) {}
    return PatientDashboard(
      prochaineAction: meta.prochaineAction,
      medicamentsConfigures: meta.medicamentsConfigures,
      notificationsAccordees: meta.notificationsAccordees,
      traitements: traitements,
      prisesAujourdhui: prises,
    );
  }

  // --- Traitements mirror ---

  Future<void> upsertTraitements(List<TraitementDetail> details) async {
    await batch((b) {
      for (final t in details) {
        b.insert(
          traitementMirrors,
          TraitementMirrorsCompanion.insert(
            id: t.id,
            payloadJson: jsonEncode(t.toCacheJson()),
            updatedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<Map<String, TraitementDetail>> readTraitementDetails() async {
    final rows = await select(traitementMirrors).get();
    final out = <String, TraitementDetail>{};
    for (final row in rows) {
      try {
        final m = jsonDecode(row.payloadJson) as Map<String, dynamic>;
        out[row.id] = TraitementDetail.fromJson(m);
      } catch (_) {}
    }
    return out;
  }

  // --- Outbox ---

  Future<int> _nextOutboxSortIndex() async {
    final maxExpr = syncOutboxEntries.sortIndex.max();
    final query = selectOnly(syncOutboxEntries)..addColumns([maxExpr]);
    final row = await query.getSingle();
    final current = row.read(maxExpr);
    return (current ?? -1) + 1;
  }

  Future<SyncOutboxEntry> insertOutboxEntry(SyncOutboxEntry entry) async {
    final sort = await _nextOutboxSortIndex();
    await into(syncOutboxEntries).insert(
      SyncOutboxEntriesCompanion.insert(
        mutationId: entry.mutationId,
        entity: entry.entity,
        entityId: entry.entityId,
        op: entry.op,
        payloadJson: jsonEncode(entry.payload),
        clientTs: entry.clientTs.toUtc(),
        attempts: Value(entry.attempts),
        nextAttemptAt: entry.nextAttemptAt.toUtc(),
        state: entry.state.wireName,
        sortIndex: sort,
      ),
      mode: InsertMode.insertOrReplace,
    );
    return entry;
  }

  Future<List<SyncOutboxEntry>> listAllOutbox() async {
    final rows = await (select(syncOutboxEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.sortIndex)]))
        .get();
    return rows.map(_outboxFromRow).toList();
  }

  Future<List<SyncOutboxEntry>> listActiveOutbox() async {
    final rows = await (select(syncOutboxEntries)
          ..where(
            (t) => t.state.isNotValue(SyncOutboxState.failedPermanent.wireName),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sortIndex)]))
        .get();
    return rows.map(_outboxFromRow).toList();
  }

  Future<void> updateOutboxEntry(SyncOutboxEntry entry) async {
    await (update(syncOutboxEntries)
          ..where((t) => t.mutationId.equals(entry.mutationId)))
        .write(
      SyncOutboxEntriesCompanion(
        attempts: Value(entry.attempts),
        nextAttemptAt: Value(entry.nextAttemptAt.toUtc()),
        state: Value(entry.state.wireName),
        payloadJson: Value(jsonEncode(entry.payload)),
      ),
    );
  }

  Future<void> deleteOutboxEntry(String mutationId) async {
    await (delete(syncOutboxEntries)
          ..where((t) => t.mutationId.equals(mutationId)))
        .go();
  }

  Future<bool> hasPendingOutboxForEntity(String entityId) async {
    final rows = await (select(syncOutboxEntries)
          ..where(
            (t) =>
                t.entityId.equals(entityId) &
                t.state.isIn([
                  SyncOutboxState.pending.wireName,
                  SyncOutboxState.inflight.wireName,
                ]),
          ))
        .get();
    return rows.isNotEmpty;
  }

  /// Merge entities from GET /sync/pull. Skips prises with pending outbox.
  Future<void> mergePullEntities(List<Map<String, dynamic>> entities) async {
    for (final raw in entities) {
      final type = raw['type'] as String?;
      if (type == 'prise') {
        await _mergePriseEntity(raw);
      } else if (type == 'traitement') {
        await _mergeTraitementEntity(raw);
      } else if (type == 'constante') {
        await _mergeConstanteEntity(raw);
      } else if (type == 'check_in') {
        await _mergeCheckInEntity(raw);
      }
    }
  }

  Future<void> upsertConstanteLocal({
    required String id,
    required String typeCode,
    required Object valeur,
    required String unite,
    required DateTime mesureAt,
    String source = 'manuel',
  }) async {
    await into(constanteSnapshots).insert(
      ConstanteSnapshotsCompanion.insert(
        id: id,
        typeCode: typeCode,
        valeurJson: jsonEncode(valeur),
        unite: unite,
        mesureAt: mesureAt.toUtc(),
        source: Value(source),
        createdAt: Value(DateTime.now().toUtc()),
        serverVersion: const Value(1),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<List<Constante>> listConstantesSince(DateTime depuis) async {
    final rows = await (select(constanteSnapshots)
          ..where((t) => t.mesureAt.isBiggerOrEqualValue(depuis.toUtc()))
          ..orderBy([(t) => OrderingTerm.desc(t.mesureAt)]))
        .get();
    return rows.map(_constanteFromRow).whereType<Constante>().toList();
  }

  Future<void> replaceConstantes(List<Constante> items) async {
    await delete(constanteSnapshots).go();
    for (final c in items) {
      final valeur = c.diastolique != null
          ? '${c.systolique.toInt()}/${c.diastolique!.toInt()}'
          : c.systolique;
      await into(constanteSnapshots).insert(
        ConstanteSnapshotsCompanion.insert(
          id: c.id,
          typeCode: c.type.code,
          valeurJson: jsonEncode(valeur),
          unite: c.unite,
          mesureAt: c.mesureAt.toUtc(),
          createdAt: Value(c.mesureAt.toUtc()),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> upsertCheckInLocal({
    required String id,
    required DateTime date,
    required String statut,
  }) async {
    final local = date.toLocal();
    final dateKey =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    // One row per day — remove other ids for same dateKey
    await (delete(checkInSnapshots)..where((t) => t.dateKey.equals(dateKey))).go();
    await into(checkInSnapshots).insert(
      CheckInSnapshotsCompanion.insert(
        id: id,
        dateKey: dateKey,
        statut: statut,
        createdAt: Value(DateTime.now().toUtc()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<CheckInEntry?> getCheckInForDateKey(String dateKey) async {
    final row = await (select(checkInSnapshots)
          ..where((t) => t.dateKey.equals(dateKey)))
        .getSingleOrNull();
    if (row == null) return null;
    return CheckInEntry(
      date: DateTime.parse(row.dateKey),
      statut: row.statut,
    );
  }

  Future<void> _mergeConstanteEntity(Map<String, dynamic> raw) async {
    final id = raw['id'] as String?;
    if (id == null || id.isEmpty) return;
    if (await hasPendingOutboxForEntity(id)) return;

    final code = (raw['type_constante'] ?? raw['constante_type'])?.toString();
    if (code == null || code.isEmpty) return;

    final mesureRaw = raw['mesure_at'] as String?;
    final mesure = mesureRaw != null
        ? DateTime.parse(mesureRaw).toUtc()
        : DateTime.now().toUtc();
    final createdRaw = raw['created_at'] ?? raw['updated_at'];
    final created = createdRaw is String
        ? DateTime.parse(createdRaw).toUtc()
        : mesure;

    await into(constanteSnapshots).insert(
      ConstanteSnapshotsCompanion.insert(
        id: id,
        typeCode: code,
        valeurJson: jsonEncode(raw['valeur']),
        unite: (raw['unite'] as String?) ?? '',
        mesureAt: mesure,
        source: Value((raw['source'] as String?) ?? 'manuel'),
        createdAt: Value(created),
        serverVersion: Value((raw['server_version'] as num?)?.toInt() ?? 1),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> _mergeCheckInEntity(Map<String, dynamic> raw) async {
    final id = raw['id'] as String?;
    if (id == null || id.isEmpty) return;
    final dateRaw = raw['date']?.toString();
    if (dateRaw == null || dateRaw.isEmpty) return;
    final dateKey = dateRaw.length >= 10 ? dateRaw.substring(0, 10) : dateRaw;
    if (await hasPendingOutboxForEntity(dateKey) ||
        await hasPendingOutboxForEntity(id)) {
      return;
    }
    final createdRaw = raw['created_at'] ?? raw['updated_at'];
    final created = createdRaw is String
        ? DateTime.parse(createdRaw).toUtc()
        : DateTime.now().toUtc();
    await (delete(checkInSnapshots)..where((t) => t.dateKey.equals(dateKey))).go();
    await into(checkInSnapshots).insert(
      CheckInSnapshotsCompanion.insert(
        id: id,
        dateKey: dateKey,
        statut: (raw['statut'] as String?) ?? 'ca_va',
        createdAt: Value(created),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Constante? _constanteFromRow(ConstanteSnapshot row) {
    Object? valeur;
    try {
      valeur = jsonDecode(row.valeurJson);
    } catch (_) {
      valeur = row.valeurJson;
    }
    return Constante.tryParse({
      'id': row.id,
      'type': row.typeCode,
      'unite': row.unite,
      'mesure_at': row.mesureAt.toIso8601String(),
      'valeur': valeur,
    });
  }

  Future<void> _mergePriseEntity(Map<String, dynamic> raw) async {
    final id = raw['id'] as String?;
    if (id == null || id.isEmpty) return;
    if (await hasPendingOutboxForEntity(id)) return;

    final remoteVersion = (raw['server_version'] as num?)?.toInt() ?? 1;
    final existing = await getPrise(id);
    if (existing != null && existing.serverVersion >= remoteVersion) {
      return;
    }

    final heureRaw = raw['heure_prevue'] as String?;
    final heure = heureRaw != null
        ? DateTime.parse(heureRaw).toUtc()
        : (existing?.heurePrevue ?? DateTime.now().toUtc());
    final dateKey =
        '${heure.toLocal().year.toString().padLeft(4, '0')}-'
        '${heure.toLocal().month.toString().padLeft(2, '0')}-'
        '${heure.toLocal().day.toString().padLeft(2, '0')}';
    final updatedAtRaw = raw['updated_at'] as String?;
    final updatedAt = updatedAtRaw != null
        ? DateTime.parse(updatedAtRaw).toUtc()
        : DateTime.now().toUtc();

    final payload = Map<String, dynamic>.from(raw)
      ..remove('type')
      ..remove('server_version');

    await into(priseSnapshots).insert(
      PriseSnapshotsCompanion.insert(
        id: id,
        dateKey: dateKey,
        heurePrevue: heure,
        statut: (raw['statut'] as String?) ?? existing?.statut ?? 'en_attente',
        medicamentNom: Value(
          raw['medicament_nom'] as String? ??
              existing?.medicamentNom ??
              '',
        ),
        dosage: Value(raw['dosage'] as String? ?? existing?.dosage ?? ''),
        updatedAt: Value(updatedAt),
        serverVersion: Value(remoteVersion),
        payloadJson: Value(jsonEncode(payload)),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> _mergeTraitementEntity(Map<String, dynamic> raw) async {
    final id = raw['id'] as String?;
    if (id == null || id.isEmpty) return;
    final payload = raw['payload'];
    final payloadMap = payload is Map
        ? Map<String, dynamic>.from(payload)
        : Map<String, dynamic>.from(raw)
      ..remove('type')
      ..remove('server_version')
      ..remove('updated_at');
    final updatedAtRaw = raw['updated_at'] as String?;
    final updatedAt = updatedAtRaw != null
        ? DateTime.parse(updatedAtRaw).toUtc()
        : DateTime.now().toUtc();
    await into(traitementMirrors).insert(
      TraitementMirrorsCompanion.insert(
        id: id,
        payloadJson: jsonEncode(payloadMap),
        updatedAt: updatedAt,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  SyncOutboxEntry _outboxFromRow(OutboxRow row) {
    Map<String, dynamic> payload = {};
    try {
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is Map) {
        payload = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return SyncOutboxEntry(
      mutationId: row.mutationId,
      entity: row.entity,
      entityId: row.entityId,
      op: row.op,
      payload: payload,
      clientTs: row.clientTs.toUtc(),
      attempts: row.attempts,
      nextAttemptAt: row.nextAttemptAt.toUtc(),
      state: SyncOutboxState.fromWire(row.state),
    );
  }
}

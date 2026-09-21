import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';

/// Entrée outbox conforme au contrat `offline-sync`.
class SyncOutboxEntry {
  SyncOutboxEntry({
    required this.mutationId,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.clientTs,
    this.attempts = 0,
    DateTime? nextAttemptAt,
    this.state = SyncOutboxState.pending,
  }) : nextAttemptAt = nextAttemptAt ?? clientTs;

  final String mutationId;
  final String entity;
  final String entityId;
  final String op;
  final Map<String, dynamic> payload;
  final DateTime clientTs;
  final int attempts;
  final DateTime nextAttemptAt;
  final SyncOutboxState state;

  SyncOutboxEntry copyWith({
    int? attempts,
    DateTime? nextAttemptAt,
    SyncOutboxState? state,
  }) {
    return SyncOutboxEntry(
      mutationId: mutationId,
      entity: entity,
      entityId: entityId,
      op: op,
      payload: payload,
      clientTs: clientTs,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => {
        'mutation_id': mutationId,
        'entity': entity,
        'entity_id': entityId,
        'op': op,
        'payload': payload,
        'client_ts': clientTs.toUtc().toIso8601String(),
        'attempts': attempts,
        'next_attempt_at': nextAttemptAt.toUtc().toIso8601String(),
        'state': state.wireName,
      };

  factory SyncOutboxEntry.fromJson(Map<String, dynamic> json) {
    return SyncOutboxEntry(
      mutationId: '${json['mutation_id']}',
      entity: '${json['entity']}',
      entityId: '${json['entity_id']}',
      op: '${json['op']}',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      clientTs: DateTime.parse('${json['client_ts']}').toUtc(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      nextAttemptAt: DateTime.parse(
        '${json['next_attempt_at'] ?? json['client_ts']}',
      ).toUtc(),
      state: SyncOutboxState.fromWire(json['state']),
    );
  }
}

enum SyncOutboxState {
  pending,
  inflight,
  failedPermanent;

  String get wireName => switch (this) {
        SyncOutboxState.pending => 'pending',
        SyncOutboxState.inflight => 'inflight',
        SyncOutboxState.failedPermanent => 'failed_permanent',
      };

  static SyncOutboxState fromWire(Object? raw) {
    final s = '$raw';
    return SyncOutboxState.values.firstWhere(
      (e) => e.wireName == s || e.name == s,
      orElse: () => SyncOutboxState.pending,
    );
  }
}

/// Outbox Drift (Phase 3) — migration one-shot depuis SharedPreferences.
class SyncOutbox {
  SyncOutbox(
    this._db, {
    SharedPreferences? prefs,
  }) : _prefs = prefs;

  static const prefsKey = 'sync_outbox_v1';
  static const legacyKey = 'pending_prise_sync_v1';
  static const _uuid = Uuid();

  final AppDatabase _db;
  final SharedPreferences? _prefs;
  bool _migrated = false;

  Future<void> ensureMigrated() async {
    if (_migrated) return;
    _migrated = true;
    final prefs = _prefs;
    if (prefs == null) return;

    // Prefs outbox v1 → Drift
    final raw = prefs.getString(prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;
            await _db.insertOutboxEntry(
              SyncOutboxEntry.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      } catch (_) {}
      await prefs.remove(prefsKey);
    }

    // Legacy pending_prise_sync_v1 → Drift
    final legacy = prefs.getString(legacyKey);
    if (legacy == null || legacy.isEmpty) return;
    try {
      final decoded = jsonDecode(legacy);
      if (decoded is! List) {
        await prefs.remove(legacyKey);
        return;
      }
      final now = DateTime.now().toUtc();
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final type = map['type'] as String?;
        final priseId = map['priseId'] as String?;
        if (priseId == null || priseId.isEmpty) continue;
        if (type == 'confirm') {
          await _db.insertOutboxEntry(
            SyncOutboxEntry(
              mutationId: _uuid.v4(),
              entity: 'prise',
              entityId: priseId,
              op: 'confirm',
              payload: {
                'confirmee_at': map['confirmeeAt'] ?? now.toIso8601String(),
                'canal': 'app',
              },
              clientTs: now,
            ),
          );
        } else if (type == 'report') {
          final rawHeure = map['nouvelleHeure'] as String?;
          if (rawHeure == null) continue;
          await _db.insertOutboxEntry(
            SyncOutboxEntry(
              mutationId: _uuid.v4(),
              entity: 'prise',
              entityId: priseId,
              op: 'report',
              payload: {'nouvelle_heure': rawHeure},
              clientTs: now,
            ),
          );
        }
      }
    } catch (_) {}
    await prefs.remove(legacyKey);
  }

  Future<SyncOutboxEntry> enqueue({
    required String entity,
    required String entityId,
    required String op,
    required Map<String, dynamic> payload,
    DateTime? clientTs,
    String? mutationId,
  }) async {
    await ensureMigrated();
    final entry = SyncOutboxEntry(
      mutationId: mutationId ?? _uuid.v4(),
      entity: entity,
      entityId: entityId,
      op: op,
      payload: payload,
      clientTs: (clientTs ?? DateTime.now()).toUtc(),
    );
    return _db.insertOutboxEntry(entry);
  }

  Future<List<SyncOutboxEntry>> listReady({DateTime? now}) async {
    await ensureMigrated();
    final t = (now ?? DateTime.now()).toUtc();
    final all = await _db.listAllOutbox();
    return all
        .where(
          (e) =>
              e.state != SyncOutboxState.failedPermanent &&
              !e.nextAttemptAt.isAfter(t),
        )
        .toList(growable: false);
  }

  /// Mutations actives pour projection UI (pending + inflight).
  Future<List<SyncOutboxEntry>> listPendingForProjection() async {
    await ensureMigrated();
    return _db.listActiveOutbox();
  }

  Future<void> markInflight(String mutationId) async {
    await ensureMigrated();
    final all = await _db.listAllOutbox();
    final idx = all.indexWhere((e) => e.mutationId == mutationId);
    if (idx < 0) return;
    await _db.updateOutboxEntry(
      all[idx].copyWith(state: SyncOutboxState.inflight),
    );
  }

  Future<void> markDone(String mutationId) async {
    await ensureMigrated();
    await _db.deleteOutboxEntry(mutationId);
  }

  Future<void> markRetry(String mutationId, {required int attempts}) async {
    await ensureMigrated();
    final delaySec = min(300, pow(2, attempts).toInt());
    final jitter = Random().nextDouble() * 0.6 - 0.3;
    final seconds = max(1, (delaySec * (1 + jitter)).round());
    final next = DateTime.now().toUtc().add(Duration(seconds: seconds));
    final all = await _db.listAllOutbox();
    final idx = all.indexWhere((e) => e.mutationId == mutationId);
    if (idx < 0) return;
    await _db.updateOutboxEntry(
      all[idx].copyWith(
        attempts: attempts,
        nextAttemptAt: next,
        state: SyncOutboxState.pending,
      ),
    );
  }

  Future<void> markPermanent(String mutationId) async {
    await ensureMigrated();
    final all = await _db.listAllOutbox();
    final idx = all.indexWhere((e) => e.mutationId == mutationId);
    if (idx < 0) return;
    await _db.updateOutboxEntry(
      all[idx].copyWith(state: SyncOutboxState.failedPermanent),
    );
  }

  /// Dead letters — rejets permanents exclus du flush.
  Future<List<SyncOutboxEntry>> listFailedPermanent() async {
    await ensureMigrated();
    return _db.listFailedPermanentOutbox();
  }

  /// Remet une dead letter en file (pending) pour un nouvel essai.
  Future<void> requeue(String mutationId) async {
    await ensureMigrated();
    final all = await _db.listAllOutbox();
    final idx = all.indexWhere((e) => e.mutationId == mutationId);
    if (idx < 0) return;
    await _db.updateOutboxEntry(
      all[idx].copyWith(
        attempts: 0,
        nextAttemptAt: DateTime.now().toUtc(),
        state: SyncOutboxState.pending,
      ),
    );
  }
}

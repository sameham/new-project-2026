// lib/database/dao/sync_queue_dao.dart

import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {

  SyncQueueDao(super.db);

  Future<int> enqueue({
    required String targetTable,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) =>
      into(syncQueue).insert(
        SyncQueueCompanion.insert(
          targetTable:  targetTable,
          recordId:   recordId,
          operation:  operation,
          payload:    jsonEncode(payload),
          status:     const Value('pending'),
          retryCount: const Value(0),
          createdAt:  Value(DateTime.now()),
        ),
      );

  Future<List<SyncQueueData>> getPending({int limit = 50}) =>
      (select(syncQueue)
        ..where((q) => q.status.equals('pending'))
        ..orderBy([(q) => OrderingTerm.asc(q.createdAt)])
        ..limit(limit))
      .get();

  Future<int> getPendingCount() async {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([count])
      ..where(syncQueue.status.equals('pending'));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Stream<int> watchPendingCount() {
    final count = syncQueue.id.count();
    return (selectOnly(syncQueue)
      ..addColumns([count])
      ..where(syncQueue.status.equals('pending')))
    .watchSingle()
    .map((row) => row.read(count) ?? 0);
  }

  Future<void> markSynced(int id) async =>
      (update(syncQueue)..where((q) => q.id.equals(id)))
          .write(SyncQueueCompanion(
            status:      const Value('synced'),
            processedAt: Value(DateTime.now()),
          ));

  Future<void> markFailed(int id, String error) async {
    final entry = await (select(syncQueue)
        ..where((q) => q.id.equals(id)))
        .getSingle();
    final newCount  = entry.retryCount + 1;
    final newStatus = newCount >= 3 ? 'failed' : 'pending';
    await (update(syncQueue)..where((q) => q.id.equals(id)))
        .write(SyncQueueCompanion(
          status:       Value(newStatus),
          retryCount:   Value(newCount),
          errorMessage: Value(error),
          processedAt:  Value(DateTime.now()),
        ));
  }

  Future<void> resetFailed() async =>
      (update(syncQueue)..where((q) => q.status.equals('failed')))
          .write(const SyncQueueCompanion(
            status:     Value('pending'),
            retryCount: Value(0),
          ));

  Future<void> clearSynced() async =>
      (delete(syncQueue)..where((q) => q.status.equals('synced'))).go();
}

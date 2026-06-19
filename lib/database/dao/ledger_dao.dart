// lib/database/dao/ledger_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/ledger_table.dart';

part 'ledger_dao.g.dart';

@DriftAccessor(tables: [LedgerEntries])
class LedgerDao extends DatabaseAccessor<AppDatabase>
    with _$LedgerDaoMixin {

  LedgerDao(super.db);

  Stream<List<LedgerEntry>> watchAll() =>
      (select(ledgerEntries)
        ..orderBy([(e) => OrderingTerm.desc(e.entryDate)]))
      .watch();

  Future<List<LedgerEntry>> getByDateRange({
    required DateTime from, required DateTime to,
  }) =>
      (select(ledgerEntries)
        ..where((e) =>
            e.entryDate.isBiggerOrEqualValue(from) &
            e.entryDate.isSmallerOrEqualValue(to))
        ..orderBy([(e) => OrderingTerm.asc(e.entryDate)]))
      .get();

  Future<void> insertEntry(LedgerEntriesCompanion e) async {
    await into(ledgerEntries).insert(e);
    final row = await (select(ledgerEntries)..where((tbl) => tbl.id.equals(e.id.value))).getSingleOrNull();
    if (row != null) {
      await db.syncQueueDao.enqueue(targetTable: 'ledger_entries', recordId: row.id, operation: 'INSERT', payload: row.toJson());
    }
  }

  Future<bool> updateEntry(LedgerEntriesCompanion e) async {
    final res = await update(ledgerEntries).replace(e);
    if (res) {
      final row = await (select(ledgerEntries)..where((tbl) => tbl.id.equals(e.id.value))).getSingleOrNull();
      if (row != null) {
        await db.syncQueueDao.enqueue(targetTable: 'ledger_entries', recordId: row.id, operation: 'UPDATE', payload: row.toJson());
      }
    }
    return res;
  }

  Future<int> deleteEntry(String id) async {
    await db.syncQueueDao.enqueue(targetTable: 'ledger_entries', recordId: id, operation: 'DELETE', payload: {});
    return (delete(ledgerEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<void> markSynced(String id) async =>
      (update(ledgerEntries)..where((e) => e.id.equals(id)))
          .write(LedgerEntriesCompanion(
            syncStatus: const Value('synced'),
            syncedAt:   Value(DateTime.now()),
          ));
}

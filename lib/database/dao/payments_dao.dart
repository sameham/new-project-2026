// lib/database/dao/payments_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/payments_table.dart';

part 'payments_dao.g.dart';

@DriftAccessor(tables: [Payments])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {

  PaymentsDao(super.db);

  Stream<List<Payment>> watchAll() =>
      (select(payments)
        ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
      .watch();

  Future<Payment?> getById(String id) =>
      (select(payments)..where((p) => p.id.equals(id)))
      .getSingleOrNull();

  Future<List<Payment>> getByCustomer(String customerId) =>
      (select(payments)
        ..where((p) => p.customerId.equals(customerId))
        ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
      .get();

  Stream<List<Payment>> watchByCustomer(String customerId) =>
      (select(payments)
        ..where((p) => p.customerId.equals(customerId))
        ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
      .watch();



  Future<List<Payment>> getByBooking(String bookingId) =>
      (select(payments)
        ..where((p) => p.bookingId.equals(bookingId)))
      .get();

  Stream<List<Payment>> watchByBooking(String bookingId) =>
      (select(payments)
        ..where((p) => p.bookingId.equals(bookingId))
        ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
      .watch();

  Stream<double> watchTotalIn() {
    final sum = payments.amount.sum();
    final q = selectOnly(payments)
      ..addColumns([sum])
      ..where(payments.direction.equals('in'));
    return q.watchSingle().map((row) => row.read(sum) ?? 0.0);
  }

  Future<List<Payment>> getByDateRange({
    required DateTime from, required DateTime to,
  }) =>
      (select(payments)
        ..where((p) =>
            p.paymentDate.isBiggerOrEqualValue(from) &
            p.paymentDate.isSmallerOrEqualValue(to))
        ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
      .get();

  Stream<List<Payment>> watchByDateRange({
    required DateTime from, required DateTime to,
  }) =>
      (select(payments)
        ..where((p) =>
            p.paymentDate.isBiggerOrEqualValue(from) &
            p.paymentDate.isSmallerOrEqualValue(to))
        ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
      .watch();

  Future<double> getTodayTotal() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final sum = payments.amount.sum();
    final q = selectOnly(payments)..addColumns([sum])
      ..where(payments.direction.equals('in') & payments.createdAt.isBiggerOrEqualValue(start));
    return (await q.getSingle()).read(sum) ?? 0.0;
  }

  Stream<double> watchTodayTotal() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final sum = payments.amount.sum();
    final q = selectOnly(payments)..addColumns([sum])
      ..where(payments.direction.equals('in') & payments.createdAt.isBiggerOrEqualValue(start));
    return q.watchSingle().map((row) => row.read(sum) ?? 0.0);
  }



  Stream<double> watchMonthTotal() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final sum = payments.amount.sum();
    final q = selectOnly(payments)..addColumns([sum])
      ..where(payments.direction.equals('in') & payments.createdAt.isBiggerOrEqualValue(start));
    return q.watchSingle().map((row) => row.read(sum) ?? 0.0);
  }

  Future<double> getMonthTotal({int? year, int? month}) async {
    final now  = DateTime.now();
    final y    = year  ?? now.year;
    final m    = month ?? now.month;
    final from = DateTime(y, m, 1);
    final to   = DateTime(y, m + 1, 0, 23, 59, 59);
    final sum  = payments.amount.sum();
    final query = selectOnly(payments)
      ..addColumns([sum])
      ..where(
        payments.paymentDate.isBiggerOrEqualValue(from) &
        payments.paymentDate.isSmallerOrEqualValue(to)  &
        payments.direction.equals('in'),
      );
    return (await query.getSingle()).read(sum) ?? 0.0;
  }

  Future<Map<String, double>> getTotalByMethod({
    DateTime? from, DateTime? to,
  }) async {
    final rows = from != null && to != null
        ? await getByDateRange(from: from, to: to)
        : await select(payments).get();
    final map = <String, double>{};
    for (final p in rows.where((p) => p.direction == 'in')) {
      map[p.paymentMethod] = (map[p.paymentMethod] ?? 0) + p.amount;
    }
    return map;
  }

  Future<void> insertPayment(PaymentsCompanion p) async {
    await into(payments).insert(p);
    final row = await (select(payments)..where((tbl) => tbl.id.equals(p.id.value))).getSingleOrNull();
    if (row != null) {
      await db.syncQueueDao.enqueue(targetTable: 'payments', recordId: row.id, operation: 'INSERT', payload: row.toJson());
    }
  }

  Future<bool> updatePayment(PaymentsCompanion p) async {
    final res = await update(payments).replace(p);
    if (res) {
      final row = await (select(payments)..where((tbl) => tbl.id.equals(p.id.value))).getSingleOrNull();
      if (row != null) {
        await db.syncQueueDao.enqueue(targetTable: 'payments', recordId: row.id, operation: 'UPDATE', payload: row.toJson());
      }
    }
    return res;
  }

  Future<int> deletePayment(String id) async {
    await db.syncQueueDao.enqueue(targetTable: 'payments', recordId: id, operation: 'DELETE', payload: {});
    return (delete(payments)..where((p) => p.id.equals(id))).go();
  }

  Future<void> markSynced(String id) async =>
      (update(payments)..where((p) => p.id.equals(id)))
          .write(PaymentsCompanion(
            syncStatus: const Value('synced'),
            syncedAt:   Value(DateTime.now()),
          ));
}

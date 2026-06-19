// lib/database/dao/customers_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/customers_table.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {

  CustomersDao(super.db);

  Stream<List<Customer>> watchAllCustomers() =>
      (select(customers)
        ..orderBy([(c) => OrderingTerm.asc(c.firstName)]))
      .watch();

  Future<Customer?> getCustomerById(String id) =>
      (select(customers)..where((c) => c.id.equals(id)))
      .getSingleOrNull();

  Stream<Customer?> watchCustomerById(String id) =>
      (select(customers)..where((c) => c.id.equals(id)))
      .watchSingleOrNull();

  Future<List<Customer>> searchCustomers(String query) =>
      (select(customers)
        ..where((c) =>
            c.firstName.contains(query) |
            c.lastName.contains(query)  |
            c.phone.contains(query)     |
            c.passportNumber.contains(query)))
      .get();

  Future<List<Customer>> getDebtors() =>
      (select(customers)
        ..where((c) => c.balance.isSmallerThanValue(0)))
      .get();

  Future<int> getCount() async {
    final count = customers.id.count();
    final q = selectOnly(customers)..addColumns([count]);
    return (await q.getSingle()).read(count) ?? 0;
  }

  Stream<int> watchCount() {
    final count = customers.id.count();
    final q = selectOnly(customers)..addColumns([count]);
    return q.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<void> insertCustomer(CustomersCompanion c) async {
    await into(customers).insert(c);
    final row = await (select(customers)..where((tbl) => tbl.id.equals(c.id.value))).getSingleOrNull();
    if (row != null) {
      await db.syncQueueDao.enqueue(targetTable: 'customers', recordId: row.id, operation: 'INSERT', payload: row.toJson());
    }
  }

  Future<bool> updateCustomer(CustomersCompanion c) async {
    final res = await update(customers).replace(c);
    if (res) {
      final row = await (select(customers)..where((tbl) => tbl.id.equals(c.id.value))).getSingleOrNull();
      if (row != null) {
        await db.syncQueueDao.enqueue(targetTable: 'customers', recordId: row.id, operation: 'UPDATE', payload: row.toJson());
      }
    }
    return res;
  }

  Future<void> updateBalance(String id, double balance) async {
    await (update(customers)..where((c) => c.id.equals(id))).write(CustomersCompanion(balance: Value(balance)));
    final row = await (select(customers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await db.syncQueueDao.enqueue(targetTable: 'customers', recordId: row.id, operation: 'UPDATE', payload: row.toJson());
    }
  }

  Future<int> deleteCustomer(String id) async {
    await db.syncQueueDao.enqueue(targetTable: 'customers', recordId: id, operation: 'DELETE', payload: {});
    return (delete(customers)..where((c) => c.id.equals(id))).go();
  }

  Future<void> markSynced(String id) async =>
      (update(customers)..where((c) => c.id.equals(id)))
          .write(CustomersCompanion(
            syncStatus: const Value('synced'),
            syncedAt:   Value(DateTime.now()),
          ));
}

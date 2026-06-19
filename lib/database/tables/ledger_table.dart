// lib/database/tables/ledger_table.dart

import 'package:drift/drift.dart';
import 'customers_table.dart';

class LedgerEntries extends Table {
  TextColumn    get id            => text()();
  TextColumn    get entryType     => text()();
  TextColumn    get referenceId   => text().nullable()();
  TextColumn    get referenceType => text().nullable()();
  TextColumn    get customerId    => text().nullable().references(Customers, #id)();
  RealColumn    get debit         => real().withDefault(const Constant(0.0))();
  RealColumn    get credit        => real().withDefault(const Constant(0.0))();
  RealColumn    get balance       => real().withDefault(const Constant(0.0))();
  TextColumn    get currency      => text().withDefault(const Constant('EGP'))();
  TextColumn    get description   => text()();
  TextColumn    get notes         => text().nullable()();
  DateTimeColumn get entryDate    => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt    => dateTime().withDefault(currentDateAndTime)();
  TextColumn    get syncStatus    => text().withDefault(const Constant('pending'))();
  DateTimeColumn get syncedAt     => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// lib/database/tables/expenses_table.dart

import 'package:drift/drift.dart';
import 'bookings_table.dart';

class ExpenseCategories extends Table {
  TextColumn    get id        => text()();
  TextColumn    get name      => text()();
  TextColumn    get nameAr    => text()();
  TextColumn    get icon      => text().nullable()();
  TextColumn    get color     => text().nullable()();
  BoolColumn    get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn    get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get syncedAt  => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn    get id            => text()();
  TextColumn    get categoryId    => text().references(ExpenseCategories, #id)();
  TextColumn    get bookingId     => text().nullable().references(Bookings, #id)();
  TextColumn    get expenseNumber => text()();
  TextColumn    get description   => text()();
  RealColumn    get amount        => real()();
  TextColumn    get currency      => text().withDefault(const Constant('EGP'))();
  DateTimeColumn get expenseDate  => dateTime()();
  TextColumn    get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn    get paidTo        => text().nullable()();
  TextColumn    get receiptNumber => text().nullable()();
  TextColumn    get notes         => text().nullable()();
  DateTimeColumn get createdAt    => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt    => dateTime().withDefault(currentDateAndTime)();
  TextColumn    get syncStatus    => text().withDefault(const Constant('pending'))();
  DateTimeColumn get syncedAt     => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

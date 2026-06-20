// lib/database/tables/customers_table.dart

import 'package:drift/drift.dart';

class Customers extends Table {
  TextColumn    get id             => text()();
  TextColumn    get customerCode   => text()();
  TextColumn    get firstName      => text()();
  TextColumn    get lastName       => text()();
  TextColumn    get firstNameEn    => text().nullable()();
  TextColumn    get lastNameEn     => text().nullable()();
  TextColumn    get phone          => text()();
  TextColumn    get phoneAlt       => text().nullable()();
  TextColumn    get email          => text().nullable()();
  TextColumn    get passportNumber => text().nullable()();
  DateTimeColumn get passportExpiry => dateTime().nullable()();
  TextColumn    get nationality    => text().nullable()();
  DateTimeColumn get dateOfBirth   => dateTime().nullable()();
  TextColumn    get gender         => text().nullable()();
  TextColumn    get address        => text().nullable()();
  TextColumn    get notes          => text().nullable()();
  RealColumn    get balance        => real().withDefault(const Constant(0.0))();
  TextColumn    get tags           => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt     => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt     => dateTime().withDefault(currentDateAndTime)();
  TextColumn    get syncStatus     => text().withDefault(const Constant('pending'))();
  DateTimeColumn get syncedAt      => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// lib/database/tables/payments_table.dart

import 'package:drift/drift.dart';
import 'customers_table.dart';
import 'bookings_table.dart';

class Payments extends Table {
  TextColumn    get id              => text()();
  TextColumn    get customerId      => text().references(Customers, #id)();
  TextColumn    get bookingId       => text().nullable().references(Bookings, #id)();
  TextColumn    get paymentNumber   => text()();
  RealColumn    get amount          => real()();
  TextColumn    get currency        => text().withDefault(const Constant('EGP'))();
  DateTimeColumn get paymentDate    => dateTime()();
  TextColumn    get paymentMethod   => text()();
  TextColumn    get referenceNumber => text().nullable()();
  TextColumn    get direction       => text().withDefault(const Constant('in'))();
  TextColumn    get notes           => text().nullable()();
  DateTimeColumn get createdAt      => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt      => dateTime().withDefault(currentDateAndTime)();
  TextColumn    get syncStatus      => text().withDefault(const Constant('pending'))();
  DateTimeColumn get syncedAt       => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

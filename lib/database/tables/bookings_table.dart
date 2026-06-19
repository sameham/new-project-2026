// lib/database/tables/bookings_table.dart

import 'package:drift/drift.dart';
import 'customers_table.dart';

class Bookings extends Table {
  TextColumn    get id            => text()();
  TextColumn    get customerId    => text().references(Customers, #id)();
  TextColumn    get bookingNumber => text()();
  TextColumn    get bookingType   => text()();
  TextColumn    get status        => text().withDefault(const Constant('pending'))();
  TextColumn    get origin        => text().nullable()();
  TextColumn    get destination   => text().nullable()();
  TextColumn    get airlineName   => text().nullable()();
  TextColumn    get flightNumber  => text().nullable()();
  TextColumn    get pnrNumber     => text().nullable()();
  TextColumn    get travelClass   => text().nullable()();
  DateTimeColumn get departureDate => dateTime().nullable()();
  DateTimeColumn get returnDate    => dateTime().nullable()();
  IntColumn     get adultsCount   => integer().withDefault(const Constant(1))();
  IntColumn     get childrenCount => integer().withDefault(const Constant(0))();
  IntColumn     get infantsCount  => integer().withDefault(const Constant(0))();
  RealColumn    get totalCost     => real().withDefault(const Constant(0.0))();
  RealColumn    get sellingPrice  => real().withDefault(const Constant(0.0))();
  RealColumn    get paidAmount    => real().withDefault(const Constant(0.0))();
  RealColumn    get taxAmount     => real().nullable()();
  TextColumn    get notes         => text().nullable()();
  DateTimeColumn get createdAt    => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt    => dateTime().withDefault(currentDateAndTime)();
  TextColumn    get syncStatus    => text().withDefault(const Constant('pending'))();
  DateTimeColumn get syncedAt     => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

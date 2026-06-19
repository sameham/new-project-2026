// lib/database/tables/sync_queue_table.dart

import 'package:drift/drift.dart';

class SyncQueue extends Table {
  IntColumn     get id          => integer().autoIncrement()();
  TextColumn    get targetTable   => text()();
  TextColumn    get recordId    => text()();
  TextColumn    get operation   => text()();
  TextColumn    get payload     => text()();
  TextColumn    get status      => text().withDefault(const Constant('pending'))();
  IntColumn     get retryCount  => integer().withDefault(const Constant(0))();
  TextColumn    get errorMessage => text().nullable()();
  DateTimeColumn get createdAt  => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
}

class Settings extends Table {
  TextColumn    get key       => text()();
  TextColumn    get value     => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

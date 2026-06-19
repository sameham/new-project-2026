// lib/database/dao/settings_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {

  SettingsDao(super.db);

  Future<Setting?> get(String key) =>
      (select(settings)..where((s) => s.key.equals(key)))
      .getSingleOrNull();

  Future<String?> getValue(String key) async {
    final row = await get(key);
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        key:       key,
        value:     value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSetting(String key) async =>
      (delete(settings)..where((s) => s.key.equals(key))).go();

  Stream<List<Setting>> watchAll() => select(settings).watch();
}

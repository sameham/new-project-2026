// lib/core/services/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/app_database.dart';

class SyncService {
  final AppDatabase db;
  final SupabaseClient supabase;
  Timer? _timer;
  bool _isSyncing = false;

  SyncService(this.db) : supabase = Supabase.instance.client;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _syncNow());
    // Trigger immediately on start
    _syncNow();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final autoSyncValue = await db.settingsDao.getValue('auto_sync');
      if (autoSyncValue != 'true') return;

      final pending = await db.syncQueueDao.getPending(limit: 50);
      if (pending.isEmpty) return;

      for (final item in pending) {
        try {
          final table = item.targetTable;
          final payload = jsonDecode(item.payload) as Map<String, dynamic>;

          if (item.operation == 'DELETE') {
            await supabase.from(table).delete().eq('id', item.recordId);
          } else {
            await supabase.from(table).upsert(payload);
          }

          await db.syncQueueDao.markSynced(item.id);
        } catch (e) {
          debugPrint('Sync Error for item ${item.id}: $e');
          await db.syncQueueDao.markFailed(item.id, e.toString());
        }
      }
    } catch (e) {
      debugPrint('Sync Worker Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> forceSync() async {
    await _syncNow();
  }
}

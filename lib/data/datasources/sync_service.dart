// ============================================================
// lib/data/datasources/sync_service.dart
// Đồng bộ dữ liệu giữa SQLite local và Supabase cloud
// ============================================================
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import 'sqlite_datasource.dart';
class SyncService {
  static const _tag = 'SyncService';

  final SqliteDataSource _db;
  final SupabaseClient   _supabase = Supabase.instance.client;

  Timer?  _syncTimer;
  Timer?  _cleanupTimer;
  bool    _isSyncing = false;

  SyncService(this._db);

  // ── Kiểm tra kết nối mạng ──
  Future<bool> _hasNetwork() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ── Bắt đầu sync định kỳ ──
  void start() {
   AppLogger.i('[$_tag] SyncService started');
    // Sync mỗi 30 giây
    _syncTimer = Timer.periodic(
      SupabaseConstants.syncInterval,
      (_) => _sync(),
    );

    // Cleanup mỗi 24 giờ
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => _cleanup(),
    );

    // Sync ngay lần đầu
    _sync();
  }

  // ── Main sync logic ──
  Future<void> _sync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final hasNet = await _hasNetwork();

      if (hasNet) {
        // Có mạng → upload records chưa sync
        await _uploadPending();
      } else {
        AppLogger.w('[$_tag] No network – skipping sync');
      }
    } catch (e) {
      AppLogger.e('[$_tag] Sync error', e);
    } finally {
      _isSyncing = false;
    }
  }

  // ── Upload records chưa sync lên Supabase ──
  Future<void> _uploadPending() async {
    try {
      // Lấy tất cả records chưa sync từ SQLite
      final pending = await _db.getUnsyncedRecords();

      if (pending.isEmpty) {
        AppLogger.d('[$_tag] No pending records to sync');
        return;
      }

      AppLogger.i('[$_tag] Uploading ${pending.length} records to Supabase...');

      // Upload vehicles trước
      final vins = pending.map((r) => r.vin).whereType<String>().toSet();
      for (final vin in vins) {
        await _upsertVehicle(vin);
      }

      // Upload obd_records theo batch
      final batch = pending.map((r) => {
        'vin':          r.vin,
        'rpm':          r.rpm,
        'speed':        r.speed,
        'coolant_temp': r.coolantTemp,
        'throttle_pos': r.throttlePos,
        'battery_volt': r.batteryVoltage,
        'timestamp':    r.timestamp.millisecondsSinceEpoch,
        'is_synced':    1,
      }).toList();

      await _supabase
          .from(SupabaseConstants.tableObd)
          .insert(batch);

      // Đánh dấu đã sync trong SQLite
      final ids = pending.map((r) => r.id).whereType<int>().toList();
      await _db.markAsSynced(ids);

      AppLogger.i('[$_tag] Synced ${pending.length} records ✓');
    } catch (e) {
      AppLogger.e('[$_tag] Upload failed', e);
      // Không throw – giữ nguyên is_synced=0 để retry sau
    }
  }

  // ── Upsert vehicle lên Supabase ──
  Future<void> _upsertVehicle(String vin) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _supabase
          .from(SupabaseConstants.tableVehicles)
          .upsert({
            'vin':        vin,
            'first_seen': now,
            'last_seen':  now,
          },
          onConflict: 'vin',
          ignoreDuplicates: false,
      );
    } catch (e) {
      AppLogger.w('[$_tag] Upsert vehicle failed: $e');
    }
  }

  // ── Cleanup records cũ đã sync ──
  Future<void> _cleanup() async {
    try {
      final cutoff = DateTime.now()
          .subtract(SupabaseConstants.cleanupInterval)
          .millisecondsSinceEpoch;

      final deleted = await _db.deleteSyncedOlderThan(cutoff);
      AppLogger.i('[$_tag] Cleanup: deleted $deleted old synced records');
    } catch (e) {
      AppLogger.e('[$_tag] Cleanup error', e);
    }
  }

  void stop() {
    _syncTimer?.cancel();
    _cleanupTimer?.cancel();
    AppLogger.i('[$_tag] SyncService stopped');
  }
  // ── Pull data từ Supabase về SQLite khi khởi động ──
Future<void> pullFromCloud(String vin) async {
  try {
    final hasNet = await _hasNetwork();
    if (!hasNet) {
      AppLogger.w('[$_tag] No network – skip pull');
      return;
    }

    AppLogger.i('[$_tag] Pulling data from Supabase for VIN: $vin');

    final records = await _supabase
        .from(SupabaseConstants.tableObd)
        .select()
        .eq('vin', vin)
        .order('timestamp', ascending: true);

    if (records.isEmpty) {
      AppLogger.i('[$_tag] No records found on cloud for VIN: $vin');
      return;
    }

    for (final r in records) {
      try {
        await _db.insertRaw(
          vin:            r['vin'] as String?,
          timestamp:      r['timestamp'] as int,
          rpm:            (r['rpm'] as num?)?.toDouble(),
          speed:          (r['speed'] as num?)?.toDouble(),
          coolantTemp:    (r['coolant_temp'] as num?)?.toDouble(),
          throttlePos:    (r['throttle_pos'] as num?)?.toDouble(),
          batteryVoltage: (r['battery_volt'] as num?)?.toDouble(),
          isSynced:       1,
        );
      } catch (_) {} // bỏ qua record trùng
    }

    AppLogger.i('[$_tag] Pulled ${records.length} records ✓');
  } catch (e) {
    AppLogger.e('[$_tag] Pull failed', e);
  }
}
  void dispose() => stop();
}
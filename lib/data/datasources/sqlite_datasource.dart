// ============================================================
// lib/data/datasources/sqlite_datasource.dart
// Datasource layer – tương tác trực tiếp với SQLite
// ============================================================

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/app_logger.dart';
import '../models/vehicle_data_model.dart';

/// Singleton quản lý mở / đóng / truy vấn SQLite
class SqliteDataSource {
  SqliteDataSource._();
  static final SqliteDataSource instance = SqliteDataSource._();

  Database? _db;

  // ── Initialize ────────────────────────────────────────────

  /// Gọi một lần duy nhất khi app khởi động
  Future<void> initialize() async {
    if (_db != null) return; // Đã mở rồi

    try {
      final dir  = await getDatabasesPath();
      final path = join(dir, AppConstants.dbName);
      AppLogger.i('SQLite path: $path');

      _db = await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      final version = await _db!.getVersion();
      AppLogger.i('SQLite current version: $version');
      try {
        await _db!.execute(
          'ALTER TABLE ${AppConstants.tableVehicles} ADD COLUMN name TEXT',
        );
        AppLogger.i('Added column name');
      } catch (_) {}
      try {
        await _db!.execute(
          'ALTER TABLE ${AppConstants.tableVehicles} ADD COLUMN plate TEXT',
        );
        AppLogger.i('Added column plate');
      } catch (_) {}
    } catch (e, st) {
      AppLogger.e('Cannot open SQLite', e, st);
      throw DatabaseException('Cannot open database', originalError: e);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.i('Creating database schema v$version');
    await db.execute(VehicleDataModel.createTableSql);
    await db.execute(VehicleDataModel.createIndexSql);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableVehicles} (
        vin        TEXT PRIMARY KEY,
        first_seen INTEGER NOT NULL,
        last_seen  INTEGER NOT NULL
      )
    ''');
  }
  Future<void> _onUpgrade(Database db, int old, int neo) async {
  AppLogger.w('DB upgrade: $old → $neo');
  if (old < 2) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableVehicles} (
        vin        TEXT PRIMARY KEY,
        first_seen INTEGER NOT NULL,
        last_seen  INTEGER NOT NULL,
        name       TEXT,
        plate      TEXT
      )
    ''');
    AppLogger.i('Migration v2: vehicles table created');
  }
  if (old < 3) {
    await db.execute(
      'ALTER TABLE ${AppConstants.tableVehicleData} ADD COLUMN is_synced INTEGER DEFAULT 0',
    );
    AppLogger.i('Migration v3: is_synced column added');
  }
  if (old < 4) {
  await db.execute(
    'ALTER TABLE ${AppConstants.tableVehicles} ADD COLUMN name TEXT',
  );
  await db.execute(
    'ALTER TABLE ${AppConstants.tableVehicles} ADD COLUMN plate TEXT',
  );
  AppLogger.i('Migration v4: name + plate columns added');    
  }
}
  Database get _database {
    if (_db == null) throw DatabaseException('Database not initialized');
    return _db!;
  }

  // ── CRUD ──────────────────────────────────────────────────

  /// Chèn bản ghi mới, trả về rowId
  Future<int> insert(VehicleDataModel model) async {
    try {
      return await _database.insert(
        AppConstants.tableVehicleData,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      AppLogger.e('Insert failed', e);
      throw DatabaseException('Insert failed', originalError: e);
    }
  }

  /// Query theo khoảng thời gian [fromMs, toMs] (epoch ms)
  Future<List<VehicleDataModel>> queryRange({
    required int fromMs,
    required int toMs,
    int? limit,
  }) async {
    try {
      final rows = await _database.query(
        AppConstants.tableVehicleData,
        where: 'timestamp BETWEEN ? AND ?',
        whereArgs: [fromMs, toMs],
        orderBy: 'timestamp ASC',
        limit: limit,
      );
      return rows.map(VehicleDataModel.fromMap).toList();
    } catch (e) {
      AppLogger.e('Query failed', e);
      throw DatabaseException('Query failed', originalError: e);
    }
  }

  /// Xóa bản ghi cũ hơn [beforeMs]
  Future<int> deleteOlderThan(int beforeMs) async {
    try {
      return await _database.delete(
        AppConstants.tableVehicleData,
        where: 'timestamp < ?',
        whereArgs: [beforeMs],
      );
    } catch (e) {
      AppLogger.e('Delete failed', e);
      throw DatabaseException('Delete failed', originalError: e);
    }
  }

  /// Đếm tổng số bản ghi
  Future<int> count() async {
    final res = await _database.rawQuery(
      'SELECT COUNT(*) FROM ${AppConstants.tableVehicleData}',
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }
 Future<void> upsertVehicle(String vin) async {
  final now = DateTime.now().millisecondsSinceEpoch;

  // Kiểm tra VIN đã tồn tại chưa
  final existing = await _database.query(
    AppConstants.tableVehicles,
    where: 'vin = ?',
    whereArgs: [vin],
    limit: 1,
  );

  if (existing.isEmpty) {
    // Chưa có → INSERT mới
    await _database.insert(
      AppConstants.tableVehicles,
      {'vin': vin, 'first_seen': now, 'last_seen': now},
    );
  } else {
    // Đã có → UPDATE last_seen
    await _database.update(
      AppConstants.tableVehicles,
      {'last_seen': now},
      where: 'vin = ?',
      whereArgs: [vin],
    );
  }
}

  Future<List<String>> getAllVins() async {
    final rows = await _database.query(
      AppConstants.tableVehicles,
      orderBy: 'last_seen DESC',
    );
    return rows.map((r) => r['vin'] as String).toList();
  }

  Future<List<VehicleDataModel>> queryByVin({
    required String vin,
    required int fromMs,
    required int toMs,
  }) async {
    final rows = await _database.query(
      AppConstants.tableVehicleData,
      where: 'vin = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [vin, fromMs, toMs],
      orderBy: 'timestamp ASC',
    );
    return rows.map(VehicleDataModel.fromMap).toList();
  }
  // Lấy records chưa sync
Future<List<VehicleDataModel>> getUnsyncedRecords() async {
  final rows = await _database.query(
    AppConstants.tableVehicleData,
    where: 'is_synced = 0',
    orderBy: 'timestamp ASC',
    limit: 500, // tối đa 500 records mỗi lần
  );
  return rows.map(VehicleDataModel.fromMap).toList();
}

// Đánh dấu đã sync
Future<void> markAsSynced(List<int> ids) async {
  if (ids.isEmpty) return;
  final placeholders = ids.map((_) => '?').join(',');
  await _database.rawUpdate(
    'UPDATE ${AppConstants.tableVehicleData} SET is_synced = 1 WHERE id IN ($placeholders)',
    ids,
  );
}

// Xóa records cũ đã sync
Future<int> deleteSyncedOlderThan(int timestampMs) async {
  return await _database.delete(
    AppConstants.tableVehicleData,
    where: 'is_synced = 1 AND timestamp < ?',
    whereArgs: [timestampMs],
  );
}
  Future<void> insertRaw({
  String? vin,
  required int timestamp,
  double? rpm,
  double? speed,
  double? coolantTemp,
  double? throttlePos,
  double? batteryVoltage,
  int isSynced = 1,
}) async {
  try {
    await _database.insert(
      AppConstants.tableVehicleData,
      {
        'timestamp':       timestamp,
        'vin':             vin,
        'rpm':             rpm,
        'speed':           speed,
        'coolant_temp':    coolantTemp,
        'throttle_pos':    throttlePos,
        'battery_voltage': batteryVoltage,
        'is_synced':       isSynced,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, 
    );
  } catch (e) {
    AppLogger.e('insertRaw failed', e);
  }
}
    Future<void> updateVehicleInfo(String vin, String name, String plate) async {
    AppLogger.d('updateVehicleInfo: vin=$vin name=$name plate=$plate');
    try {
      final result = await _database.update(
        AppConstants.tableVehicles,
        {'name': name, 'plate': plate},
        where: 'vin = ?',
        whereArgs: [vin],
      );
      AppLogger.d('updateVehicleInfo: updated $result rows');
    } catch (e) {
      AppLogger.e('updateVehicleInfo failed', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getVehicleInfo(String vin) async {
    final rows = await _database.query(
      AppConstants.tableVehicles,
      where: 'vin = ?',
      whereArgs: [vin],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

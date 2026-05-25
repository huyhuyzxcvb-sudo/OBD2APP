// ============================================================
// lib/data/models/vehicle_data_model.dart
// Model tầng Data – chịu trách nhiệm serialize/deserialize SQLite
// ============================================================

import '../../core/constants/app_constants.dart';
import '../../domain/entities/vehicle_data.dart';

/// Kế thừa Entity, bổ sung toMap / fromMap cho SQLite
class VehicleDataModel extends VehicleData {
   final int isSynced;
  const VehicleDataModel({
    super.id,
    required super.timestamp,
    super.vin,
    super.rpm,
    super.speed,
    super.coolantTemp,
    super.throttlePos,
    super.batteryVoltage,
    this.isSynced = 0,
  });

  /// Từ Domain Entity → Model
  factory VehicleDataModel.fromEntity(VehicleData e) => VehicleDataModel(
    id:             e.id,
    timestamp:      e.timestamp,
    vin:            e.vin, 
    rpm:            e.rpm,
    speed:          e.speed,
    coolantTemp:    e.coolantTemp,
    throttlePos:    e.throttlePos,
    batteryVoltage: e.batteryVoltage,
  );

  /// Từ SQLite Map → Model
  factory VehicleDataModel.fromMap(Map<String, dynamic> m) => VehicleDataModel(
    id:             m['id']               as int?,
    timestamp:      DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
    vin:             m['vin']              as String?,
    rpm:            (m['rpm']             as num?)?.toDouble(),
    speed:          (m['speed']           as num?)?.toDouble(),
    coolantTemp:    (m['coolant_temp']    as num?)?.toDouble(),
    throttlePos:    (m['throttle_pos']    as num?)?.toDouble(),
    batteryVoltage: (m['battery_voltage'] as num?)?.toDouble(),
    isSynced:       (m['is_synced']       as int?) ?? 0,
  );

  /// Model → SQLite Map
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'timestamp':       timestamp.millisecondsSinceEpoch,
    'vin':             vin, 
    'rpm':             rpm,
    'speed':           speed,
    'coolant_temp':    coolantTemp,
    'throttle_pos':    throttlePos,
    'battery_voltage': batteryVoltage,
    'is_synced':       isSynced
  };

  // ── DDL ──────────────────────────────────────────────────
  static String get createTableSql => '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableVehicleData} (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp        INTEGER NOT NULL,
      vin              TEXT,
      rpm              REAL,
      speed            REAL,
      coolant_temp     REAL,
      throttle_pos     REAL,
      battery_voltage  REAL,
      is_synced        INTEGER DEFAULT 0
    )
  ''';

  /// Index tăng tốc query theo timestamp
  static String get createIndexSql => '''
    CREATE INDEX IF NOT EXISTS idx_ts
    ON ${AppConstants.tableVehicleData}(timestamp)
  ''';
}

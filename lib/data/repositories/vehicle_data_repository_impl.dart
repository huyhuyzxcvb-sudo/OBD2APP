// ============================================================
// lib/data/repositories/vehicle_data_repository_impl.dart
// Implementation của VehicleDataRepository
// ============================================================

import '../../core/constants/app_constants.dart';
import '../../domain/entities/vehicle_data.dart';
import '../../domain/repositories/vehicle_data_repository.dart';
import '../datasources/sqlite_datasource.dart';
import '../models/vehicle_data_model.dart';

class VehicleDataRepositoryImpl implements VehicleDataRepository {
  final SqliteDataSource _db;
  VehicleDataRepositoryImpl(this._db);

  @override
  Future<void> save(VehicleData data) async {
    final model = VehicleDataModel.fromEntity(data);
    await _db.insert(model);
  }

  @override
  Future<List<VehicleData>> getByRange({
    required DateTime from,
    required DateTime to,
  }) => _db.queryRange(
    fromMs: from.millisecondsSinceEpoch,
    toMs:   to.millisecondsSinceEpoch,
  );

  @override
  Future<List<VehicleData>> getByPeriod(StatsPeriod period) {
    final now  = DateTime.now();
    final from = switch (period) {
      StatsPeriod.day  => now.subtract(const Duration(hours: 24)),
      StatsPeriod.week => now.subtract(const Duration(days: 7)),
    };
    return getByRange(from: from, to: now);
  }

  @override
  Future<void> deleteOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    await _db.deleteOlderThan(cutoff.millisecondsSinceEpoch);
  }

  @override
  Future<int> count() => _db.count();
}

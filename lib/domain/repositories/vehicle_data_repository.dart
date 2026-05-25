// ============================================================
// lib/domain/repositories/vehicle_data_repository.dart
// Abstract repository – tầng Domain (chỉ khai báo contract)
// ============================================================

import '../../core/constants/app_constants.dart';
import '../entities/vehicle_data.dart';

/// Contract cho repository lưu trữ / truy vấn dữ liệu xe
abstract class VehicleDataRepository {
  /// Lưu một snapshot dữ liệu xe vào database
  Future<void> save(VehicleData data);

  /// Lấy dữ liệu theo khoảng thời gian [from, to]
  Future<List<VehicleData>> getByRange({
    required DateTime from,
    required DateTime to,
  });

  /// Lấy dữ liệu theo filter ngắn gọn (1 ngày / 1 tuần)
  Future<List<VehicleData>> getByPeriod(StatsPeriod period);

  /// Xóa dữ liệu cũ hơn [days] ngày (dọn dẹp định kỳ)
  Future<void> deleteOlderThan(int days);

  /// Tổng số bản ghi trong database
  Future<int> count();
}

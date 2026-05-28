// ============================================================
// lib/presentation/providers/statistics_provider.dart
// Providers cho màn hình Statistics
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/vehicle_data.dart';
import 'obd_controller_provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
/// Filter đang chọn (day / week)
final statsPeriodProvider =
    StateProvider<StatsPeriod>((ref) => StatsPeriod.day);
/// VIN đang được chọn để xem thống kê
final selectedVinProvider = StateProvider<String?>((ref) => null);
/// Danh sách tất cả VIN đã từng kết nối (lấy từ SQLite)
final allVinsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final db = ref.read(sqliteProvider);
  return db.getAllVins();
});

/// Load dữ liệu thống kê từ SQLite theo period và VIN đang chọn
// Provider khi ĐANG kết nối - chỉ dùng RAM
final realtimeStatsProvider =
    StreamProvider<List<VehicleData>>((ref) {
  final controller = StreamController<List<VehicleData>>();
  final obdState = ref.read(obdProvider);
  controller.add(obdState.history);

  final timer = Timer.periodic(const Duration(seconds: 5), (_) {
    if (controller.isClosed) return;
    controller.add(ref.read(obdProvider).history);
  });

  ref.onDispose(() { timer.cancel(); controller.close(); });
  return controller.stream;
});

// Provider khi KHÔNG kết nối - chỉ dùng SQLite
final historyStatsProvider =
    FutureProvider.autoDispose<List<VehicleData>>((ref) async {
  final period      = ref.watch(statsPeriodProvider);
  final selectedVin = ref.watch(selectedVinProvider);
  final repo        = ref.read(vehicleRepoProvider);
  final db          = ref.read(sqliteProvider);
  final now         = DateTime.now();
  final from        = period == StatsPeriod.day
      ? now.subtract(const Duration(hours: 24))
      : now.subtract(const Duration(days: 7));
      debugPrint('Query from: $from');
      debugPrint('Query to: $now');
      debugPrint('Query fromMs: ${from.millisecondsSinceEpoch}');
      debugPrint('Query toMs: ${now.millisecondsSinceEpoch}');
    List<VehicleData> result;
  if (selectedVin == null) {
    result = await repo.getByPeriod(period);
  } else {
    result = await db.queryByVin(
      vin: selectedVin,
      fromMs: from.millisecondsSinceEpoch,
      toMs: now.millisecondsSinceEpoch,
    );
  }
  result.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // ── DEBUG ──────────────────────────────────────────────
  debugPrint('Total: ${result.length}');
  final byDay = <String, int>{};
  for (final d in result) {
    final key = '${d.timestamp.day}/${d.timestamp.month}';
    byDay[key] = (byDay[key] ?? 0) + 1;
  }
  debugPrint('By day: $byDay');
  debugPrint('RPM null: ${result.where((d) => d.rpm == null).length}/${result.length}');
  if (result.isNotEmpty) {
    debugPrint('First: ${result.first.timestamp}');
    debugPrint('Last:  ${result.last.timestamp}');
  }
  // ── END DEBUG ──────────────────────────────────────────
  return result;
});
/// Tổng số bản ghi trong DB
final dbCountProvider = FutureProvider.autoDispose<int>((ref) {
  final repo = ref.read(vehicleRepoProvider);
  return repo.count();
});

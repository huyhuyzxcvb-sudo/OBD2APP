// ============================================================
// lib/presentation/providers/engine_warning_provider.dart
// Riverpod provider — cầu nối giữa service và UI
// ============================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/engine_warning_service.dart';
import '../../domain/entities/engine_warning.dart';
import 'obd_controller_provider.dart';

/// Provider chính — lắng nghe stream dữ liệu OBD và phân tích
final engineWarningProvider =
    StreamProvider.autoDispose<EngineWarning>((ref) {
  final service    = EngineWarningService.instance;
  final controller = StreamController<EngineWarning>();

  // Reset service khi provider được tạo mới
  service.reset();

  // Lắng nghe obdProvider mỗi 500ms
  final timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
    final obdState = ref.read(obdProvider);

    // Không kết nối → reset và trả về normal
    if (!obdState.isConnected || obdState.current == null) {
      service.reset();
      if (!controller.isClosed) {
        controller.add(EngineWarning.normal);
      }
      return;
    }

    // Phân tích điểm dữ liệu mới nhất
    final warning = service.analyze(obdState.current!);
    if (!controller.isClosed) {
      controller.add(warning);
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
    service.reset();
  });

  return controller.stream;
});

/// Provider tiện ích — chỉ trả về level hiện tại
final engineWarningLevelProvider =
    Provider.autoDispose<EngineWarningLevel>((ref) {
  return ref.watch(engineWarningProvider).whenOrNull(
        data: (w) => w.level,
      ) ??
      EngineWarningLevel.normal;
});
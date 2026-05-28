// ============================================================
// lib/domain/entities/engine_warning.dart
// Model định nghĩa trạng thái cảnh báo động cơ
// ============================================================

/// Mức độ cảnh báo — 3 mức từ bình thường đến nguy hiểm
enum EngineWarningLevel {
  normal,   // Hoạt động bình thường
  warning,  // Cần chú ý
  critical, // Nguy hiểm — cần xử lý ngay
}

/// Kết quả phân tích trạng thái động cơ
class EngineWarning {
  final EngineWarningLevel level;
  final String message;
  final String description;
  final double severity; // 0.0 → 1.0

  const EngineWarning({
    required this.level,
    required this.message,
    required this.description,
    required this.severity,
  });

  /// Trạng thái bình thường — dùng như singleton
  static const normal = EngineWarning(
    level:       EngineWarningLevel.normal,
    message:     'Động cơ hoạt động bình thường',
    description: '',
    severity:    0.0,
  );

  /// Màu sắc tương ứng với mức độ — dùng trong UI
  static const Map<EngineWarningLevel, int> levelColors = {
    EngineWarningLevel.normal:   0xFF00E5FF, // Cyan
    EngineWarningLevel.warning:  0xFFFFAB40, // Cam
    EngineWarningLevel.critical: 0xFFFF1744, // Đỏ
  };

  bool get isNormal   => level == EngineWarningLevel.normal;
  bool get isWarning  => level == EngineWarningLevel.warning;
  bool get isCritical => level == EngineWarningLevel.critical;
}

/// Cấu hình ngưỡng cảnh báo — tập trung ở đây để dễ chỉnh
/// Không hardcode trong logic hay UI
class EngineWarningThresholds {
  // ── Ngưỡng HIGH LOAD ───────────────────────────────────────
  static const double tpsHighLoad      = 15.0;  // %
  static const double rpmHighLoad      = 2000.0; // r/min
  static const double speedHighLoad    = 90.0;  // km/h

  // ── Ngưỡng NHIỆT ĐỘ ────────────────────────────────────────
  static const double coolantWarning   = 85.0;  // °C
  static const double coolantCritical  = 90.0; // °C
  static const double coolantRiseRate  = 0.3;   // °C/phân tích (tăng liên tục)

  // ── Debounce & Buffer ───────────────────────────────────────
  static const int    bufferSize       = 8;     // số điểm dữ liệu giữ trong buffer
  static const int    debounceSeconds  = 3;     // giây trước khi đổi trạng thái
  static const int    coolantSamples   = 5;     // số mẫu để tính xu hướng nhiệt độ
}
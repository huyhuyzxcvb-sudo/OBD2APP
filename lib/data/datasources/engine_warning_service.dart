// ============================================================
// lib/data/datasources/engine_warning_service.dart
// Service phân tích thông số và phát hiện tải bất thường
// ============================================================

import 'dart:collection';
import '../../domain/entities/engine_warning.dart';
import '../../domain/entities/vehicle_data.dart';

class EngineWarningService {
  EngineWarningService._();
  static final EngineWarningService instance = EngineWarningService._();

  // ── Buffer dữ liệu ngắn ────────────────────────────────────
  // Giữ N điểm gần nhất để tính moving average và xu hướng
  final Queue<VehicleData> _buffer = Queue();

  // ── Debounce ───────────────────────────────────────────────
  // Tránh cảnh báo nhấp nháy — chỉ đổi trạng thái sau N giây
  EngineWarning _lastWarning    = EngineWarning.normal;
  DateTime?     _lastChangeTime;
  EngineWarning _pendingWarning = EngineWarning.normal;

  // ── Public API ─────────────────────────────────────────────

  /// Thêm điểm dữ liệu mới và trả về cảnh báo hiện tại
  EngineWarning analyze(VehicleData data) {
    _addToBuffer(data);
    final raw = _evaluateRules();
    return _applyDebounce(raw);
  }

  /// Reset toàn bộ buffer và trạng thái
  void reset() {
    _buffer.clear();
    _lastWarning    = EngineWarning.normal;
    _lastChangeTime = null;
    _pendingWarning = EngineWarning.normal;
  }

  // ── Buffer management ──────────────────────────────────────

  void _addToBuffer(VehicleData data) {
    _buffer.addLast(data);
    // Giữ buffer không quá N điểm
    while (_buffer.length > EngineWarningThresholds.bufferSize) {
      _buffer.removeFirst();
    }
  }

  // ── Moving Average ─────────────────────────────────────────
  // Làm mượt nhiễu bằng cách lấy trung bình N điểm gần nhất

  double? _movingAvg(double? Function(VehicleData) getter) {
    final vals = _buffer
        .map(getter)
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  // ── Xu hướng nhiệt độ ─────────────────────────────────────
  // Trả về true nếu nhiệt độ đang tăng liên tục
  // Dùng linear regression đơn giản trên N mẫu gần nhất

  bool _isCoolantRising() {
    final n = EngineWarningThresholds.coolantSamples;
    final samples = _buffer
        .toList()
        .reversed
        .take(n)
        .map((d) => d.coolantTemp)
        .whereType<double>()
        .toList()
        .reversed
        .toList();

    if (samples.length < 3) return false;

    // Tính slope (độ dốc) bằng least squares đơn giản
    int count = samples.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < count; i++) {
      sumX  += i;
      sumY  += samples[i];
      sumXY += i * samples[i];
      sumX2 += i * i.toDouble();
    }
    final slope = (count * sumXY - sumX * sumY) /
                  (count * sumX2 - sumX * sumX);

    // Slope dương và vượt ngưỡng → nhiệt độ đang tăng
    return slope >= EngineWarningThresholds.coolantRiseRate;
  }

  // ── Rule Engine ────────────────────────────────────────────
  // Tất cả rule tập trung ở đây — dễ thêm rule mới

  EngineWarning _evaluateRules() {
    if (_buffer.isEmpty) return EngineWarning.normal;

    // Dùng moving average để tránh nhiễu nhất thời
    final avgTps     = _movingAvg((d) => d.throttlePos);
    final avgRpm     = _movingAvg((d) => d.rpm);
    final avgSpeed   = _movingAvg((d) => d.speed);
    final avgCoolant = _movingAvg((d) => d.coolantTemp);

    if (avgTps == null || avgRpm == null ||
        avgSpeed == null || avgCoolant == null) {
      return EngineWarning.normal;
    }

    // ── Rule 1: Nhiệt độ CRITICAL ──────────────────────────
    if (avgCoolant >= EngineWarningThresholds.coolantCritical) {
      return EngineWarning(
        level:       EngineWarningLevel.critical,
        message:     'NGUY HIỂM: Động cơ quá nhiệt',
        description: 'Nhiệt độ nước làm mát ${avgCoolant.toStringAsFixed(0)}°C '
                     'vượt ngưỡng nguy hiểm ${EngineWarningThresholds.coolantCritical.toStringAsFixed(0)}°C. '
                     'Dừng xe ngay và kiểm tra hệ thống làm mát.',
        severity:    1.0,
      );
    }

    // ── Rule 2: HIGH LOAD + NHIỆT ĐỘ TĂNG → CRITICAL ──────
    final isHighLoad = avgTps   >= EngineWarningThresholds.tpsHighLoad   &&
                       avgRpm   >= EngineWarningThresholds.rpmHighLoad   &&
                       avgSpeed <= EngineWarningThresholds.speedHighLoad;

    if (isHighLoad && _isCoolantRising()) {
      return EngineWarning(
        level:       EngineWarningLevel.critical,
        message:     'CẢNH BÁO NGHIÊM TRỌNG: Tải cao + Nhiệt độ tăng',
        description: 'Động cơ đang chịu tải cao (TPS ${avgTps.toStringAsFixed(0)}%, '
                     'RPM ${avgRpm.toStringAsFixed(0)}) trong khi tốc độ thấp '
                     '(${avgSpeed.toStringAsFixed(0)} km/h) và nhiệt độ đang tăng liên tục. '
                     'Giảm tốc và kiểm tra xe.',
        severity:    0.9,
      );
    }

    // ── Rule 3: HIGH LOAD đơn thuần → WARNING ──────────────
    if (isHighLoad) {
      return EngineWarning(
        level:       EngineWarningLevel.warning,
        message:     'CẢNH BÁO: Động cơ đang chịu tải cao',
        description: 'TPS ${avgTps.toStringAsFixed(0)}%, '
                     'RPM ${avgRpm.toStringAsFixed(0)} r/min, '
                     'tốc độ chỉ ${avgSpeed.toStringAsFixed(0)} km/h. '
                     'Động cơ đang hoạt động nặng tải ở tốc độ thấp.',
        severity:    0.6,
      );
    }

    // ── Rule 4: Nhiệt độ WARNING ───────────────────────────
    if (avgCoolant >= EngineWarningThresholds.coolantWarning) {
      return EngineWarning(
        level:       EngineWarningLevel.warning,
        message:     'CHÚ Ý: Nhiệt độ nước làm mát cao',
        description: 'Nhiệt độ nước làm mát ${avgCoolant.toStringAsFixed(0)}°C '
                     'đang tiệm cận ngưỡng nguy hiểm. Theo dõi chặt chẽ.',
        severity:    0.5,
      );
    }

    // Không có rule nào khớp → bình thường
    return EngineWarning.normal;
  }

  // ── Debounce ───────────────────────────────────────────────
  // Chỉ đổi trạng thái sau khi cảnh báo mới duy trì đủ N giây
  // Tránh widget nhấp nháy khi dữ liệu dao động quanh ngưỡng

  EngineWarning _applyDebounce(EngineWarning raw) {
    final now = DateTime.now();

    // Nếu cảnh báo mới khác với đang chờ → reset timer
    if (raw.level != _pendingWarning.level) {
      _pendingWarning = raw;
      _lastChangeTime = now;
    }

    // Chưa đủ thời gian debounce → giữ nguyên cảnh báo cũ
    if (_lastChangeTime != null) {
      final elapsed = now.difference(_lastChangeTime!).inSeconds;
      if (elapsed < EngineWarningThresholds.debounceSeconds) {
        return _lastWarning;
      }
    }

    // Đủ thời gian → cập nhật cảnh báo
    _lastWarning = _pendingWarning;
    return _lastWarning;
  }
}
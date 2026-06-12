// ============================================================
// lib/domain/entities/warning_rule.dart
// ============================================================
 
import '../../domain/entities/vehicle_data.dart';
 
enum WarningSeverity { normal, warning, critical }
 
class WarningResult {
  final WarningSeverity severity;
  final String          title;
  final String          message;
  final String          ruleId;
  final DateTime        timestamp;
 
  const WarningResult({
    required this.severity,
    required this.title,
    required this.message,
    required this.ruleId,
    required this.timestamp,
  });
 
  bool get isNormal   => severity == WarningSeverity.normal;
  bool get isWarning  => severity == WarningSeverity.warning;
  bool get isCritical => severity == WarningSeverity.critical;
 
  static final normal = WarningResult(
    severity:  WarningSeverity.normal,
    title:     '',
    message:   '',
    ruleId:    'none',
    timestamp: DateTime(0),
  );
}
 
abstract class WarningRule {
  String get id;
  String get displayName;
  WarningResult? evaluate(List<VehicleData> buffer);
}
 
class OverheatRule extends WarningRule {
  @override String get id          => 'overheat';
  @override String get displayName => 'Quá nhiệt động cơ';
 
  static const double _warnTemp     = 95.0;
  static const double _criticalTemp = 105.0;
 
  @override
  WarningResult? evaluate(List<VehicleData> buffer) {
    if (buffer.isEmpty) return null;
    final avg = _avg(buffer, (d) => d.coolantTemp);
    if (avg == null) return null;
 
    if (avg >= _criticalTemp) {
      return WarningResult(
        severity:  WarningSeverity.critical,
        title:     'Động cơ quá nhiệt',
        message:   'Nhiệt độ nước làm mát ${avg.toStringAsFixed(0)}°C vượt ngưỡng nguy hiểm. Dừng xe ngay!',
        ruleId:    id,
        timestamp: DateTime.now(),
      );
    }
    if (avg >= _warnTemp) {
      return WarningResult(
        severity:  WarningSeverity.warning,
        title:     'Nhiệt độ nước làm mát cao',
        message:   'Nhiệt độ ${avg.toStringAsFixed(0)}°C đang tiệm cận ngưỡng nguy hiểm.',
        ruleId:    id,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }
}
 
class HighEngineLoadRule extends WarningRule {
  @override String get id          => 'high_load';
  @override String get displayName => 'Tải động cơ cao';
 
  static const double _tpsThreshold   = 70.0;
  static const double _rpmThreshold   = 3500.0;
  static const double _speedThreshold = 40.0;
 
  @override
  WarningResult? evaluate(List<VehicleData> buffer) {
    if (buffer.isEmpty) return null;
    final avgTps   = _avg(buffer, (d) => d.throttlePos);
    final avgRpm   = _avg(buffer, (d) => d.rpm);
    final avgSpeed = _avg(buffer, (d) => d.speed);
    if (avgTps == null || avgRpm == null || avgSpeed == null) return null;
 
    if (avgTps   >= _tpsThreshold   &&
        avgRpm   >= _rpmThreshold   &&
        avgSpeed <= _speedThreshold) {
      return WarningResult(
        severity:  WarningSeverity.warning,
        title:     'Động cơ chịu tải cao',
        message:   'TPS ${avgTps.toStringAsFixed(0)}%, RPM ${avgRpm.toStringAsFixed(0)}, Tốc độ ${avgSpeed.toStringAsFixed(0)} km/h.',
        ruleId:    id,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }
}
 
class LowBatteryRule extends WarningRule {
  @override String get id          => 'low_battery';
  @override String get displayName => 'Dien ap ac quy thap';
 
  static const double _warnVolt = 12.0;
  static const double _critVolt = 11.5;
 
  @override
  WarningResult? evaluate(List<VehicleData> buffer) {
    if (buffer.isEmpty) return null;
    final avg = _avg(buffer, (d) => d.batteryVoltage);
    if (avg == null) return null;
 
    if (avg <= _critVolt) {
      return WarningResult(
        severity:  WarningSeverity.critical,
        title:     'Điện áp ắc quy thấp',
        message:   'Điện áp ${avg.toStringAsFixed(1)}V rất thấp. Ắc quy có thể hỏng.',
        ruleId:    id,
        timestamp: DateTime.now(),
      );
    }
    if (avg <= _warnVolt) {
      return WarningResult(
        severity:  WarningSeverity.warning,
        title:     'Điện áp ắc quy thấp',
        message:   'Điện áp ${avg.toStringAsFixed(1)}V thấp hơn bình thường.',
        ruleId:    id,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }
}
 
double? _avg(List<VehicleData> buffer, double? Function(VehicleData) getter) {
  final vals = buffer.map(getter).whereType<double>().toList();
  if (vals.isEmpty) return null;
  return vals.reduce((a, b) => a + b) / vals.length;
}
// ============================================================
// lib/domain/entities/vehicle_data.dart
// Entity thuần túy tầng Domain – không phụ thuộc framework
// ============================================================

/// Dữ liệu xe tại một thời điểm (snapshot)
class VehicleData {
  final int?      id;
  final DateTime  timestamp;
  ///Mã VIN
  final String?   vin;

  /// Vòng tua động cơ – RPM (r/min)
  final double? rpm;

  /// Tốc độ xe – Speed (km/h)
  final double? speed;

  /// Nhiệt độ nước làm mát – Coolant (°C)
  final double? coolantTemp;

  /// Vị trí bướm ga – Throttle (%)
  final double? throttlePos;

  /// Điện áp ắc quy – Battery (V)
  final double? batteryVoltage;

  const VehicleData({
    this.id,
    required this.timestamp,
    this.vin, 
    this.rpm,
    this.speed,
    this.coolantTemp,
    this.throttlePos,
    this.batteryVoltage,
  });

  /// Tạo bản sao với một số field thay đổi
  VehicleData copyWith({
    int?      id,
    DateTime? timestamp,
    String?   vin,
    double?   rpm,
    double?   speed,
    double?   coolantTemp,
    double?   throttlePos,
    double?   batteryVoltage,
  }) => VehicleData(
    id:             id            ?? this.id,
    timestamp:      timestamp     ?? this.timestamp,
    vin:            vin           ?? this.vin,
    rpm:            rpm           ?? this.rpm,
    speed:          speed         ?? this.speed,
    coolantTemp:    coolantTemp   ?? this.coolantTemp,
    throttlePos:    throttlePos   ?? this.throttlePos,
    batteryVoltage: batteryVoltage ?? this.batteryVoltage,
  );

  /// Entity rỗng (chưa có dữ liệu) – dùng khi chưa kết nối
  factory VehicleData.empty() => VehicleData(timestamp: DateTime.now());

  @override
  String toString() => 'VehicleData('
      'rpm=${rpm?.toStringAsFixed(0)}, '
      'speed=${speed?.toStringAsFixed(0)}km/h, '
      'temp=${coolantTemp?.toStringAsFixed(1)}°C, '
      'battery=${batteryVoltage?.toStringAsFixed(2)}V'
      ')';
}

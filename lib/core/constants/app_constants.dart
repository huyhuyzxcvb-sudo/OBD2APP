// ============================================================
// lib/core/constants/app_constants.dart
// Hằng số toàn cục – tập trung một chỗ để dễ thay đổi
// ============================================================

class AppConstants {
  AppConstants._(); // Không cho phép khởi tạo

  // ── App Info ─────────────────────────────────────────────
  static const String appName    = 'OBD2 Diagnostics';
  static const String appVersion = '1.0.0';

  // ── Bluetooth ────────────────────────────────────────────
  /// UUID chuẩn SPP (Serial Port Profile) – bắt buộc cho BT Classic
  static const String sppUuid = '00001101-0000-1000-8000-00805F9B34FB';

  /// Timeout kết nối Bluetooth (giây)
  static const int btConnectTimeoutSec = 10;

  /// Số giây chờ giữa các lần reconnect (base, sẽ nhân đôi mỗi lần)
  static const int reconnectBaseDelaySec = 5;

  /// Số lần thử reconnect tối đa trước khi từ bỏ
  static const int maxReconnectAttempts = 5;

  // ── ELM327 AT Commands ───────────────────────────────────
  /// Reset chip ELM327 về mặc định
  static const String cmdReset        = 'ATZ';
  /// Tắt echo: ELM327 sẽ không gửi lại lệnh đã nhận
  static const String cmdEchoOff      = 'ATE0';
  /// Tắt linefeed trong response
  static const String cmdLinefeedOff  = 'ATL0';
  /// Tắt header OBD (chỉ nhận data bytes)
  static const String cmdHeaderOff    = 'ATH0';
  /// Tắt khoảng trắng giữa các byte (dễ parse hơn)
  static const String cmdSpacesOff    = 'ATS0';
  /// Tự động phát hiện protocol OBD của xe
  static const String cmdAutoProtocol = 'ATSP0';
  ///Đọc VIN
  static const String pidVin = '0902';

  // ── OBD-II PIDs ──────────────────────────────────────────
  /// Vòng tua động cơ (RPM)
  static const String pidRpm          = '010C';
  /// Tốc độ xe (km/h)
  static const String pidSpeed        = '010D';
  /// Nhiệt độ nước làm mát (°C)
  static const String pidCoolantTemp  = '0105';
  /// Vị trí bướm ga (%)
  static const String pidThrottle     = '0111';
  /// Điện áp ắc quy – AT command, không phải mode 01 PID
  static const String pidBattery      = 'ATRV';

  // ── Timing ───────────────────────────────────────────────
  /// Chu kỳ polling gửi PID (ms) – 500ms = ~2 vòng/giây
  static const int pollingIntervalMs  = 500;
  /// Timeout cho mỗi lệnh OBD (ms) – nếu quá sẽ skip
  static const int cmdTimeoutMs       = 2000;
  /// Chu kỳ lưu dữ liệu vào SQLite (ms)
  static const int dbSaveIntervalMs   = 5000;

  // ── Realtime Chart ───────────────────────────────────────
  /// Số điểm tối đa trên biểu đồ realtime
  static const int realtimeMaxPoints  = 60;

  // ── SQLite ───────────────────────────────────────────────
  static const String dbName              = 'obd2_data.db';
  static const int    dbVersion           = 4;
  static const String tableVehicleData    = 'vehicle_data';
  static const String tableVehicles = 'vehicles';
}

// ── Enums ────────────────────────────────────────────────────

/// Trạng thái kết nối Bluetooth / ELM327
enum ConnectionStatus {
  disconnected,   // Chưa kết nối
  scanning,       // Đang quét thiết bị
  connecting,     // Đang thiết lập kết nối BT
  initializing,   // Đang gửi AT commands khởi tạo
  connected,      // Đã kết nối và sẵn sàng đọc dữ liệu
  reconnecting,   // Đang thử kết nối lại
  error,          // Lỗi không phục hồi được
}

/// Khoảng thời gian filter thống kê
enum StatsPeriod { day, week }
class SupabaseConstants {
  SupabaseConstants._();
  static const String url     = 'https://klmxzzfixhfdnyymnqdd.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtsbXh6emZpeGhmZG55eW1ucWRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4MTIxNjYsImV4cCI6MjA5NDM4ODE2Nn0.MiWFCONohTnkUbwwsg3smUzCZkNZfZSDLWXGmiiyxVA';
  static const String tableVehicles = 'vehicles';
  static const String tableObd      = 'obd_records';
  static const Duration syncInterval    = Duration(seconds: 30);
  static const Duration cleanupInterval = Duration(days: 7);
}
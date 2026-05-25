// ============================================================
// lib/core/errors/exceptions.dart
// Custom exceptions cho toàn bộ ứng dụng
// ============================================================

/// Lỗi liên quan đến Bluetooth (kết nối, gửi/nhận)
class BluetoothException implements Exception {
  final String message;
  final String? code;
  const BluetoothException(this.message, {this.code});

  @override
  String toString() => 'BluetoothException[$code]: $message';
}

/// Lỗi khi kết nối thất bại
class ConnectionException extends BluetoothException {
  const ConnectionException(super.message, {super.code});
}

/// Lỗi timeout khi gửi lệnh OBD và không nhận được phản hồi
class CommandTimeoutException implements Exception {
  final String command;
  final int timeoutMs;
  const CommandTimeoutException(this.command, this.timeoutMs);

  @override
  String toString() =>
      'CommandTimeoutException: "$command" timed out after ${timeoutMs}ms';
}

/// Lỗi khi parse response HEX từ ELM327 thất bại
class ParseException implements Exception {
  final String raw;
  final String reason;
  const ParseException(this.raw, this.reason);

  @override
  String toString() => 'ParseException: raw="$raw", reason=$reason';
}

/// Lỗi liên quan đến SQLite
class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;
  const DatabaseException(this.message, {this.originalError});

  @override
  String toString() => 'DatabaseException: $message';
}

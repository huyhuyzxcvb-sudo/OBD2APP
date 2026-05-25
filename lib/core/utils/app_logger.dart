// ============================================================
// lib/core/utils/app_logger.dart
// Logger tập trung – in ra có màu, có tag
// ============================================================

import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 6,
      lineLength: 100,
      colors: true,
      printEmojis: true,
    ),
    level: Level.debug,
  );

  static void d(String msg, [dynamic err]) => _log.d(msg, error: err);
  static void i(String msg, [dynamic err]) => _log.i(msg, error: err);
  static void w(String msg, [dynamic err]) => _log.w(msg, error: err);
  static void e(String msg, [dynamic err, StackTrace? st]) =>
      _log.e(msg, error: err, stackTrace: st);
}

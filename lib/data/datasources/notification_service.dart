// ============================================================
// lib/data/datasources/notification_service.dart
// ============================================================
 
import 'package:vibration/vibration.dart';
import '../../domain/entities/warning_rule.dart';
 
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
 
  Future<void> initialize() async {}
 
  Future<void> showWarning(WarningResult warning) async {
    if (warning.isNormal) return;
    if (warning.isCritical) await _vibrate();
  }
 
  Future<void> cancelWarning(String ruleId) async {}
 
  Future<void> cancelAll() async {}
 
  Future<void> _vibrate() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;
    await Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
  }
}
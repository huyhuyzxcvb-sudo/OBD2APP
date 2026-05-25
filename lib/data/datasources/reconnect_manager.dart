// ============================================================
// lib/data/datasources/reconnect_manager.dart
// Tự động reconnect với exponential backoff khi mất kết nối
// ============================================================

import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';

/// Callback thực hiện kết nối – trả về true nếu thành công
typedef ReconnectFn = Future<bool> Function();

/// Quản lý logic reconnect tự động
/// Backoff: 5s → 10s → 20s → 40s → 80s (tối đa 5 lần)
class ReconnectManager {
  final ReconnectFn _reconnect;

  int    _attempts  = 0;
  bool   _active    = false;
  Timer? _timer;

  bool get isActive  => _active;
  int  get attempts  => _attempts;

  ReconnectManager(this._reconnect);

  /// Bắt đầu quá trình reconnect
  void start() {
    if (_active) return;
    _active   = true;
    _attempts = 0;
    AppLogger.i('ReconnectManager started');
    _schedule();
  }

  void _schedule() {
    if (!_active) return;

    if (_attempts >= AppConstants.maxReconnectAttempts) {
      AppLogger.w('Max reconnect attempts reached, giving up');
      stop();
      return;
    }

    // Exponential backoff: base * 2^attempt (capped at 80s)
    final delaySec = AppConstants.reconnectBaseDelaySec *
        (1 << _attempts.clamp(0, 4));
    AppLogger.i(
        'Reconnect #${_attempts + 1}/${AppConstants.maxReconnectAttempts} '
        'in ${delaySec}s...');

    _timer = Timer(Duration(seconds: delaySec), _attempt);
  }

  Future<void> _attempt() async {
    if (!_active) return;
    _attempts++;

    try {
      final ok = await _reconnect();
      if (ok) {
        AppLogger.i('Reconnect successful after $_attempts attempt(s)');
        stop();
      } else {
        AppLogger.w('Reconnect #$_attempts failed, scheduling next...');
        _schedule();
      }
    } catch (e) {
      AppLogger.e('Reconnect #$_attempts threw error', e);
      _schedule();
    }
  }

  /// Dừng reconnect (gọi khi kết nối thành công hoặc user disconnect)
  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    AppLogger.i('ReconnectManager stopped');
  }

  void dispose() => stop();
}

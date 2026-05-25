// ============================================================
// lib/data/datasources/elm327_service.dart
// ELM327 Service – command queue, init sequence, polling loop
// ============================================================

import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/vehicle_data.dart';
import 'bluetooth_service.dart';
import 'obd_pid_parser.dart';

// ── Internal Pending Command ──────────────────────────────────

/// Một lệnh đang chờ trong queue
class _Cmd {
  final String           cmd;
  final Completer<String> completer;
  final DateTime         sentAt;

  _Cmd(this.cmd)
      : completer = Completer<String>(),
        sentAt    = DateTime.now();

  bool get timedOut =>
      DateTime.now().difference(sentAt).inMilliseconds >
      AppConstants.cmdTimeoutMs;
}

// ── ELM327 Service ────────────────────────────────────────────

/// Điều phối toàn bộ giao tiếp với chip ELM327:
/// - Gửi AT commands khởi tạo
/// - Vòng lặp polling PID
/// - Command queue tránh đụng nhau
/// - Stream dữ liệu xe → UI
class Elm327Service {
  final BluetoothService _bt;
  Elm327Service(this._bt);

  // ── Command Queue State ───────────────────────────────────
  final _queue     = <_Cmd>[];
  _Cmd? _pending;             // Lệnh đang chờ response
  bool  _processing = false;

  // ── Polling State ─────────────────────────────────────────
  bool   _polling = false;
  Timer? _pollTimer;

  /// Các PID đọc mỗi vòng polling (theo thứ tự)
  static const _pids = [
    AppConstants.pidRpm,
    AppConstants.pidSpeed,
    AppConstants.pidCoolantTemp,
    AppConstants.pidThrottle,
    AppConstants.pidBattery,
  ];
  // VIN của xe đang kết nối
  String? _vin;
  String? get vin => _vin;
  // Buffer giá trị hiện tại
  double? _rpm, _speed, _coolant, _throttle, _battery;

  // ── Output Stream ─────────────────────────────────────────
  final _dataCtrl = StreamController<VehicleData>.broadcast();

  /// Stream dữ liệu xe realtime – UI subscribe vào đây
  Stream<VehicleData> get vehicleStream => _dataCtrl.stream;

  // ── Init Sequence ─────────────────────────────────────────

  /// Gửi chuỗi AT commands khởi tạo ELM327
  /// Phải gọi ngay sau khi BluetoothService.connect() thành công
  Future<void> initialize() async {
  AppLogger.i('─── ELM327 Initialize ───');
  try {
    // 1. Reset chip
    AppLogger.d('[1/8] ATZ – Reset');
    await _send(AppConstants.cmdReset, timeoutMs: 5000);
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. Tắt echo
    AppLogger.d('[2/8] ATE0 – Echo Off');
    await _send(AppConstants.cmdEchoOff);

    // 3. Tắt linefeed
    AppLogger.d('[3/8] ATL0 – Linefeed Off');
    await _send(AppConstants.cmdLinefeedOff);

    // 4. Bật header – cần để parse VIN multiframe
    AppLogger.d('[4/8] ATH1 – Header On');
    await _send('ATH1');

    // 5. Bật spaces – cần để parse VIN
    AppLogger.d('[5/8] ATS1 – Spaces On');
    await _send('ATS1');
    // 6. Auto-select OBD protocol
    AppLogger.d('[6/8] ATSP0 – Auto Protocol');
    await _send(AppConstants.cmdAutoProtocol);
     AppLogger.d('[7/8] ATAL – Allow Long Messages');
    await _send('ATAL');
    // 7. Đọc VIN khi header + spaces đang bật
    AppLogger.d('[8/8] Reading VIN...');
    try {
      final vinResp = await _send(
        AppConstants.pidVin,
        timeoutMs: 8000,
      );
      AppLogger.d('VIN raw response: $vinResp');
      _vin = ObdPidParser.parseVin(vinResp);
      AppLogger.i('VIN: $_vin');
    } catch (e) {
      AppLogger.w('VIN read failed (non-fatal): $e');
      _vin = null;
    }

    // 8. Tắt header + spaces SAU khi đọc VIN xong
    AppLogger.d('ATH0 – Header Off');
    await _send(AppConstants.cmdHeaderOff);
    AppLogger.d('ATS0 – Spaces Off');
    await _send(AppConstants.cmdSpacesOff);

    AppLogger.i('─── ELM327 Ready ✓ ───');
  } catch (e) {
    AppLogger.e('ELM327 init failed', e);
    rethrow;
  }
}

  // ── Polling Loop ──────────────────────────────────────────

  /// Bắt đầu vòng lặp đọc PID định kỳ
  void startPolling() {
    if (_polling) return;
    _polling = true;
    AppLogger.i('Polling started (interval=${AppConstants.pollingIntervalMs}ms)');
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    if (!_polling) return;
    _pollTimer = Timer(
      Duration(milliseconds: AppConstants.pollingIntervalMs),
      _pollOnce,
    );
  }

  /// Đọc lần lượt từng PID trong một vòng
  Future<void> _pollOnce() async {
    try {
      for (final pid in _pids) {
        if (!_polling) return;
        final resp = await _send(pid);
        _handlePidResponse(pid, resp);
      }
      _emitData();       // Phát dữ liệu lên stream sau khi đọc xong 1 vòng
    } catch (e) {
      AppLogger.w('Poll error: $e');
    } finally {
      _scheduleNextPoll();
    }
  }

  /// Parse response và cập nhật buffer
  void _handlePidResponse(String pid, String resp) {
    final val = ObdPidParser.parse(pid, resp);
    if (val == null) return;
    switch (pid.toUpperCase()) {
      case '010C': _rpm      = val;
      case '010D': _speed    = val;
      case '0105': _coolant  = val;
      case '0111': _throttle = val;
      case 'ATRV': _battery  = val;
    }
  }

  /// Emit snapshot VehicleData lên Stream
  void _emitData() {
    if (_dataCtrl.isClosed) return;
    _dataCtrl.add(VehicleData(
      timestamp:      DateTime.now(),
      vin:            _vin,
      rpm:            _rpm,
      speed:          _speed,
      coolantTemp:    _coolant,
      throttlePos:    _throttle,
      batteryVoltage: _battery,
    ));
  }

  /// Dừng polling
  void stopPolling() {
    _polling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    AppLogger.i('Polling stopped');
  }

  // ── Command Queue ─────────────────────────────────────────

  /// Gửi lệnh và đợi response (thread-safe thông qua queue)
  Future<String> _send(String cmd, {int? timeoutMs}) async {
    final c = _Cmd(cmd);
    _queue.add(c);
    _flush();

    return c.completer.future.timeout(
      Duration(milliseconds: timeoutMs ?? AppConstants.cmdTimeoutMs),
      onTimeout: () {
        _queue.remove(c);
        if (_pending == c) _pending = null;
        throw CommandTimeoutException(cmd, timeoutMs ?? AppConstants.cmdTimeoutMs);
      },
    );
  }

  /// Xử lý queue – chỉ gửi khi không có lệnh đang chờ
  void _flush() {
    if (_processing || _queue.isEmpty) return;
    _processing = true;
    _sendNext();
  }

  void _sendNext() {
    if (_queue.isEmpty) { _processing = false; return; }
    final cmd = _queue.first;
    _pending = cmd;

    _bt.send(cmd.cmd).catchError((Object e) {
      if (!cmd.completer.isCompleted) cmd.completer.completeError(e);
      _queue.remove(cmd);
      _pending = null;
      _sendNext();
    });
  }

  /// Gọi khi BluetoothService nhận được response từ ELM327
  void onBtData(String response) {
    final cmd = _pending;
    if (cmd == null) {
      AppLogger.w('Unexpected BT data: "$response"');
      return;
    }
    if (!cmd.completer.isCompleted) {
      cmd.completer.complete(response);
    }
    _queue.remove(cmd);
    _pending = null;
    _sendNext();
  }

  // ── Dispose ───────────────────────────────────────────────

  void dispose() {
    stopPolling();
    // Cancel tất cả lệnh đang pending
    for (final c in _queue) {
      if (!c.completer.isCompleted) {
        c.completer.completeError(
            const BluetoothException('Service disposed'));
      }
    }
    _queue.clear();
    _pending = null;
    _dataCtrl.close();
  }
}

// ============================================================
// lib/data/datasources/bluetooth_service.dart
// Bluetooth Classic SPP service – giao tiếp với ELM327
// ============================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/exceptions.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/bt_device_entity.dart';

typedef OnDataCallback       = void Function(String data);
typedef OnDisconnectCallback = void Function();

/// Quản lý toàn bộ vòng đời kết nối Bluetooth Classic SPP
class BluetoothService {
  BluetoothConnection? _conn;
  StreamSubscription?  _rxSub;

  /// Buffer ghép các chunk nhỏ thành response hoàn chỉnh
  final StringBuffer _rxBuf = StringBuffer();

  OnDataCallback?       _onData;
  OnDisconnectCallback? _onDisconnect;

  bool get isConnected => _conn?.isConnected ?? false;

  // ── Permissions ───────────────────────────────────────────

  Future<bool> requestPermissions() async {
    final result = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    final granted = result.values.every((s) => s.isGranted);
    if (!granted) AppLogger.w('Some BT permissions denied: $result');
    return granted;
  }

  // ── Device Discovery ──────────────────────────────────────

  /// Lấy danh sách thiết bị đã pair (Bluetooth Classic cần pair trước)
  Future<List<BtDeviceEntity>> getPairedDevices() async {
    try {
      final paired = await FlutterBluetoothSerial.instance.getBondedDevices();
      return paired.map((d) => BtDeviceEntity(
        name:     d.name ?? 'Unknown',
        address:  d.address,
        isPaired: true,
      )).toList();
    } catch (e) {
      AppLogger.e('getPairedDevices failed', e);
      throw BluetoothException('Cannot list paired devices: $e');
    }
  }

  /// Bắt đầu quét thiết bị (discovery) – trả về Stream
  Stream<BtDeviceEntity> startScan() {
    final ctrl = StreamController<BtDeviceEntity>.broadcast();
    FlutterBluetoothSerial.instance.startDiscovery().listen(
      (r) {
        if (r.device.name != null) {
          ctrl.add(BtDeviceEntity(
            name:     r.device.name!,
            address:  r.device.address,
            isPaired: r.device.isBonded,
          ));
        }
      },
      onDone:  ctrl.close,
      onError: ctrl.addError,
    );
    return ctrl.stream;
  }

  Future<void> stopScan() =>
      FlutterBluetoothSerial.instance.cancelDiscovery();

  // ── Connection ────────────────────────────────────────────

  /// Kết nối đến thiết bị qua SPP (địa chỉ MAC)
  Future<void> connect({
    required String           address,
    required OnDataCallback   onData,
    required OnDisconnectCallback onDisconnect,
  }) async {
    _onData       = onData;
    _onDisconnect = onDisconnect;

    try {
      AppLogger.i('Connecting to $address...');
      _conn = await BluetoothConnection.toAddress(address).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw ConnectionException('Connection timed out'),
      );
      AppLogger.i('Connected ✓');

      // Lắng nghe luồng dữ liệu từ ELM327
      _rxSub = _conn!.input!.listen(
        _onRxBytes,
        onDone:  _handleDisconnect,
        onError: (e) { AppLogger.e('BT stream error', e); _handleDisconnect(); },
      );
    } on BluetoothException { rethrow; }
    catch (e) {
      AppLogger.e('Connect failed', e);
      throw ConnectionException('Failed to connect: $e');
    }
  }

  // ── RX Handling ───────────────────────────────────────────

  /// ELM327 kết thúc mỗi response bằng ký tự '>' (prompt)
  /// Ta ghép chunk vào buffer và emit khi gặp '>'
  void _onRxBytes(Uint8List bytes) {
    _rxBuf.write(String.fromCharCodes(bytes));
    final buf = _rxBuf.toString();

    final promptIdx = buf.lastIndexOf('>');
    if (promptIdx < 0) return; // Chưa nhận đủ response

    // Lấy response hoàn chỉnh (không gồm '>')
    final response = buf.substring(0, promptIdx);

    // Giữ lại phần sau '>' nếu có
    _rxBuf.clear();
    final tail = buf.substring(promptIdx + 1);
    if (tail.isNotEmpty) _rxBuf.write(tail);

    if (response.trim().isNotEmpty) {
      AppLogger.d('BT RX ← "${response.trim()}"');
      _onData?.call(response);
    }
  }

  void _handleDisconnect() {
    AppLogger.w('BT disconnected');
    _rxSub?.cancel();
    _onDisconnect?.call();
  }

  // ── TX ────────────────────────────────────────────────────

  /// Gửi lệnh đến ELM327 (tự động thêm '\r')
  Future<void> send(String command) async {
    if (!isConnected) throw ConnectionException('Not connected');
    final raw = '$command\r';
    AppLogger.d('BT TX → "$command"');
    try {
      _conn!.output.add(Uint8List.fromList(raw.codeUnits));
      await _conn!.output.allSent;
    } catch (e) {
      AppLogger.e('Send failed', e);
      throw BluetoothException('Send "$command" failed: $e');
    }
  }

  // ── Disconnect ────────────────────────────────────────────

  Future<void> disconnect() async {
    _rxSub?.cancel();
    await _conn?.close();
    _conn = null;
    AppLogger.i('BT disconnected by user');
  }
}

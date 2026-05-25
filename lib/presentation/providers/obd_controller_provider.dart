// ============================================================
// lib/presentation/providers/obd_controller_provider.dart
// Riverpod providers + OBD Controller (StateNotifier)
// ============================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/bluetooth_service.dart';
import '../../data/datasources/elm327_service.dart';
import '../../data/datasources/reconnect_manager.dart';
import '../../data/datasources/sqlite_datasource.dart';
import '../../data/repositories/vehicle_data_repository_impl.dart';
import '../../domain/entities/bt_device_entity.dart';
import '../../domain/entities/vehicle_data.dart';
import '../../data/datasources/sync_service.dart';
// ────────────────────────────────────────────────────────────
// State
// ────────────────────────────────────────────────────────────

class OBDState {
  final ConnectionStatus     status;
  final String?              deviceName;   // Tên thiết bị đang kết nối
  final String?              vin; 
  final VehicleData?         current;      // Dữ liệu mới nhất
  final List<VehicleData>    history;      // Buffer realtime chart
  final String?              error;

  const OBDState({
    this.status    = ConnectionStatus.disconnected,
    this.deviceName,
    this.vin,
    this.current,
    this.history   = const [],
    this.error,
  });

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isBusy      =>
      status == ConnectionStatus.connecting  ||
      status == ConnectionStatus.initializing ||
      status == ConnectionStatus.reconnecting;

  OBDState copyWith({
    ConnectionStatus?  status,
    String?            deviceName,
    String?            vin, 
    VehicleData?       current,
    List<VehicleData>? history,
    String?            error,
    bool clearError  = false,
    bool clearDevice = false,
  }) => OBDState(
    status:     status     ?? this.status,
    deviceName: clearDevice ? null : deviceName ?? this.deviceName,
    vin:        vin        ?? this.vin,
    current:    current    ?? this.current,
    history:    history    ?? this.history,
    error:      clearError ? null : error ?? this.error,
  );
}

// ────────────────────────────────────────────────────────────
// Providers
// ────────────────────────────────────────────────────────────

final btServiceProvider = Provider<BluetoothService>(
  (_) => BluetoothService(),
);

final sqliteProvider = Provider<SqliteDataSource>(
  (_) => SqliteDataSource.instance,
);

final vehicleRepoProvider = Provider<VehicleDataRepositoryImpl>((ref) =>
    VehicleDataRepositoryImpl(ref.read(sqliteProvider)));
final syncServiceProvider = Provider<SyncService>((ref) {
  final db  = ref.read(sqliteProvider);
  final svc = SyncService(db);
  ref.onDispose(svc.dispose);
  return svc;
});
final obdProvider =
    StateNotifierProvider<OBDController, OBDState>((ref) {
  final bt   = ref.read(btServiceProvider);
  final repo = ref.read(vehicleRepoProvider);
  final db   = ref.read(sqliteProvider);
  final sync = ref.read(syncServiceProvider);  
  return OBDController(bt, repo, db, sync);    
});
final elm327StreamProvider = StreamProvider.autoDispose<VehicleData>((ref) {
  // Tạo stream từ history changes
  final ctrl = StreamController<VehicleData>();
  
  final sub = ref.listen(obdProvider, (prev, next) {
    if (next.current != null && next.current != prev?.current) {
      ctrl.add(next.current!);
    }
  });
  
  ref.onDispose(() {
    sub.close();
    ctrl.close();
  });
  
  return ctrl.stream;
});
// ────────────────────────────────────────────────────────────
// Controller
// ────────────────────────────────────────────────────────────

class OBDController extends StateNotifier<OBDState> {
  final BluetoothService            _bt;
  final VehicleDataRepositoryImpl   _repo;
  final SqliteDataSource            _db;
  final SyncService                 _sync;
  Elm327Service?   _elm;
  Elm327Service? get elm => _elm;
  ReconnectManager? _reconnector;
  StreamSubscription? _dataSub;
  Timer?           _dbTimer;


  // Lưu lại để reconnect
  String? _lastAddress;
  String? _lastName;

OBDController(this._bt, this._repo, this._db, this._sync)
    : super(const OBDState()) {
  _sync.start(); // ← Bắt đầu sync ngay khi khởi động
}

  // ── Permissions ───────────────────────────────────────────
  Future<void> requestPermissions() => _bt.requestPermissions();

  // ── Paired Devices ────────────────────────────────────────
  Future<List<BtDeviceEntity>> getPairedDevices() =>
      _bt.getPairedDevices();

  // ── Connect ───────────────────────────────────────────────

  Future<void> connect(BtDeviceEntity device) async {
    _lastAddress = device.address;
    _lastName    = device.name;
    
    state = state.copyWith(
      status:     ConnectionStatus.connecting,
      clearError: true,
    );

    try {
      // 1. Tạo ELM327 service
      _elm = Elm327Service(_bt);

      // 2. Kết nối Bluetooth SPP
      await _bt.connect(
        address:      device.address,
        onData:       (d) => _elm?.onBtData(d),
        onDisconnect: _onBtDisconnect,
      );

      // 3. Khởi tạo ELM327 (gửi AT commands)
      state = state.copyWith(status: ConnectionStatus.initializing);
      await _elm!.initialize();
      // Lưu VIN vào DB và state
      final vin = _elm!.vin;
      if (vin != null) {
        await _db.upsertVehicle(vin);
        await _sync.pullFromCloud(vin);
      }

      // 4. Sẵn sàng
      state = state.copyWith(
        status:     ConnectionStatus.connected,
        deviceName: device.name,
        vin:        vin,
      );

      _startDataFlow();
      AppLogger.i('OBD connected to ${device.name}');
    } catch (e) {
      AppLogger.e('Connect failed', e);
      state = state.copyWith(
        status: ConnectionStatus.error,
        error:  e.toString(),
      );
    }
  }

  // ── Data Flow ─────────────────────────────────────────────

  void _startDataFlow() {
    _elm!.startPolling();

    // Subscribe stream VehicleData → cập nhật UI
    _dataSub = _elm!.vehicleStream.listen(_onNewData);

    // Timer lưu DB định kỳ
    _dbTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.dbSaveIntervalMs),
      (_) => _saveToDb(),
    );
  }
  void _onNewData(VehicleData data) {
  // Gắn VIN vào mỗi bản ghi
    final dataWithVin = data.copyWith(vin: state.vin);
    final h = [...state.history, dataWithVin];
    final trimmed = h.length > AppConstants.realtimeMaxPoints
      ? h.sublist(h.length - AppConstants.realtimeMaxPoints)
      : h;

  state = state.copyWith(current: dataWithVin, history: trimmed);
}

  Future<void> _saveToDb() async {
    final d = state.current;
    if (d == null) return;
    try {
      await _repo.save(d);
    } catch (e) {
      AppLogger.e('DB save error', e);
    }
  }

  // ── Disconnect / Reconnect ────────────────────────────────

  void _onBtDisconnect() {
    AppLogger.w('BT disconnected unexpectedly');
    _stopDataFlow();
    state = state.copyWith(
      status: ConnectionStatus.reconnecting,
      history: const[],
      current: null,);

    _reconnector = ReconnectManager(() async {
      if (_lastAddress == null) return false;
      try {
        final dev = BtDeviceEntity(
          name:    _lastName ?? 'ELM327',
          address: _lastAddress!,
        );
        await connect(dev);
        return state.isConnected;
      } catch (_) { return false; }
    });
    _reconnector!.start();
  }

  void _stopDataFlow() {
    _elm?.stopPolling();
    _dataSub?.cancel();
    _dbTimer?.cancel();
    _dataSub = null;
    _dbTimer = null;
  }

  Future<void> disconnect() async {
    _reconnector?.stop();
    _stopDataFlow();
    _elm?.dispose();
    _elm = null;
    await _bt.disconnect();
    state = const OBDState();
  }

  @override
  void dispose() {
    _reconnector?.dispose();
    _stopDataFlow();
    _elm?.dispose();
    _sync.stop(); 
    super.dispose();
  }
}

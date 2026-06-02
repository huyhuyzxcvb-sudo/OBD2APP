// ============================================================
// lib/data/datasources/warning_manager.dart
// ============================================================
 
import 'dart:collection';
import '../../domain/entities/warning_rule.dart';
import '../../domain/entities/vehicle_data.dart';
 
class WarningManager {
  WarningManager._();
  static final WarningManager instance = WarningManager._();
 
  static const int      _bufferSize = 8;
  static const Duration _cooldown   = Duration(seconds: 30);
  static const Duration _debounce   = Duration(seconds: 3);
 
  final Queue<VehicleData> _buffer = Queue();
 
  final List<WarningRule> _rules = [
    OverheatRule(),
    HighEngineLoadRule(),
    LowBatteryRule(),
  ];
 
  final Map<String, DateTime> _lastNotifiedAt = {};
 
  WarningResult _currentResult  = WarningResult.normal;
  WarningResult _pendingResult  = WarningResult.normal;
  DateTime?     _pendingStarted;
 
  WarningResult process(VehicleData data) {
    _addToBuffer(data);
    final raw = _runRules();
    return _applyDebounce(raw);
  }
 
  bool canNotify(String ruleId) {
    final last = _lastNotifiedAt[ruleId];
    if (last == null) return true;
    return DateTime.now().difference(last) >= _cooldown;
  }
 
  void markNotified(String ruleId) {
    _lastNotifiedAt[ruleId] = DateTime.now();
  }
 
  void reset() {
    _buffer.clear();
    _currentResult  = WarningResult.normal;
    _pendingResult  = WarningResult.normal;
    _pendingStarted = null;
    _lastNotifiedAt.clear();
  }
 
  void _addToBuffer(VehicleData data) {
    _buffer.addLast(data);
    while (_buffer.length > _bufferSize) {
      _buffer.removeFirst();
    }
  }
 
  WarningResult _runRules() {
    final bufferList = _buffer.toList();
    WarningResult? worst;
 
    for (final rule in _rules) {
      final result = rule.evaluate(bufferList);
      if (result == null) continue;
      if (worst == null || result.severity.index > worst.severity.index) {
        worst = result;
      }
    }
 
    return worst ?? WarningResult.normal;
  }
 
  WarningResult _applyDebounce(WarningResult raw) {
    final now = DateTime.now();
 
    if (raw.ruleId != _pendingResult.ruleId ||
        raw.severity != _pendingResult.severity) {
      _pendingResult  = raw;
      _pendingStarted = now;
    }
 
    if (_pendingStarted != null &&
        now.difference(_pendingStarted!) < _debounce) {
      return _currentResult;
    }
 
    _currentResult = _pendingResult;
    return _currentResult;
  }
}
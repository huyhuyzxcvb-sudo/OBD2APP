// ============================================================
// lib/domain/entities/bt_device_entity.dart
// Entity Bluetooth device – tầng Domain (không phụ thuộc plugin)
// ============================================================

/// Đại diện cho một thiết bị Bluetooth được tìm thấy / đã pair
class BtDeviceEntity {
  final String name;
  final String address; // MAC address: "XX:XX:XX:XX:XX:XX"
  final bool   isPaired;

  const BtDeviceEntity({
    required this.name,
    required this.address,
    this.isPaired = false,
  });

  /// Heuristic: kiểm tra tên có khả năng là ELM327 không
  bool get isLikelyElm327 {
    final n = name.toLowerCase();
    return n.contains('elm')   ||
           n.contains('obd')   ||
           n.contains('vlink') ||
           n.contains('v-link');
  }

  @override
  bool operator ==(Object other) =>
      other is BtDeviceEntity && address == other.address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() => 'BtDevice($name @ $address)';
}

// ============================================================
// lib/presentation/widgets/connection_bar.dart
// Thanh trạng thái kết nối + nút scan / disconnect
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../domain/entities/bt_device_entity.dart';
import '../providers/obd_controller_provider.dart';

// ── Provider danh sách paired devices ─────────────────────────
final pairedDevicesProvider =
    FutureProvider.autoDispose<List<BtDeviceEntity>>((ref) {
  final bt = ref.read(btServiceProvider);
  return bt.getPairedDevices();
});

// ── Connection Bar ────────────────────────────────────────────

class ConnectionBar extends ConsumerWidget {
  const ConnectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s      = ref.watch(obdProvider);
    final status = s.status;

    return GestureDetector(
      onTap: () {
        if (!s.isConnected && !s.isBusy) _showSheet(context, ref);
      },
      child: Container(
        margin:  const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:        AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: _borderColor(status), width: 1),
        ),
        child: Row(children: [
          _BlinkDot(status: status),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title(status),
                  style: TextStyle(
                    color: _textColor(status), fontSize: 14,
                    fontWeight: FontWeight.w700, letterSpacing: 1,
                  ),
                ),
                if (s.deviceName != null)
                  Text(s.deviceName!,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                if (s.vin != null)
                  Text(
                   'VIN: ${s.vin!.length < 17 ? "${s.vin}..." : s.vin}',
                      style: TextStyle(
                          color: AppTheme.cyan.withOpacity(0.8),
                          fontSize: 11,
                          letterSpacing: 1,
               )
        ),
                if (s.error != null)
                  Text(s.error!,
                      style: const TextStyle(
                          color: AppTheme.red, fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // Disconnect button
          if (s.isConnected)
            IconButton(
              icon: const Icon(Icons.link_off,
                  color: AppTheme.textSecondary, size: 18),
              onPressed: () =>
                  ref.read(obdProvider.notifier).disconnect(),
            )
          else if (status == ConnectionStatus.disconnected ||
                   status == ConnectionStatus.error)
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),

          // Loading indicator
          if (s.isBusy)
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.cyan),
            ),
        ]),
      ),
    );
  }

  void _showSheet(BuildContext ctx, WidgetRef ref) {
    ref.read(obdProvider.notifier).requestPermissions();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DeviceSheet(),
    );
  }

  Color _borderColor(ConnectionStatus s) => switch (s) {
    ConnectionStatus.connected    => AppTheme.green.withOpacity(0.5),
    ConnectionStatus.connecting   ||
    ConnectionStatus.initializing => AppTheme.cyan.withOpacity(0.5),
    ConnectionStatus.reconnecting => AppTheme.yellow.withOpacity(0.5),
    ConnectionStatus.error        => AppTheme.red.withOpacity(0.5),
    _                             => AppTheme.borderDark,
  };

  Color _textColor(ConnectionStatus s) => switch (s) {
    ConnectionStatus.connected    => AppTheme.green,
    ConnectionStatus.connecting   ||
    ConnectionStatus.initializing => AppTheme.cyan,
    ConnectionStatus.reconnecting => AppTheme.yellow,
    ConnectionStatus.error        => AppTheme.red,
    _                             => AppTheme.textSecondary,
  };

  String _title(ConnectionStatus s) => switch (s) {
    ConnectionStatus.disconnected  => 'NHẤN ĐỂ KẾT NỐI ELM327',
    ConnectionStatus.scanning      => 'ĐANG QUÉT...',
    ConnectionStatus.connecting    => 'ĐANG KẾT NỐI...',
    ConnectionStatus.initializing  => 'ĐANG KHỞI TẠO ELM327...',
    ConnectionStatus.connected     => 'ĐÃ KẾT NỐI',
    ConnectionStatus.reconnecting  => 'ĐANG RECONNECT...',
    ConnectionStatus.error         => 'LỖI KẾT NỐI',
  };
}

// ── Device Sheet ──────────────────────────────────────────────

class _DeviceSheet extends ConsumerWidget {
  const _DeviceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pairedDevicesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top:   BorderSide(color: AppTheme.borderDark),
          left:  BorderSide(color: AppTheme.borderDark),
          right: BorderSide(color: AppTheme.borderDark),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppTheme.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_searching,
                    color: AppTheme.cyan, size: 20),
                const SizedBox(width: 10),
                Text('THIẾT BỊ ĐÃ PAIR',
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 16,
                        fontWeight: FontWeight.w700, letterSpacing: 2)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () => ref.refresh(pairedDevicesProvider),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pair ELM327 trong Settings → Bluetooth trước.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),

          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.cyan),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Lỗi: $e',
                  style: const TextStyle(color: AppTheme.red)),
            ),
            data: (devices) {
              if (devices.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    const Icon(Icons.bluetooth_disabled,
                        color: AppTheme.textDisabled, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy thiết bị paired\n'
                      'Vui lòng pair ELM327 trong Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ]),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics:    const NeverScrollableScrollPhysics(),
                padding:    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount:  devices.length,
                itemBuilder: (ctx, i) {
                  final d = devices[i];
                  return _DeviceTile(
                    device: d,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ref.read(obdProvider.notifier).connect(d);
                    },
                  );
                },
              );
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final BtDeviceEntity device;
  final VoidCallback   onTap;
  const _DeviceTile({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isElm = device.isLikelyElm327;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color:        AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isElm ? AppTheme.cyan.withOpacity(0.4) : AppTheme.borderDark,
        ),
        gradient: isElm ? AppTheme.cardGradient(AppTheme.cyan) : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isElm ? AppTheme.cyan : AppTheme.textSecondary)
                .withOpacity(0.12),
          ),
          child: Icon(
            isElm ? Icons.settings_input_component : Icons.bluetooth,
            color: isElm ? AppTheme.cyan : AppTheme.textSecondary,
            size: 20,
          ),
        ),
        title: Text(device.name,
            style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 16,
                fontWeight: FontWeight.w600)),
        subtitle: Text(device.address,
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        trailing: isElm
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.cyan.withOpacity(0.4)),
                ),
                child: Text('ELM327',
                    style: TextStyle(
                        color: AppTheme.cyan, fontSize: 11,
                        letterSpacing: 1)),
              )
            : null,
      ),
    );
  }
}

// ── Blinking status dot ───────────────────────────────────────

class _BlinkDot extends StatefulWidget {
  final ConnectionStatus status;
  const _BlinkDot({required this.status});

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 750));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = _color(widget.status);
    final blink = widget.status == ConnectionStatus.connecting  ||
                  widget.status == ConnectionStatus.initializing ||
                  widget.status == ConnectionStatus.reconnecting;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          shape:    BoxShape.circle,
          color:    blink ? color.withOpacity(_anim.value) : color,
          boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
        ),
      ),
    );
  }

  Color _color(ConnectionStatus s) => switch (s) {
    ConnectionStatus.connected    => AppTheme.green,
    ConnectionStatus.connecting   ||
    ConnectionStatus.initializing => AppTheme.cyan,
    ConnectionStatus.reconnecting => AppTheme.yellow,
    ConnectionStatus.error        => AppTheme.red,
    _                             => AppTheme.textDisabled,
  };
}

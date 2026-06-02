// ============================================================
// lib/presentation/screens/dashboard_screen.dart
// Trang 2 – Dashboard realtime
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../core/constants/app_theme.dart';
import '../providers/obd_controller_provider.dart';
import '../widgets/arc_gauge.dart';
import '../widgets/connection_bar.dart';
import '../widgets/metric_card.dart';
import '../widgets/warning_overlay_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s    = ref.watch(obdProvider);
    final data = s.current;

    final rpm     = data?.rpm            ?? 0.0;
    final speed   = data?.speed          ?? 0.0;
    final coolant = data?.coolantTemp    ?? 0.0;
    final throttle= data?.throttlePos   ?? 0.0;
    final battery = data?.batteryVoltage ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ─────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.surfaceDark,
            floating: true,
            snap:    true,
            title: Row(
              children: [
                const Text('DASHBOARD',
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 20,
                        fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(width: 12),
                if (s.isConnected) _LiveBadge(),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Connection bar ────────────────────────
                const ConnectionBar(),
                const WarningOverlayWidget(),
                const SizedBox(height: 20),

                // ── RPM + Speed gauges ────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _GaugeCard(
                        child: ArcGauge(
                          value:    rpm,
                          min:      0,
                          max:      8000,
                          label:    'RPM',
                          unit:     'r/min',
                          color:    AppTheme.cyan,
                          gradient: const [Color(0xFF0060FF), AppTheme.cyan],
                          size:     160,
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _GaugeCard(
                        child: ArcGauge(
                          value:    speed,
                          min:      0,
                          max:      200,
                          label:    'TỐC ĐỘ',
                          unit:     'km/h',
                          color:    AppTheme.green,
                          gradient: const [Color(0xFF00AA55), AppTheme.green],
                          size:     160,
                        ),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Coolant + Battery cards ───────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(child: MetricCard(
                      label:    'NHIỆT ĐỘ NƯỚC',
                      value:    coolant.toStringAsFixed(1),
                      unit:     '°C',
                      color:    _coolantColor(coolant),
                      icon:     Icons.thermostat_outlined,
                      progress: ((coolant + 40) / 160).clamp(0.0, 1.0),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: MetricCard(
                      label:    'ĐIỆN ÁP ẮC QUI',
                      value:    battery.toStringAsFixed(2),
                      unit:     'V',
                      color:    _batteryColor(battery),
                      icon:     Icons.battery_charging_full_outlined,
                      progress: ((battery - 10.0) / 5.0).clamp(0.0, 1.0),
                    )),
                  ]),
                ),

                const SizedBox(height: 14),

                // ── Throttle bar ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ThrottleBar(throttle: throttle),
                ),

                const SizedBox(height: 14),

                // ── Session peaks ─────────────────────────
                if (s.history.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _PeaksCard(history: s.history),
                  ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _coolantColor(double t) {
    if (t < 60)  return AppTheme.cyan;
    if (t < 95)  return AppTheme.green;
    if (t < 110) return AppTheme.yellow;
    return AppTheme.red;
  }

  Color _batteryColor(double v) {
    if (v >= 13.5) return AppTheme.green;
    if (v >= 12.0) return AppTheme.yellow;
    return AppTheme.red;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _GaugeCard extends StatelessWidget {
  final Widget child;
  const _GaugeCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.cardDark,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.borderDark),
    ),
    child: Center(child: child),
  );
}

class _ThrottleBar extends StatelessWidget {
  final double throttle;
  const _ThrottleBar({required this.throttle});

  @override
  Widget build(BuildContext context) {
    final pct = (throttle / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppTheme.orange, size: 16),
              const SizedBox(width: 8),
              const Text('VỊ TRÍ BƯỚM GA',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12,
                      letterSpacing: 1.5)),
              const Spacer(),
              Text('${throttle.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: AppTheme.orange, fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Stack(children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.borderDark,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C00), AppTheme.orange, AppTheme.red],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: AppTheme.glow(AppTheme.orange, spread: 3),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _PeaksCard extends StatelessWidget {
  final List<dynamic> history;
  const _PeaksCard({required this.history});

  @override
  Widget build(BuildContext context) {
    double maxRpm = 0, maxSpd = 0;
    for (final d in history) {
      if ((d.rpm   ?? 0) > maxRpm) maxRpm = d.rpm   ?? 0;
      if ((d.speed ?? 0) > maxSpd) maxSpd = d.speed ?? 0;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SESSION PEAKS',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11,
                  letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(children: [
            _Peak('Max RPM', maxRpm.toStringAsFixed(0), 'r/min', AppTheme.cyan),
            const SizedBox(width: 12),
            _Peak('Max Speed', maxSpd.toStringAsFixed(0), 'km/h', AppTheme.green),
            const SizedBox(width: 12),
            _Peak('Readings', '${history.length}', 'pts', AppTheme.purple),
          ]),
        ],
      ),
    );
  }
}

class _Peak extends StatelessWidget {
  final String label, value, unit;
  final Color  color;
  const _Peak(this.label, this.value, this.unit, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(
          color: AppTheme.textSecondary, fontSize: 11)),
      Text('$value $unit', style: TextStyle(
          color: color, fontSize: 14, fontWeight: FontWeight.w600)),
    ],
  ));
}

// ── Live badge (blink) ────────────────────────────────────────
class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}
class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.green.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 5, height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.green.withOpacity(0.5 + _c.value * 0.5),
              )),
          const SizedBox(width: 4),
          const Text('LIVE', style: TextStyle(
              color: AppTheme.green, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ]),
      ),
    );
  }
}

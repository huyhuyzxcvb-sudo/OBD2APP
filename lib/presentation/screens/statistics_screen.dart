// ============================================================
// lib/presentation/screens/statistics_screen.dart
// Trang 3 – Biểu đồ thống kê dữ liệu lịch sử (SQLite)
// ============================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:obd2_diagnostics/presentation/providers/obd_controller_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../domain/entities/vehicle_data.dart';
import '../providers/statistics_provider.dart';
import '../../data/datasources/sqlite_datasource.dart';
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period    = ref.watch(statsPeriodProvider);
    final obdState  = ref.watch(obdProvider);
    final cntAsync  = ref.watch(dbCountProvider);
    final dataAsync = obdState.isConnected
      ? ref.watch(realtimeStatsProvider)
      : ref.watch(historyStatsProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ─────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.surfaceDark,
            floating: true, snap: true,
            title: Text('THỐNG KÊ',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 20,
                    fontWeight: FontWeight.w800, letterSpacing: 2)),
            actions: [
              cntAsync.when(
                data: (n) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Chip(
                    backgroundColor: AppTheme.cardDark,
                    side: const BorderSide(color: AppTheme.borderDark),
                    label: Text('$n bản ghi',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    padding: EdgeInsets.zero,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error:   (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // ── VIN selector ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const _VinSelector(),
                ),
                const SizedBox(height: 12),

                // ── Period filter ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PeriodFilter(selected: period),
                ),

                const SizedBox(height: 20),

                // ── Charts ────────────────────────────────
                dataAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.cyan),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Lỗi: $e',
                        style: const TextStyle(color: AppTheme.red)),
                  ),
                  data: (data) => data.isEmpty
                      ? _EmptyState()
                      : _AllCharts(data: data, period: period),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ── Period Filter ─────────────────────────────────────────────

class _PeriodFilter extends ConsumerWidget {
  final StatsPeriod selected;
  const _PeriodFilter({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(children: [
      Expanded(child: _FilterBtn(
        label: '24 GIỜ QUA',
        active: selected == StatsPeriod.day,
        onTap: () => ref.read(statsPeriodProvider.notifier).state =
            StatsPeriod.day,
      )),
      const SizedBox(width: 12),
      Expanded(child: _FilterBtn(
        label: '7 NGÀY QUA',
        active: selected == StatsPeriod.week,
        onTap: () => ref.read(statsPeriodProvider.notifier).state =
            StatsPeriod.week,
      )),
    ]);
  }
}

class _FilterBtn extends StatelessWidget {
  final String   label;
  final bool     active;
  final VoidCallback onTap;
  const _FilterBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.cyan.withOpacity(0.14)
            : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppTheme.cyan.withOpacity(0.5) : AppTheme.borderDark,
        ),
      ),
      child: Center(child: Text(label,
          style: TextStyle(
              color: active ? AppTheme.cyan : AppTheme.textSecondary,
              fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1))),
    ),
  );
}

// ── All Charts ────────────────────────────────────────────────

class _AllCharts extends StatelessWidget {
  final List<VehicleData> data;
  final StatsPeriod       period;
  const _AllCharts({required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
   final gap = period == StatsPeriod.day ? 30 : 360; // 30 phút | 6 tiếng
   final maxPoints = period == StatsPeriod.day ? 500 : 800;
   final sampled   = _sample(data, maxPoints, gapMinutes: gap);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        _ChartCard(
          title: 'VÒNG TUA ĐỘNG CƠ (RPM)',
          color: AppTheme.cyan,
          unit:  'r/min',
          minY: 0, maxY: 6000,
          period: period,
          gapMinutes: gap,
          spots: sampled
              .where((d) => d.rpm != null)
              // Lọc bỏ điểm bất thường (RPM > 8000 hoặc < 0)
              .where((d) => d.rpm! >= 0 && d.rpm! <= 8000)
              .where((d) => d.rpm!.isFinite) 
              .map((d) => FlSpot(
                d.timestamp.millisecondsSinceEpoch.toDouble(), d.rpm!))
              .toList(),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'TỐC ĐỘ XE (km/h)',
          color: AppTheme.green,
          unit:  'km/h',
          minY: 0, maxY: 180,
          period: period,
          gapMinutes: gap,
          spots: sampled
              .where((d) => d.speed != null)
              .where((d) => d.speed! >= 0 && d.speed! <= 200)
              .where((d) => d.speed!.isFinite)
              .map((d) => FlSpot(
                d.timestamp.millisecondsSinceEpoch.toDouble(), d.speed!))
              .toList(),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'NHIỆT ĐỘ NƯỚC LÀM MÁT (°C)',
          color: AppTheme.orange,
          unit:  '°C',
          minY: 0, maxY: 130,
          period: period,
          gapMinutes: gap,
          spots: sampled
              .where((d) => d.coolantTemp != null)
              .where((d) => d.coolantTemp! >= -40 && d.coolantTemp! <= 130)
              .where((d) => d.coolantTemp!.isFinite)
              .map((d) => FlSpot(
                d.timestamp.millisecondsSinceEpoch.toDouble(),
                d.coolantTemp!))
              .toList(),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'ĐIỆN ÁP ẮC QUI (V)',
          color: AppTheme.yellow,
          unit:  'V',
          minY: 10, maxY: 16,
          period: period,
          gapMinutes: gap,
          spots: sampled
              .where((d) => d.batteryVoltage != null)
              .where((d) => d.batteryVoltage! >= 0 && d.batteryVoltage! <= 16)
              .where((d) => d.batteryVoltage!.isFinite)
              .map((d) => FlSpot(
                d.timestamp.millisecondsSinceEpoch.toDouble(),
                d.batteryVoltage!))
              .toList(),
        ),
      ]),
    );
  }

  /// Down-sample data để chart không bị quá nhiều điểm
 static List<VehicleData> _sample(List<VehicleData> src, int maxTotal, {int gapMinutes = 30}) {
  if (src.isEmpty) return src;

  // Bước 1: Sort
  final sorted = [...src]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Bước 2: Tách thành các session (gap > 30 phút)
  final sessions = <List<VehicleData>>[];
  var current = <VehicleData>[sorted.first];

  for (int i = 1; i < sorted.length; i++) {
    final gapMin = sorted[i].timestamp
        .difference(sorted[i - 1].timestamp)
        .inMinutes;
    if (gapMin > gapMinutes) {
      sessions.add(current);
      current = [sorted[i]];
    } else {
      current.add(sorted[i]);
    }
  }
  sessions.add(current);

  // Bước 3: Phân bổ maxTotal điểm đều cho mỗi session
  // Mỗi session được ít nhất 2 điểm (đầu + cuối)
  final pointsPerSession = (maxTotal / sessions.length).floor().clamp(2, maxTotal);

  final result = <VehicleData>[];
  for (final session in sessions) {
    if (session.length <= pointsPerSession) {
      result.addAll(session);
    } else {
      // Lấy đều trong session này
      final step = (session.length - 1) / (pointsPerSession - 1);
      for (int i = 0; i < pointsPerSession; i++) {
        result.add(session[(i * step).round().clamp(0, session.length - 1)]);
      }
    }
  }
  return result;
}
static List<List<FlSpot>> _splitIntoSegments(
      List<FlSpot> spots, {int gapMinutes = 30}) {
    if (spots.isEmpty) return [];

    final segments = <List<FlSpot>>[];
    var   current  = <FlSpot>[spots.first];

    for (int i = 1; i < spots.length; i++) {
      final gapMs = spots[i].x - spots[i - 1].x;
      if (gapMs > gapMinutes * 60 * 1000) {
        if (current.length >= 1) segments.add(current);
        current = [spots[i]];
      } else {
        current.add(spots[i]);
      }
    }

    if (current.length >= 1) segments.add(current);
    return segments;
  }
}

// ── Single Chart Card ─────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String        title;
  final Color         color;
  final String        unit;
  final double        minY, maxY;
  final StatsPeriod   period;
  final List<FlSpot>  spots;
  final int gapMinutes;
  
  const _ChartCard({
    required this.title,
    required this.color,
    required this.unit,
    required this.minY,
    required this.maxY,
    required this.period,
    required this.spots,
    this.gapMinutes = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Center(child: Text('Không có dữ liệu $title',
            style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    final ys   = spots.map((s) => s.y).toList();
    final avg  = ys.reduce((a, b) => a + b) / ys.length;
    final vmax = ys.reduce((a, b) => a > b ? a : b);
    final vmin = ys.reduce((a, b) => a < b ? a : b);
    final xInterval = _xInterval(spots);
    final segments = _AllCharts._splitIntoSegments(spots, gapMinutes: gapMinutes); 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
        gradient: AppTheme.cardGradient(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(title, style: TextStyle(
              color: color, fontSize: 13,
              fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 8),

          // Min / Avg / Max
          Row(children: [
            _Stat('MIN', vmin.toStringAsFixed(1), unit, color),
            const SizedBox(width: 16),
            _Stat('AVG', avg.toStringAsFixed(1),  unit, color),
            const SizedBox(width: 16),
            _Stat('MAX', vmax.toStringAsFixed(1), unit, color),
          ]),
          const SizedBox(height: 14),

          // Line chart
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: minY, maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.borderDark.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: TextStyle(
                            color: AppTheme.textDisabled, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: xInterval,
                      getTitlesWidget: (v, meta) {
                        if (v == meta.min || v == meta.max) {
                           return const SizedBox.shrink();
                         }
                        final dt = DateTime.fromMillisecondsSinceEpoch(v.toInt());
                        final fmt = period == StatsPeriod.day
                             ? DateFormat('HH:mm')
                             : DateFormat('dd/MM');
                        return Text(fmt.format(dt),
                             style: TextStyle(
                             color: AppTheme.textDisabled, fontSize: 9));
                    },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: segments.isEmpty
                  ? [LineChartBarData(spots: spots, color: color, barWidth: 2)]
                  : segments.map((seg) => LineChartBarData(
                        spots:            seg,
                        isCurved:         true,
                        curveSmoothness:  0.3,
                        color:            color,
                        barWidth:         2,
                        isStrokeCapRound: true,
                        dotData:          const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end:   Alignment.bottomCenter,
                            colors: [
                              color.withOpacity(0.28),
                              color.withOpacity(0.0),
                            ],
                          ),
                        ),
                      )).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceDark,
                    getTooltipItems: (touched) => touched
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(1)} $unit',
                              TextStyle(
                                color: color, fontSize: 12,
                                fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                ),
              ),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }

double _xInterval(List<FlSpot> allSpots) {
  if (allSpots.length < 2) return 1;

  // Sort để đảm bảo first/last đúng
  final sorted = [...allSpots]..sort((a, b) => a.x.compareTo(b.x));
  final range  = sorted.last.x - sorted.first.x;
  if (range <= 0) return 60000;

  const ms = 60 * 1000.0; // 1 phút tính bằng ms

  // Tối đa 4 nhãn để tránh chồng
  final interval = range / 4;

  // Làm tròn lên mốc đẹp gần nhất
  if (interval <=  5 * ms) return  5 * ms;
  if (interval <= 10 * ms) return 10 * ms;
  if (interval <= 15 * ms) return 15 * ms;
  if (interval <= 30 * ms) return 30 * ms;
  if (interval <= 60 * ms) return 60 * ms;        // 1 giờ
  if (interval <= 120 * ms) return 120 * ms;      // 2 giờ
  if (interval <= 360 * ms) return 360 * ms;      // 6 giờ
  return 720 * ms;                                // 12 giờ
}
}

class _Stat extends StatelessWidget {
  final String label, value, unit;
  final Color  color;
  const _Stat(this.label, this.value, this.unit, this.color);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(
          color: AppTheme.textDisabled, fontSize: 10, letterSpacing: 1)),
      Text('$value $unit', style: TextStyle(
          color: color, fontSize: 13, fontWeight: FontWeight.w700)),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(60),
    child: Column(children: [
      const Icon(Icons.bar_chart_outlined,
          color: AppTheme.textDisabled, size: 60),
      const SizedBox(height: 16),
      Text('Chưa có dữ liệu thống kê',
          style: TextStyle(
              color: AppTheme.textSecondary, fontSize: 16)),
      const SizedBox(height: 8),
      Text('Kết nối xe và để app chạy để thu thập dữ liệu',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppTheme.textDisabled, fontSize: 13)),
    ]),
  );
}
// ── VIN Selector ──────────────────────────────────────────────

class _VinSelector extends ConsumerWidget {
  const _VinSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vinsAsync   = ref.watch(allVinsProvider);
    final selectedVin = ref.watch(selectedVinProvider);

    return vinsAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (vins) {
        if (vins.isEmpty) return const SizedBox.shrink(); 
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHỌN XE',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount:       vins.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
              final vin        = vins[i];
              final isSelected = vin == selectedVin;
                return _VinItem(
                  vin: vin,
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(selectedVinProvider.notifier)
                      .state = isSelected ? null : vin,
                );
              }, 
             ),
            ),
          ],
        );
      },
    );
  }
}  
class _VinItem extends StatefulWidget {
  final String vin;
  final bool isSelected;
  final VoidCallback onTap;

  const _VinItem({
    required this.vin,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VinItem> createState() => _VinItemState();
}
class _VinItemState extends State<_VinItem> {
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info =
        await SqliteDataSource.instance.getVehicleInfo(widget.vin);
    if (!mounted) return;
    if (info?['name'] != null && (info!['name'] as String).isNotEmpty) {
      final plate = info['plate'] as String? ?? '';
      setState(() {
        _displayName = plate.isNotEmpty
            ? '${info['name']} ($plate)'
            : info['name'] as String;
      });
    }
  }

  void _showEdit(BuildContext context) {
    final nameCtrl  = TextEditingController();
    final plateCtrl = TextEditingController();

    SqliteDataSource.instance.getVehicleInfo(widget.vin).then((info) {
      if (info != null) {
        nameCtrl.text  = info['name']  as String? ?? '';
        plateCtrl.text = info['plate'] as String? ?? '';
      }
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Đặt tên xe',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Tên xe',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              hintText: 'Ví dụ: Ford Focus của tôi',
              hintStyle: TextStyle(color: AppTheme.textDisabled),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: plateCtrl,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Biển số xe',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              hintText: 'Ví dụ: 51A-123.45',
              hintStyle: TextStyle(color: AppTheme.textDisabled),
            ),
          ),
        ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Huỷ',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await SqliteDataSource.instance.updateVehicleInfo(
                  widget.vin,
                  nameCtrl.text.trim(),
                  plateCtrl.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _loadInfo();
              } catch (e, st) {
                debugPrint('updateVehicleInfo error: $e');
                debugPrint('$st');
              }
            },
            child: Text('Lưu',
                style: TextStyle(color: AppTheme.cyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName ??
        (widget.vin.length > 11
            ? '${widget.vin.substring(0, 11)}...'
            : widget.vin);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppTheme.cyan.withOpacity(0.15)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected
                ? AppTheme.cyan.withOpacity(0.6)
                : AppTheme.borderDark,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.directions_car,
              size: 14,
              color: widget.isSelected
                  ? AppTheme.cyan
                  : AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(displayName,
              style: TextStyle(
                color: widget.isSelected
                    ? AppTheme.cyan
                    : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          if (widget.isSelected) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle, size: 14, color: AppTheme.cyan),
          ],
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showEdit(context),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.edit, size: 14, color: AppTheme.cyan),
            ),
          ),
        ]),
      ),
    );
  }
}
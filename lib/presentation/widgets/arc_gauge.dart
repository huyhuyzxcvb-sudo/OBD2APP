// ============================================================
// lib/presentation/widgets/arc_gauge.dart
// Widget đồng hồ đo hình cung (Arc Gauge) – RPM / Speed
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';


import '../../core/constants/app_theme.dart';

class ArcGauge extends StatelessWidget {
  final double   value;
  final double   min;
  final double   max;
  final String   label;
  final String   unit;
  final Color    color;
  final List<Color>? gradient;
  final double   size;

  const ArcGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.unit,
    required this.color,
    this.gradient,
    this.size = 170,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((value.clamp(min, max)) - min) / (max - min);

    return SizedBox(
      width:  size,
      height: size * 0.86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Arc background + foreground ─────────────────
          CustomPaint(
            size: Size(size, size * 0.86),
            painter: _ArcPainter(
              pct:      pct,
              color:    color,
              gradient: gradient,
            ),
          ),

          // ── Center text ──────────────────────────────────
          Positioned(
            bottom: size * 0.06,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Giá trị số
                Text(
                  value < 100
                      ? value.toStringAsFixed(1)
                      : value.toStringAsFixed(0),
                  style: TextStyle(
                    color:      AppTheme.textPrimary,
                    fontSize:   size * 0.20,
                    fontWeight: FontWeight.w700,
                    height:     1,
                  ),
                ),
                // Đơn vị
                Text(
                  unit,
                  style: TextStyle(
                    color:       color.withOpacity(0.85),
                    fontSize:    size * 0.078,
                    fontWeight:  FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                // Nhãn
                Text(
                  label,
                  style: TextStyle(
                    color:       AppTheme.textSecondary,
                    fontSize:    size * 0.066,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter ────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double       pct;
  final Color        color;
  final List<Color>? gradient;

  // Góc bắt đầu và góc quét của arc (độ → radian)
  static const double _startDeg = 150;
  static const double _sweepDeg = 240;
  static const double _startRad = _startDeg * math.pi / 180;
  static const double _sweepRad = _sweepDeg * math.pi / 180;

  const _ArcPainter({
    required this.pct,
    required this.color,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height * 0.54;
    final center = Offset(cx, cy);
    final radius = size.width * 0.41;
    final sw     = size.width * 0.052; // strokeWidth

    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Track (nền) ──────────────────────────────────────
    canvas.drawArc(
      rect, _startRad, _sweepRad, false,
      Paint()
        ..color       = AppTheme.borderDark.withOpacity(0.8)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap   = StrokeCap.round,
    );

    // ── Tick marks ───────────────────────────────────────
    _drawTicks(canvas, center, radius, sw);

    if (pct <= 0) return;

    // ── Value arc ────────────────────────────────────────
    final valuePaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap   = StrokeCap.round;

    final colors = gradient ?? [color.withOpacity(0.6), color];
    valuePaint.shader = SweepGradient(
      startAngle: _startRad,
      endAngle:   _startRad + _sweepRad * pct,
      colors:     colors,
    ).createShader(rect);

    canvas.drawArc(rect, _startRad, _sweepRad * pct, false, valuePaint);

    // ── Glow ─────────────────────────────────────────────
    canvas.drawArc(
      rect, _startRad, _sweepRad * pct, false,
      Paint()
        ..color      = color.withOpacity(0.25)
        ..style      = PaintingStyle.stroke
        ..strokeWidth = sw * 1.6
        ..strokeCap  = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sw * 0.6),
    );

    // ── Needle dot ───────────────────────────────────────
    final angle     = _startRad + _sweepRad * pct;
    final dotCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(dotCenter, sw * 0.72, Paint()..color = color);
    canvas.drawCircle(
      dotCenter, sw * 1.3,
      Paint()
        ..color      = color.withOpacity(0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sw * 0.5),
    );
  }

  void _drawTicks(Canvas canvas, Offset c, double r, double sw) {
    final p = Paint()
      ..color       = AppTheme.textDisabled
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke;

    for (int i = 0; i <= 10; i++) {
      final a     = _startRad + _sweepRad * (i / 10);
      final inner = r - sw * 1.2;
      final outer = r - sw * 0.1;
      canvas.drawLine(
        Offset(c.dx + inner * math.cos(a), c.dy + inner * math.sin(a)),
        Offset(c.dx + outer * math.cos(a), c.dy + outer * math.sin(a)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.pct != pct;
}

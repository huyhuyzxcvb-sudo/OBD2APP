// ============================================================
// lib/presentation/screens/cover_screen.dart
// Trang 1 – Bìa đề tài / Thông tin sinh viên
// ============================================================

import 'package:flutter/material.dart';


import '../../core/constants/app_theme.dart';

class CoverScreen extends StatefulWidget {
  const CoverScreen({super.key});
  @override
  State<CoverScreen> createState() => _CoverScreenState();
}

class _CoverScreenState extends State<CoverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<double>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _fade  = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _slide = Tween<double>(begin: 36, end: 0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [Color(0xFF040810), AppTheme.bgDark],
              ),
            ),
          ),
          // Grid lines overlay
          CustomPaint(painter: _GridPainter(), size: Size.infinite),
          // Top-right glow
          Positioned(
            top: -120, right: -120,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.cyan.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────
          SafeArea(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(
                    offset: Offset(0, _slide.value), child: child),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── Badge ─────────────────────────────
                    _Badge('ĐỒ ÁN TỐT NGHIỆP'),

                    const SizedBox(height: 28),

                    // ── Icon ──────────────────────────────
                    _GlowIcon(
                      icon:  Icons.directions_car,
                      color: AppTheme.cyan,
                      size:  76,
                    ),

                    const SizedBox(height: 28),

                    // ── Title ─────────────────────────────
                    Text(
                      'LẬP TRÌNH\nPHẦN MỀM ĐỌC\nTHÔNG TIN HỆ THỐNG\nĐIỀU KHIỂN ĐỘNG CƠ',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'bằng thiết bị chẩn đoán dựa trên chip',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          letterSpacing: 0.3),
                    ),

                    const SizedBox(height: 10),

                    // ── ELM327 highlight ──────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cyanGradient(),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: AppTheme.glow(AppTheme.cyan, spread: 5),
                      ),
                      child: Text('ELM327',
                          style: TextStyle(
                            color: AppTheme.bgDark,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          )),
                    ),

                    const SizedBox(height: 48),

                    // ── Divider ────────────────────────────
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppTheme.cyan.withOpacity(0.6),
                          Colors.transparent,
                        ]),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Student info ──────────────────────
                    _InfoRow('SINH VIÊN', 'Nguyễn Viết Huy'),
                    const SizedBox(height: 14),
                    _InfoRow('LỚP',
                        'Kỹ thuật Ô tô 4 / K62'),

                    const SizedBox(height: 36),

                    // ── Tech stack ────────────────────────
                    Text('CÔNG NGHỆ SỬ DỤNG',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: const [
                        _TechBadge('Flutter',        AppTheme.cyan),
                        _TechBadge('Dart',           AppTheme.green),
                        _TechBadge('Bluetooth SPP',  AppTheme.orange),
                        _TechBadge('SQLite',         AppTheme.yellow),
                        _TechBadge('Riverpod',       AppTheme.purple),
                        _TechBadge('OBD-II ELM327',  AppTheme.red),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // ── Spec card ─────────────────────────
                    _SpecCard(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.cyan.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(4),
        color: AppTheme.cyan.withOpacity(0.06),
      ),
      child: Text(text,
          style: TextStyle(
              color: AppTheme.cyan, fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 3)),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final double   size;
  const _GlowIcon({required this.icon, required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withOpacity(0.18), color.withOpacity(0.04),
        ]),
        boxShadow: AppTheme.glow(color),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Icon(icon, color: color, size: size * 0.44),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11, letterSpacing: 1.5)),
        ),
        Container(
          width: 2, height: 16,
          color: AppTheme.cyan.withOpacity(0.5),
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: AppTheme.textPrimary, fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _TechBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _TechBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12,
              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}

class _SpecCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THÔNG SỐ KỸ THUẬT',
              style: TextStyle(
                  color: AppTheme.cyan, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 14),
          const _SR('Giao thức',    'OBD-II / SAE J1979'),
          const _SR('Bluetooth',    'Classic SPP (UUID 1101)'),
          const _SR('Polling',      '500 ms / PID'),
          const _SR('Lưu DB',       'Mỗi 5 giây'),
          const _SR('PIDs đọc',
              'RPM · Speed · Coolant · Throttle · Battery'),
          const _SR('Platform',     'Android API 21+'),
        ],
      ),
    );
  }
}

class _SR extends StatelessWidget {
  final String k, v;
  const _SR(this.k, this.v);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(k,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(v,
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Grid background painter ───────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1A2235).withOpacity(0.45)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width;  x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

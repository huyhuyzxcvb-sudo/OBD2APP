// ============================================================
// lib/presentation/widgets/metric_card.dart
// Card nhỏ hiển thị một chỉ số (Coolant, Battery, Throttle...)
// ============================================================

import 'package:flutter/material.dart';


import '../../core/constants/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String   unit;
  final Color    color;
  final IconData icon;
  final double?  progress; // 0‥1 nếu muốn hiện progress bar

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppTheme.borderDark),
        gradient:     AppTheme.cardGradient(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const Spacer(),
            // Live dot
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.6), blurRadius: 5),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Value ────────────────────────────────────────
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 4),

          // ── Label ────────────────────────────────────────
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1,
            ),
          ),

          // ── Optional progress bar ─────────────────────────
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value:           progress!.clamp(0.0, 1.0),
                backgroundColor: AppTheme.borderDark,
                valueColor:      AlwaysStoppedAnimation<Color>(color),
                minHeight:       3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

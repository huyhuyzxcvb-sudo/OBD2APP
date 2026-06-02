// ============================================================
// lib/presentation/widgets/warning_overlay_widget.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/warning_rule.dart';
import '../../core/constants/app_theme.dart';
import '../providers/warning_provider.dart';

class WarningOverlayWidget extends ConsumerWidget {
  const WarningOverlayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(warningProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data:    (result) => result.isNormal
          ? const SizedBox.shrink()
          : _WarningCard(result: result),
    );
  }
}

class _WarningCard extends StatefulWidget {
  final WarningResult result;
  const _WarningCard({required this.result});

  @override
  State<_WarningCard> createState() => _WarningCardState();
}

class _WarningCardState extends State<_WarningCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    );
    _startAnimation();
  }

  @override
  void didUpdateWidget(_WarningCard old) {
    super.didUpdateWidget(old);
    if (widget.result.severity != old.result.severity) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (widget.result.isCritical) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.result.severity) {
      case WarningSeverity.critical: return const Color(0xFFFF1744);
      case WarningSeverity.warning:  return const Color(0xFFFFAB40);
      default:                       return AppTheme.cyan;
    }
  }

  IconData get _icon => widget.result.isCritical
      ? Icons.warning_rounded
      : Icons.info_outline_rounded;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: Container(
        margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withOpacity(0.6), width: 1.5),
        ),
        child: Row(children: [
          Icon(_icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.result.title,
                    style: TextStyle(
                      color:      color,
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                    )),
                if (widget.result.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(widget.result.message,
                      maxLines: 1,
                      style: TextStyle(
                        color:    AppTheme.textSecondary,
                        fontSize: 9,
                      )),
                ],
              ],
            ),
          ),
          _SeverityBadge(severity: widget.result.severity, color: color),
        ]),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final WarningSeverity severity;
  final Color           color;
  const _SeverityBadge({required this.severity, required this.color});

  String get _label {
    switch (severity) {
      case WarningSeverity.critical: return 'NGUY HIỂM';
      case WarningSeverity.warning:  return 'CẢNH BÁO';
      default:                       return 'BÌNH THƯỜNG';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(_label,
        style: TextStyle(
          color:      color,
          fontSize:   9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        )),
  );
}
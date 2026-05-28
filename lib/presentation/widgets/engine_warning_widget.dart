// ============================================================
// lib/presentation/widgets/engine_warning_widget.dart
// Widget hiển thị cảnh báo — tích hợp vào Dashboard
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/engine_warning.dart';
import '../providers/engine_warning_provider.dart';
import '../../core/constants/app_theme.dart';

class EngineWarningWidget extends ConsumerWidget {
  const EngineWarningWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warningAsync = ref.watch(engineWarningProvider);

    return warningAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data:    (warning) {
        // Không hiện gì khi bình thường
        if (warning.isNormal) return const SizedBox.shrink();
        return _WarningBanner(warning: warning);
      },
    );
  }
}

/// Banner cảnh báo — hiển thị trên Dashboard
class _WarningBanner extends StatefulWidget {
  final EngineWarning warning;
  const _WarningBanner({required this.warning});

  @override
  State<_WarningBanner> createState() => _WarningBannerState();
}

class _WarningBannerState extends State<_WarningBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );

    // CRITICAL → nhấp nháy liên tục
    // WARNING  → hiện tĩnh
    if (widget.warning.isCritical) {
      _animCtrl.repeat(reverse: true);
    } else {
      _animCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(_WarningBanner old) {
    super.didUpdateWidget(old);
    if (widget.warning.level != old.warning.level) {
      if (widget.warning.isCritical) {
        _animCtrl.repeat(reverse: true);
      } else {
        _animCtrl.stop();
        _animCtrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Color get _bannerColor => Color(
    EngineWarning.levelColors[widget.warning.level] ?? 0xFFFFAB40,
  );

  IconData get _icon => widget.warning.isCritical
      ? Icons.warning_rounded
      : Icons.info_outline_rounded;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bannerColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _bannerColor.withOpacity(0.6), width: 1.5),
        ),
        child: Row(children: [
          Icon(_icon, color: _bannerColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.warning.message,
                  style: TextStyle(
                    color:      _bannerColor,
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                if (widget.warning.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.warning.description,
                    style: TextStyle(
                      color:    AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Thanh mức độ nghiêm trọng
          _SeverityBar(
            severity: widget.warning.severity,
            color:    _bannerColor,
          ),
        ]),
      ),
    );
  }
}

/// Thanh hiển thị mức độ nghiêm trọng 0.0 → 1.0
class _SeverityBar extends StatelessWidget {
  final double severity;
  final Color  color;
  const _SeverityBar({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '${(severity * 100).toInt()}%',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: 6, height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: RotatedBox(
            quarterTurns: 3,
            child: LinearProgressIndicator(
              value:            severity,
              backgroundColor:  color.withOpacity(0.2),
              valueColor:       AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ),
    ],
  );
}
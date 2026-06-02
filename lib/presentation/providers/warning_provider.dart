// ============================================================
// lib/presentation/providers/warning_provider.dart
// ============================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/warning_manager.dart';
import '../../data/datasources/notification_service.dart';
import '../../domain/entities/warning_rule.dart';
import 'obd_controller_provider.dart';

final warningProvider =
    StreamProvider.autoDispose<WarningResult>((ref) {
  ref.keepAlive();
  final manager    = WarningManager.instance;
  final notifSvc   = NotificationService.instance;
  final controller = StreamController<WarningResult>();

  manager.reset();

  final timer = Timer.periodic(
    const Duration(milliseconds: 500), (_) async {
    final obdState = ref.read(obdProvider);

    if (!obdState.isConnected || obdState.current == null) {
      manager.reset();
      await notifSvc.cancelAll();
      if (!controller.isClosed) {
        controller.add(WarningResult.normal);
      }
      return;
    }

    final result = manager.process(obdState.current!);

    if (!result.isNormal && manager.canNotify(result.ruleId)) {
      await notifSvc.showWarning(result);
      manager.markNotified(result.ruleId);
    }

    if (result.isNormal) {
      await notifSvc.cancelAll();
    }

    if (!controller.isClosed) {
      controller.add(result);
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
    manager.reset();
    notifSvc.cancelAll();
  });

  return controller.stream;
});

final warningSeverityProvider =
    Provider.autoDispose<WarningSeverity>((ref) {
  return ref.watch(warningProvider).whenOrNull(
        data: (r) => r.severity,
      ) ??
      WarningSeverity.normal;
});
// ============================================================
// lib/main.dart
// Entry point – khởi tạo app, SQLite, và chạy Flutter
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'data/datasources/sqlite_datasource.dart';
import 'presentation/screens/main_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
// Khởi tạo Supabase
  await Supabase.initialize(
  url:    'https://klmxzzfixhfdnyymnqdd.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtsbXh6emZpeGhmZG55eW1ucWRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4MTIxNjYsImV4cCI6MjA5NDM4ODE2Nn0.MiWFCONohTnkUbwwsg3smUzCZkNZfZSDLWXGmiiyxVA',
);
  // Khóa chiều dọc
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar trong suốt
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Khởi tạo SQLite một lần duy nhất
  try {
    await SqliteDataSource.instance.initialize();
    AppLogger.i('SQLite initialized ✓');
  } catch (e) {
    AppLogger.e('SQLite init failed – data will not be persisted', e);
    // App vẫn chạy được, chỉ mất chức năng lưu DB
  }

  runApp(
    // ProviderScope bắt buộc để Riverpod hoạt động
    const ProviderScope(child: OBD2App()),
  );
}

class OBD2App extends StatelessWidget {
  const OBD2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                   'OBD2 Diagnostics',
      debugShowCheckedModeBanner: false,
      theme:                   AppTheme.dark,
      home:                    const MainShell(),
    );
  }
}

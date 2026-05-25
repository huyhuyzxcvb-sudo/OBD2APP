// lib/presentation/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../core/constants/app_theme.dart';
import 'cover_screen.dart';
import 'dashboard_screen.dart';
import 'statistics_screen.dart';

final _tabProvider = StateProvider<int>((_) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    DashboardScreen(),
    StatisticsScreen(),
    CoverScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,

      // ── Nút nhỏ góc trên phải để mở trang Đề tài ──────
      floatingActionButton: tab != 2
          ? FloatingActionButton.small(
              backgroundColor: AppTheme.surfaceDark,
              foregroundColor: AppTheme.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppTheme.borderDark),
              ),
              onPressed: () {
                ref.read(_tabProvider.notifier).state = 2;
              },
              child: const Icon(Icons.article_outlined, size: 18),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,

      // ── Body ────────────────────────────────────────────
      body: IndexedStack(index: tab, children: _screens),

      // ── Bottom nav chỉ 2 tab ────────────────────────────
      bottomNavigationBar: tab == 2
          // Khi đang ở tab Đề tài → hiện nút quay lại thay vì navbar
          ? Container(
              height: 60,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(
                    top: BorderSide(color: AppTheme.borderDark)),
              ),
              child: TextButton.icon(
                onPressed: () {
                  ref.read(_tabProvider.notifier).state = 0;
                },
                icon: const Icon(Icons.arrow_back,
                    color: AppTheme.cyan, size: 18),
                label: Text(
                  'QUAY LẠI',
                  style: TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
          // Khi ở tab khác → hiện navbar bình thường 2 tab
          : Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(
                    top: BorderSide(color: AppTheme.borderDark)),
              ),
              child: BottomNavigationBar(
                currentIndex: tab,
                onTap: (i) =>
                    ref.read(_tabProvider.notifier).state = i,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppTheme.cyan,
                unselectedItemColor: AppTheme.textDisabled,
                selectedLabelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1),
                unselectedLabelStyle: TextStyle(
                    fontSize: 11, letterSpacing: 0.5),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.speed_outlined),
                    activeIcon: Icon(Icons.speed),
                    label: 'DASHBOARD',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_outlined),
                    activeIcon: Icon(Icons.bar_chart),
                    label: 'THỐNG KÊ',
                  ),
                ],
              ),
            ),
    );
  }
}

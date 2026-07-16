import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/session_provider.dart';

// Screens
import '../screens/home/home_screen.dart';
import '../screens/tutor/tutor_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/exam_prep/exam_prep_screen.dart';
import '../screens/research/research_screen.dart';
import '../screens/settings/settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      backgroundColor: UEColors.bgPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 70),
                child: IndexedStack(
                  index: navProvider.selectedIndex,
                  children: const [
                    HomeScreen(),       // 0
                    LibraryScreen(),    // 1
                    TutorScreen(),      // 2
                    ResearchScreen(),   // 3
                    SettingsScreen(),   // 4
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomNav(
                selectedIndex: navProvider.selectedIndex,
                onTap: (index) => navProvider.setIndex(index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;

  const _BottomNavItem({
    required this.icon,
    required this.label,
  });
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const List<_BottomNavItem> _navItems = [
    _BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
    _BottomNavItem(icon: Icons.folder_copy_outlined, label: 'Library'),
    _BottomNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Tutor'),
    _BottomNavItem(icon: Icons.travel_explore_rounded, label: 'Research'),
    _BottomNavItem(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(
          top: BorderSide(color: UEColors.bgCard, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final active = i == selectedIndex;
              final item = _navItems[i];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: active ? UEColors.indigo : UEColors.textMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: UETypography.label.copyWith(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? UEColors.indigo : UEColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

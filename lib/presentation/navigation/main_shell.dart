import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
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
    final sessionProvider = Provider.of<SessionProvider>(context);

    return Scaffold(
      backgroundColor: UEColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Current Screen Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80), // height of bottom nav
                child: Column(
                  children: [
                    // Persistent Status Bar
                    _StatusBar(
                      isOffline: sessionProvider.isOffline,
                      onToggleOffline: () {
                        sessionProvider.toggleOffline(!sessionProvider.isOffline);
                      },
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: navProvider.selectedIndex,
                        children: const [
                          HomeScreen(),
                          TutorScreen(),
                          LibraryScreen(),
                          ExamPrepScreen(),
                          ResearchScreen(),
                          SettingsScreen(), // Hidden index accessed via quick links/taps
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
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

class _StatusBar extends StatelessWidget {
  final bool isOffline;
  final VoidCallback onToggleOffline;

  const _StatusBar({
    required this.isOffline,
    required this.onToggleOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: UETypography.inter(fontSize: 12, color: UEColors.textMuted),
          ),
          _OfflineBadge(
            isOffline: isOffline,
            onTap: onToggleOffline,
          ),
          const Icon(Icons.battery_3_bar, size: 18, color: UEColors.textMuted),
        ],
      ),
    );
  }
}

class _OfflineBadge extends StatefulWidget {
  final bool isOffline;
  final VoidCallback onTap;

  const _OfflineBadge({
    required this.isOffline,
    required this.onTap,
  });

  @override
  State<_OfflineBadge> createState() => _OfflineBadgeState();
}

class _OfflineBadgeState extends State<_OfflineBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1, end: 0.4).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeBg = widget.isOffline ? UEColors.greenBg : UEColors.iconBg;
    final activeBorder = widget.isOffline ? UEColors.greenBorder : UEColors.border;
    final activeColor = widget.isOffline ? UEColors.green : UEColors.accent;
    final labelText = widget.isOffline ? 'Offline · Ready' : 'Online · Syncing';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: activeBg,
          border: Border.all(color: activeBorder, width: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _opacity,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              labelText,
              style: UETypography.inter(fontSize: 11, color: activeColor, fontWeight: FontWeight.w500),
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
    _BottomNavItem(icon: TablerIcons.home_2, label: 'Home'),
    _BottomNavItem(icon: TablerIcons.message_chatbot, label: 'Tutor'),
    _BottomNavItem(icon: TablerIcons.books, label: 'Library'),
    _BottomNavItem(icon: TablerIcons.school, label: 'Exam'),
    _BottomNavItem(icon: TablerIcons.world_search, label: 'Research'),
  ];

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: UEColors.bg,
        border: Border(
          top: BorderSide(color: UEColors.surface, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (i) {
            // Settings screen index is 5, highlight nothing in nav if 5 is selected.
            final active = i == selectedIndex;
            final item = _navItems[i];

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: active ? UEColors.accent : UEColors.textMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: UETypography.inter(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? UEColors.accent : UEColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

void main() {
  runApp(const UbuntuElimuApp());
}

class UbuntuElimuApp extends StatelessWidget {
  const UbuntuElimuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ubuntu Elimu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
      ),
      home: const HomeScreen(),
    );
  }
}

// ── Colour tokens ────────────────────────────────────────────────────────────
class UEColors {
  static const bg          = Color(0xFF0D0F14);
  static const surface     = Color(0xFF1A1D26);
  static const border      = Color(0xFF2D3147);
  static const iconBg      = Color(0xFF1E2340);
  static const textPrimary = Color(0xFFE8E9F0);
  static const textMuted   = Color(0xFF6B7280);
  static const accent      = Color(0xFF4F6EF7);
  static const violet      = Color(0xFFA78BFA);
  static const green       = Color(0xFF34D399);
  static const greenBg     = Color(0xFF0D1F17);
  static const greenBorder = Color(0xFF065F46);
  static const pdfBg       = Color(0xFF1E1616);
  static const pdfFg       = Color(0xFFF87171);
  static const pptxBg      = Color(0xFF1A1910);
  static const pptxFg      = Color(0xFFFBBF24);
  static const docxBg      = Color(0xFF101A1E);
  static const docxFg      = Color(0xFF60A5FA);
}

// ── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded,          label: 'Home'),
    _NavItem(icon: Icons.chat_bubble_outline,   label: 'Tutor'),
    _NavItem(icon: Icons.folder_copy_outlined,  label: 'Library'),
    _NavItem(icon: Icons.menu_book_outlined,    label: 'Exam'),
    _NavItem(icon: Icons.travel_explore,        label: 'Research'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UEColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Scrollable content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBar(),
                  const SizedBox(height: 16),
                  _Greeting(),
                  const SizedBox(height: 24),
                  _SessionCard(),
                  const SizedBox(height: 24),
                  _SectionLabel('Quick actions'),
                  const SizedBox(height: 12),
                  _QuickActions(),
                  const SizedBox(height: 28),
                  _SectionLabel('Recent uploads'),
                  const SizedBox(height: 12),
                  _RecentUploads(),
                ],
              ),
            ),
            // Bottom nav
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _BottomNav(
                items: _navItems,
                selectedIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status bar ───────────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('9:41',
            style: TextStyle(fontSize: 12, color: UEColors.textMuted)),
        _OfflineBadge(),
        const Icon(Icons.battery_3_bar, size: 18, color: UEColors.textMuted),
      ],
    );
  }
}

class _OfflineBadge extends StatefulWidget {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: UEColors.greenBg,
        border: Border.all(color: UEColors.greenBorder, width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: UEColors.green, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 5),
          const Text('Offline · Ready',
              style: TextStyle(fontSize: 11, color: UEColors.green)),
        ],
      ),
    );
  }
}

// ── Greeting ─────────────────────────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Good morning',
            style: TextStyle(fontSize: 13, color: UEColors.textMuted)),
        const SizedBox(height: 4),
        RichText(
          text: const TextSpan(
            style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: UEColors.textPrimary,
                height: 1.2),
            children: [
              TextSpan(text: 'What are we\nstudying '),
              TextSpan(text: 'today?',
                  style: TextStyle(color: UEColors.accent)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Session card ─────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: UEColors.surface,
          border: Border.all(color: UEColors.border, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: UEColors.iconBg,
                border: Border.all(color: UEColors.border, width: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: UEColors.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RESUME SESSION',
                      style: TextStyle(
                          fontSize: 11,
                          color: UEColors.accent,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.08 * 11)),
                  const SizedBox(height: 2),
                  const Text('Organic Chemistry — Ch.7',
                      style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: UEColors.textPrimary)),
                  const SizedBox(height: 2),
                  const Text('45 min ago · Power mode · EN→SW',
                      style: TextStyle(
                          fontSize: 12, color: UEColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: UEColors.border, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: UEColors.textMuted,
          letterSpacing: 0.1 * 11),
    );
  }
}

// ── Quick actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  static const _items = [
    _ActionData(
        icon: Icons.bolt,
        label: 'Ask Tutor',
        sub: 'Socratic mode on',
        violet: false),
    _ActionData(
        icon: Icons.upload_file_outlined,
        label: 'Upload Doc',
        sub: 'PDF, PPTX, DOCX',
        violet: true),
    _ActionData(
        icon: Icons.menu_book_outlined,
        label: 'Practice Exam',
        sub: 'Flashcards · Past papers',
        violet: false),
    _ActionData(
        icon: Icons.travel_explore,
        label: 'Research',
        sub: 'Build a report',
        violet: true),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _items.map(_ActionButton.new).toList(),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final String sub;
  final bool violet;
  const _ActionData(
      {required this.icon,
        required this.label,
        required this.sub,
        required this.violet});
}

class _ActionButton extends StatefulWidget {
  final _ActionData data;
  const _ActionButton(this.data, {super.key});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.data.violet ? UEColors.violet : UEColors.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: UEColors.surface,
            border: Border.all(
                color: _hovered ? accent : UEColors.border, width: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.data.icon, color: accent, size: 22),
              const Spacer(),
              Text(widget.data.label,
                  style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: UEColors.textPrimary)),
              const SizedBox(height: 2),
              Text(widget.data.sub,
                  style: const TextStyle(
                      fontSize: 11, color: UEColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent uploads ────────────────────────────────────────────────────────────
class _RecentUploads extends StatelessWidget {
  static const _docs = [
    _DocData(
        type: 'pdf',
        name: 'Biochem Lecture Notes — W4.pdf',
        meta: '2.4 MB · Added today',
        tag: 'New',
        tagColor: UEColors.accent),
    _DocData(
        type: 'pptx',
        name: 'Thermodynamics Slides.pptx',
        meta: '8.1 MB · Yesterday',
        tag: '12 cards',
        tagColor: UEColors.pptxFg),
    _DocData(
        type: 'docx',
        name: 'Research Handbook — APA.docx',
        meta: '1.1 MB · 3 days ago',
        tag: 'Active',
        tagColor: UEColors.docxFg),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _docs
          .map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _DocCard(data: d),
      ))
          .toList(),
    );
  }
}

class _DocData {
  final String type, name, meta, tag;
  final Color tagColor;
  const _DocData(
      {required this.type,
        required this.name,
        required this.meta,
        required this.tag,
        required this.tagColor});
}

class _DocCard extends StatelessWidget {
  final _DocData data;
  const _DocCard({required this.data, super.key});

  Color get _iconBg => switch (data.type) {
    'pdf'  => UEColors.pdfBg,
    'pptx' => UEColors.pptxBg,
    _      => UEColors.docxBg,
  };

  Color get _iconFg => switch (data.type) {
    'pdf'  => UEColors.pdfFg,
    'pptx' => UEColors.pptxFg,
    _      => UEColors.docxFg,
  };

  IconData get _icon => switch (data.type) {
    'pdf'  => Icons.picture_as_pdf_outlined,
    'pptx' => Icons.slideshow_outlined,
    _      => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: UEColors.surface,
          border: Border.all(color: UEColors.border, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: _iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(_icon, color: _iconFg, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: UEColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(data.meta,
                      style: const TextStyle(
                          fontSize: 11, color: UEColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: UEColors.iconBg,
                border: Border.all(color: UEColors.border, width: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(data.tag,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: data.tagColor)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: UEColors.bg,
        border: Border(top: BorderSide(color: UEColors.surface, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == selectedIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].icon,
                          size: 22,
                          color: active ? UEColors.accent : UEColors.border),
                      const SizedBox(height: 4),
                      Text(items[i].label,
                          style: TextStyle(
                              fontSize: 10,
                              color: active
                                  ? UEColors.accent
                                  : UEColors.border)),
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
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../models/code_action.dart';

class DiffViewSheet extends StatelessWidget {
  final List<DiffLine> diff;
  final String title;
  final VoidCallback onAccept;
  final VoidCallback onUndo;

  const DiffViewSheet({
    super.key,
    required this.diff,
    required this.title,
    required this.onAccept,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF11141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: UEColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: UEColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.difference_outlined, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Edit Inspection',
                      style: UETypography.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: UEColors.textPrimary,
                      ),
                    ),
                    Text(
                      title,
                      style: UETypography.inter(fontSize: 11, color: UEColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(TablerIcons.x, size: 20, color: UEColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Diff Lines Box
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF080B12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: UEColors.border),
              ),
              child: diff.isEmpty
                  ? Center(
                      child: Text(
                        'Full file scaffold or rewrite applied.',
                        style: UETypography.inter(fontSize: 12, color: UEColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: diff.length,
                      itemBuilder: (context, index) {
                        final item = diff[index];
                        final isAdded = item.type == DiffType.added;
                        final isRemoved = item.type == DiffType.removed;

                        final bgColor = isAdded
                            ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                            : isRemoved
                                ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
                                : Colors.transparent;

                        final textColor = isAdded
                            ? const Color(0xFF34D399)
                            : isRemoved
                                ? const Color(0xFFF87171)
                                : const Color(0xFF94A3B8);

                        final prefix = isAdded
                            ? '+ '
                            : isRemoved
                                ? '- '
                                : '  ';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$prefix${item.text}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 14),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF87171),
                    side: const BorderSide(color: Color(0xFF7F1D1D)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    onUndo();
                    Navigator.pop(context);
                  },
                  icon: const Icon(TablerIcons.arrow_back_up, size: 16),
                  label: const Text('Undo Edit', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UEColors.green,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    onAccept();
                    Navigator.pop(context);
                  },
                  icon: const Icon(TablerIcons.check, size: 16),
                  label: const Text('Keep Changes 🚀', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

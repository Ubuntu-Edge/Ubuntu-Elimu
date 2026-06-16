import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../providers/session_provider.dart';

class DocContextBar extends StatelessWidget {
  const DocContextBar({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(color: UEColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            TablerIcons.sparkles,
            color: UEColors.accent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Active: ${sessionProvider.activeSessionTitle}',
              overflow: TextOverflow.ellipsis,
              style: UETypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: UEColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              sessionProvider.updateActiveSession(
                'Organic Chemistry — Ch.7',
                '45 min ago · Power mode · EN→SW',
              );
            },
            child: const Icon(
              TablerIcons.x,
              color: UEColors.textMuted,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

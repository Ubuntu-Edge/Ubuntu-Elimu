import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

class CitationCard extends StatelessWidget {
  final String title;

  const CitationCard({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: UEColors.iconBg,
        border: Border.all(color: UEColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            TablerIcons.file_text,
            color: UEColors.accent,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: UETypography.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: UEColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

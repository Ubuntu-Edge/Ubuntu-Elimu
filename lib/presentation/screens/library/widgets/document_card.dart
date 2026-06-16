import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../models/document.dart';
import 'file_action_sheet.dart';

class DocumentCard extends StatelessWidget {
  final Document doc;

  const DocumentCard({
    required this.doc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = FileUtils.getIconBg(doc.fileType);
    final iconFg = FileUtils.getIconFg(doc.fileType);
    final icon = FileUtils.getIcon(doc.fileType);
    final sizeStr = FileUtils.formatBytes(doc.sizeBytes);
    final timeStr = DateUtilsHelper.getRelativeTime(doc.uploadTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(color: UEColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconFg, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  overflow: TextOverflow.ellipsis,
                  style: UETypography.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: UEColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sizeStr · $timeStr',
                  style: UETypography.inter(
                    fontSize: 11,
                    color: UEColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: UEColors.bg,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => FileActionSheet(doc: doc),
              );
            },
            child: Icon(
              TablerIcons.dots_vertical,
              color: UEColors.textMuted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

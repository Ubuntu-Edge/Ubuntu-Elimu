import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../providers/session_provider.dart';
import '../../../../providers/navigation_provider.dart';
import '../../tutor/widgets/chat_history_sheet.dart';

class RecentChatsList extends StatelessWidget {
  const RecentChatsList({super.key});

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final navProvider = context.read<NavigationProvider>();
    final sessions = sessionProvider.sessions;

    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT CONVERSATIONS (${sessions.length})',
              style: UETypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: UEColors.textMuted,
                letterSpacing: 1.1,
              ),
            ),
            GestureDetector(
              onTap: () => ChatHistorySheet.show(context),
              child: Text(
                'View All',
                style: UETypography.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: UEColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.take(4).length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = sessions[index];
            final isActive = s.id == sessionProvider.currentSessionId;

            return InkWell(
              onTap: () {
                sessionProvider.switchSession(s.id);
                navProvider.setIndex(2); // Jump to Tutor
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? UEColors.accent.withValues(alpha: 0.08) : UEColors.surface,
                  border: Border.all(
                    color: isActive ? UEColors.accent.withValues(alpha: 0.3) : UEColors.border,
                    width: isActive ? 1.0 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isActive ? UEColors.accent.withValues(alpha: 0.15) : UEColors.bgPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isActive ? TablerIcons.message_dots : TablerIcons.message_2,
                        size: 18,
                        color: isActive ? UEColors.accent : UEColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.title,
                                  style: UETypography.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                    color: UEColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: UEColors.accent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s.previewText,
                            style: UETypography.inter(
                              fontSize: 11,
                              color: UEColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(TablerIcons.clock, size: 10, color: UEColors.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                _formatTimestamp(s.updatedAt),
                                style: UETypography.inter(
                                  fontSize: 9.5,
                                  color: UEColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(fontSize: 9.5, color: UEColors.textMuted)),
                              const SizedBox(width: 8),
                              Text(
                                '${s.messages.length} ${s.messages.length == 1 ? "message" : "messages"}',
                                style: UETypography.inter(
                                  fontSize: 9.5,
                                  color: UEColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(TablerIcons.chevron_right, size: 16, color: UEColors.textMuted),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

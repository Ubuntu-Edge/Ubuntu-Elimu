import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../models/chat_message.dart';
import 'citation_card.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                _buildAvatar(),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: message.isUser ? UEColors.accent : UEColors.surface,
                        border: Border.all(
                          color: message.isUser ? UEColors.accent : UEColors.border,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: message.isUser ? const Radius.circular(14) : Radius.zero,
                          bottomRight: message.isUser ? Radius.zero : const Radius.circular(14),
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: UETypography.inter(
                          fontSize: 13.5,
                          color: message.isUser ? Colors.white : UEColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (!message.isUser && message.citations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildCitations(),
                    ],
                  ],
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 10),
                _buildUserAvatar(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: UEColors.iconBg,
        border: Border.all(color: UEColors.border, width: 0.5),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        TablerIcons.brain,
        color: UEColors.accent,
        size: 14,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(color: UEColors.border, width: 0.5),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        TablerIcons.user,
        color: UEColors.textMuted,
        size: 14,
      ),
    );
  }

  Widget _buildCitations() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: message.citations.map((cit) => CitationCard(title: cit)).toList(),
    );
  }
}

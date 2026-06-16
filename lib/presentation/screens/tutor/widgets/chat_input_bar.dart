import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../providers/session_provider.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    Provider.of<SessionProvider>(context, listen: false).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: UEColors.bg,
        border: Border(
          top: BorderSide(color: UEColors.surface, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Reset / Clear button
            GestureDetector(
              onTap: () {
                sessionProvider.clearChat();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Conversation reset'),
                    backgroundColor: UEColors.surface,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: UEColors.surface,
                  border: Border.all(color: UEColors.border, width: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  TablerIcons.refresh,
                  color: UEColors.textMuted,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Input Field container
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: UEColors.surface,
                  border: Border.all(color: UEColors.border, width: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: UETypography.inter(fontSize: 13, color: UEColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Ask Socratic AI...',
                          hintStyle: UETypography.inter(fontSize: 13, color: UEColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    // Simulate Voice Icon
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Offline Dictation listening...'),
                            backgroundColor: UEColors.surface,
                          ),
                        );
                      },
                      child: Icon(
                        TablerIcons.microphone,
                        color: UEColors.textMuted,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: sessionProvider.isGenerating ? null : _submit,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: sessionProvider.isGenerating ? UEColors.surface : UEColors.accent,
                  shape: BoxShape.circle,
                ),
                child: sessionProvider.isGenerating
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: UEColors.accent,
                        ),
                      )
                    : const Icon(
                        TablerIcons.send,
                        color: Colors.white,
                        size: 16,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

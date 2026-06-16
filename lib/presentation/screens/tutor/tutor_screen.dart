import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../providers/session_provider.dart';
import 'widgets/model_lang_controls.dart';
import 'widgets/doc_context_bar.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    // Whenever message list size changes, scroll down
    _scrollToBottom();

    return Column(
      children: [
        const ModelLangControls(),
        const DocContextBar(),
        Expanded(
          child: Container(
            color: UEColors.bg,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: sessionProvider.chatMessages.length,
              itemBuilder: (context, index) {
                final message = sessionProvider.chatMessages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
        ),
        const ChatInputBar(),
      ],
    );
  }
}

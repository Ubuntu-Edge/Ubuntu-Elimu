import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/chat_message.dart';
import '../tutor/widgets/chat_bubble.dart';
import '../tutor/widgets/chat_input_bar.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        id: 'welcome',
        role: MessageRole.ai,
        content: "Hello! I'm your AI Study Companion. How can I assist you today?",
        timestamp: DateTime.now(),
      ),
    );
  }

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
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic, // Smoother ChatGPT-style scroll animation
        );
      }
    });
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.user,
        content: text,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulated ChatGPT Dynamic Response
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.ai,
          content: _generateChatGPTStyleResponse(text),
          timestamp: DateTime.now(),
          model: ModelMode.power, // Keeping your high-performance model tier indicator
        ));
      });
      _scrollToBottom();
    });
  }

  /// Simulates a highly adaptive, multi-disciplinary ChatGPT response.
  String _generateChatGPTStyleResponse(String query) {
    final lower = query.toLowerCase();

    // 1. Math / Science
    if (lower.contains('solve') || lower.contains('math') || lower.contains('equation') || lower.contains('physics')) {
      return "***📐 Step-by-Step Breakdown***\n\n"
          "I can absolutely help you solve and understand this concept. Let's look at the underlying framework:\n\n"
          "1. **Identify the Given Data**: Extract your known variables.\n"
          "2. **Apply the Formula**: We isolate the variable we are looking for.\n"
          "3. **Execution**: Calculate carefully step-by-step to avoid simple arithmetic mistakes.\n\n"
          "Study Tip: Don't just look at the answer—focus on the method so you can crush it on your exam. Paste the exact problem numbers below and we'll solve it together!";
    }

    // 2. Coding / Computer Science
    if (lower.contains('code') || lower.contains('flutter') || lower.contains('programming') || lower.contains('bug')) {
      return "***💻 Code Analysis & Structure***\n\n"
          "Let's look at how to approach this programmatically. For clean, maintainable architecture, remember to:\n\n"
          "• **Separate Concerns**: Keep logic separate from your UI views.\n"
          "• **Handle Edge Cases**: Ensure null safety and unexpected user inputs don't crash your app.\n\n"
          "Drop your code snippet or error logs right here, and I will refactor it, find the bugs, and explain the fix!";
    }

    // 3. History / Literature / Essays
    if (lower.contains('write') || lower.contains('essay') || lower.contains('history') || lower.contains('summary')) {
      return "***📝 Writing & Analysis Framework***\n\n"
          "Let's elevate this piece. To make your arguments highly compelling, I can help you structure it using a thesis-driven format:\n\n"
          "• **The Hook & Thesis**: Grab the reader and declare your stance.\n"
          "• **Evidence Blocks**: Contextualize historical events or literature quotes.\n"
          "• **The Counter-Argument**: Acknowledging opposing views makes your essay twice as strong.\n\n"
          "Give me your rough ideas, a paragraph you've already written, or your essay prompt, and I'll help you draft or refine it!";
    }

    // 4. Brainstorming / Strategy
    if (lower.contains('brainstorm') || lower.contains('ideas') || lower.contains('topic') || lower.contains('project')) {
      return "***💡 Brainstorming Session***\n\n"
          "Awesome. Finding a great angle is half the battle. Here are three distinct directions we could take this project:\n\n"
          "1. **The Modern Lens**: Evaluating this subject against recent technology or global trends.\n"
          "2. **The Case-Study Approach**: Focusing deeply on one real-world company, historical event, or scientific anomaly.\n"
          "3. **The Creative Solution**: Proposing an original fix to a problem hidden within this topic.\n\n"
          "Tell me which direction feels exciting, or tell me your class subject and we'll generate completely fresh ideas!";
    }

    // 5. Default General-Purpose AI response
    return "***🔮 How should we approach this?***\n\n"
        "I've processed your request. To tailor my assistance perfectly to your school guidelines, tell me what you need next:\n\n"
        "• Do you want a **comprehensive breakdown** or a **quick summary**?\n"
        "• Do you need a **step-by-step guide** or should I just **check your work**?\n\n"
        "I'm ready when you are. Let's make this assignment easy!";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UEColors.bgPrimary,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const TypingIndicator(); // Ensure this is styled cleanly
                }
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          ChatInputBar(
            onSend: _handleSend,
            isTyping: _isTyping,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(
          bottom: BorderSide(color: UEColors.bgCard, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Study Companion', style: UETypography.h3),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: UEColors.indigo.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'GPT-4',
                        style: UETypography.caption.copyWith(
                          color: UEColors.indigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online & Adaptive',
                      style: UETypography.caption.copyWith(
                        color: UEColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: UEColors.textDim, size: 20),
              tooltip: 'Clear Chat',
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _addWelcomeMessage();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/chat_message.dart';
import '../../../services/offline_ai_service.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/ai/base_ai_provider.dart';
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

    _streamAIResponse(text);
  }

  void _streamAIResponse(String userMessage) {
    final settings = context.read<SettingsProvider>();
    final aiProvider = settings.getAIProvider();

    if (settings.activeBackend == AIBackend.local && !settings.isModelDownloaded) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.ai,
          content: '⚠️ No model loaded. Please download and activate a model in Settings.',
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
      return;
    }

    // Add empty AI message to stream tokens into
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        id: aiMessageId,
        role: MessageRole.ai,
        content: '',
        timestamp: DateTime.now(),
      ));
    });

    final stream = aiProvider.streamGenerate(
      userMessage,
      systemPrompt: 'You are a helpful AI study companion for students. Be concise, clear, and educational.',
    );

    stream.listen(
          (token) {
        if (!mounted) return;
        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              content: _messages[index].content + token,
            );
          }
        });
        _scrollToBottom();
      },
      onDone: () => _scrollToBottom(),
      onError: (e) {
        if (!mounted) return;
        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              content: '❌ Error: $e',
            );
          }
        });
      },
    );
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
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
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
    final hasModel = OfflineAIService.instance.isModelLoaded;
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
                        hasModel ? 'Local LLM' : 'No Engine',
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
                      decoration: BoxDecoration(
                        color: hasModel ? Colors.green : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasModel ? 'Offline & Active' : 'Model Offline',
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
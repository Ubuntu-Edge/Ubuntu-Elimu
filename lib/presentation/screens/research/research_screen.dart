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
  bool _isStreaming = false;

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

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty || _isStreaming) return;

    // Prefix user IDs to avoid collision with AI message IDs
    final userMsgId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _messages.add(ChatMessage(
        id: userMsgId,
        role: MessageRole.user,
        content: text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    _streamAIResponse(text);
  }

  void _streamAIResponse(String userMessage) {
    final settings = context.read<SettingsProvider>();
    final aiProvider = settings.getAIProvider();

    if (settings.activeBackend == AIBackend.local && !settings.isModelDownloaded) {
      setState(() {
        _messages.add(ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.ai,
          content: '⚠️ No model loaded. Please download and activate a model in Settings.',
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
      return;
    }

    if (settings.activeBackend == AIBackend.groq && settings.groqApiKey.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.ai,
          content: '⚠️ Groq API key is missing. Please check your settings.',
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
      return;
    }

    // Prefix AI IDs to guarantee no collision with user message IDs
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _isStreaming = true;
      _messages.add(ChatMessage(
        id: aiMsgId,
        role: MessageRole.ai,
        content: '',
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    aiProvider.streamGenerate(
      userMessage,
      systemPrompt:
          'You are Elimu, a helpful AI study companion for students. '
          'Be concise, clear, and educational. Use markdown formatting where helpful.',
      maxTokens: 1024,
    ).listen(
      (token) {
        if (!mounted) return;
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == aiMsgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              content: _messages[idx].content + token,
            );
          }
        });
        _scrollToBottom(animate: false);
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isStreaming = false;
          final idx = _messages.indexWhere((m) => m.id == aiMsgId);
          if (idx != -1 && _messages[idx].content.trim().isEmpty) {
            _messages[idx] = _messages[idx].copyWith(
              content: '❌ No response received. Please check your API key or try again.',
            );
          }
        });
        _scrollToBottom();
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _isStreaming = false;
          final idx = _messages.indexWhere((m) => m.id == aiMsgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
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
            isTyping: _isStreaming,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final isLocal = settings.activeBackend == AIBackend.local;
        final hasEngine = isLocal
            ? OfflineAIService.instance.isModelLoaded
            : settings.groqApiKey.isNotEmpty;
        final engineName = isLocal ? 'Local LLM' : 'Groq Cloud';

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
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: UEColors.indigo.withOpacity(0.35),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Study Companion', style: UETypography.h3),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: UEColors.indigo.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasEngine ? engineName : 'No Engine',
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
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: hasEngine ? Colors.green : Colors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasEngine ? 'Active & Ready' : 'Engine Offline',
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
                  icon: const Icon(Icons.refresh_rounded,
                      color: UEColors.textDim, size: 20),
                  tooltip: 'Clear Chat',
                  onPressed: () {
                    setState(() {
                      _messages.clear();
                      _isStreaming = false;
                      _addWelcomeMessage();
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

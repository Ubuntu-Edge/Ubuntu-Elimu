import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/offline_model_provider.dart';
import '../../../services/offline_ai_service.dart';

class ResearchMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? sources;
  final bool isStreaming;

  ResearchMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.isStreaming = false,
  });

  ResearchMessage copyWith({
    String? text,
    bool? isStreaming,
    List<String>? sources,
  }) {
    return ResearchMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      sources: sources ?? this.sources,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ResearchMessage> _messages = [];
  
  bool _isGenerating = false;
  bool _useLibraryGrounding = true;
  String? _error;
  StreamSubscription<String>? _streamSub;

  final List<Map<String, String>> _suggestions = [
    {
      'icon': '💡',
      'title': 'Quantum Computing',
      'prompt': 'Explain quantum computing in simple terms for a student.',
    },
    {
      'icon': '🧬',
      'title': 'Photosynthesis vs Respiration',
      'prompt': 'Compare photosynthesis and cellular respiration in detail.',
    },
    {
      'icon': '📜',
      'title': 'Causes of World War I',
      'prompt': 'Summarize the main geopolitical causes and timeline of World War I.',
    },
    {
      'icon': '🤖',
      'title': 'Transformer Neural Networks',
      'prompt': 'How do self-attention and transformer models work in AI?',
    },
  ];

  @override
  void dispose() {
    _streamSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    _streamSub?.cancel();
    setState(() {
      _messages.clear();
      _isGenerating = false;
      _error = null;
    });
  }

  Future<void> _sendMessage(String userPrompt) async {
    final trimmed = userPrompt.trim();
    if (trimmed.isEmpty || _isGenerating) return;

    final modelProvider = context.read<OfflineModelProvider>();
    if (!modelProvider.hasActiveModel) {
      setState(() => _error = 'No AI model loaded — activate one in Settings first.');
      return;
    }

    _textController.clear();

    final userMsg = ResearchMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final aiMsg = ResearchMessage(
      id: aiMsgId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _error = null;
      _messages.add(userMsg);
      _messages.add(aiMsg);
      _isGenerating = true;
    });
    _scrollToBottom();

    // Collect grounding context from library docs if enabled
    List<String> contextChunks = [];
    List<String> sourceNames = [];

    if (_useLibraryGrounding) {
      final docProvider = context.read<DocumentProvider>();
      final related = docProvider.findRelevantAcrossLibrary(trimmed);
      contextChunks = related.expand((e) => e.value).toList();
      sourceNames = related.map((e) => e.key.name).toList();
    }

    final systemPrompt = contextChunks.isNotEmpty
        ? 'You are a brilliant research assistant. Provide thorough, well-structured, '
            'accurate answers formatted in clear markdown. Ground your response in the '
            'following study documents:\n\n${contextChunks.join("\n\n---\n\n")}'
        : 'You are a brilliant research assistant. Provide thorough, well-structured, '
            'accurate, and engaging answers formatted in clear markdown for the user.';

    try {
      final stream = OfflineAIService.instance.generateResponseStream(
        prompt: trimmed,
        systemPrompt: systemPrompt,
        maxTokens: 1000,
        temperature: 0.7,
      );

      String accumulated = '';

      _streamSub = stream.listen(
        (chunk) {
          accumulated += chunk;
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == aiMsgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                text: accumulated,
                sources: sourceNames.isNotEmpty ? sourceNames : null,
              );
            }
          });
          _scrollToBottom();
        },
        onError: (err) {
          setState(() {
            _isGenerating = false;
            _error = 'Error stream: $err';
          });
        },
        onDone: () {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == aiMsgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                isStreaming: false,
                sources: sourceNames.isNotEmpty ? sourceNames : null,
              );
            }
            _isGenerating = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _error = 'Failed to generate response: $e';
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied response to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: UEColors.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelProvider = context.watch<OfflineModelProvider>();

    return Scaffold(
      backgroundColor: UEColors.bgPrimary,
      body: Column(
        children: [
          // ChatGPT Header Bar
          _buildHeader(modelProvider),

          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: UEColors.pdfBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: UEColors.pdfFg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: UETypography.inter(fontSize: 11, color: UEColors.pdfFg),
                    ),
                  ),
                ],
              ),
            ),

          // Main Chat Area / Empty Suggestion State
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(modelProvider)
                : _buildMessageList(),
          ),

          // Floating Input Bar
          _buildInputBar(modelProvider),
        ],
      ),
    );
  }

  Widget _buildHeader(OfflineModelProvider modelProvider) {
    final activeModelName = modelProvider.activeModel?.name ?? 'No Model Active';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(bottom: BorderSide(color: UEColors.bgCard, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: UEColors.indigo.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              TablerIcons.sparkles,
              color: UEColors.indigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Research',
                style: UETypography.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: UEColors.textPrimary,
                ),
              ),
              Text(
                activeModelName,
                style: UETypography.inter(
                  fontSize: 11,
                  color: UEColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_messages.isNotEmpty)
            IconButton(
              onPressed: _clearChat,
              icon: const Icon(TablerIcons.plus, size: 20, color: UEColors.textMuted),
              tooltip: 'New Chat',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(OfflineModelProvider modelProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: UEColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: UEColors.border, width: 0.5),
            ),
            child: const Icon(
              TablerIcons.robot,
              size: 32,
              color: UEColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'What would you like to research?',
            textAlign: TextAlign.center,
            style: UETypography.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: UEColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask any question. Get deep, structured answers powered 100% offline by your local Denizen engine.',
            textAlign: TextAlign.center,
            style: UETypography.inter(
              fontSize: 13,
              color: UEColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SUGGESTED TOPICS',
              style: UETypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: UEColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.45,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, i) {
              final item = _suggestions[i];
              return InkWell(
                onTap: () => _sendMessage(item['prompt']!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UEColors.surface,
                    border: Border.all(color: UEColors.border, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['icon']!, style: const TextStyle(fontSize: 18)),
                      const Spacer(),
                      Text(
                        item['title']!,
                        style: UETypography.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: UEColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildChatBubble(msg);
      },
    );
  }

  Widget _buildChatBubble(ResearchMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 48, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: UEColors.indigo.withOpacity(0.18),
            border: Border.all(color: UEColors.indigo.withOpacity(0.3), width: 0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.text,
            style: UETypography.inter(
              fontSize: 14,
              color: UEColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // AI Response Bubble
    return Container(
      margin: const EdgeInsets.only(right: 24, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: UEColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: UEColors.border, width: 0.5),
            ),
            child: const Icon(
              TablerIcons.sparkles,
              size: 16,
              color: UEColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Research Assistant',
                      style: UETypography.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: UEColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (!msg.isStreaming && msg.text.isNotEmpty)
                      IconButton(
                        onPressed: () => _copyToClipboard(msg.text),
                        icon: const Icon(TablerIcons.copy, size: 16, color: UEColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: UEColors.surface,
                    border: Border.all(color: UEColors.border, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.text.isEmpty && msg.isStreaming)
                        Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: UEColors.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Thinking & researching…',
                              style: UETypography.inter(
                                fontSize: 13,
                                color: UEColors.textMuted,
                              ),
                            ),
                          ],
                        )
                      else
                        SelectableText(
                          msg.text,
                          style: UETypography.inter(
                            fontSize: 14,
                            color: UEColors.textPrimary,
                            height: 1.5,
                          ),
                        ),

                      if (msg.sources != null && msg.sources!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: UEColors.border, height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(TablerIcons.file_text, size: 14, color: UEColors.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Grounded in library: ${msg.sources!.join(", ")}',
                                style: UETypography.inter(
                                  fontSize: 11,
                                  color: UEColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(OfflineModelProvider modelProvider) {
    final isEnabled = modelProvider.hasActiveModel;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(top: BorderSide(color: UEColors.bgCard, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Library Grounding Pill
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _useLibraryGrounding = !_useLibraryGrounding),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _useLibraryGrounding
                          ? UEColors.accent.withOpacity(0.12)
                          : UEColors.surface,
                      border: Border.all(
                        color: _useLibraryGrounding ? UEColors.accent : UEColors.border,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          TablerIcons.books,
                          size: 14,
                          color: _useLibraryGrounding ? UEColors.accent : UEColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _useLibraryGrounding ? 'Library Grounding: ON' : 'Library Grounding: OFF',
                          style: UETypography.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _useLibraryGrounding ? UEColors.accent : UEColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ChatGPT Style Input Field
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: UEColors.surface,
                      border: Border.all(color: UEColors.border, width: 0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      enabled: isEnabled && !_isGenerating,
                      minLines: 1,
                      maxLines: 4,
                      style: UETypography.inter(fontSize: 14, color: UEColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: isEnabled
                            ? 'Ask anything (e.g. quantum physics, calculus)...'
                            : 'Activate a model in Settings to ask...',
                        hintStyle: UETypography.inter(fontSize: 13, color: UEColors.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) => _sendMessage(val),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isEnabled && !_isGenerating
                      ? () => _sendMessage(_textController.text)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: isEnabled && !_isGenerating ? UEColors.indigo : UEColors.surface,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(TablerIcons.send, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

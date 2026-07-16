import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/chat_message.dart';
import '../../../models/document.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/offline_ai_service.dart';
import '../../../services/ai/base_ai_provider.dart';
import 'widgets/doc_context_bar.dart';
import 'widgets/model_lang_controls.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/language_sheet.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final ScrollController _scrollController = ScrollController();

  Language _language = Language.english;
  bool _socraticMode = true;

  Document? _activeDoc;
  String? _activeDocId;
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      setState(() => _socraticMode = settings.socraticMode);

      // Auto-select most recent document (unfiltered list)
      final allDocs = context.read<DocumentProvider>().allDocuments;
      if (allDocs.isNotEmpty) {
        final doc = allDocs.first;
        setState(() {
          _activeDoc = doc;
          _activeDocId = doc.id;
        });
      }

      _addWelcomeMessage();
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        id: 'welcome',
        role: MessageRole.ai,
        content: _activeDoc != null
            ? "I'm ready to help you study **${_activeDoc!.name}**. What would you like to explore?"
            : "Hi! I'm your AI Tutor. Upload a document from the Library to get started, or ask me anything.",
        timestamp: DateTime.now(),
        language: _language,
      ));
    });
  }

  void _updateWelcomeMessage(Document doc) {
    setState(() {
      final welcomeIdx = _messages.indexWhere((m) => m.id == 'welcome');
      final updated = ChatMessage(
        id: 'welcome',
        role: MessageRole.ai,
        content:
            "I'm ready to help you study **${doc.name}**. What would you like to explore?",
        timestamp: DateTime.now(),
        language: _language,
      );
      if (welcomeIdx != -1) {
        _messages[welcomeIdx] = updated;
      } else {
        _messages.insert(0, updated);
      }
    });
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
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
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
          language: _language,
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
          language: _language,
        ));
      });
      _scrollToBottom();
      return;
    }

    // ── RAG: fetch chunks BEFORE mutating state ────────────────────────────
    // Always look up the document fresh from the provider by ID so we get
    // the latest processed state — the local _activeDoc ref may be stale.
    List<String> contextChunks = [];
    if (_activeDocId != null) {
      final docProvider = context.read<DocumentProvider>();
      final liveDoc = docProvider.getDocumentById(_activeDocId!);
      if (liveDoc != null && liveDoc.isProcessed && liveDoc.chunks.isNotEmpty) {
        contextChunks = docProvider.getRelevantChunks(
          _activeDocId!,
          userMessage,
          topK: 4,
        );
      }
    }

    final systemPrompt = _buildSystemPrompt(contextChunks);

    // Use a prefixed unique ID to avoid collision with user message IDs
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _isStreaming = true;
      _messages.add(ChatMessage(
        id: aiMsgId,
        role: MessageRole.ai,
        content: '',
        timestamp: DateTime.now(),
        language: _language,
      ));
    });
    _scrollToBottom();

    aiProvider.streamGenerate(
      userMessage,
      systemPrompt: systemPrompt,
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
          // If we finished with empty content, show an error
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
              content: '❌ Generation error: $e',
            );
          }
        });
      },
    );
  }

  String _buildSystemPrompt(List<String> contextChunks) {
    final langInstruction = switch (_language) {
      Language.swahili => 'Respond in Kiswahili.',
      Language.french   => 'Respond in French.',
      Language.english  => 'Respond in English.',
    };

    final socraticInstruction = _socraticMode
        ? 'Use the Socratic method — guide the student with thoughtful questions rather than giving direct answers.'
        : 'Give clear, direct, well-structured explanations.';

    final String docContext;
    if (contextChunks.isNotEmpty) {
      docContext =
          'The student is studying a document. Here are the most relevant excerpts:\n\n'
          '---\n'
          '${contextChunks.join('\n\n---\n')}\n'
          '---\n\n'
          'Base your answer on these excerpts where relevant. '
          'If the answer is not in the excerpts, say so and answer from general knowledge.\n\n';
    } else if (_activeDocId != null) {
      docContext =
          'Note: The student has a document selected but its content is still being processed. '
          'Answer from general knowledge for now.\n\n';
    } else {
      docContext = '';
    }

    return '${docContext}You are Elimu, a helpful and encouraging AI tutor. '
        '$socraticInstruction $langInstruction Be concise and educational.';
  }

  void _showDocPicker() {
    final docs = context.read<DocumentProvider>().allDocuments;
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No documents yet — upload one from the Library.'),
          backgroundColor: UEColors.bgCard,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: UEColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: UEColors.bgBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('Choose Document', style: UETypography.h3.copyWith(fontSize: 15)),
          ),
          ...docs.map((doc) => ListTile(
            leading: Icon(
              doc.type == DocType.pdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.description_rounded,
              color: doc.type == DocType.pdf ? UEColors.pdfColor : UEColors.docxColor,
              size: 20,
            ),
            title: Text(doc.name, style: UETypography.body.copyWith(fontSize: 13)),
            subtitle: Text(
              doc.isProcessed ? 'Ready' : 'Processing...',
              style: UETypography.caption.copyWith(
                color: doc.isProcessed ? UEColors.green : UEColors.textDim,
                fontSize: 10,
              ),
            ),
            onTap: () {
              setState(() {
                _activeDoc = doc;
                _activeDocId = doc.id;
              });
              _updateWelcomeMessage(doc);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _isStreaming = false;
    });
    _addWelcomeMessage();
  }

  void _openCitation(CitationRef citation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${citation.docName} p.${citation.page}'),
        backgroundColor: UEColors.bgCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UEColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return ChatBubble(
                    message: msg,
                    onCitationTap: msg.citation != null
                        ? () => _openCitation(msg.citation!)
                        : null,
                  );
                },
              ),
            ),
            ChatInputBar(
              onSend: _handleSend,
              isTyping: _isStreaming,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(
          bottom: BorderSide(color: UEColors.bgCard, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          children: [
            // ── Top row: back / title / actions ──
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: UEColors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: UEColors.bgBorder, width: 0.5),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: UEColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
                const Spacer(),
                // Elimu avatar + title
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: UEColors.indigo.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('AI Tutor', style: UETypography.h3),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _clearChat,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: UEColors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: UEColors.bgBorder, width: 0.5),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: UEColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Document context bar ──
            DocContextBar(activeDoc: _activeDoc, onChangeTap: _showDocPicker),
            const SizedBox(height: 10),

            // ── Language + Socratic ──
            ModelLangControls(
              selectedLanguage: _language,
              socraticMode: _socraticMode,
              onLanguageTap: () => LanguageSheet.show(
                context,
                current: _language,
                onSelected: (l) => setState(() => _language = l),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

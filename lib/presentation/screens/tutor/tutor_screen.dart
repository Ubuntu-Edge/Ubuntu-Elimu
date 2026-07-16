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

  ModelMode _model = ModelMode.power;
  Language _language = Language.english;
  bool _socraticMode = true;

  Document? _activeDoc;
  String? _activeDocId; // track by ID to always fetch fresh from provider
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Read socratic mode from SettingsProvider
      final settings = context.read<SettingsProvider>();
      setState(() => _socraticMode = settings.socraticMode);

      // Auto-select most recent document
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
        model: _model,
        language: _language,
      ));
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
          // Jump immediately during streaming so the view follows tokens
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
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
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.ai,
          content: '⚠️ No model loaded. Please download and activate a model in Settings.',
          timestamp: DateTime.now(),
          model: _model,
          language: _language,
        ));
      });
      _scrollToBottom();
      return;
    }
    
    if (settings.activeBackend == AIBackend.groq && settings.groqApiKey.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.ai,
          content: '⚠️ Groq API key is missing. Please check your settings.',
          timestamp: DateTime.now(),
          model: _model,
          language: _language,
        ));
      });
      _scrollToBottom();
      return;
    }

    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _messages.add(ChatMessage(
        id: aiMessageId,
        role: MessageRole.ai,
        content: '',
        timestamp: DateTime.now(),
        model: _model,
        language: _language,
      ));
    });

    // Get relevant chunks from active document for RAG.
    // Always look up the document fresh from the provider (by ID) so we get
    // the latest processed state with all chunks — the local _activeDoc ref
    // may be stale if processing completed after selection.
    List<String> contextChunks = [];
    if (_activeDocId != null) {
      final docProvider = context.read<DocumentProvider>();
      final liveDoc = docProvider.getDocumentById(_activeDocId!);
      if (liveDoc != null && liveDoc.isProcessed && liveDoc.chunks.isNotEmpty) {
        contextChunks = docProvider.getRelevantChunks(_activeDocId!, userMessage);
      }
    }

    final systemPrompt = _buildSystemPrompt(contextChunks);

    aiProvider.streamGenerate(
      userMessage,
      systemPrompt: systemPrompt,
    ).listen(
          (token) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              content: _messages[index].content + token,
            );
          }
        });
        // Use jump (no animation) during streaming so the view reliably follows
        _scrollToBottom(animate: false);
      },
      onError: (e) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
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
        ? 'Use the Socratic method — guide with questions rather than giving direct answers.'
        : 'Give clear, direct explanations.';

    final docContext = contextChunks.isNotEmpty
        ? 'Use this context from the student\'s document:\n\n${contextChunks.join('\n\n')}\n\n'
        : '';

    return '${docContext}You are a helpful AI tutor. $socraticInstruction $langInstruction Be concise.';
  }

  void _showDocPicker() {
    // Always use allDocuments (unfiltered) so search/category state doesn't
    // hide documents from the picker
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
      builder: (_) => ListView(
        shrinkWrap: true,
        children: docs.map((doc) => ListTile(
          title: Text(doc.name, style: UETypography.body),
          subtitle: Text(
            doc.isProcessed ? 'Ready' : 'Processing...',
            style: UETypography.caption.copyWith(
              color: doc.isProcessed ? UEColors.green : UEColors.textDim,
            ),
          ),
          onTap: () {
            setState(() {
              _activeDoc = doc;
              _activeDocId = doc.id;
            });
            // Update welcome message to reflect the newly selected document
            _updateWelcomeMessage(doc);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  /// Replaces the initial welcome message with one referencing the new doc.
  void _updateWelcomeMessage(Document doc) {
    setState(() {
      final welcomeIdx = _messages.indexWhere((m) => m.id == 'welcome');
      final updated = ChatMessage(
        id: 'welcome',
        role: MessageRole.ai,
        content:
            "I'm ready to help you study **${doc.name}**. What would you like to explore?",
        timestamp: DateTime.now(),
        model: _model,
        language: _language,
      );
      if (welcomeIdx != -1) {
        _messages[welcomeIdx] = updated;
      } else {
        _messages.insert(0, updated);
      }
    });
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
            _TopBar(onBack: () => Navigator.maybePop(context)),
            _TopControls(
              activeDoc: _activeDoc,
              model: _model,
              language: _language,
              socraticMode: _socraticMode,
              onChangeTap: _showDocPicker,
              onModelChanged: (m) => setState(() => _model = m),
              onLanguageTap: () => LanguageSheet.show(
                context,
                current: _language,
                onSelected: (l) => setState(() => _language = l),
              ),
            ),
            const _SessionDivider(),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
              isTyping: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_rounded,
                color: UEColors.textMuted, size: 22),
          ),
          const Spacer(),
          Text('AI Tutor', style: UETypography.h3),
          const Spacer(),
          const Icon(Icons.more_horiz_rounded,
              color: UEColors.textMuted, size: 22),
        ],
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  final Document? activeDoc;
  final ModelMode model;
  final Language language;
  final bool socraticMode;
  final VoidCallback onChangeTap;
  final ValueChanged<ModelMode> onModelChanged;
  final VoidCallback onLanguageTap;

  const _TopControls({
    required this.activeDoc,
    required this.model,
    required this.language,
    required this.socraticMode,
    required this.onChangeTap,
    required this.onModelChanged,
    required this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: UEColors.bgCard, width: 0.5)),
      ),
      child: Column(
        children: [
          DocContextBar(activeDoc: activeDoc, onChangeTap: onChangeTap),
          const SizedBox(height: 10),
          ModelLangControls(
            selectedModel: model,
            selectedLanguage: language,
            socraticMode: socraticMode,
            onModelChanged: onModelChanged,
            onLanguageTap: onLanguageTap,
          ),
        ],
      ),
    );
  }
}

class _SessionDivider extends StatelessWidget {
  const _SessionDivider();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final isLocal = settings.activeBackend == AIBackend.local;
        final hasEngine = isLocal ? OfflineAIService.instance.isModelLoaded : settings.groqApiKey.isNotEmpty;
        final engineName = isLocal ? 'Local LLM' : 'Groq Cloud';
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                'Session started · Today',
                style: UETypography.caption.copyWith(color: UEColors.textDim, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasEngine ? Colors.green : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasEngine ? '$engineName Active' : 'No Engine Active',
                    style: UETypography.caption.copyWith(
                      color: UEColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

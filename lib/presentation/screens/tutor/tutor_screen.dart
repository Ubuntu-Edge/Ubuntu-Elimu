import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/chat_message.dart';
import '../../../models/document.dart';
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
  Language _language = Language.swahili;
  bool _socraticMode = true;
  bool _isTyping = false;

  // Stub active document
  final Document _activeDoc = Document(
    id: '1',
    name: 'Organic Chemistry — Ch.7.pdf',
    type: DocType.pdf,
    sizeBytes: 2400000,
    addedAt: DateTime.now(),
    pageCount: 22,
  );

  // Stub messages
  late final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      role: MessageRole.user,
      content:
      "I don't understand how nucleophilic substitution works. Can you just explain it to me?",
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      id: '2',
      role: MessageRole.ai,
      content:
      'Kabla sijaeleza — hebu niulize kwanza.\n\nUkiwa na kitu kinachohitaji elektroni — na kitu kingine chenye elektroni nyingi — unafikiria nini kitatokea unapozileta pamoja?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      language: Language.swahili,
      model: ModelMode.power,
      citation: const CitationRef(
        docName: 'Ch.7',
        page: 4,
        excerpt: 'Nucleophiles and electrophiles',
      ),
    ),
    ChatMessage(
      id: '3',
      role: MessageRole.user,
      content:
      'Nadhani itavutana... elektroni itaenda kwa kitu kinachohitaji?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
    ChatMessage(
      id: '4',
      role: MessageRole.ai,
      content:
      'Exactly right. That pull is the core of every SN reaction.\n\nNow — what do you think determines how fast that substitution happens? Think about what might get in the way.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      language: Language.english,
      model: ModelMode.power,
      citation: const CitationRef(
        docName: 'Ch.7',
        page: 7,
        excerpt: 'Reaction rate factors',
      ),
    ),
  ];

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

  void _handleSend(String text) {
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

    // Stub AI response delay — replace with real inference later
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.ai,
          content:
          'Good question. Before I answer — what do you already know about that concept? Walk me through your current understanding.',
          timestamp: DateTime.now(),
          language: _language,
          model: _model,
        ));
      });
      _scrollToBottom();
    });
  }

  void _showDocPicker() {
    // TODO: open library screen / doc picker sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Doc picker coming — wire to Library screen'),
        backgroundColor: UEColors.bgCard,
      ),
    );
  }

  void _openCitation(CitationRef citation) {
    // TODO: open document at page
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
        bottom: false,
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
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const TypingIndicator();
                  }
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
              isTyping: _isTyping,
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
            child: const Icon(
              Icons.arrow_back_rounded,
              color: UEColors.textMuted,
              size: 22,
            ),
          ),
          const Spacer(),
          Text('AI Tutor', style: UETypography.h3),
          const Spacer(),
          const Icon(
            Icons.more_horiz_rounded,
            color: UEColors.textMuted,
            size: 22,
          ),
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
          bottom: BorderSide(color: UEColors.bgCard, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          DocContextBar(
            activeDoc: activeDoc,
            onChangeTap: onChangeTap,
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Session started · Today',
        style: UETypography.caption.copyWith(
          color: UEColors.textDim,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
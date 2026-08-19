import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/chat_message.dart';
import '../../../models/document.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/offline_model_provider.dart';
import '../../../providers/settings_provider.dart';
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
  int _lastMessageCount = 0;

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

  void _handleSend(SessionProvider session, DocumentProvider docs, bool socratic, String text) {
    session.sendMessage(
      text,
      docProvider: docs,
      socratic: socratic,
      language: _language.fullName,
    );
    _scrollToBottom();
  }

  void _showDocPicker(BuildContext context, SessionProvider session, DocumentProvider docs) {
    if (docs.documents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No documents yet — upload one from the Library tab first.'),
          backgroundColor: UEColors.surface,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: UEColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Study Document',
                    style: UETypography.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: UEColors.textPrimary,
                    ),
                  ),
                  if (session.activeDocumentId != null)
                    TextButton.icon(
                      onPressed: () {
                        session.clearActiveDocument();
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(TablerIcons.x, size: 14, color: UEColors.pdfFg),
                      label: Text(
                        'Deselect',
                        style: UETypography.inter(fontSize: 12, color: UEColors.pdfFg),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: docs.documents.length,
                  separatorBuilder: (_, __) => const Divider(color: UEColors.border, height: 0.5),
                  itemBuilder: (_, i) {
                    final doc = docs.documents[i];
                    final isSelected = doc.id == session.activeDocumentId;
                    return ListTile(
                      leading: Icon(
                        _iconForType(doc.type),
                        color: isSelected ? UEColors.accent : UEColors.textMuted,
                      ),
                      title: Text(
                        doc.name,
                        style: UETypography.inter(
                          fontSize: 13,
                          color: isSelected ? UEColors.accent : UEColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        doc.isProcessed ? '${doc.sizeLabel} · Ready for AI' : 'Processing…',
                        style: UETypography.inter(fontSize: 11, color: UEColors.textMuted),
                      ),
                      trailing: isSelected ? const Icon(TablerIcons.check, color: UEColors.accent, size: 18) : null,
                      onTap: () {
                        session.setActiveDocument(doc.id, doc.name);
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(DocType type) {
    switch (type) {
      case DocType.pdf:
        return TablerIcons.file_type_pdf;
      case DocType.pptx:
        return TablerIcons.file_type_ppt;
      case DocType.docx:
        return TablerIcons.file_type_docx;
      default:
        return TablerIcons.file_text;
    }
  }

  void _openCitation(CitationRef citation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${citation.docName} p.${citation.page}'),
        backgroundColor: UEColors.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final docs = context.watch<DocumentProvider>();
    final modelProvider = context.watch<OfflineModelProvider>();
    final settings = context.watch<SettingsProvider>();

    if (session.chatMessages.length != _lastMessageCount) {
      _lastMessageCount = session.chatMessages.length;
      _scrollToBottom();
    }

    final activeDoc = session.activeDocumentId == null
        ? null
        : docs.documents.where((d) => d.id == session.activeDocumentId).firstOrNull;

    return Scaffold(
      backgroundColor: UEColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Research-style clean header bar (NO top back arrow)
            _buildHeader(context, modelProvider),

            if (!modelProvider.hasActiveModel)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: UEColors.pdfBg,
                child: Text(
                  'No model loaded — go to Settings to download and activate one.',
                  style: UETypography.inter(fontSize: 11, color: UEColors.pdfFg),
                ),
              ),

            // Document & Socratic Quick Bar
            _buildControlBar(context, session, docs, activeDoc, settings),

            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: session.chatMessages.length + (session.isGenerating ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == session.chatMessages.length) {
                    return const TypingIndicator();
                  }
                  final msg = session.chatMessages[index];
                  return ChatBubble(
                    message: msg,
                    onCitationTap: msg.citation != null ? () => _openCitation(msg.citation!) : null,
                  );
                },
              ),
            ),
            ChatInputBar(
              onSend: (text) => _handleSend(session, docs, settings.socraticMode, text),
              onStop: () => session.stopGeneration(),
              isTyping: session.isGenerating,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OfflineModelProvider modelProvider) {
    final activeModelName = modelProvider.activeModel?.name ?? 'No Model Active';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(bottom: BorderSide(color: UEColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: UEColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              TablerIcons.brain,
              color: UEColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Tutor',
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
          // New Chat button
          IconButton(
            onPressed: () {
              context.read<SessionProvider>().startNewSession();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Started new AI Tutor session'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(TablerIcons.plus, size: 20, color: UEColors.indigo),
            tooltip: 'New Chat Session',
          ),
          const SizedBox(width: 4),
          // Language selection chip button
          GestureDetector(
            onTap: () => LanguageSheet.show(
              context,
              current: _language,
              onSelected: (l) => setState(() => _language = l),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: UEColors.surface,
                border: Border.all(color: UEColors.border, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(TablerIcons.language, size: 14, color: UEColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _language.label,
                    style: UETypography.inter(fontSize: 11, color: UEColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(
    BuildContext context,
    SessionProvider session,
    DocumentProvider docs,
    Document? activeDoc,
    SettingsProvider settings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(bottom: BorderSide(color: UEColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Select Document Chip (like Research page Library Grounding chip)
          Expanded(
            child: GestureDetector(
              onTap: () => _showDocPicker(context, session, docs),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: activeDoc != null ? UEColors.accent.withOpacity(0.12) : UEColors.surface,
                  border: Border.all(
                    color: activeDoc != null ? UEColors.accent : UEColors.border,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      activeDoc != null ? _iconForType(activeDoc.type) : TablerIcons.file_plus,
                      size: 14,
                      color: activeDoc != null ? UEColors.accent : UEColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activeDoc != null ? activeDoc.name : 'Select Document to Study…',
                        overflow: TextOverflow.ellipsis,
                        style: UETypography.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: activeDoc != null ? UEColors.accent : UEColors.textMuted,
                        ),
                      ),
                    ),
                    Icon(
                      TablerIcons.chevron_down,
                      size: 14,
                      color: activeDoc != null ? UEColors.accent : UEColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Socratic Mode Pill Toggle
          GestureDetector(
            onTap: () => settings.toggleSocraticMode(!settings.socraticMode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: settings.socraticMode ? UEColors.greenBg : UEColors.surface,
                border: Border.all(
                  color: settings.socraticMode ? UEColors.greenBorder : UEColors.border,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    TablerIcons.school,
                    size: 14,
                    color: settings.socraticMode ? UEColors.green : UEColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    settings.socraticMode ? 'Socratic' : 'Direct',
                    style: UETypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: settings.socraticMode ? UEColors.green : UEColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

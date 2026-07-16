import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/document.dart';
import '../../../providers/settings_provider.dart';

class DocumentWorkspaceScreen extends StatefulWidget {
  final dynamic document;
  final String mode;

  const DocumentWorkspaceScreen({
    super.key,
    required this.document,
    required this.mode,
  });

  @override
  State<DocumentWorkspaceScreen> createState() =>
      _DocumentWorkspaceScreenState();
}

class _DocumentWorkspaceScreenState extends State<DocumentWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _summary;
  bool _isLoadingSummary = false;
  String? _summaryError;

  @override
  void initState() {
    super.initState();

    // Only Reader (0) and Summary (1) tabs remain
    _tabController = TabController(length: 2, vsync: this);

    switch (widget.mode) {
      case 'summary':
        _tabController.index = 1;
        _generateSummary();
        break;
      default:
        _tabController.index = 0;
    }

    _tabController.addListener(() {
      if (_tabController.index == 1 &&
          _summary == null &&
          !_isLoadingSummary) {
        _generateSummary();
      }
    });
  }

  Future<void> _generateSummary() async {
    final doc = widget.document as Document;
    if (!doc.isProcessed) {
      setState(
          () => _summaryError = 'This document has not been processed yet.');
      return;
    }
    if (doc.chunks.isEmpty) {
      setState(
          () => _summaryError = 'No text content available to summarize.');
      return;
    }

    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });
    try {
      final aiProvider = context.read<SettingsProvider>().getAIProvider();
      final result = await aiProvider.generateJson(
        'Summarize this content:\n\n${doc.chunks.take(5).join('\n\n')}',
        systemPrompt: 'You are an expert summarizer for students. '
            'You must return a valid JSON object with the following exact keys: '
            '"title" (String), "summary" (String), "key_concepts" (List of Strings), '
            '"exam_focus" (List of Strings), and "notes" (List of Strings). '
            'Do not wrap in any other key.',
      );
      if (mounted) {
        setState(() {
          if (result == null) {
            _summaryError =
                'Failed to generate a valid summary format. Please try again.';
          } else {
            _summary = result;
          }
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating summary: $e');
      if (mounted) {
        setState(() {
          _summaryError = 'Error connecting to AI backend: $e';
          _isLoadingSummary = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;

    return Scaffold(
      backgroundColor: UEColors.bg,
      appBar: AppBar(
        backgroundColor: UEColors.surface,
        elevation: 0,
        title: Text(
          doc.name,
          style: UETypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: UEColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: UEColors.accent,
          labelColor: UEColors.accent,
          unselectedLabelColor: UEColors.textMuted,
          tabs: const [
            Tab(icon: Icon(TablerIcons.file_text, size: 18)),
            Tab(icon: Icon(TablerIcons.sparkles, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReaderTab(doc),
          _buildSummaryTab(doc),
        ],
      ),
    );
  }

  // ================= READER =================
  Widget _buildReaderTab(doc) {
    final document = doc as Document;

    if (!document.isProcessed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: UEColors.accent),
            const SizedBox(height: 16),
            Text(
              'Processing document...',
              style: UETypography.inter(
                fontSize: 13,
                color: UEColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (document.filePath == null || !File(document.filePath!).existsSync()) {
      return Center(
        child: Text(
          'Document file not found',
          style: UETypography.inter(fontSize: 13, color: UEColors.textMuted),
        ),
      );
    }

    if (document.type == DocType.pdf) {
      return Container(
        color: UEColors.bg,
        child: SfPdfViewer.file(
          File(document.filePath!),
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
          enableTextSelection: true,
        ),
      );
    }

    if (document.extractedText == null || document.extractedText!.isEmpty) {
      return Center(
        child: Text(
          'No text could be extracted from this document',
          style: UETypography.inter(fontSize: 13, color: UEColors.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: UEColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          _sanitizeExtractedText(document.extractedText!),
          style: UETypography.inter(
            fontSize: 13,
            color: UEColors.textPrimary,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  // ================= AI SUMMARY =================
  Widget _buildSummaryTab(doc) {
    if (_isLoadingSummary) {
      return const Center(
        child: CircularProgressIndicator(color: UEColors.accent),
      );
    }

    if (_summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No summary generated yet',
                style: UETypography.inter(
                  fontSize: 13,
                  color: UEColors.textMuted,
                ),
              ),
              if (_summaryError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _summaryError!,
                  style: UETypography.caption.copyWith(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generateSummary,
                style:
                    ElevatedButton.styleFrom(backgroundColor: UEColors.accent),
                child: const Text('Generate Summary'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_summary!['title'] != null) ...[
          Text(
            _summary!['title'],
            style: UETypography.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: UEColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_summary!['summary'] != null) ...[
          _sectionTitle("📘 Summary"),
          _card(_summary!['summary']),
        ],

        if (_summary!['key_concepts'] != null) ...[
          _sectionTitle("🧠 Key Concepts"),
          _card(
            (_summary!['key_concepts'] as List).map((c) => '• $c').join('\n'),
          ),
        ],

        if (_summary!['exam_focus'] != null) ...[
          _sectionTitle("🎯 Exam Focus"),
          _card(
            (_summary!['exam_focus'] as List).map((e) => '• $e').join('\n'),
          ),
        ],

        if (_summary!['notes'] != null) ...[
          _sectionTitle("📝 Detailed Notes"),
          _card((_summary!['notes'] as List).map((n) => '• $n').join('\n')),
        ],
      ],
    );
  }

  // ================= UI HELPERS =================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text,
        style: UETypography.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: UEColors.textPrimary,
        ),
      ),
    );
  }

  Widget _card(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UEColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: UETypography.inter(fontSize: 13, color: UEColors.textPrimary),
      ),
    );
  }

  /// Sanitize extracted text by removing aggressive single-character line breaks
  /// while preserving actual paragraph boundaries and readability
  String _sanitizeExtractedText(String rawText) {
    // 1. Remove hyphens that break a word across newlines (e.g., re-\nranking -> reranking)
    String cleaned = rawText.replaceAll(RegExp(r'(\w+)-\n(\w+)'), r'$1$2');

    // 2. Replace single newlines (accidental line wraps) with a space,
    // but keep double newlines (\n\n) which indicate actual paragraph breaks
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\n)\n(?!\n)'),
      (match) => ' ',
    );

    // 3. Clean up multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r' {2,}'), ' ');

    // 4. Normalize paragraph breaks (reduce 3+ newlines to exactly 2)
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }
}

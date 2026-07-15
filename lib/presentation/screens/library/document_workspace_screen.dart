import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../services/offline_ai_service.dart';
import '../../../models/document.dart';

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
  Map<String, dynamic>? _studyPlan;
  List<Map<String, dynamic>>? _flashcards;
  bool _isLoadingSummary = false;
  bool _isLoadingStudyPlan = false;
  bool _isLoadingFlashcards = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    // Auto-open based on mode
    switch (widget.mode) {
      case "summary":
        _tabController.index = 1;
        _generateSummary();
        break;
      case "study_plan":
        _tabController.index = 2;
        _generateStudyPlan();
        break;
      case "flashcards":
        _tabController.index = 3;
        _generateFlashcards();
        break;
      default:
        _tabController.index = 0;
    }

    _tabController.addListener(() {
      if (_tabController.index == 1 && _summary == null && !_isLoadingSummary) {
        _generateSummary();
      } else if (_tabController.index == 2 &&
          _studyPlan == null &&
          !_isLoadingStudyPlan) {
        _generateStudyPlan();
      } else if (_tabController.index == 3 &&
          _flashcards == null &&
          !_isLoadingFlashcards) {
        _generateFlashcards();
      }
    });
  }

  Future<void> _generateSummary() async {
    final doc = widget.document as Document;
    if (!doc.isProcessed || doc.chunks.isEmpty) return;

    setState(() => _isLoadingSummary = true);
    try {
      final result = await OfflineAIService.instance.summarizeChunks(
        doc.chunks.take(5).toList(),
      );
      if (mounted) {
        setState(() {
          _summary = result;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  Future<void> _generateStudyPlan() async {
    final doc = widget.document as Document;
    if (!doc.isProcessed || doc.chunks.isEmpty) return;

    setState(() => _isLoadingStudyPlan = true);
    try {
      final result = await OfflineAIService.instance.generateStudyPlan(
        doc.chunks.take(3).toList(),
        days: 3,
      );
      if (mounted) {
        setState(() {
          _studyPlan = result;
          _isLoadingStudyPlan = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStudyPlan = false);
      }
    }
  }

  Future<void> _generateFlashcards() async {
    final doc = widget.document as Document;
    if (!doc.isProcessed || doc.chunks.isEmpty) return;

    setState(() => _isLoadingFlashcards = true);
    try {
      final result = await OfflineAIService.instance.generateFlashcards(
        doc.chunks.take(5).toList(),
        count: 8,
      );
      if (mounted) {
        setState(() {
          _flashcards = result;
          _isLoadingFlashcards = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFlashcards = false);
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
            Tab(icon: Icon(TablerIcons.calendar, size: 18)),
            Tab(icon: Icon(TablerIcons.cards, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReaderTab(doc),
          _buildSummaryTab(doc),
          _buildStudyPlanTab(doc),
          _buildFlashcardsTab(doc),
        ],
      ),
    );
  }

  // ================= ORIGINAL READER =================
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

    // Show native PDF viewer for PDF files
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

    // For DOCX and other formats, show extracted text
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateSummary,
              style: ElevatedButton.styleFrom(backgroundColor: UEColors.accent),
              child: const Text('Generate Summary'),
            ),
          ],
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

  // ================= STUDY PLAN =================
  Widget _buildStudyPlanTab(doc) {
    if (_isLoadingStudyPlan) {
      return const Center(
        child: CircularProgressIndicator(color: UEColors.accent),
      );
    }

    if (_studyPlan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No study plan generated yet',
              style: UETypography.inter(
                fontSize: 13,
                color: UEColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateStudyPlan,
              style: ElevatedButton.styleFrom(backgroundColor: UEColors.accent),
              child: const Text('Generate Study Plan'),
            ),
          ],
        ),
      );
    }

    final plan = _studyPlan!['plan'] as List?;
    final tips = _studyPlan!['tips'] as List?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("📅 Study Plan"),

        if (plan != null)
          ...plan
              .map(
                (day) => _planCard(
                  "Day ${day['day']}",
                  day['focus'] ?? 'Study session',
                  "${day['duration_minutes'] ?? 30} min",
                  tasks: day['tasks'] as List?,
                ),
              )
              .toList(),

        if (tips != null && tips.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle("⚡ Tips"),
          _card(tips.map((t) => '• $t').join('\n')),
        ],
      ],
    );
  }

  // ================= FLASHCARDS =================
  Widget _buildFlashcardsTab(doc) {
    if (_isLoadingFlashcards) {
      return const Center(
        child: CircularProgressIndicator(color: UEColors.accent),
      );
    }

    if (_flashcards == null || _flashcards!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No flashcards generated yet',
              style: UETypography.inter(
                fontSize: 13,
                color: UEColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateFlashcards,
              style: ElevatedButton.styleFrom(backgroundColor: UEColors.accent),
              child: const Text('Generate Flashcards'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flashcards!.length,
      itemBuilder: (context, index) {
        final card = _flashcards![index];

        return Card(
          color: UEColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            iconColor: UEColors.accent,
            collapsedIconColor: UEColors.textMuted,
            title: Text(
              card['q'] ?? 'Question ${index + 1}',
              style: UETypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: UEColors.textPrimary,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  card['a'] ?? 'No answer',
                  style: UETypography.inter(
                    fontSize: 13,
                    color: UEColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _planCard(
    String day,
    String topic,
    String time, {
    List<dynamic>? tasks,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UEColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: UETypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: UEColors.textPrimary,
                    ),
                  ),
                  Text(
                    topic,
                    style: UETypography.inter(
                      fontSize: 12,
                      color: UEColors.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                time,
                style: UETypography.inter(
                  fontSize: 12,
                  color: UEColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (tasks != null && tasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...tasks
                .map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '• $task',
                      style: UETypography.inter(
                        fontSize: 11,
                        color: UEColors.textMuted,
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        ],
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

    // 3. Clean up multiple spaces that may have been introduced
    cleaned = cleaned.replaceAll(RegExp(r' {2,}'), ' ');

    // 4. Normalize paragraph breaks (reduce 3+ newlines to exactly 2)
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }
}

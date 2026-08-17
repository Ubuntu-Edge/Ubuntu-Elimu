import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/document.dart';
import '../../../services/offline_ai_service.dart';

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

  bool _isGeneratingSummary = false;
  Map<String, dynamic>? _generatedSummary;

  bool _isGeneratingPlan = false;
  Map<String, dynamic>? _generatedPlan;

  bool _isGeneratingFlashcards = false;
  List<Map<String, dynamic>>? _generatedFlashcards;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    // Auto-open based on mode
    switch (widget.mode) {
      case "summary":
        _tabController.index = 1;
        break;
      case "study_plan":
        _tabController.index = 2;
        break;
      case "flashcards":
        _tabController.index = 3;
        break;
      default:
        _tabController.index = 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> get _docChunks {
    final doc = widget.document;
    if (doc.chunks != null && (doc.chunks as List).isNotEmpty) {
      return List<String>.from(doc.chunks);
    }
    if (doc.extractedText != null && (doc.extractedText as String).isNotEmpty) {
      return [doc.extractedText as String];
    }
    return [doc.name ?? 'Document'];
  }

  Future<void> _generateSummary() async {
    if (!OfflineAIService.instance.isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No model loaded. Please activate one in Settings.')),
      );
      return;
    }
    setState(() => _isGeneratingSummary = true);
    try {
      final res = await OfflineAIService.instance.summarizeChunks(_docChunks);
      if (mounted) setState(() => _generatedSummary = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate summary: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingSummary = false);
    }
  }

  Future<void> _generatePlan() async {
    if (!OfflineAIService.instance.isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No model loaded. Please activate one in Settings.')),
      );
      return;
    }
    setState(() => _isGeneratingPlan = true);
    try {
      final res = await OfflineAIService.instance.generateStudyPlan(_docChunks, days: 3);
      if (mounted) setState(() => _generatedPlan = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate study plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPlan = false);
    }
  }

  Future<void> _generateFlashcards() async {
    if (!OfflineAIService.instance.isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No model loaded. Please activate one in Settings.')),
      );
      return;
    }
    setState(() => _isGeneratingFlashcards = true);
    try {
      final res = await OfflineAIService.instance.generateFlashcards(_docChunks, count: 6);
      if (mounted) setState(() => _generatedFlashcards = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate flashcards: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingFlashcards = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildContent(context);
    } catch (e, stack) {
      debugPrint('DocumentWorkspaceScreen build error: $e\n$stack');
      return Scaffold(
        backgroundColor: UEColors.bg,
        appBar: AppBar(
          backgroundColor: UEColors.surface,
          elevation: 0,
          title: const Text('Document', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Could not open document',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: UEColors.accent),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
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

  String _safeExtractedText(dynamic doc) {
    if (doc == null) return '';
    try {
      final raw = doc.extractedText?.toString() ?? '';
      if (raw.trim().isEmpty) {
        final chunkCount = (doc.chunks != null && doc.chunks is List) ? (doc.chunks as List).length : 0;
        return "Document content parsed into $chunkCount indexed knowledge chunks for offline AI reasoning.";
      }
      final buffer = StringBuffer();
      for (final char in raw.runes) {
        if ((char >= 32 && char <= 0xD7FF) ||
            (char >= 0xE000 && char <= 0xFFFD) ||
            (char >= 0x10000 && char <= 0x10FFFF) ||
            char == 10 || char == 13 || char == 9) {
          buffer.writeCharCode(char);
        }
      }
      return buffer.toString();
    } catch (_) {
      return "Document content indexed for offline AI reasoning.";
    }
  }

  // ================= DOCUMENT READER =================
  Widget _buildReaderTab(dynamic doc) {
    final filePath = doc.filePath?.toString();
    final docType = doc.type;
    final isPdf = docType == DocType.pdf;

    // ── PDF: use Syncfusion native renderer ──────────────────
    if (isPdf && filePath != null && File(filePath).existsSync()) {
      return _PdfReaderView(filePath: filePath);
    }

    // ── DOCX / other: rich scrollable text view ──────────────
    final text = _safeExtractedText(doc);
    final hasText = text.trim().isNotEmpty;

    return Container(
      color: UEColors.bg,
      child: hasText
          ? Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: SelectableText(
                  text,
                  style: UETypography.inter(
                    fontSize: 14,
                    color: UEColors.textSecondary,
                    height: 1.75,
                  ),
                ),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(TablerIcons.file_off, color: UEColors.textDim, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No readable text found in this document.',
                    style: UETypography.inter(fontSize: 13, color: UEColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  // ================= AI SUMMARY =================
  Widget _buildSummaryTab(dynamic doc) {
    if (_isGeneratingSummary) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Generating offline summary with Denizen AI...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    final summary = _generatedSummary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AI SUMMARY', style: UETypography.label),
            ElevatedButton.icon(
              onPressed: _generateSummary,
              icon: const Icon(TablerIcons.sparkles, size: 14),
              label: Text(summary == null ? 'Generate with AI' : 'Regenerate', style: const TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: UEColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (summary != null) ...[
          _sectionTitle("📘 ${summary['title'] ?? 'Overview'}"),
          _card(summary['summary']?.toString() ?? ''),
          if (summary['key_concepts'] is List) ...[
            _sectionTitle("🧠 Key Concepts"),
            _card((summary['key_concepts'] as List).map((e) => "• $e").join('\n')),
          ],
          if (summary['exam_focus'] is List) ...[
            _sectionTitle("🎯 Exam Focus"),
            _card((summary['exam_focus'] as List).map((e) => "• $e").join('\n')),
          ],
          if (summary['notes'] is List) ...[
            _sectionTitle("📝 Detailed Notes"),
            _card((summary['notes'] as List).map((e) => "• $e").join('\n')),
          ],
        ] else ...[
          _sectionTitle("📘 Structured Notes"),
          _card("• ${doc.name} key concepts parsed.\n• Click 'Generate with AI' to run offline model synthesis."),
          _sectionTitle("🧠 Key Concepts"),
          _card("• Offline LLM Reasoning\n• Vector Retrieval Grounding"),
          _sectionTitle("🎯 Exam Focus"),
          _card("• Core formulas and definitions\n• Worked problem patterns"),
        ],
      ],
    );
  }

  // ================= STUDY PLAN =================
  Widget _buildStudyPlanTab(dynamic doc) {
    if (_isGeneratingPlan) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Generating personalized study plan...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    final plan = _generatedPlan;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('STUDY PLAN', style: UETypography.label),
            ElevatedButton.icon(
              onPressed: _generatePlan,
              icon: const Icon(TablerIcons.calendar, size: 14),
              label: Text(plan == null ? 'Generate Plan' : 'Regenerate', style: const TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: UEColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (plan != null && plan['plan'] is List) ...[
          _sectionTitle("📅 ${(plan['plan'] as List).length}-Day Study Plan"),
          ...(plan['plan'] as List).map((item) {
            final day = "Day ${item['day'] ?? ''}";
            final focus = "${item['focus'] ?? ''}\n${(item['tasks'] as List?)?.map((t) => '- $t').join('\n') ?? ''}";
            final duration = "${item['duration_minutes'] ?? 45} min";
            return _planCard(day, focus, duration);
          }),
          if (plan['tips'] is List) ...[
            const SizedBox(height: 12),
            _sectionTitle("⚡ Study Tips"),
            _card((plan['tips'] as List).map((t) => "• $t").join('\n')),
          ],
        ] else ...[
          _sectionTitle("📅 3-Day Study Plan"),
          _planCard("Day 1", "Introduction + Core Concepts", "30–45 min"),
          _planCard("Day 2", "Deep Dive Topics", "45–60 min"),
          _planCard("Day 3", "Revision + Practice Questions", "60 min"),
          const SizedBox(height: 12),
          _sectionTitle("⚡ Tips"),
          _card("• Study in short focused sessions\n• Revise active recall questions\n• Avoid passive reading only"),
        ],
      ],
    );
  }

  // ================= FLASHCARDS =================
  Widget _buildFlashcardsTab(dynamic doc) {
    if (_isGeneratingFlashcards) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Extracting flashcards with Denizen AI...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    final cards = _generatedFlashcards ?? [
      {
        "q": "What is the primary topic of ${doc.name}?",
        "a": "The key concepts extracted from this document."
      },
      {
        "q": "How does offline AI help study this material?",
        "a": "It enables instant local questioning without internet or data cost."
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('FLASHCARDS', style: UETypography.label),
            ElevatedButton.icon(
              onPressed: _generateFlashcards,
              icon: const Icon(TablerIcons.cards, size: 14),
              label: Text(_generatedFlashcards == null ? 'Generate Flashcards' : 'Regenerate', style: const TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: UEColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...cards.map((card) {
          return Card(
            color: UEColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              iconColor: UEColors.accent,
              collapsedIconColor: UEColors.textMuted,
              title: Text(
                card["q"]?.toString() ?? '',
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
                    card["a"]?.toString() ?? '',
                    style: UETypography.inter(
                      fontSize: 13,
                      color: UEColors.textMuted,
                    ),
                  ),
                )
              ],
            ),
          );
        }),
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
        style: UETypography.inter(
          fontSize: 13,
          color: UEColors.textPrimary,
        ),
      ),
    );
  }

  Widget _planCard(String day, String topic, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UEColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
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
          ),
          const SizedBox(width: 8),
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
    );
  }
}

// ════════════════════════════════════════════════════════════
// PDF Reader with Syncfusion PdfViewer + page counter overlay
// ════════════════════════════════════════════════════════════
class _PdfReaderView extends StatefulWidget {
  final String filePath;
  const _PdfReaderView({required this.filePath});

  @override
  State<_PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<_PdfReaderView> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_outlined, color: Colors.orange, size: 48),
              const SizedBox(height: 12),
              Text(
                'Could not render PDF',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // ── PDF Viewer ─────────────────────────────────────────
        SfPdfViewer.file(
          File(widget.filePath),
          controller: _pdfController,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          scrollDirection: PdfScrollDirection.vertical,
          enableDoubleTapZooming: true,
          onDocumentLoaded: (details) {
            if (mounted) {
              setState(() {
                _totalPages = details.document.pages.count;
                _isLoading = false;
              });
            }
          },
          onPageChanged: (details) {
            if (mounted) setState(() => _currentPage = details.newPageNumber);
          },
          onDocumentLoadFailed: (details) {
            if (mounted) setState(() {
              _error = details.description;
              _isLoading = false;
            });
          },
        ),

        // ── Loading indicator ──────────────────────────────────
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),

        // ── Page counter badge ─────────────────────────────────
        if (!_isLoading && _totalPages > 0)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: UEColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: UEColors.border, width: 0.5),
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // ── Zoom controls ──────────────────────────────────────
        if (!_isLoading)
          Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: [
                _ZoomButton(
                  icon: Icons.zoom_in,
                  onTap: () => _pdfController.zoomLevel =
                      (_pdfController.zoomLevel + 0.25).clamp(0.75, 3.0),
                ),
                const SizedBox(width: 8),
                _ZoomButton(
                  icon: Icons.zoom_out,
                  onTap: () => _pdfController.zoomLevel =
                      (_pdfController.zoomLevel - 0.25).clamp(0.75, 3.0),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: UEColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: UEColors.border, width: 0.5),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}
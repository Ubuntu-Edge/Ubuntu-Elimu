import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../services/local_code_server.dart';
import 'widgets/ai_coder_sheet.dart';
import 'widgets/code_editor_pane.dart';
import 'widgets/codelab_preview_pane.dart';
import 'widgets/templates_modal.dart';

class CodeLabScreen extends StatefulWidget {
  const CodeLabScreen({super.key});

  @override
  State<CodeLabScreen> createState() => _CodeLabScreenState();
}

class _CodeLabScreenState extends State<CodeLabScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<CodeLabPreviewPaneState> _previewKey = GlobalKey<CodeLabPreviewPaneState>();
  final LocalCodeServer _server = LocalCodeServer.instance;

  String _projectTitle = 'Untitled Project';
  int _selectedTab = 0; // 0 = Editor, 1 = Preview (for narrow screens)
  String? _lastError;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    // Start blank — no default template pre-loaded.
    // The user lands straight in "what do you want to build?" mode via
    // the AI assistant sheet, opened automatically after first frame.
    _startServer();
    _errorSub = _server.errorStream.listen((errorMsg) {
      if (mounted) {
        setState(() {
          _lastError = errorMsg;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _codeController.text.isEmpty) {
        _openAiAssistant();
      }
    });
  }

  Future<void> _startServer() async {
    await _server.start();
    _server.updateCode(_codeController.text);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _runCode() {
    setState(() {
      _lastError = null;
    });
    _server.updateCode(_codeController.text);
    _previewKey.currentState?.reload();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Sandbox reloaded with latest code!'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openInChrome() async {
    _server.updateCode(_codeController.text);
    final success = await _server.openInChrome();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch Chrome. Please check device browser settings.'),
          backgroundColor: UEColors.pdfFg,
        ),
      );
    }
  }

  void _openAiAssistant({String? initialPrompt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: _codeController.text.isNotEmpty, // don't let a blank project dismiss with nothing built
      enableDrag: _codeController.text.isNotEmpty,
      builder: (ctx) => AICoderSheet(
        currentCode: _codeController.text,
        initialPrompt: initialPrompt,
        onApplyCode: (newCode) {
          setState(() {
            _codeController.text = newCode;
          });
          _runCode();
        },
      ),
    );
  }

  void _openTemplates() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TemplatesModal(
        onSelectTemplate: (template) {
          setState(() {
            _projectTitle = template.title;
            _codeController.text = template.code;
          });
          _runCode();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletLandscape = screenWidth >= 800;

    return Scaffold(
      backgroundColor: UEColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Top Navigation Bar
              _buildTopBar(isTabletLandscape),
              const SizedBox(height: 12),

              // Narrow Screen View Switcher (Editor / Preview)
              if (!isTabletLandscape) ...[
                _buildTabSwitcher(),
                const SizedBox(height: 10),
              ],

              // Runtime Error Banner
              if (_lastError != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: 10),
              ],

              // Main Workspace Area
              Expanded(
                child: isTabletLandscape
                    ? Row(
                        children: [
                          // Left: Code Editor (50%)
                          Expanded(
                            child: CodeEditorPane(
                              controller: _codeController,
                              onRun: _runCode,
                              onAskAi: () => _openAiAssistant(),
                              emptyStateHint: _codeController.text.isEmpty
                                  ? 'Nothing built yet — tell the AI what to make.'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right: Live Preview (50%)
                          Expanded(
                            child: CodeLabPreviewPane(
                              key: _previewKey,
                              onOpenInChrome: _openInChrome,
                              onRefresh: _runCode,
                            ),
                          ),
                        ],
                      )
                    : IndexedStack(
                        index: _selectedTab,
                        children: [
                          CodeEditorPane(
                            controller: _codeController,
                            onRun: () {
                              _runCode();
                              setState(() => _selectedTab = 1); // Switch to preview
                            },
                            onAskAi: () => _openAiAssistant(),
                            emptyStateHint: _codeController.text.isEmpty
                                ? 'Nothing built yet — tell the AI what to make.'
                                : null,
                          ),
                          CodeLabPreviewPane(
                            key: _previewKey,
                            onOpenInChrome: _openInChrome,
                            onRefresh: _runCode,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: UEColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UEColors.border),
      ),
      child: Row(
        children: [
          // CodeLab Brand Icon & Title
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: UEColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(TablerIcons.terminal_2, color: UEColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'CodeLab',
                      style: UETypography.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: UEColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: UEColors.greenBg,
                        border: Border.all(color: UEColors.greenBorder, width: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: UEColors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ':${_server.port}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: UEColors.green,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  _projectTitle,
                  style: UETypography.inter(
                    fontSize: 11,
                    color: UEColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Action Buttons
          IconButton(
            icon: const Icon(TablerIcons.book, color: UEColors.textSecondary, size: 20),
            tooltip: 'Curriculum Templates',
            onPressed: _openTemplates,
          ),
          IconButton(
            icon: const Icon(TablerIcons.sparkles, color: UEColors.violet, size: 20),
            tooltip: 'AI Coding Assistant',
            onPressed: () => _openAiAssistant(),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: const Color(0xFF38BDF8),
              side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _openInChrome,
            icon: const Icon(TablerIcons.brand_chrome, size: 16),
            label: Text(
              isWide ? 'View in Chrome' : 'Chrome',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: UEColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: UEColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? UEColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        TablerIcons.code,
                        size: 15,
                        color: _selectedTab == 0 ? Colors.white : UEColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Code Editor',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 0 ? Colors.white : UEColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _runCode();
                setState(() => _selectedTab = 1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? UEColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        TablerIcons.world,
                        size: 15,
                        color: _selectedTab == 1 ? Colors.white : UEColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live Preview',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 1 ? Colors.white : UEColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D1214),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(TablerIcons.bug, color: Color(0xFFF87171), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _lastError!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFFFCA5A5),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFFF87171),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              _openAiAssistant(
                initialPrompt: 'Fix this browser runtime error: $_lastError',
              );
            },
            icon: const Icon(TablerIcons.sparkles, size: 14),
            label: const Text('Fix with AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(TablerIcons.x, size: 16, color: Color(0xFFFCA5A5)),
            onPressed: () => setState(() => _lastError = null),
          ),
        ],
      ),
    );
  }
}
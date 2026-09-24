import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../services/codelab_ai_service.dart';

class AICoderSheet extends StatefulWidget {
  final String currentCode;
  final String? initialPrompt;
  final ValueChanged<String> onApplyCode;

  const AICoderSheet({
    super.key,
    required this.currentCode,
    this.initialPrompt,
    required this.onApplyCode,
  });

  @override
  State<AICoderSheet> createState() => _AICoderSheetState();
}

class _AICoderSheetState extends State<AICoderSheet> {
  final TextEditingController _promptController = TextEditingController();
  final CodeLabAIService _aiService = CodeLabAIService.instance;

  String _responseAccumulator = '';
  bool _isGenerating = false;
  String? _extractedHtml;
  StreamSubscription<String>? _streamSub;

  final List<String> _quickPrompts = [
    '✨ Add a button that changes the background color',
    '📱 Build a simple M-Pesa balance checker',
    '🎨 Create a dark mode toggle button',
    '⏱️ Add a 10-second countdown timer',
    '💡 Explain how this code works step by step',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _promptController.text = widget.initialPrompt!;
      _submitPrompt();
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _promptController.dispose();
    super.dispose();
  }

  void _submitPrompt([String? explicitPrompt]) {
    final prompt = explicitPrompt ?? _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _responseAccumulator = '';
      _extractedHtml = null;
    });

    _streamSub?.cancel();

    if (prompt.toLowerCase().startsWith('explain')) {
      _streamSub = _aiService.explainCodeStream(codeSnippet: widget.currentCode, specificQuestion: prompt).listen(
        (token) {
          setState(() {
            _responseAccumulator += token;
          });
        },
        onDone: () {
          setState(() {
            _isGenerating = false;
          });
        },
        onError: (err) {
          setState(() {
            _isGenerating = false;
            _responseAccumulator = '⚠️ Error: ${err.toString()}';
          });
        },
      );
    } else {
      _streamSub = _aiService.generateWebProjectStream(
        studentPrompt: prompt,
        currentCode: widget.currentCode,
      ).listen(
        (token) {
          setState(() {
            _responseAccumulator += token;
          });
        },
        onDone: () {
          final html = _aiService.extractHtmlFromResponse(_responseAccumulator);
          setState(() {
            _isGenerating = false;
            _extractedHtml = html;
          });
        },
        onError: (err) {
          setState(() {
            _isGenerating = false;
            _responseAccumulator = '⚠️ Generation Error: ${err.toString()}';
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF11141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: UEColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: UEColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: UEColors.violet.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(TablerIcons.sparkles, color: UEColors.violet, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elimu AI Code Tutor',
                    style: UETypography.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: UEColors.textPrimary,
                    ),
                  ),
                  Text(
                    '100% On-Device Pair Programmer',
                    style: UETypography.inter(fontSize: 11, color: UEColors.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(TablerIcons.x, size: 20, color: UEColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick prompt chips
          if (_responseAccumulator.isEmpty && !_isGenerating) ...[
            Text('Quick Ideas:', style: UETypography.inter(fontSize: 12, color: UEColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _quickPrompts.map((p) {
                return InkWell(
                  onTap: () {
                    _promptController.text = p.substring(2).trim();
                    _submitPrompt();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2330),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: UEColors.border),
                    ),
                    child: Text(
                      p,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFC7D2FE)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          // Response Display Area
          if (_responseAccumulator.isNotEmpty || _isGenerating) ...[
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: UEColors.border),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _responseAccumulator,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          color: Color(0xFFE2E8F0),
                          height: 1.45,
                        ),
                      ),
                      if (_isGenerating) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: UEColors.violet),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thinking & Coding offline...',
                              style: UETypography.inter(fontSize: 11, color: UEColors.violet),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Apply Code Button
            if (_extractedHtml != null && !_isGenerating) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UEColors.green,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    widget.onApplyCode(_extractedHtml!);
                    Navigator.pop(context);
                  },
                  icon: const Icon(TablerIcons.code_plus, size: 18),
                  label: const Text(
                    'Apply Code to Editor & Run 🚀',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ] else
            const Spacer(),

          const SizedBox(height: 12),
          // Input Box
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181C26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: UEColors.border),
                  ),
                  child: TextField(
                    controller: _promptController,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'What should we build or change?',
                      hintStyle: TextStyle(color: UEColors.textMuted, fontSize: 13),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submitPrompt(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: UEColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(TablerIcons.send, size: 18, color: Colors.white),
                onPressed: _isGenerating ? null : () => _submitPrompt(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

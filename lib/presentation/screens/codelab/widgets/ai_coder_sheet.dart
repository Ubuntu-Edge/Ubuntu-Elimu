import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../models/code_action.dart';
import '../../../../services/codelab_agent_loop.dart';
import '../../../../services/codelab_ai_service.dart';
import 'diff_view_sheet.dart';

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
  final CodeLabAgentLoop _agentLoop = CodeLabAgentLoop.instance;
  final CodeLabAIService _aiService = CodeLabAIService.instance;

  final List<AgentLoopUpdate> _loopUpdates = [];
  String _responseAccumulator = '';
  bool _isGenerating = false;
  String? _stagedCode;
  List<DiffLine> _currentDiff = [];
  StreamSubscription? _activeSub;

  final List<String> _quickPrompts = [
    '🎨 Change button color to glowing emerald green',
    '📱 Add an M-Pesa transaction fee calculator',
    '⏱️ Add a 10-second countdown timer',
    '💡 Explain how this code works step by step',
    '🐛 Fix any syntax or runtime bugs',
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
    _activeSub?.cancel();
    _promptController.dispose();
    super.dispose();
  }

  void _submitPrompt([String? explicitPrompt]) {
    final prompt = explicitPrompt ?? _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _loopUpdates.clear();
      _responseAccumulator = '';
      _stagedCode = null;
      _currentDiff = [];
    });

    _activeSub?.cancel();

    if (prompt.toLowerCase().startsWith('explain')) {
      // Explanation mode
      _activeSub = _aiService.explainCodeStream(
        codeSnippet: widget.currentCode,
        specificQuestion: prompt,
      ).listen(
        (token) {
          setState(() {
            _responseAccumulator += token;
          });
        },
        onDone: () => setState(() => _isGenerating = false),
        onError: (err) => setState(() {
          _isGenerating = false;
          _responseAccumulator = '⚠️ Error: $err';
        }),
      );
    } else {
      // Fast Agentic Delta Loop (Plan -> Act -> Observe)
      _activeSub = _agentLoop.runEditLoop(
        prompt: prompt,
        currentCode: widget.currentCode,
      ).listen(
        (update) {
          setState(() {
            _loopUpdates.add(update);
            if (update.finalCode != null) {
              _stagedCode = update.finalCode;
            }
            if (update.deltaResult != null && update.deltaResult!.diff.isNotEmpty) {
              _currentDiff = update.deltaResult!.diff;
            }
          });
        },
        onDone: () => setState(() => _isGenerating = false),
        onError: (err) => setState(() {
          _isGenerating = false;
          _loopUpdates.add(AgentLoopUpdate(
            step: AgentStep.error,
            message: 'Agent Loop Error: $err',
          ));
        }),
      );
    }
  }

  void _openDiffViewer() {
    if (_stagedCode == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DiffViewSheet(
        diff: _currentDiff,
        title: _promptController.text,
        onAccept: () {
          widget.onApplyCode(_stagedCode!);
          Navigator.pop(context); // close parent sheet too
        },
        onUndo: () {
          setState(() {
            _stagedCode = null;
            _currentDiff = [];
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUpdates = _loopUpdates.isNotEmpty;
    final hasTextResponse = _responseAccumulator.isNotEmpty;

    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = viewInsets.bottom;
    // Use up to 85% of available screen height (minus keyboard) so we never overflow
    final maxSheetHeight = screenHeight * 0.85;
    final availableHeight = maxSheetHeight - keyboardHeight;

    return Container(
      height: availableHeight.clamp(300.0, maxSheetHeight),
      padding: EdgeInsets.only(
        bottom: keyboardHeight > 0 ? 8 : 16,
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
                  color: UEColors.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(TablerIcons.sparkles, color: UEColors.violet, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elimu Agentic Code Tutor',
                    style: UETypography.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: UEColors.textPrimary,
                    ),
                  ),
                  Text(
                    'On-Device Delta Editing & Runtime Verification',
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
          if (!hasUpdates && !hasTextResponse && !_isGenerating) ...[
            Text('Quick Instructions:', style: UETypography.inter(fontSize: 12, color: UEColors.textMuted)),
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

          // Agent Loop Step Pipeline Display
          if (hasUpdates) ...[
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: UEColors.border),
                ),
                child: ListView.separated(
                  itemCount: _loopUpdates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = _loopUpdates[index];
                    return _buildStepRow(u);
                  },
                ),
              ),
            ),
            // Actions Toolbar (Diff / Apply)
            if (_stagedCode != null && !_isGenerating) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_currentDiff.isNotEmpty) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _openDiffViewer,
                      icon: const Icon(Icons.difference_outlined, size: 16),
                      label: const Text('View Diff', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UEColors.green,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        widget.onApplyCode(_stagedCode!);
                        Navigator.pop(context);
                      },
                      icon: const Icon(TablerIcons.bolt, size: 18),
                      label: const Text(
                        'Apply & Test Live ⚡',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else if (hasTextResponse) ...[
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: UEColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _responseAccumulator,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: Color(0xFFE2E8F0),
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ] else
            const Spacer(),

          const SizedBox(height: 12),
          // Prompt Input Box
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
                      hintText: 'e.g. "make button green", "add audio on click"',
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

  Widget _buildStepRow(AgentLoopUpdate u) {
    IconData icon;
    Color iconColor;

    switch (u.step) {
      case AgentStep.thinking:
        icon = TablerIcons.brain;
        iconColor = UEColors.violet;
        break;
      case AgentStep.actionProposed:
        icon = TablerIcons.tools;
        iconColor = const Color(0xFF38BDF8);
        break;
      case AgentStep.deltaApplied:
        icon = TablerIcons.git_commit;
        iconColor = const Color(0xFFFBBF24);
        break;
      case AgentStep.verifyingRuntime:
        icon = TablerIcons.device_laptop;
        iconColor = const Color(0xFFA78BFA);
        break;
      case AgentStep.success:
        icon = TablerIcons.circle_check;
        iconColor = UEColors.green;
        break;
      case AgentStep.error:
        icon = TablerIcons.alert_triangle;
        iconColor = const Color(0xFFF87171);
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            u.message,
            style: TextStyle(
              fontSize: 12.5,
              color: u.step == AgentStep.error ? const Color(0xFFFCA5A5) : UEColors.textPrimary,
              fontWeight: u.step == AgentStep.success ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'widgets/topic_input_form.dart';
import 'widgets/report_output_view.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  bool _isGenerating = false;
  String _generatedTopic = '';
  String _generatedContent = '';

  void _generateReport(String topic, String depth, String length) async {
    setState(() {
      _isGenerating = true;
    });

    // Simulate local LLM text generation
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isGenerating = false;
      _generatedTopic = topic;
      _generatedContent =
          'Summary: Local synthesis of "$topic" generated with $depth detail level and $length formatting.\n\n'
          'Key Findings:\n'
          '1. Primary mechanisms are highly correlated with core biochemical structures analyzed in local lecture materials.\n'
          '2. Energy pathways utilize spontaneous delta G interactions as verified by thermodynamics calculations.\n'
          '3. Experimental observations confirm Socratic predictions with an accuracy of 92% across test cycles.\n\n'
          'Recommendation:\n'
          'Proceed to Chapter 8 exercises in Library view to validate secondary kinetic models offline.';
    });
  }

  void _clear() {
    setState(() {
      _generatedTopic = '';
      _generatedContent = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          TopicInputForm(
            onGenerate: _generateReport,
            isGenerating: _isGenerating,
          ),
          if (_generatedTopic.isNotEmpty) ...[
            const SizedBox(height: 20),
            ReportOutputView(
              topic: _generatedTopic,
              content: _generatedContent,
              onClear: _clear,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget to display AI responses with formatted sections (Assessment, Action, Important)
/// Enhanced for emergency situations with clear, professional formatting
class FormattedAIMessage extends StatelessWidget {
  final String message;
  final bool isEmergency;

  const FormattedAIMessage({
    super.key, 
    required this.message,
    this.isEmergency = false,
  });

  Map<String, String> _parseSections(String text) {
    final sections = <String, String>{};
    
    // Try to find Assessment section
    final assessmentMatch = RegExp(
      r'(?:Assessment|Tathmini):\s*([^\n]+(?:\n(?!(?:Action|Hatua|Important|Muhimu):)[^\n]+)*)',
      caseSensitive: false,
    ).firstMatch(text);
    
    // Try to find Action section
    final actionMatch = RegExp(
      r'(?:Action|Hatua):\s*([^\n]+(?:\n(?!(?:Important|Muhimu):)[^\n]+)*)',
      caseSensitive: false,
    ).firstMatch(text);
    
    // Try to find Important section
    final importantMatch = RegExp(
      r'(?:Important|Muhimu):\s*(.+)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(text);
    
    if (assessmentMatch != null) {
      sections['assessment'] = assessmentMatch.group(1)!.trim();
    }
    if (actionMatch != null) {
      sections['action'] = actionMatch.group(1)!.trim();
    }
    if (importantMatch != null) {
      sections['important'] = importantMatch.group(1)!.trim();
    }
    
    return sections;
  }
  
  // Check if the message contains emergency keywords
  bool _containsEmergencyKeywords(String text) {
    final emergencyKeywords = [
      'urgent', 'emergency', 'immediately', 'hospital', 'ambulance', 
      'danger', 'critical', 'severe', 'life-threatening',
      'haraka', 'dharura', 'hospitali', 'hatari', 'mbaya sana',
    ];
    final lowerText = text.toLowerCase();
    return emergencyKeywords.any((keyword) => lowerText.contains(keyword));
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parseSections(message);
    final hasEmergencyContent = isEmergency || _containsEmergencyKeywords(message);
    
    // If no sections found, return formatted plain text
    if (sections.isEmpty) {
      return _buildPlainTextResponse(context, message);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emergency Banner (if applicable)
        if (hasEmergencyContent) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.toLowerCase().contains('haraka') || message.toLowerCase().contains('dharura')
                        ? 'Kesi hii inahitaji uangalifu wa haraka'
                        : 'This case requires urgent attention',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Assessment Section
        if (sections.containsKey('assessment')) ...[
          _buildSection(
            context: context,
            icon: Icons.medical_information_outlined,
            title: message.toLowerCase().contains('tathmini') ? 'Tathmini' : 'Assessment',
            content: sections['assessment']!,
            color: Colors.blue,
            priority: 1,
          ),
          const SizedBox(height: 12),
        ],
        
        // Action Section
        if (sections.containsKey('action')) ...[
          _buildSection(
            context: context,
            icon: Icons.healing_outlined,
            title: message.toLowerCase().contains('hatua') ? 'Hatua' : 'What to Do',
            content: sections['action']!,
            color: Colors.green,
            priority: 2,
          ),
          const SizedBox(height: 12),
        ],
        
        // Important Section
        if (sections.containsKey('important')) ...[
          _buildSection(
            context: context,
            icon: hasEmergencyContent ? Icons.emergency_outlined : Icons.info_outline,
            title: message.toLowerCase().contains('muhimu') ? 'Muhimu' : 'Important',
            content: sections['important']!,
            color: hasEmergencyContent ? Colors.red : Colors.orange,
            priority: 3,
            isHighlighted: hasEmergencyContent,
          ),
        ],
        
        // Quick action buttons for emergency
        if (hasEmergencyContent) ...[
          const SizedBox(height: 16),
          _buildQuickActions(context),
        ],
      ],
    );
  }
  
  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required MaterialColor color,
    required int priority,
    bool isHighlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? color[400]! : color[200]!,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color[600],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color[800],
                  ),
                ),
                const Spacer(),
                // Copy button
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title copied'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Icon(Icons.copy_outlined, size: 16, color: color[600]),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlainTextResponse(BuildContext context, String text) {
    // Parse bullet points and numbered lists for better formatting
    final lines = text.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmedLine = line.trim();
        
        // Check for bullet points
        if (trimmedLine.startsWith('•') || trimmedLine.startsWith('-') || trimmedLine.startsWith('*')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    trimmedLine.substring(1).trim(),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }
        
        // Check for numbered lists
        final numberMatch = RegExp(r'^(\d+)[.)\]]\s*').firstMatch(trimmedLine);
        if (numberMatch != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${numberMatch.group(1)}.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    trimmedLine.substring(numberMatch.end).trim(),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }
        
        // Regular text
        return trimmedLine.isEmpty 
            ? const SizedBox(height: 8)
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SelectableText(
                  trimmedLine,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              );
      }).toList(),
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    final isSwahili = message.toLowerCase().contains('haraka') || 
                      message.toLowerCase().contains('hospitali') ||
                      message.toLowerCase().contains('hatua');
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Copy entire message for sharing
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isSwahili ? 'Imenakiliwa' : 'Copied to clipboard'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.share_outlined, size: 18),
            label: Text(isSwahili ? 'Shiriki' : 'Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              side: BorderSide(color: Colors.blue[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}

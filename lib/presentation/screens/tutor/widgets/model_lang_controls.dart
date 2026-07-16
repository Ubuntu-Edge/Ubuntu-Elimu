import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../models/chat_message.dart';

/// Shows only the language selector + Socratic mode badge.
/// Model chips (3B / 1B Lite) have been removed — model selection is
/// handled internally by the AI provider.
class ModelLangControls extends StatelessWidget {
  final Language selectedLanguage;
  final bool socraticMode;
  final VoidCallback onLanguageTap;
  final VoidCallback onSocraticTap;

  const ModelLangControls({
    super.key,
    required this.selectedLanguage,
    required this.socraticMode,
    required this.onLanguageTap,
    required this.onSocraticTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LangPill(language: selectedLanguage, onTap: onLanguageTap),
        const Spacer(),
        GestureDetector(
          onTap: onSocraticTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: socraticMode ? UEColors.onlineBg : UEColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: socraticMode ? UEColors.onlineBorder : UEColors.bgBorder,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: socraticMode ? UEColors.online : UEColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  socraticMode ? 'Socratic on' : 'Socratic off',
                  style: UETypography.caption.copyWith(
                    color: socraticMode ? UEColors.online : UEColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LangPill extends StatelessWidget {
  final Language language;
  final VoidCallback onTap;

  const _LangPill({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: UEColors.violet, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate_rounded, size: 12, color: UEColors.violet),
            const SizedBox(width: 4),
            Text(
              'EN → ${language.label}',
              style: UETypography.label.copyWith(
                color: UEColors.violet,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
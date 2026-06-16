import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../providers/settings_provider.dart';

class ModelLangControls extends StatelessWidget {
  const ModelLangControls({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: UEColors.surface, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Socratic/Direct Toggle
          GestureDetector(
            onTap: () {
              settingsProvider.toggleSocraticMode(!settingsProvider.socraticMode);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: settingsProvider.socraticMode ? UEColors.iconBg : UEColors.surface,
                border: Border.all(
                  color: settingsProvider.socraticMode ? UEColors.accent : UEColors.border,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    TablerIcons.brain,
                    color: settingsProvider.socraticMode ? UEColors.accent : UEColors.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    settingsProvider.socraticMode ? 'Socratic Mode' : 'Direct Answers',
                    style: UETypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: settingsProvider.socraticMode ? UEColors.accent : UEColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Translation languages EN -> SW
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: UEColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: UEColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                _buildLangBtn(context, settingsProvider.sourceLanguage, () {
                  final newSrc = settingsProvider.sourceLanguage == 'EN' ? 'SW' : 'EN';
                  final newTgt = settingsProvider.targetLanguage == 'EN' ? 'SW' : 'EN';
                  settingsProvider.setLanguages(newSrc, newTgt);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    TablerIcons.arrow_narrow_right,
                    size: 14,
                    color: UEColors.textMuted,
                  ),
                ),
                _buildLangBtn(context, settingsProvider.targetLanguage, () {
                  final newSrc = settingsProvider.sourceLanguage == 'EN' ? 'SW' : 'EN';
                  final newTgt = settingsProvider.targetLanguage == 'EN' ? 'SW' : 'EN';
                  settingsProvider.setLanguages(newSrc, newTgt);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangBtn(BuildContext context, String code, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        code,
        style: UETypography.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: UEColors.textPrimary,
        ),
      ),
    );
  }
}

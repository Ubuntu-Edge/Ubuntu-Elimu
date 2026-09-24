import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../models/codelab_template.dart';

class TemplatesModal extends StatelessWidget {
  final ValueChanged<CodeLabTemplate> onSelectTemplate;

  const TemplatesModal({
    super.key,
    required this.onSelectTemplate,
  });

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'calculator':
        return TablerIcons.calculator;
      case 'paw':
        return TablerIcons.paw;
      case 'palette':
        return TablerIcons.palette;
      case 'planet':
        return TablerIcons.planet;
      case 'bulb':
        return TablerIcons.bulb;
      default:
        return TablerIcons.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    const templates = CodeLabTemplate.cbcCurriculumTemplates;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                  color: UEColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(TablerIcons.book, color: UEColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CBC STEM Starter Projects',
                    style: UETypography.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: UEColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Pre-loaded offline projects aligned with Kenyan curriculum',
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
          const SizedBox(height: 16),
          // List of templates
          Expanded(
            child: ListView.separated(
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = templates[index];
                final icon = _getIcon(item.iconName);

                return InkWell(
                  onTap: () {
                    onSelectTemplate(item);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A26),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: UEColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2538),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: const Color(0xFF38BDF8), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: UETypography.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: UEColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: UEColors.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: UEColors.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: UETypography.inter(
                                  fontSize: 12,
                                  color: UEColors.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(TablerIcons.chevron_right, size: 18, color: UEColors.textMuted),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

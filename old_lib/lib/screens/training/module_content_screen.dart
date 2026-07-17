import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/training_module.dart';
import '../../l10n/app_localizations.dart';

/// Screen for viewing training module content
class ModuleContentScreen extends StatefulWidget {
  final TrainingModule module;

  const ModuleContentScreen({super.key, required this.module});

  @override
  State<ModuleContentScreen> createState() => _ModuleContentScreenState();
}

class _ModuleContentScreenState extends State<ModuleContentScreen> {
  int _currentSectionIndex = 0;
  late PageController _pageController;
  final Set<int> _completedSections = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextSection() {
    if (_currentSectionIndex < widget.module.sections.length - 1) {
      _completedSections.add(_currentSectionIndex);
      setState(() {
        _currentSectionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Module completed
      _completedSections.add(_currentSectionIndex);
      _showCompletionDialog();
    }
  }

  void _goToPreviousSection() {
    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(FontAwesomeIcons.graduationCap, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate('moduleCompleted') ?? 'Module Completed!',
                style: AppTheme.headingSmall,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.success, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('congratulations') ?? 'Congratulations!',
                    style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.translate('completedAllSections') ?? "You've completed all sections of"} "${widget.module.title}"',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.module.quizzes.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.clipboardQuestion, color: AppColors.info, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.translate('takeQuizNow') ?? 'Take the quiz to test your knowledge!',
                        style: AppTheme.bodySmall.copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // Return true to indicate completion
            },
            child: Text(l10n.translate('backToModules') ?? 'Back to Modules'),
          ),
          if (widget.module.quizzes.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to quiz screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.translate('takeQuiz') ?? 'Take Quiz'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Section accessed directly in itemBuilder
    final progress = (_currentSectionIndex + 1) / widget.module.sections.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(l10n, progress),
            
            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.module.sections.length,
                onPageChanged: (index) {
                  setState(() => _currentSectionIndex = index);
                },
                itemBuilder: (context, index) {
                  return _buildSectionContent(widget.module.sections[index], l10n);
                },
              ),
            ),
            
            // Navigation
            _buildNavigationBar(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, double progress) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FaIcon(FontAwesomeIcons.xmark, color: AppColors.primary, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.module.title,
                      style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${l10n.translate('section') ?? 'Section'} ${_currentSectionIndex + 1} ${l10n.translate('of') ?? 'of'} ${widget.module.sections.length}',
                      style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(LearningSection section, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.secondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    _getSectionIcon(section.contentType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    section.title,
                    style: AppTheme.headingSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main content text
                Text(
                  _expandContent(section.content),
                  style: AppTheme.bodyMedium.copyWith(
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (section.imageAsset != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      section.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: FaIcon(FontAwesomeIcons.image, color: AppColors.textLight),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Key Points
          if (section.keyPoints.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.lightbulb, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.translate('keyPoints') ?? 'Key Points',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...section.keyPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            point,
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80), // Space for navigation bar
        ],
      ),
    );
  }

  Widget _buildNavigationBar(AppLocalizations l10n) {
    final isLastSection = _currentSectionIndex == widget.module.sections.length - 1;
    final isFirstSection = _currentSectionIndex == 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isFirstSection)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToPreviousSection,
                icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 14),
                label: Text(l10n.translate('previous') ?? 'Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _goToNextSection,
              icon: FaIcon(
                isLastSection ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.arrowRight,
                size: 14,
                color: Colors.white,
              ),
              label: Text(
                isLastSection 
                  ? (l10n.translate('complete') ?? 'Complete')
                  : (l10n.translate('next') ?? 'Next'),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastSection ? AppColors.success : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(LearningContentType type) {
    switch (type) {
      case LearningContentType.video:
        return FontAwesomeIcons.video;
      case LearningContentType.interactive:
        return FontAwesomeIcons.handPointer;
      case LearningContentType.caseStudy:
        return FontAwesomeIcons.bookMedical;
      default:
        return FontAwesomeIcons.bookOpen;
    }
  }

  /// Expand abbreviated content with more detailed explanations
  String _expandContent(String content) {
    // Map of abbreviated content to full explanations
    final contentExpansions = {
      'Introduction to community health concepts...': '''Community health focuses on the health and well-being of entire populations within a specific geographical area. As a Community Health Worker (CHW), you are a vital link between healthcare systems and communities.

Community health encompasses:
• Preventive care and health education
• Disease surveillance and outbreak response
• Maternal and child health services
• Chronic disease management
• Mental health support
• Environmental health initiatives

Your role is essential in ensuring communities have access to basic health services, especially in underserved areas where healthcare facilities may be distant or inaccessible.''',

      'Understanding your role as a CHW...': '''As a Community Health Worker, you serve as a trusted bridge between the healthcare system and your community. Your responsibilities include:

Primary Responsibilities:
• Conducting home visits to monitor patient health
• Providing health education and counseling
• Identifying individuals who need referral to health facilities
• Following up on patients after hospital discharge
• Tracking vital health indicators in the community

Key Skills Required:
• Effective communication and listening
• Cultural sensitivity and community understanding
• Basic health assessment abilities
• Accurate record-keeping and reporting
• Emergency recognition and response

Remember: You are often the first point of contact for health concerns in your community.''',

      'Ethical considerations in healthcare...': '''Ethics and confidentiality are fundamental to healthcare practice. As a CHW, you must uphold the highest standards of professional conduct.

Patient Rights:
• Right to privacy and confidentiality
• Right to informed consent
• Right to respectful treatment
• Right to refuse treatment
• Right to access their health records

Confidentiality Rules:
• Never share patient information without consent
• Store health records securely
• Discuss patient cases only with relevant healthcare providers
• Use privacy when conducting health assessments
• Report data only through official channels

Ethical Principles:
• Beneficence: Always act in the patient's best interest
• Non-maleficence: Do no harm
• Autonomy: Respect patient decisions
• Justice: Treat all patients fairly''',

      'Effective communication with patients...': '''Good communication is the foundation of effective healthcare delivery. These skills help you connect with patients and understand their needs.

Active Listening:
• Give your full attention to the speaker
• Avoid interrupting
• Ask clarifying questions
• Summarize what you've heard to confirm understanding
• Pay attention to non-verbal cues

Empathy in Practice:
• Acknowledge patient feelings
• Show genuine concern
• Avoid judgment
• Use supportive body language
• Validate their experiences

Communication Tips:
• Use simple, clear language
• Avoid medical jargon
• Speak at an appropriate pace
• Check for understanding
• Be patient and respectful''',

      'How to measure body temperature...': '''Accurate temperature measurement is essential for detecting fever and monitoring patient health.

Normal Body Temperature:
• Oral: 36.8°C (98.2°F)
• Axillary (armpit): 36.4°C (97.5°F)
• Range considered normal: 36.1°C - 37.2°C (97°F - 99°F)

Measurement Methods:
1. Digital Thermometer (Oral)
   - Place under tongue
   - Wait for beep
   - Record reading

2. Axillary (Armpit)
   - Place in dry armpit
   - Hold arm against body
   - Wait 3-5 minutes

3. Infrared (Forehead)
   - Point at center of forehead
   - Keep 1-2 inches away
   - Take reading

Fever Classifications:
• Low-grade: 37.3°C - 38°C
• Moderate: 38.1°C - 39°C
• High: Above 39°C (requires medical attention)''',

      'Understanding blood pressure...': '''Blood pressure is a vital indicator of cardiovascular health. Understanding how to measure and interpret it is crucial.

Blood Pressure Basics:
• Systolic: Pressure when heart beats (top number)
• Diastolic: Pressure between beats (bottom number)
• Measured in mmHg (millimeters of mercury)

Normal Ranges:
• Normal: Less than 120/80 mmHg
• Elevated: 120-129/<80 mmHg
• High Stage 1: 130-139/80-89 mmHg
• High Stage 2: ≥140/≥90 mmHg
• Crisis: >180/>120 mmHg (emergency)

Measurement Tips:
• Patient should rest 5 minutes before measuring
• Use appropriate cuff size
• Position arm at heart level
• Take multiple readings if uncertain
• Record time and position''',

      'Measuring pulse and breathing...': '''Pulse and respiratory rate provide important information about a patient's overall condition.

Pulse Assessment:
• Normal adult rate: 60-100 beats per minute
• Children (1-10 years): 70-120 bpm
• Infants: 100-160 bpm

How to Measure:
1. Locate radial pulse (wrist) or carotid pulse (neck)
2. Use index and middle finger (not thumb)
3. Count beats for 30 seconds, multiply by 2
4. Note rhythm and strength

Respiratory Rate:
• Normal adult: 12-20 breaths per minute
• Children: 20-30 breaths per minute
• Infants: 30-60 breaths per minute

Breathing Assessment:
• Watch chest rise and fall
• Count for 30 seconds without patient awareness
• Note depth, rhythm, and effort
• Listen for abnormal sounds''',

      'When to be concerned...': '''Recognizing abnormal vital signs is critical for timely intervention and appropriate referral.

Warning Signs - Immediate Referral:
• Temperature >39°C or <35°C
• Blood pressure >180/120 or <90/60 mmHg
• Pulse >120 or <50 beats per minute
• Respiratory rate >30 or <10 per minute
• Oxygen saturation <92%

Additional Red Flags:
• Difficulty breathing or gasping
• Blue lips or fingernails (cyanosis)
• Confusion or altered consciousness
• Severe headache with high BP
• Chest pain with abnormal vitals

Referral Criteria:
• Stable but concerning values: Refer within 24 hours
• Unstable or dangerous values: Refer immediately
• Life-threatening values: Emergency transport required

Always document your findings and communicate clearly to the receiving facility.''',

      // Default for any other abbreviated content
      'default': 'This section contains important training content. Please review carefully and note the key points highlighted below.',
    };

    // Return expanded content if available, otherwise return original with default expansion
    if (contentExpansions.containsKey(content)) {
      return contentExpansions[content]!;
    }
    
    // If content ends with '...', it's likely abbreviated
    if (content.endsWith('...')) {
      return '${content.substring(0, content.length - 3)}\n\n${contentExpansions['default']}';
    }
    
    return content;
  }
}

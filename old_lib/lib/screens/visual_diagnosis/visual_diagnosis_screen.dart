import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/visual_diagnosis.dart';
import '../../services/visual_diagnosis_service.dart';
import '../../services/visual_diagnosis_api_service.dart' as api;
import '../../l10n/app_localizations.dart';

class VisualDiagnosisScreen extends StatefulWidget {
  const VisualDiagnosisScreen({super.key});

  @override
  State<VisualDiagnosisScreen> createState() => _VisualDiagnosisScreenState();
}

class _VisualDiagnosisScreenState extends State<VisualDiagnosisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VisualDiagnosisService _localDiagnosisService =
      VisualDiagnosisService();
  final api.VisualDiagnosisApiService _apiService =
      api.VisualDiagnosisApiService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Backend data
  List<api.VisualDiagnosisResult> _apiDiagnoses = [];
  List<api.ReferenceImage> _referenceImages = [];
  // ignore: unused_field
  api.DiagnosisStats? _stats;
  bool _isLoadingHistory = false;
  bool _isLoadingReferences = false;
  final bool _useBackend = true; // Toggle between backend and local

  File? _selectedImage;
  String _selectedBodyPart = 'skin';
  bool _isAnalyzing = false;
  VisualDiagnosis? _currentDiagnosis;

  final List<Map<String, dynamic>> _bodyParts = [
    {'id': 'skin', 'name': 'Skin', 'icon': Icons.person},
    {'id': 'eye', 'name': 'Eye', 'icon': Icons.remove_red_eye},
    {'id': 'mouth', 'name': 'Mouth/Throat', 'icon': Icons.face},
    {'id': 'ear', 'name': 'Ear', 'icon': Icons.hearing},
    {'id': 'wound', 'name': 'Wound', 'icon': Icons.healing},
    {'id': 'nail', 'name': 'Nail', 'icon': Icons.back_hand},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadDiagnosisHistory(),
      _loadReferenceImages(),
      _loadStats(),
    ]);
  }

  Future<void> _loadDiagnosisHistory() async {
    if (!_useBackend) return;

    setState(() => _isLoadingHistory = true);
    try {
      final result = await _apiService.listDiagnoses();
      setState(() {
        _apiDiagnoses = result.items;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      // Fall back to local service silently
      debugPrint('Backend unavailable for diagnoses: $e');
    }
  }

  Future<void> _loadReferenceImages() async {
    if (!_useBackend) return;

    setState(() => _isLoadingReferences = true);
    try {
      final images = await _apiService.getReferenceImages(
        category: _selectedBodyPart,
      );
      setState(() {
        _referenceImages = images;
        _isLoadingReferences = false;
      });
    } catch (e) {
      setState(() => _isLoadingReferences = false);
      debugPrint('Backend unavailable for reference images: $e');
    }
  }

  Future<void> _loadStats() async {
    if (!_useBackend) return;

    try {
      final stats = await _apiService.getStats();
      setState(() => _stats = stats);
    } catch (e) {
      debugPrint('Backend unavailable for stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('visualDiagnosis') ?? 'Visual Diagnosis',
            style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTheme.labelMedium,
          tabs: [
            Tab(text: l10n.translate('capture') ?? 'Capture'),
            Tab(text: l10n.translate('reference') ?? 'Reference'),
            Tab(text: l10n.translate('history') ?? 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCaptureTab(),
          _buildReferenceTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCaptureTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: AppColors.info, size: 32),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        l10n.translate('visualAssessmentAid') ??
                            'Visual Assessment Aid',
                        style: AppTheme.labelMedium),
                    Text(
                      l10n.translate('visualAssessmentDesc') ??
                          'Capture images to get AI-assisted visual condition assessment. This is a support tool, not a replacement for clinical diagnosis.',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Body part selection
        Text(l10n.translate('selectBodyPart') ?? 'Select Body Part',
            style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children:
              _bodyParts.map((part) => _buildBodyPartChip(part, l10n)).toList(),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Image capture area
        Text(l10n.translate('captureImage') ?? 'Capture Image',
            style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),
        _buildImageCapture(l10n),
        const SizedBox(height: AppTheme.spacingMd),

        // Analysis result
        if (_currentDiagnosis != null) _buildAnalysisResult(l10n),
      ],
    );
  }

  Widget _buildBodyPartChip(Map<String, dynamic> part, AppLocalizations l10n) {
    final isSelected = _selectedBodyPart == part['id'];

    // Get localized body part name
    String getLocalizedName(String id) {
      switch (id) {
        case 'skin':
          return l10n.translate('skin') ?? 'Skin';
        case 'eye':
          return l10n.translate('eye') ?? 'Eye';
        case 'mouth':
          return l10n.translate('mouthThroat') ?? 'Mouth/Throat';
        case 'ear':
          return l10n.translate('ear') ?? 'Ear';
        case 'wound':
          return l10n.translate('wound') ?? 'Wound';
        case 'nail':
          return l10n.translate('nail') ?? 'Nail';
        default:
          return part['name'] as String;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBodyPart = part['id'];
          _currentDiagnosis = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          boxShadow: isSelected ? AppTheme.shadowSm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              part['icon'] as IconData,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              getLocalizedName(part['id'] as String),
              style: AppTheme.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCapture(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          // Image preview
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd)),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusMd)),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo,
                          size: 48,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        l10n.translate('noImageCaptured') ??
                            'No image captured',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
          ),

          // Capture buttons
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, color: AppColors.primary),
                    label: Text(l10n.translate('gallery') ?? 'Gallery',
                        style: AppTheme.labelMedium
                            .copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(l10n.translate('camera') ?? 'Camera',
                        style:
                            AppTheme.labelMedium.copyWith(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Analyze button
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.spacingMd,
                right: AppTheme.spacingMd,
                bottom: AppTheme.spacingMd,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeImage,
                  icon: _isAnalyzing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isAnalyzing
                        ? (l10n.translate('analyzing') ?? 'Analyzing...')
                        : (l10n.translate('analyzeImage') ?? 'Analyze Image'),
                    style: AppTheme.labelMedium.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingMd),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(AppLocalizations l10n) {
    final diagnosis = _currentDiagnosis!;
    // Primary condition available via diagnosis.matchedConditions.first if needed

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd)),
            ),
            child: Row(
              children: [
                Icon(Icons.assessment, color: AppColors.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Text(l10n.translate('analysisResults') ?? 'Analysis Results',
                    style: AppTheme.headingSmall),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Confidence
                Row(
                  children: [
                    Text(
                        '${l10n.translate('confidenceLevel') ?? 'Confidence'}:',
                        style: AppTheme.labelMedium),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: diagnosis.confidenceScore ?? 0,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation(
                          (diagnosis.confidenceScore ?? 0) > 0.7
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      '${((diagnosis.confidenceScore ?? 0) * 100).toInt()}%',
                      style: AppTheme.labelMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Possible conditions
                Text(
                    '${l10n.translate('possibleCondition') ?? 'Possible Conditions'}:',
                    style: AppTheme.labelMedium),
                const SizedBox(height: AppTheme.spacingSm),
                ...diagnosis.matchedConditions.map((condition) => Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(condition, style: AppTheme.bodyMedium),
                        ],
                      ),
                    )),
                const SizedBox(height: AppTheme.spacingMd),

                // Recommendations
                Text(
                    '${l10n.translate('recommendations') ?? 'Recommendations'}:',
                    style: AppTheme.labelMedium),
                const SizedBox(height: AppTheme.spacingSm),
                ...diagnosis.matchedConditions.map((rec) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTheme.spacingXs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: AppColors.success),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(rec, style: AppTheme.bodySmall),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: AppTheme.spacingMd),

                // Referral indicator
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: diagnosis.isFlagged
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: diagnosis.isFlagged
                          ? AppColors.warning.withValues(alpha: 0.5)
                          : AppColors.success.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        diagnosis.isFlagged ? Icons.warning : Icons.check,
                        color: diagnosis.isFlagged
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          diagnosis.isFlagged
                              ? (l10n.translate('referralNeeded') ??
                                  'Referral to health facility recommended')
                              : (l10n.translate('referralNotNeeded') ??
                                  'Can be managed at community level'),
                          style: AppTheme.labelMedium.copyWith(
                            color: diagnosis.isFlagged
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceTab() {
    final l10n = AppLocalizations.of(context);

    // Use backend reference images if available, otherwise fall back to local
    if (_useBackend && _referenceImages.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Category filter
          Text(l10n.translate('filterByType') ?? 'Filter by Type',
              style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingSm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _bodyParts
                  .map((part) => Padding(
                        padding:
                            const EdgeInsets.only(right: AppTheme.spacingSm),
                        child: FilterChip(
                          label: Text(part['name'] as String),
                          selected: _selectedBodyPart == part['id'],
                          onSelected: (selected) {
                            setState(
                                () => _selectedBodyPart = part['id'] as String);
                            _loadReferenceImages();
                          },
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          if (_isLoadingReferences)
            const Center(child: CircularProgressIndicator())
          else ...[
            Text(l10n.translate('referenceImages') ?? 'Reference Images',
                style: AppTheme.headingSmall),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '${_referenceImages.length} images for $_selectedBodyPart conditions',
              style:
                  AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Grid of reference images
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: AppTheme.spacingSm,
                mainAxisSpacing: AppTheme.spacingSm,
              ),
              itemCount: _referenceImages.length,
              itemBuilder: (context, index) =>
                  _buildReferenceImageCard(_referenceImages[index]),
            ),
          ],
        ],
      );
    }

    // Fall back to local static reference
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        Text(l10n.translate('commonConditions') ?? 'Visual Reference Guide',
            style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          l10n.translate('searchConditions') ??
              'Common conditions for visual identification',
          style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Reference cards for common conditions
        ...CommonVisualConditions.conditions
            .take(8)
            .map((c) => _buildReferenceCard(c)),
      ],
    );
  }

  Widget _buildReferenceImageCard(api.ReferenceImage image) {
    return GestureDetector(
      onTap: () => _showReferenceImageDetail(image),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder (would load from URL in production)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd)),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(image.category),
                  size: 40,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.conditionName,
                    style: AppTheme.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          image.category,
                          style: AppTheme.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'skin':
        return Icons.local_florist;
      case 'eye':
        return Icons.remove_red_eye;
      case 'mouth':
        return Icons.sentiment_very_satisfied;
      case 'ear':
        return Icons.hearing;
      case 'wound':
        return Icons.healing;
      default:
        return Icons.medical_services;
    }
  }

  void _showReferenceImageDetail(api.ReferenceImage image) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  // Image
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(image.category),
                        size: 80,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  Text(image.conditionName, style: AppTheme.headingSmall),
                  const SizedBox(height: AppTheme.spacingSm),

                  Row(
                    children: [
                      _buildInfoChip(
                          'Category', image.category, AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  if (image.description != null) ...[
                    Text('Description', style: AppTheme.labelMedium),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(image.description!, style: AppTheme.bodySmall),
                    const SizedBox(height: AppTheme.spacingMd),
                  ],

                  if (image.symptoms.isNotEmpty) ...[
                    Text('Symptoms', style: AppTheme.labelMedium),
                    const SizedBox(height: AppTheme.spacingSm),
                    Wrap(
                      spacing: AppTheme.spacingSm,
                      runSpacing: AppTheme.spacingSm,
                      children: image.symptoms
                          .map((symptom) => Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(symptom,
                                    style: AppTheme.labelSmall
                                        .copyWith(color: AppColors.warning)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        '$label: $value',
        style: AppTheme.labelSmall.copyWith(color: color),
      ),
    );
  }

  // TODO: May be needed later
  // Color _getSeverityColor(String severity) {
  //   switch (severity.toLowerCase()) {
  //     case 'mild':
  //       return AppColors.success;
  //     case 'moderate':
  //       return AppColors.warning;
  //     case 'severe':
  //       return AppColors.error;
  //     default:
  //       return AppColors.textSecondary;
  //   }
  // }

  Color _getApiSeverityColor(api.DiagnosisSeverity? severity) {
    if (severity == null) return AppColors.textSecondary;
    switch (severity) {
      case api.DiagnosisSeverity.mild:
        return AppColors.success;
      case api.DiagnosisSeverity.moderate:
        return AppColors.warning;
      case api.DiagnosisSeverity.severe:
      case api.DiagnosisSeverity.critical:
        return AppColors.error;
    }
  }

  IconData _getApiConditionTypeIcon(api.DiagnosisType type) {
    switch (type) {
      case api.DiagnosisType.skin:
        return Icons.local_florist;
      case api.DiagnosisType.eye:
        return Icons.remove_red_eye;
      case api.DiagnosisType.mouth:
        return Icons.sentiment_very_satisfied;
      case api.DiagnosisType.ear:
        return Icons.hearing;
      case api.DiagnosisType.wound:
        return Icons.healing;
      case api.DiagnosisType.nail:
        return Icons.back_hand;
    }
  }

  String _getApiDiagnosisTypeName(api.DiagnosisType type) {
    switch (type) {
      case api.DiagnosisType.skin:
        return 'Skin';
      case api.DiagnosisType.eye:
        return 'Eye';
      case api.DiagnosisType.mouth:
        return 'Mouth/Throat';
      case api.DiagnosisType.ear:
        return 'Ear';
      case api.DiagnosisType.wound:
        return 'Wound';
      case api.DiagnosisType.nail:
        return 'Nail';
    }
  }

  Widget _buildReferenceCard(Map<String, dynamic> condition) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            _getConditionTypeIcon(condition['type'] as String),
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(condition['name'] as String, style: AppTheme.labelMedium),
        subtitle: Text(
          condition['type'] as String,
          style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description:', style: AppTheme.labelSmall),
                Text(condition['description'] as String,
                    style: AppTheme.bodySmall),
                const SizedBox(height: AppTheme.spacingSm),
                Text('Symptoms:', style: AppTheme.labelSmall),
                ...(condition['symptoms'] as List<String>)
                    .map((sign) => Padding(
                          padding: const EdgeInsets.only(
                              left: AppTheme.spacingSm, top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 6, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(sign, style: AppTheme.bodySmall)),
                            ],
                          ),
                        )),
                const SizedBox(height: AppTheme.spacingSm),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: (condition['requiresReferral'] as bool)
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (condition['requiresReferral'] as bool)
                            ? Icons.local_hospital
                            : Icons.home,
                        size: 16,
                        color: (condition['requiresReferral'] as bool)
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (condition['requiresReferral'] as bool)
                            ? 'Needs referral'
                            : 'Community manageable',
                        style: AppTheme.labelSmall.copyWith(
                          color: (condition['requiresReferral'] as bool)
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final l10n = AppLocalizations.of(context);

    // Use backend history if available
    if (_useBackend && (_apiDiagnoses.isNotEmpty || _isLoadingHistory)) {
      if (_isLoadingHistory) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_apiDiagnoses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: AppTheme.spacingMd),
              Text(l10n.translate('noAssessmentsYet') ?? 'No diagnosis history',
                  style: AppTheme.headingSmall
                      .copyWith(color: AppColors.textSecondary)),
              Text(
                l10n.translate('captureFirstImage') ??
                    'Captured images and analyses will appear here',
                style:
                    AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextButton.icon(
                onPressed: _loadDiagnosisHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadDiagnosisHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          itemCount: _apiDiagnoses.length,
          itemBuilder: (context, index) {
            final diagnosis = _apiDiagnoses[index];
            final confidenceScore = diagnosis.confidenceScore ?? 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.shadowSm,
              ),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getApiSeverityColor(diagnosis.severity)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    _getApiConditionTypeIcon(diagnosis.diagnosisType),
                    color: _getApiSeverityColor(diagnosis.severity),
                  ),
                ),
                title: Text(
                  diagnosis.matchedConditions.isNotEmpty
                      ? diagnosis.matchedConditions.first.name
                      : _getApiDiagnosisTypeName(diagnosis.diagnosisType),
                  style: AppTheme.labelMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient: ${diagnosis.patientId}',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      _formatDate(diagnosis.createdAt),
                      style: AppTheme.labelSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: (confidenceScore >= 0.7)
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '${(confidenceScore * 100).toInt()}%',
                        style: AppTheme.labelSmall.copyWith(
                          color: (confidenceScore >= 0.7)
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                    if (diagnosis.requiresReferral)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.warning,
                            size: 16, color: AppColors.warning),
                      ),
                  ],
                ),
                onTap: () => _showApiDiagnosisDetail(diagnosis),
              ),
            );
          },
        ),
      );
    }

    // Fall back to local history
    final history = _localDiagnosisService.getDiagnosisHistory();

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: AppTheme.spacingMd),
            Text(l10n.translate('noAssessmentsYet') ?? 'No diagnosis history',
                style: AppTheme.headingSmall
                    .copyWith(color: AppColors.textSecondary)),
            Text(
              l10n.translate('captureFirstImage') ??
                  'Captured images and analyses will appear here',
              style:
                  AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final diagnosis = history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.shadowSm,
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: diagnosis.photoPath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: Image.file(
                        File(diagnosis.photoPath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : Icon(Icons.image, color: AppColors.textSecondary),
            ),
            title: Text(
              diagnosis.matchedConditions.isNotEmpty
                  ? diagnosis.matchedConditions.first
                  : 'Unknown',
              style: AppTheme.labelMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diagnosis.bodyLocation,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  _formatDate(diagnosis.capturedAt),
                  style: AppTheme.labelSmall.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
              decoration: BoxDecoration(
                color: diagnosis.isFlagged
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '${((diagnosis.confidenceScore ?? 0) * 100).toInt()}%',
                style: AppTheme.labelSmall.copyWith(
                  color: diagnosis.isFlagged
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ),
            onTap: () {
              // Show full details
            },
          ),
        );
      },
    );
  }

  void _showApiDiagnosisDetail(api.VisualDiagnosisResult diagnosis) {
    final confidenceScore = diagnosis.confidenceScore ?? 0.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getApiSeverityColor(diagnosis.severity)
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Icon(
                          _getApiConditionTypeIcon(diagnosis.diagnosisType),
                          size: 32,
                          color: _getApiSeverityColor(diagnosis.severity),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _getApiDiagnosisTypeName(
                                    diagnosis.diagnosisType),
                                style: AppTheme.headingSmall),
                            Text(
                              _formatDate(diagnosis.createdAt),
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (diagnosis.requiresReferral)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning,
                                  size: 14, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text('Refer',
                                  style: AppTheme.labelSmall
                                      .copyWith(color: AppColors.warning)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Confidence
                  Row(
                    children: [
                      Text('Confidence:', style: AppTheme.labelMedium),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: confidenceScore,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation(
                            confidenceScore >= 0.7
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        '${(confidenceScore * 100).toInt()}%',
                        style: AppTheme.labelMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Matched conditions
                  if (diagnosis.matchedConditions.isNotEmpty) ...[
                    Text('Matched Conditions:', style: AppTheme.labelMedium),
                    const SizedBox(height: AppTheme.spacingSm),
                    ...diagnosis.matchedConditions.map((c) => Container(
                          margin:
                              const EdgeInsets.only(bottom: AppTheme.spacingSm),
                          padding: const EdgeInsets.all(AppTheme.spacingSm),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: AppTheme.labelMedium),
                                    if (c.description != null &&
                                        c.description!.isNotEmpty)
                                      Text(c.description!,
                                          style: AppTheme.bodySmall.copyWith(
                                              color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Text(
                                '${(c.probability * 100).toInt()}%',
                                style: AppTheme.labelSmall
                                    .copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        )),
                  ],
                  const SizedBox(height: AppTheme.spacingMd),

                  // Recommendations
                  if (diagnosis.recommendedActions.isNotEmpty) ...[
                    Text('Recommendations:', style: AppTheme.labelMedium),
                    const SizedBox(height: AppTheme.spacingSm),
                    ...diagnosis.recommendedActions.map((r) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTheme.spacingXs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 16, color: AppColors.success),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                  child: Text(r, style: AppTheme.bodySmall)),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TODO: May be needed later
  // IconData _getBodyPartIcon(String bodyPart) {
  //   switch (bodyPart.toLowerCase()) {
  //     case 'skin':
  //       return Icons.person;
  //     case 'eye':
  //       return Icons.remove_red_eye;
  //     case 'mouth':
  //       return Icons.face;
  //     case 'ear':
  //       return Icons.hearing;
  //     case 'wound':
  //       return Icons.healing;
  //     case 'nail':
  //       return Icons.back_hand;
  //     default:
  //       return Icons.medical_services;
  //   }
  // }

  IconData _getConditionTypeIcon(String conditionType) {
    switch (conditionType.toLowerCase()) {
      case 'skinrash':
        return Icons.coronavirus;
      case 'wound':
        return Icons.healing;
      case 'eyecondition':
        return Icons.remove_red_eye;
      case 'oralcondition':
        return Icons.face;
      case 'malnutrition':
        return Icons.child_care;
      case 'swelling':
        return Icons.bubble_chart;
      case 'skininfection':
        return Icons.bug_report;
      case 'burn':
        return Icons.whatshot;
      default:
        return Icons.medical_services;
    }
  }

  api.DiagnosisType _getDiagnosisTypeFromBodyPart(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'skin':
        return api.DiagnosisType.skin;
      case 'eye':
      case 'eyes':
        return api.DiagnosisType.eye;
      case 'mouth':
      case 'throat':
        return api.DiagnosisType.mouth;
      case 'ear':
      case 'ears':
        return api.DiagnosisType.ear;
      case 'wound':
        return api.DiagnosisType.wound;
      case 'nail':
      case 'nails':
        return api.DiagnosisType.nail;
      default:
        return api.DiagnosisType.skin;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _currentDiagnosis = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e', style: AppTheme.bodyMedium),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      if (_useBackend) {
        // Convert image to base64 for API
        final imageBytes = await _selectedImage!.readAsBytes();
        final imageBase64 = base64Encode(imageBytes);

        // Determine diagnosis type from body part
        final diagnosisType = _getDiagnosisTypeFromBodyPart(_selectedBodyPart);

        // Use backend API for analysis
        final result = await _apiService.analyzeImage(
          imageBase64: imageBase64,
          diagnosisType: diagnosisType,
          patientId: 'current_patient',
          bodyLocation: _selectedBodyPart,
          chiefComplaint: 'Visual diagnosis from mobile app',
        );

        // Convert API result to local model for display
        final diagnosis = VisualDiagnosis(
          id: result.diagnosisId,
          patientId: result.patientId,
          visitId: result.visitId ??
              'visit_${DateTime.now().millisecondsSinceEpoch}',
          photoPath: _selectedImage!.path,
          type: VisualDiagnosisType.other,
          bodyLocation: result.bodyLocation ?? _selectedBodyPart,
          description: result.matchedConditions.isNotEmpty
              ? result.matchedConditions.first.name
              : 'AI Analysis Result',
          capturedAt: result.createdAt,
          matchedConditions:
              result.matchedConditions.map((c) => c.name).toList(),
          confidenceScore: result.confidenceScore,
          isFlagged: result.requiresReferral,
          flagReason: result.referralReason,
        );

        setState(() {
          _currentDiagnosis = diagnosis;
          _isAnalyzing = false;
        });

        // If referral is needed, show dialog
        if (result.requiresReferral) {
          _showReferralRecommendation(result);
        }

        // Reload history
        await _loadDiagnosisHistory();
      } else {
        // Fall back to local service
        final diagnosis = await _localDiagnosisService.analyzeImage(
          patientId: 'current_patient',
          visitId: 'visit_${DateTime.now().millisecondsSinceEpoch}',
          imagePath: _selectedImage!.path,
          type: VisualDiagnosisType.other,
          bodyLocation: _selectedBodyPart,
          capturedBy: 'current_chw',
        );

        setState(() {
          _currentDiagnosis = diagnosis;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);

      // If backend fails, try local service
      if (_useBackend) {
        debugPrint('Backend analysis failed, trying local: $e');
        try {
          final diagnosis = await _localDiagnosisService.analyzeImage(
            patientId: 'current_patient',
            visitId: 'visit_${DateTime.now().millisecondsSinceEpoch}',
            imagePath: _selectedImage!.path,
            type: VisualDiagnosisType.other,
            bodyLocation: _selectedBodyPart,
            capturedBy: 'current_chw',
          );

          setState(() {
            _currentDiagnosis = diagnosis;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Using offline analysis (backend unavailable)',
                  style: AppTheme.bodyMedium),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        } catch (localError) {
          // Both failed
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e', style: AppTheme.bodyMedium),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showReferralRecommendation(api.VisualDiagnosisResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: AppTheme.spacingSm),
            Text('Referral Recommended', style: AppTheme.headingSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The analysis suggests this condition may require professional medical attention.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (result.matchedConditions.isNotEmpty) ...[
              Text('Detected conditions:', style: AppTheme.labelMedium),
              const SizedBox(height: AppTheme.spacingSm),
              ...result.matchedConditions.take(3).map((c) => Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spacingSm),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: AppColors.warning),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                            child: Text(
                                '${c.name} (${(c.probability * 100).toInt()}%)',
                                style: AppTheme.bodySmall)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Dismiss', style: AppTheme.labelMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to referral creation
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text('Create Referral',
                style: AppTheme.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

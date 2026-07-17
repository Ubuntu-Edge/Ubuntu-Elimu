import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/user_feedback.dart';
import '../../models/feedback_models.dart' as api_models;
import '../../services/feedback_api_service.dart';
import 'dart:io' show Platform;

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final FeedbackApiService _feedbackApi = FeedbackApiService.instance;
  
  FeedbackType _selectedType = FeedbackType.suggestion;
  FeedbackCategory _selectedCategory = FeedbackCategory.general;
  int _rating = 0;
  bool _isSubmitting = false;
  List<api_models.FeedbackResponse> _myFeedback = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeedback();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Map local FeedbackType enum to API string
  String _mapTypeToApiString(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return api_models.FeedbackType.bug;
      case FeedbackType.suggestion:
        return api_models.FeedbackType.suggestion;
      case FeedbackType.question:
        return api_models.FeedbackType.question;
      case FeedbackType.complaint:
        return api_models.FeedbackType.complaint;
      case FeedbackType.praise:
        return api_models.FeedbackType.praise;
    }
  }

  /// Map local FeedbackCategory enum to API string
  String _mapCategoryToApiString(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.general:
        return api_models.FeedbackCategory.general;
      case FeedbackCategory.patientManagement:
      case FeedbackCategory.triage:
      case FeedbackCategory.training:
      case FeedbackCategory.aiAssistant:
      case FeedbackCategory.dataSync:
        return api_models.FeedbackCategory.data;
      case FeedbackCategory.notifications:
        return api_models.FeedbackCategory.general;
      case FeedbackCategory.performance:
        return api_models.FeedbackCategory.performance;
      case FeedbackCategory.userInterface:
        return api_models.FeedbackCategory.ui;
      case FeedbackCategory.security:
        return api_models.FeedbackCategory.login;
      case FeedbackCategory.other:
        return api_models.FeedbackCategory.general;
    }
  }

  /// Map API type string to local FeedbackType enum
  FeedbackType _mapApiTypeToLocal(String apiType) {
    switch (apiType) {
      case 'bug':
        return FeedbackType.bug;
      case 'suggestion':
        return FeedbackType.suggestion;
      case 'question':
        return FeedbackType.question;
      case 'complaint':
        return FeedbackType.complaint;
      case 'praise':
        return FeedbackType.praise;
      default:
        return FeedbackType.suggestion;
    }
  }

  /// Map API category string to local FeedbackCategory enum
  FeedbackCategory _mapApiCategoryToLocal(String apiCategory) {
    switch (apiCategory) {
      case 'sync':
        return FeedbackCategory.dataSync;
      case 'ui':
        return FeedbackCategory.userInterface;
      case 'performance':
        return FeedbackCategory.performance;
      case 'data':
        return FeedbackCategory.patientManagement;
      case 'login':
        return FeedbackCategory.security;
      case 'general':
      default:
        return FeedbackCategory.general;
    }
  }

  /// Map API status string to local FeedbackStatus enum
  FeedbackStatus _mapApiStatusToLocal(String apiStatus) {
    switch (apiStatus) {
      case 'pending':
        return FeedbackStatus.pending;
      case 'in_review':
      case 'acknowledged':
      case 'in_progress':
        return FeedbackStatus.inReview;
      case 'resolved':
        return FeedbackStatus.resolved;
      case 'closed':
      case 'wont_fix':
      case 'duplicate':
        return FeedbackStatus.closed;
      default:
        return FeedbackStatus.pending;
    }
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _feedbackApi.listFeedback(
        page: 1,
        perPage: 50,
        sortBy: 'created_at',
        sortOrder: 'desc',
      );
      setState(() {
        _myFeedback = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e is api_models.FeedbackApiException
            ? e.message
            : 'Failed to load feedback';
      });
    }
  }

  Map<String, dynamic> _getDeviceInfo() {
    try {
      return {
        'platform': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'device_model': Platform.localHostname,
      };
    } catch (e) {
      return {'platform': 'unknown'};
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final request = api_models.FeedbackCreateRequest(
        type: _mapTypeToApiString(_selectedType),
        category: _mapCategoryToApiString(_selectedCategory),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        rating: _rating > 0 ? _rating : null,
        deviceInfo: _getDeviceInfo(),
      );
      
      await _feedbackApi.submitFeedback(request);
      
      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedType = FeedbackType.suggestion;
        _selectedCategory = FeedbackCategory.general;
        _rating = 0;
      });
      
      // Reload feedback list
      await _loadFeedback();
      
      // Switch to history tab
      _tabController.animateTo(1);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                FaIcon(FontAwesomeIcons.circleCheck, color: Colors.white, size: 18),
                SizedBox(width: AppTheme.spacingSm),
                Text('Feedback submitted successfully!', style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on api_models.FeedbackApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSubmitTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback & Support',
                        style: AppTheme.headingMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Help us improve the app',
                        style: AppTheme.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white,
              labelStyle: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.penToSquare, size: 14),
                      SizedBox(width: 6),
                      Text('Submit'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.clockRotateLeft, size: 14),
                      SizedBox(width: 6),
                      Text('History'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback Type Selection
            Text('Type of Feedback', style: AppTheme.labelLarge),
            SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: FeedbackType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.icon, style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text(
                          type.displayName,
                          style: AppTheme.bodySmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: AppTheme.spacingLg),
            
            // Category Selection
            Text('Category', style: AppTheme.labelLarge),
            SizedBox(height: AppTheme.spacingSm),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FeedbackCategory>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: FaIcon(FontAwesomeIcons.chevronDown, size: 14, color: AppColors.textSecondary),
                  items: FeedbackCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName, style: AppTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCategory = value);
                  },
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingLg),
            
            // Title
            Text('Title', style: AppTheme.labelLarge),
            SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Brief summary of your feedback',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.spacingLg),
            
            // Description
            Text('Description', style: AppTheme.labelLarge),
            SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe your feedback in detail...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.spacingLg),
            
            // Rating (Optional)
            Text('Rate your experience (optional)', style: AppTheme.labelLarge),
            SizedBox(height: AppTheme.spacingSm),
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  child: Padding(
                    padding: EdgeInsets.only(right: AppTheme.spacingSm),
                    child: FaIcon(
                      starIndex <= _rating ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
                      color: starIndex <= _rating ? AppColors.warning : AppColors.textSecondary,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            
            SizedBox(height: AppTheme.spacingXl),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.paperPlane, size: 16),
                          SizedBox(width: AppTheme.spacingSm),
                          Text('Submit Feedback', style: AppTheme.labelLarge.copyWith(color: Colors.white)),
                        ],
                      ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.circleExclamation, size: 48, color: AppColors.error),
            SizedBox(height: AppTheme.spacingMd),
            Text(_errorMessage!, style: AppTheme.bodyMedium.copyWith(color: AppColors.error)),
            SizedBox(height: AppTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: _loadFeedback,
              icon: FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
              label: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_myFeedback.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.commentDots,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text('No feedback submitted yet', style: AppTheme.headingSmall),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              'Your submitted feedback will appear here',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadFeedback,
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        itemCount: _myFeedback.length,
        itemBuilder: (context, index) {
          final feedback = _myFeedback[index];
          return _buildFeedbackCard(feedback);
        },
      ),
    );
  }

  Widget _buildFeedbackCard(api_models.FeedbackResponse feedback) {
    final localType = _mapApiTypeToLocal(feedback.type);
    final localCategory = _mapApiCategoryToLocal(feedback.category);
    final localStatus = _mapApiStatusToLocal(feedback.status);
    
    Color statusColor;
    switch (localStatus) {
      case FeedbackStatus.pending:
        statusColor = AppColors.warning;
        break;
      case FeedbackStatus.inReview:
        statusColor = AppColors.info;
        break;
      case FeedbackStatus.resolved:
        statusColor = AppColors.success;
        break;
      case FeedbackStatus.closed:
        statusColor = AppColors.textSecondary;
        break;
    }
    
    return GestureDetector(
      onTap: () => _showFeedbackDetail(feedback),
      child: Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
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
            // Header
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(localType.icon, style: TextStyle(fontSize: 18)),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.title,
                          style: AppTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          localCategory.displayName,
                          style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      localStatus.displayName,
                      style: AppTheme.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1, color: AppColors.divider),
            
            // Description
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Text(
                feedback.description,
                style: AppTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Footer
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.clock, size: 12, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    _formatDate(feedback.createdAt),
                    style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  if (feedback.rating != null) ...[
                    SizedBox(width: AppTheme.spacingMd),
                    ...List.generate(5, (index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 2),
                        child: FaIcon(
                          index < feedback.rating! ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
                          size: 12,
                          color: index < feedback.rating! ? AppColors.warning : AppColors.textSecondary,
                        ),
                      );
                    }),
                  ],
                  if (feedback.priority != null) ...[
                    Spacer(),
                    _buildPriorityBadge(feedback.priority!),
                  ],
                  // Tap hint
                  if (feedback.priority == null) Spacer(),
                  FaIcon(FontAwesomeIcons.chevronRight, size: 12, color: AppColors.textSecondary),
                ],
              ),
            ),
            
            // Response (if any)
            if (feedback.responseMessage != null && feedback.responseMessage!.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.fromLTRB(AppTheme.spacingMd, 0, AppTheme.spacingMd, AppTheme.spacingMd),
                padding: EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.reply, size: 12, color: AppColors.success),
                        SizedBox(width: 6),
                        Text(
                          'Response',
                          style: AppTheme.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                        if (feedback.respondedAt != null) ...[
                          Spacer(),
                          Text(
                            _formatDate(feedback.respondedAt!),
                            style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Text(feedback.responseMessage!, style: AppTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bgColor;
    Color textColor;
    switch (priority) {
      case 'critical':
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
      case 'high':
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        break;
      case 'medium':
        bgColor = AppColors.info.withValues(alpha: 0.1);
        textColor = AppColors.info;
        break;
      default:
        bgColor = AppColors.textSecondary.withValues(alpha: 0.1);
        textColor = AppColors.textSecondary;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFullDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  void _showFeedbackDetail(api_models.FeedbackResponse feedback) {
    final localType = _mapApiTypeToLocal(feedback.type);
    final localCategory = _mapApiCategoryToLocal(feedback.category);
    final localStatus = _mapApiStatusToLocal(feedback.status);
    
    Color statusColor;
    switch (localStatus) {
      case FeedbackStatus.pending:
        statusColor = AppColors.warning;
        break;
      case FeedbackStatus.inReview:
        statusColor = AppColors.info;
        break;
      case FeedbackStatus.resolved:
        statusColor = AppColors.success;
        break;
      case FeedbackStatus.closed:
        statusColor = AppColors.textSecondary;
        break;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(localType.icon, style: TextStyle(fontSize: 24)),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                localStatus.displayName,
                                style: AppTheme.labelSmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (feedback.priority != null) ...[
                              SizedBox(width: 8),
                              _buildPriorityBadge(feedback.priority!),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          feedback.title,
                          style: AppTheme.headingSmall.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: FaIcon(FontAwesomeIcons.xmark, color: AppColors.textSecondary, size: 18),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      'Description',
                      style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feedback.description,
                        style: AppTheme.bodyMedium.copyWith(height: 1.6),
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingLg),
                    
                    // Details section
                    Text(
                      'Details',
                      style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    
                    _buildFeedbackDetailRow(
                      FontAwesomeIcons.tag,
                      'Type',
                      localType.displayName,
                    ),
                    
                    _buildFeedbackDetailRow(
                      FontAwesomeIcons.folder,
                      'Category',
                      localCategory.displayName,
                    ),
                    
                    _buildFeedbackDetailRow(
                      FontAwesomeIcons.clock,
                      'Submitted',
                      _formatFullDate(feedback.createdAt),
                    ),
                    
                    if (feedback.rating != null)
                      _buildFeedbackDetailRow(
                        FontAwesomeIcons.star,
                        'Rating',
                        '${feedback.rating}/5 stars',
                        trailing: Row(
                          children: List.generate(5, (index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 2),
                              child: FaIcon(
                                index < feedback.rating! ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
                                size: 14,
                                color: index < feedback.rating! ? AppColors.warning : AppColors.textSecondary,
                              ),
                            );
                          }),
                        ),
                      ),
                    
                    // Device Info
                    if (feedback.deviceInfo != null && feedback.deviceInfo!.isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacingLg),
                      Text(
                        'Device Information',
                        style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: AppTheme.spacingMd),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: feedback.deviceInfo!.entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_formatKey(entry.key)}: ',
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${entry.value}',
                                      style: AppTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Bug Report Details
                    if (feedback.type == 'bug') ...[
                      if (feedback.errorMessage != null) ...[
                        SizedBox(height: AppTheme.spacingLg),
                        Text(
                          'Error Message',
                          style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            feedback.errorMessage!,
                            style: AppTheme.bodySmall.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                      
                      if (feedback.stepsToReproduce != null) ...[
                        SizedBox(height: AppTheme.spacingLg),
                        Text(
                          'Steps to Reproduce',
                          style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            feedback.stepsToReproduce!,
                            style: AppTheme.bodyMedium.copyWith(height: 1.6),
                          ),
                        ),
                      ],
                    ],
                    
                    // Tags
                    if (feedback.tags != null && feedback.tags!.isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacingLg),
                      Text(
                        'Tags',
                        style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: AppTheme.spacingSm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: feedback.tags!.map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tag,
                              style: AppTheme.labelSmall.copyWith(color: AppColors.primary),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // Response Section
                    if (feedback.responseMessage != null && feedback.responseMessage!.isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacingLg),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: FaIcon(FontAwesomeIcons.reply, size: 14, color: AppColors.success),
                                ),
                                SizedBox(width: AppTheme.spacingSm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Official Response',
                                        style: AppTheme.labelMedium.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (feedback.respondedAt != null)
                                        Text(
                                          _formatFullDate(feedback.respondedAt!),
                                          style: AppTheme.labelSmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppTheme.spacingMd),
                            Text(
                              feedback.responseMessage!,
                              style: AppTheme.bodyMedium.copyWith(height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Resolution Notes
                    if (feedback.resolvedAt != null) ...[
                      SizedBox(height: AppTheme.spacingLg),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                FaIcon(FontAwesomeIcons.circleCheck, size: 14, color: AppColors.success),
                                SizedBox(width: 8),
                                Text(
                                  'Resolved',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  _formatFullDate(feedback.resolvedAt!),
                                  style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            if (feedback.resolutionNotes != null && feedback.resolutionNotes!.isNotEmpty) ...[
                              SizedBox(height: AppTheme.spacingSm),
                              Text(
                                feedback.resolutionNotes!,
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    
                    // Attachments
                    if (feedback.attachments != null && feedback.attachments!.isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacingLg),
                      Text(
                        'Attachments',
                        style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: AppTheme.spacingSm),
                      ...feedback.attachments!.map((url) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              FaIcon(FontAwesomeIcons.paperclip, size: 14, color: AppColors.primary),
                              SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Text(
                                  url.split('/').last,
                                  style: AppTheme.bodySmall.copyWith(color: AppColors.primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              FaIcon(FontAwesomeIcons.externalLink, size: 12, color: AppColors.textSecondary),
                            ],
                          ),
                        );
                      }),
                    ],
                    
                    SizedBox(height: AppTheme.spacingLg),
                    
                    // Delete button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteFeedback(feedback),
                        icon: FaIcon(FontAwesomeIcons.trash, size: 14),
                        label: Text('Delete Feedback'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingLg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackDetailRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: FaIcon(icon, color: AppColors.primary, size: 14),
            ),
          ),
          SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                if (trailing != null)
                  trailing
                else
                  Text(
                    value,
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    // Convert snake_case to Title Case
    return key.split('_').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  void _confirmDeleteFeedback(api_models.FeedbackResponse feedback) {
    Navigator.pop(context); // Close detail sheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Feedback', style: AppTheme.headingMedium),
        content: Text('Are you sure you want to delete this feedback? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _feedbackApi.deleteFeedback(feedback.id);
                await _loadFeedback();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Feedback deleted'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete feedback'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

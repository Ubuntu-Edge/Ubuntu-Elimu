import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int>? _statistics;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _villageController = TextEditingController();
  final _healthFacilityController = TextEditingController();
  final _regionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    _healthFacilityController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final chw = authProvider.currentCHW;
    
    if (chw != null) {
      _firstNameController.text = chw.firstName;
      _lastNameController.text = chw.lastName;
      _emailController.text = chw.email ?? '';
      _villageController.text = chw.village ?? '';
      _healthFacilityController.text = chw.healthFacility ?? '';
      _regionController.text = chw.region ?? '';
      
      try {
        final stats = await DatabaseService.instance.getCHWStatistics(chw.id);
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    final chw = authProvider.currentCHW;
    
    if (chw != null) {
      final updatedChw = chw.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        village: _villageController.text.trim().isEmpty ? null : _villageController.text.trim(),
        healthFacility: _healthFacilityController.text.trim().isEmpty ? null : _healthFacilityController.text.trim(),
        region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
      );
      
      try {
        await DatabaseService.instance.createCHW(updatedChw);
        await authProvider.refreshCurrentCHW();
        
        setState(() => _isEditing = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('profileUpdated') ?? 'Profile updated successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('errorUpdatingProfile') ?? 'Error updating profile'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chw = authProvider.currentCHW;
    final l10n = AppLocalizations.of(context);

    if (chw == null) {
      return Scaffold(
        body: Center(
          child: Text(l10n.translate('notLoggedIn') ?? 'Not logged in'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(chw, l10n)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  _buildStatisticsSection(l10n),
                  SizedBox(height: AppTheme.spacingMd),
                  _buildProfileDetailsSection(chw, l10n),
                  SizedBox(height: AppTheme.spacingMd),
                  _buildAccountInfoSection(chw, l10n),
                  SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(chw, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    l10n.profile,
                    style: AppTheme.headingMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!_isEditing)
                  GestureDetector(
                    onTap: () => setState(() => _isEditing = true),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.white, size: 18),
                    ),
                  ),
                if (_isEditing) ...[
                  GestureDetector(
                    onTap: () {
                      _loadData();
                      setState(() => _isEditing = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white, size: 18),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  GestureDetector(
                    onTap: _saveProfile,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const FaIcon(FontAwesomeIcons.check, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: AppTheme.spacingLg),
            // Profile Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  chw.fullName.isNotEmpty ? chw.fullName[0].toUpperCase() : 'U',
                  style: AppTheme.headingLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              chw.fullName,
              style: AppTheme.headingMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppTheme.spacingXs),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingXs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.translate('communityHealthWorker') ?? 'Community Health Worker',
                style: AppTheme.bodySmall.copyWith(color: Colors.white),
              ),
            ),
            if (chw.village != null) ...[
              SizedBox(height: AppTheme.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.locationDot, color: Colors.white.withValues(alpha: 0.8), size: 14),
                  SizedBox(width: AppTheme.spacingXs),
                  Text(
                    chw.village!,
                    style: AppTheme.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(AppLocalizations l10n) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
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
          Row(
            children: [
              FaIcon(FontAwesomeIcons.chartBar, color: AppColors.primary, size: 16),
              SizedBox(width: AppTheme.spacingSm),
              Text(
                l10n.translate('myStatistics') ?? 'My Statistics',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: FontAwesomeIcons.users,
                  value: '${_statistics?['totalPatients'] ?? 0}',
                  label: l10n.patients,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: FontAwesomeIcons.stethoscope,
                  value: '${_statistics?['totalVisits'] ?? 0}',
                  label: l10n.visits,
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: FontAwesomeIcons.triangleExclamation,
                  value: '${_statistics?['highRiskPatients'] ?? 0}',
                  label: l10n.highRisk,
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: FontAwesomeIcons.clock,
                  value: '${_statistics?['pendingFollowUps'] ?? 0}',
                  label: l10n.followups,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(icon, color: color, size: 18),
        ),
        SizedBox(height: AppTheme.spacingSm),
        Text(
          value,
          style: AppTheme.headingSmall.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileDetailsSection(chw, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
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
          Row(
            children: [
              FaIcon(FontAwesomeIcons.userPen, color: AppColors.primary, size: 16),
              SizedBox(width: AppTheme.spacingSm),
              Text(
                l10n.translate('personalInformation') ?? 'Personal Information',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          if (_isEditing) ...[
            _buildEditableField(
              controller: _firstNameController,
              label: l10n.translate('firstName') ?? 'First Name',
              icon: FontAwesomeIcons.user,
            ),
            SizedBox(height: AppTheme.spacingMd),
            _buildEditableField(
              controller: _lastNameController,
              label: l10n.translate('lastName') ?? 'Last Name',
              icon: FontAwesomeIcons.user,
            ),
            SizedBox(height: AppTheme.spacingMd),
            _buildEditableField(
              controller: _emailController,
              label: l10n.translate('email') ?? 'Email',
              icon: FontAwesomeIcons.envelope,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: AppTheme.spacingMd),
            _buildEditableField(
              controller: _villageController,
              label: l10n.translate('village') ?? 'Village',
              icon: FontAwesomeIcons.locationDot,
            ),
            SizedBox(height: AppTheme.spacingMd),
            _buildEditableField(
              controller: _healthFacilityController,
              label: l10n.translate('healthFacility') ?? 'Health Facility',
              icon: FontAwesomeIcons.hospital,
            ),
            SizedBox(height: AppTheme.spacingMd),
            _buildEditableField(
              controller: _regionController,
              label: l10n.translate('region') ?? 'Region',
              icon: FontAwesomeIcons.mapLocationDot,
            ),
          ] else ...[
            _buildInfoRow(
              icon: FontAwesomeIcons.user,
              label: l10n.translate('firstName') ?? 'First Name',
              value: chw.firstName,
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.user,
              label: l10n.translate('lastName') ?? 'Last Name',
              value: chw.lastName,
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.envelope,
              label: l10n.translate('email') ?? 'Email',
              value: chw.email ?? '-',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.locationDot,
              label: l10n.translate('village') ?? 'Village',
              value: chw.village ?? '-',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.hospital,
              label: l10n.translate('healthFacility') ?? 'Health Facility',
              value: chw.healthFacility ?? '-',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.mapLocationDot,
              label: l10n.translate('region') ?? 'Region',
              value: chw.region ?? '-',
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
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
                    Text(
                      value,
                      style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(color: AppColors.divider),
      ],
    );
  }

  Widget _buildAccountInfoSection(chw, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
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
          Row(
            children: [
              FaIcon(FontAwesomeIcons.circleInfo, color: AppColors.primary, size: 16),
              SizedBox(width: AppTheme.spacingSm),
              Text(
                l10n.translate('accountInformation') ?? 'Account Information',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          _buildInfoRow(
            icon: FontAwesomeIcons.phone,
            label: l10n.translate('phoneNumber') ?? 'Phone Number',
            value: chw.phoneNumber,
          ),
          _buildInfoRow(
            icon: FontAwesomeIcons.idCard,
            label: l10n.translate('chwId') ?? 'CHW ID',
            value: chw.id,
          ),
          _buildInfoRow(
            icon: FontAwesomeIcons.calendarCheck,
            label: l10n.translate('registeredDate') ?? 'Registered Date',
            value: _formatDate(chw.registeredDate),
          ),
          _buildInfoRow(
            icon: FontAwesomeIcons.circleCheck,
            label: l10n.translate('accountStatus') ?? 'Account Status',
            value: chw.isActive 
                ? (l10n.translate('active') ?? 'Active')
                : (l10n.translate('inactive') ?? 'Inactive'),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/sync_service.dart';
import '../../services/auth_validation.dart';
import '../../l10n/app_localizations.dart';
import '../feedback/feedback_screen.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailySummaryEnabled = true;
  bool _autoSyncEnabled = true;
  String _selectedLanguage = 'English';
  bool _isSyncing = false;
  String? _lastSyncTime;
  Map<String, int>? _syncStats;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final localeProvider = context.read<LocaleProvider>();
    setState(() {
      _selectedLanguage = AppLocales.getLanguageName(localeProvider.currentLocale);
    });
    try {
      final syncService = SyncService.instance;
      final stats = await syncService.getSyncStatistics();
      setState(() {
        _syncStats = stats;
        _lastSyncTime = syncService.lastSyncTime?.toString().substring(0, 16);
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _performSync() async {
    setState(() => _isSyncing = true);
    try {
      final result = await SyncService.instance.syncAll();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                FaIcon(
                  result.success ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleXmark,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: AppTheme.spacingSm),
                Text(
                  result.success
                      ? 'Synced ${result.recordsSynced} records'
                      : 'Sync failed: ${result.errorMessage}',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: result.success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.translate('selectLanguage') ?? 'Select Language', style: AppTheme.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', 'en', '🇺🇸'),
            _buildLanguageOption('Kiswahili', 'sw', '🇰🇪'),
            _buildLanguageOption('Français', 'fr', '🇫🇷'),
            _buildLanguageOption('Português', 'pt', '🇲🇿'),
            _buildLanguageOption('አማርኛ', 'am', '🇪🇹'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String name, String code, String flag) {
    final isSelected = _selectedLanguage == name;
    return ListTile(
      leading: Text(flag, style: TextStyle(fontSize: 24)),
      title: Text(name, style: AppTheme.bodyMedium),
      trailing: isSelected
          ? FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.primary, size: 18)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      onTap: () async {
        // Get the locale based on the code
        Locale newLocale;
        switch (code) {
          case 'en':
            newLocale = AppLocales.english;
            break;
          case 'sw':
            newLocale = AppLocales.swahili;
            break;
          case 'fr':
            newLocale = AppLocales.french;
            break;
          case 'pt':
            newLocale = AppLocales.portuguese;
            break;
          case 'am':
            newLocale = AppLocales.amharic;
            break;
          default:
            newLocale = AppLocales.english;
        }
        
        // Update locale via provider
        final localeProvider = context.read<LocaleProvider>();
        await localeProvider.setLocale(newLocale);
        
        setState(() => _selectedLanguage = name);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to $name'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _showChangePinDialog() {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.translate('changePin') ?? 'Change PIN', style: AppTheme.headingMedium),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.translate('currentPin') ?? 'Current PIN',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Current PIN is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: newPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.translate('newPin') ?? 'New PIN',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: AuthValidation.validatePin,
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: confirmPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.translate('confirmNewPin') ?? 'Confirm New PIN',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => AuthValidation.validateConfirmPin(
                    value,
                    newPinController.text,
                  ),
                ),
                if (isLoading)
                  Padding(
                    padding: EdgeInsets.only(top: AppTheme.spacingMd),
                    child: const CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;

                setState(() => isLoading = true);

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final success = await authProvider.changePin(
                    currentPinController.text,
                    newPinController.text,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.circleCheck, color: Colors.white, size: 18),
                            SizedBox(width: AppTheme.spacingSm),
                            Text(
                              l10n.translate('pinChangedSuccessfully') ?? 'PIN changed successfully',
                              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  } else if (mounted) {
                    setState(() => isLoading = false);
                    final errorMsg = authProvider.errorMessage ?? 'Failed to change PIN';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.circleXmark, color: Colors.white, size: 18),
                            SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(
                                errorMsg,
                                style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.translate('changePin') ?? 'Change PIN'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.translate('changePassword') ?? 'Change Password', style: AppTheme.headingMedium),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: !showCurrentPassword,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.translate('currentPassword') ?? 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: FaIcon(
                          showCurrentPassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                          size: 18,
                        ),
                        onPressed: () => setState(() => showCurrentPassword = !showCurrentPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Current password is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMd),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: !showNewPassword,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.translate('newPassword') ?? 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: FaIcon(
                          showNewPassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                          size: 18,
                        ),
                        onPressed: () => setState(() => showNewPassword = !showNewPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: AuthValidation.validatePassword,
                  ),
                  SizedBox(height: AppTheme.spacingMd),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.translate('confirmNewPassword') ?? 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: FaIcon(
                          showConfirmPassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                          size: 18,
                        ),
                        onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => AuthValidation.validateConfirmPassword(
                      value,
                      newPasswordController.text,
                    ),
                  ),
                  if (isLoading)
                    Padding(
                      padding: EdgeInsets.only(top: AppTheme.spacingMd),
                      child: const CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;

                setState(() => isLoading = true);

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final success = await authProvider.changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.circleCheck, color: Colors.white, size: 18),
                            SizedBox(width: AppTheme.spacingSm),
                            Text(
                              l10n.translate('passwordChangedSuccessfully') ?? 'Password changed successfully',
                              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  } else if (mounted) {
                    setState(() => isLoading = false);
                    final errorMsg = authProvider.errorMessage ?? 'Failed to change password';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.circleXmark, color: Colors.white, size: 18),
                            SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(
                                errorMsg,
                                style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.translate('changePassword') ?? 'Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(FontAwesomeIcons.heartPulse, color: AppColors.primary, size: 24),
            ),
            SizedBox(width: AppTheme.spacingMd),
            Text('UbuntuHealth', style: AppTheme.headingMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('aboutDescription') ?? 'Empowering Community Health Workers with AI-assisted medical support.',
              style: AppTheme.bodyMedium,
            ),
            SizedBox(height: AppTheme.spacingMd),
            _buildAboutRow(l10n.translate('version') ?? 'Version', '1.0.0'),
            _buildAboutRow(l10n.translate('build') ?? 'Build', '6'),
            _buildAboutRow(l10n.translate('platform') ?? 'Platform', 'Android'),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              '© 2024 UbuntuHealth Team',
              style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('close') ?? 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.logout, style: AppTheme.headingMedium),
        content: Text(l10n.translate('logoutConfirmation') ?? 'Are you sure you want to logout?', style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chw = authProvider.currentCHW;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(chw?.fullName ?? 'User'),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  // Profile Section
                  _buildSectionHeader(l10n.profile, FontAwesomeIcons.user),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: FontAwesomeIcons.userPen,
                      title: l10n.translate('viewEditProfile') ?? 'View & Edit Profile',
                      value: chw?.fullName ?? 'User',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                  ]),
                  
                  SizedBox(height: AppTheme.spacingMd),
                  
                  // Sync Section
                  _buildSectionHeader(l10n.dataSync, FontAwesomeIcons.arrowsRotate),
                  _buildSettingsCard([
                    _buildSyncTile(),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: FontAwesomeIcons.rotate,
                      title: l10n.autoSync,
                      subtitle: l10n.translate('autoSyncDescription') ?? 'Automatically sync data in background',
                      value: _autoSyncEnabled,
                      onChanged: (value) => setState(() => _autoSyncEnabled = value),
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: FontAwesomeIcons.database,
                      title: l10n.translate('dataStatistics') ?? 'Data Statistics',
                      value: _syncStats != null
                          ? '${_syncStats!['totalRecords']} ${l10n.translate('records') ?? 'records'}'
                          : '${l10n.translate('loading') ?? 'Loading'}...',
                    ),
                  ]),
                  
                  SizedBox(height: AppTheme.spacingMd),
                  
                  // Notifications Section
                  _buildSectionHeader(l10n.notifications, FontAwesomeIcons.bell),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: FontAwesomeIcons.bell,
                      title: l10n.translate('pushNotifications') ?? 'Push Notifications',
                      subtitle: l10n.translate('pushNotificationsDescription') ?? 'Receive alerts and reminders',
                      value: _notificationsEnabled,
                      onChanged: (value) => setState(() => _notificationsEnabled = value),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: FontAwesomeIcons.calendar,
                      title: l10n.translate('dailySummary') ?? 'Daily Summary',
                      subtitle: l10n.translate('dailySummaryDescription') ?? 'Get a morning summary of tasks',
                      value: _dailySummaryEnabled,
                      onChanged: (value) => setState(() => _dailySummaryEnabled = value),
                    ),
                  ]),
                  
                  SizedBox(height: AppTheme.spacingMd),
                  
                  // Appearance Section
                  _buildSectionHeader(l10n.appearance, FontAwesomeIcons.palette),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: FontAwesomeIcons.language,
                      title: l10n.language,
                      value: _selectedLanguage,
                      onTap: _showLanguageDialog,
                    ),
                  ]),
                  
                  SizedBox(height: AppTheme.spacingMd),
                  
                  // Security Section
                  _buildSectionHeader(l10n.translate('security') ?? 'Security', FontAwesomeIcons.shield),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: FontAwesomeIcons.key,
                      title: l10n.translate('changePin') ?? 'Change PIN',
                      value: '••••',
                      onTap: _showChangePinDialog,
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: FontAwesomeIcons.lock,
                      title: l10n.translate('changePassword') ?? 'Change Password',
                      value: '••••••••',
                      onTap: _showChangePasswordDialog,
                    ),
                  ]),
                  
                  SizedBox(height: AppTheme.spacingMd),
                  
                  // Support Section
                  _buildSectionHeader(l10n.translate('support') ?? 'Support', FontAwesomeIcons.circleQuestion),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: FontAwesomeIcons.commentDots,
                      title: l10n.translate('feedbackSupport') ?? 'Feedback & Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: FontAwesomeIcons.circleInfo,
                      title: l10n.translate('about') ?? 'About',
                      onTap: _showAboutDialog,
                    ),
                  ]),
                  
                  SizedBox(height: AppTheme.spacingLg),
                  
                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: FaIcon(FontAwesomeIcons.rightFromBracket, size: 16),
                    label: Text(l10n.logout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
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
      ),
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
                  AppLocalizations.of(context).settings,
                  style: AppTheme.headingMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  userName,
                  style: AppTheme.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          FaIcon(icon, size: 14, color: AppColors.primary),
          SizedBox(width: AppTheme.spacingSm),
          Text(title, style: AppTheme.labelLarge.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.divider, indent: 56, endIndent: 16);
  }

  Widget _buildSyncTile() {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _isSyncing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
              )
            : FaIcon(FontAwesomeIcons.cloudArrowUp, color: AppColors.info, size: 18),
      ),
      title: Text(l10n.translate('syncNow') ?? 'Sync Now', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        _lastSyncTime != null ? '${l10n.translate('lastSync') ?? 'Last'}: $_lastSyncTime' : l10n.translate('neverSynced') ?? 'Never synced',
        style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: ElevatedButton(
        onPressed: _isSyncing ? null : _performSync,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(_isSyncing ? '${l10n.translate('syncing') ?? 'Syncing'}...' : l10n.translate('sync') ?? 'Sync'),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FaIcon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(title, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FaIcon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(title, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value, style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
          SizedBox(width: 8),
          FaIcon(FontAwesomeIcons.chevronRight, size: 14, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FaIcon(icon, color: AppColors.success, size: 18),
      ),
      title: Text(title, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      trailing: Text(value, style: AppTheme.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
    );
  }
}

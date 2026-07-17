import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/auth_validation.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _villageController = TextEditingController();
  final _healthFacilityController = TextEditingController();
  final _regionController = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _villageController.dispose();
    _healthFacilityController.dispose();
    _regionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Password is optional but if provided, must match confirmation
    String? password;
    if (_passwordController.text.isNotEmpty) {
      password = _passwordController.text;
    }

    // Format phone number to E.164 format (+254...) for backend
    final formattedPhone =
        AuthValidation.formatPhoneNumber(_phoneController.text.trim());

    final success = await authProvider.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: formattedPhone,
      pin: _pinController.text,
      password: password,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      village: _villageController.text.trim().isNotEmpty
          ? _villageController.text.trim()
          : null,
      healthFacility: _healthFacilityController.text.trim().isNotEmpty
          ? _healthFacilityController.text.trim()
          : null,
      region: _regionController.text.trim().isNotEmpty
          ? _regionController.text.trim()
          : null,
    );

    if (success && mounted) {
      final isOnline = ConnectivityService.instance.isOnline;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(FontAwesomeIcons.circleCheck,
                  color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOnline
                      ? 'Registration successful! Welcome!'
                      : 'Registration saved locally! Will sync when online.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(FontAwesomeIcons.circleExclamation,
                  color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(authProvider.errorMessage ?? 'Registration failed'),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // Calculate password strength (0.0 to 1.0)
  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0.0;

    // Length contribution (up to 0.25)
    if (password.length >= 8) {
      strength += 0.25;
    } else if (password.length >= 6)
      strength += 0.15;
    else if (password.length >= 4) strength += 0.05;

    // Has lowercase (0.2)
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;

    // Has uppercase (0.2)
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;

    // Has digit (0.2)
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;

    // Has special char (0.15)
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.15;

    return strength.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.3) return AppColors.error;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.85) return Colors.amber;
    return AppColors.success;
  }

  String _getStrengthLabel(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Fair';
    if (strength < 0.85) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final connectivity = ConnectivityService.instance;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppColors.primary);
              },
            ),
          ),
          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.85),
                    AppColors.primaryDark.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildOfflineBadge(connectivity.isOnline),
                            const SizedBox(height: 16),
                            _buildProgressIndicator(),
                            const SizedBox(height: 24),
                            _buildFormCard(authProvider),
                            const SizedBox(height: 24),
                            _buildLoginLink(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBadge(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            isOnline ? FontAwesomeIcons.wifi : FontAwesomeIcons.cloud,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            isOnline
                ? 'Online - Will sync immediately'
                : 'Offline - Will sync later',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.arrowLeft,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                FaIcon(FontAwesomeIcons.userPlus,
                    size: 14, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Sign Up',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Join Our Community',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account to start helping patients',
          style: TextStyle(
              fontSize: 15, color: Colors.white.withValues(alpha: 0.9)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Personal', 'Work', 'Security'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= _currentStep;
        final isCompleted = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? FaIcon(FontAwesomeIcons.check,
                                size: 14, color: AppColors.primary)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.primary
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index],
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  height: 2,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: index < _currentStep
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFormCard(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentStep == 0
            ? _buildPersonalSection()
            : _currentStep == 1
                ? _buildWorkSection()
                : _buildSecuritySection(authProvider),
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Column(
      key: const ValueKey('personal'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Information', FontAwesomeIcons.user),
        const SizedBox(height: 20),
        _buildInputField(
          label: 'First Name *',
          hint: 'Enter your first name',
          controller: _firstNameController,
          icon: FontAwesomeIcons.user,
          validator: (value) =>
              AuthValidation.validateName(value, 'First name'),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Last Name *',
          hint: 'Enter your last name',
          controller: _lastNameController,
          icon: FontAwesomeIcons.userTag,
          validator: (value) => AuthValidation.validateName(value, 'Last name'),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Phone Number *',
          hint: '0712345678',
          controller: _phoneController,
          icon: FontAwesomeIcons.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (value) => AuthValidation.validatePhoneNumber(value),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Email (Optional)',
          hint: 'your.email@example.com',
          controller: _emailController,
          icon: FontAwesomeIcons.envelope,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return null; // Optional
            return AuthValidation.validateEmail(value);
          },
        ),
        const SizedBox(height: 28),
        _buildNextButton(() {
          // Validate personal section fields
          final firstNameError = AuthValidation.validateName(
              _firstNameController.text, 'First name');
          final lastNameError = AuthValidation.validateName(
              _lastNameController.text, 'Last name');
          final phoneError =
              AuthValidation.validatePhoneNumber(_phoneController.text);

          if (firstNameError != null ||
              lastNameError != null ||
              phoneError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(firstNameError ??
                    lastNameError ??
                    phoneError ??
                    'Please fill in all required fields'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else {
            setState(() => _currentStep = 1);
          }
        }),
      ],
    );
  }

  Widget _buildWorkSection() {
    return Column(
      key: const ValueKey('work'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
            'Work Information', FontAwesomeIcons.briefcaseMedical),
        const SizedBox(height: 20),
        _buildInputField(
          label: 'Village/Area (Optional)',
          hint: 'Where you primarily work',
          controller: _villageController,
          icon: FontAwesomeIcons.locationDot,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Health Facility (Optional)',
          hint: 'Your affiliated health center',
          controller: _healthFacilityController,
          icon: FontAwesomeIcons.hospital,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Region/County (Optional)',
          hint: 'e.g., Nairobi, Mombasa',
          controller: _regionController,
          icon: FontAwesomeIcons.mapLocationDot,
        ),
        const SizedBox(height: 28),
        _buildNextButton(() => setState(() => _currentStep = 2)),
      ],
    );
  }

  Widget _buildSecuritySection(AuthProvider authProvider) {
    final passwordStrength =
        _calculatePasswordStrength(_passwordController.text);

    return Column(
      key: const ValueKey('security'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Create PIN', FontAwesomeIcons.shieldHalved),
        const SizedBox(height: 8),
        Text(
          'Create a 4-6 digit PIN for quick & secure login',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: 'Create PIN *',
          hint: String.fromCharCodes([0x2022, 0x2022, 0x2022, 0x2022]),
          controller: _pinController,
          icon: FontAwesomeIcons.lock,
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePin = !_obscurePin),
            child: FaIcon(
              _obscurePin ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          validator: (value) => AuthValidation.validatePin(value),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Confirm PIN *',
          hint: String.fromCharCodes([0x2022, 0x2022, 0x2022, 0x2022]),
          controller: _confirmPinController,
          icon: FontAwesomeIcons.lockOpen,
          obscureText: _obscureConfirmPin,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          suffixIcon: GestureDetector(
            onTap: () =>
                setState(() => _obscureConfirmPin = !_obscureConfirmPin),
            child: FaIcon(
              _obscureConfirmPin
                  ? FontAwesomeIcons.eyeSlash
                  : FontAwesomeIcons.eye,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          validator: (value) {
            if (value?.isEmpty == true) return 'Please confirm your PIN';
            if (value != _pinController.text) return 'PINs do not match';
            return null;
          },
        ),
        const SizedBox(height: 24),
        // Optional Password Section
        Container(
          padding: const EdgeInsets.all(16),
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
                  FaIcon(FontAwesomeIcons.key,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Password (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'For additional account security on web portal',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'Password',
                hint: 'Min 8 chars, upper, lower, digit',
                controller: _passwordController,
                icon: FontAwesomeIcons.key,
                obscureText: _obscurePassword,
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: FaIcon(
                    _obscurePassword
                        ? FontAwesomeIcons.eyeSlash
                        : FontAwesomeIcons.eye,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) return null; // Optional
                  return AuthValidation.validatePassword(value);
                },
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Password strength indicator
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: passwordStrength,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStrengthColor(passwordStrength),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getStrengthLabel(passwordStrength),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStrengthColor(passwordStrength),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  controller: _confirmPasswordController,
                  icon: FontAwesomeIcons.key,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                    child: FaIcon(
                      _obscureConfirmPassword
                          ? FontAwesomeIcons.eyeSlash
                          : FontAwesomeIcons.eye,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (_passwordController.text.isEmpty) return null;
                    if (value?.isEmpty == true)
                      return 'Please confirm password';
                    if (value != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      FaIcon(FontAwesomeIcons.userPlus, size: 18),
                      SizedBox(width: 12),
                      Text('Create Account',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Center(child: FaIcon(icon, size: 16, color: AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textLight),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: FaIcon(icon, size: 18, color: AppColors.textSecondary),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 52),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: suffixIcon)
                : null,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Continue',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            SizedBox(width: 10),
            FaIcon(FontAwesomeIcons.arrowRight, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Text('Log In',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                SizedBox(width: 6),
                FaIcon(FontAwesomeIcons.rightToBracket,
                    size: 12, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

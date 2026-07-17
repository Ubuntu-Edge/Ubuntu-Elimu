import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';

/// Welcome Screen - First screen after splash for new users
/// Provides app identity, value proposition, and call-to-action
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToOnboarding() async {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _navigateToLogin() async {
    // Mark as seen and go directly to login
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1E88E5),
                        const Color(0xFF0D47A1),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Gradient Overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxHeight < 600;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Top spacing and logo area
                          Flexible(
                            flex: 2,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: isSmallScreen ? 16 : 32),
                                    // Logo
                                    Container(
                                      width: isSmallScreen ? 80 : 100,
                                      height: isSmallScreen ? 80 : 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/ubuntuhealth_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    FontAwesomeIcons.heartPulse,
                                    size: 50,
                                    color: Color(0xFF1E88E5),
                                  );
                                },
                              ),
                            ),
                          ),
                                    SizedBox(height: isSmallScreen ? 12 : 20),
                                    // App Name
                                    Text(
                                      'UbuntuHealth',
                                      style: theme.textTheme.headlineLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        fontSize: isSmallScreen ? 24 : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Tagline
                                    Text(
                                      'Empowering Community Health Workers',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w300,
                                        fontSize: isSmallScreen ? 14 : null,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Value Propositions
                          Flexible(
                            flex: 2,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildFeatureItem(
                                        icon: FontAwesomeIcons.wifi,
                                        text: 'Works offline in low-connectivity areas',
                                        isSmall: isSmallScreen,
                                      ),
                                      SizedBox(height: isSmallScreen ? 10 : 16),
                                      _buildFeatureItem(
                                        icon: FontAwesomeIcons.clipboardCheck,
                                        text: 'Simplifies household visits & follow-ups',
                                        isSmall: isSmallScreen,
                                      ),
                                      SizedBox(height: isSmallScreen ? 10 : 16),
                                      _buildFeatureItem(
                                        icon: FontAwesomeIcons.shieldHalved,
                                        text: 'Keeps health data private & secure',
                                        isSmall: isSmallScreen,
                                      ),
                                      SizedBox(height: isSmallScreen ? 10 : 16),
                                      _buildFeatureItem(
                                        icon: FontAwesomeIcons.robot,
                                        text: 'AI-powered clinical decision support',
                                        isSmall: isSmallScreen,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // CTA Buttons
                          Flexible(
                            flex: 1,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Primary CTA
                                      SizedBox(
                                        width: double.infinity,
                                        height: isSmallScreen ? 48 : 56,
                                        child: ElevatedButton(
                                          onPressed: _navigateToOnboarding,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E88E5),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 8,
                                            shadowColor: const Color(0xFF1E88E5).withValues(alpha: 0.5),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Get Started',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 16 : 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const FaIcon(
                                                FontAwesomeIcons.arrowRight,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 8 : 16),
                                      // Secondary CTA
                                      TextButton(
                                        onPressed: _navigateToLogin,
                                        child: Text(
                                          'I already have an account',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Trust Signal
                          Padding(
                            padding: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.lock,
                                    size: isSmallScreen ? 12 : 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Offline-first & Privacy-focused',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: isSmallScreen ? 11 : 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildFeatureItem({required IconData icon, required String text, bool isSmall = false}) {
    return Row(
      children: [
        Container(
          width: isSmall ? 36 : 44,
          height: isSmall ? 36 : 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
            border: Border.all(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: FaIcon(
              icon,
              size: isSmall ? 16 : 20,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: isSmall ? 12 : 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

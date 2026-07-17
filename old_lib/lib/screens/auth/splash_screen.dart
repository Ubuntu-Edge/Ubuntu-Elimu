import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../welcome/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _statusMessage = 'Initializing...';
  double _progress = 0.0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 🧠 Main initialization (safe against context usage after awaits)
  Future<void> _initializeApp() async {
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Wait for plugins to be fully registered (critical for sqflite)
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _updateProgress('Checking first launch...', 0.2);
      
      // Check if user has seen onboarding
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        print('⚠️ SharedPreferences failed, treating as first launch: $e');
      }
      
      final hasSeenOnboarding = prefs?.getBool('hasSeenOnboarding') ?? false;
      
      await _updateProgress('Checking authentication...', 0.5);
      // Add a timeout to the authentication initialization
      await authProvider.initialize().timeout(const Duration(seconds: 10));

      await _updateProgress('Finalizing...', 0.9);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      await _animationController.reverse();

      // Determine target screen based on onboarding and auth status
      Widget targetScreen;
      if (!hasSeenOnboarding) {
        targetScreen = const WelcomeScreen();
      } else if (authProvider.isAuthenticated) {
        targetScreen = const HomeScreen();
      } else {
        targetScreen = const LoginScreen();
      }

      navigator.pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: targetScreen,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _statusMessage = 'Initialization failed: $e';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _showErrorDialog(navigator);
    }
  }

  /// ⏳ Animated progress updates
  Future<void> _updateProgress(String message, double targetProgress) async {
    if (!mounted) return;
    setState(() => _statusMessage = message);

    while (_progress < targetProgress && mounted) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
      setState(() {
        _progress += 0.02;
        if (_progress > targetProgress) _progress = targetProgress;
      });
    }
  }

  /// ⚠️ Error dialog (safe navigation)
  void _showErrorDialog(NavigatorState navigator) {
    if (!mounted) return;
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text(_statusMessage),
        actions: [
          TextButton(
            onPressed: () {
              navigator.pop();
              if (mounted) {
                setState(() {
                  _hasError = false;
                  _statusMessage = 'Retrying...';
                  _progress = 0.0;
                });
                _initializeApp();
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// 🎨 Gradient-based color transition
  Color get _progressColor {
    if (_progress < 0.33) return Colors.redAccent;
    if (_progress < 0.66) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_progress * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🩺 App Logo
                Image.asset(
                  'assets/images/ubuntuhealth_logo.png',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 32),

                const Text(
                  'UbuntuHealth',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Your health is our health!',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 48),

                if (!_hasError) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(.0),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_progressColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_statusMessage  ($percentage%)',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 48),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/followup_provider.dart';
import 'providers/pal_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/referral_provider.dart';
import 'providers/offline_model_provider.dart';
import 'providers/sync_provider.dart';
import 'services/notification_service.dart';
import 'services/medical_library_service.dart';
import 'services/ai_service.dart';
import 'services/offline_ai_service.dart';
import 'services/connectivity_service.dart';
import 'services/app_migration_service.dart';
import 'services/sync_service.dart';
import 'services/security_service.dart';
import 'services/feedback_service.dart';
import 'services/audit_log_service.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop/web platforms
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    // Desktop platforms need sqflite_common_ffi
    // This is handled by the sqflite package automatically on desktop
  }

  try {
    // Load environment variables with a timeout (optional for offline-only operation)
    await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 5));
    print('✅ Environment variables loaded');
  } catch (e) {
    // Non-critical error - app can work offline without online API token
    print('⚠️ .env file not loaded (offline-only mode): $e');
    // Continue initialization - app works offline without HF_API_TOKEN
  }

  // Check for app version updates and run migrations
  // This clears old state that might cause bugs after updates
  try {
    await AppMigrationService.checkAndMigrate();
  } catch (e) {
    print('Migration check failed: $e');
  }

  // Initialize all critical services
  try {
    await MedicalLibraryService.instance.loadLibrary();
  } catch (e) {
    print('MedicalLibraryService failed to initialize: $e');
  }
  
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    print('NotificationService failed to initialize: $e');
  }
  
  try {
    await AIService.instance.initialize();
  } catch (e) {
    print('AIService failed to initialize: $e');
  }
  
  try {
    await OfflineAIService.instance.initialize(); // Initialize offline AI service
  } catch (e) {
    print('OfflineAIService failed to initialize (non-critical): $e');
  }
  
  try {
    await ConnectivityService.instance.initialize(); // Initialize network monitoring
  } catch (e) {
    print('ConnectivityService failed to initialize: $e');
  }
  
  // Initialize new services for enhanced features
  try {
    await SyncService.instance.initialize(
      autoSyncInterval: const Duration(minutes: 15), // Auto-sync every 15 minutes
    ); // Background sync service with connectivity listening
  } catch (e) {
    print('SyncService failed to initialize: $e');
  }
  
  // Initialize audit logging service
  try {
    await AuditLogService.instance.initialize(); // Audit logging for offline operations
  } catch (e) {
    print('AuditLogService failed to initialize: $e');
  }
  
  try {
    await SecurityService.instance.initialize(); // Security and encryption service
  } catch (e) {
    print('SecurityService failed to initialize: $e');
  }
  
  // Skip FeedbackService on web as sqflite doesn't work there without special setup
  if (!kIsWeb) {
    try {
      await FeedbackService.instance.initialize(); // Feedback service
    } catch (e) {
      print('FeedbackService failed to initialize: $e');
    }
  }

  runApp(const CHWMedicalApp());
}

class CHWMedicalApp extends StatelessWidget {
  const CHWMedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => FollowupProvider()),
        ChangeNotifierProvider(
          create: (_) => PalProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
        ChangeNotifierProvider(
          create: (_) => OfflineModelProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'UbuntuHealth',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: localeProvider.currentLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing the app: $error'),
        ),
      ),
    );
  }
}
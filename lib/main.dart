import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'presentation/navigation/main_shell.dart';
import 'providers/navigation_provider.dart';
import 'providers/session_provider.dart';
import 'providers/document_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/offline_model_provider.dart';
import 'providers/chat_provider.dart';
import 'services/offline_ai_service.dart';
import 'services/education_service.dart';
import 'services/crash_logger_service.dart';

late DocumentProvider _docProvider;
late OfflineModelProvider _modelProvider;
late SessionProvider _sessionProvider;

/// Global error handler - catches uncaught exceptions
void _setupErrorHandlers() {
  // Handle uncaught exceptions in the main zone
  FlutterError.onError = (FlutterErrorDetails details) {
    CrashLoggerService.instance.logCrash(
      message: 'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
      context: {'type': 'FlutterError'},
    );
  };

  // Handle exceptions from isolates
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLoggerService.instance.logCrash(
      message: 'Platform Error (Isolate)',
      error: error,
      stackTrace: stack,
      context: {'type': 'PlatformError', 'fatal': true},
    );
    return true;
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup error handlers FIRST before any async operations
  _setupErrorHandlers();

  // Initialize local crash logger
  await CrashLoggerService.instance.initialize();

  // Initialize all providers within error boundary
  await runZonedGuarded(() async {
    try {
      await Hive.initFlutter();
      debugPrint('✅ Hive initialized');
    } catch (e) {
      debugPrint('❌ Hive init failed: $e');
      CrashLoggerService.instance.logCrash(
        message: 'Hive initialization failed',
        error: e,
      );
    }

    try {
      _docProvider = DocumentProvider();
      await _docProvider.init();
      debugPrint('✅ DocumentProvider initialized');
    } catch (e) {
      debugPrint('❌ DocumentProvider failed: $e');
      CrashLoggerService.instance.logCrash(
        message: 'DocumentProvider initialization failed',
        error: e,
      );
      _docProvider = DocumentProvider();
    }

    try {
      await OfflineAIService.instance.initialize();
      debugPrint('✅ OfflineAIService initialized');
    } catch (e) {
      debugPrint('⚠️ OfflineAIService failed (non-critical): $e');
    }

    try {
      _modelProvider = OfflineModelProvider();
      await _modelProvider.initialize();
      debugPrint('✅ OfflineModelProvider initialized');
    } catch (e) {
      debugPrint('❌ OfflineModelProvider failed: $e');
      CrashLoggerService.instance.logCrash(
        message: 'OfflineModelProvider initialization failed',
        error: e,
      );
      _modelProvider = OfflineModelProvider();
    }

    try {
      _sessionProvider = SessionProvider();
      await _sessionProvider.init();
      debugPrint('✅ SessionProvider initialized');
    } catch (e) {
      debugPrint('❌ SessionProvider failed: $e');
      CrashLoggerService.instance.logCrash(
        message: 'SessionProvider initialization failed',
        error: e,
      );
      _sessionProvider = SessionProvider();
    }

    runApp(const UbuntuElimuApp());
  }, (error, stackTrace) {
    // Catch any error that escapes the zone
    debugPrint('❌ FATAL ERROR (Zone): $error\n$stackTrace');
    CrashLoggerService.instance.logCrash(
      message: 'Zone-level uncaught error',
      error: error,
      stackTrace: stackTrace,
      context: {'type': 'ZonedError', 'fatal': true},
    );
  });
}

class UbuntuElimuApp extends StatelessWidget {
  const UbuntuElimuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider.value(value: _sessionProvider),
        ChangeNotifierProvider.value(value: _docProvider),
        ChangeNotifierProvider.value(value: _modelProvider),
        // 1. SettingsProvider must come before consumers like ChatProvider and EducationService
        ChangeNotifierProvider(
          create: (context) {
            final settings = SettingsProvider();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final models = context.read<OfflineModelProvider>();
              settings.attachModelProvider(models);
            });
            return settings;
          },
        ),
        // 2. ChatProvider depends on SettingsProvider for its AIProvider
        ChangeNotifierProxyProvider<SettingsProvider, ChatProvider>(
          create: (context) => ChatProvider(
            Provider.of<SettingsProvider>(context, listen: false)
                .getAIProvider(),
          ),
          update: (context, settings, chatProvider) {
            chatProvider?.updateAIProvider(settings.getAIProvider());
            return chatProvider ?? ChatProvider(settings.getAIProvider());
          },
        ),
        // 3. EducationService depends on SettingsProvider
        ProxyProvider<SettingsProvider, EducationService>(
          update: (context, settings, previous) =>
              EducationService(settings.getAIProvider()),
        ),
      ],
      child: MaterialApp(
        title: 'Ubuntu Elimu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFF0D0F14),
          brightness: Brightness.dark,
        ),
        home: const MainShell(),
      ),
    );
  }
}

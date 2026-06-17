import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'providers/navigation_provider.dart';
import 'providers/session_provider.dart';
import 'providers/document_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/offline_model_provider.dart';
import 'services/offline_ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize DocumentProvider and load stored documents
  final docProvider = DocumentProvider();
  await docProvider.init();

  // Initialize SessionProvider and load session history
  final sessionProvider = SessionProvider();
  await sessionProvider.init();

  // Initialize OfflineAIService
  await OfflineAIService.instance.initialize();

  // Initialize OfflineModelProvider and auto-load active model
  final modelProvider = OfflineModelProvider();
  await modelProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider.value(value: sessionProvider),
        ChangeNotifierProvider.value(value: docProvider),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider.value(value: modelProvider),
      ],
      child: const UbuntuElimuApp(),
    ),
  );
}

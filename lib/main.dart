import 'package:flutter/material.dart';
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

late DocumentProvider _docProvider;
late OfflineModelProvider _modelProvider;
late SessionProvider _sessionProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint('Hive init failed: $e');
  }

  try {
    _docProvider = DocumentProvider();
    await _docProvider.init();
  } catch (e) {
    debugPrint('DocumentProvider failed: $e');
    _docProvider = DocumentProvider();
  }

  try {
    await OfflineAIService.instance.initialize();
  } catch (e) {
    debugPrint('OfflineAIService failed (non-critical): $e');
  }

  try {
    _modelProvider = OfflineModelProvider();
    await _modelProvider.initialize();
  } catch (e) {
    debugPrint('OfflineModelProvider failed: $e');
    _modelProvider = OfflineModelProvider();
  }

  try {
    _sessionProvider = SessionProvider();
    await _sessionProvider.init();
  } catch (e) {
    debugPrint('SessionProvider failed: $e');
    _sessionProvider = SessionProvider();
  }

  runApp(const UbuntuElimuApp());
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
            Provider.of<SettingsProvider>(context, listen: false).getAIProvider(),
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

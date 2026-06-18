import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/navigation/main_shell.dart';
import 'providers/navigation_provider.dart';
import 'providers/session_provider.dart';
import 'providers/document_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/offline_model_provider.dart';
import 'services/offline_ai_service.dart';

void main() {
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool _ready = false;

  late DocumentProvider _docProvider;
  late OfflineModelProvider _modelProvider;
  late SessionProvider _sessionProvider;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Platform channels are guaranteed ready here
    await Hive.initFlutter();
    await SharedPreferences.getInstance();

    _docProvider = DocumentProvider();
    await _docProvider.init();

    await OfflineAIService.instance.initialize();

    _modelProvider = OfflineModelProvider();
    await _modelProvider.initialize();

    _sessionProvider = SessionProvider();
    await _sessionProvider.init();

    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0D0F14),
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider.value(value: _sessionProvider),
        ChangeNotifierProvider.value(value: _docProvider),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider.value(value: _modelProvider),
      ],
      child: MaterialApp(
        title: 'Ubuntu Elimu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFF0D0F14),
        ),
        home: const MainShell(),
      ),
    );
  }
}
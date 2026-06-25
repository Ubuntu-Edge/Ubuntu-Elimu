import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'presentation/navigation/main_shell.dart';
import 'providers/navigation_provider.dart';
import 'providers/session_provider.dart';
import 'providers/document_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/offline_model_provider.dart';
import 'services/offline_ai_service.dart';

late DocumentProvider _docProvider;
late OfflineModelProvider _modelProvider;
late SessionProvider _sessionProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
  } catch (e) {
    print('Hive init failed: $e');
  }

  try {
    _docProvider = DocumentProvider();
    await _docProvider.init();
  } catch (e) {
    print('DocumentProvider failed: $e');
    _docProvider = DocumentProvider();
  }

  try {
    await OfflineAIService.instance.initialize();
  } catch (e) {
    print('OfflineAIService failed (non-critical): $e');
  }

  try {
    _modelProvider = OfflineModelProvider();
    await _modelProvider.initialize();
  } catch (e) {
    print('OfflineModelProvider failed: $e');
    _modelProvider = OfflineModelProvider();
  }

  try {
    _sessionProvider = SessionProvider();
    await _sessionProvider.init();
  } catch (e) {
    print('SessionProvider failed: $e');
    _sessionProvider = SessionProvider();
  }

  runApp(
    UbuntuElimuApp(
      docProvider: _docProvider,
      modelProvider: _modelProvider,
      sessionProvider: _sessionProvider,
    ),
  );
}
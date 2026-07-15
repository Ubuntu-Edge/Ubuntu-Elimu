import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'offline_model_provider.dart';
import '../models/offline_model.dart';
import '../services/ai/base_ai_provider.dart';
import '../services/ai/local_ai_provider.dart';
import '../services/ai/groq_ai_provider.dart';

enum AIBackend { local, groq }

class SettingsProvider with ChangeNotifier {
  bool _socraticMode = true;
  bool _powerMode = true;
  AIBackend _activeBackend = AIBackend.local;
  String _groqApiKey = '';

  // Reference to the real model provider
  OfflineModelProvider? _modelProvider;
  late Box _settingsBox;
  bool _isInitialized = false;

  bool get socraticMode => _socraticMode;
  bool get powerMode => _powerMode;
  AIBackend get activeBackend => _activeBackend;
  bool get isInitialized => _isInitialized;
  String get groqApiKey => _groqApiKey;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    _settingsBox = await Hive.openBox('settings');

    _socraticMode = _settingsBox.get('socraticMode', defaultValue: true);
    _powerMode = _settingsBox.get('powerMode', defaultValue: true);
    _groqApiKey = _settingsBox.get('groqApiKey', defaultValue: '');

    // Default to Groq (Proxy) if no preference saved
    final backendIndex = _settingsBox.get(
      'activeBackend',
      defaultValue: AIBackend.groq.index,
    );
    _activeBackend = AIBackend.values[backendIndex];

    _isInitialized = true;
    notifyListeners();
  }

  bool get isModelDownloaded =>
      _modelProvider?.models.any((m) => m.isDownloaded) ?? false;

  String get modelName {
    if (_activeBackend == AIBackend.groq) return 'Groq (Secure Proxy)';
    final active = _modelProvider?.activeModel;
    if (active != null) return active.name;
    return _modelProvider?.models.firstOrNull?.name ?? 'No model selected';
  }

  AIProvider getAIProvider() {
    if (_activeBackend == AIBackend.groq) {
      return GroqAIProvider(_groqApiKey);
    }
    return LocalAIProvider();
  }

  void setAIBackend(AIBackend backend) {
    _activeBackend = backend;
    _settingsBox.put('activeBackend', backend.index);
    notifyListeners();
  }

  void attachModelProvider(OfflineModelProvider provider) {
    _modelProvider = provider;
    provider.addListener(_onModelProviderChanged);
    notifyListeners();
  }

  void _onModelProviderChanged() => notifyListeners();

  void toggleSocraticMode(bool value) {
    _socraticMode = value;
    _settingsBox.put('socraticMode', value);
    notifyListeners();
  }

  void togglePowerMode(bool value) {
    _powerMode = value;
    _settingsBox.put('powerMode', value);
    notifyListeners();
  }

  void setGroqApiKey(String value) {
    _groqApiKey = value;
    _settingsBox.put('groqApiKey', value);
    notifyListeners();
  }

  @override
  void dispose() {
    _modelProvider?.removeListener(_onModelProviderChanged);
    super.dispose();
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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

  // Reference to the real model provider
  OfflineModelProvider? _modelProvider;

  bool get socraticMode => _socraticMode;
  bool get powerMode => _powerMode;
  AIBackend get activeBackend => _activeBackend;

  // Delegate all model state to OfflineModelProvider
  bool get isModelDownloaded => _modelProvider?.models.any((m) => m.isDownloaded) ?? false;
  bool get isDownloading => _modelProvider?.models.any((m) => m.downloadProgress > 0 && m.downloadProgress < 1.0) ?? false;
  double get downloadProgress {
    final downloading = _modelProvider?.models
        .where((m) => m.downloadProgress > 0 && m.downloadProgress < 1.0)
        .firstOrNull;
    return downloading?.downloadProgress ?? 0.0;
  }
  String get modelName {
    if (_activeBackend == AIBackend.groq) return 'Groq (Cloud)';
    final active = _modelProvider?.activeModel;
    if (active != null) return active.name;
    return _modelProvider?.models.firstOrNull?.name ?? 'No model selected';
  }

  /// Returns the appropriate AI provider based on current settings
  AIProvider getAIProvider() {
    if (_activeBackend == AIBackend.groq) {
      // Use environment variable for the API key
      const apiKey = String.fromEnvironment('GROQ_API_KEY');
      if (apiKey.isNotEmpty) {
        return GroqAIProvider(apiKey);
      }
      // Fallback to runtime environment variable (e.g. for local dev/testing)
      final envKey = Platform.environment['GROQ_API_KEY'] ?? '';
      return GroqAIProvider(envKey);
    }
    return LocalAIProvider();
  }

  void setAIBackend(AIBackend backend) {
    _activeBackend = backend;
    notifyListeners();
  }

  /// Call this from the UI or main.dart after providers are set up
  void attachModelProvider(OfflineModelProvider provider) {
    _modelProvider = provider;
    provider.addListener(_onModelProviderChanged);
    notifyListeners();
  }

  void _onModelProviderChanged() {
    notifyListeners(); // bubble up changes from OfflineModelProvider
  }

  void toggleSocraticMode(bool value) {
    _socraticMode = value;
    notifyListeners();
  }

  void togglePowerMode(bool value) {
    _powerMode = value;
    notifyListeners();
  }

  void startModelDownload() {
    final model = _modelProvider?.models.firstOrNull;
    if (model == null || model.isDownloaded) return;
    _modelProvider?.startDownload(model); // Updated to handle listener state internally
  }

  void deleteModel() {
    final model = _modelProvider?.models.where((m) => m.isDownloaded).firstOrNull;
    if (model != null) {
      _modelProvider?.deleteModel(model);
    }
  }

  @override
  void dispose() {
    _modelProvider?.removeListener(_onModelProviderChanged);
    super.dispose();
  }
}

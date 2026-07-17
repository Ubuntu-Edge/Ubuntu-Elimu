import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

import '../models/offline_model.dart';
import '../models/offline_context_params.dart';
import '../models/default_offline_models.dart';
import '../services/model_download_service.dart';
import '../services/offline_ai_service.dart';

/// Provider for managing offline AI models (GGUF models for llama.cpp)
class OfflineModelProvider extends ChangeNotifier {
  List<OfflineModel> _models = [];
  OfflineModel? _activeModel;
  bool _isContextLoading = false;
  bool _isInferencing = false;
  bool _isStreaming = false;
  String? _error;

  OfflineContextParams _contextParams = const OfflineContextParams();

  static const String _modelsKey = 'offline_models';
  static const String _activeModelKey = 'active_offline_model_id';
  static const String _contextParamsKey = 'offline_context_params';

  // Getters
  List<OfflineModel> get models => _models;
  OfflineModel? get activeModel => _activeModel;
  bool get isContextLoading => _isContextLoading;
  bool get isInferencing => _isInferencing;
  bool get isStreaming => _isStreaming;
  String? get error => _error;
  OfflineContextParams get contextParams => _contextParams;
  bool get hasActiveModel => _activeModel != null;

  /// Request necessary permissions for offline model loading
  Future<bool> _requestModelLoadingPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
    }
    return true;
  }

  /// Initialize - load models from storage
  Future<void> initialize() async {
    try {
      debugPrint('🚀 Initializing OfflineModelProvider...');

      // Give the Flutter engine time to register plugin channels
      await Future.delayed(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();

      // Load models from storage or defaults
      final modelsJson = prefs.getStringList(_modelsKey) ?? [];
      if (modelsJson.isEmpty) {
        _models = DefaultOfflineModels.getEducationModels();
        debugPrint('✅ Loaded default models');
      } else {
        _models = modelsJson
            .map((json) => OfflineModel.fromJson(jsonDecode(json)))
            .toList();
        debugPrint('✅ Loaded ${_models.length} models from storage');
      }

      // Auto-detect downloaded models from disk
      await _autoDetectDownloadedModels();

      // Load active model
      final activeModelId = prefs.getString(_activeModelKey);
      if (activeModelId != null) {
        final model = _models.where((m) => m.id == activeModelId).firstOrNull;
        if (model != null && model.isDownloaded) {
          await setActiveModel(model);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ OfflineModelProvider initialization failed: $e');
      _models = DefaultOfflineModels.getEducationModels();
      notifyListeners();
    }
  }

  /// Set active model (will be loaded for inference)
  Future<void> setActiveModel(OfflineModel model) async {
    _error = null;

    if (!model.isDownloaded) {
      _error = 'Model must be downloaded first.';
      notifyListeners();
      return;
    }

    _activeModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeModelKey, model.id);

    _isContextLoading = true;
    notifyListeners();

    try {
      final modelPath = await getModelFullPath(model);

      if (modelPath == null) {
        throw Exception('Model file not found on device');
      }

      // Validate file exists and is not empty
      final file = File(modelPath);
      if (!await file.exists()) {
        throw Exception('Model file does not exist: $modelPath');
      }

      final fileSize = await file.length();
      if (fileSize < 1024 * 1024) {
        throw Exception(
          'Model file is too small (${fileSize} bytes). File may be corrupted.',
        );
      }

      debugPrint('📂 Model path validated: $modelPath');
      debugPrint(
        '📊 File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
      );

      await _requestModelLoadingPermissions();

      // Load model with error handling
      debugPrint('🔄 Loading model into memory...');
      final loaded = await OfflineAIService.instance
          .loadModel(modelPath: modelPath, model: model)
          .timeout(
        const Duration(seconds: 60), // Increased timeout for memory checks
        onTimeout: () {
          throw TimeoutException(
            'Model loading timed out after 60 seconds',
          );
        },
      );

      if (!loaded) {
        throw Exception(
          'Model failed to load. This may be due to insufficient memory or an incompatible model format.',
        );
      }

      debugPrint('✅ Model loaded successfully: ${model.name}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading model: $e');
      debugPrint('Stack trace: $stackTrace');

      // Provide user-friendly error messages
      if (e.toString().contains('Insufficient memory') ||
          e.toString().contains('OutOfMemory') ||
          e.toString().contains('memory')) {
        _error = 'Insufficient Memory 💾\n\n'
            'Your device doesn\'t have enough available RAM to load this model.\n\n'
            '📋 Solutions:\n'
            '• Close other apps to free memory\n'
            '• Restart your device\n'
            '• Use a smaller/lighter model\n'
            '• Try again when fewer apps are running\n\n'
            'Try checking your RAM usage in Android Settings.';
      } else if (e.toString().contains('timeout')) {
        _error = 'Loading Timeout ⏱️\n\n'
            'The model took too long to load. This usually indicates:\n\n'
            '• Low device memory\n'
            '• Background apps using resources\n'
            '• Very large model file\n\n'
            'Try restarting your device and closing all other apps before loading the model.';
      } else if (e.toString().contains('corrupted') ||
          e.toString().contains('too small')) {
        _error = 'Corrupted Model File ⚠️\n\n'
            'The model file appears to be incomplete or corrupted.\n\n'
            'Solutions:\n'
            '• Delete the model from the list\n'
            '• Re-download it with stable WiFi\n'
            '• Check your storage isn\'t full';
      } else {
        _error = 'Failed to Load Model ❌\n\n'
            '$e\n\n'
            'Troubleshooting:\n'
            '• Restart the app\n'
            '• Re-download the model\n'
            '• Try a different model\n'
            '• Check available storage space';
      }

      // Clear active model on failure
      _activeModel = null;
      await prefs.remove(_activeModelKey);
    } finally {
      _isContextLoading = false;
      notifyListeners();
    }
  }

  /// Download a model (returns stream for UI to listen to)
  Stream<ModelDownloadProgress> downloadModel(OfflineModel model) {
    return ModelDownloadService.instance.downloadModel(
      url: model.downloadUrl ?? '',
      modelId: model.id,
      fileName: model.filename ?? '${model.id}.gguf',
      author: model.author,
      useCompression: false,
    );
  }

  /// Start download and update state automatically
  Future<void> startDownload(OfflineModel model) async {
    _error = null;

    downloadModel(model).listen((progress) {
      final index = _models.indexWhere((m) => m.id == model.id);
      if (index == -1) return;

      if (progress.stage == ModelDownloadStage.completed &&
          progress.localPath != null) {
        _models[index] = _models[index].copyWith(
          isDownloaded: true,
          downloadProgress: 1.0,
          localPath: progress.localPath,
        );
        _saveModels();
        debugPrint('✅ Download complete: ${model.name}');
      } else if (progress.stage == ModelDownloadStage.failed) {
        _error = progress.error;
        _models[index] = _models[index].copyWith(downloadProgress: 0);
        debugPrint('❌ Download failed: ${progress.error}');
      } else {
        // progress.progress is 0-100, normalize to 0.0-1.0
        _models[index] = _models[index].copyWith(
          downloadProgress: progress.progress / 100,
        );
      }
      notifyListeners();
    });
  }

  Future<String?> getModelFullPath(OfflineModel model) async {
    if (model.localPath != null && await File(model.localPath!).exists()) {
      return model.localPath;
    }

    final storageDir = await _getModelStorageDirectory();
    final path = '${storageDir.path}/models/${model.author}/${model.filename}';
    if (await File(path).exists()) return path;
    return null;
  }

  Future<Directory> _getModelStorageDirectory() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir != null) return dir;
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _autoDetectDownloadedModels() async {
    bool changed = false;
    for (int i = 0; i < _models.length; i++) {
      final path = await getModelFullPath(_models[i]);
      if (path != null && !_models[i].isDownloaded) {
        _models[i] = _models[i].copyWith(
          isDownloaded: true,
          downloadProgress: 1.0,
          localPath: path,
        );
        changed = true;
      }
    }
    if (changed) await _saveModels();
  }

  Future<void> _saveModels() async {
    // Add small delay to ensure channel is ready if called early
    await Future.delayed(const Duration(milliseconds: 100));
    final prefs = await SharedPreferences.getInstance();
    final modelsJson = _models.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_modelsKey, modelsJson);
  }

  Future<void> deleteModel(OfflineModel model) async {
    final path = await getModelFullPath(model);
    if (path != null) {
      await ModelDownloadService.instance.deleteModel(path);

      // Explicitly resetting model progress properties directly inline
      final index = _models.indexWhere((m) => m.id == model.id);
      if (index != -1) {
        _models[index] = _models[index].copyWith(
          downloadProgress: 0.0,
          isDownloaded: false,
          localPath: null,
        );
      }

      if (_activeModel?.id == model.id) {
        _activeModel = null;
        await OfflineAIService.instance.unloadModel();
      }

      await _saveModels();
      notifyListeners();
    }
  }

  Future<void> clearActiveModel() async {
    await OfflineAIService.instance.unloadModel();
    _activeModel = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeModelKey);
    notifyListeners();
  }

  /// Clear any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

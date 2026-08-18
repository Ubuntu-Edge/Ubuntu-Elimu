import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:denizen_ai/denizen_ai.dart';

/// Provider for managing offline AI models using the Denizen AI Model Manager.
class OfflineModelProvider extends ChangeNotifier {
  final DenizenAI _denizen = DenizenAI();
  List<OfflineModel> _models = [];
  OfflineModel? _activeModel;
  bool _isContextLoading = false;
  final bool _isInferencing = false;
  final bool _isStreaming = false;
  String? _error;

  static const String _modelsKey = 'offline_models';
  static const String _activeModelKey = 'active_offline_model_id';

  // Getters
  List<OfflineModel> get models => _models;
  OfflineModel? get activeModel => _activeModel;
  bool get isContextLoading => _isContextLoading;
  bool get isInferencing => _isInferencing;
  bool get isStreaming => _isStreaming;
  String? get error => _error;
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

  /// Initialize - load models from storage and auto-detect downloaded models
  Future<void> initialize() async {
    try {
      debugPrint('🚀 Initializing OfflineModelProvider with Denizen AI...');
      final prefs = await SharedPreferences.getInstance();

      final defaultModels = DefaultOfflineModels.getMedicalModels();

      // Load models from storage
      final modelsJson = prefs.getStringList(_modelsKey) ?? [];
      if (modelsJson.isEmpty) {
        _models = defaultModels;
      } else {
        final storedModels = modelsJson.map((json) {
          try {
            return OfflineModel.fromJson(jsonDecode(json));
          } catch (_) {
            return null;
          }
        }).whereType<OfflineModel>().toList();

        // Merge stored models with default models, replacing obsolete entries
        final Map<String, OfflineModel> modelMap = {
          for (final m in defaultModels) m.id: m,
        };

        for (final stored in storedModels) {
          if (modelMap.containsKey(stored.id)) {
            modelMap[stored.id] = modelMap[stored.id]!.copyWith(
              isDownloaded: stored.isDownloaded,
              downloadProgress: stored.downloadProgress,
              localPath: stored.localPath,
            );
          } else if (stored.isDownloaded) {
            modelMap[stored.id] = stored;
          }
        }

        _models = modelMap.values.toList();
      }

      // Auto-detect downloaded models from Denizen AI engine / storage
      await _autoDetectDownloadedModels();

      // Load active model if previously saved
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
      _models = DefaultOfflineModels.getMedicalModels();
      notifyListeners();
    }
  }

  /// Set active model (will be loaded into Denizen AI native inference engine)
  Future<void> setActiveModel(OfflineModel model) async {
    if (_isContextLoading && _activeModel?.id == model.id) return; // Prevent concurrent re-entry for same model
    _error = null;

    _isContextLoading = true;
    notifyListeners();

    try {
      await _requestModelLoadingPermissions();

      // Cleanly unload any existing model from native C++ RAM first to prevent OOM crash
      if (_denizen.isModelLoaded) {
        await _denizen.engine.unloadModel();
      }

      await _denizen.models.load(
        model.id,
        onProgress: (progress) {
          final fraction = progress.progress.clamp(0.0, 1.0);
          _updateModelProgress(model.id, fraction, false);
        },
      );

      _activeModel = model;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeModelKey, model.id);

      _updateModelProgress(model.id, 1.0, true);
      debugPrint('✅ Model loaded successfully into Denizen AI engine: ${model.name}');
    } catch (e) {
      _error = 'Error loading model: $e';
      _updateModelProgress(model.id, 0.0, false);
      debugPrint('❌ Error loading model: $e');
    } finally {
      _isContextLoading = false;
      notifyListeners();
    }
  }

  /// Download a model via Denizen AI Model Manager
  Future<void> downloadModel(OfflineModel model) async {
    _isContextLoading = false;
    _error = null;
    await setActiveModel(model);
  }

  /// Cancel an in-progress download
  void cancelDownload(String modelId) {
    try {
      ModelDownloadService.instance.cancelDownload(modelId);
    } catch (e) {
      debugPrint('Notice on cancelDownload: $e');
    }
    _isContextLoading = false;
    _error = null;
    _updateModelProgress(modelId, 0.0, false);
    notifyListeners();
  }

  void _updateModelProgress(String id, double progress, bool downloaded, {String? path}) {
    final index = _models.indexWhere((m) => m.id == id);
    if (index != -1) {
      _models[index] = _models[index].copyWith(
        downloadProgress: progress,
        isDownloaded: downloaded,
        localPath: path,
      );
      notifyListeners();
    }
  }

  Future<String?> getModelFullPath(OfflineModel model) async {
    if (model.localPath != null && await File(model.localPath!).exists()) {
      return model.localPath;
    }

    final storageDir = await ModelDownloadService.instance.getModelStorageDirectory();
    final path = '${storageDir.path}/models/${model.author}/${model.filename}';
    if (await File(path).exists()) return path;
    return null;
  }

  Future<void> _autoDetectDownloadedModels() async {
    bool changed = false;
    for (int i = 0; i < _models.length; i++) {
      final isDownloaded = await _denizen.models.isDownloaded(_models[i].id);
      final path = await getModelFullPath(_models[i]);
      if ((isDownloaded || path != null) && !_models[i].isDownloaded) {
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
    final prefs = await SharedPreferences.getInstance();
    final modelsJson = _models.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_modelsKey, modelsJson);
  }

  Future<void> deleteModel(OfflineModel model) async {
    await _denizen.models.deleteModel(model.id);
    _updateModelProgress(model.id, 0.0, false, path: null);

    if (_activeModel?.id == model.id) {
      _activeModel = null;
      await _denizen.engine.unloadModel();
    }

    await _saveModels();
  }

  /// Total disk space used by downloaded models, in bytes
  Future<int> getUsedStorageBytes() {
    return ModelDownloadService.instance.getModelsDirectorySize();
  }

  Future<void> clearActiveModel() async {
    await _denizen.engine.unloadModel();
    _activeModel = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeModelKey);
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:denizen_ai/denizen_ai.dart';

/// Provider for managing offline AI models using the Denizen AI Model Manager.
class OfflineModelProvider extends ChangeNotifier with WidgetsBindingObserver {
  final DenizenAI _denizen = DenizenAI();
  List<OfflineModel> _models = [];
  OfflineModel? _activeModel;
  bool _isContextLoading = false;
  final bool _isInferencing = false;
  final bool _isStreaming = false;
  String? _error;

  static const String _modelsKey = 'offline_models';
  static const String _activeModelKey = 'active_offline_model_id';

  OfflineModelProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isContextLoading) {
        _isContextLoading = false;
        notifyListeners();
      }
    }
  }

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

      final Map<String, OfflineModel> modelMap = {
        for (final m in defaultModels) m.id: m,
      };

      // Load models from storage and merge with default catalog
      final storedModelsJson = prefs.getString(_modelsKey);
      if (storedModelsJson != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(storedModelsJson);
          for (final j in jsonList) {
            final stored = OfflineModel.fromJson(j);
            if (modelMap.containsKey(stored.id)) {
              modelMap[stored.id] = modelMap[stored.id]!.copyWith(
                isDownloaded: stored.isDownloaded,
                downloadProgress: stored.downloadProgress,
                localPath: stored.localPath,
              );
            } else {
              modelMap[stored.id] = stored;
            }
          }
        } catch (e) {
          debugPrint('Error parsing stored models: $e');
        }
      }

      _models = modelMap.values.toList();
      await _autoDetectDownloadedModels();

      // Restore active model if recorded
      final storedActiveId = prefs.getString(_activeModelKey);
      if (storedActiveId != null) {
        final activeIndex = _models.indexWhere((m) => m.id == storedActiveId);
        if (activeIndex != -1 && _models[activeIndex].isDownloaded) {
          _activeModel = _models[activeIndex];
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ OfflineModelProvider initialization error: $e');
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
      await WakelockPlus.enable();
      await _requestModelLoadingPermissions();

      // Cleanly unload any existing model from native C++ RAM first to prevent OOM crash
      if (_denizen.isModelLoaded) {
        await _denizen.engine.unloadModel();
      }

      await _denizen.models.load(
        model.id,
        onProgress: (progress) {
          final fraction = progress.progress.clamp(0.0, 1.0);
          final isDownloaded = fraction >= 0.999;
          _updateModelProgress(model.id, fraction, isDownloaded);
        },
      );

      _activeModel = model;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeModelKey, model.id);

      _updateModelProgress(model.id, 1.0, true);
      await _saveModelsToPrefs();
      debugPrint('✅ Model loaded successfully into Denizen AI engine: ${model.name}');
    } catch (e) {
      _error = 'Error loading model: $e';
      final isAlreadyDownloaded = await _denizen.models.isDownloaded(model.id);
      if (!isAlreadyDownloaded) {
        _updateModelProgress(model.id, 0.0, false);
      }
      debugPrint('❌ Error loading model: $e');
    } finally {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
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
      if (downloaded) {
        _saveModelsToPrefs();
      }
      notifyListeners();
    }
  }

  Future<void> _saveModelsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _models.map((m) => m.toJson()).toList();
      await prefs.setString(_modelsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving models to prefs: $e');
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

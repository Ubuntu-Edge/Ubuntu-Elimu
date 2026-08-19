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

  String? _downloadingModelId;
  String? _lastErrorModelId;
  void Function(String modelName, String message)? onLoadError;

  // Getters
  List<OfflineModel> get models => _models;
  OfflineModel? get activeModel => _activeModel;
  String? get downloadingModelId => _downloadingModelId;
  String? get lastErrorModelId => _lastErrorModelId;
  String? get loadedModelId => _denizen.engine.loadedModel?.id ?? _activeModel?.id;
  bool get isContextLoading => _isContextLoading;
  bool get isInferencing => _isInferencing;
  bool get isStreaming => _isStreaming;
  String? get error => _error;
  bool get hasActiveModel => _activeModel != null || _denizen.isModelLoaded;

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

  /// Returns available RAM in MB by reading /proc/meminfo (Android only).
  /// Returns -1 if unavailable or not on Android.
  Future<int> getAvailableRamMB() async {
    try {
      if (Platform.isAndroid) {
        final memInfo = await File('/proc/meminfo').readAsString();
        final match = RegExp(r'MemAvailable:\s+(\d+)').firstMatch(memInfo);
        if (match != null) {
          return int.parse(match.group(1)!) ~/ 1024; // kB → MB
        }
      }
    } catch (e) {
      debugPrint('RAM check unavailable: $e');
    }
    return -1; // Unknown — allow load to proceed
  }

  /// Initialize - load models from storage and auto-detect downloaded models
  Future<void> initialize() async {
    try {
      debugPrint('🚀 Initializing OfflineModelProvider with Denizen AI...');
      final prefs = await SharedPreferences.getInstance();

      final defaultModels = DefaultOfflineModels.getEducationModels();

      final Map<String, OfflineModel> modelMap = {
        for (final m in defaultModels) m.id: m,
      };

      // Load models from storage and merge with default catalog
      String? storedModelsJson;
      try {
        final raw = prefs.get(_modelsKey);
        if (raw is String) {
          storedModelsJson = raw;
        } else if (raw is List) {
          storedModelsJson = jsonEncode(raw);
        }
      } catch (e) {
        debugPrint('Safe prefs read error: $e');
      }

      if (storedModelsJson != null) {
        try {
          final dynamic decoded = jsonDecode(storedModelsJson);
          if (decoded is List) {
            for (final j in decoded) {
              if (j is Map<String, dynamic>) {
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
            }
          }
        } catch (e) {
          debugPrint('Error parsing stored models: $e');
        }
      }

      _models = modelMap.values.toList();
      await _autoDetectDownloadedModels();

      // Verify if a model is actually live in native C++ memory
      if (_denizen.isModelLoaded && _denizen.engine.loadedModel != null) {
        final activeIndex = _models.indexWhere((m) => m.id == _denizen.engine.loadedModel!.id);
        if (activeIndex != -1) {
          _activeModel = _models[activeIndex];
        }
      } else {
        _activeModel = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ OfflineModelProvider initialization error: $e');
      _models = DefaultOfflineModels.getMedicalModels();
      await _autoDetectDownloadedModels();
      notifyListeners();
    }
  }

  /// Set active model (will be loaded into Denizen AI native inference engine)
  Future<void> setActiveModel(OfflineModel model) async {
    // Fast-path: if this model is already live in the engine, just record it and done
    if (_denizen.engine.loadedModel?.id == model.id) {
      _activeModel = model;
      _downloadingModelId = null;
      _isContextLoading = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeModelKey, model.id);
      notifyListeners();
      debugPrint('✅ Model already in engine, no reload needed: ${model.name}');
      return;
    }

    _error = null;
    _downloadingModelId = model.id;
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
      debugPrint('✅ Model loaded into Denizen engine: ${model.name}');
    } catch (e) {
      final errMsg = e.toString().replaceFirst('Exception: ', '');
      _error = errMsg;
      _lastErrorModelId = model.id;
      final isAlreadyDownloaded = await _denizen.models.isDownloaded(model.id);
      if (!isAlreadyDownloaded) {
        _updateModelProgress(model.id, 0.0, false);
      }
      debugPrint('❌ Error loading model ${model.name}: $e');
      onLoadError?.call(model.name, errMsg);
    } finally {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
      _downloadingModelId = null;
      _isContextLoading = false;
      notifyListeners();
    }
  }

  /// Download a model via Denizen AI Model Manager
  Future<void> downloadModel(OfflineModel model) async {
    await setActiveModel(model);
  }

  /// Cancel an in-progress download
  void cancelDownload(String modelId) {
    try {
      ModelDownloadService.instance.cancelDownload(modelId);
    } catch (e) {
      debugPrint('Notice on cancelDownload: $e');
    }
    _downloadingModelId = null;
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

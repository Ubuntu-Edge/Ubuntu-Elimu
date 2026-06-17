import 'package:flutter/material.dart';
import '../models/offline_model.dart';
import '../models/default_offline_models.dart';
import '../services/model_download_service.dart';
import '../services/offline_ai_service.dart';

class OfflineModelProvider with ChangeNotifier {
  final ModelDownloadService _downloadService = ModelDownloadService();
  final OfflineAiService _aiService = OfflineAiService();

  List<OfflineModel> _availableModels = DefaultOfflineModels.availableModels;
  String? _activeModelId;
  double _downloadProgress = 0;
  bool _isDownloading = false;
  String? _error;

  // Getters
  List<OfflineModel> get availableModels => _availableModels;
  String? get activeModelId => _activeModelId;
  double get downloadProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;
  String? get error => _error;
  bool get isAiInitialized => _aiService.isInitialized;

  OfflineModelProvider() {
    _checkDownloadedModels();
  }

  Future<void> _checkDownloadedModels() async {
    List<OfflineModel> updatedModels = [];
    for (var model in _availableModels) {
      bool exists = await _downloadService.checkModelExists(model.filename);
      updatedModels.add(model.copyWith(isDownloaded: exists));
    }
    _availableModels = updatedModels;
    notifyListeners();
  }

  Future<void> downloadModel(OfflineModel model) async {
    _isDownloading = true;
    _downloadProgress = 0;
    _error = null;
    notifyListeners();

    await _downloadService.downloadModel(
      model: model,
      onProgress: (progress) {
        _downloadProgress = progress;
        notifyListeners();
      },
      onSuccess: (path) async {
        _isDownloading = false;
        _downloadProgress = 1.0;
        await _checkDownloadedModels();
        notifyListeners();
      },
      onError: (err) {
        _isDownloading = false;
        _error = err;
        notifyListeners();
      },
    );
  }

  Future<void> setActiveModel(String modelId) async {
    final model = _availableModels.firstWhere((m) => m.id == modelId);
    if (!model.isDownloaded) {
      _error = "Model must be downloaded first.";
      notifyListeners();
      return;
    }

    _activeModelId = modelId;
    
    // Initialize AI with the new model
    // In a real app, you'd get the full path to the model file
    // String path = await _getModelPath(model.filename);
    // await _aiService.initialize(path);
    
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

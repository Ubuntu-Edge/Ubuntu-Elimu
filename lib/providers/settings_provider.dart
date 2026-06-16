import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  bool _socraticMode = true;
  bool _powerMode = true;
  String _sourceLanguage = 'EN';
  String _targetLanguage = 'SW';

  // Offline models statuses
  bool _isModelDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _modelName = 'Socratic-Mini-7B-Quantized (1.4 GB)';

  bool get socraticMode => _socraticMode;
  bool get powerMode => _powerMode;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  bool get isModelDownloaded => _isModelDownloaded;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get modelName => _modelName;

  void toggleSocraticMode(bool value) {
    _socraticMode = value;
    notifyListeners();
  }

  void togglePowerMode(bool value) {
    _powerMode = value;
    notifyListeners();
  }

  void setLanguages(String source, String target) {
    _sourceLanguage = source;
    _targetLanguage = target;
    notifyListeners();
  }

  void startModelDownload() {
    if (_isModelDownloaded || _isDownloading) return;
    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    // Simulate downloading progress
    int steps = 20;
    int currentStep = 0;
    StreamPeriodically(const Duration(milliseconds: 150), (timer) {
      currentStep++;
      _downloadProgress = currentStep / steps;
      if (currentStep >= steps) {
        timer.cancel();
        _isDownloading = false;
        _isModelDownloaded = true;
        _downloadProgress = 1.0;
      }
      notifyListeners();
    });
  }

  void deleteModel() {
    _isModelDownloaded = false;
    _downloadProgress = 0.0;
    notifyListeners();
  }
}

// Simple periodic helper class since timer in microtask can be cleaner
class StreamPeriodically {
  final Duration duration;
  final void Function(StreamPeriodically timer) callback;
  late Timer _timer;

  StreamPeriodically(this.duration, this.callback) {
    _timer = Timer.periodic(duration, (t) {
      callback(this);
    });
  }

  void cancel() {
    _timer.cancel();
  }
}

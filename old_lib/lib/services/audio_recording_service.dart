import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// Service for recording and playing audio messages
/// Uses native audio recording capabilities
class AudioRecordingService {
  static final AudioRecordingService _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final _uuid = const Uuid();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  String? _currentPlayingPath;
  DateTime? _recordingStartTime;
  
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  
  // Stream controllers for UI updates
  final _recordingStateController = StreamController<RecordingState>.broadcast();
  final _playbackStateController = StreamController<PlaybackState>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();
  
  Stream<RecordingState> get recordingStateStream => _recordingStateController.stream;
  Stream<PlaybackState> get playbackStateStream => _playbackStateController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  int get recordingDuration => _recordingDuration;

  /// Check if we have microphone permission
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    if (_isRecording) {
      debugPrint('Already recording');
      return false;
    }
    
    // Check permission
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('Microphone permission denied');
        return false;
      }
    }
    
    try {
      // Create recording path
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      
      _currentRecordingPath = '${recordingsDir.path}/${_uuid.v4()}.m4a';
      
      // In production, use record package:
      // await _audioRecorder.start(
      //   RecordConfig(encoder: AudioEncoder.aacLc),
      //   path: _currentRecordingPath!,
      // );
      
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingDuration = 0;
      
      // Start duration timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
        _recordingStateController.add(RecordingState(
          isRecording: true,
          duration: _recordingDuration,
          path: _currentRecordingPath,
        ));
        
        // Simulate amplitude for waveform (in production, get real amplitude)
        _amplitudeController.add(_getSimulatedAmplitude());
      });
      
      _recordingStateController.add(RecordingState(
        isRecording: true,
        duration: 0,
        path: _currentRecordingPath,
      ));
      
      debugPrint('Started recording: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<RecordingResult?> stopRecording() async {
    if (!_isRecording) {
      debugPrint('Not recording');
      return null;
    }
    
    try {
      // In production, use record package:
      // final path = await _audioRecorder.stop();
      
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      // Calculate actual duration from start time
      final duration = _recordingStartTime != null 
          ? DateTime.now().difference(_recordingStartTime!).inSeconds 
          : _recordingDuration;
      final path = _currentRecordingPath;
      
      _isRecording = false;
      _recordingDuration = 0;
      _recordingStartTime = null;
      _currentRecordingPath = null;
      
      _recordingStateController.add(RecordingState(
        isRecording: false,
        duration: 0,
        path: null,
      ));
      
      debugPrint('Stopped recording: $path, duration: $duration seconds');
      
      if (path != null) {
        // Check if file exists (created by the actual recorder)
        final file = File(path);
        if (!await file.exists()) {
          debugPrint('Warning: Recording file not found at $path');
          return null;
        }
        
        return RecordingResult(
          path: path,
          duration: duration,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      _isRecording = false;
      _recordingTimer?.cancel();
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    
    _recordingTimer?.cancel();
    _recordingTimer = null;
    
    // Delete the partial recording file
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    _isRecording = false;
    _recordingDuration = 0;
    _recordingStartTime = null;
    _currentRecordingPath = null;
    
    _recordingStateController.add(RecordingState(
      isRecording: false,
      duration: 0,
      path: null,
    ));
    
    debugPrint('Recording cancelled');
  }

  /// Play an audio file
  Future<bool> playAudio(String path) async {
    if (_isPlaying) {
      await stopAudio();
    }
    
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('Audio file not found: $path');
        return false;
      }
      
      // In production, use audioplayers package:
      // await _audioPlayer.play(DeviceFileSource(path));
      
      _isPlaying = true;
      _currentPlayingPath = path;
      
      _playbackStateController.add(PlaybackState(
        isPlaying: true,
        path: path,
        position: Duration.zero,
        duration: const Duration(seconds: 10), // Placeholder
      ));
      
      debugPrint('Playing audio: $path');
      
      // Simulate playback ending after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (_currentPlayingPath == path) {
          _onPlaybackComplete();
        }
      });
      
      return true;
    } catch (e) {
      debugPrint('Failed to play audio: $e');
      return false;
    }
  }

  /// Pause audio playback
  Future<void> pauseAudio() async {
    if (!_isPlaying) return;
    
    // In production: await _audioPlayer.pause();
    
    _isPlaying = false;
    
    _playbackStateController.add(PlaybackState(
      isPlaying: false,
      path: _currentPlayingPath,
      position: const Duration(seconds: 2), // Placeholder
      duration: const Duration(seconds: 10),
    ));
    
    debugPrint('Audio paused');
  }

  /// Resume audio playback
  Future<void> resumeAudio() async {
    if (_isPlaying || _currentPlayingPath == null) return;
    
    // In production: await _audioPlayer.resume();
    
    _isPlaying = true;
    
    _playbackStateController.add(PlaybackState(
      isPlaying: true,
      path: _currentPlayingPath,
      position: const Duration(seconds: 2),
      duration: const Duration(seconds: 10),
    ));
    
    debugPrint('Audio resumed');
  }

  /// Stop audio playback
  Future<void> stopAudio() async {
    if (!_isPlaying && _currentPlayingPath == null) return;
    
    // In production: await _audioPlayer.stop();
    
    _isPlaying = false;
    _currentPlayingPath = null;
    
    _playbackStateController.add(PlaybackState(
      isPlaying: false,
      path: null,
      position: Duration.zero,
      duration: Duration.zero,
    ));
    
    debugPrint('Audio stopped');
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    if (_currentPlayingPath == null) return;
    
    // In production: await _audioPlayer.seek(position);
    
    _playbackStateController.add(PlaybackState(
      isPlaying: _isPlaying,
      path: _currentPlayingPath,
      position: position,
      duration: const Duration(seconds: 10),
    ));
    
    debugPrint('Seeking to: ${position.inSeconds}s');
  }

  /// Handle playback completion
  void _onPlaybackComplete() {
    _isPlaying = false;
    _currentPlayingPath = null;
    
    _playbackStateController.add(PlaybackState(
      isPlaying: false,
      path: null,
      position: Duration.zero,
      duration: Duration.zero,
    ));
    
    debugPrint('Playback complete');
  }

  /// Get simulated amplitude for waveform visualization
  double _getSimulatedAmplitude() {
    // In production, get real amplitude from recorder
    return 0.3 + (DateTime.now().millisecond % 100) / 100.0 * 0.7;
  }

  /// Format duration for display
  static String formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Delete an audio file
  Future<bool> deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted audio file: $path');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete audio file: $e');
      return false;
    }
  }

  /// Get the size of an audio file
  Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Dispose resources
  void dispose() {
    _recordingTimer?.cancel();
    _recordingStateController.close();
    _playbackStateController.close();
    _amplitudeController.close();
  }
}

/// Recording state for UI updates
class RecordingState {
  final bool isRecording;
  final int duration;
  final String? path;

  RecordingState({
    required this.isRecording,
    required this.duration,
    this.path,
  });
}

/// Playback state for UI updates
class PlaybackState {
  final bool isPlaying;
  final String? path;
  final Duration position;
  final Duration duration;

  PlaybackState({
    required this.isPlaying,
    this.path,
    required this.position,
    required this.duration,
  });

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }
}

/// Result of a recording session
class RecordingResult {
  final String path;
  final int duration;

  RecordingResult({
    required this.path,
    required this.duration,
  });
}

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Local crash logging service
/// Captures crashes that may not reach Firebase
/// Useful for analyzing silent/background crashes
class CrashLoggerService {
  static final CrashLoggerService _instance = CrashLoggerService._internal();
  static CrashLoggerService get instance => _instance;

  CrashLoggerService._internal();

  late Box<Map> _crashBox;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  bool _isInitialized = false;

  static const String _boxName = 'crash_logs';
  static const int _maxCrashes = 50; // Keep last 50 crashes

  Future<void> initialize() async {
    try {
      _crashBox = await Hive.openBox<Map>(_boxName);
      _isInitialized = true;
      debugPrint('✅ CrashLoggerService initialized');
    } catch (e) {
      debugPrint('❌ CrashLoggerService init failed: $e');
    }
  }

  /// Log a crash with context
  Future<void> logCrash({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    if (!_isInitialized) return;

    try {
      final timestamp = DateTime.now();
      final deviceInfo = await _getDeviceInfo();

      final crashLog = {
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'error': error?.toString() ?? 'Unknown',
        'stackTrace': stackTrace?.toString() ?? 'No stack trace',
        'context': context ?? {},
        'deviceInfo': deviceInfo,
      };

      // Add to crash box
      await _crashBox.add(crashLog);

      // Keep only last N crashes (prevent unbounded growth)
      if (_crashBox.length > _maxCrashes) {
        for (int i = 0; i < _crashBox.length - _maxCrashes; i++) {
          await _crashBox.deleteAt(i);
        }
      }

      debugPrint('💾 Crash logged: $message');
    } catch (e) {
      debugPrint('❌ Failed to log crash: $e');
    }
  }

  /// Get device info for diagnostic purposes
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'version':
              '${androidInfo.version.release} (API ${androidInfo.version.sdkInt})',
          'device': '${androidInfo.manufacturer} ${androidInfo.model}',
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'totalMemory': await _getTotalMemory(),
          'availableMemory': await _getAvailableMemory(),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'systemVersion': iosInfo.systemVersion,
          'model': iosInfo.model,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      }
      return {'platform': 'Unknown'};
    } catch (e) {
      return {'platform': 'Unknown', 'error': e.toString()};
    }
  }

  /// Get system memory info (Android)
  Future<String> _getTotalMemory() async {
    try {
      if (Platform.isAndroid) {
        final result = await Process.run('cat', ['/proc/meminfo']);
        final lines = result.stdout.toString().split('\n');
        final memTotal = lines.firstWhere(
          (line) => line.startsWith('MemTotal:'),
          orElse: () => 'MemTotal: unknown',
        );
        return memTotal;
      }
    } catch (e) {
      debugPrint('Could not read memory info: $e');
    }
    return 'Unknown';
  }

  /// Get available memory (Android)
  Future<String> _getAvailableMemory() async {
    try {
      if (Platform.isAndroid) {
        final result = await Process.run('cat', ['/proc/meminfo']);
        final lines = result.stdout.toString().split('\n');
        final memAvail = lines.firstWhere(
          (line) => line.startsWith('MemAvailable:'),
          orElse: () => 'MemAvailable: unknown',
        );
        return memAvail;
      }
    } catch (e) {
      debugPrint('Could not read available memory: $e');
    }
    return 'Unknown';
  }

  /// Get all logged crashes
  List<Map<String, dynamic>> getAllCrashes() {
    try {
      return _crashBox.values
          .toList()
          .cast<Map<String, dynamic>>()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('Error reading crashes: $e');
      return [];
    }
  }

  /// Get crash count
  int getCrashCount() {
    try {
      return _crashBox.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all crash logs
  Future<void> clearCrashes() async {
    try {
      await _crashBox.clear();
      debugPrint('✅ Crash logs cleared');
    } catch (e) {
      debugPrint('Error clearing crashes: $e');
    }
  }

  /// Export crashes as JSON (for debugging)
  Future<String> exportCrashesAsJson() async {
    try {
      final crashes = getAllCrashes();
      final json = {
        'timestamp': DateTime.now().toIso8601String(),
        'crashCount': crashes.length,
        'crashes': crashes,
      };
      return jsonEncode(json);
    } catch (e) {
      return '{"error": "$e"}';
    }
  }
}

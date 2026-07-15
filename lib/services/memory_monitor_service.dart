import 'dart:io';
import 'package:flutter/foundation.dart';

/// Memory monitoring service for Android devices
class MemoryMonitorService {
  static final MemoryMonitorService _instance =
      MemoryMonitorService._internal();
  static MemoryMonitorService get instance => _instance;
  MemoryMonitorService._internal();

  /// Get available memory in MB
  Future<int?> getAvailableMemoryMB() async {
    if (!Platform.isAndroid) return null;

    try {
      final result = await Process.run('cat', ['/proc/meminfo']);
      final lines = result.stdout.toString().split('\n');

      final availLine = lines.firstWhere(
        (line) => line.startsWith('MemAvailable:'),
        orElse: () => '',
      );

      if (availLine.isEmpty) return null;

      // Parse "MemAvailable:     975752 kB"
      final match = RegExp(r'(\d+)').firstMatch(availLine);
      if (match != null) {
        final kb = int.parse(match.group(1)!);
        return kb ~/ 1024; // Convert to MB
      }
    } catch (e) {
      debugPrint('Failed to get memory info: $e');
    }
    return null;
  }

  /// Get total memory in MB
  Future<int?> getTotalMemoryMB() async {
    if (!Platform.isAndroid) return null;

    try {
      final result = await Process.run('cat', ['/proc/meminfo']);
      final lines = result.stdout.toString().split('\n');

      final totalLine = lines.firstWhere(
        (line) => line.startsWith('MemTotal:'),
        orElse: () => '',
      );

      if (totalLine.isEmpty) return null;

      final match = RegExp(r'(\d+)').firstMatch(totalLine);
      if (match != null) {
        final kb = int.parse(match.group(1)!);
        return kb ~/ 1024;
      }
    } catch (e) {
      debugPrint('Failed to get total memory: $e');
    }
    return null;
  }

  /// Check if device has sufficient memory for model loading
  /// Returns true if available memory > minRequiredMB
  Future<bool> hasSufficientMemory({int minRequiredMB = 800}) async {
    final available = await getAvailableMemoryMB();
    if (available == null) {
      debugPrint('⚠️ Could not determine available memory');
      return true; // Assume OK if we can't check
    }

    debugPrint(
        '💾 Available memory: ${available}MB (required: ${minRequiredMB}MB)');
    return available >= minRequiredMB;
  }

  /// Get recommended context size based on available memory
  /// Low memory (< 1.5GB) → 512 context
  /// Medium memory (1.5-3GB) → 1024 context
  /// High memory (> 3GB) → 2048 context
  Future<int> getRecommendedContextSize() async {
    final available = await getAvailableMemoryMB();
    if (available == null) return 1024; // Default to safe value

    if (available < 1024) {
      debugPrint('🔻 Low memory detected: recommending context=512');
      return 512;
    } else if (available < 1536) {
      debugPrint('📊 Medium memory detected: recommending context=1024');
      return 1024;
    } else if (available < 3072) {
      debugPrint('📈 Good memory detected: recommending context=1536');
      return 1536;
    } else {
      debugPrint('🚀 High memory detected: recommending context=2048');
      return 2048;
    }
  }

  /// Get recommended thread count based on CPU cores
  Future<int> getRecommendedThreadCount() async {
    final available = await getAvailableMemoryMB();
    if (available == null) return 2;

    // Low memory devices should use fewer threads
    if (available < 1024) {
      return 2;
    } else if (available < 2048) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Force garbage collection (best effort)
  void forceGarbageCollection() {
    debugPrint('🗑️ Requesting garbage collection...');
    // Dart doesn't have direct GC control, but we can hint
    // The VM will decide when to actually collect
  }

  /// Get memory info for logging
  Future<Map<String, dynamic>> getMemoryInfo() async {
    final total = await getTotalMemoryMB();
    final available = await getAvailableMemoryMB();

    return {
      'totalMB': total ?? 'unknown',
      'availableMB': available ?? 'unknown',
      'usedMB':
          (total != null && available != null) ? total - available : 'unknown',
      'usagePercent': (total != null && available != null)
          ? ((total - available) / total * 100).toStringAsFixed(1)
          : 'unknown',
    };
  }
}

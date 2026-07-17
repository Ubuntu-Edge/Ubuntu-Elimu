import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service to handle app version migrations and cleanup
/// Ensures old bugs don't persist after app updates
class AppMigrationService {
  static const String _lastVersionKey = 'last_app_version';
  static const String _lastBuildNumberKey = 'last_build_number';
  
  /// Check if this is a new version and run necessary migrations
  static Future<void> checkAndMigrate() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    
    final currentVersion = packageInfo.version;
    final currentBuildNumber = int.parse(packageInfo.buildNumber);
    
    final lastVersion = prefs.getString(_lastVersionKey);
    final lastBuildNumber = prefs.getInt(_lastBuildNumberKey);
    
    debugPrint('🔄 App Migration Check:');
    debugPrint('  Current: v$currentVersion ($currentBuildNumber)');
    debugPrint('  Last: v$lastVersion ($lastBuildNumber)');
    
    // First install or version upgrade
    if (lastVersion == null || lastBuildNumber == null || currentBuildNumber > lastBuildNumber) {
      debugPrint('📦 New version detected - running migrations...');
      await _runMigrations(
        prefs: prefs,
        fromVersion: lastVersion,
        fromBuildNumber: lastBuildNumber,
        toVersion: currentVersion,
        toBuildNumber: currentBuildNumber,
      );
      
      // Update stored version
      await prefs.setString(_lastVersionKey, currentVersion);
      await prefs.setInt(_lastBuildNumberKey, currentBuildNumber);
      debugPrint('✅ Migration completed - version updated');
    } else {
      debugPrint('✅ Same version - no migration needed');
    }
  }
  
  /// Run version-specific migrations
  static Future<void> _runMigrations({
    required SharedPreferences prefs,
    required String? fromVersion,
    required int? fromBuildNumber,
    required String toVersion,
    required int toBuildNumber,
  }) async {
    // First install - no migration needed
    if (fromVersion == null) {
      debugPrint('  🆕 First install - skipping migrations');
      return;
    }
    
    // Version-specific aggressive cleanups for known problematic versions
    // Builds 1-3 had connectivity/mode switching bugs - clear all state except models
    if (fromBuildNumber != null && fromBuildNumber <= 3 && toBuildNumber >= 4) {
      debugPrint('  ⚠️ Upgrading from buggy build $fromBuildNumber to $toBuildNumber - aggressive cleanup');
      await _aggressiveCleanup(prefs);
      return;
    }
    
    // Clear problematic keys that might have old bugs
    await _clearProblematicKeys(prefs);
    
    // Version-specific migrations can be added here
    // Example: if (fromBuildNumber < 5) { ... }
  }
  
  /// Clear SharedPreferences keys that are known to cause issues
  static Future<void> _clearProblematicKeys(SharedPreferences prefs) async {
    debugPrint('  🧹 Clearing potentially problematic keys...');
    
    // List of keys that should be reset on upgrade to prevent old bugs
    final keysToPreserve = {
      // Keep user's data
      'offline_models',
      'active_offline_model_id',
      'offline_context_params',
      'chat_ai_mode',  // Preserve user's online/offline preference
      _lastVersionKey,
      _lastBuildNumberKey,
      
      // Keep authentication state
      'current_chw_id',
      'is_logged_in',
      
      // Keep model download states (but clear if causing issues)
      // 'active_downloads', // Uncomment to reset downloads on upgrade
    };
    
    // Get all keys
    final allKeys = prefs.getKeys();
    
    // Remove keys not in preserve list
    int clearedCount = 0;
    for (final key in allKeys) {
      if (!keysToPreserve.contains(key)) {
        await prefs.remove(key);
        clearedCount++;
        debugPrint('    🗑️ Cleared: $key');
      }
    }
    
    debugPrint('  ✅ Cleared $clearedCount old preference keys');
  }
  
  /// Aggressive cleanup for major version upgrades with known bugs
  /// Clears everything except models and auth to ensure fresh start
  static Future<void> _aggressiveCleanup(SharedPreferences prefs) async {
    debugPrint('  🧹 Running AGGRESSIVE cleanup...');
    
    // Only preserve absolute essentials
    final criticalKeys = {
      'offline_models',
      'active_offline_model_id',
      'offline_context_params',
      _lastVersionKey,
      _lastBuildNumberKey,
      'current_chw_id',
      'is_logged_in',
    };
    
    final allKeys = prefs.getKeys();
    int clearedCount = 0;
    
    for (final key in allKeys) {
      if (!criticalKeys.contains(key)) {
        await prefs.remove(key);
        clearedCount++;
        debugPrint('    🗑️ Aggressively cleared: $key');
      }
    }
    
    debugPrint('  ✅ Aggressive cleanup completed: $clearedCount keys removed');
    debugPrint('  💾 Preserved: models, auth state');
  }
  
  /// Force clear all app data (for debugging/troubleshooting)
  /// Preserves downloaded models but clears all other preferences
  static Future<void> clearAllAppData() async {
    debugPrint('⚠️ CLEARING APP DATA - Preserving downloaded models...');
    final prefs = await SharedPreferences.getInstance();
    
    // Preserve model-related data
    final modelsJson = prefs.getStringList('offline_models');
    final activeModelId = prefs.getString('active_offline_model_id');
    final contextParams = prefs.getString('offline_context_params');
    
    // Clear all preferences
    await prefs.clear();
    
    // Restore model data
    if (modelsJson != null) {
      await prefs.setStringList('offline_models', modelsJson);
      debugPrint('  💾 Preserved ${modelsJson.length} model records');
    }
    if (activeModelId != null) {
      await prefs.setString('active_offline_model_id', activeModelId);
      debugPrint('  💾 Preserved active model ID');
    }
    if (contextParams != null) {
      await prefs.setString('offline_context_params', contextParams);
      debugPrint('  💾 Preserved context params');
    }
    
    debugPrint('✅ App data cleared - models preserved');
  }
  
  /// Get current app version info
  static Future<String> getVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'v${packageInfo.version} (${packageInfo.buildNumber})';
  }
}

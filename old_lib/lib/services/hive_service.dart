import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive service for fast key-value caching
/// Used for session data, preferences, and frequently accessed data
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Box names
  static const String _sessionBox = 'session';
  static const String _cacheBox = 'cache';
  static const String _preferencesBox = 'preferences';
  static const String _offlineDataBox = 'offline_data';
  static const String _medicalLibraryBox = 'medical_library';

  bool _isInitialized = false;

  /// Initialize Hive
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox(_sessionBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_preferencesBox);
    await Hive.openBox(_offlineDataBox);
    await Hive.openBox(_medicalLibraryBox);

    _isInitialized = true;
    debugPrint('HiveService initialized');
  }

  // ==================== Session Management ====================

  /// Store authentication token
  Future<void> setAuthToken(String token) async {
    final box = Hive.box(_sessionBox);
    await box.put('auth_token', token);
  }

  /// Get authentication token
  String? getAuthToken() {
    final box = Hive.box(_sessionBox);
    return box.get('auth_token');
  }

  /// Store refresh token
  Future<void> setRefreshToken(String token) async {
    final box = Hive.box(_sessionBox);
    await box.put('refresh_token', token);
  }

  /// Get refresh token
  String? getRefreshToken() {
    final box = Hive.box(_sessionBox);
    return box.get('refresh_token');
  }

  /// Store current user data
  Future<void> setCurrentUser(Map<String, dynamic> userData) async {
    final box = Hive.box(_sessionBox);
    await box.put('current_user', jsonEncode(userData));
  }

  /// Get current user data
  Map<String, dynamic>? getCurrentUser() {
    final box = Hive.box(_sessionBox);
    final data = box.get('current_user');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  /// Store session expiry time
  Future<void> setSessionExpiry(DateTime expiry) async {
    final box = Hive.box(_sessionBox);
    await box.put('session_expiry', expiry.toIso8601String());
  }

  /// Get session expiry time
  DateTime? getSessionExpiry() {
    final box = Hive.box(_sessionBox);
    final data = box.get('session_expiry');
    if (data != null) {
      return DateTime.parse(data);
    }
    return null;
  }

  /// Check if session is valid
  bool isSessionValid() {
    final token = getAuthToken();
    final expiry = getSessionExpiry();
    
    if (token == null || expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  /// Clear session data (logout)
  Future<void> clearSession() async {
    final box = Hive.box(_sessionBox);
    await box.clear();
  }

  // ==================== Cache Management ====================

  /// Cache data with optional TTL (time-to-live)
  Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? ttl,
  }) async {
    final box = Hive.box(_cacheBox);
    final cacheEntry = {
      'data': data is String ? data : jsonEncode(data),
      'cached_at': DateTime.now().toIso8601String(),
      'expires_at': ttl != null 
          ? DateTime.now().add(ttl).toIso8601String()
          : null,
    };
    await box.put(key, jsonEncode(cacheEntry));
  }

  /// Get cached data
  T? getCachedData<T>(String key) {
    final box = Hive.box(_cacheBox);
    final rawData = box.get(key);
    
    if (rawData == null) return null;
    
    try {
      final cacheEntry = jsonDecode(rawData);
      
      // Check if expired
      if (cacheEntry['expires_at'] != null) {
        final expiresAt = DateTime.parse(cacheEntry['expires_at']);
        if (DateTime.now().isAfter(expiresAt)) {
          // Remove expired data
          box.delete(key);
          return null;
        }
      }
      
      final data = cacheEntry['data'];
      if (T == String) {
        return data as T;
      } else if (T == Map<String, dynamic>) {
        return (data is String ? jsonDecode(data) : data) as T;
      } else if (T == List<dynamic>) {
        return (data is String ? jsonDecode(data) : data) as T;
      }
      
      return data as T?;
    } catch (e) {
      debugPrint('Error getting cached data: $e');
      return null;
    }
  }

  /// Check if cache exists and is valid
  bool isCacheValid(String key) {
    final box = Hive.box(_cacheBox);
    final rawData = box.get(key);
    
    if (rawData == null) return false;
    
    try {
      final cacheEntry = jsonDecode(rawData);
      
      if (cacheEntry['expires_at'] != null) {
        final expiresAt = DateTime.parse(cacheEntry['expires_at']);
        return DateTime.now().isBefore(expiresAt);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove cached item
  Future<void> removeCachedItem(String key) async {
    final box = Hive.box(_cacheBox);
    await box.delete(key);
  }

  /// Clear all cache
  Future<void> clearCache() async {
    final box = Hive.box(_cacheBox);
    await box.clear();
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    final box = Hive.box(_cacheBox);
    final keysToRemove = <String>[];
    
    for (final key in box.keys) {
      final rawData = box.get(key);
      if (rawData != null) {
        try {
          final cacheEntry = jsonDecode(rawData);
          if (cacheEntry['expires_at'] != null) {
            final expiresAt = DateTime.parse(cacheEntry['expires_at']);
            if (DateTime.now().isAfter(expiresAt)) {
              keysToRemove.add(key.toString());
            }
          }
        } catch (e) {
          keysToRemove.add(key.toString());
        }
      }
    }
    
    for (final key in keysToRemove) {
      await box.delete(key);
    }
    
    debugPrint('Cleared ${keysToRemove.length} expired cache entries');
  }

  // ==================== Preferences ====================

  /// Set a preference value
  Future<void> setPreference<T>(String key, T value) async {
    final box = Hive.box(_preferencesBox);
    await box.put(key, value);
  }

  /// Get a preference value
  T? getPreference<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_preferencesBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  /// Common preferences
  Future<void> setLanguage(String languageCode) async {
    await setPreference('language', languageCode);
  }

  String getLanguage() {
    return getPreference<String>('language', defaultValue: 'en') ?? 'en';
  }

  Future<void> setThemeMode(String mode) async {
    await setPreference('theme_mode', mode);
  }

  String getThemeMode() {
    return getPreference<String>('theme_mode', defaultValue: 'system') ?? 'system';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await setPreference('notifications_enabled', enabled);
  }

  bool getNotificationsEnabled() {
    return getPreference<bool>('notifications_enabled', defaultValue: true) ?? true;
  }

  Future<void> setOfflineModeEnabled(bool enabled) async {
    await setPreference('offline_mode_enabled', enabled);
  }

  bool getOfflineModeEnabled() {
    return getPreference<bool>('offline_mode_enabled', defaultValue: true) ?? true;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await setPreference('last_sync_time', time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeStr = getPreference<String>('last_sync_time');
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  // ==================== Offline Data ====================

  /// Store offline action for later sync
  Future<void> storeOfflineAction(Map<String, dynamic> action) async {
    final box = Hive.box(_offlineDataBox);
    final actions = getOfflineActions();
    actions.add({
      ...action,
      'queued_at': DateTime.now().toIso8601String(),
    });
    await box.put('offline_actions', jsonEncode(actions));
  }

  /// Get all pending offline actions
  List<Map<String, dynamic>> getOfflineActions() {
    final box = Hive.box(_offlineDataBox);
    final rawData = box.get('offline_actions');
    
    if (rawData == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(rawData);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Remove synced offline action
  Future<void> removeOfflineAction(int index) async {
    final box = Hive.box(_offlineDataBox);
    final actions = getOfflineActions();
    
    if (index >= 0 && index < actions.length) {
      actions.removeAt(index);
      await box.put('offline_actions', jsonEncode(actions));
    }
  }

  /// Clear all synced offline actions
  Future<void> clearOfflineActions() async {
    final box = Hive.box(_offlineDataBox);
    await box.delete('offline_actions');
  }

  /// Get pending offline actions count
  int getPendingActionsCount() {
    return getOfflineActions().length;
  }

  // ==================== Medical Library Cache ====================

  /// Cache diseases data
  Future<void> cacheDiseases(List<Map<String, dynamic>> diseases) async {
    final box = Hive.box(_medicalLibraryBox);
    await box.put('diseases', jsonEncode(diseases));
    await box.put('diseases_cached_at', DateTime.now().toIso8601String());
  }

  /// Get cached diseases
  List<Map<String, dynamic>>? getCachedDiseases() {
    final box = Hive.box(_medicalLibraryBox);
    final rawData = box.get('diseases');
    
    if (rawData == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(rawData);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Cache medications data
  Future<void> cacheMedications(List<Map<String, dynamic>> medications) async {
    final box = Hive.box(_medicalLibraryBox);
    await box.put('medications', jsonEncode(medications));
    await box.put('medications_cached_at', DateTime.now().toIso8601String());
  }

  /// Get cached medications
  List<Map<String, dynamic>>? getCachedMedications() {
    final box = Hive.box(_medicalLibraryBox);
    final rawData = box.get('medications');
    
    if (rawData == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(rawData);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Cache clinical guidelines
  Future<void> cacheGuidelines(List<Map<String, dynamic>> guidelines) async {
    final box = Hive.box(_medicalLibraryBox);
    await box.put('guidelines', jsonEncode(guidelines));
    await box.put('guidelines_cached_at', DateTime.now().toIso8601String());
  }

  /// Get cached guidelines
  List<Map<String, dynamic>>? getCachedGuidelines() {
    final box = Hive.box(_medicalLibraryBox);
    final rawData = box.get('guidelines');
    
    if (rawData == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(rawData);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Cache emergency procedures
  Future<void> cacheEmergencyProcedures(List<Map<String, dynamic>> procedures) async {
    final box = Hive.box(_medicalLibraryBox);
    await box.put('emergency_procedures', jsonEncode(procedures));
    await box.put('emergency_procedures_cached_at', DateTime.now().toIso8601String());
  }

  /// Get cached emergency procedures
  List<Map<String, dynamic>>? getCachedEmergencyProcedures() {
    final box = Hive.box(_medicalLibraryBox);
    final rawData = box.get('emergency_procedures');
    
    if (rawData == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(rawData);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // ==================== Utilities ====================

  /// Get storage statistics
  Future<Map<String, int>> getStorageStats() async {
    return {
      'session_entries': Hive.box(_sessionBox).length,
      'cache_entries': Hive.box(_cacheBox).length,
      'preference_entries': Hive.box(_preferencesBox).length,
      'offline_actions': getPendingActionsCount(),
      'medical_library_entries': Hive.box(_medicalLibraryBox).length,
    };
  }

  /// Clear all Hive data (for complete reset)
  Future<void> clearAll() async {
    await Hive.box(_sessionBox).clear();
    await Hive.box(_cacheBox).clear();
    await Hive.box(_preferencesBox).clear();
    await Hive.box(_offlineDataBox).clear();
    await Hive.box(_medicalLibraryBox).clear();
    debugPrint('All Hive data cleared');
  }

  /// Compact all boxes to reclaim space
  Future<void> compactBoxes() async {
    await Hive.box(_sessionBox).compact();
    await Hive.box(_cacheBox).compact();
    await Hive.box(_preferencesBox).compact();
    await Hive.box(_offlineDataBox).compact();
    await Hive.box(_medicalLibraryBox).compact();
    debugPrint('All Hive boxes compacted');
  }

  /// Close all boxes (call on app termination)
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
    debugPrint('HiveService closed');
  }
}

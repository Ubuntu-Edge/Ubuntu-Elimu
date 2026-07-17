import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// SecurityService handles encryption, secure storage, and authentication security
class SecurityService {
  static final SecurityService instance = SecurityService._init();
  
  SecurityService._init();
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  static const String _encryptionKeyKey = 'app_encryption_key';
  static const String _pinAttemptsKey = 'pin_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const int _maxPinAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  String? _cachedEncryptionKey;
  
  /// Initialize security service
  Future<void> initialize() async {
    await _ensureEncryptionKey();
    debugPrint('🔐 SecurityService initialized');
  }
  
  /// Ensure encryption key exists or create one
  Future<void> _ensureEncryptionKey() async {
    _cachedEncryptionKey = await _secureStorage.read(key: _encryptionKeyKey);
    if (_cachedEncryptionKey == null) {
      _cachedEncryptionKey = _generateSecureKey(32);
      await _secureStorage.write(key: _encryptionKeyKey, value: _cachedEncryptionKey);
    }
  }
  
  /// Generate a secure random key
  String _generateSecureKey(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Encode(values);
  }
  
  /// Hash a PIN securely using SHA-256
  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Hash a PIN with salt for enhanced security
  String hashPinWithSalt(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Generate a unique salt for PIN hashing
  String generateSalt() {
    return _generateSecureKey(16);
  }
  
  /// Verify a PIN against its hash
  bool verifyPin(String pin, String hash, {String? salt}) {
    final computedHash = salt != null ? hashPinWithSalt(pin, salt) : hashPin(pin);
    return computedHash == hash;
  }
  
  /// Store sensitive data securely
  Future<void> storeSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  /// Retrieve sensitive data
  Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  /// Delete sensitive data
  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  /// Delete all secure data (used on logout or account deletion)
  Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
    _cachedEncryptionKey = null;
    await _ensureEncryptionKey();
  }
  
  /// Encrypt sensitive text data
  String encryptData(String plainText) {
    if (_cachedEncryptionKey == null) return plainText;
    
    try {
      final key = utf8.encode(_cachedEncryptionKey!);
      final plainBytes = utf8.encode(plainText);
      
      // XOR-based encryption (for basic protection)
      // In production, use proper AES encryption
      final encrypted = List<int>.generate(
        plainBytes.length,
        (i) => plainBytes[i] ^ key[i % key.length],
      );
      
      return base64Encode(Uint8List.fromList(encrypted));
    } catch (e) {
      debugPrint('⚠️ Encryption failed: $e');
      return plainText;
    }
  }
  
  /// Decrypt encrypted text data
  String decryptData(String encryptedText) {
    if (_cachedEncryptionKey == null) return encryptedText;
    
    try {
      final key = utf8.encode(_cachedEncryptionKey!);
      final encryptedBytes = base64Decode(encryptedText);
      
      // XOR decryption (reverse of encryption)
      final decrypted = List<int>.generate(
        encryptedBytes.length,
        (i) => encryptedBytes[i] ^ key[i % key.length],
      );
      
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('⚠️ Decryption failed: $e');
      return encryptedText;
    }
  }
  
  /// Check if account is locked due to failed attempts
  Future<bool> isAccountLocked() async {
    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) return false;
    
    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final unlockTime = lockoutTime.add(_lockoutDuration);
    
    if (DateTime.now().isAfter(unlockTime)) {
      // Lockout period has passed, reset
      await _resetLoginAttempts();
      return false;
    }
    
    return true;
  }
  
  /// Get remaining lockout time in seconds
  Future<int> getRemainingLockoutSeconds() async {
    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) return 0;
    
    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final unlockTime = lockoutTime.add(_lockoutDuration);
    final remaining = unlockTime.difference(DateTime.now());
    
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }
  
  /// Record a failed login attempt
  Future<int> recordFailedAttempt() async {
    final attemptsStr = await _secureStorage.read(key: _pinAttemptsKey);
    int attempts = (attemptsStr != null) ? int.parse(attemptsStr) + 1 : 1;
    
    await _secureStorage.write(key: _pinAttemptsKey, value: attempts.toString());
    
    if (attempts >= _maxPinAttempts) {
      await _secureStorage.write(
        key: _lockoutTimeKey,
        value: DateTime.now().toIso8601String(),
      );
    }
    
    return _maxPinAttempts - attempts;
  }
  
  /// Reset login attempts after successful login
  Future<void> _resetLoginAttempts() async {
    await _secureStorage.delete(key: _pinAttemptsKey);
    await _secureStorage.delete(key: _lockoutTimeKey);
  }
  
  /// Called on successful login
  Future<void> onSuccessfulLogin() async {
    await _resetLoginAttempts();
  }
  
  /// Get number of remaining login attempts
  Future<int> getRemainingAttempts() async {
    final attemptsStr = await _secureStorage.read(key: _pinAttemptsKey);
    final attempts = (attemptsStr != null) ? int.parse(attemptsStr) : 0;
    return _maxPinAttempts - attempts;
  }
  
  /// Validate PIN format (4 digits)
  bool isValidPinFormat(String pin) {
    return RegExp(r'^\d{4}$').hasMatch(pin);
  }
  
  /// Validate phone number format
  bool isValidPhoneFormat(String phone) {
    // Accepts formats: +254XXXXXXXXX, 0XXXXXXXXX, 07XXXXXXXX
    return RegExp(r'^(\+?254|0)?[17]\d{8}$').hasMatch(phone.replaceAll(' ', ''));
  }
  
  /// Sanitize user input to prevent injection
  String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"' "'" r']'), '')
        .trim();
  }
  
  /// Generate a session token
  String generateSessionToken() {
    return _generateSecureKey(32);
  }
  
  /// Store session token securely
  Future<void> storeSessionToken(String userId, String token) async {
    await _secureStorage.write(key: 'session_$userId', value: token);
    await _secureStorage.write(
      key: 'session_${userId}_time',
      value: DateTime.now().toIso8601String(),
    );
  }
  
  /// Validate session token
  Future<bool> validateSessionToken(String userId, String token) async {
    final storedToken = await _secureStorage.read(key: 'session_$userId');
    final sessionTimeStr = await _secureStorage.read(key: 'session_${userId}_time');
    
    if (storedToken == null || sessionTimeStr == null) return false;
    if (storedToken != token) return false;
    
    // Check session expiry (24 hours)
    final sessionTime = DateTime.parse(sessionTimeStr);
    if (DateTime.now().difference(sessionTime).inHours > 24) {
      await invalidateSession(userId);
      return false;
    }
    
    return true;
  }
  
  /// Invalidate session
  Future<void> invalidateSession(String userId) async {
    await _secureStorage.delete(key: 'session_$userId');
    await _secureStorage.delete(key: 'session_${userId}_time');
  }
}

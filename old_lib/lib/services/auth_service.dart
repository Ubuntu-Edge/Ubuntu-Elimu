// Corrected import path for FlutterSecureStorage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../models/chw.dart';
import '../models/auth_models.dart';
import 'database_service.dart';
import 'auth_api_service.dart';
import 'auth_validation.dart';
import 'connectivity_service.dart';
import 'package:uuid/uuid.dart';

/// Service class dedicated to handling CHW authentication, registration,
/// and secure storage of session tokens. Implements offline-first architecture
/// with backend synchronization when online.
class AuthService {
  // Singleton pattern for easy access
  static final AuthService instance = AuthService._init();

  // Initialize secure storage and database instances
  final _storage = const FlutterSecureStorage();
  final _db = DatabaseService.instance;
  final _api = AuthApiService.instance;
  final _connectivity = ConnectivityService.instance;

  // Keys for secure storage
  static const String _keyCurrentCHWId = 'current_chw_id';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTokenExpiry = 'token_expiry';

  // Private constructor
  AuthService._init();

  /// Hash a PIN or password for secure local storage
  String _hashCredential(String credential) {
    final bytes = utf8.encode(credential);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get device information for API requests
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      // Simple device ID - in production, use device_info_plus package
      return {
        'device_id': const Uuid().v4(),
      };
    } catch (e) {
      return {
        'device_id': 'unknown',
      };
    }
  }

  /// Check if online
  bool get isOnline => _connectivity.isOnline;

  // ========== REGISTRATION ==========

  /// Registers a new Community Health Worker with backend sync when online.
  /// Falls back to offline-only registration when no network.
  Future<CHW?> registerCHW({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String pin,
    String? password,
    String? email,
    String? village,
    String? healthFacility,
    String? region,
  }) async {
    try {
      // Format phone number to E.164
      final formattedPhone = AuthValidation.formatPhoneNumber(phoneNumber);
      final formattedFirstName = AuthValidation.formatName(firstName);
      final formattedLastName = AuthValidation.formatName(lastName);

      // 1. Check if phone number already exists locally
      final existing = await _db.getCHWByPhone(formattedPhone);
      if (existing != null) {
        throw Exception('Phone number already registered');
      }

      // 2. Validate PIN
      final pinError = AuthValidation.validatePin(pin);
      if (pinError != null) {
        throw Exception(pinError);
      }

      // 3. Validate password if provided
      if (password != null && password.isNotEmpty) {
        final passwordError = AuthValidation.validatePassword(password);
        if (passwordError != null) {
          throw Exception(passwordError);
        }
      }

      // 4. OFFLINE-FIRST: Create local account immediately
      log('Creating local registration for: $formattedPhone', name: 'AuthService');
      
      final chw = CHW(
        id: const Uuid().v4(),
        firstName: formattedFirstName,
        lastName: formattedLastName,
        phoneNumber: formattedPhone,
        email: email,
        pin: _hashCredential(pin), // Store hashed PIN
        village: village,
        healthFacility: healthFacility,
        region: region,
        registeredDate: DateTime.now(),
        isActive: true,
        role: 'chw',
        isSynced: false,
        pendingSync: true,
      );

      // 5. Save to local database immediately
      await _db.createCHW(chw);

      // 6. Auto-login
      await _saveCurrentCHW(chw.id);

      // 7. Add to sync queue for later backend sync
      await _db.addToAuthSyncQueue(
        operation: 'register',
        userId: chw.id,
        data: jsonEncode({
          'first_name': formattedFirstName,
          'last_name': formattedLastName,
          'phone_number': formattedPhone,
          'pin': pin, // Original PIN for sync
          'password': password,
          'email': email,
          'village': village,
          'health_facility': healthFacility,
          'region': region,
        }),
      );

      // 8. Try to sync with backend in background (non-blocking)
      if (isOnline) {
        _syncRegistrationInBackground(chw.id, formattedPhone, pin, password, email, 
          formattedFirstName, formattedLastName, village, healthFacility, region);
      }

      return chw;
    } catch (e) {
      log('Error registering CHW: $e', name: 'AuthService');
      rethrow;
    }
  }

  // ========== LOGIN ==========

  /// Login with phone and PIN. Offline-first - always validates locally.
  Future<CHW?> login(String phoneNumber, String pin, {bool rememberMe = false}) async {
    try {
      final formattedPhone = AuthValidation.formatPhoneNumber(phoneNumber);
      log('Login attempt for: $formattedPhone (offline-first)', name: 'AuthService');

      // 1. OFFLINE-FIRST: Validate credentials locally
      final chw = await _offlineLogin(formattedPhone, pin);
      
      if (chw == null) {
        log('Invalid credentials - no local user found', name: 'AuthService');
        return null;
      }

      log('✅ Login successful (local): ${chw.id}', name: 'AuthService');

      // 2. Save session
      await _saveCurrentCHW(chw.id);

      // 3. Handle remember me
      if (rememberMe) {
        await _storage.write(key: _keyRememberMe, value: 'true');
      } else {
        await _storage.delete(key: _keyRememberMe);
      }

      // 4. Try to sync with backend in background (non-blocking)
      if (isOnline) {
        _syncLoginInBackground(formattedPhone, pin, chw);
      }

      return chw;
    } catch (e) {
      log('Error logging in: $e', name: 'AuthService');
      rethrow;
    }
  }

  /// Offline login using locally stored credentials
  Future<CHW?> _offlineLogin(String phoneNumber, String pin) async {
    final hashedPin = _hashCredential(pin);
    
    // Try to find user by phone and hashed PIN
    final db = await _db.database;
    final maps = await db.query(
      'chws',
      where: 'phone_number = ? AND pin = ? AND is_active = 1',
      whereArgs: [phoneNumber, hashedPin],
    );

    if (maps.isNotEmpty) {
      return CHW.fromMap(maps.first);
    }

    // Legacy support: try with plain PIN (for users created before hashing)
    final legacyMaps = await db.query(
      'chws',
      where: 'phone_number = ? AND pin = ? AND is_active = 1',
      whereArgs: [phoneNumber, pin],
    );

    if (legacyMaps.isNotEmpty) {
      // Upgrade to hashed PIN
      final chw = CHW.fromMap(legacyMaps.first);
      await db.update(
        'chws',
        {'pin': hashedPin},
        where: 'id = ?',
        whereArgs: [chw.id],
      );
      return chw;
    }

    return null;
  }

  // ========== TOKEN MANAGEMENT ==========

  /// Save tokens to secure storage and database
  Future<void> _saveTokens(
    String userId,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiry,
  ) async {
    // Save to secure storage for quick access
    if (accessToken != null) {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      log('Saved access token for user $userId: ${accessToken.substring(0, 20)}...', name: 'AuthService');
    }
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
      log('Saved refresh token for user $userId', name: 'AuthService');
    }
    if (tokenExpiry != null) {
      await _storage.write(key: _keyTokenExpiry, value: tokenExpiry.toIso8601String());
      log('Token expiry set to: $tokenExpiry', name: 'AuthService');
    }

    // Also save to database for persistence
    await _db.saveAuthTokens(
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiry: tokenExpiry,
    );
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _keyAccessToken);
    if (token != null) {
      log('Retrieved access token: ${token.substring(0, 20)}...', name: 'AuthService');
      // Check if token is expired
      final expired = await isTokenExpired();
      if (expired) {
        log('WARNING: Access token is expired', name: 'AuthService');
      }
    } else {
      log('WARNING: No access token found in storage', name: 'AuthService');
    }
    return token;
  }

  /// Get a valid access token, refreshing if necessary
  /// Returns null if no valid token is available and refresh fails
  Future<String?> getValidAccessToken() async {
    // Check if token is expired
    final expired = await isTokenExpired();
    
    if (expired && isOnline) {
      log('Token expired, attempting refresh...', name: 'AuthService');
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        log('Token refresh failed', name: 'AuthService');
        return null;
      }
    }
    
    return await getAccessToken();
  }

  /// Get authorization headers with valid JWT token
  /// This is the recommended method for all API services to use
  /// Handles token refresh automatically when online
  /// Throws AuthException if no valid token is available
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getValidAccessToken();
    
    if (token == null || token.isEmpty) {
      log('ERROR: No valid auth token available for API request', name: 'AuthService');
      throw AuthException('No valid authentication token available. Please login again.');
    }
    
    log('Providing auth headers with token: ${token.substring(0, 20)}...', name: 'AuthService');
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Check if user has valid authentication (token exists and not expired, or offline with local credentials)
  Future<bool> hasValidAuth() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    
    // If online, check if token is expired
    if (isOnline) {
      final expired = await isTokenExpired();
      if (expired) {
        // Try to refresh
        return await refreshAccessToken();
      }
    }
    
    return true;
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiryStr = await _storage.read(key: _keyTokenExpiry);
    if (expiryStr == null) return true;

    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return true;

    return DateTime.now().isAfter(expiry);
  }

  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    if (!isOnline) {
      log('Cannot refresh token - offline', name: 'AuthService');
      return false;
    }

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        log('Cannot refresh token - no refresh token available', name: 'AuthService');
        return false;
      }

      log('Attempting to refresh token...', name: 'AuthService');
      final response = await _api.refreshToken(refreshToken);
      final currentId = await _storage.read(key: _keyCurrentCHWId);

      if (currentId != null) {
        final expiry = DateTime.now().add(Duration(seconds: response.expiresIn));
        await _saveTokens(currentId, response.accessToken, response.refreshToken, expiry);
        log('Token successfully refreshed', name: 'AuthService');
      }

      return true;
    } catch (e) {
      log('Token refresh failed: $e', name: 'AuthService');
      return false;
    }
  }

  // ========== SESSION MANAGEMENT ==========

  /// Get current logged-in CHW
  Future<CHW?> getCurrentCHW() async {
    try {
      final chwId = await _storage.read(key: _keyCurrentCHWId);
      if (chwId != null) {
        return await _db.getCHWById(chwId);
      }
      return null;
    } catch (e) {
      log('Error getting current CHW: $e', name: 'AuthService');
      return null;
    }
  }

  /// Check if user should stay logged in
  Future<bool> shouldRememberUser() async {
    final rememberMe = await _storage.read(key: _keyRememberMe);
    return rememberMe == 'true';
  }

  /// Logout - clears all session data
  Future<void> logout() async {
    try {
      // Try to logout from backend
      final accessToken = await getAccessToken();
      if (accessToken != null && isOnline) {
        try {
          await _api.logout(accessToken);
        } catch (e) {
          log('Backend logout failed (non-critical): $e', name: 'AuthService');
        }
      }

      // Clear local session
      final currentId = await _storage.read(key: _keyCurrentCHWId);
      if (currentId != null) {
        await _db.deleteAuthTokens(currentId);
      }

      await _storage.delete(key: _keyCurrentCHWId);
      await _storage.delete(key: _keyRememberMe);
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyTokenExpiry);
    } catch (e) {
      log('Logout error: $e', name: 'AuthService');
    }
  }

  /// Save current CHW ID
  Future<void> _saveCurrentCHW(String chwId) async {
    await _storage.write(key: _keyCurrentCHWId, value: chwId);
  }

  /// Check if CHW is logged in
  Future<bool> isLoggedIn() async {
    final chwId = await _storage.read(key: _keyCurrentCHWId);
    return chwId != null;
  }

  /// Get CHW by ID
  Future<CHW?> getCHWById(String id) async {
    try {
      return await _db.getCHWById(id);
    } catch (e) {
      log('Error getting CHW by ID: $e', name: 'AuthService');
      return null;
    }
  }

  // ========== PASSWORD & PIN MANAGEMENT ==========

  /// Change password (requires online) - uses sync endpoint
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (!isOnline) {
      throw Exception('Password change requires internet connection');
    }

    // Validate new password
    final passwordError = AuthValidation.validatePassword(newPassword);
    if (passwordError != null) {
      throw Exception(passwordError);
    }

    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      final currentCHW = await getCurrentCHW();
      if (currentCHW == null) {
        throw Exception('Not authenticated');
      }

      // Get device info for sync
      final deviceInfo = await _getDeviceInfo();

      // Use sync endpoint to change password with timestamp tracking
      final syncRequest = UserProfileSyncRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
        deviceId: deviceInfo['device_id'],
        lastUpdatedAt: DateTime.now(),
      );

      log('Syncing password change: ${syncRequest.toJson()}', name: 'AuthService');

      final syncResponse = await _api.syncUserProfile(accessToken, syncRequest);

      if (syncResponse.success) {
        // Update local database with new timestamp
        final db = await _db.database;
        await db.update(
          'chws',
          {
            'updated_at': syncResponse.syncTimestamp.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [currentCHW.id],
        );

        log('Password changed and synced. Fields updated: ${syncResponse.fieldsUpdated.join(", ")}',
            name: 'AuthService');

        if (syncResponse.conflicts.isNotEmpty) {
          log('Sync conflicts detected: ${syncResponse.conflicts.length}',
              name: 'AuthService');
        }

        return true;
      }

      return false;
    } catch (e) {
      log('Change password error: $e', name: 'AuthService');
      rethrow;
    }
  }

  /// Change PIN - uses sync endpoint when online
  Future<bool> changePin(String currentPin, String newPin) async {
    // Validate new PIN
    final pinError = AuthValidation.validatePin(newPin);
    if (pinError != null) {
      throw Exception(pinError);
    }

    try {
      final currentCHW = await getCurrentCHW();
      if (currentCHW == null) {
        throw Exception('Not authenticated');
      }

      // Verify current PIN locally
      final hashedCurrentPin = _hashCredential(currentPin);
      if (currentCHW.pin != hashedCurrentPin && currentCHW.pin != currentPin) {
        throw Exception('Current PIN is incorrect');
      }

      // Try online PIN change using sync endpoint
      if (isOnline) {
        try {
          final accessToken = await getAccessToken();
          if (accessToken != null) {
            // Get device info for sync
            final deviceInfo = await _getDeviceInfo();
            
            // Use sync endpoint to change PIN with timestamp tracking
            final syncRequest = UserProfileSyncRequest(
              currentPin: currentPin,
              newPin: newPin,
              deviceId: deviceInfo['device_id'],
              lastUpdatedAt: DateTime.now(),
            );

            log('Syncing PIN change: ${syncRequest.toJson()}', name: 'AuthService');

            final syncResponse = await _api.syncUserProfile(accessToken, syncRequest);

            if (syncResponse.success) {
              // Update local PIN with hashed value
              final hashedNewPin = _hashCredential(newPin);
              final db = await _db.database;
              await db.update(
                'chws',
                {
                  'pin': hashedNewPin,
                  'updated_at': syncResponse.syncTimestamp.toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [currentCHW.id],
              );

              log('PIN changed and synced. Fields updated: ${syncResponse.fieldsUpdated.join(", ")}',
                  name: 'AuthService');

              if (syncResponse.conflicts.isNotEmpty) {
                log('Sync conflicts detected: ${syncResponse.conflicts.length}',
                    name: 'AuthService');
              }

              return true;
            }
          }
        } on AuthApiException catch (e) {
          if (!e.isNetworkError) {
            rethrow;
          }
          // For network errors, continue with local change
        }
      }

      // Update local PIN
      final hashedNewPin = _hashCredential(newPin);
      final db = await _db.database;
      await db.update(
        'chws',
        {'pin': hashedNewPin},
        where: 'id = ?',
        whereArgs: [currentCHW.id],
      );

      return true;
    } catch (e) {
      log('Change PIN error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // ========== SYNC OPERATIONS ==========

  /// Pull user profile from server to check for updates
  /// Use this before pushing local changes to detect conflicts
  Future<UserResponse?> pullUserProfile() async {
    if (!isOnline) return null;

    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        log('No access token available for profile pull', name: 'AuthService');
        return null;
      }

      final userProfile = await _api.getUserProfile(accessToken);
      
      // Update local database with server data
      final currentCHW = await getCurrentCHW();
      if (currentCHW != null) {
        final db = await _db.database;
        await db.update(
          'chws',
          {
            'first_name': userProfile.firstName,
            'last_name': userProfile.lastName,
            'phone_number': userProfile.phoneNumber,
            'email': userProfile.email,
            'village': userProfile.village,
            'health_facility': userProfile.healthFacility,
            'region': userProfile.region,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [currentCHW.id],
        );

        log('User profile pulled and updated from server', name: 'AuthService');
      }

      return userProfile;
    } on AuthApiException catch (e) {
      log('Failed to pull user profile: ${e.message}', name: 'AuthService');
      return null;
    } catch (e) {
      log('Error pulling user profile: $e', name: 'AuthService');
      return null;
    }
  }

  /// Sync user profile with server (push local changes)
  Future<UserProfileSyncResponse?> pushUserProfile({
    String? email,
    String? firstName,
    String? lastName,
    String? village,
    String? healthFacility,
    String? region,
    String? fcmToken,
  }) async {
    if (!isOnline) {
      log('Cannot push profile changes - offline', name: 'AuthService');
      return null;
    }

    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      final currentCHW = await getCurrentCHW();
      if (currentCHW == null) {
        throw Exception('Not authenticated');
      }

      // Build sync request with changes
      final syncRequest = UserProfileSyncRequest(
        email: email,
        firstName: firstName,
        lastName: lastName,
        village: village,
        healthFacility: healthFacility,
        region: region,
        fcmToken: fcmToken,
        lastUpdatedAt: DateTime.now(),
      );

      final syncResponse = await _api.syncUserProfile(accessToken, syncRequest);

      if (syncResponse.success) {
        // Update local database with synced data
        final db = await _db.database;
        final updateData = <String, dynamic>{
          'updated_at': syncResponse.syncTimestamp.toIso8601String(),
        };

        // Update fields that were changed
        if (syncResponse.fieldsUpdated.contains('email')) {
          updateData['email'] = syncResponse.user.email;
        }
        if (syncResponse.fieldsUpdated.contains('first_name')) {
          updateData['first_name'] = syncResponse.user.firstName;
        }
        if (syncResponse.fieldsUpdated.contains('last_name')) {
          updateData['last_name'] = syncResponse.user.lastName;
        }
        if (syncResponse.fieldsUpdated.contains('village')) {
          updateData['village'] = syncResponse.user.village;
        }
        if (syncResponse.fieldsUpdated.contains('health_facility')) {
          updateData['health_facility'] = syncResponse.user.healthFacility;
        }
        if (syncResponse.fieldsUpdated.contains('region')) {
          updateData['region'] = syncResponse.user.region;
        }

        await db.update(
          'chws',
          updateData,
          where: 'id = ?',
          whereArgs: [currentCHW.id],
        );

        log('Profile synced. Fields updated: ${syncResponse.fieldsUpdated.join(", ")}',
            name: 'AuthService');

        if (syncResponse.conflicts.isNotEmpty) {
          log('Sync conflicts: ${syncResponse.conflicts.map((c) => "${c.field}: ${c.resolution}").join(", ")}',
              name: 'AuthService');
        }

        return syncResponse;
      }

      return null;
    } on AuthApiException catch (e) {
      log('Failed to push user profile: ${e.message}', name: 'AuthService');
      rethrow;
    } catch (e) {
      log('Error pushing user profile: $e', name: 'AuthService');
      rethrow;
    }
  }

  /// Sync pending registrations with backend
  Future<void> syncPendingOperations() async {
    if (!isOnline) return;

    try {
      // First, pull latest profile from server
      await pullUserProfile();

      // Then sync pending operations
      final pendingOps = await _db.getPendingAuthSyncOperations();

      for (final op in pendingOps) {
        try {
          final operation = op['operation'] as String;
          final userId = op['user_id'] as String;
          final data = jsonDecode(op['data'] as String) as Map<String, dynamic>;

          if (operation == 'register') {
            // Try to register with backend
            final request = RegisterRequest(
              firstName: data['first_name'],
              lastName: data['last_name'],
              phoneNumber: data['phone_number'],
              pin: data['pin'],
              password: data['password'],
              email: data['email'],
              village: data['village'],
              healthFacility: data['health_facility'],
              region: data['region'],
            );

            final response = await _api.register(request);

            // Update local record with backend ID
            final db = await _db.database;
            await db.update(
              'chws',
              {
                'id': response.user.id,
                'is_synced': 1,
                'last_sync_date': DateTime.now().toIso8601String(),
                'pending_sync': 0,
              },
              where: 'id = ?',
              whereArgs: [userId],
            );

            // Remove from sync queue
            await _db.removeAuthSyncOperation(op['id'] as int);
            log('Synced registration for: ${data['phone_number']}', name: 'AuthService');
          }
        } catch (e) {
          log('Failed to sync operation: $e', name: 'AuthService');
          await _db.updateAuthSyncRetry(op['id'] as int, e.toString());
        }
      }
    } catch (e) {
      log('Sync error: $e', name: 'AuthService');
    }
  }

  // ========== BACKGROUND SYNC HELPERS (NON-BLOCKING) ==========

  /// Background registration sync - runs asynchronously, doesn't block user
  void _syncRegistrationInBackground(
    String userId,
    String phone,
    String pin,
    String? password,
    String? email,
    String firstName,
    String lastName,
    String? village,
    String? healthFacility,
    String? region,
  ) {
    // Run in separate isolate/future to not block UI
    Future.microtask(() async {
      try {
        log('🔄 Background sync: Registering with backend...', name: 'AuthService');
        
        final request = RegisterRequest(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phone,
          pin: pin,
          password: password,
          email: email,
          village: village,
          healthFacility: healthFacility,
          region: region,
        );

        final response = await _api.register(request);

        // Update local record with backend ID and tokens
        final db = await _db.database;
        await db.update(
          'chws',
          {
            'id': response.user.id,
            'is_synced': 1,
            'last_sync_date': DateTime.now().toIso8601String(),
            'pending_sync': 0,
          },
          where: 'id = ?',
          whereArgs: [userId],
        );

        // Save tokens
        await _saveTokens(
          response.user.id,
          response.accessToken,
          response.refreshToken,
          DateTime.now().add(Duration(seconds: response.expiresIn)),
        );

        // Remove from sync queue
        final pendingOps = await _db.getPendingAuthSyncOperations();
        for (final op in pendingOps) {
          if (op['user_id'] == userId && op['operation'] == 'register') {
            await _db.removeAuthSyncOperation(op['id'] as int);
          }
        }

        log('✅ Background sync: Registration synced with backend', name: 'AuthService');
      } catch (e) {
        log('⚠️ Background sync: Registration failed, will retry later: $e', name: 'AuthService');
        // Don't throw - this is non-blocking background sync
      }
    });
  }

  /// Background login sync - fetches user data and tokens from backend
  void _syncLoginInBackground(String phone, String pin, CHW localChw) {
    Future.microtask(() async {
      try {
        log('🔄 Background sync: Fetching user data from backend...', name: 'AuthService');
        
        final request = LoginRequest(
          phoneNumber: phone,
          pin: pin,
        );

        final response = await _api.login(request);

        // Update local record with backend data
        final updatedChw = localChw.copyWith(
          id: response.user.id,
          firstName: response.user.firstName,
          lastName: response.user.lastName,
          email: response.user.email,
          role: response.user.role,
          village: response.user.village,
          healthFacility: response.user.healthFacility,
          region: response.user.region,
          profilePhotoUrl: response.user.profilePhotoUrl,
          permissions: response.user.permissions,
          isSynced: true,
          lastSyncDate: DateTime.now(),
          pendingSync: false,
        );
        
        await _db.updateCHWFromBackend(updatedChw);

        // Save tokens
        await _saveTokens(
          response.user.id,
          response.accessToken,
          response.refreshToken,
          DateTime.now().add(Duration(seconds: response.expiresIn)),
        );

        log('✅ Background sync: User data synced with backend', name: 'AuthService');
      } catch (e) {
        log('⚠️ Background sync: Login sync failed, will retry later: $e', name: 'AuthService');
        // Don't throw - this is non-blocking background sync
      }
    });
  }
}

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';

  bool get isUnauthorized => statusCode == 401;
  bool get isTokenExpired => message.contains('expired') || message.contains('token');
}
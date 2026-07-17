import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/chw.dart';
import '../services/auth_service.dart';
import '../services/auth_api_service.dart';
import '../services/connectivity_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;

  CHW? _currentCHW;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = true;

  CHW? get currentCHW => _currentCHW;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentCHW != null;
  bool get isOnline => _isOnline;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Update online status
      _isOnline = _connectivity.isOnline;
      
      final shouldRemember = await _authService.shouldRememberUser();
      if (shouldRemember) {
        _currentCHW = await _authService.getCurrentCHW();
        
        // Try to refresh token if online
        if (_currentCHW != null && _isOnline) {
          final isExpired = await _authService.isTokenExpired();
          if (isExpired) {
            await _authService.refreshAccessToken();
          }
        }
      }
      
      // Sync pending operations if online
      if (_isOnline) {
        await _authService.syncPendingOperations();
      }
    } catch (e) {
      log('Auth initialization warning: $e', name: 'AuthProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register new CHW
  Future<bool> register({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final chw = await _authService.registerCHW(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        pin: pin,
        password: password,
        email: email,
        village: village,
        healthFacility: healthFacility,
        region: region,
      );

      if (chw != null) {
        _currentCHW = chw;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login(String phoneNumber, String pin, {bool rememberMe = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isOnline = _connectivity.isOnline;
      
      final chw = await _authService.login(phoneNumber, pin, rememberMe: rememberMe);

      if (chw != null) {
        _currentCHW = chw;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid phone number or PIN';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _currentCHW = null;
    notifyListeners();
  }

  // Change PIN
  Future<bool> changePin(String currentPin, String newPin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.changePin(currentPin, newPin);
      _isLoading = false;
      notifyListeners();
      return success;
    } on AuthApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Change Password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.changePassword(currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return success;
    } on AuthApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh current CHW data from database
  Future<void> refreshCurrentCHW() async {
    if (_currentCHW != null) {
      try {
        final refreshedCHW = await _authService.getCHWById(_currentCHW!.id);
        if (refreshedCHW != null) {
          _currentCHW = refreshedCHW;
          notifyListeners();
        }
      } catch (e) {
        log('Error refreshing CHW: $e', name: 'AuthProvider');
      }
    }
  }

  // Sync pending operations
  Future<void> syncPendingOperations() async {
    if (_connectivity.isOnline) {
      await _authService.syncPendingOperations();
      await refreshCurrentCHW();
    }
  }

  // Pull user profile from server (GET sync)
  Future<bool> pullUserProfile() async {
    if (!_connectivity.isOnline) {
      _errorMessage = 'Cannot sync - offline';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userProfile = await _authService.pullUserProfile();
      _isLoading = false;
      
      if (userProfile != null) {
        await refreshCurrentCHW();
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Failed to pull profile from server';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Push user profile to server (POST sync)
  Future<bool> pushUserProfile({
    String? email,
    String? firstName,
    String? lastName,
    String? village,
    String? healthFacility,
    String? region,
    String? fcmToken,
  }) async {
    if (!_connectivity.isOnline) {
      _errorMessage = 'Cannot sync - offline';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final syncResponse = await _authService.pushUserProfile(
        email: email,
        firstName: firstName,
        lastName: lastName,
        village: village,
        healthFacility: healthFacility,
        region: region,
        fcmToken: fcmToken,
      );

      _isLoading = false;
      
      if (syncResponse != null && syncResponse.success) {
        await refreshCurrentCHW();
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Failed to sync profile with server';
      notifyListeners();
      return false;
    } on AuthApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update online status
  void updateOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
      
      // Sync when coming online
      if (isOnline) {
        syncPendingOperations();
      }
    }
  }
}
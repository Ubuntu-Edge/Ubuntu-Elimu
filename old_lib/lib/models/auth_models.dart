// Authentication Models for API Integration
// These models match the backend API schemas for authentication endpoints

/// User model returned from backend after login/register
class UserResponse {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String role;
  final String? village;
  final String? healthFacility;
  final String? region;
  final String? profilePhotoUrl;
  final List<String>? permissions;

  UserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    required this.role,
    this.village,
    this.healthFacility,
    this.region,
    this.profilePhotoUrl,
    this.permissions,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'chw',
      village: json['village'],
      healthFacility: json['health_facility'],
      region: json['region'],
      profilePhotoUrl: json['profile_photo_url'],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'email': email,
      'role': role,
      'village': village,
      'health_facility': healthFacility,
      'region': region,
      'profile_photo_url': profilePhotoUrl,
      'permissions': permissions,
    };
  }

  String get fullName => '$firstName $lastName';
}

/// Authentication response containing tokens and user data
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserResponse user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      expiresIn: json['expires_in'] ?? 86400,
      user: UserResponse.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}

/// Login request model
class LoginRequest {
  final String phoneNumber;
  final String pin;
  final String? deviceId;
  final String? deviceName;
  final String? fcmToken;

  LoginRequest({
    required this.phoneNumber,
    required this.pin,
    this.deviceId,
    this.deviceName,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'pin': pin,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (fcmToken != null) 'fcm_token': fcmToken,
    };
  }
}

/// Register request model
class RegisterRequest {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String pin;
  final String? password;
  final String? email;
  final String? village;
  final String? healthFacility;
  final String? region;
  final String? role;
  final String? deviceId;
  final String? deviceName;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.pin,
    this.password,
    this.email,
    this.village,
    this.healthFacility,
    this.region,
    this.role = 'chw',
    this.deviceId,
    this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'pin': pin,
      if (password != null) 'password': password,
      if (email != null) 'email': email,
      if (village != null) 'village': village,
      if (healthFacility != null) 'health_facility': healthFacility,
      if (region != null) 'region': region,
      if (role != null) 'role': role,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
    };
  }
}

/// Refresh token request
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refresh_token': refreshToken};
  }
}

/// Change password request
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
    };
  }
}

/// Change PIN request
class ChangePinRequest {
  final String currentPin;
  final String newPin;

  ChangePinRequest({
    required this.currentPin,
    required this.newPin,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_pin': currentPin,
      'new_pin': newPin,
    };
  }
}

/// Generic API response for simple success/error messages
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

/// Validation error detail from API
class ValidationErrorDetail {
  final List<dynamic> loc;
  final String msg;
  final String type;

  ValidationErrorDetail({
    required this.loc,
    required this.msg,
    required this.type,
  });

  factory ValidationErrorDetail.fromJson(Map<String, dynamic> json) {
    return ValidationErrorDetail(
      loc: json['loc'] ?? [],
      msg: json['msg'] ?? '',
      type: json['type'] ?? '',
    );
  }

  String get fieldName {
    if (loc.isNotEmpty) {
      return loc.last.toString();
    }
    return '';
  }
}

/// Validation error response from API (422)
class ValidationErrorResponse {
  final List<ValidationErrorDetail> detail;

  ValidationErrorResponse({required this.detail});

  factory ValidationErrorResponse.fromJson(Map<String, dynamic> json) {
    final detailList = json['detail'] as List<dynamic>? ?? [];
    return ValidationErrorResponse(
      detail: detailList
          .map((d) => ValidationErrorDetail.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedMessage {
    if (detail.isEmpty) return 'Validation error';
    return detail.map((d) => '${d.fieldName}: ${d.msg}').join('\n');
  }

  String get firstError {
    if (detail.isEmpty) return 'Validation error';
    return detail.first.msg;
  }
}

/// Stored credentials for offline authentication
class StoredCredentials {
  final String id;
  final String phoneNumber;
  final String pinHash;
  final String? passwordHash;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final DateTime lastLogin;
  final bool isOnlineVerified;

  StoredCredentials({
    required this.id,
    required this.phoneNumber,
    required this.pinHash,
    this.passwordHash,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    required this.lastLogin,
    this.isOnlineVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'pin_hash': pinHash,
      'password_hash': passwordHash,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expiry': tokenExpiry?.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
      'is_online_verified': isOnlineVerified ? 1 : 0,
    };
  }

  factory StoredCredentials.fromMap(Map<String, dynamic> map) {
    return StoredCredentials(
      id: map['id'],
      phoneNumber: map['phone_number'],
      pinHash: map['pin_hash'],
      passwordHash: map['password_hash'],
      accessToken: map['access_token'],
      refreshToken: map['refresh_token'],
      tokenExpiry: map['token_expiry'] != null
          ? DateTime.parse(map['token_expiry'])
          : null,
      lastLogin: DateTime.parse(map['last_login']),
      isOnlineVerified: map['is_online_verified'] == 1,
    );
  }

  bool get isTokenValid {
    if (accessToken == null || tokenExpiry == null) return false;
    return DateTime.now().isBefore(tokenExpiry!);
  }
}

/// User profile sync request
class UserProfileSyncRequest {
  final String? deviceId;
  final String? email;
  final String? fcmToken;
  final String? firstName;
  final String? lastName;
  final String? village;
  final String? healthFacility;
  final String? region;
  final String? profilePhotoUrl;
  final String? bio;
  final String? currentPassword;
  final String? newPassword;
  final String? currentPin;
  final String? newPin;
  final DateTime? lastUpdatedAt;

  UserProfileSyncRequest({
    this.deviceId,
    this.email,
    this.fcmToken,
    this.firstName,
    this.lastName,
    this.village,
    this.healthFacility,
    this.region,
    this.profilePhotoUrl,
    this.bio,
    this.currentPassword,
    this.newPassword,
    this.currentPin,
    this.newPin,
    this.lastUpdatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (deviceId != null) 'device_id': deviceId,
      if (email != null) 'email': email,
      if (fcmToken != null) 'fcm_token': fcmToken,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (village != null) 'village': village,
      if (healthFacility != null) 'health_facility': healthFacility,
      if (region != null) 'region': region,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (bio != null) 'bio': bio,
      if (currentPassword != null) 'current_password': currentPassword,
      if (newPassword != null) 'new_password': newPassword,
      if (currentPin != null) 'current_pin': currentPin,
      if (newPin != null) 'new_pin': newPin,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt!.toUtc().toIso8601String(),
    };
  }
}

/// Conflict information from sync response
class SyncConflict {
  final String field;
  final dynamic serverValue;
  final dynamic localValue;
  final String resolution;

  SyncConflict({
    required this.field,
    required this.serverValue,
    required this.localValue,
    required this.resolution,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      field: json['field'] ?? '',
      serverValue: json['server_value'],
      localValue: json['local_value'],
      resolution: json['resolution'] ?? 'server_wins',
    );
  }
}

/// User profile sync response
class UserProfileSyncResponse {
  final bool success;
  final String message;
  final UserResponse user;
  final List<String> fieldsUpdated;
  final List<SyncConflict> conflicts;
  final DateTime syncTimestamp;

  UserProfileSyncResponse({
    required this.success,
    required this.message,
    required this.user,
    required this.fieldsUpdated,
    required this.conflicts,
    required this.syncTimestamp,
  });

  factory UserProfileSyncResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileSyncResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: UserResponse.fromJson(json['user']),
      fieldsUpdated: json['fields_updated'] != null
          ? List<String>.from(json['fields_updated'])
          : [],
      conflicts: json['conflicts'] != null
          ? (json['conflicts'] as List)
              .map((c) => SyncConflict.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      syncTimestamp: json['sync_timestamp'] != null
          ? DateTime.parse(json['sync_timestamp'])
          : DateTime.now(),
    );
  }
}

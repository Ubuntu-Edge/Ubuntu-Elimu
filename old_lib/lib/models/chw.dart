/// Represents a Community Health Worker (CHW).
/// This class is designed to be immutable (all fields are final)
/// and includes utility methods for persistence (toMap, fromMap) and object manipulation (copyWith).
class CHW {
  /// Unique identifier for the CHW (UUID from backend).
  final String id;
  /// The CHW's first name.
  final String firstName;
  /// The CHW's last name.
  final String lastName;
  /// The primary phone number for the CHW (E.164 format).
  final String phoneNumber;
  /// Optional email address for the CHW. Can be null.
  final String? email;
  /// 4-digit PIN for quick login/authentication.
  /// Note: Stored as hash locally, plain text only during input.
  final String pin;
  /// The village where the CHW primarily works or resides. Can be null.
  final String? village;
  /// The associated health facility (e.g., clinic, hospital). Can be null.
  final String? healthFacility;
  /// The administrative region the CHW belongs to. Can be null.
  final String? region;
  /// The date and time the CHW was registered in the system.
  final DateTime registeredDate;
  /// Status indicating if the CHW account is currently active. Defaults to true.
  final bool isActive;
  
  // ===== NEW FIELDS FOR BACKEND INTEGRATION =====
  
  /// User role: 'chw', 'supervisor', or 'admin'
  final String role;
  /// Profile photo URL from backend. Can be null.
  final String? profilePhotoUrl;
  /// List of permissions granted to this user.
  final List<String>? permissions;
  /// Whether this user has been synced with backend.
  final bool isSynced;
  /// Last sync timestamp with backend.
  final DateTime? lastSyncDate;
  /// Whether the user was created offline and needs to be synced.
  final bool pendingSync;

  /// Constructor for creating a new CHW instance.
  /// Requires essential fields and makes optional fields explicitly nullable.
  CHW({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    required this.pin,
    this.village,
    this.healthFacility,
    this.region,
    required this.registeredDate,
    this.isActive = true,
    this.role = 'chw',
    this.profilePhotoUrl,
    this.permissions,
    this.isSynced = false,
    this.lastSyncDate,
    this.pendingSync = false,
  });

  // --- Persistence Methods ---

  /// Converts the CHW object into a Map<String, dynamic>.
  /// This format is suitable for storage in databases like SQLite or Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // Using snake_case for database column names
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'email': email,
      'pin': pin,
      'village': village,
      'health_facility': healthFacility,
      'region': region,
      // Converting DateTime to a standardized string format for storage
      'registered_date': registeredDate.toIso8601String(),
      // Converting bool to int (1 for true, 0 for false) for database compatibility
      'is_active': isActive ? 1 : 0,
      // New fields for backend integration
      'role': role,
      'profile_photo_url': profilePhotoUrl,
      'permissions': permissions?.join(','),
      'is_synced': isSynced ? 1 : 0,
      'last_sync_date': lastSyncDate?.toIso8601String(),
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  /// Factory constructor to create a CHW object from a database Map (row).
  ///
  /// @param map The Map containing the CHW's data, typically from a database query.
  /// @returns A new CHW instance.
  factory CHW.fromMap(Map<String, dynamic> map) {
    return CHW(
      id: map['id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      phoneNumber: map['phone_number'],
      email: map['email'],
      pin: map['pin'],
      village: map['village'],
      healthFacility: map['health_facility'],
      region: map['region'],
      // Parsing the stored ISO 8601 string back into a DateTime object
      registeredDate: DateTime.parse(map['registered_date']),
      // Converting stored int (1/0) back to a boolean
      isActive: map['is_active'] == 1,
      // New fields with defaults for backwards compatibility
      role: map['role'] ?? 'chw',
      profilePhotoUrl: map['profile_photo_url'],
      permissions: map['permissions'] != null
          ? (map['permissions'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : null,
      isSynced: map['is_synced'] == 1,
      lastSyncDate: map['last_sync_date'] != null
          ? DateTime.parse(map['last_sync_date'])
          : null,
      pendingSync: map['pending_sync'] == 1,
    );
  }

  /// Factory constructor to create a CHW from API response
  factory CHW.fromApiResponse(Map<String, dynamic> userJson, String pin) {
    return CHW(
      id: userJson['id'] ?? '',
      firstName: userJson['first_name'] ?? '',
      lastName: userJson['last_name'] ?? '',
      phoneNumber: userJson['phone_number'] ?? '',
      email: userJson['email'],
      pin: pin, // PIN is not returned from API, must be provided
      village: userJson['village'],
      healthFacility: userJson['health_facility'],
      region: userJson['region'],
      registeredDate: DateTime.now(),
      isActive: true,
      role: userJson['role'] ?? 'chw',
      profilePhotoUrl: userJson['profile_photo_url'],
      permissions: userJson['permissions'] != null
          ? List<String>.from(userJson['permissions'])
          : null,
      isSynced: true,
      lastSyncDate: DateTime.now(),
      pendingSync: false,
    );
  }

  // --- Utility Methods & Getters ---

  /// Getter to combine the first and last name into a full name string.
  String get fullName => '$firstName $lastName';

  /// Creates a copy of the current CHW object, optionally replacing
  /// specific fields with new values. This is essential for immutable objects.
  ///
  /// @param [id] New ID, if provided.
  /// @param [firstName] New first name, if provided.
  /// ...and so on for all fields.
  /// @returns A new CHW object with updated values.
  CHW copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? pin,
    String? village,
    String? healthFacility,
    String? region,
    DateTime? registeredDate,
    bool? isActive,
    String? role,
    String? profilePhotoUrl,
    List<String>? permissions,
    bool? isSynced,
    DateTime? lastSyncDate,
    bool? pendingSync,
  }) {
    return CHW(
      // Use the provided new value (id) if it's not null, otherwise use the current object's value (this.id).
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      pin: pin ?? this.pin,
      village: village ?? this.village,
      healthFacility: healthFacility ?? this.healthFacility,
      region: region ?? this.region,
      registeredDate: registeredDate ?? this.registeredDate,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      permissions: permissions ?? this.permissions,
      isSynced: isSynced ?? this.isSynced,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    return permissions?.contains(permission) ?? false;
  }

  /// Check if user is a supervisor
  bool get isSupervisor => role == 'supervisor';

  /// Check if user is an admin
  bool get isAdmin => role == 'admin';

  /// Check if user is a CHW
  bool get isChw => role == 'chw';
}
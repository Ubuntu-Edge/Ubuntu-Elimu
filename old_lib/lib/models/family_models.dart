// Family Models for API Integration
// These models match the backend API schemas for family endpoints

/// Family create request model
class FamilyCreateRequest {
  final String familyName;
  final String? village;
  final String? address;
  final String? location;
  final String? headOfHouseholdId;
  final int? householdSize;
  final String? housingType;
  final String? waterSource;
  final String? sanitationType;
  final bool? hasElectricity;
  final bool? hasNhif;
  final String? nhifNumber;
  final double? latitude;
  final double? longitude;
  final String? notes;

  FamilyCreateRequest({
    required this.familyName,
    this.village,
    this.address,
    this.location,
    this.headOfHouseholdId,
    this.householdSize,
    this.housingType,
    this.waterSource,
    this.sanitationType,
    this.hasElectricity,
    this.hasNhif,
    this.nhifNumber,
    this.latitude,
    this.longitude,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'family_name': familyName,
    };
    
    if (village != null) data['village'] = village;
    if (address != null) data['address'] = address;
    if (location != null) data['location'] = location;
    if (headOfHouseholdId != null) data['head_of_household_id'] = headOfHouseholdId;
    if (householdSize != null) data['household_size'] = householdSize;
    if (housingType != null) data['housing_type'] = housingType;
    if (waterSource != null) data['water_source'] = waterSource;
    if (sanitationType != null) data['sanitation_type'] = sanitationType;
    if (hasElectricity != null) data['has_electricity'] = hasElectricity;
    if (hasNhif != null) data['has_nhif'] = hasNhif;
    if (nhifNumber != null) data['nhif_number'] = nhifNumber;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (notes != null) data['notes'] = notes;
    
    return data;
  }
}

/// Family update request model
class FamilyUpdateRequest {
  final String? familyName;
  final String? village;
  final String? address;
  final String? location;
  final String? headOfHouseholdId;
  final int? householdSize;
  final String? housingType;
  final String? waterSource;
  final String? sanitationType;
  final bool? hasElectricity;
  final bool? hasNhif;
  final String? nhifNumber;
  final double? latitude;
  final double? longitude;
  final String? notes;

  FamilyUpdateRequest({
    this.familyName,
    this.village,
    this.address,
    this.location,
    this.headOfHouseholdId,
    this.householdSize,
    this.housingType,
    this.waterSource,
    this.sanitationType,
    this.hasElectricity,
    this.hasNhif,
    this.nhifNumber,
    this.latitude,
    this.longitude,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (familyName != null) data['family_name'] = familyName;
    if (village != null) data['village'] = village;
    if (address != null) data['address'] = address;
    if (location != null) data['location'] = location;
    if (headOfHouseholdId != null) data['head_of_household_id'] = headOfHouseholdId;
    if (householdSize != null) data['household_size'] = householdSize;
    if (housingType != null) data['housing_type'] = housingType;
    if (waterSource != null) data['water_source'] = waterSource;
    if (sanitationType != null) data['sanitation_type'] = sanitationType;
    if (hasElectricity != null) data['has_electricity'] = hasElectricity;
    if (hasNhif != null) data['has_nhif'] = hasNhif;
    if (nhifNumber != null) data['nhif_number'] = nhifNumber;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (notes != null) data['notes'] = notes;
    
    return data;
  }
}

/// Family response model from API
class FamilyResponse {
  final String id;
  final String familyName;
  final String? headOfHouseholdId;
  final String? village;
  final String? address;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int? householdSize;
  final String? housingType;
  final String? waterSource;
  final String? sanitationType;
  final bool hasElectricity;
  final bool hasNhif;
  final String? nhifNumber;
  final DateTime? registeredDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;
  final bool hasVulnerableMembers;

  FamilyResponse({
    required this.id,
    required this.familyName,
    this.headOfHouseholdId,
    this.village,
    this.address,
    this.location,
    this.latitude,
    this.longitude,
    this.householdSize,
    this.housingType,
    this.waterSource,
    this.sanitationType,
    this.hasElectricity = false,
    this.hasNhif = false,
    this.nhifNumber,
    this.registeredDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 0,
    this.hasVulnerableMembers = false,
  });

  factory FamilyResponse.fromJson(Map<String, dynamic> json) {
    return FamilyResponse(
      id: json['id'] ?? '',
      familyName: json['family_name'] ?? '',
      headOfHouseholdId: json['head_of_household_id'],
      village: json['village'],
      address: json['address'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      householdSize: json['household_size'],
      housingType: json['housing_type'],
      waterSource: json['water_source'],
      sanitationType: json['sanitation_type'],
      hasElectricity: json['has_electricity'] ?? false,
      hasNhif: json['has_nhif'] ?? false,
      nhifNumber: json['nhif_number'],
      registeredDate: json['registered_date'] != null 
          ? DateTime.parse(json['registered_date']) 
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      memberCount: json['member_count'] ?? 0,
      hasVulnerableMembers: json['has_vulnerable_members'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_name': familyName,
      'head_of_household_id': headOfHouseholdId,
      'village': village,
      'address': address,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'household_size': householdSize,
      'housing_type': housingType,
      'water_source': waterSource,
      'sanitation_type': sanitationType,
      'has_electricity': hasElectricity,
      'has_nhif': hasNhif,
      'nhif_number': nhifNumber,
      'registered_date': registeredDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'member_count': memberCount,
      'has_vulnerable_members': hasVulnerableMembers,
    };
  }

  /// Convert to database map for local storage
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'family_name': familyName,
      'head_of_household_id': headOfHouseholdId,
      'village': village,
      'address': address,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'household_size': householdSize,
      'housing_type': housingType,
      'water_source': waterSource,
      'sanitation_type': sanitationType,
      'has_electricity': hasElectricity ? 1 : 0,
      'has_nhif': hasNhif ? 1 : 0,
      'nhif_number': nhifNumber,
      'registered_date': registeredDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'member_count': memberCount,
      'has_vulnerable_members': hasVulnerableMembers ? 1 : 0,
      'is_synced': 1,
    };
  }

  /// Create from database map
  factory FamilyResponse.fromDbMap(Map<String, dynamic> map) {
    return FamilyResponse(
      id: map['id'] ?? '',
      familyName: map['family_name'] ?? '',
      headOfHouseholdId: map['head_of_household_id'],
      village: map['village'],
      address: map['address'],
      location: map['location'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      householdSize: map['household_size'],
      housingType: map['housing_type'],
      waterSource: map['water_source'],
      sanitationType: map['sanitation_type'],
      hasElectricity: map['has_electricity'] == 1,
      hasNhif: map['has_nhif'] == 1,
      nhifNumber: map['nhif_number'],
      registeredDate: map['registered_date'] != null 
          ? DateTime.parse(map['registered_date']) 
          : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      memberCount: map['member_count'] ?? 0,
      hasVulnerableMembers: map['has_vulnerable_members'] == 1,
    );
  }
}

/// Pagination metadata
class PaginationMeta {
  final int page;
  final int perPage;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationMeta({
    required this.page,
    required this.perPage,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}

/// Family list response with pagination
class FamilyListResponse {
  final bool success;
  final List<FamilyResponse> data;
  final PaginationMeta pagination;

  FamilyListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory FamilyListResponse.fromJson(Map<String, dynamic> json) {
    return FamilyListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => FamilyResponse.fromJson(e))
          .toList() ?? [],
      pagination: PaginationMeta.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// API Exception for Family operations
class FamilyApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<ValidationError>? validationErrors;

  FamilyApiException(
    this.message, {
    this.statusCode,
    this.validationErrors,
  });

  @override
  String toString() => message;
}

/// Validation error detail
class ValidationError {
  final List<dynamic> loc;
  final String msg;
  final String type;

  ValidationError({
    required this.loc,
    required this.msg,
    required this.type,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      loc: json['loc'] ?? [],
      msg: json['msg'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

/// Validation error response
class ValidationErrorResponse {
  final List<ValidationError> detail;

  ValidationErrorResponse({required this.detail});

  factory ValidationErrorResponse.fromJson(Map<String, dynamic> json) {
    return ValidationErrorResponse(
      detail: (json['detail'] as List<dynamic>?)
          ?.map((e) => ValidationError.fromJson(e))
          .toList() ?? [],
    );
  }

  String get firstError {
    if (detail.isEmpty) return 'Validation error';
    final error = detail.first;
    final field = error.loc.length > 1 ? error.loc.last.toString() : 'field';
    return '$field: ${error.msg}';
  }
}

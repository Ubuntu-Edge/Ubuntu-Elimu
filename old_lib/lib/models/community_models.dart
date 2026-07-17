/// Community Health Mapping Models
/// Matches the backend API at /api/v1/community/*
library;

// ==================== ALLOWED VALUES / ENUMS ====================

/// Risk levels for households
class RiskLevel {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static const List<String> values = [low, medium, high, critical];

  static bool isValid(String? value) =>
      value == null || values.contains(value.toLowerCase());

  static String displayName(String value) {
    switch (value.toLowerCase()) {
      case low:
        return 'Low';
      case medium:
        return 'Medium';
      case high:
        return 'High';
      case critical:
        return 'Critical';
      default:
        return value;
    }
  }
}

/// Resource types for shared community resources
class ResourceType {
  static const String waterSource = 'water_source';
  static const String latrine = 'latrine';
  static const String clinic = 'clinic';
  static const String school = 'school';

  static const List<String> values = [waterSource, latrine, clinic, school];

  static bool isValid(String? value) =>
      value == null || values.contains(value.toLowerCase());

  static String displayName(String value) {
    switch (value.toLowerCase()) {
      case waterSource:
        return 'Water Source';
      case latrine:
        return 'Latrine';
      case clinic:
        return 'Clinic';
      case school:
        return 'School';
      default:
        return value;
    }
  }
}

/// Severity levels for disease cases
class DiseaseSeverity {
  static const String mild = 'mild';
  static const String moderate = 'moderate';
  static const String severe = 'severe';

  static const List<String> values = [mild, moderate, severe];

  static bool isValid(String? value) =>
      value == null || values.contains(value.toLowerCase());

  static String displayName(String value) {
    switch (value.toLowerCase()) {
      case mild:
        return 'Mild';
      case moderate:
        return 'Moderate';
      case severe:
        return 'Severe';
      default:
        return value;
    }
  }
}

/// Status for disease cases
class DiseaseCaseStatus {
  static const String active = 'active';
  static const String recovered = 'recovered';
  static const String fatal = 'fatal';
  static const String underTreatment = 'under_treatment';

  static const List<String> values = [active, recovered, fatal, underTreatment];

  static bool isValid(String? value) =>
      value == null || values.contains(value.toLowerCase());

  static String displayName(String value) {
    switch (value.toLowerCase()) {
      case active:
        return 'Active';
      case recovered:
        return 'Recovered';
      case fatal:
        return 'Fatal';
      case underTreatment:
        return 'Under Treatment';
      default:
        return value;
    }
  }
}

// ==================== HOUSEHOLD MODELS ====================

/// Household model for community health mapping
class Household {
  final String id;
  final String chwId;
  final String? familyId;
  final double latitude;
  final double longitude;
  final String area;
  final String village;
  final double riskScore;
  final String riskLevel;
  final int householdSize;
  final int vulnerableMembers;
  final bool waterAccess;
  final bool sanitationAccess;
  final bool electricityAccess;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? diseaseCaseCount;

  Household({
    required this.id,
    required this.chwId,
    this.familyId,
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.village,
    this.riskScore = 0.0,
    this.riskLevel = RiskLevel.low,
    this.householdSize = 0,
    this.vulnerableMembers = 0,
    this.waterAccess = false,
    this.sanitationAccess = false,
    this.electricityAccess = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.diseaseCaseCount,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] ?? '',
      chwId: json['chw_id'] ?? '',
      familyId: json['family_id'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      area: json['area'] ?? '',
      village: json['village'] ?? '',
      riskScore: (json['risk_score'] ?? 0.0).toDouble(),
      riskLevel: json['risk_level'] ?? RiskLevel.low,
      householdSize: json['household_size'] ?? 0,
      vulnerableMembers: json['vulnerable_members'] ?? 0,
      waterAccess: json['water_access'] ?? false,
      sanitationAccess: json['sanitation_access'] ?? false,
      electricityAccess: json['electricity_access'] ?? false,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      diseaseCaseCount: json['disease_case_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chw_id': chwId,
      'family_id': familyId,
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'village': village,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'household_size': householdSize,
      'vulnerable_members': vulnerableMembers,
      'water_access': waterAccess,
      'sanitation_access': sanitationAccess,
      'electricity_access': electricityAccess,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'disease_case_count': diseaseCaseCount,
    };
  }

  String get riskLevelDisplay => RiskLevel.displayName(riskLevel);

  bool get isHighRisk =>
      riskLevel == RiskLevel.high || riskLevel == RiskLevel.critical;
}

/// Request model for creating/updating households
class HouseholdRequest {
  final double latitude;
  final double longitude;
  final String area;
  final String village;
  final String? familyId;
  final double? riskScore;
  final String? riskLevel;
  final int? householdSize;
  final int? vulnerableMembers;
  final bool? waterAccess;
  final bool? sanitationAccess;
  final bool? electricityAccess;
  final String? notes;

  HouseholdRequest({
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.village,
    this.familyId,
    this.riskScore,
    this.riskLevel,
    this.householdSize,
    this.vulnerableMembers,
    this.waterAccess,
    this.sanitationAccess,
    this.electricityAccess,
    this.notes,
  }) : assert(riskLevel == null || RiskLevel.isValid(riskLevel),
            'Invalid risk_level. Must be one of: ${RiskLevel.values.join(", ")}');

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'village': village,
    };
    if (familyId != null) json['family_id'] = familyId;
    if (riskScore != null) json['risk_score'] = riskScore;
    if (riskLevel != null) json['risk_level'] = riskLevel;
    if (householdSize != null) json['household_size'] = householdSize;
    if (vulnerableMembers != null)
      json['vulnerable_members'] = vulnerableMembers;
    if (waterAccess != null) json['water_access'] = waterAccess;
    if (sanitationAccess != null) json['sanitation_access'] = sanitationAccess;
    if (electricityAccess != null)
      json['electricity_access'] = electricityAccess;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

/// Response for listing households with pagination
class HouseholdListResponse {
  final bool success;
  final List<Household> data;
  final PaginationInfo pagination;

  HouseholdListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory HouseholdListResponse.fromJson(Map<String, dynamic> json) {
    return HouseholdListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Household.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

// ==================== SHARED RESOURCE MODELS ====================

/// Shared community resource model
class SharedResource {
  final String id;
  final String resourceType;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final String area;
  final String village;
  final bool functional;
  final int capacity;
  final int usersCount;
  final DateTime? lastInspectionDate;
  final String? reportedById;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SharedResource({
    required this.id,
    required this.resourceType,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.village,
    this.functional = true,
    this.capacity = 0,
    this.usersCount = 0,
    this.lastInspectionDate,
    this.reportedById,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SharedResource.fromJson(Map<String, dynamic> json) {
    return SharedResource(
      id: json['id'] ?? '',
      resourceType: json['resource_type'] ?? ResourceType.waterSource,
      name: json['name'] ?? '',
      description: json['description'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      area: json['area'] ?? '',
      village: json['village'] ?? '',
      functional: json['functional'] ?? true,
      capacity: json['capacity'] ?? 0,
      usersCount: json['users_count'] ?? 0,
      lastInspectionDate: json['last_inspection_date'] != null
          ? DateTime.tryParse(json['last_inspection_date'])
          : null,
      reportedById: json['reported_by_id'],
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resource_type': resourceType,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'village': village,
      'functional': functional,
      'capacity': capacity,
      'users_count': usersCount,
      'last_inspection_date': lastInspectionDate?.toIso8601String(),
      'reported_by_id': reportedById,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get resourceTypeDisplay => ResourceType.displayName(resourceType);

  double get utilizationRate {
    if (capacity == 0) return 0.0;
    return (usersCount / capacity).clamp(0.0, 1.0);
  }
}

/// Request model for creating/updating shared resources
class SharedResourceRequest {
  final String resourceType;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;
  final String? area;
  final String? village;
  final bool? functional;
  final int? capacity;
  final int? usersCount;
  final DateTime? lastInspectionDate;
  final String? notes;

  SharedResourceRequest({
    required this.resourceType,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    this.area,
    this.village,
    this.functional,
    this.capacity,
    this.usersCount,
    this.lastInspectionDate,
    this.notes,
  }) : assert(ResourceType.isValid(resourceType),
            'Invalid resource_type. Must be one of: ${ResourceType.values.join(", ")}');

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'resource_type': resourceType,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
    if (description != null) json['description'] = description;
    if (area != null) json['area'] = area;
    if (village != null) json['village'] = village;
    if (functional != null) json['functional'] = functional;
    if (capacity != null) json['capacity'] = capacity;
    if (usersCount != null) json['users_count'] = usersCount;
    if (lastInspectionDate != null) {
      // Format without timezone Z for compatibility
      json['last_inspection_date'] =
          lastInspectionDate!.toIso8601String().replaceAll('Z', '');
    }
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

/// Response for listing shared resources with pagination
class SharedResourceListResponse {
  final bool success;
  final List<SharedResource> data;
  final PaginationInfo pagination;

  SharedResourceListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory SharedResourceListResponse.fromJson(Map<String, dynamic> json) {
    return SharedResourceListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => SharedResource.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

// ==================== DISEASE CASE MODELS ====================

/// Disease case model for community health tracking
class DiseaseCase {
  final String id;
  final String householdId;
  final String? patientId;
  final String? reportedById;
  final String disease;
  final String? diseaseCode;
  final String severity;
  final DateTime caseDate;
  final DateTime? recoveryDate;
  final String status;
  final bool confirmed;
  final String? symptoms;
  final String? treatment;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiseaseCase({
    required this.id,
    required this.householdId,
    this.patientId,
    this.reportedById,
    required this.disease,
    this.diseaseCode,
    this.severity = DiseaseSeverity.mild,
    required this.caseDate,
    this.recoveryDate,
    this.status = DiseaseCaseStatus.active,
    this.confirmed = false,
    this.symptoms,
    this.treatment,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiseaseCase.fromJson(Map<String, dynamic> json) {
    return DiseaseCase(
      id: json['id'] ?? '',
      householdId: json['household_id'] ?? '',
      patientId: json['patient_id'],
      reportedById: json['reported_by_id'],
      disease: json['disease'] ?? '',
      diseaseCode: json['disease_code'],
      severity: json['severity'] ?? DiseaseSeverity.mild,
      caseDate: DateTime.tryParse(json['case_date'] ?? '') ?? DateTime.now(),
      recoveryDate: json['recovery_date'] != null
          ? DateTime.tryParse(json['recovery_date'])
          : null,
      status: json['status'] ?? DiseaseCaseStatus.active,
      confirmed: json['confirmed'] ?? false,
      symptoms: json['symptoms'],
      treatment: json['treatment'],
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'patient_id': patientId,
      'reported_by_id': reportedById,
      'disease': disease,
      'disease_code': diseaseCode,
      'severity': severity,
      'case_date': caseDate.toIso8601String(),
      'recovery_date': recoveryDate?.toIso8601String(),
      'status': status,
      'confirmed': confirmed,
      'symptoms': symptoms,
      'treatment': treatment,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get severityDisplay => DiseaseSeverity.displayName(severity);
  String get statusDisplay => DiseaseCaseStatus.displayName(status);

  bool get isActive => status == DiseaseCaseStatus.active;
  bool get isRecovered => status == DiseaseCaseStatus.recovered;
  bool get isFatal => status == DiseaseCaseStatus.fatal;
  bool get isUnderTreatment => status == DiseaseCaseStatus.underTreatment;
  bool get isSevere => severity == DiseaseSeverity.severe;
}

/// Request model for creating/updating disease cases
class DiseaseCaseRequest {
  final String householdId;
  final String disease;
  final String? patientId;
  final String? diseaseCode;
  final String? severity;
  final DateTime? caseDate;
  final DateTime? recoveryDate;
  final String? status;
  final bool? confirmed;
  final String? symptoms;
  final String? treatment;
  final String? notes;

  DiseaseCaseRequest({
    required this.householdId,
    required this.disease,
    this.patientId,
    this.diseaseCode,
    this.severity,
    this.caseDate,
    this.recoveryDate,
    this.status,
    this.confirmed,
    this.symptoms,
    this.treatment,
    this.notes,
  })  : assert(severity == null || DiseaseSeverity.isValid(severity),
            'Invalid severity. Must be one of: ${DiseaseSeverity.values.join(", ")}'),
        assert(status == null || DiseaseCaseStatus.isValid(status),
            'Invalid status. Must be one of: ${DiseaseCaseStatus.values.join(", ")}');

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'household_id': householdId,
      'disease': disease,
    };
    if (patientId != null) json['patient_id'] = patientId;
    if (diseaseCode != null) json['disease_code'] = diseaseCode;
    if (severity != null) json['severity'] = severity;
    if (caseDate != null) {
      // Format without timezone Z for compatibility
      json['case_date'] = caseDate!.toIso8601String().replaceAll('Z', '');
    }
    if (recoveryDate != null) {
      json['recovery_date'] =
          recoveryDate!.toIso8601String().replaceAll('Z', '');
    }
    if (status != null) json['status'] = status;
    if (confirmed != null) json['confirmed'] = confirmed;
    if (symptoms != null) json['symptoms'] = symptoms;
    if (treatment != null) json['treatment'] = treatment;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

/// Response for listing disease cases with pagination
class DiseaseCaseListResponse {
  final bool success;
  final List<DiseaseCase> data;
  final PaginationInfo pagination;

  DiseaseCaseListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory DiseaseCaseListResponse.fromJson(Map<String, dynamic> json) {
    return DiseaseCaseListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => DiseaseCase.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

// ==================== RISK SCORE SUMMARY ====================

/// Risk score summary for an area
class RiskScoreSummary {
  final String area;
  final int totalHouseholds;
  final double averageRiskScore;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final int totalDiseaseCases;
  final int activeDiseaseCases;

  RiskScoreSummary({
    required this.area,
    this.totalHouseholds = 0,
    this.averageRiskScore = 0.0,
    this.highRiskCount = 0,
    this.mediumRiskCount = 0,
    this.lowRiskCount = 0,
    this.totalDiseaseCases = 0,
    this.activeDiseaseCases = 0,
  });

  factory RiskScoreSummary.fromJson(Map<String, dynamic> json) {
    return RiskScoreSummary(
      area: json['area'] ?? '',
      totalHouseholds: json['total_households'] ?? 0,
      averageRiskScore: (json['average_risk_score'] ?? 0.0).toDouble(),
      highRiskCount: json['high_risk_count'] ?? 0,
      mediumRiskCount: json['medium_risk_count'] ?? 0,
      lowRiskCount: json['low_risk_count'] ?? 0,
      totalDiseaseCases: json['total_disease_cases'] ?? 0,
      activeDiseaseCases: json['active_disease_cases'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'total_households': totalHouseholds,
      'average_risk_score': averageRiskScore,
      'high_risk_count': highRiskCount,
      'medium_risk_count': mediumRiskCount,
      'low_risk_count': lowRiskCount,
      'total_disease_cases': totalDiseaseCases,
      'active_disease_cases': activeDiseaseCases,
    };
  }
}

// ==================== SHARED PAGINATION MODEL ====================

/// Pagination info for list responses
class PaginationInfo {
  final int page;
  final int perPage;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationInfo({
    this.page = 1,
    this.perPage = 20,
    this.totalCount = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrev = false,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'per_page': perPage,
      'total_count': totalCount,
      'total_pages': totalPages,
      'has_next': hasNext,
      'has_prev': hasPrev,
    };
  }
}

// ==================== API EXCEPTION ====================

/// Exception for community API errors
class CommunityApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  CommunityApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'CommunityApiException: $message';
}

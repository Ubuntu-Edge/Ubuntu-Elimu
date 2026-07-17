/// Patient API Models
/// Models for patient CRUD operations with backend API
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

/// Request model for creating a new patient
/// Required: first_name, last_name
class PatientCreateRequest {
  final String firstName;
  final String lastName;
  final String? otherNames;
  final String? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? village;
  final String? address;
  final String? familyId;
  final String? relationshipToHead;
  final String? nationalId;
  final String? maritalStatus;
  final String? healthStatus;
  final bool? isPregnant;
  final String? expectedDeliveryDate;
  final String? lastMenstrualPeriod;
  final int? pregnancyWeek;
  final bool? hasChronicCondition;
  final List<String>? chronicConditions;
  final bool? isHighRisk;
  final List<String>? riskFactors;
  final double? riskScore;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? currentMedications;
  final String? alternativePhone;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinRelationship;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? notes;
  final String? deviceId;

  PatientCreateRequest({
    required this.firstName,
    required this.lastName,
    this.otherNames,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.village,
    this.address,
    this.familyId,
    this.relationshipToHead,
    this.nationalId,
    this.maritalStatus,
    this.healthStatus,
    this.isPregnant,
    this.expectedDeliveryDate,
    this.lastMenstrualPeriod,
    this.pregnancyWeek,
    this.hasChronicCondition,
    this.chronicConditions,
    this.isHighRisk,
    this.riskFactors,
    this.riskScore,
    this.bloodType,
    this.allergies,
    this.currentMedications,
    this.alternativePhone,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinRelationship,
    this.location,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.notes,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'first_name': firstName,
      'last_name': lastName,
    };

    if (otherNames != null) data['other_names'] = otherNames;
    if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
    if (gender != null) data['gender'] = gender;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (village != null) data['village'] = village;
    if (address != null) data['address'] = address;
    if (familyId != null) data['family_id'] = familyId;
    if (relationshipToHead != null)
      data['relationship_to_head'] = relationshipToHead;
    if (nationalId != null) data['national_id'] = nationalId;
    if (maritalStatus != null) data['marital_status'] = maritalStatus;
    if (healthStatus != null) data['health_status'] = healthStatus;
    if (isPregnant != null) data['is_pregnant'] = isPregnant;
    if (expectedDeliveryDate != null)
      data['expected_delivery_date'] = expectedDeliveryDate;
    if (lastMenstrualPeriod != null)
      data['last_menstrual_period'] = lastMenstrualPeriod;
    if (pregnancyWeek != null) data['pregnancy_week'] = pregnancyWeek;
    if (hasChronicCondition != null)
      data['has_chronic_condition'] = hasChronicCondition;
    if (chronicConditions != null)
      data['chronic_conditions'] = chronicConditions;
    if (isHighRisk != null) data['is_high_risk'] = isHighRisk;
    if (riskFactors != null) data['risk_factors'] = riskFactors;
    if (riskScore != null) data['risk_score'] = riskScore;
    if (bloodType != null) data['blood_type'] = bloodType;
    if (allergies != null) data['allergies'] = allergies;
    if (currentMedications != null)
      data['current_medications'] = currentMedications;
    if (alternativePhone != null) data['alternative_phone'] = alternativePhone;
    if (nextOfKinName != null) data['next_of_kin_name'] = nextOfKinName;
    if (nextOfKinPhone != null) data['next_of_kin_phone'] = nextOfKinPhone;
    if (nextOfKinRelationship != null)
      data['next_of_kin_relationship'] = nextOfKinRelationship;
    if (location != null) data['location'] = location;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (photoUrl != null) data['photo_url'] = photoUrl;
    if (notes != null) data['notes'] = notes;
    if (deviceId != null) data['device_id'] = deviceId;

    return data;
  }
}

/// Request model for updating a patient (all fields optional)
class PatientUpdateRequest {
  final String? firstName;
  final String? lastName;
  final String? otherNames;
  final String? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? village;
  final String? address;
  final String? familyId;
  final String? relationshipToHead;
  final String? nationalId;
  final String? maritalStatus;
  final String? healthStatus;
  final bool? isPregnant;
  final String? expectedDeliveryDate;
  final String? lastMenstrualPeriod;
  final int? pregnancyWeek;
  final bool? hasChronicCondition;
  final List<String>? chronicConditions;
  final bool? isHighRisk;
  final List<String>? riskFactors;
  final double? riskScore;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? currentMedications;
  final String? alternativePhone;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinRelationship;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? notes;

  PatientUpdateRequest({
    this.firstName,
    this.lastName,
    this.otherNames,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.village,
    this.address,
    this.familyId,
    this.relationshipToHead,
    this.nationalId,
    this.maritalStatus,
    this.healthStatus,
    this.isPregnant,
    this.expectedDeliveryDate,
    this.lastMenstrualPeriod,
    this.pregnancyWeek,
    this.hasChronicCondition,
    this.chronicConditions,
    this.isHighRisk,
    this.riskFactors,
    this.riskScore,
    this.bloodType,
    this.allergies,
    this.currentMedications,
    this.alternativePhone,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinRelationship,
    this.location,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (otherNames != null) data['other_names'] = otherNames;
    if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
    if (gender != null) data['gender'] = gender;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (village != null) data['village'] = village;
    if (address != null) data['address'] = address;
    if (familyId != null) data['family_id'] = familyId;
    if (relationshipToHead != null)
      data['relationship_to_head'] = relationshipToHead;
    if (nationalId != null) data['national_id'] = nationalId;
    if (maritalStatus != null) data['marital_status'] = maritalStatus;
    if (healthStatus != null) data['health_status'] = healthStatus;
    if (isPregnant != null) data['is_pregnant'] = isPregnant;
    if (expectedDeliveryDate != null)
      data['expected_delivery_date'] = expectedDeliveryDate;
    if (lastMenstrualPeriod != null)
      data['last_menstrual_period'] = lastMenstrualPeriod;
    if (pregnancyWeek != null) data['pregnancy_week'] = pregnancyWeek;
    if (hasChronicCondition != null)
      data['has_chronic_condition'] = hasChronicCondition;
    if (chronicConditions != null)
      data['chronic_conditions'] = chronicConditions;
    if (isHighRisk != null) data['is_high_risk'] = isHighRisk;
    if (riskFactors != null) data['risk_factors'] = riskFactors;
    if (riskScore != null) data['risk_score'] = riskScore;
    if (bloodType != null) data['blood_type'] = bloodType;
    if (allergies != null) data['allergies'] = allergies;
    if (currentMedications != null)
      data['current_medications'] = currentMedications;
    if (alternativePhone != null) data['alternative_phone'] = alternativePhone;
    if (nextOfKinName != null) data['next_of_kin_name'] = nextOfKinName;
    if (nextOfKinPhone != null) data['next_of_kin_phone'] = nextOfKinPhone;
    if (nextOfKinRelationship != null)
      data['next_of_kin_relationship'] = nextOfKinRelationship;
    if (location != null) data['location'] = location;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (photoUrl != null) data['photo_url'] = photoUrl;
    if (notes != null) data['notes'] = notes;

    return data;
  }
}

/// Response model for patient data from API
class PatientResponse {
  final String id;
  final String? chwId;
  final String? familyId;
  final String firstName;
  final String lastName;
  final String? fullName;
  final String? otherNames;
  final String? dateOfBirth;
  final int? age;
  final int? ageInMonths;
  final String? gender;
  final String? phoneNumber;
  final String? village;
  final String? address;
  final String? relationshipToHead;
  final String? nationalId;
  final String? maritalStatus;
  final String? healthStatus;
  final bool? isPregnant;
  final String? expectedDeliveryDate;
  final String? lastMenstrualPeriod;
  final int? pregnancyWeek;
  final bool? hasChronicCondition;
  final List<String>? chronicConditions;
  final bool? isHighRisk;
  final List<String>? riskFactors;
  final double? riskScore;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? currentMedications;
  final String? alternativePhone;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinRelationship;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? notes;
  final String? registeredDate;
  final String? registrationSource;
  final String? createdAt;
  final String? updatedAt;
  final int? syncVersion;
  final String? lastSyncedAt;
  final Map<String, dynamic>? chw;

  PatientResponse({
    required this.id,
    this.chwId,
    this.familyId,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.otherNames,
    this.dateOfBirth,
    this.age,
    this.ageInMonths,
    this.gender,
    this.phoneNumber,
    this.village,
    this.address,
    this.relationshipToHead,
    this.nationalId,
    this.maritalStatus,
    this.healthStatus,
    this.isPregnant,
    this.expectedDeliveryDate,
    this.lastMenstrualPeriod,
    this.pregnancyWeek,
    this.hasChronicCondition,
    this.chronicConditions,
    this.isHighRisk,
    this.riskFactors,
    this.riskScore,
    this.bloodType,
    this.allergies,
    this.currentMedications,
    this.alternativePhone,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinRelationship,
    this.location,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.notes,
    this.registeredDate,
    this.registrationSource,
    this.createdAt,
    this.updatedAt,
    this.syncVersion,
    this.lastSyncedAt,
    this.chw,
  });

  factory PatientResponse.fromJson(Map<String, dynamic> json) {
    return PatientResponse(
      id: json['id'] ?? '',
      chwId: json['chw_id'],
      familyId: json['family_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'],
      otherNames: json['other_names'],
      dateOfBirth: json['date_of_birth'],
      age: json['age'],
      ageInMonths: json['age_in_months'],
      gender: json['gender'],
      phoneNumber: json['phone_number'],
      village: json['village'],
      address: json['address'],
      relationshipToHead: json['relationship_to_head'],
      nationalId: json['national_id'],
      maritalStatus: json['marital_status'],
      healthStatus: json['health_status'],
      isPregnant: json['is_pregnant'],
      expectedDeliveryDate: json['expected_delivery_date'],
      lastMenstrualPeriod: json['last_menstrual_period'],
      pregnancyWeek: json['pregnancy_week'],
      hasChronicCondition: json['has_chronic_condition'],
      chronicConditions: json['chronic_conditions'] != null
          ? List<String>.from(json['chronic_conditions'])
          : null,
      isHighRisk: json['is_high_risk'],
      riskFactors: json['risk_factors'] != null
          ? List<String>.from(json['risk_factors'])
          : null,
      riskScore: json['risk_score']?.toDouble(),
      bloodType: json['blood_type'],
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : null,
      currentMedications: json['current_medications'] != null
          ? List<String>.from(json['current_medications'])
          : null,
      alternativePhone: json['alternative_phone'],
      nextOfKinName: json['next_of_kin_name'],
      nextOfKinPhone: json['next_of_kin_phone'],
      nextOfKinRelationship: json['next_of_kin_relationship'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      photoUrl: json['photo_url'],
      notes: json['notes'],
      registeredDate: json['registered_date'],
      registrationSource: json['registration_source'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      syncVersion: json['sync_version'],
      lastSyncedAt: json['last_synced_at'],
      chw: json['chw'],
    );
  }

  /// Convert to database map for local storage
  /// Only includes fields that exist in the SQLite schema
  Map<String, dynamic> toDbMap() {
    // Use registered_date from API, fallback to created_at, or use current time
    String registeredDate = createdAt ?? DateTime.now().toIso8601String();

    return {
      'id': id,
      'chw_id': chwId,
      'family_id': familyId,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'phone_number': phoneNumber,
      'village': village,
      'address': address,
      'relationship_to_head': relationshipToHead,
      'health_status': healthStatus,
      'is_pregnant': isPregnant == true ? 1 : 0,
      'has_chronic_condition': hasChronicCondition == true ? 1 : 0,
      'chronic_conditions': chronicConditions?.join(','),
      'is_high_risk': isHighRisk == true ? 1 : 0,
      'location': location,
      'photo_path': photoUrl, // Map photo_url to photo_path for local database
      'notes': notes,
      'registered_date': registeredDate,
    };
  }
}

/// Response model for patient summary
class PatientSummaryResponse {
  final String id;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? village;
  final bool? isHighRisk;
  final bool? isPregnant;
  final String? photoUrl;

  PatientSummaryResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.village,
    this.isHighRisk,
    this.isPregnant,
    this.photoUrl,
  });

  factory PatientSummaryResponse.fromJson(Map<String, dynamic> json) {
    return PatientSummaryResponse(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      phoneNumber: json['phone_number'],
      village: json['village'],
      isHighRisk: json['is_high_risk'],
      isPregnant: json['is_pregnant'],
      photoUrl: json['photo_url'],
    );
  }
}

/// Response model for paginated patient list
class PatientListResponse {
  final bool success;
  final List<PatientResponse> data;
  final PaginationMeta pagination;

  PatientListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory PatientListResponse.fromJson(Map<String, dynamic> json) {
    return PatientListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => PatientResponse.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationMeta.fromJson(json['pagination'] ?? {}),
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

/// Exception for patient API errors
class PatientApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<ValidationError>? validationErrors;

  PatientApiException(this.message, {this.statusCode, this.validationErrors});

  @override
  String toString() => 'PatientApiException: $message';
}

/// Validation error from API
class ValidationError {
  final String type;
  final List<String> loc;
  final String msg;
  final dynamic input;

  ValidationError({
    required this.type,
    required this.loc,
    required this.msg,
    this.input,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      type: json['type'] ?? '',
      loc: List<String>.from(json['loc']?.map((e) => e.toString()) ?? []),
      msg: json['msg'] ?? '',
      input: json['input'],
    );
  }
}

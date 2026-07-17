import 'dart:convert';

class Patient {
  final String id;
  final String chwId;
  final String? familyId;
  final String firstName;
  final String lastName;
  final String? otherNames;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? relationshipToHead;
  final String? healthStatus;
  final String? village;
  final String? location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? photoPath;
  final String? notes;
  final bool? isPregnant;
  final int? pregnancyWeek;
  final DateTime? expectedDeliveryDate;
  final bool? hasChronicCondition;
  final String? chronicConditions;
  final bool isHighRisk;
  final String? riskFactors;
  final double? riskScore;
  final String? bloodType;
  final String? allergies;
  final String? currentMedications;
  final String? maritalStatus;
  final String? nationalId;
  final String? alternativePhone;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinRelationship;
  final DateTime registeredDate;

  Patient({
    required this.id,
    required this.chwId,
    this.familyId,
    required this.firstName,
    required this.lastName,
    this.otherNames,
    this.dateOfBirth,
    this.gender,
    this.relationshipToHead,
    this.healthStatus,
    this.village,
    this.location,
    this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.photoPath,
    this.notes,
    this.isPregnant,
    this.pregnancyWeek,
    this.expectedDeliveryDate,
    this.hasChronicCondition,
    this.chronicConditions,
    this.isHighRisk = false,
    this.riskFactors,
    this.riskScore,
    this.bloodType,
    this.allergies,
    this.currentMedications,
    this.maritalStatus,
    this.nationalId,
    this.alternativePhone,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinRelationship,
    required this.registeredDate,
  });

  String get displayId => '$firstName $lastName';

  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get ageDisplay {
    if (dateOfBirth == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(dateOfBirth!);
    if (difference.inDays < 30) {
      return '${difference.inDays} days';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months';
    } else {
      return '$age years';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chw_id': chwId,
      'family_id': familyId,
      'first_name': firstName,
      'last_name': lastName,
      'other_names': otherNames,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'relationship_to_head': relationshipToHead,
      'health_status': healthStatus,
      'village': village,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone_number': phoneNumber,
      'photo_path': photoPath,
      'notes': notes,
      'is_pregnant': isPregnant == true ? 1 : 0,
      'pregnancy_week': pregnancyWeek,
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'has_chronic_condition': hasChronicCondition == true ? 1 : 0,
      'chronic_conditions': chronicConditions,
      'is_high_risk': isHighRisk ? 1 : 0,
      'risk_factors': riskFactors,
      'risk_score': riskScore,
      'blood_type': bloodType,
      'allergies': allergies,
      'current_medications': currentMedications,
      'marital_status': maritalStatus,
      'national_id': nationalId,
      'alternative_phone': alternativePhone,
      'next_of_kin_name': nextOfKinName,
      'next_of_kin_phone': nextOfKinPhone,
      'next_of_kin_relationship': nextOfKinRelationship,
      'registered_date': registeredDate.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      chwId: map['chw_id'],
      familyId: map['family_id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      otherNames: map['other_names'],
      dateOfBirth: map['date_of_birth'] != null ? DateTime.parse(map['date_of_birth']) : null,
      gender: map['gender'],
      relationshipToHead: map['relationship_to_head'],
      healthStatus: map['health_status'],
      village: map['village'],
      location: map['location'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      phoneNumber: map['phone_number'],
      photoPath: map['photo_path'],
      notes: map['notes'],
      isPregnant: map['is_pregnant'] == 1,
      pregnancyWeek: map['pregnancy_week'],
      expectedDeliveryDate: map['expected_delivery_date'] != null ? DateTime.parse(map['expected_delivery_date']) : null,
      hasChronicCondition: map['has_chronic_condition'] == 1,
      chronicConditions: map['chronic_conditions'],
      isHighRisk: map['is_high_risk'] == 1,
      riskFactors: map['risk_factors'],
      riskScore: map['risk_score'],
      bloodType: map['blood_type'],
      allergies: map['allergies'],
      currentMedications: map['current_medications'],
      maritalStatus: map['marital_status'],
      nationalId: map['national_id'],
      alternativePhone: map['alternative_phone'],
      nextOfKinName: map['next_of_kin_name'],
      nextOfKinPhone: map['next_of_kin_phone'],
      nextOfKinRelationship: map['next_of_kin_relationship'],
      registeredDate: DateTime.parse(map['registered_date']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Patient.fromJson(String source) => Patient.fromMap(json.decode(source));

  Patient copyWith({
    String? id,
    String? chwId,
    String? familyId,
    String? firstName,
    String? lastName,
    String? otherNames,
    DateTime? dateOfBirth,
    String? gender,
    String? relationshipToHead,
    String? healthStatus,
    String? village,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? photoPath,
    String? notes,
    bool? isPregnant,
    int? pregnancyWeek,
    DateTime? expectedDeliveryDate,
    bool? hasChronicCondition,
    String? chronicConditions,
    bool? isHighRisk,
    String? riskFactors,
    double? riskScore,
    String? bloodType,
    String? allergies,
    String? currentMedications,
    String? maritalStatus,
    String? nationalId,
    String? alternativePhone,
    String? nextOfKinName,
    String? nextOfKinPhone,
    String? nextOfKinRelationship,
    DateTime? registeredDate,
  }) {
    return Patient(
      id: id ?? this.id,
      chwId: chwId ?? this.chwId,
      familyId: familyId ?? this.familyId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      otherNames: otherNames ?? this.otherNames,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      relationshipToHead: relationshipToHead ?? this.relationshipToHead,
      healthStatus: healthStatus ?? this.healthStatus,
      village: village ?? this.village,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      isPregnant: isPregnant ?? this.isPregnant,
      pregnancyWeek: pregnancyWeek ?? this.pregnancyWeek,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      hasChronicCondition: hasChronicCondition ?? this.hasChronicCondition,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      riskFactors: riskFactors ?? this.riskFactors,
      riskScore: riskScore ?? this.riskScore,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      currentMedications: currentMedications ?? this.currentMedications,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      nationalId: nationalId ?? this.nationalId,
      alternativePhone: alternativePhone ?? this.alternativePhone,
      nextOfKinName: nextOfKinName ?? this.nextOfKinName,
      nextOfKinPhone: nextOfKinPhone ?? this.nextOfKinPhone,
      nextOfKinRelationship: nextOfKinRelationship ?? this.nextOfKinRelationship,
      registeredDate: registeredDate ?? this.registeredDate,
    );
  }
}

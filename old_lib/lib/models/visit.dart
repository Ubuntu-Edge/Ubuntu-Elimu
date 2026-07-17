import 'dart:convert';

/// Allowed values for urgency_level from backend
class UrgencyLevel {
  static const String emergency = 'emergency';
  static const String urgent = 'urgent';
  static const String standard = 'standard';
  static const String low = 'low';
  static const String routine = 'routine';
  
  static const List<String> values = [emergency, urgent, standard, low, routine];
  
  static bool isValid(String? value) => value == null || values.contains(value);
}

/// Allowed values for visit_type from backend
class VisitType {
  static const String homeVisit = 'home_visit';
  static const String followUp = 'follow_up';
  static const String emergency = 'emergency';
  static const String routineCheck = 'routine_check';
  static const String immunization = 'immunization';
  static const String antenatal = 'antenatal';
  static const String postnatal = 'postnatal';
  static const String growthMonitoring = 'growth_monitoring';
  static const String referralFollowUp = 'referral_follow_up';
  static const String chronicCare = 'chronic_care';
  
  static const List<String> values = [
    homeVisit, followUp, emergency, routineCheck, immunization,
    antenatal, postnatal, growthMonitoring, referralFollowUp, chronicCare
  ];
  
  static String getDisplayName(String? type) {
    switch (type) {
      case homeVisit: return 'Home Visit';
      case followUp: return 'Follow Up';
      case emergency: return 'Emergency';
      case routineCheck: return 'Routine Check';
      case immunization: return 'Immunization';
      case antenatal: return 'Antenatal';
      case postnatal: return 'Postnatal';
      case growthMonitoring: return 'Growth Monitoring';
      case referralFollowUp: return 'Referral Follow Up';
      case chronicCare: return 'Chronic Care';
      default: return type ?? 'Unknown';
    }
  }
}

/// Allowed values for symptom_severity from backend
class SymptomSeverity {
  static const String mild = 'mild';
  static const String moderate = 'moderate';
  static const String severe = 'severe';
  
  static const List<String> values = [mild, moderate, severe];
}

/// Allowed values for MUAC color from backend
class MuacColor {
  static const String green = 'green';
  static const String yellow = 'yellow';
  static const String orange = 'orange';
  static const String red = 'red';
  
  static const List<String> values = [green, yellow, orange, red];
}

/// Vitals model for visit measurements
class Vitals {
  final double? temperature;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? pulseRate;
  final int? respiratoryRate;
  final double? oxygenSaturation;
  final double? weight;
  final double? height;
  final double? bmi;
  final double? bloodGlucose;
  final double? muac;
  final String? muacColor;

  Vitals({
    this.temperature,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.pulseRate,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.weight,
    this.height,
    this.bmi,
    this.bloodGlucose,
    this.muac,
    this.muacColor,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (temperature != null) data['temperature'] = temperature;
    if (bloodPressureSystolic != null) data['blood_pressure_systolic'] = bloodPressureSystolic;
    if (bloodPressureDiastolic != null) data['blood_pressure_diastolic'] = bloodPressureDiastolic;
    if (pulseRate != null) data['pulse_rate'] = pulseRate;
    if (respiratoryRate != null) data['respiratory_rate'] = respiratoryRate;
    if (oxygenSaturation != null) data['oxygen_saturation'] = oxygenSaturation;
    if (weight != null) data['weight'] = weight;
    if (height != null) data['height'] = height;
    if (bmi != null) data['bmi'] = bmi;
    if (bloodGlucose != null) data['blood_glucose'] = bloodGlucose;
    if (muac != null) data['muac'] = muac;
    if (muacColor != null) data['muac_color'] = muacColor;
    return data;
  }

  factory Vitals.fromJson(Map<String, dynamic> json) {
    return Vitals(
      temperature: json['temperature']?.toDouble(),
      bloodPressureSystolic: json['blood_pressure_systolic'],
      bloodPressureDiastolic: json['blood_pressure_diastolic'],
      pulseRate: json['pulse_rate'],
      respiratoryRate: json['respiratory_rate'],
      oxygenSaturation: json['oxygen_saturation']?.toDouble(),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      bloodGlucose: json['blood_glucose']?.toDouble(),
      muac: json['muac']?.toDouble(),
      muacColor: json['muac_color'],
    );
  }
  
  bool get isEmpty => temperature == null && bloodPressureSystolic == null &&
      bloodPressureDiastolic == null && pulseRate == null && respiratoryRate == null &&
      oxygenSaturation == null && weight == null && height == null && bmi == null &&
      bloodGlucose == null && muac == null && muacColor == null;
      
  String get bloodPressureDisplay {
    if (bloodPressureSystolic != null && bloodPressureDiastolic != null) {
      return '$bloodPressureSystolic/$bloodPressureDiastolic mmHg';
    }
    return 'N/A';
  }
}

/// Medication given during visit
class MedicationGivenModel {
  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? route;
  final String? notes;

  MedicationGivenModel({
    required this.name,
    this.dosage,
    this.frequency,
    this.duration,
    this.route,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'name': name};
    if (dosage != null) data['dosage'] = dosage;
    if (frequency != null) data['frequency'] = frequency;
    if (duration != null) data['duration'] = duration;
    if (route != null) data['route'] = route;
    if (notes != null) data['notes'] = notes;
    return data;
  }

  factory MedicationGivenModel.fromJson(Map<String, dynamic> json) {
    return MedicationGivenModel(
      name: json['name'] ?? '',
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      route: json['route'],
      notes: json['notes'],
    );
  }
  
  String get displayString {
    final parts = <String>[name];
    if (dosage != null) parts.add(dosage!);
    if (frequency != null) parts.add(frequency!);
    if (duration != null) parts.add('for $duration');
    return parts.join(' - ');
  }
}

class Visit {
  final String? id; // Changed to String to match API UUID format
  final String patientId;
  final DateTime visitDate;
  final String chwId;
  final String? visitType;
  final String? visitLocation;
  final String? chiefComplaint;
  final String? symptoms;
  final List<String>? symptomsList;
  final String? symptomDuration;
  final String? symptomSeverity;
  final String? diagnosis;
  final List<String>? diagnosisCodes;
  final List<String>? differentialDiagnosis;
  final Map<String, dynamic>? aiAssessment;
  final String? treatment;
  final List<MedicationGivenModel>? medicationsGiven;
  final List<String>? proceduresPerformed;
  final String? healthEducation;
  final String urgencyLevel;
  final bool wasReferred;
  final String? referralLocation;
  final String? referralReason;
  final String? outcome;
  final String? patientStatusAfter;
  final DateTime? followUpDate;
  final bool followUpCompleted;
  final String? followUpNotes;
  final Vitals? vitals;
  final String? notes;
  final List<String>? attachments;
  final int? visitDurationMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Visit({
    this.id,
    required this.patientId,
    required this.visitDate,
    required this.chwId,
    this.visitType,
    this.visitLocation,
    this.chiefComplaint,
    this.symptoms,
    this.symptomsList,
    this.symptomDuration,
    this.symptomSeverity,
    this.diagnosis,
    this.diagnosisCodes,
    this.differentialDiagnosis,
    this.aiAssessment,
    this.treatment,
    this.medicationsGiven,
    this.proceduresPerformed,
    this.healthEducation,
    this.urgencyLevel = 'routine',
    this.wasReferred = false,
    this.referralLocation,
    this.referralReason,
    this.outcome,
    this.patientStatusAfter,
    this.followUpDate,
    this.followUpCompleted = false,
    this.followUpNotes,
    this.vitals,
    this.notes,
    this.attachments,
    this.visitDurationMinutes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'visitDate': visitDate.toIso8601String(),
      'chwId': chwId,
      'visitType': visitType,
      'visitLocation': visitLocation,
      'chiefComplaint': chiefComplaint,
      'symptoms': symptoms,
      'symptomsList': symptomsList?.join(','),
      'symptomDuration': symptomDuration,
      'symptomSeverity': symptomSeverity,
      'diagnosis': diagnosis,
      'diagnosisCodes': diagnosisCodes?.join(','),
      'differentialDiagnosis': differentialDiagnosis?.join(','),
      'aiAssessment': aiAssessment != null ? jsonEncode(aiAssessment) : null,
      'treatment': treatment,
      'medicationsGiven': medicationsGiven != null 
          ? jsonEncode(medicationsGiven!.map((m) => m.toJson()).toList()) 
          : null,
      'proceduresPerformed': proceduresPerformed?.join(','),
      'healthEducation': healthEducation,
      'urgencyLevel': urgencyLevel,
      'wasReferred': wasReferred ? 1 : 0,
      'referralLocation': referralLocation,
      'referralReason': referralReason,
      'outcome': outcome,
      'patientStatusAfter': patientStatusAfter,
      'followUpDate': followUpDate?.toIso8601String(),
      'followUpCompleted': followUpCompleted ? 1 : 0,
      'followUpNotes': followUpNotes,
      'vitals': vitals != null ? jsonEncode(vitals!.toJson()) : null,
      'notes': notes,
      'attachments': attachments?.join(','),
      'visitDurationMinutes': visitDurationMinutes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    // Helper to safely parse lists from comma-separated strings
    List<String>? parseList(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return value.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    // Helper to safely parse JSON
    Map<String, dynamic>? parseJson(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return jsonDecode(value.toString()) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    
    // Helper to parse medications list
    List<MedicationGivenModel>? parseMedications(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        final list = jsonDecode(value.toString()) as List;
        return list.map((m) => MedicationGivenModel.fromJson(m)).toList();
      } catch (_) {
        return null;
      }
    }
    
    return Visit(
      id: map['id']?.toString(),
      patientId: map['patientId']?.toString() ?? map['patient_id']?.toString() ?? '',
      visitDate: DateTime.tryParse(map['visitDate']?.toString() ?? map['visit_date']?.toString() ?? '') ?? DateTime.now(),
      chwId: map['chwId']?.toString() ?? map['chw_id']?.toString() ?? '',
      visitType: map['visitType'] ?? map['visit_type'],
      visitLocation: map['visitLocation'] ?? map['visit_location'],
      chiefComplaint: map['chiefComplaint'] ?? map['chief_complaint'],
      symptoms: map['symptoms'],
      symptomsList: parseList(map['symptomsList'] ?? map['symptoms_list']),
      symptomDuration: map['symptomDuration'] ?? map['symptom_duration'],
      symptomSeverity: map['symptomSeverity'] ?? map['symptom_severity'],
      diagnosis: map['diagnosis'],
      diagnosisCodes: parseList(map['diagnosisCodes'] ?? map['diagnosis_codes']),
      differentialDiagnosis: parseList(map['differentialDiagnosis'] ?? map['differential_diagnosis']),
      aiAssessment: parseJson(map['aiAssessment'] ?? map['ai_assessment']),
      treatment: map['treatment'],
      medicationsGiven: parseMedications(map['medicationsGiven'] ?? map['medications_given']),
      proceduresPerformed: parseList(map['proceduresPerformed'] ?? map['procedures_performed']),
      healthEducation: map['healthEducation'] ?? map['health_education'],
      urgencyLevel: map['urgencyLevel']?.toString() ?? map['urgency_level']?.toString() ?? 'routine',
      wasReferred: map['wasReferred'] == 1 || map['wasReferred'] == true || map['was_referred'] == 1 || map['was_referred'] == true,
      referralLocation: map['referralLocation'] ?? map['referral_location'],
      referralReason: map['referralReason'] ?? map['referral_reason'],
      outcome: map['outcome'],
      patientStatusAfter: map['patientStatusAfter'] ?? map['patient_status_after'],
      followUpDate: map['followUpDate'] != null 
          ? DateTime.tryParse(map['followUpDate'].toString())
          : map['follow_up_date'] != null 
              ? DateTime.tryParse(map['follow_up_date'].toString())
              : null,
      followUpCompleted: map['followUpCompleted'] == 1 || map['followUpCompleted'] == true || 
                         map['follow_up_completed'] == 1 || map['follow_up_completed'] == true,
      followUpNotes: map['followUpNotes'] ?? map['follow_up_notes'],
      vitals: map['vitals'] != null 
          ? (map['vitals'] is String ? Vitals.fromJson(parseJson(map['vitals']) ?? {}) : Vitals.fromJson(map['vitals']))
          : null,
      notes: map['notes'],
      attachments: parseList(map['attachments']),
      visitDurationMinutes: map['visitDurationMinutes'] ?? map['visit_duration_minutes'],
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString())
          : map['created_at'] != null 
              ? DateTime.tryParse(map['created_at'].toString())
              : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt'].toString())
          : map['updated_at'] != null 
              ? DateTime.tryParse(map['updated_at'].toString())
              : null,
    );
  }

  // Adding copyWith for easier updates
  Visit copyWith({
    String? id,
    String? patientId,
    DateTime? visitDate,
    String? chwId,
    String? visitType,
    String? visitLocation,
    String? chiefComplaint,
    String? symptoms,
    List<String>? symptomsList,
    String? symptomDuration,
    String? symptomSeverity,
    String? diagnosis,
    List<String>? diagnosisCodes,
    List<String>? differentialDiagnosis,
    Map<String, dynamic>? aiAssessment,
    String? treatment,
    List<MedicationGivenModel>? medicationsGiven,
    List<String>? proceduresPerformed,
    String? healthEducation,
    String? urgencyLevel,
    bool? wasReferred,
    String? referralLocation,
    String? referralReason,
    String? outcome,
    String? patientStatusAfter,
    DateTime? followUpDate,
    bool? followUpCompleted,
    String? followUpNotes,
    Vitals? vitals,
    String? notes,
    List<String>? attachments,
    int? visitDurationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      visitDate: visitDate ?? this.visitDate,
      chwId: chwId ?? this.chwId,
      visitType: visitType ?? this.visitType,
      visitLocation: visitLocation ?? this.visitLocation,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      symptoms: symptoms ?? this.symptoms,
      symptomsList: symptomsList ?? this.symptomsList,
      symptomDuration: symptomDuration ?? this.symptomDuration,
      symptomSeverity: symptomSeverity ?? this.symptomSeverity,
      diagnosis: diagnosis ?? this.diagnosis,
      diagnosisCodes: diagnosisCodes ?? this.diagnosisCodes,
      differentialDiagnosis: differentialDiagnosis ?? this.differentialDiagnosis,
      aiAssessment: aiAssessment ?? this.aiAssessment,
      treatment: treatment ?? this.treatment,
      medicationsGiven: medicationsGiven ?? this.medicationsGiven,
      proceduresPerformed: proceduresPerformed ?? this.proceduresPerformed,
      healthEducation: healthEducation ?? this.healthEducation,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      wasReferred: wasReferred ?? this.wasReferred,
      referralLocation: referralLocation ?? this.referralLocation,
      referralReason: referralReason ?? this.referralReason,
      outcome: outcome ?? this.outcome,
      patientStatusAfter: patientStatusAfter ?? this.patientStatusAfter,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpCompleted: followUpCompleted ?? this.followUpCompleted,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      vitals: vitals ?? this.vitals,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      visitDurationMinutes: visitDurationMinutes ?? this.visitDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to API request format
  Map<String, dynamic> toApiJson() {
    final Map<String, dynamic> data = {
      'patient_id': patientId,
      'visit_date': visitDate.toIso8601String(),
    };
    
    if (visitType != null) data['visit_type'] = visitType;
    if (visitLocation != null) data['visit_location'] = visitLocation;
    if (chiefComplaint != null) data['chief_complaint'] = chiefComplaint;
    if (symptoms != null) data['symptoms'] = symptoms;
    if (symptomsList != null) data['symptoms_list'] = symptomsList;
    if (symptomDuration != null) data['symptom_duration'] = symptomDuration;
    if (symptomSeverity != null) data['symptom_severity'] = symptomSeverity;
    if (diagnosis != null) data['diagnosis'] = diagnosis;
    if (diagnosisCodes != null) data['diagnosis_codes'] = diagnosisCodes;
    if (differentialDiagnosis != null) data['differential_diagnosis'] = differentialDiagnosis;
    if (aiAssessment != null) data['ai_assessment'] = aiAssessment;
    if (treatment != null) data['treatment'] = treatment;
    if (medicationsGiven != null) {
      data['medications_given'] = medicationsGiven!.map((m) => m.toJson()).toList();
    }
    if (proceduresPerformed != null) data['procedures_performed'] = proceduresPerformed;
    if (healthEducation != null) data['health_education'] = healthEducation;
    data['urgency_level'] = urgencyLevel;
    data['was_referred'] = wasReferred;
    if (referralLocation != null) data['referral_location'] = referralLocation;
    if (referralReason != null) data['referral_reason'] = referralReason;
    if (outcome != null) data['outcome'] = outcome;
    if (patientStatusAfter != null) data['patient_status_after'] = patientStatusAfter;
    if (followUpDate != null) data['follow_up_date'] = followUpDate!.toIso8601String().split('T')[0];
    data['follow_up_completed'] = followUpCompleted;
    if (followUpNotes != null) data['follow_up_notes'] = followUpNotes;
    if (vitals != null && !vitals!.isEmpty) data['vitals'] = vitals!.toJson();
    if (notes != null) data['notes'] = notes;
    if (attachments != null) data['attachments'] = attachments;
    if (visitDurationMinutes != null) data['visit_duration_minutes'] = visitDurationMinutes;
    
    return data;
  }
  
  /// Get display-friendly urgency level
  String get urgencyLevelDisplay {
    switch (urgencyLevel.toLowerCase()) {
      case 'emergency': return 'Emergency';
      case 'urgent': return 'Urgent';
      case 'standard': return 'Standard';
      case 'low': return 'Low';
      case 'routine': return 'Routine';
      default: return urgencyLevel;
    }
  }
  
  /// Get visit type display name
  String get visitTypeDisplay => VisitType.getDisplayName(visitType);
  
  /// Get summary of medications given
  String get medicationsSummary {
    if (medicationsGiven == null || medicationsGiven!.isEmpty) return 'None';
    return medicationsGiven!.map((m) => m.name).join(', ');
  }

  @override
  String toString() {
    return 'Visit{id: $id, patientId: $patientId, visitDate: $visitDate, visitType: $visitType, '
        'chiefComplaint: $chiefComplaint, diagnosis: $diagnosis, urgencyLevel: $urgencyLevel, '
        'wasReferred: $wasReferred, followUpDate: $followUpDate}';
  }
}
/// Smart Triage API Service
/// Symptom-based patient prioritization using IMCI and emergency triage protocols
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

// ==================== ENUMS ====================

enum UrgencyLevel {
  emergency,
  urgent,
  semiUrgent,
  nonUrgent,
}

enum TriageCategory {
  red, // Emergency - immediate
  orange, // Urgent - 15 min
  yellow, // Semi-urgent - 60 min
  green, // Non-urgent - 120 min
}

enum ReferralUrgency {
  immediate,
  urgent,
  routine,
  notRequired,
}

// ==================== MODELS ====================

class VitalSigns {
  final double? temperatureC;
  final int? pulseRate;
  final int? respiratoryRate;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? oxygenSaturation;
  final double? weightKg;

  VitalSigns({
    this.temperatureC,
    this.pulseRate,
    this.respiratoryRate,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.oxygenSaturation,
    this.weightKg,
  });

  Map<String, dynamic> toJson() {
    return {
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (pulseRate != null) 'pulse_rate': pulseRate,
      if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
      if (bloodPressureSystolic != null)
        'blood_pressure_systolic': bloodPressureSystolic,
      if (bloodPressureDiastolic != null)
        'blood_pressure_diastolic': bloodPressureDiastolic,
      if (oxygenSaturation != null) 'oxygen_saturation': oxygenSaturation,
      if (weightKg != null) 'weight_kg': weightKg,
    };
  }

  factory VitalSigns.fromJson(Map<String, dynamic> json) {
    return VitalSigns(
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      pulseRate: json['pulse_rate'],
      respiratoryRate: json['respiratory_rate'],
      bloodPressureSystolic: json['blood_pressure_systolic'],
      bloodPressureDiastolic: json['blood_pressure_diastolic'],
      oxygenSaturation: json['oxygen_saturation'],
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
    );
  }
}

class PossibleCondition {
  final String name;
  final double probability;
  final String? description;

  PossibleCondition({
    required this.name,
    required this.probability,
    this.description,
  });

  factory PossibleCondition.fromJson(Map<String, dynamic> json) {
    return PossibleCondition(
      name: json['name'] ?? '',
      probability: (json['probability'] ?? 0).toDouble(),
      description: json['description'],
    );
  }
}

class TriageAssessment {
  final String assessmentId;
  final String patientId;
  final String? visitId;
  final String? chiefComplaint;
  final List<String> symptoms;
  final String? symptomDuration;
  final VitalSigns? vitalSigns;
  final int? patientAgeMonths;
  final bool? isPregnant;
  final UrgencyLevel urgencyLevel;
  final double priorityScore;
  final TriageCategory triageCategory;
  final List<String> redFlags;
  final List<String> dangerSignsPresent;
  final String recommendedAction;
  final String? recommendedFacility;
  final int maxWaitTimeMinutes;
  final bool requiresReferral;
  final ReferralUrgency? referralUrgency;
  final String? referralReason;
  final String? aiReasoning;
  final List<String> guidelinesMatched;
  final List<String> nextSteps;
  final String? assessmentNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TriageAssessment({
    required this.assessmentId,
    required this.patientId,
    this.visitId,
    this.chiefComplaint,
    required this.symptoms,
    this.symptomDuration,
    this.vitalSigns,
    this.patientAgeMonths,
    this.isPregnant,
    required this.urgencyLevel,
    required this.priorityScore,
    required this.triageCategory,
    required this.redFlags,
    required this.dangerSignsPresent,
    required this.recommendedAction,
    this.recommendedFacility,
    required this.maxWaitTimeMinutes,
    required this.requiresReferral,
    this.referralUrgency,
    this.referralReason,
    this.aiReasoning,
    required this.guidelinesMatched,
    required this.nextSteps,
    this.assessmentNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TriageAssessment.fromJson(Map<String, dynamic> json) {
    return TriageAssessment(
      assessmentId: json['assessment_id'] ?? json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      visitId: json['visit_id'],
      chiefComplaint: json['chief_complaint'],
      symptoms: List<String>.from(json['symptoms'] ?? []),
      symptomDuration: json['symptom_duration'],
      vitalSigns: json['vital_signs'] != null
          ? VitalSigns.fromJson(json['vital_signs'])
          : null,
      patientAgeMonths: json['patient_age_months'],
      isPregnant: json['is_pregnant'],
      urgencyLevel: _parseUrgencyLevel(json['urgency_level']),
      priorityScore: (json['priority_score'] ?? 0).toDouble(),
      triageCategory: _parseTriageCategory(json['triage_category']),
      redFlags: List<String>.from(json['red_flags'] ?? []),
      dangerSignsPresent: List<String>.from(json['danger_signs_present'] ?? []),
      recommendedAction: json['recommended_action'] ?? '',
      recommendedFacility: json['recommended_facility'],
      maxWaitTimeMinutes: json['max_wait_time_minutes'] ?? 120,
      requiresReferral: json['requires_referral'] ?? false,
      referralUrgency: _parseReferralUrgency(json['referral_urgency']),
      referralReason: json['referral_reason'],
      aiReasoning: json['ai_reasoning'],
      guidelinesMatched: List<String>.from(json['guidelines_matched'] ?? []),
      nextSteps: List<String>.from(json['next_steps'] ?? []),
      assessmentNotes: json['assessment_notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  static UrgencyLevel _parseUrgencyLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'emergency':
      case 'life_threatening':
        return UrgencyLevel.emergency;
      case 'urgent':
        return UrgencyLevel.urgent;
      case 'semi_urgent':
      case 'semiurgent':
        return UrgencyLevel.semiUrgent;
      case 'non_urgent':
      case 'nonurgent':
      case 'routine':
        return UrgencyLevel.nonUrgent;
      default:
        return UrgencyLevel.nonUrgent;
    }
  }

  static TriageCategory _parseTriageCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'red':
        return TriageCategory.red;
      case 'orange':
        return TriageCategory.orange;
      case 'yellow':
        return TriageCategory.yellow;
      case 'green':
        return TriageCategory.green;
      default:
        return TriageCategory.green;
    }
  }

  static ReferralUrgency? _parseReferralUrgency(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'immediate':
        return ReferralUrgency.immediate;
      case 'urgent':
        return ReferralUrgency.urgent;
      case 'routine':
        return ReferralUrgency.routine;
      case 'not_required':
        return ReferralUrgency.notRequired;
      default:
        return null;
    }
  }
}

class SymptomCheckResult {
  final List<PossibleCondition> possibleConditions;
  final List<String> redFlags;
  final UrgencyLevel urgencyLevel;
  final String recommendedAction;
  final List<String> additionalQuestions;
  final List<String> guidelinesMatched;

  SymptomCheckResult({
    required this.possibleConditions,
    required this.redFlags,
    required this.urgencyLevel,
    required this.recommendedAction,
    required this.additionalQuestions,
    required this.guidelinesMatched,
  });

  factory SymptomCheckResult.fromJson(Map<String, dynamic> json) {
    return SymptomCheckResult(
      possibleConditions: (json['possible_conditions'] as List<dynamic>?)
              ?.map((e) => PossibleCondition.fromJson(e))
              .toList() ??
          [],
      redFlags: List<String>.from(json['red_flags'] ?? []),
      urgencyLevel: TriageAssessment._parseUrgencyLevel(json['urgency_level']),
      recommendedAction: json['recommended_action'] ?? '',
      additionalQuestions:
          List<String>.from(json['additional_questions'] ?? []),
      guidelinesMatched: List<String>.from(json['guidelines_matched'] ?? []),
    );
  }
}

class TriageQueueEntry {
  final String id;
  final String patientId;
  final String patientName;
  final String assessmentId;
  final TriageCategory triageCategory;
  final UrgencyLevel urgencyLevel;
  final String chiefComplaint;
  final int waitTimeMinutes;
  final int queuePosition;
  final DateTime arrivedAt;

  TriageQueueEntry({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.assessmentId,
    required this.triageCategory,
    required this.urgencyLevel,
    required this.chiefComplaint,
    required this.waitTimeMinutes,
    required this.queuePosition,
    required this.arrivedAt,
  });

  factory TriageQueueEntry.fromJson(Map<String, dynamic> json) {
    return TriageQueueEntry(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      assessmentId: json['assessment_id'] ?? '',
      triageCategory:
          TriageAssessment._parseTriageCategory(json['triage_category']),
      urgencyLevel: TriageAssessment._parseUrgencyLevel(json['urgency_level']),
      chiefComplaint: json['chief_complaint'] ?? '',
      waitTimeMinutes: json['wait_time_minutes'] ?? 0,
      queuePosition: json['queue_position'] ?? 0,
      arrivedAt: DateTime.tryParse(json['arrived_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class TriageQueue {
  final List<TriageQueueEntry> items;
  final int totalWaiting;
  final int emergencyCount;
  final int urgentCount;
  final int averageWaitMinutes;

  TriageQueue({
    required this.items,
    required this.totalWaiting,
    required this.emergencyCount,
    required this.urgentCount,
    required this.averageWaitMinutes,
  });

  factory TriageQueue.fromJson(Map<String, dynamic> json) {
    return TriageQueue(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TriageQueueEntry.fromJson(e))
              .toList() ??
          [],
      totalWaiting: json['total_waiting'] ?? 0,
      emergencyCount: json['emergency_count'] ?? 0,
      urgentCount: json['urgent_count'] ?? 0,
      averageWaitMinutes: json['average_wait_minutes'] ?? 0,
    );
  }
}

class TriageGuideline {
  final String id;
  final String title;
  final String category;
  final String? ageGroup;
  final String content;
  final List<String> symptoms;
  final List<String> dangerSigns;
  final String? source;

  TriageGuideline({
    required this.id,
    required this.title,
    required this.category,
    this.ageGroup,
    required this.content,
    required this.symptoms,
    required this.dangerSigns,
    this.source,
  });

  factory TriageGuideline.fromJson(Map<String, dynamic> json) {
    return TriageGuideline(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      ageGroup: json['age_group'],
      content: json['content'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      dangerSigns: List<String>.from(json['danger_signs'] ?? []),
      source: json['source'],
    );
  }
}

class TriageListResponse {
  final List<TriageAssessment> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  TriageListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory TriageListResponse.fromJson(Map<String, dynamic> json) {
    return TriageListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TriageAssessment.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

class TriageStats {
  final int totalAssessments;
  final Map<String, int> byCategory;
  final int referralsNeeded;
  final double averageWaitMinutes;

  TriageStats({
    required this.totalAssessments,
    required this.byCategory,
    required this.referralsNeeded,
    required this.averageWaitMinutes,
  });

  factory TriageStats.fromJson(Map<String, dynamic> json) {
    return TriageStats(
      totalAssessments: json['total_assessments'] ?? 0,
      byCategory: Map<String, int>.from(json['by_category'] ?? {}),
      referralsNeeded: json['referrals_needed'] ?? 0,
      averageWaitMinutes: (json['average_wait_minutes'] ?? 0).toDouble(),
    );
  }
}

// ==================== EXCEPTION ====================

class TriageApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  TriageApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'TriageApiException: $message (status: $statusCode)';
}

// ==================== SERVICE ====================

class TriageApiService {
  static final TriageApiService instance = TriageApiService._internal();
  TriageApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  String _getUrgencyLevelString(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.emergency:
        return 'emergency';
      case UrgencyLevel.urgent:
        return 'urgent';
      case UrgencyLevel.semiUrgent:
        return 'semi_urgent';
      case UrgencyLevel.nonUrgent:
        return 'non_urgent';
    }
  }

  /// Perform triage assessment
  /// POST /triage/assess
  Future<TriageAssessment> performAssessment({
    required String patientId,
    String? visitId,
    String? chiefComplaint,
    required List<String> symptoms,
    String? symptomDuration,
    VitalSigns? vitalSigns,
    int? patientAgeMonths,
    bool? isPregnant,
    List<String>? chronicConditions,
    String? assessmentNotes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'patient_id': patientId,
        'symptoms': symptoms,
      };

      if (visitId != null) body['visit_id'] = visitId;
      if (chiefComplaint != null) body['chief_complaint'] = chiefComplaint;
      if (symptomDuration != null) body['symptom_duration'] = symptomDuration;
      if (vitalSigns != null) body['vital_signs'] = vitalSigns.toJson();
      if (patientAgeMonths != null)
        body['patient_age_months'] = patientAgeMonths;
      if (isPregnant != null) body['is_pregnant'] = isPregnant;
      if (chronicConditions != null)
        body['chronic_conditions'] = chronicConditions;
      if (assessmentNotes != null) body['assessment_notes'] = assessmentNotes;

      final response = await http.post(
        Uri.parse('$_baseUrl/triage/assess'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TriageAssessment.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TriageApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        throw TriageApiException('Validation error: ${response.body}',
            statusCode: 422);
      } else {
        throw TriageApiException(
          'Failed to perform assessment: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TriageApiException) rethrow;
      debugPrint('Error performing assessment: $e');
      throw TriageApiException('Network error: $e');
    }
  }

  /// List triage assessments
  /// GET /triage
  Future<TriageListResponse> listAssessments({
    String? patientId,
    UrgencyLevel? urgencyLevel,
    bool? requiresReferral,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (patientId != null) queryParams['patient_id'] = patientId;
      if (urgencyLevel != null)
        queryParams['urgency_level'] = _getUrgencyLevelString(urgencyLevel);
      if (requiresReferral != null)
        queryParams['requires_referral'] = requiresReferral.toString();

      final uri =
          Uri.parse('$_baseUrl/triage').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TriageListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TriageApiException('Unauthorized', statusCode: 401);
      } else {
        throw TriageApiException(
          'Failed to list assessments: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TriageApiException) rethrow;
      debugPrint('Error listing assessments: $e');
      throw TriageApiException('Network error: $e');
    }
  }

  /// Get assessment by ID
  /// GET /triage/{assessment_id}
  Future<TriageAssessment> getAssessment(String assessmentId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/triage/$assessmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TriageAssessment.fromJson(data);
      } else if (response.statusCode == 404) {
        throw TriageApiException('Assessment not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw TriageApiException('Unauthorized', statusCode: 401);
      } else {
        throw TriageApiException(
          'Failed to get assessment: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TriageApiException) rethrow;
      debugPrint('Error getting assessment: $e');
      throw TriageApiException('Network error: $e');
    }
  }

  /// Quick symptom check without full assessment
  /// POST /triage/symptoms/check
  Future<SymptomCheckResult> quickSymptomCheck({
    required List<String> symptoms,
    int? ageMonths,
    bool? isPregnant,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'symptoms': symptoms,
      };

      if (ageMonths != null) body['age_months'] = ageMonths;
      if (isPregnant != null) body['is_pregnant'] = isPregnant;

      final response = await http.post(
        Uri.parse('$_baseUrl/triage/symptoms/check'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SymptomCheckResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TriageApiException('Unauthorized', statusCode: 401);
      } else {
        throw TriageApiException(
          'Failed to check symptoms: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TriageApiException) rethrow;
      debugPrint('Error checking symptoms: $e');
      throw TriageApiException('Network error: $e');
    }
  }

  /// Get triage queue
  /// GET /triage/queue
  Future<TriageQueue> getQueue({String? facilityId}) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};
      if (facilityId != null) queryParams['facility_id'] = facilityId;

      final uri = Uri.parse('$_baseUrl/triage/queue').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TriageQueue.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TriageApiException('Unauthorized', statusCode: 401);
      } else {
        throw TriageApiException(
          'Failed to get queue: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TriageApiException) rethrow;
      debugPrint('Error getting queue: $e');
      throw TriageApiException('Network error: $e');
    }
  }

  /// Get triage guidelines
  /// GET /triage/guidelines
  Future<List<TriageGuideline>> getGuidelines({
    String? category,
    String? ageGroup,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (ageGroup != null) queryParams['age_group'] = ageGroup;

      final uri = Uri.parse('$_baseUrl/triage/guidelines').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] ?? data;
        return (items as List<dynamic>)
            .map((e) => TriageGuideline.fromJson(e))
            .toList();
      } else if (response.statusCode == 401) {
        throw TriageApiException('Unauthorized', statusCode: 401);
      } else {
        throw TriageApiException(
          'Failed to get guidelines: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TriageApiException) rethrow;
      debugPrint('Error getting guidelines: $e');
      throw TriageApiException('Network error: $e');
    }
  }

  /// Get specific guideline
  /// GET /triage/guidelines/{guideline_id}
  Future<TriageGuideline> getGuideline(String guidelineId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/triage/guidelines/$guidelineId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TriageGuideline.fromJson(data);
      } else if (response.statusCode == 404) {
        throw TriageApiException('Guideline not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw TriageApiException('Unauthorized', statusCode: 401);
      } else {
        throw TriageApiException(
          'Failed to get guideline: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TriageApiException) rethrow;
      debugPrint('Error getting guideline: $e');
      throw TriageApiException('Network error: $e');
    }
  }

  /// Get triage statistics
  /// GET /triage/stats/summary
  Future<TriageStats> getStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/triage/stats/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TriageStats.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TriageApiException('Unauthorized', statusCode: 401);
      } else {
        throw TriageApiException(
          'Failed to get stats: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TriageApiException) rethrow;
      debugPrint('Error getting stats: $e');
      throw TriageApiException('Network error: $e');
    }
  }
}

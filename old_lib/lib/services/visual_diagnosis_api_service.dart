/// Visual Diagnosis API Service
/// AI-assisted visual diagnosis for skin conditions, wounds, eye problems
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

// ==================== ENUMS ====================

enum DiagnosisType {
  skin,
  eye,
  mouth,
  ear,
  wound,
  nail,
}

enum DiagnosisSeverity {
  mild,
  moderate,
  severe,
  critical,
}

enum ImprovementRating {
  muchWorse,
  worse,
  same,
  better,
  muchBetter,
  resolved,
}

enum DiagnosisStatus {
  pending,
  analyzed,
  confirmed,
  treated,
  resolved,
  referredOut,
}

// ==================== MODELS ====================

class MatchedCondition {
  final String name;
  final double probability;
  final String? description;

  MatchedCondition({
    required this.name,
    required this.probability,
    this.description,
  });

  factory MatchedCondition.fromJson(Map<String, dynamic> json) {
    return MatchedCondition(
      name: json['name'] ?? '',
      probability: (json['probability'] ?? 0).toDouble(),
      description: json['description'],
    );
  }
}

class VisualDiagnosisResult {
  final String diagnosisId;
  final String patientId;
  final String? visitId;
  final DiagnosisType diagnosisType;
  final String? bodyLocation;
  final String? chiefComplaint;
  final String? imageUrl;
  final List<MatchedCondition> matchedConditions;
  final double? confidenceScore;
  final List<String> aiSuggestions;
  final List<String> recommendedActions;
  final bool requiresReferral;
  final String? referralReason;
  final DiagnosisSeverity? severity;
  final DiagnosisStatus status;
  final String? chwNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  VisualDiagnosisResult({
    required this.diagnosisId,
    required this.patientId,
    this.visitId,
    required this.diagnosisType,
    this.bodyLocation,
    this.chiefComplaint,
    this.imageUrl,
    required this.matchedConditions,
    this.confidenceScore,
    required this.aiSuggestions,
    required this.recommendedActions,
    required this.requiresReferral,
    this.referralReason,
    this.severity,
    required this.status,
    this.chwNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisualDiagnosisResult.fromJson(Map<String, dynamic> json) {
    return VisualDiagnosisResult(
      diagnosisId: json['diagnosis_id'] ?? json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      visitId: json['visit_id'],
      diagnosisType: _parseDiagnosisType(json['diagnosis_type']),
      bodyLocation: json['body_location'],
      chiefComplaint: json['chief_complaint'],
      imageUrl: json['image_url'],
      matchedConditions: (json['matched_conditions'] as List<dynamic>?)
              ?.map((e) => MatchedCondition.fromJson(e))
              .toList() ??
          [],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      aiSuggestions: List<String>.from(json['ai_suggestions'] ?? []),
      recommendedActions: List<String>.from(json['recommended_actions'] ?? []),
      requiresReferral: json['requires_referral'] ?? false,
      referralReason: json['referral_reason'],
      severity: _parseSeverity(json['severity']),
      status: _parseStatus(json['status']),
      chwNotes: json['chw_notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  static DiagnosisType _parseDiagnosisType(String? type) {
    switch (type?.toLowerCase()) {
      case 'skin':
        return DiagnosisType.skin;
      case 'eye':
        return DiagnosisType.eye;
      case 'mouth':
        return DiagnosisType.mouth;
      case 'ear':
        return DiagnosisType.ear;
      case 'wound':
        return DiagnosisType.wound;
      case 'nail':
        return DiagnosisType.nail;
      default:
        return DiagnosisType.skin;
    }
  }

  static DiagnosisSeverity? _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'mild':
        return DiagnosisSeverity.mild;
      case 'moderate':
        return DiagnosisSeverity.moderate;
      case 'severe':
        return DiagnosisSeverity.severe;
      case 'critical':
        return DiagnosisSeverity.critical;
      default:
        return null;
    }
  }

  static DiagnosisStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return DiagnosisStatus.pending;
      case 'analyzed':
        return DiagnosisStatus.analyzed;
      case 'confirmed':
        return DiagnosisStatus.confirmed;
      case 'treated':
        return DiagnosisStatus.treated;
      case 'resolved':
        return DiagnosisStatus.resolved;
      case 'referred_out':
        return DiagnosisStatus.referredOut;
      default:
        return DiagnosisStatus.pending;
    }
  }
}

class DiagnosisProgress {
  final String id;
  final String diagnosisId;
  final String? notes;
  final ImprovementRating improvementRating;
  final String? followUpImageUrl;
  final DateTime createdAt;

  DiagnosisProgress({
    required this.id,
    required this.diagnosisId,
    this.notes,
    required this.improvementRating,
    this.followUpImageUrl,
    required this.createdAt,
  });

  factory DiagnosisProgress.fromJson(Map<String, dynamic> json) {
    return DiagnosisProgress(
      id: json['id'] ?? '',
      diagnosisId: json['diagnosis_id'] ?? '',
      notes: json['notes'],
      improvementRating: _parseRating(json['improvement_rating']),
      followUpImageUrl: json['follow_up_image_url'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static ImprovementRating _parseRating(String? rating) {
    switch (rating?.toLowerCase()) {
      case 'much_worse':
        return ImprovementRating.muchWorse;
      case 'worse':
        return ImprovementRating.worse;
      case 'same':
        return ImprovementRating.same;
      case 'better':
        return ImprovementRating.better;
      case 'much_better':
        return ImprovementRating.muchBetter;
      case 'resolved':
        return ImprovementRating.resolved;
      default:
        return ImprovementRating.same;
    }
  }
}

class ReferenceImage {
  final String id;
  final String conditionName;
  final String category;
  final String imageUrl;
  final String? description;
  final List<String> symptoms;

  ReferenceImage({
    required this.id,
    required this.conditionName,
    required this.category,
    required this.imageUrl,
    this.description,
    required this.symptoms,
  });

  factory ReferenceImage.fromJson(Map<String, dynamic> json) {
    return ReferenceImage(
      id: json['id'] ?? '',
      conditionName: json['condition_name'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
      description: json['description'],
      symptoms: List<String>.from(json['symptoms'] ?? []),
    );
  }
}

class DiagnosisListResponse {
  final List<VisualDiagnosisResult> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  DiagnosisListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory DiagnosisListResponse.fromJson(Map<String, dynamic> json) {
    return DiagnosisListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => VisualDiagnosisResult.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

class DiagnosisStats {
  final int totalDiagnoses;
  final Map<String, int> byType;
  final int referralsNeeded;
  final double referralRate;

  DiagnosisStats({
    required this.totalDiagnoses,
    required this.byType,
    required this.referralsNeeded,
    required this.referralRate,
  });

  factory DiagnosisStats.fromJson(Map<String, dynamic> json) {
    return DiagnosisStats(
      totalDiagnoses: json['total_diagnoses'] ?? 0,
      byType: Map<String, int>.from(json['by_type'] ?? {}),
      referralsNeeded: json['referrals_needed'] ?? 0,
      referralRate: (json['referral_rate'] ?? 0).toDouble(),
    );
  }
}

// ==================== EXCEPTION ====================

class VisualDiagnosisApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  VisualDiagnosisApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() =>
      'VisualDiagnosisApiException: $message (status: $statusCode)';
}

// ==================== SERVICE ====================

class VisualDiagnosisApiService {
  static final VisualDiagnosisApiService instance =
      VisualDiagnosisApiService._internal();
  VisualDiagnosisApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  String _getDiagnosisTypeString(DiagnosisType type) {
    switch (type) {
      case DiagnosisType.skin:
        return 'skin';
      case DiagnosisType.eye:
        return 'eye';
      case DiagnosisType.mouth:
        return 'mouth';
      case DiagnosisType.ear:
        return 'ear';
      case DiagnosisType.wound:
        return 'wound';
      case DiagnosisType.nail:
        return 'nail';
    }
  }

  String _getImprovementRatingString(ImprovementRating rating) {
    switch (rating) {
      case ImprovementRating.muchWorse:
        return 'much_worse';
      case ImprovementRating.worse:
        return 'worse';
      case ImprovementRating.same:
        return 'same';
      case ImprovementRating.better:
        return 'better';
      case ImprovementRating.muchBetter:
        return 'much_better';
      case ImprovementRating.resolved:
        return 'resolved';
    }
  }

  /// Analyze image for AI-assisted diagnosis
  /// POST /visual-diagnosis/analyze
  Future<VisualDiagnosisResult> analyzeImage({
    required String patientId,
    String? visitId,
    required DiagnosisType diagnosisType,
    String? bodyLocation,
    String? chiefComplaint,
    required String imageBase64,
    Map<String, dynamic>? photoMetadata,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'patient_id': patientId,
        'diagnosis_type': _getDiagnosisTypeString(diagnosisType),
        'image_data': imageBase64,
      };

      if (visitId != null) body['visit_id'] = visitId;
      if (bodyLocation != null) body['body_location'] = bodyLocation;
      if (chiefComplaint != null) body['chief_complaint'] = chiefComplaint;
      if (photoMetadata != null) body['photo_metadata'] = photoMetadata;

      final response = await http.post(
        Uri.parse('$_baseUrl/visual-diagnosis/analyze'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return VisualDiagnosisResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw VisualDiagnosisApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        throw VisualDiagnosisApiException('Validation error: ${response.body}',
            statusCode: 422);
      } else {
        throw VisualDiagnosisApiException(
          'Failed to analyze image: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisualDiagnosisApiException) rethrow;
      debugPrint('Error analyzing image: $e');
      throw VisualDiagnosisApiException('Network error: $e');
    }
  }

  /// Create diagnosis record without AI analysis
  /// POST /visual-diagnosis
  Future<VisualDiagnosisResult> createDiagnosis({
    required String patientId,
    String? visitId,
    required DiagnosisType diagnosisType,
    String? bodyLocation,
    String? chiefComplaint,
    String? imageUrl,
    List<String>? matchedConditions,
    String? chwNotes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'patient_id': patientId,
        'diagnosis_type': _getDiagnosisTypeString(diagnosisType),
      };

      if (visitId != null) body['visit_id'] = visitId;
      if (bodyLocation != null) body['body_location'] = bodyLocation;
      if (chiefComplaint != null) body['chief_complaint'] = chiefComplaint;
      if (imageUrl != null) body['image_url'] = imageUrl;
      if (matchedConditions != null)
        body['matched_conditions'] = matchedConditions;
      if (chwNotes != null) body['chw_notes'] = chwNotes;

      final response = await http.post(
        Uri.parse('$_baseUrl/visual-diagnosis'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return VisualDiagnosisResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw VisualDiagnosisApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisualDiagnosisApiException(
          'Failed to create diagnosis: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisualDiagnosisApiException) rethrow;
      debugPrint('Error creating diagnosis: $e');
      throw VisualDiagnosisApiException('Network error: $e');
    }
  }

  /// List diagnoses with filters
  /// GET /visual-diagnosis
  Future<DiagnosisListResponse> listDiagnoses({
    String? patientId,
    DiagnosisType? diagnosisType,
    DiagnosisStatus? status,
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
      if (diagnosisType != null)
        queryParams['diagnosis_type'] = _getDiagnosisTypeString(diagnosisType);
      if (status != null) queryParams['status'] = status.name;
      if (requiresReferral != null)
        queryParams['requires_referral'] = requiresReferral.toString();

      final uri = Uri.parse('$_baseUrl/visual-diagnosis')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiagnosisListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw VisualDiagnosisApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisualDiagnosisApiException(
          'Failed to list diagnoses: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisualDiagnosisApiException) rethrow;
      debugPrint('Error listing diagnoses: $e');
      throw VisualDiagnosisApiException('Network error: $e');
    }
  }

  /// Get diagnosis by ID
  /// GET /visual-diagnosis/{diagnosis_id}
  Future<VisualDiagnosisResult> getDiagnosis(String diagnosisId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/visual-diagnosis/$diagnosisId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VisualDiagnosisResult.fromJson(data);
      } else if (response.statusCode == 404) {
        throw VisualDiagnosisApiException('Diagnosis not found',
            statusCode: 404);
      } else if (response.statusCode == 401) {
        throw VisualDiagnosisApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisualDiagnosisApiException(
          'Failed to get diagnosis: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisualDiagnosisApiException) rethrow;
      debugPrint('Error getting diagnosis: $e');
      throw VisualDiagnosisApiException('Network error: $e');
    }
  }

  /// Add progress record
  /// POST /visual-diagnosis/{diagnosis_id}/progress
  Future<DiagnosisProgress> addProgress({
    required String diagnosisId,
    String? notes,
    required ImprovementRating improvementRating,
    String? followUpImageUrl,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'improvement_rating': _getImprovementRatingString(improvementRating),
      };

      if (notes != null) body['notes'] = notes;
      if (followUpImageUrl != null)
        body['follow_up_image_url'] = followUpImageUrl;

      final response = await http.post(
        Uri.parse('$_baseUrl/visual-diagnosis/$diagnosisId/progress'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return DiagnosisProgress.fromJson(data);
      } else if (response.statusCode == 401) {
        throw VisualDiagnosisApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisualDiagnosisApiException(
          'Failed to add progress: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisualDiagnosisApiException) rethrow;
      debugPrint('Error adding progress: $e');
      throw VisualDiagnosisApiException('Network error: $e');
    }
  }

  /// Get progress history
  /// GET /visual-diagnosis/{diagnosis_id}/progress
  Future<List<DiagnosisProgress>> getProgressHistory(String diagnosisId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/visual-diagnosis/$diagnosisId/progress'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] ?? data;
        return (items as List<dynamic>)
            .map((e) => DiagnosisProgress.fromJson(e))
            .toList();
      } else if (response.statusCode == 401) {
        throw VisualDiagnosisApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisualDiagnosisApiException(
          'Failed to get progress history: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisualDiagnosisApiException) rethrow;
      debugPrint('Error getting progress history: $e');
      throw VisualDiagnosisApiException('Network error: $e');
    }
  }

  /// Get reference images
  /// GET /visual-diagnosis/references
  Future<List<ReferenceImage>> getReferenceImages({
    String? category,
    String? condition,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};

      if (category != null) queryParams['category'] = category;
      if (condition != null) queryParams['condition'] = condition;

      final uri = Uri.parse('$_baseUrl/visual-diagnosis/references').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] ?? data;
        return (items as List<dynamic>)
            .map((e) => ReferenceImage.fromJson(e))
            .toList();
      } else if (response.statusCode == 401) {
        throw VisualDiagnosisApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisualDiagnosisApiException(
          'Failed to get reference images: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisualDiagnosisApiException) rethrow;
      debugPrint('Error getting reference images: $e');
      throw VisualDiagnosisApiException('Network error: $e');
    }
  }

  /// Get diagnosis statistics
  /// GET /visual-diagnosis/stats/summary
  Future<DiagnosisStats> getStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/visual-diagnosis/stats/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiagnosisStats.fromJson(data);
      } else if (response.statusCode == 401) {
        throw VisualDiagnosisApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisualDiagnosisApiException(
          'Failed to get stats: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisualDiagnosisApiException) rethrow;
      debugPrint('Error getting stats: $e');
      throw VisualDiagnosisApiException('Network error: $e');
    }
  }
}

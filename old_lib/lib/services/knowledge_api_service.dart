/// Knowledge Pocket API Service
/// Clinical guidelines, danger signs, drug dosing, and referral criteria
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

// ==================== ENUMS ====================

enum KnowledgeCategory {
  maternal,
  child,
  nutrition,
  communicableDiseases,
  nonCommunicable,
  emergency,
  mentalHealth,
  reproductive,
  immunization,
  waterSanitation,
}

enum TargetAudience {
  chw,
  patient,
  caregiver,
  all,
}

enum AgeGroup {
  newborn,
  infant,
  child,
  adolescent,
  adult,
  elderly,
  all,
}

enum DangerSignSeverity {
  critical,
  high,
  moderate,
  low,
}

enum DrugClass {
  antibiotic,
  antimalarial,
  analgesic,
  antiemetic,
  antidiarrheal,
  antihypertensive,
  antidiabetic,
  vitamin,
  ors,
  other,
}

enum AdministrationRoute {
  oral,
  intramuscular,
  intravenous,
  topical,
  rectal,
  subcutaneous,
  inhaled,
}

enum FacilityLevel {
  community,
  healthCenter,
  districtHospital,
  regionalHospital,
  nationalHospital,
}

// ==================== MODELS ====================

class KnowledgeGuideline {
  final String id;
  final String title;
  final KnowledgeCategory category;
  final String? subcategory;
  final String content;
  final String? summary;
  final TargetAudience targetAudience;
  final AgeGroup? ageGroup;
  final List<String> keywords;
  final int viewCount;
  final bool isBookmarked;
  final String? source;
  final String? version;
  final DateTime? lastUpdated;
  final DateTime createdAt;

  KnowledgeGuideline({
    required this.id,
    required this.title,
    required this.category,
    this.subcategory,
    required this.content,
    this.summary,
    required this.targetAudience,
    this.ageGroup,
    required this.keywords,
    required this.viewCount,
    required this.isBookmarked,
    this.source,
    this.version,
    this.lastUpdated,
    required this.createdAt,
  });

  factory KnowledgeGuideline.fromJson(Map<String, dynamic> json) {
    return KnowledgeGuideline(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: _parseCategory(json['category']),
      subcategory: json['subcategory'],
      content: json['content'] ?? '',
      summary: json['summary'],
      targetAudience: _parseTargetAudience(json['target_audience']),
      ageGroup: _parseAgeGroup(json['age_group']),
      keywords: List<String>.from(json['keywords'] ?? []),
      viewCount: json['view_count'] ?? 0,
      isBookmarked: json['is_bookmarked'] ?? false,
      source: json['source'],
      version: json['version'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static KnowledgeCategory _parseCategory(String? category) {
    switch (category?.toLowerCase().replaceAll('_', '')) {
      case 'maternal':
        return KnowledgeCategory.maternal;
      case 'child':
        return KnowledgeCategory.child;
      case 'nutrition':
        return KnowledgeCategory.nutrition;
      case 'communicablediseases':
        return KnowledgeCategory.communicableDiseases;
      case 'noncommunicable':
        return KnowledgeCategory.nonCommunicable;
      case 'emergency':
        return KnowledgeCategory.emergency;
      case 'mentalhealth':
        return KnowledgeCategory.mentalHealth;
      case 'reproductive':
        return KnowledgeCategory.reproductive;
      case 'immunization':
        return KnowledgeCategory.immunization;
      case 'watersanitation':
        return KnowledgeCategory.waterSanitation;
      default:
        return KnowledgeCategory.communicableDiseases;
    }
  }

  static TargetAudience _parseTargetAudience(String? audience) {
    switch (audience?.toLowerCase()) {
      case 'chw':
        return TargetAudience.chw;
      case 'patient':
        return TargetAudience.patient;
      case 'caregiver':
        return TargetAudience.caregiver;
      case 'all':
        return TargetAudience.all;
      default:
        return TargetAudience.chw;
    }
  }

  static AgeGroup? _parseAgeGroup(String? ageGroup) {
    switch (ageGroup?.toLowerCase()) {
      case 'newborn':
        return AgeGroup.newborn;
      case 'infant':
        return AgeGroup.infant;
      case 'child':
        return AgeGroup.child;
      case 'adolescent':
        return AgeGroup.adolescent;
      case 'adult':
        return AgeGroup.adult;
      case 'elderly':
        return AgeGroup.elderly;
      case 'all':
        return AgeGroup.all;
      default:
        return null;
    }
  }
}

class DangerSign {
  final String id;
  final String signName;
  final String description;
  final KnowledgeCategory category;
  final AgeGroup? ageGroup;
  final DangerSignSeverity severity;
  final List<String> recognitionTips;
  final List<String> immediateActions;
  final bool referralNeeded;
  final String? referralUrgency;
  final String? relatedConditions;
  final DateTime createdAt;

  DangerSign({
    required this.id,
    required this.signName,
    required this.description,
    required this.category,
    this.ageGroup,
    required this.severity,
    required this.recognitionTips,
    required this.immediateActions,
    required this.referralNeeded,
    this.referralUrgency,
    this.relatedConditions,
    required this.createdAt,
  });

  factory DangerSign.fromJson(Map<String, dynamic> json) {
    return DangerSign(
      id: json['id'] ?? '',
      signName: json['sign_name'] ?? '',
      description: json['description'] ?? '',
      category: KnowledgeGuideline._parseCategory(json['category']),
      ageGroup: KnowledgeGuideline._parseAgeGroup(json['age_group']),
      severity: _parseSeverity(json['severity']),
      recognitionTips: List<String>.from(json['recognition_tips'] ?? []),
      immediateActions: List<String>.from(json['immediate_actions'] ?? []),
      referralNeeded: json['referral_needed'] ?? true,
      referralUrgency: json['referral_urgency'],
      relatedConditions: json['related_conditions'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static DangerSignSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return DangerSignSeverity.critical;
      case 'high':
        return DangerSignSeverity.high;
      case 'moderate':
        return DangerSignSeverity.moderate;
      case 'low':
        return DangerSignSeverity.low;
      default:
        return DangerSignSeverity.moderate;
    }
  }
}

class DrugDosingGuideline {
  final String id;
  final String drugName;
  final String? genericName;
  final DrugClass drugClass;
  final List<String> indications;
  final Map<String, dynamic> dosingGuidelines;
  final AdministrationRoute administrationRoute;
  final List<String> sideEffects;
  final List<String> contraindications;
  final List<String> interactions;
  final String? storageRequirements;
  final String? notes;
  final DateTime createdAt;

  DrugDosingGuideline({
    required this.id,
    required this.drugName,
    this.genericName,
    required this.drugClass,
    required this.indications,
    required this.dosingGuidelines,
    required this.administrationRoute,
    required this.sideEffects,
    required this.contraindications,
    required this.interactions,
    this.storageRequirements,
    this.notes,
    required this.createdAt,
  });

  factory DrugDosingGuideline.fromJson(Map<String, dynamic> json) {
    return DrugDosingGuideline(
      id: json['id'] ?? '',
      drugName: json['drug_name'] ?? '',
      genericName: json['generic_name'],
      drugClass: _parseDrugClass(json['drug_class']),
      indications: List<String>.from(json['indications'] ?? []),
      dosingGuidelines:
          Map<String, dynamic>.from(json['dosing_guidelines'] ?? {}),
      administrationRoute: _parseRoute(json['administration_route']),
      sideEffects: List<String>.from(json['side_effects'] ?? []),
      contraindications: List<String>.from(json['contraindications'] ?? []),
      interactions: List<String>.from(json['interactions'] ?? []),
      storageRequirements: json['storage_requirements'],
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static DrugClass _parseDrugClass(String? drugClass) {
    switch (drugClass?.toLowerCase()) {
      case 'antibiotic':
        return DrugClass.antibiotic;
      case 'antimalarial':
        return DrugClass.antimalarial;
      case 'analgesic':
        return DrugClass.analgesic;
      case 'antiemetic':
        return DrugClass.antiemetic;
      case 'antidiarrheal':
        return DrugClass.antidiarrheal;
      case 'antihypertensive':
        return DrugClass.antihypertensive;
      case 'antidiabetic':
        return DrugClass.antidiabetic;
      case 'vitamin':
        return DrugClass.vitamin;
      case 'ors':
        return DrugClass.ors;
      default:
        return DrugClass.other;
    }
  }

  static AdministrationRoute _parseRoute(String? route) {
    switch (route?.toLowerCase()) {
      case 'oral':
        return AdministrationRoute.oral;
      case 'intramuscular':
        return AdministrationRoute.intramuscular;
      case 'intravenous':
        return AdministrationRoute.intravenous;
      case 'topical':
        return AdministrationRoute.topical;
      case 'rectal':
        return AdministrationRoute.rectal;
      case 'subcutaneous':
        return AdministrationRoute.subcutaneous;
      case 'inhaled':
        return AdministrationRoute.inhaled;
      default:
        return AdministrationRoute.oral;
    }
  }
}

class DrugDoseCalculation {
  final String drugName;
  final double patientWeightKg;
  final int? patientAgeMonths;
  final String recommendedDose;
  final String dosePerKg;
  final String frequency;
  final String? formulation;
  final List<String> warnings;
  final String? calculationNotes;

  DrugDoseCalculation({
    required this.drugName,
    required this.patientWeightKg,
    this.patientAgeMonths,
    required this.recommendedDose,
    required this.dosePerKg,
    required this.frequency,
    this.formulation,
    required this.warnings,
    this.calculationNotes,
  });

  factory DrugDoseCalculation.fromJson(Map<String, dynamic> json) {
    return DrugDoseCalculation(
      drugName: json['drug_name'] ?? '',
      patientWeightKg: (json['patient_weight_kg'] ?? 0).toDouble(),
      patientAgeMonths: json['patient_age_months'],
      recommendedDose: json['recommended_dose'] ?? '',
      dosePerKg: json['dose_per_kg'] ?? '',
      frequency: json['frequency'] ?? '',
      formulation: json['formulation'],
      warnings: List<String>.from(json['warnings'] ?? []),
      calculationNotes: json['calculation_notes'],
    );
  }
}

class ReferralCriteria {
  final String id;
  final String conditionName;
  final String conditionCategory;
  final List<String> immediateReferralSigns;
  final List<String> urgentReferralSigns;
  final List<String> preReferralActions;
  final FacilityLevel facilityLevelRequired;
  final String? transportationNotes;
  final String? additionalNotes;
  final DateTime createdAt;

  ReferralCriteria({
    required this.id,
    required this.conditionName,
    required this.conditionCategory,
    required this.immediateReferralSigns,
    required this.urgentReferralSigns,
    required this.preReferralActions,
    required this.facilityLevelRequired,
    this.transportationNotes,
    this.additionalNotes,
    required this.createdAt,
  });

  factory ReferralCriteria.fromJson(Map<String, dynamic> json) {
    return ReferralCriteria(
      id: json['id'] ?? '',
      conditionName: json['condition_name'] ?? '',
      conditionCategory: json['condition_category'] ?? '',
      immediateReferralSigns:
          List<String>.from(json['immediate_referral_signs'] ?? []),
      urgentReferralSigns:
          List<String>.from(json['urgent_referral_signs'] ?? []),
      preReferralActions: List<String>.from(json['pre_referral_actions'] ?? []),
      facilityLevelRequired:
          _parseFacilityLevel(json['facility_level_required']),
      transportationNotes: json['transportation_notes'],
      additionalNotes: json['additional_notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static FacilityLevel _parseFacilityLevel(String? level) {
    switch (level?.toLowerCase().replaceAll('_', '').replaceAll(' ', '')) {
      case 'community':
        return FacilityLevel.community;
      case 'healthcenter':
        return FacilityLevel.healthCenter;
      case 'districthospital':
        return FacilityLevel.districtHospital;
      case 'regionalhospital':
        return FacilityLevel.regionalHospital;
      case 'nationalhospital':
        return FacilityLevel.nationalHospital;
      default:
        return FacilityLevel.healthCenter;
    }
  }
}

class KnowledgeBookmark {
  final String id;
  final String guidelineId;
  final String? notes;
  final DateTime createdAt;

  KnowledgeBookmark({
    required this.id,
    required this.guidelineId,
    this.notes,
    required this.createdAt,
  });

  factory KnowledgeBookmark.fromJson(Map<String, dynamic> json) {
    return KnowledgeBookmark(
      id: json['id'] ?? '',
      guidelineId: json['guideline_id'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class KnowledgeCategoryInfo {
  final String name;
  final String displayName;
  final String icon;
  final int itemCount;

  KnowledgeCategoryInfo({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.itemCount,
  });

  factory KnowledgeCategoryInfo.fromJson(Map<String, dynamic> json) {
    return KnowledgeCategoryInfo(
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      icon: json['icon'] ?? 'article',
      itemCount: json['item_count'] ?? 0,
    );
  }
}

class GuidelineListResponse {
  final List<KnowledgeGuideline> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;
  final List<String>? categories;

  GuidelineListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
    this.categories,
  });

  factory GuidelineListResponse.fromJson(Map<String, dynamic> json) {
    return GuidelineListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => KnowledgeGuideline.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : null,
    );
  }
}

class DangerSignListResponse {
  final List<DangerSign> items;
  final int total;
  final Map<String, int>? bySeverity;

  DangerSignListResponse({
    required this.items,
    required this.total,
    this.bySeverity,
  });

  factory DangerSignListResponse.fromJson(Map<String, dynamic> json) {
    return DangerSignListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => DangerSign.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      bySeverity: json['by_severity'] != null
          ? Map<String, int>.from(json['by_severity'])
          : null,
    );
  }
}

class DrugListResponse {
  final List<DrugDosingGuideline> items;
  final int total;
  final List<String>? drugClasses;

  DrugListResponse({
    required this.items,
    required this.total,
    this.drugClasses,
  });

  factory DrugListResponse.fromJson(Map<String, dynamic> json) {
    return DrugListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => DrugDosingGuideline.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      drugClasses: json['drug_classes'] != null
          ? List<String>.from(json['drug_classes'])
          : null,
    );
  }
}

class KnowledgeSyncResponse {
  final DateTime syncTimestamp;
  final List<KnowledgeGuideline> guidelines;
  final List<DangerSign> dangerSigns;
  final List<DrugDosingGuideline> drugDosing;
  final List<ReferralCriteria> referralCriteria;
  final int totalItems;
  final int newItems;
  final int updatedItems;

  KnowledgeSyncResponse({
    required this.syncTimestamp,
    required this.guidelines,
    required this.dangerSigns,
    required this.drugDosing,
    required this.referralCriteria,
    required this.totalItems,
    required this.newItems,
    required this.updatedItems,
  });

  factory KnowledgeSyncResponse.fromJson(Map<String, dynamic> json) {
    return KnowledgeSyncResponse(
      syncTimestamp:
          DateTime.tryParse(json['sync_timestamp'] ?? '') ?? DateTime.now(),
      guidelines: (json['guidelines'] as List<dynamic>?)
              ?.map((e) => KnowledgeGuideline.fromJson(e))
              .toList() ??
          [],
      dangerSigns: (json['danger_signs'] as List<dynamic>?)
              ?.map((e) => DangerSign.fromJson(e))
              .toList() ??
          [],
      drugDosing: (json['drug_dosing'] as List<dynamic>?)
              ?.map((e) => DrugDosingGuideline.fromJson(e))
              .toList() ??
          [],
      referralCriteria: (json['referral_criteria'] as List<dynamic>?)
              ?.map((e) => ReferralCriteria.fromJson(e))
              .toList() ??
          [],
      totalItems: json['total_items'] ?? 0,
      newItems: json['new_items'] ?? 0,
      updatedItems: json['updated_items'] ?? 0,
    );
  }
}

// ==================== EXCEPTION ====================

class KnowledgeApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  KnowledgeApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'KnowledgeApiException: $message (status: $statusCode)';
}

// ==================== SERVICE ====================

class KnowledgeApiService {
  static final KnowledgeApiService instance = KnowledgeApiService._internal();
  KnowledgeApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  String _getCategoryString(KnowledgeCategory category) {
    switch (category) {
      case KnowledgeCategory.maternal:
        return 'maternal';
      case KnowledgeCategory.child:
        return 'child';
      case KnowledgeCategory.nutrition:
        return 'nutrition';
      case KnowledgeCategory.communicableDiseases:
        return 'communicable_diseases';
      case KnowledgeCategory.nonCommunicable:
        return 'non_communicable';
      case KnowledgeCategory.emergency:
        return 'emergency';
      case KnowledgeCategory.mentalHealth:
        return 'mental_health';
      case KnowledgeCategory.reproductive:
        return 'reproductive';
      case KnowledgeCategory.immunization:
        return 'immunization';
      case KnowledgeCategory.waterSanitation:
        return 'water_sanitation';
    }
  }

  String _getAgeGroupString(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.newborn:
        return 'newborn';
      case AgeGroup.infant:
        return 'infant';
      case AgeGroup.child:
        return 'child';
      case AgeGroup.adolescent:
        return 'adolescent';
      case AgeGroup.adult:
        return 'adult';
      case AgeGroup.elderly:
        return 'elderly';
      case AgeGroup.all:
        return 'all';
    }
  }

  // ==================== GUIDELINES ====================

  /// List guidelines
  /// GET /knowledge/guidelines
  Future<GuidelineListResponse> listGuidelines({
    KnowledgeCategory? category,
    String? subcategory,
    TargetAudience? targetAudience,
    AgeGroup? ageGroup,
    String? query,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (category != null)
        queryParams['category'] = _getCategoryString(category);
      if (subcategory != null) queryParams['subcategory'] = subcategory;
      if (targetAudience != null)
        queryParams['target_audience'] = targetAudience.name;
      if (ageGroup != null)
        queryParams['age_group'] = _getAgeGroupString(ageGroup);
      if (query != null && query.isNotEmpty) queryParams['q'] = query;

      final uri = Uri.parse('$_baseUrl/knowledge/guidelines')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GuidelineListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to list guidelines: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error listing guidelines: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  /// Search guidelines
  /// POST /knowledge/guidelines/search
  Future<GuidelineListResponse> searchGuidelines({
    required String query,
    KnowledgeCategory? category,
    AgeGroup? ageGroup,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'query': query,
        'page': page,
        'per_page': perPage,
      };

      if (category != null) body['category'] = _getCategoryString(category);
      if (ageGroup != null) body['age_group'] = _getAgeGroupString(ageGroup);

      final response = await http.post(
        Uri.parse('$_baseUrl/knowledge/guidelines/search'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GuidelineListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to search guidelines: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error searching guidelines: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  /// Get guideline by ID
  /// GET /knowledge/guidelines/{guideline_id}
  Future<KnowledgeGuideline> getGuideline(String guidelineId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/knowledge/guidelines/$guidelineId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return KnowledgeGuideline.fromJson(data);
      } else if (response.statusCode == 404) {
        throw KnowledgeApiException('Guideline not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to get guideline: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error getting guideline: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  // ==================== DANGER SIGNS ====================

  /// List danger signs
  /// GET /knowledge/danger-signs
  Future<DangerSignListResponse> listDangerSigns({
    KnowledgeCategory? category,
    AgeGroup? ageGroup,
    DangerSignSeverity? severity,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (category != null)
        queryParams['category'] = _getCategoryString(category);
      if (ageGroup != null)
        queryParams['age_group'] = _getAgeGroupString(ageGroup);
      if (severity != null) queryParams['severity'] = severity.name;

      final uri = Uri.parse('$_baseUrl/knowledge/danger-signs')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DangerSignListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to list danger signs: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error listing danger signs: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  /// Get danger sign by ID
  /// GET /knowledge/danger-signs/{sign_id}
  Future<DangerSign> getDangerSign(String signId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/knowledge/danger-signs/$signId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DangerSign.fromJson(data);
      } else if (response.statusCode == 404) {
        throw KnowledgeApiException('Danger sign not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to get danger sign: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error getting danger sign: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  // ==================== DRUG DOSING ====================

  /// List drug dosing guidelines
  /// GET /knowledge/drugs
  Future<DrugListResponse> listDrugs({
    DrugClass? drugClass,
    String? indication,
    String? query,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (drugClass != null) queryParams['drug_class'] = drugClass.name;
      if (indication != null) queryParams['indication'] = indication;
      if (query != null && query.isNotEmpty) queryParams['q'] = query;

      final uri = Uri.parse('$_baseUrl/knowledge/drugs')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DrugListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to list drugs: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error listing drugs: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  /// Get drug by ID
  /// GET /knowledge/drugs/{drug_id}
  Future<DrugDosingGuideline> getDrug(String drugId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/knowledge/drugs/$drugId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DrugDosingGuideline.fromJson(data);
      } else if (response.statusCode == 404) {
        throw KnowledgeApiException('Drug not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to get drug: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error getting drug: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  /// Calculate drug dose
  /// POST /knowledge/drugs/calculate
  Future<DrugDoseCalculation> calculateDose({
    required String drugName,
    required double patientWeightKg,
    int? patientAgeMonths,
    String? indication,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'drug_name': drugName,
        'patient_weight_kg': patientWeightKg,
      };

      if (patientAgeMonths != null)
        body['patient_age_months'] = patientAgeMonths;
      if (indication != null) body['indication'] = indication;

      final response = await http.post(
        Uri.parse('$_baseUrl/knowledge/drugs/calculate'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DrugDoseCalculation.fromJson(data);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw KnowledgeApiException('Drug not found', statusCode: 404);
      } else {
        throw KnowledgeApiException(
          'Failed to calculate dose: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error calculating dose: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  // ==================== REFERRAL CRITERIA ====================

  /// List referral criteria
  /// GET /knowledge/referral-criteria
  Future<List<ReferralCriteria>> listReferralCriteria({
    String? conditionCategory,
    FacilityLevel? facilityLevel,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (conditionCategory != null)
        queryParams['condition_category'] = conditionCategory;
      if (facilityLevel != null)
        queryParams['facility_level'] = facilityLevel.name;

      final uri = Uri.parse('$_baseUrl/knowledge/referral-criteria')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] ?? data;
        return (items as List<dynamic>)
            .map((e) => ReferralCriteria.fromJson(e))
            .toList();
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to list referral criteria: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error listing referral criteria: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  /// Get referral criteria by ID
  /// GET /knowledge/referral-criteria/{criteria_id}
  Future<ReferralCriteria> getReferralCriteria(String criteriaId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/knowledge/referral-criteria/$criteriaId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReferralCriteria.fromJson(data);
      } else if (response.statusCode == 404) {
        throw KnowledgeApiException('Criteria not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to get referral criteria: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error getting referral criteria: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  // ==================== BOOKMARKS ====================

  /// Create bookmark
  /// POST /knowledge/bookmarks
  Future<KnowledgeBookmark> createBookmark({
    required String guidelineId,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'guideline_id': guidelineId,
      };
      if (notes != null) body['notes'] = notes;

      final response = await http.post(
        Uri.parse('$_baseUrl/knowledge/bookmarks'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return KnowledgeBookmark.fromJson(data);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to create bookmark: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error creating bookmark: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  /// List bookmarks
  /// GET /knowledge/bookmarks
  Future<List<KnowledgeBookmark>> listBookmarks() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/knowledge/bookmarks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] ?? data;
        return (items as List<dynamic>)
            .map((e) => KnowledgeBookmark.fromJson(e))
            .toList();
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to list bookmarks: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error listing bookmarks: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  /// Delete bookmark
  /// DELETE /knowledge/bookmarks/{bookmark_id}
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/knowledge/bookmarks/$bookmarkId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        if (response.statusCode == 401) {
          throw KnowledgeApiException('Unauthorized', statusCode: 401);
        }
        throw KnowledgeApiException(
          'Failed to delete bookmark: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error deleting bookmark: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  // ==================== CATEGORIES & SYNC ====================

  /// Get all categories
  /// GET /knowledge/categories
  Future<List<KnowledgeCategoryInfo>> getCategories() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/knowledge/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = data['categories'] ?? data;
        return (categories as List<dynamic>)
            .map((e) => KnowledgeCategoryInfo.fromJson(e))
            .toList();
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to get categories: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error getting categories: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }

  /// Sync knowledge base for offline use
  /// POST /knowledge/sync
  Future<KnowledgeSyncResponse> syncKnowledgeBase({
    DateTime? lastSyncAt,
    List<KnowledgeCategory>? categories,
    bool includeMedia = false,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'include_media': includeMedia,
      };

      if (lastSyncAt != null)
        body['last_sync_at'] = lastSyncAt.toIso8601String();
      if (categories != null) {
        body['categories'] =
            categories.map((c) => _getCategoryString(c)).toList();
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/knowledge/sync'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return KnowledgeSyncResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw KnowledgeApiException('Unauthorized', statusCode: 401);
      } else {
        throw KnowledgeApiException(
          'Failed to sync knowledge base: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      debugPrint('Error syncing knowledge base: $e');
      throw KnowledgeApiException('Network error: $e');
    }
  }
}

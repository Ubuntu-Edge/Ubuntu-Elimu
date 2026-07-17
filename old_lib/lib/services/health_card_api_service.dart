/// Health Cards & QR API Service
/// Patient health cards with QR codes, vaccination records, and card printing
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

// ==================== ENUMS ====================

enum CardType {
  standard,
  child,
  maternal,
  chronic,
  emergency,
}

enum CardStatus {
  active,
  expired,
  suspended,
  replaced,
}

enum SMSMessageType {
  cardLink,
  reminder,
  appointment,
  results,
  vaccination,
}

// ==================== MODELS ====================

class HealthCard {
  final String id;
  final String patientId;
  final String cardNumber;
  final CardType cardType;
  final String? qrCodeData;
  final String? qrCodeUrl;
  final CardStatus status;
  final bool includeVaccinations;
  final bool includeAllergies;
  final bool includeConditions;
  final bool includeMedications;
  final bool includeEmergencyContacts;
  final DateTime validFrom;
  final DateTime? validUntil;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthCard({
    required this.id,
    required this.patientId,
    required this.cardNumber,
    required this.cardType,
    this.qrCodeData,
    this.qrCodeUrl,
    required this.status,
    required this.includeVaccinations,
    required this.includeAllergies,
    required this.includeConditions,
    required this.includeMedications,
    required this.includeEmergencyContacts,
    required this.validFrom,
    this.validUntil,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthCard.fromJson(Map<String, dynamic> json) {
    return HealthCard(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      cardNumber: json['card_number'] ?? '',
      cardType: _parseCardType(json['card_type']),
      qrCodeData: json['qr_code_data'],
      qrCodeUrl: json['qr_code_url'],
      status: _parseCardStatus(json['status']),
      includeVaccinations: json['include_vaccinations'] ?? true,
      includeAllergies: json['include_allergies'] ?? true,
      includeConditions: json['include_conditions'] ?? true,
      includeMedications: json['include_medications'] ?? false,
      includeEmergencyContacts: json['include_emergency_contacts'] ?? true,
      validFrom: DateTime.tryParse(json['valid_from'] ?? '') ?? DateTime.now(),
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'])
          : null,
      version: json['version'] ?? 1,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  static CardType _parseCardType(String? type) {
    switch (type?.toLowerCase()) {
      case 'standard':
        return CardType.standard;
      case 'child':
        return CardType.child;
      case 'maternal':
        return CardType.maternal;
      case 'chronic':
        return CardType.chronic;
      case 'emergency':
        return CardType.emergency;
      default:
        return CardType.standard;
    }
  }

  static CardStatus _parseCardStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return CardStatus.active;
      case 'expired':
        return CardStatus.expired;
      case 'suspended':
        return CardStatus.suspended;
      case 'replaced':
        return CardStatus.replaced;
      default:
        return CardStatus.active;
    }
  }
}

class QRCodeResult {
  final String patientId;
  final String cardNumber;
  final String qrCodeBase64;
  final String? qrCodeUrl;
  final String? scanUrl;
  final String format;
  final DateTime generatedAt;

  QRCodeResult({
    required this.patientId,
    required this.cardNumber,
    required this.qrCodeBase64,
    this.qrCodeUrl,
    this.scanUrl,
    required this.format,
    required this.generatedAt,
  });

  factory QRCodeResult.fromJson(Map<String, dynamic> json) {
    return QRCodeResult(
      patientId: json['patient_id'] ?? '',
      cardNumber: json['card_number'] ?? '',
      qrCodeBase64: json['qr_code_base64'] ?? '',
      qrCodeUrl: json['qr_code_url'],
      scanUrl: json['scan_url'],
      format: json['format'] ?? 'png',
      generatedAt:
          DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class QRScanResult {
  final bool isValid;
  final String? patientId;
  final String? patientName;
  final String? cardNumber;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<VaccinationRecord> vaccinations;
  final CardStatus cardStatus;
  final DateTime? validUntil;
  final String? errorMessage;

  QRScanResult({
    required this.isValid,
    this.patientId,
    this.patientName,
    this.cardNumber,
    this.dateOfBirth,
    this.bloodGroup,
    required this.allergies,
    required this.chronicConditions,
    required this.vaccinations,
    required this.cardStatus,
    this.validUntil,
    this.errorMessage,
  });

  factory QRScanResult.fromJson(Map<String, dynamic> json) {
    return QRScanResult(
      isValid: json['is_valid'] ?? false,
      patientId: json['patient_id'],
      patientName: json['patient_name'],
      cardNumber: json['card_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      bloodGroup: json['blood_group'],
      allergies: List<String>.from(json['allergies'] ?? []),
      chronicConditions: List<String>.from(json['chronic_conditions'] ?? []),
      vaccinations: (json['vaccinations'] as List<dynamic>?)
              ?.map((e) => VaccinationRecord.fromJson(e))
              .toList() ??
          [],
      cardStatus: HealthCard._parseCardStatus(json['card_status']),
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'])
          : null,
      errorMessage: json['error_message'],
    );
  }
}

class VaccinationRecord {
  final String id;
  final String patientId;
  final String vaccineName;
  final String? vaccineCode;
  final int doseNumber;
  final int? totalDoses;
  final DateTime administeredDate;
  final String? batchNumber;
  final String? manufacturer;
  final String? facilityName;
  final String? administeredBy;
  final DateTime? nextDoseDue;
  final String? notes;
  final DateTime createdAt;

  VaccinationRecord({
    required this.id,
    required this.patientId,
    required this.vaccineName,
    this.vaccineCode,
    required this.doseNumber,
    this.totalDoses,
    required this.administeredDate,
    this.batchNumber,
    this.manufacturer,
    this.facilityName,
    this.administeredBy,
    this.nextDoseDue,
    this.notes,
    required this.createdAt,
  });

  factory VaccinationRecord.fromJson(Map<String, dynamic> json) {
    return VaccinationRecord(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      vaccineName: json['vaccine_name'] ?? '',
      vaccineCode: json['vaccine_code'],
      doseNumber: json['dose_number'] ?? 1,
      totalDoses: json['total_doses'],
      administeredDate:
          DateTime.tryParse(json['administered_date'] ?? '') ?? DateTime.now(),
      batchNumber: json['batch_number'],
      manufacturer: json['manufacturer'],
      facilityName: json['facility_name'],
      administeredBy: json['administered_by'],
      nextDoseDue: json['next_dose_due'] != null
          ? DateTime.tryParse(json['next_dose_due'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class VaccinationListResponse {
  final List<VaccinationRecord> items;
  final int total;
  final bool fullyVaccinated;
  final List<Map<String, dynamic>> upcomingVaccinations;

  VaccinationListResponse({
    required this.items,
    required this.total,
    required this.fullyVaccinated,
    required this.upcomingVaccinations,
  });

  factory VaccinationListResponse.fromJson(Map<String, dynamic> json) {
    return VaccinationListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => VaccinationRecord.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      fullyVaccinated: json['fully_vaccinated'] ?? false,
      upcomingVaccinations: (json['upcoming_vaccinations'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
  }
}

class SMSSendResult {
  final bool success;
  final String? messageId;
  final String status;
  final String? errorMessage;
  final DateTime sentAt;

  SMSSendResult({
    required this.success,
    this.messageId,
    required this.status,
    this.errorMessage,
    required this.sentAt,
  });

  factory SMSSendResult.fromJson(Map<String, dynamic> json) {
    return SMSSendResult(
      success: json['success'] ?? false,
      messageId: json['message_id'],
      status: json['status'] ?? 'unknown',
      errorMessage: json['error_message'],
      sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class PrintQueueEntry {
  final String id;
  final String cardId;
  final String patientId;
  final String patientName;
  final String cardNumber;
  final String status;
  final DateTime requestedAt;
  final DateTime? printedAt;

  PrintQueueEntry({
    required this.id,
    required this.cardId,
    required this.patientId,
    required this.patientName,
    required this.cardNumber,
    required this.status,
    required this.requestedAt,
    this.printedAt,
  });

  factory PrintQueueEntry.fromJson(Map<String, dynamic> json) {
    return PrintQueueEntry(
      id: json['id'] ?? '',
      cardId: json['card_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      cardNumber: json['card_number'] ?? '',
      status: json['status'] ?? 'pending',
      requestedAt:
          DateTime.tryParse(json['requested_at'] ?? '') ?? DateTime.now(),
      printedAt: json['printed_at'] != null
          ? DateTime.tryParse(json['printed_at'])
          : null,
    );
  }
}

class HealthCardListResponse {
  final List<HealthCard> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  HealthCardListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory HealthCardListResponse.fromJson(Map<String, dynamic> json) {
    return HealthCardListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => HealthCard.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

class HealthCardStats {
  final int totalCards;
  final int activeCards;
  final int expiredCards;
  final int totalVaccinations;
  final Map<String, int> cardsByType;

  HealthCardStats({
    required this.totalCards,
    required this.activeCards,
    required this.expiredCards,
    required this.totalVaccinations,
    required this.cardsByType,
  });

  factory HealthCardStats.fromJson(Map<String, dynamic> json) {
    return HealthCardStats(
      totalCards: json['total_cards'] ?? 0,
      activeCards: json['active_cards'] ?? 0,
      expiredCards: json['expired_cards'] ?? 0,
      totalVaccinations: json['total_vaccinations'] ?? 0,
      cardsByType: Map<String, int>.from(json['cards_by_type'] ?? {}),
    );
  }
}

// ==================== EXCEPTION ====================

class HealthCardApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  HealthCardApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'HealthCardApiException: $message (status: $statusCode)';
}

// ==================== SERVICE ====================

class HealthCardApiService {
  static final HealthCardApiService instance = HealthCardApiService._internal();
  HealthCardApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  String _getCardTypeString(CardType type) {
    switch (type) {
      case CardType.standard:
        return 'standard';
      case CardType.child:
        return 'child';
      case CardType.maternal:
        return 'maternal';
      case CardType.chronic:
        return 'chronic';
      case CardType.emergency:
        return 'emergency';
    }
  }

  String _getSMSMessageTypeString(SMSMessageType type) {
    switch (type) {
      case SMSMessageType.cardLink:
        return 'card_link';
      case SMSMessageType.reminder:
        return 'reminder';
      case SMSMessageType.appointment:
        return 'appointment';
      case SMSMessageType.results:
        return 'results';
      case SMSMessageType.vaccination:
        return 'vaccination';
    }
  }

  /// Create health card
  /// POST /health-cards
  Future<HealthCard> createCard({
    required String patientId,
    CardType cardType = CardType.standard,
    bool includeVaccinations = true,
    bool includeAllergies = true,
    bool includeConditions = true,
    bool includeMedications = false,
    bool includeEmergencyContacts = true,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'patient_id': patientId,
        'card_type': _getCardTypeString(cardType),
        'include_vaccinations': includeVaccinations,
        'include_allergies': includeAllergies,
        'include_conditions': includeConditions,
        'include_medications': includeMedications,
        'include_emergency_contacts': includeEmergencyContacts,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/health-cards'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return HealthCard.fromJson(data);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to create card: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error creating card: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// List health cards
  /// GET /health-cards
  Future<HealthCardListResponse> listCards({
    String? patientId,
    CardType? cardType,
    CardStatus? status,
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
      if (cardType != null)
        queryParams['card_type'] = _getCardTypeString(cardType);
      if (status != null) queryParams['status'] = status.name;

      final uri = Uri.parse('$_baseUrl/health-cards')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HealthCardListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to list cards: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error listing cards: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Get health card by ID
  /// GET /health-cards/{card_id}
  Future<HealthCard> getCard(String cardId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/health-cards/$cardId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HealthCard.fromJson(data);
      } else if (response.statusCode == 404) {
        throw HealthCardApiException('Card not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to get card: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error getting card: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Get patient's active health card
  /// GET /health-cards/patient/{patient_id}
  Future<HealthCard?> getPatientCard(String patientId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/health-cards/patient/$patientId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HealthCard.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to get patient card: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error getting patient card: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Generate QR code
  /// POST /health-cards/qr/generate
  Future<QRCodeResult> generateQRCode({
    required String patientId,
    bool includeVaccinations = true,
    bool includeAllergies = true,
    String format = 'png',
    int size = 300,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'patient_id': patientId,
        'include_vaccinations': includeVaccinations,
        'include_allergies': includeAllergies,
        'format': format,
        'size': size,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/health-cards/qr/generate'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return QRCodeResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to generate QR code: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error generating QR code: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Scan QR code
  /// POST /health-cards/qr/scan
  Future<QRScanResult> scanQRCode({
    required String qrData,
    String? scannerDeviceId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'qr_data': qrData,
      };

      if (scannerDeviceId != null) body['scanner_device_id'] = scannerDeviceId;
      if (latitude != null && longitude != null) {
        body['location'] = {'lat': latitude, 'lng': longitude};
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/health-cards/qr/scan'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QRScanResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to scan QR code: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error scanning QR code: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Record vaccination
  /// POST /health-cards/vaccinations
  Future<VaccinationRecord> recordVaccination({
    required String patientId,
    required String vaccineName,
    String? vaccineCode,
    required int doseNumber,
    int? totalDoses,
    required DateTime administeredDate,
    String? batchNumber,
    String? manufacturer,
    String? facilityName,
    String? administeredBy,
    DateTime? nextDoseDue,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'patient_id': patientId,
        'vaccine_name': vaccineName,
        'dose_number': doseNumber,
        'administered_date': administeredDate.toIso8601String().split('T')[0],
      };

      if (vaccineCode != null) body['vaccine_code'] = vaccineCode;
      if (totalDoses != null) body['total_doses'] = totalDoses;
      if (batchNumber != null) body['batch_number'] = batchNumber;
      if (manufacturer != null) body['manufacturer'] = manufacturer;
      if (facilityName != null) body['facility_name'] = facilityName;
      if (administeredBy != null) body['administered_by'] = administeredBy;
      if (nextDoseDue != null)
        body['next_dose_due'] = nextDoseDue.toIso8601String().split('T')[0];
      if (notes != null) body['notes'] = notes;

      final response = await http.post(
        Uri.parse('$_baseUrl/health-cards/vaccinations'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return VaccinationRecord.fromJson(data);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to record vaccination: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error recording vaccination: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Get patient vaccinations
  /// GET /health-cards/vaccinations/patient/{patient_id}
  Future<VaccinationListResponse> getPatientVaccinations(
      String patientId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/health-cards/vaccinations/patient/$patientId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VaccinationListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to get vaccinations: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error getting vaccinations: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Send health card via SMS
  /// POST /health-cards/sms/send
  Future<SMSSendResult> sendCardViaSMS({
    required String patientId,
    required String phoneNumber,
    bool includeQRLink = true,
    SMSMessageType messageType = SMSMessageType.cardLink,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'patient_id': patientId,
        'phone_number': phoneNumber,
        'include_qr_link': includeQRLink,
        'message_type': _getSMSMessageTypeString(messageType),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/health-cards/sms/send'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SMSSendResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to send SMS: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error sending SMS: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Add to print queue
  /// POST /health-cards/print
  Future<PrintQueueEntry> addToPrintQueue(String cardId) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {'card_id': cardId};

      final response = await http.post(
        Uri.parse('$_baseUrl/health-cards/print'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PrintQueueEntry.fromJson(data);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to add to print queue: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error adding to print queue: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Get print queue
  /// GET /health-cards/print/queue
  Future<List<PrintQueueEntry>> getPrintQueue() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/health-cards/print/queue'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] ?? data;
        return (items as List<dynamic>)
            .map((e) => PrintQueueEntry.fromJson(e))
            .toList();
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to get print queue: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error getting print queue: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }

  /// Get statistics
  /// GET /health-cards/stats/summary
  Future<HealthCardStats> getStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/health-cards/stats/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HealthCardStats.fromJson(data);
      } else if (response.statusCode == 401) {
        throw HealthCardApiException('Unauthorized', statusCode: 401);
      } else {
        throw HealthCardApiException(
          'Failed to get stats: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is HealthCardApiException) rethrow;
      debugPrint('Error getting stats: $e');
      throw HealthCardApiException('Network error: $e');
    }
  }
}

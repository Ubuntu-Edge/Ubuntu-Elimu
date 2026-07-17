import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/patient_models.dart';
import 'auth_service.dart';

/// Patient API Service
/// Handles all patient-related API calls to the backend
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
class PatientApiService {
  static final PatientApiService instance = PatientApiService._internal();
  PatientApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Create a new patient
  /// POST /patients
  Future<PatientResponse> createPatient(PatientCreateRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/patients'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PatientResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => ValidationError.fromJson(e))
            .toList();
        throw PatientApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw PatientApiException('Unauthorized', statusCode: 401);
      } else {
        throw PatientApiException(
          'Failed to create patient: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is PatientApiException) rethrow;
      debugPrint('Error creating patient: $e');
      throw PatientApiException('Network error: $e');
    }
  }

  /// List patients with optional filters and pagination
  /// GET /patients
  Future<PatientListResponse> listPatients({
    int page = 1,
    int perPage = 20,
    String? query,
    String? village,
    bool? isHighRisk,
    bool? isPregnant,
    String? gender,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (village != null && village.isNotEmpty) queryParams['village'] = village;
      if (isHighRisk != null) queryParams['is_high_risk'] = isHighRisk.toString();
      if (isPregnant != null) queryParams['is_pregnant'] = isPregnant.toString();
      if (gender != null && gender.isNotEmpty) queryParams['gender'] = gender;

      final uri = Uri.parse('$_baseUrl/patients').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PatientListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw PatientApiException('Unauthorized', statusCode: 401);
      } else {
        throw PatientApiException(
          'Failed to list patients: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is PatientApiException) rethrow;
      debugPrint('Error listing patients: $e');
      throw PatientApiException('Network error: $e');
    }
  }

  /// Get patient details by ID
  /// GET /patients/{patient_id}
  Future<PatientResponse> getPatient(String patientId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PatientResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw PatientApiException('Patient not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw PatientApiException('Unauthorized', statusCode: 401);
      } else {
        throw PatientApiException(
          'Failed to get patient: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is PatientApiException) rethrow;
      debugPrint('Error getting patient: $e');
      throw PatientApiException('Network error: $e');
    }
  }

  /// Get patient summary by ID
  /// GET /patients/{patient_id}/summary
  Future<PatientSummaryResponse> getPatientSummary(String patientId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/patients/$patientId/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PatientSummaryResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw PatientApiException('Patient not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw PatientApiException('Unauthorized', statusCode: 401);
      } else {
        throw PatientApiException(
          'Failed to get patient summary: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is PatientApiException) rethrow;
      debugPrint('Error getting patient summary: $e');
      throw PatientApiException('Network error: $e');
    }
  }

  /// Update patient by ID
  /// PATCH /patients/{patient_id}
  Future<PatientResponse> updatePatient(
    String patientId,
    PatientUpdateRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PatientResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw PatientApiException('Patient not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => ValidationError.fromJson(e))
            .toList();
        throw PatientApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw PatientApiException('Unauthorized', statusCode: 401);
      } else {
        throw PatientApiException(
          'Failed to update patient: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is PatientApiException) rethrow;
      debugPrint('Error updating patient: $e');
      throw PatientApiException('Network error: $e');
    }
  }

  /// Delete patient by ID
  /// DELETE /patients/{patient_id}
  Future<bool> deletePatient(String patientId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw PatientApiException('Patient not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw PatientApiException('Unauthorized', statusCode: 401);
      } else {
        throw PatientApiException(
          'Failed to delete patient: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is PatientApiException) rethrow;
      debugPrint('Error deleting patient: $e');
      throw PatientApiException('Network error: $e');
    }
  }
}

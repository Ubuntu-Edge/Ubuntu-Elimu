import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/analytics_models.dart';
import 'auth_service.dart';

/// Analytics API Service
/// Handles all analytics-related API calls to the backend
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
class AnalyticsApiService {
  static final AnalyticsApiService instance = AnalyticsApiService._internal();
  AnalyticsApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Get analytics summary for a specific period
  /// GET /analytics/summary?period_start={date}&period_end={date}
  Future<AnalyticsSummaryResponse> getAnalyticsSummary({
    required String periodStart, // YYYY-MM-DD
    required String periodEnd, // YYYY-MM-DD
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        'period_start': periodStart,
        'period_end': periodEnd,
      };

      final uri = Uri.parse('$_baseUrl/analytics/summary')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AnalyticsSummaryResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AnalyticsApiException('Unauthorized', statusCode: 401);
      } else {
        throw AnalyticsApiException(
          'Failed to get analytics summary: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AnalyticsApiException) rethrow;
      debugPrint('Error getting analytics summary: $e');
      throw AnalyticsApiException('Network error: $e');
    }
  }

  /// Get performance metrics for a specific period
  /// GET /analytics/performance?period_start={date}&period_end={date}
  Future<PerformanceMetricsResponse> getPerformanceMetrics({
    required String periodStart, // YYYY-MM-DD
    required String periodEnd, // YYYY-MM-DD
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        'period_start': periodStart,
        'period_end': periodEnd,
      };

      final uri = Uri.parse('$_baseUrl/analytics/performance')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PerformanceMetricsResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AnalyticsApiException('Unauthorized', statusCode: 401);
      } else {
        throw AnalyticsApiException(
          'Failed to get performance metrics: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AnalyticsApiException) rethrow;
      debugPrint('Error getting performance metrics: $e');
      throw AnalyticsApiException('Network error: $e');
    }
  }

  /// Get dashboard overview (for supervisors/admins)
  /// GET /analytics/dashboard?period_start={date}&period_end={date}
  Future<DashboardOverviewResponse> getDashboardOverview({
    required String periodStart, // YYYY-MM-DD
    required String periodEnd, // YYYY-MM-DD
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        'period_start': periodStart,
        'period_end': periodEnd,
      };

      final uri = Uri.parse('$_baseUrl/analytics/dashboard')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardOverviewResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AnalyticsApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 403) {
        throw AnalyticsApiException('Access denied - supervisor role required', statusCode: 403);
      } else {
        throw AnalyticsApiException(
          'Failed to get dashboard overview: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AnalyticsApiException) rethrow;
      debugPrint('Error getting dashboard overview: $e');
      throw AnalyticsApiException('Network error: $e');
    }
  }
}

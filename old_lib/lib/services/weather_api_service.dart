/// Weather Service API
/// Weather forecasts, alerts, and travel advisories for CHW field work
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

// ==================== ENUMS ====================

enum WeatherCondition {
  sunny,
  partlyCloudy,
  cloudy,
  overcast,
  lightRain,
  rain,
  heavyRain,
  thunderstorm,
  drizzle,
  fog,
  mist,
  haze,
  windy,
  hot,
  cold,
}

enum AlertSeverity {
  advisory,
  watch,
  warning,
  emergency,
}

enum AlertType {
  rain,
  storm,
  flood,
  heat,
  cold,
  wind,
  fog,
  dust,
  other,
}

enum TravelRiskLevel {
  low,
  moderate,
  high,
  extreme,
}

// ==================== MODELS ====================

class CurrentWeather {
  final WeatherCondition condition;
  final String conditionIcon;
  final double temperatureC;
  final double? temperatureFeelsLikeC;
  final int precipitationProbability;
  final int humidityPercent;
  final double windSpeedKmh;
  final String? windDirection;
  final int? visibility;
  final int? uvIndex;
  final bool outdoorWorkSuitable;
  final String travelConditions;

  CurrentWeather({
    required this.condition,
    required this.conditionIcon,
    required this.temperatureC,
    this.temperatureFeelsLikeC,
    required this.precipitationProbability,
    required this.humidityPercent,
    required this.windSpeedKmh,
    this.windDirection,
    this.visibility,
    this.uvIndex,
    required this.outdoorWorkSuitable,
    required this.travelConditions,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      condition: _parseCondition(json['condition']),
      conditionIcon: json['condition_icon'] ?? '☀️',
      temperatureC: (json['temperature_c'] ?? 25).toDouble(),
      temperatureFeelsLikeC:
          (json['temperature_feels_like_c'] as num?)?.toDouble(),
      precipitationProbability: json['precipitation_probability'] ?? 0,
      humidityPercent: json['humidity_percent'] ?? 50,
      windSpeedKmh: (json['wind_speed_kmh'] ?? 0).toDouble(),
      windDirection: json['wind_direction'],
      visibility: json['visibility'],
      uvIndex: json['uv_index'],
      outdoorWorkSuitable: json['outdoor_work_suitable'] ?? true,
      travelConditions: json['travel_conditions'] ?? 'good',
    );
  }

  static WeatherCondition _parseCondition(String? condition) {
    switch (condition?.toLowerCase().replaceAll('_', '')) {
      case 'sunny':
        return WeatherCondition.sunny;
      case 'partlycloudy':
        return WeatherCondition.partlyCloudy;
      case 'cloudy':
        return WeatherCondition.cloudy;
      case 'overcast':
        return WeatherCondition.overcast;
      case 'lightrain':
        return WeatherCondition.lightRain;
      case 'rain':
        return WeatherCondition.rain;
      case 'heavyrain':
        return WeatherCondition.heavyRain;
      case 'thunderstorm':
        return WeatherCondition.thunderstorm;
      case 'drizzle':
        return WeatherCondition.drizzle;
      case 'fog':
        return WeatherCondition.fog;
      case 'mist':
        return WeatherCondition.mist;
      case 'haze':
        return WeatherCondition.haze;
      case 'windy':
        return WeatherCondition.windy;
      case 'hot':
        return WeatherCondition.hot;
      case 'cold':
        return WeatherCondition.cold;
      default:
        return WeatherCondition.partlyCloudy;
    }
  }
}

class DailyForecast {
  final DateTime forecastDate;
  final WeatherCondition condition;
  final String conditionIcon;
  final double temperatureMinC;
  final double temperatureMaxC;
  final int precipitationProbability;
  final double? precipitationMm;
  final double? windSpeedKmh;
  final int? humidityPercent;
  final String? summary;

  DailyForecast({
    required this.forecastDate,
    required this.condition,
    required this.conditionIcon,
    required this.temperatureMinC,
    required this.temperatureMaxC,
    required this.precipitationProbability,
    this.precipitationMm,
    this.windSpeedKmh,
    this.humidityPercent,
    this.summary,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      forecastDate:
          DateTime.tryParse(json['forecast_date'] ?? '') ?? DateTime.now(),
      condition: CurrentWeather._parseCondition(json['condition']),
      conditionIcon: json['condition_icon'] ?? '☀️',
      temperatureMinC: (json['temperature_min_c'] ?? 18).toDouble(),
      temperatureMaxC: (json['temperature_max_c'] ?? 28).toDouble(),
      precipitationProbability: json['precipitation_probability'] ?? 0,
      precipitationMm: (json['precipitation_mm'] as num?)?.toDouble(),
      windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble(),
      humidityPercent: json['humidity_percent'],
      summary: json['summary'],
    );
  }
}

class HourlyForecast {
  final DateTime forecastTime;
  final WeatherCondition condition;
  final String conditionIcon;
  final double temperatureC;
  final int precipitationProbability;
  final double? windSpeedKmh;

  HourlyForecast({
    required this.forecastTime,
    required this.condition,
    required this.conditionIcon,
    required this.temperatureC,
    required this.precipitationProbability,
    this.windSpeedKmh,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      forecastTime:
          DateTime.tryParse(json['forecast_time'] ?? '') ?? DateTime.now(),
      condition: CurrentWeather._parseCondition(json['condition']),
      conditionIcon: json['condition_icon'] ?? '☀️',
      temperatureC: (json['temperature_c'] ?? 25).toDouble(),
      precipitationProbability: json['precipitation_probability'] ?? 0,
      windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble(),
    );
  }
}

class WeatherForecast {
  final String locationName;
  final double latitude;
  final double longitude;
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final List<HourlyForecast>? hourly;
  final DateTime lastUpdated;

  WeatherForecast({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.current,
    required this.daily,
    this.hourly,
    required this.lastUpdated,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      locationName: json['location_name'] ?? 'Unknown',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      current: CurrentWeather.fromJson(json['current'] ?? {}),
      daily: (json['daily'] as List<dynamic>?)
              ?.map((e) => DailyForecast.fromJson(e))
              .toList() ??
          [],
      hourly: json['hourly'] != null
          ? (json['hourly'] as List<dynamic>)
              .map((e) => HourlyForecast.fromJson(e))
              .toList()
          : null,
      lastUpdated:
          DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
    );
  }
}

class WeatherAlert {
  final String id;
  final AlertType alertType;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String? instructions;
  final DateTime startTime;
  final DateTime? endTime;
  final bool affectsTravel;
  final bool affectsOutdoorWork;
  final List<String> recommendedActions;
  final String? areaAffected;
  final DateTime createdAt;

  WeatherAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.description,
    this.instructions,
    required this.startTime,
    this.endTime,
    required this.affectsTravel,
    required this.affectsOutdoorWork,
    required this.recommendedActions,
    this.areaAffected,
    required this.createdAt,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      id: json['id'] ?? '',
      alertType: _parseAlertType(json['alert_type']),
      severity: _parseSeverity(json['severity']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructions: json['instructions'],
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime:
          json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      affectsTravel: json['affects_travel'] ?? false,
      affectsOutdoorWork: json['affects_outdoor_work'] ?? false,
      recommendedActions: List<String>.from(json['recommended_actions'] ?? []),
      areaAffected: json['area_affected'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static AlertType _parseAlertType(String? type) {
    switch (type?.toLowerCase()) {
      case 'rain':
        return AlertType.rain;
      case 'storm':
        return AlertType.storm;
      case 'flood':
        return AlertType.flood;
      case 'heat':
        return AlertType.heat;
      case 'cold':
        return AlertType.cold;
      case 'wind':
        return AlertType.wind;
      case 'fog':
        return AlertType.fog;
      case 'dust':
        return AlertType.dust;
      default:
        return AlertType.other;
    }
  }

  static AlertSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'advisory':
        return AlertSeverity.advisory;
      case 'watch':
        return AlertSeverity.watch;
      case 'warning':
        return AlertSeverity.warning;
      case 'emergency':
        return AlertSeverity.emergency;
      default:
        return AlertSeverity.advisory;
    }
  }
}

class WeatherAlertListResponse {
  final List<WeatherAlert> items;
  final int total;
  final int activeCount;
  final Map<String, int>? bySeverity;

  WeatherAlertListResponse({
    required this.items,
    required this.total,
    required this.activeCount,
    this.bySeverity,
  });

  factory WeatherAlertListResponse.fromJson(Map<String, dynamic> json) {
    return WeatherAlertListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => WeatherAlert.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      activeCount: json['active_count'] ?? 0,
      bySeverity: json['by_severity'] != null
          ? Map<String, int>.from(json['by_severity'])
          : null,
    );
  }
}

class TravelAdvisory {
  final String fromLocation;
  final String toLocation;
  final double distanceKm;
  final int estimatedTravelTimeMinutes;
  final bool isSafeToTravel;
  final TravelRiskLevel riskLevel;
  final String conditions;
  final List<String> hazards;
  final List<String> recommendations;
  final String bestTravelTime;
  final DateTime validUntil;

  TravelAdvisory({
    required this.fromLocation,
    required this.toLocation,
    required this.distanceKm,
    required this.estimatedTravelTimeMinutes,
    required this.isSafeToTravel,
    required this.riskLevel,
    required this.conditions,
    required this.hazards,
    required this.recommendations,
    required this.bestTravelTime,
    required this.validUntil,
  });

  factory TravelAdvisory.fromJson(Map<String, dynamic> json) {
    return TravelAdvisory(
      fromLocation: json['from_location'] ?? '',
      toLocation: json['to_location'] ?? '',
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      estimatedTravelTimeMinutes: json['estimated_travel_time_minutes'] ?? 0,
      isSafeToTravel: json['is_safe_to_travel'] ?? true,
      riskLevel: _parseRiskLevel(json['risk_level']),
      conditions: json['conditions'] ?? '',
      hazards: List<String>.from(json['hazards'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      bestTravelTime: json['best_travel_time'] ?? 'Any time',
      validUntil: DateTime.tryParse(json['valid_until'] ?? '') ??
          DateTime.now().add(const Duration(hours: 24)),
    );
  }

  static TravelRiskLevel _parseRiskLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'low':
        return TravelRiskLevel.low;
      case 'moderate':
        return TravelRiskLevel.moderate;
      case 'high':
        return TravelRiskLevel.high;
      case 'extreme':
        return TravelRiskLevel.extreme;
      default:
        return TravelRiskLevel.low;
    }
  }
}

class WorkSuitability {
  final DateTime date;
  final String locationName;
  final bool overallSuitable;
  final int suitabilityScore;
  final bool morningSuitable;
  final bool afternoonSuitable;
  final bool eveningSuitable;
  final List<String> bestWorkHours;
  final bool heatConcern;
  final bool rainConcern;
  final bool stormConcern;
  final List<String> recommendations;
  final List<String> precautions;
  final String weatherSummary;

  WorkSuitability({
    required this.date,
    required this.locationName,
    required this.overallSuitable,
    required this.suitabilityScore,
    required this.morningSuitable,
    required this.afternoonSuitable,
    required this.eveningSuitable,
    required this.bestWorkHours,
    required this.heatConcern,
    required this.rainConcern,
    required this.stormConcern,
    required this.recommendations,
    required this.precautions,
    required this.weatherSummary,
  });

  factory WorkSuitability.fromJson(Map<String, dynamic> json) {
    return WorkSuitability(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      locationName: json['location_name'] ?? '',
      overallSuitable: json['overall_suitable'] ?? true,
      suitabilityScore: json['suitability_score'] ?? 100,
      morningSuitable: json['morning_suitable'] ?? true,
      afternoonSuitable: json['afternoon_suitable'] ?? true,
      eveningSuitable: json['evening_suitable'] ?? true,
      bestWorkHours: List<String>.from(json['best_work_hours'] ?? []),
      heatConcern: json['heat_concern'] ?? false,
      rainConcern: json['rain_concern'] ?? false,
      stormConcern: json['storm_concern'] ?? false,
      recommendations: List<String>.from(json['recommendations'] ?? []),
      precautions: List<String>.from(json['precautions'] ?? []),
      weatherSummary: json['weather_summary'] ?? '',
    );
  }
}

class WeatherPreferences {
  final double? defaultLatitude;
  final double? defaultLongitude;
  final String? defaultLocationName;
  final bool alertForRain;
  final bool alertForExtremeHeat;
  final bool alertForStorms;
  final double rainThresholdMm;
  final double heatThresholdC;

  WeatherPreferences({
    this.defaultLatitude,
    this.defaultLongitude,
    this.defaultLocationName,
    required this.alertForRain,
    required this.alertForExtremeHeat,
    required this.alertForStorms,
    required this.rainThresholdMm,
    required this.heatThresholdC,
  });

  factory WeatherPreferences.fromJson(Map<String, dynamic> json) {
    return WeatherPreferences(
      defaultLatitude: (json['default_latitude'] as num?)?.toDouble(),
      defaultLongitude: (json['default_longitude'] as num?)?.toDouble(),
      defaultLocationName: json['default_location_name'],
      alertForRain: json['alert_for_rain'] ?? true,
      alertForExtremeHeat: json['alert_for_extreme_heat'] ?? true,
      alertForStorms: json['alert_for_storms'] ?? true,
      rainThresholdMm: (json['rain_threshold_mm'] ?? 10).toDouble(),
      heatThresholdC: (json['heat_threshold_c'] ?? 35).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (defaultLatitude != null) 'default_latitude': defaultLatitude,
      if (defaultLongitude != null) 'default_longitude': defaultLongitude,
      if (defaultLocationName != null)
        'default_location_name': defaultLocationName,
      'alert_for_rain': alertForRain,
      'alert_for_extreme_heat': alertForExtremeHeat,
      'alert_for_storms': alertForStorms,
      'rain_threshold_mm': rainThresholdMm,
      'heat_threshold_c': heatThresholdC,
    };
  }
}

class WeatherSummary {
  final String locationName;
  final double currentTemperatureC;
  final String currentCondition;
  final String currentConditionIcon;
  final double todayHighC;
  final double todayLowC;
  final double precipitationTodayMm;
  final int precipitationProbability;
  final int activeAlertsCount;
  final bool workSuitableToday;
  final int workSuitabilityScore;
  final String? nextRainExpected;
  final DateTime updatedAt;

  WeatherSummary({
    required this.locationName,
    required this.currentTemperatureC,
    required this.currentCondition,
    required this.currentConditionIcon,
    required this.todayHighC,
    required this.todayLowC,
    required this.precipitationTodayMm,
    required this.precipitationProbability,
    required this.activeAlertsCount,
    required this.workSuitableToday,
    required this.workSuitabilityScore,
    this.nextRainExpected,
    required this.updatedAt,
  });

  factory WeatherSummary.fromJson(Map<String, dynamic> json) {
    return WeatherSummary(
      locationName: json['location_name'] ?? 'Unknown',
      currentTemperatureC: (json['current_temperature_c'] ?? 25).toDouble(),
      currentCondition: json['current_condition'] ?? 'Partly Cloudy',
      currentConditionIcon: json['current_condition_icon'] ?? '⛅',
      todayHighC: (json['today_high_c'] ?? 28).toDouble(),
      todayLowC: (json['today_low_c'] ?? 18).toDouble(),
      precipitationTodayMm: (json['precipitation_today_mm'] ?? 0).toDouble(),
      precipitationProbability: json['precipitation_probability'] ?? 0,
      activeAlertsCount: json['active_alerts_count'] ?? 0,
      workSuitableToday: json['work_suitable_today'] ?? true,
      workSuitabilityScore: json['work_suitability_score'] ?? 100,
      nextRainExpected: json['next_rain_expected'],
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// ==================== EXCEPTION ====================

class WeatherApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  WeatherApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'WeatherApiException: $message (status: $statusCode)';
}

// ==================== SERVICE ====================

class WeatherApiService {
  static final WeatherApiService instance = WeatherApiService._internal();
  WeatherApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Get weather forecast
  /// GET /weather/forecast
  Future<WeatherForecast> getForecast({
    required double latitude,
    required double longitude,
    String? locationName,
    int days = 7,
    bool includeHourly = false,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'days': days.toString(),
        'include_hourly': includeHourly.toString(),
      };

      if (locationName != null) queryParams['location_name'] = locationName;

      final uri = Uri.parse('$_baseUrl/weather/forecast')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherForecast.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to get forecast: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error getting forecast: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// Get weather forecast (POST method for complex requests)
  /// POST /weather/forecast
  Future<WeatherForecast> getForecastPost({
    required double latitude,
    required double longitude,
    String? locationName,
    int days = 7,
    bool includeHourly = false,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'latitude': latitude,
        'longitude': longitude,
        'days': days,
        'include_hourly': includeHourly,
      };

      if (locationName != null) body['location_name'] = locationName;

      final response = await http.post(
        Uri.parse('$_baseUrl/weather/forecast'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherForecast.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to get forecast: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error getting forecast: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// Get weather alerts
  /// GET /weather/alerts
  Future<WeatherAlertListResponse> getAlerts({
    double? latitude,
    double? longitude,
    String? region,
    AlertSeverity? severity,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (region != null) queryParams['region'] = region;
      if (severity != null) queryParams['severity'] = severity.name;

      final uri = Uri.parse('$_baseUrl/weather/alerts')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherAlertListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to get alerts: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error getting alerts: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// Get alert by ID
  /// GET /weather/alerts/{alert_id}
  Future<WeatherAlert> getAlert(String alertId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/weather/alerts/$alertId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherAlert.fromJson(data);
      } else if (response.statusCode == 404) {
        throw WeatherApiException('Alert not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to get alert: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error getting alert: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// Get travel advisory
  /// POST /weather/travel-advisory
  Future<TravelAdvisory> getTravelAdvisory({
    required double fromLatitude,
    required double fromLongitude,
    String? fromLocationName,
    required double toLatitude,
    required double toLongitude,
    String? toLocationName,
    DateTime? travelDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'from_latitude': fromLatitude,
        'from_longitude': fromLongitude,
        'to_latitude': toLatitude,
        'to_longitude': toLongitude,
      };

      if (fromLocationName != null)
        body['from_location_name'] = fromLocationName;
      if (toLocationName != null) body['to_location_name'] = toLocationName;
      if (travelDate != null)
        body['travel_date'] = travelDate.toIso8601String().split('T')[0];

      final response = await http.post(
        Uri.parse('$_baseUrl/weather/travel-advisory'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TravelAdvisory.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to get travel advisory: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error getting travel advisory: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// List recent travel advisories
  /// GET /weather/travel-advisories
  Future<List<TravelAdvisory>> listTravelAdvisories({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      final uri = Uri.parse('$_baseUrl/weather/travel-advisories')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] ?? data;
        return (items as List<dynamic>)
            .map((e) => TravelAdvisory.fromJson(e))
            .toList();
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to list travel advisories: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error listing travel advisories: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// Check work suitability
  /// GET /weather/work-suitability
  Future<WorkSuitability> checkWorkSuitability({
    required double latitude,
    required double longitude,
    String? locationName,
    DateTime? checkDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };

      if (locationName != null) queryParams['location_name'] = locationName;
      if (checkDate != null)
        queryParams['check_date'] = checkDate.toIso8601String().split('T')[0];

      final uri = Uri.parse('$_baseUrl/weather/work-suitability')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WorkSuitability.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to check work suitability: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error checking work suitability: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// Check work suitability (POST method)
  /// POST /weather/work-suitability
  Future<WorkSuitability> checkWorkSuitabilityPost({
    required double latitude,
    required double longitude,
    String? locationName,
    DateTime? checkDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };

      if (locationName != null) body['location_name'] = locationName;
      if (checkDate != null)
        body['check_date'] = checkDate.toIso8601String().split('T')[0];

      final response = await http.post(
        Uri.parse('$_baseUrl/weather/work-suitability'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WorkSuitability.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to check work suitability: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error checking work suitability: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// Get weather preferences
  /// GET /weather/preferences
  Future<WeatherPreferences> getPreferences() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/weather/preferences'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherPreferences.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to get preferences: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error getting preferences: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// Update weather preferences
  /// PUT /weather/preferences
  Future<WeatherPreferences> updatePreferences(
      WeatherPreferences preferences) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/weather/preferences'),
        headers: headers,
        body: jsonEncode(preferences.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherPreferences.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to update preferences: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error updating preferences: $e');
      throw WeatherApiException('Network error: $e');
    }
  }

  /// Get weather summary for dashboard
  /// GET /weather/summary
  Future<WeatherSummary> getSummary({
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};

      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (locationName != null) queryParams['location_name'] = locationName;

      final uri = Uri.parse('$_baseUrl/weather/summary').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherSummary.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherApiException('Unauthorized', statusCode: 401);
      } else {
        throw WeatherApiException(
          'Failed to get summary: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherApiException) rethrow;
      debugPrint('Error getting summary: $e');
      throw WeatherApiException('Network error: $e');
    }
  }
}

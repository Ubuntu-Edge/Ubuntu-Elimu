/// Community Engagement Models
/// Matches the backend API at /api/v1/engagement/*
library;

// ==================== ALLOWED VALUES / ENUMS ====================

/// Event types for community events
class EventType {
  static const String healthTalk = 'health_talk';
  static const String screening = 'screening';
  static const String vaccination = 'vaccination';
  static const String outreach = 'outreach';
  static const String awareness = 'awareness';
  static const String training = 'training';
  static const String meeting = 'meeting';

  static const List<String> values = [
    healthTalk,
    screening,
    vaccination,
    outreach,
    awareness,
    training,
    meeting,
  ];

  static bool isValid(String? value) =>
      value == null || values.contains(value.toLowerCase());

  static String displayName(String value) {
    switch (value.toLowerCase()) {
      case healthTalk:
        return 'Health Talk';
      case screening:
        return 'Screening';
      case vaccination:
        return 'Vaccination';
      case outreach:
        return 'Outreach';
      case awareness:
        return 'Awareness';
      case training:
        return 'Training';
      case meeting:
        return 'Meeting';
      default:
        return value;
    }
  }
}

/// Event status values
class EventStatus {
  static const String planned = 'planned';
  static const String ongoing = 'ongoing';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> values = [planned, ongoing, completed, cancelled];

  static bool isValid(String? value) =>
      value == null || values.contains(value.toLowerCase());

  static String displayName(String value) {
    switch (value.toLowerCase()) {
      case planned:
        return 'Planned';
      case ongoing:
        return 'Ongoing';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return value;
    }
  }
}

/// Campaign types
class CampaignType {
  static const String vaccination = 'vaccination';
  static const String screening = 'screening';
  static const String deworming = 'deworming';
  static const String nutrition = 'nutrition';
  static const String malaria = 'malaria';
  static const String hiv = 'hiv';
  static const String tb = 'tb';
  static const String maternalHealth = 'maternal_health';
  static const String familyPlanning = 'family_planning';

  static const List<String> values = [
    vaccination,
    screening,
    deworming,
    nutrition,
    malaria,
    hiv,
    tb,
    maternalHealth,
    familyPlanning,
  ];

  static bool isValid(String? value) =>
      value == null || values.contains(value.toLowerCase());

  static String displayName(String value) {
    switch (value.toLowerCase()) {
      case vaccination:
        return 'Vaccination';
      case screening:
        return 'Screening';
      case deworming:
        return 'Deworming';
      case nutrition:
        return 'Nutrition';
      case malaria:
        return 'Malaria';
      case hiv:
        return 'HIV';
      case tb:
        return 'TB';
      case maternalHealth:
        return 'Maternal Health';
      case familyPlanning:
        return 'Family Planning';
      default:
        return value;
    }
  }
}

/// Campaign status values
class CampaignStatus {
  static const String active = 'active';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> values = [active, completed, cancelled];

  static bool isValid(String? value) =>
      value == null || values.contains(value.toLowerCase());

  static String displayName(String value) {
    switch (value.toLowerCase()) {
      case active:
        return 'Active';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return value;
    }
  }
}

// ==================== EVENT MODELS ====================

/// Community event model
/// API fields: title, description, event_type, event_date, start_time, end_time,
/// location, area, latitude, longitude, expected_participants, actual_participants,
/// status, notes, id, organizer_id, created_at
class CommunityEvent {
  final String id;
  final String title;
  final String eventType;
  final String? description;
  final String? area;
  final DateTime eventDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String organizerId;
  final int? expectedParticipants;
  final int? actualParticipants;
  final String status;
  final String? notes;
  final DateTime createdAt;

  CommunityEvent({
    required this.id,
    required this.title,
    required this.eventType,
    this.description,
    this.area,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.location,
    this.latitude,
    this.longitude,
    required this.organizerId,
    this.expectedParticipants,
    this.actualParticipants,
    this.status = EventStatus.planned,
    this.notes,
    required this.createdAt,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    return CommunityEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      eventType: json['event_type'] ?? EventType.healthTalk,
      description: json['description'],
      area: json['area'],
      eventDate: DateTime.tryParse(json['event_date'] ?? '') ?? DateTime.now(),
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'])
          : null,
      endTime:
          json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      organizerId: json['organizer_id'] ?? '',
      expectedParticipants: json['expected_participants'],
      actualParticipants: json['actual_participants'],
      status: json['status'] ?? EventStatus.planned,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'event_type': eventType,
      'description': description,
      'area': area,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'organizer_id': organizerId,
      'expected_participants': expectedParticipants,
      'actual_participants': actualParticipants,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get eventTypeDisplay => EventType.displayName(eventType);
  String get statusDisplay => EventStatus.displayName(status);

  bool get isPlanned => status == EventStatus.planned;
  bool get isOngoing => status == EventStatus.ongoing;
  bool get isCompleted => status == EventStatus.completed;
  bool get isCancelled => status == EventStatus.cancelled;

  // Alias getters for backward compatibility with UI
  int? get targetAttendees => expectedParticipants;
  int? get actualAttendees => actualParticipants;
  String get organizedBy => organizerId;

  double get attendanceRate {
    if (expectedParticipants == null ||
        expectedParticipants == 0 ||
        actualParticipants == null) {
      return 0.0;
    }
    return (actualParticipants! / expectedParticipants!).clamp(0.0, 2.0);
  }
}

/// Request model for creating/updating events
class EventRequest {
  final String title;
  final String eventType;
  final DateTime eventDate;
  final String? description;
  final String? area;
  final String? startTime;
  final String? endTime;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int? expectedParticipants;
  final int? actualParticipants;
  final String? status;
  final String? notes;

  EventRequest({
    required this.title,
    required this.eventType,
    required this.eventDate,
    this.description,
    this.area,
    this.startTime,
    this.endTime,
    this.location,
    this.latitude,
    this.longitude,
    this.expectedParticipants,
    this.actualParticipants,
    this.status,
    this.notes,
  })  : assert(EventType.isValid(eventType),
            'Invalid event_type. Must be one of: ${EventType.values.join(", ")}'),
        assert(status == null || EventStatus.isValid(status),
            'Invalid status. Must be one of: ${EventStatus.values.join(", ")}');

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'event_type': eventType,
      // Format date only (YYYY-MM-DD)
      'event_date': eventDate.toIso8601String().split('T')[0],
    };
    if (description != null) json['description'] = description;
    if (area != null) json['area'] = area;
    if (startTime != null) json['start_time'] = startTime;
    if (endTime != null) json['end_time'] = endTime;
    if (location != null) json['location'] = location;
    if (latitude != null) json['latitude'] = latitude;
    if (longitude != null) json['longitude'] = longitude;
    if (expectedParticipants != null)
      json['expected_participants'] = expectedParticipants;
    if (actualParticipants != null)
      json['actual_participants'] = actualParticipants;
    if (status != null) json['status'] = status;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

/// Response for listing events with pagination
/// API returns: items[], total, page, per_page, total_pages (flat structure)
class EventListResponse {
  final List<CommunityEvent> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  EventListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory EventListResponse.fromJson(Map<String, dynamic> json) {
    return EventListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CommunityEvent.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 0,
    );
  }

  // Alias for backward compatibility
  List<CommunityEvent> get data => items;
  bool get success => true;
}

// ==================== CAMPAIGN MODELS ====================

/// Health campaign model
/// API fields: name, description, campaign_type, start_date, end_date,
/// target_area, target_population, target_count, reached_count, status,
/// objectives, activities, resources_needed, partners, budget, notes,
/// id, coordinator_id, created_at
class Campaign {
  final String id;
  final String name;
  final String campaignType;
  final String? description;
  final String? targetArea;
  final DateTime startDate;
  final DateTime? endDate;
  final String? targetPopulation; // The population group name
  final int targetCount; // The numeric target count
  final int reachedCount;
  final String status;
  final String? objectives;
  final String? activities;
  final String? resourcesNeeded;
  final String? partners;
  final double? budget;
  final String? notes;
  final String? coordinatorId;
  final DateTime createdAt;

  Campaign({
    required this.id,
    required this.name,
    required this.campaignType,
    this.description,
    this.targetArea,
    required this.startDate,
    this.endDate,
    this.targetPopulation,
    this.targetCount = 0,
    this.reachedCount = 0,
    this.status = CampaignStatus.active,
    this.objectives,
    this.activities,
    this.resourcesNeeded,
    this.partners,
    this.budget,
    this.notes,
    this.coordinatorId,
    required this.createdAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      campaignType: json['campaign_type'] ?? CampaignType.vaccination,
      description: json['description'],
      targetArea: json['target_area'],
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate:
          json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      targetPopulation: json['target_population'],
      targetCount: json['target_count'] ?? 0,
      reachedCount: json['reached_count'] ?? 0,
      status: json['status'] ?? CampaignStatus.active,
      objectives: json['objectives'],
      activities: json['activities'],
      resourcesNeeded: json['resources_needed'],
      partners: json['partners'],
      budget: json['budget']?.toDouble(),
      notes: json['notes'],
      coordinatorId: json['coordinator_id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'campaign_type': campaignType,
      'description': description,
      'target_area': targetArea,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'target_population': targetPopulation,
      'target_count': targetCount,
      'reached_count': reachedCount,
      'status': status,
      'objectives': objectives,
      'activities': activities,
      'resources_needed': resourcesNeeded,
      'partners': partners,
      'budget': budget,
      'notes': notes,
      'coordinator_id': coordinatorId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get campaignTypeDisplay => CampaignType.displayName(campaignType);
  String get statusDisplay => CampaignStatus.displayName(status);

  bool get isActive => status == CampaignStatus.active;
  bool get isCompleted => status == CampaignStatus.completed;
  bool get isCancelled => status == CampaignStatus.cancelled;

  double get progressRate {
    if (targetCount == 0) return 0.0;
    return (reachedCount / targetCount).clamp(0.0, 1.0);
  }
}

/// Request model for creating/updating campaigns
class CampaignRequest {
  final String name;
  final String campaignType;
  final DateTime startDate;
  final String? description;
  final String? targetArea;
  final DateTime? endDate;
  final String? targetPopulation; // Population group name
  final int? targetCount; // Numeric target
  final int? reachedCount;
  final String? status;
  final String? objectives;
  final String? activities;
  final String? resourcesNeeded;
  final String? partners;
  final double? budget;
  final String? notes;

  CampaignRequest({
    required this.name,
    required this.campaignType,
    required this.startDate,
    this.description,
    this.targetArea,
    this.endDate,
    this.targetPopulation,
    this.targetCount,
    this.reachedCount,
    this.status,
    this.objectives,
    this.activities,
    this.resourcesNeeded,
    this.partners,
    this.budget,
    this.notes,
  })  : assert(CampaignType.isValid(campaignType),
            'Invalid campaign_type. Must be one of: ${CampaignType.values.join(", ")}'),
        assert(status == null || CampaignStatus.isValid(status),
            'Invalid status. Must be one of: ${CampaignStatus.values.join(", ")}');

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'campaign_type': campaignType,
      // Format date only (YYYY-MM-DD)
      'start_date': startDate.toIso8601String().split('T')[0],
    };
    if (description != null) json['description'] = description;
    if (targetArea != null) json['target_area'] = targetArea;
    if (endDate != null) {
      json['end_date'] = endDate!.toIso8601String().split('T')[0];
    }
    if (targetPopulation != null) json['target_population'] = targetPopulation;
    if (targetCount != null) json['target_count'] = targetCount;
    if (reachedCount != null) json['reached_count'] = reachedCount;
    if (status != null) json['status'] = status;
    if (objectives != null) json['objectives'] = objectives;
    if (activities != null) json['activities'] = activities;
    if (resourcesNeeded != null) json['resources_needed'] = resourcesNeeded;
    if (partners != null) json['partners'] = partners;
    if (budget != null) json['budget'] = budget;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

/// Response for listing campaigns with pagination
/// API returns: items[], total, page, per_page, total_pages (flat structure)
class CampaignListResponse {
  final List<Campaign> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  CampaignListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory CampaignListResponse.fromJson(Map<String, dynamic> json) {
    return CampaignListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => Campaign.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 0,
    );
  }

  // Alias for backward compatibility
  List<Campaign> get data => items;
  bool get success => true;
}

// ==================== PARTICIPANT MODELS ====================

/// Campaign participant model
class CampaignParticipant {
  final String id;
  final String campaignId;
  final String participantId;
  final String? participantName;
  final String? participantType;
  final DateTime registeredAt;
  final bool attended;
  final DateTime? attendedAt;
  final String? notes;

  CampaignParticipant({
    required this.id,
    required this.campaignId,
    required this.participantId,
    this.participantName,
    this.participantType,
    required this.registeredAt,
    this.attended = false,
    this.attendedAt,
    this.notes,
  });

  factory CampaignParticipant.fromJson(Map<String, dynamic> json) {
    return CampaignParticipant(
      id: json['id'] ?? '',
      campaignId: json['campaign_id'] ?? '',
      participantId: json['participant_id'] ?? '',
      participantName: json['participant_name'],
      participantType: json['participant_type'],
      registeredAt:
          DateTime.tryParse(json['registered_at'] ?? '') ?? DateTime.now(),
      attended: json['attended'] ?? false,
      attendedAt: json['attended_at'] != null
          ? DateTime.tryParse(json['attended_at'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'participant_id': participantId,
      'participant_name': participantName,
      'participant_type': participantType,
      'registered_at': registeredAt.toIso8601String(),
      'attended': attended,
      'attended_at': attendedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}

/// Request model for registering a campaign participant
class CampaignRegistrationRequest {
  final String participantId;
  final String? participantType;
  final String? notes;

  CampaignRegistrationRequest({
    required this.participantId,
    this.participantType,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'participant_id': participantId,
    };
    if (participantType != null) json['participant_type'] = participantType;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

/// Response for listing campaign participants
/// API returns: items[], total, page, per_page, total_pages (flat structure)
class ParticipantListResponse {
  final List<CampaignParticipant> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  ParticipantListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory ParticipantListResponse.fromJson(Map<String, dynamic> json) {
    return ParticipantListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CampaignParticipant.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 0,
    );
  }

  // Alias for backward compatibility
  List<CampaignParticipant> get data => items;
  bool get success => true;
}

// ==================== API EXCEPTION ====================

/// Exception for engagement API errors
class EngagementApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  EngagementApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'EngagementApiException: $message';
}

/// Represents an AI personality/Pal with custom settings
class AIPal {
  final String id;
  final String name;
  final String systemPrompt;
  final double temperature;
  final double topP;
  final int nCtx;
  final String? color; // Hex color for chat
  final DateTime createdAt;
  
  // Offline mode settings
  final bool useOfflineMode; // Whether this pal uses offline model
  final String? offlineModelId; // ID of offline model to use

  AIPal({
    required this.id,
    required this.name,
    required this.systemPrompt,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.nCtx = 2048,
    this.color,
    DateTime? createdAt,
    this.useOfflineMode = false,
    this.offlineModelId,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'systemPrompt': systemPrompt,
        'temperature': temperature,
        'topP': topP,
        'nCtx': nCtx,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
        'useOfflineMode': useOfflineMode,
        'offlineModelId': offlineModelId,
      };

  /// Create from JSON
  factory AIPal.fromJson(Map<String, dynamic> json) => AIPal(
        id: json['id'] as String,
        name: json['name'] as String,
        systemPrompt: json['systemPrompt'] as String,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        topP: (json['topP'] as num?)?.toDouble() ?? 0.9,
        nCtx: json['nCtx'] as int? ?? 2048,
        color: json['color'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        useOfflineMode: json['useOfflineMode'] as bool? ?? false,
        offlineModelId: json['offlineModelId'] as String?,
      );

  /// Create a copy with modified fields
  AIPal copyWith({
    String? id,
    String? name,
    String? systemPrompt,
    double? temperature,
    double? topP,
    int? nCtx,
    String? color,
    bool? useOfflineMode,
    String? offlineModelId,
  }) =>
      AIPal(
        id: id ?? this.id,
        name: name ?? this.name,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        temperature: temperature ?? this.temperature,
        topP: topP ?? this.topP,
        nCtx: nCtx ?? this.nCtx,
        color: color ?? this.color,
        createdAt: createdAt,
        useOfflineMode: useOfflineMode ?? this.useOfflineMode,
        offlineModelId: offlineModelId ?? this.offlineModelId,
      );

  @override
  String toString() => 'AIPal(id: $id, name: $name, temp: $temperature)';
}

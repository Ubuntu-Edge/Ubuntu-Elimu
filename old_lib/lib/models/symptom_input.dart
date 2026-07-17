class SymptomInput {
  final String patientId;
  final String rawText;
  final int? age;
  final String? ageUnit;
  final String gender;
  final bool isPregnant;
  final bool hasChronicConditions;
  final String? chronicConditions;
  final String? village;
  final DateTime timestamp;

  SymptomInput({
    required this.patientId,
    required this.rawText,
    this.age,
    this.ageUnit = 'years',
    required this.gender,
    this.isPregnant = false,
    this.hasChronicConditions = false,
    this.chronicConditions,
    this.village,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get ageDisplay {
    if (age == null) return 'Age unknown';
    return '$age $ageUnit';
  }

  String get contextSummary {
    final parts = <String>[];
    if (age != null) parts.add('$age $ageUnit old');
    parts.add(gender);
    if (isPregnant) parts.add('pregnant');
    if (hasChronicConditions) parts.add('chronic conditions');
    return parts.join(', ');
  }
}
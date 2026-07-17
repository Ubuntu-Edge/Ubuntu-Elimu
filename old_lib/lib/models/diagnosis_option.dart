// lib/models/diagnosis_option.dart

class DiagnosisOption {
  final String condition;
  final int confidencePercent;
  final String reasoning;

  DiagnosisOption({
    required this.condition,
    required this.confidencePercent,
    required this.reasoning,
  });

  String get confidenceDisplay => '$confidencePercent%';
}
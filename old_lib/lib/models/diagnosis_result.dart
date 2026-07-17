import 'package:chw_augment/models/triage_level.dart';
import 'package:chw_augment/models/symptom_input.dart';
// 🛑 FIX: Import DiagnosisOption from its separate file
import 'package:chw_augment/models/diagnosis_option.dart';

class DiagnosisResult {
  final String id;
  final SymptomInput input;
  final List<DiagnosisOption> diagnoses;
  final TriageLevel triageLevel;
  final List<String> immediateActions;
  final List<String> treatment;
  final List<String> redFlags;
  final bool shouldRefer;
  final String? referralReason;
  final String followUpAdvice;
  final DateTime timestamp;
  final int inferenceTimeMs;

  DiagnosisResult({
    required this.id,
    required this.input,
    required this.diagnoses,
    required this.triageLevel,
    required this.immediateActions,
    required this.treatment,
    required this.redFlags,
    required this.shouldRefer,
    this.referralReason,
    required this.followUpAdvice,
    DateTime? timestamp,
    required this.inferenceTimeMs,
  }) : timestamp = timestamp ?? DateTime.now();

  DiagnosisOption? get primaryDiagnosis {
    if (diagnoses.isEmpty) return null;
    return diagnoses.first;
  }
}
import 'package:flutter/material.dart';
import '../models/symptom_input.dart';
import '../models/diagnosis_result.dart';
import '../models/diagnosis_option.dart';
import '../models/triage_level.dart';
import '../services/ai_service.dart';
import '../services/symptom_parser.dart';

class DiagnosisProvider with ChangeNotifier {
  final AIService _aiService = AIService.instance;
  final SymptomParser _parser = SymptomParser.instance;

  bool _isLoading = false;
  DiagnosisResult? _currentDiagnosis;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  DiagnosisResult? get currentDiagnosis => _currentDiagnosis;
  String? get errorMessage => _errorMessage;

  /// Run diagnosis using the online AI service.
  Future<bool> diagnose(SymptomInput input) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_parser.isEmergency(input.rawText)) {
        print('⚠️ Emergency detected in symptoms!');
      }

      // Call the new online service, which returns a raw string.
      final responseText = await _aiService.generateResponse(input.rawText);

      // Manually construct a DiagnosisResult from the raw text response.
      final result = DiagnosisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        input: input,
        diagnoses: [
          DiagnosisOption(
            condition: "AI Guidance",
            confidencePercent: 90, // Placeholder confidence
            reasoning: "Response from online MedGemma model.",
          )
        ],
        triageLevel: TriageLevel.routine, // Default triage, as parsing logic is removed
        immediateActions: [], // These would need to be parsed from `responseText`
        treatment: [responseText], // We place the full AI response in the treatment section
        redFlags: [], // These would need to be parsed from `responseText`
        shouldRefer: false, // Default value
        referralReason: '', // Added missing required parameter
        followUpAdvice: '', // Added missing required parameter
        timestamp: DateTime.now(),
        inferenceTimeMs: 0, // Not applicable for online API
      );

      _currentDiagnosis = result;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Diagnosis failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear current diagnosis
  void clearDiagnosis() {
    _currentDiagnosis = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get extracted symptoms
  List<String> getExtractedSymptoms(String text) {
    return _parser.extractSymptoms(text);
  }
}

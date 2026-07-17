class Disease {
  final String id;
  final String name;
  final String category;
  final List<String> commonIn;
  final String description;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> riskFactors;
  final List<String> diagnosisSteps;
  final List<String> dangerSigns;
  final String treatmentMild;
  final String treatmentSevere;
  final List<String> whenToRefer;
  final List<String> prevention;
  final String followUp;

  Disease({
    required this.id,
    required this.name,
    required this.category,
    required this.commonIn,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.riskFactors,
    required this.diagnosisSteps,
    required this.dangerSigns,
    required this.treatmentMild,
    required this.treatmentSevere,
    required this.whenToRefer,
    required this.prevention,
    required this.followUp,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      commonIn: List<String>.from(json['common_in']),
      description: json['description'],
      symptoms: List<String>.from(json['symptoms']),
      causes: List<String>.from(json['causes']),
      riskFactors: List<String>.from(json['risk_factors']),
      diagnosisSteps: List<String>.from(json['diagnosis_steps']),
      dangerSigns: List<String>.from(json['danger_signs']),
      treatmentMild: json['treatment_mild'],
      treatmentSevere: json['treatment_severe'],
      whenToRefer: List<String>.from(json['when_to_refer']),
      prevention: List<String>.from(json['prevention']),
      followUp: json['follow_up'],
    );
  }
}
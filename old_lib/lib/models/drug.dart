class Drug {
  final String id;
  final String name;
  final List<String> brandNames;
  final String drugClass;
  final List<String> uses;
  final String dosageAdult;
  final String dosageChild;
  final String dosageCalculation;
  final List<String> forms;
  final List<String> administration;
  final List<String> sideEffects;
  final List<String> warnings;
  final bool pregnancySafe;
  final bool breastfeedingSafe;
  final List<String> counseling;

  Drug({
    required this.id,
    required this.name,
    required this.brandNames,
    required this.drugClass,
    required this.uses,
    required this.dosageAdult,
    required this.dosageChild,
    required this.dosageCalculation,
    required this.forms,
    required this.administration,
    required this.sideEffects,
    required this.warnings,
    required this.pregnancySafe,
    required this.breastfeedingSafe,
    required this.counseling,
  });

  factory Drug.fromJson(Map<String, dynamic> json) {
    return Drug(
      id: json['id'],
      name: json['name'],
      brandNames: List<String>.from(json['brand_names']),
      drugClass: json['drug_class'],
      uses: List<String>.from(json['uses']),
      dosageAdult: json['dosage_adult'],
      dosageChild: json['dosage_child'],
      dosageCalculation: json['dosage_calculation'],
      forms: List<String>.from(json['forms']),
      administration: List<String>.from(json['administration']),
      sideEffects: List<String>.from(json['side_effects']),
      warnings: List<String>.from(json['warnings']),
      pregnancySafe: json['pregnancy_safe'].toString().toLowerCase() == 'true',
      breastfeedingSafe: json['breastfeeding_safe'].toString().toLowerCase() == 'true',
      counseling: List<String>.from(json['counseling']),
    );
  }

  // Calculate dosage based on weight
  double calculateChildDosage(double weightKg) {
    // Extract mg/kg from dosage_child string
    // Example: "10-15mg per kg" → use 15 (max safe dose)
    return weightKg * 15;
  }
}
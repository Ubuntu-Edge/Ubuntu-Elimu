import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/disease.dart';
import '../models/drug.dart';

class MedicalLibraryService {
  static final MedicalLibraryService instance = MedicalLibraryService._init();
  MedicalLibraryService._init();

  List<Disease> _diseases = [];
  List<Drug> _drugs = [];
  bool _isLoaded = false;

  List<Disease> get diseases => _diseases;
  List<Drug> get drugs => _drugs;
  bool get isLoaded => _isLoaded;

  // Load all medical library data
  Future<void> loadLibrary() async {
    if (_isLoaded) return;

    try {
      await Future.wait([
        _loadDiseases(),
        _loadDrugs(),
      ]);
      _isLoaded = true;
      print('✅ Medical library loaded: ${_diseases.length} diseases, ${_drugs.length} drugs');
    } catch (e) {
      print('❌ Error loading medical library: $e');
      throw Exception('Failed to load medical library');
    }
  }

  // Load diseases from JSON
  Future<void> _loadDiseases() async {
    final String jsonString = await rootBundle.loadString(
      'assets/medical_library/diseases.json',
    );
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> diseasesList = jsonData['diseases'];

    _diseases = diseasesList
        .map((diseaseJson) => Disease.fromJson(diseaseJson))
        .toList();
  }

  // Load drugs from JSON
  Future<void> _loadDrugs() async {
    final String jsonString = await rootBundle.loadString(
      'assets/medical_library/medications.json',
    );
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> drugsList = jsonData['medications'];

    _drugs = drugsList
        .map((drugJson) => Drug.fromJson(drugJson))
        .toList();
  }

  // Search diseases by name or symptoms
  List<Disease> searchDiseases(String query) {
    final lowerQuery = query.toLowerCase();
    return _diseases.where((disease) {
      return disease.name.toLowerCase().contains(lowerQuery) ||
          disease.category.toLowerCase().contains(lowerQuery) ||
          disease.symptoms.any((s) => s.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Search drugs
  List<Drug> searchDrugs(String query) {
    final lowerQuery = query.toLowerCase();
    return _drugs.where((drug) {
      return drug.name.toLowerCase().contains(lowerQuery) ||
          drug.brandNames.any((b) => b.toLowerCase().contains(lowerQuery)) ||
          drug.uses.any((u) => u.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Get disease by ID
  Disease? getDiseaseById(String id) {
    try {
      return _diseases.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get drug by ID
  Drug? getDrugById(String id) {
    try {
      return _drugs.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get diseases by category
  List<Disease> getDiseasesByCategory(String category) {
    return _diseases
        .where((d) => d.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Calculate drug dosage
  String calculateDosage(String drugId, double weightKg, String ageGroup) {
    final drug = getDrugById(drugId);
    if (drug == null) return 'Drug not found';

    if (ageGroup == 'child') {
      final dosage = drug.calculateChildDosage(weightKg);
      return '${dosage.toStringAsFixed(0)}mg per dose';
    }
    return drug.dosageAdult;
  }
}
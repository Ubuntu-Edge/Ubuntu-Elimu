import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/ai_pal.dart';
import 'package:uuid/uuid.dart';

class PalProvider extends ChangeNotifier {
  List<AIPal> _pals = [];
  AIPal? _selectedPal;
  static const String _palsKey = 'ai_pals';
  static const String _selectedPalKey = 'selected_pal_id';

  List<AIPal> get pals => _pals;
  AIPal? get selectedPal => _selectedPal;

  /// Initialize by loading from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load pals
      final palsJson = prefs.getStringList(_palsKey) ?? [];
      _pals = palsJson.map((json) => AIPal.fromJson(jsonDecode(json))).toList();

      // Create default pals if none exist
      if (_pals.isEmpty) {
        await _createDefaultPals();
      }

      // Load selected pal
      final selectedId = prefs.getString(_selectedPalKey);
      if (selectedId != null) {
        _selectedPal = _pals.firstWhere(
          (p) => p.id == selectedId,
          orElse: () => _pals.first,
        );
      } else {
        _selectedPal = _pals.first;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('PalProvider initialization failed: $e');
      // Create default pals in memory
      await _createDefaultPals();
      _selectedPal = _pals.isNotEmpty ? _pals.first : null;
      notifyListeners();
    }
  }

  /// Create default pals
  Future<void> _createDefaultPals() async {
    final defaultPals = [
      AIPal(
        id: const Uuid().v4(),
        name: 'Medical Assistant',
        systemPrompt:
            'You are a helpful medical assistant for Community Health Workers. Provide clear, evidence-based medical guidance. Always encourage users to seek professional medical help for serious conditions.',
        temperature: 0.5,
        topP: 0.9,
        nCtx: 2048,
        color: '#2196F3',
      ),
      AIPal(
        id: const Uuid().v4(),
        name: 'Friendly Chat',
        systemPrompt:
            'You are a friendly and conversational AI assistant. Be warm, engaging, and helpful. Keep responses concise and natural.',
        temperature: 0.8,
        topP: 0.95,
        nCtx: 2048,
        color: '#4CAF50',
      ),
      AIPal(
        id: const Uuid().v4(),
        name: 'Detailed Expert',
        systemPrompt:
            'You are an expert AI assistant. Provide comprehensive, detailed, and thorough responses. Include relevant context and explain your reasoning.',
        temperature: 0.3,
        topP: 0.85,
        nCtx: 2048,
        color: '#FF9800',
      ),
    ];

    _pals = defaultPals;
    _selectedPal = _pals.first;
    await _savePals();
    notifyListeners();
  }

  /// Create a new pal
  Future<void> createPal({
    required String name,
    required String systemPrompt,
    double temperature = 0.7,
    double topP = 0.9,
    int nCtx = 2048,
    String? color,
    bool useOfflineMode = false,
    String? offlineModelId,
  }) async {
    final newPal = AIPal(
      id: const Uuid().v4(),
      name: name,
      systemPrompt: systemPrompt,
      temperature: temperature,
      topP: topP,
      nCtx: nCtx,
      color: color,
      useOfflineMode: useOfflineMode,
      offlineModelId: offlineModelId,
    );

    _pals.add(newPal);
    await _savePals();
    notifyListeners();
  }

  /// Update an existing pal
  Future<void> updatePal(AIPal updatedPal) async {
    final index = _pals.indexWhere((p) => p.id == updatedPal.id);
    if (index != -1) {
      _pals[index] = updatedPal;
      if (_selectedPal?.id == updatedPal.id) {
        _selectedPal = updatedPal;
      }
      await _savePals();
      notifyListeners();
    }
  }

  /// Delete a pal
  Future<void> deletePal(String palId) async {
    _pals.removeWhere((p) => p.id == palId);

    // Switch to another pal if the deleted one was selected
    if (_selectedPal?.id == palId) {
      _selectedPal = _pals.isNotEmpty ? _pals.first : null;
    }

    await _savePals();
    notifyListeners();
  }

  /// Select a pal
  Future<void> selectPal(AIPal pal) async {
    _selectedPal = pal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedPalKey, pal.id);
    notifyListeners();
  }

  /// Save all pals to SharedPreferences
  Future<void> _savePals() async {
    final prefs = await SharedPreferences.getInstance();
    final palsJson = _pals.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_palsKey, palsJson);
  }
}

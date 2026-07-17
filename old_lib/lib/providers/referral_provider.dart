import 'package:flutter/foundation.dart';
import '../models/referral.dart';
import '../models/referral_models.dart';
import '../services/database_service.dart';
import '../services/referral_api_service.dart';
import '../services/connectivity_service.dart';

class ReferralProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final ReferralApiService _apiService = ReferralApiService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;

  List<Referral> _referrals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Referral> get referrals => _referrals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _connectivity.isOnline;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Fetch referrals with offline-first approach
  /// - If online: fetches from API and syncs to local DB
  /// - If offline: loads from local DB only
  Future<void> fetchReferrals(String chwId) async {
    setLoading(true);
    try {
      debugPrint('Fetching referrals for CHW ID: $chwId');
      
      if (isOnline) {
        // Online: Fetch from API
        try {
          final response = await _apiService.listReferrals(perPage: 100);
          
          // Convert API responses to local Referral models
          _referrals = response.data.map((apiReferral) => _convertApiToLocal(apiReferral)).toList();
          
          // Sync to local database
          for (final referral in _referrals) {
            await _databaseService.createOrUpdateReferral(referral.copyWith(
              isSynced: true,
              pendingSync: false,
              lastSyncedAt: DateTime.now(),
            ));
          }
          
          debugPrint('✅ Fetched ${_referrals.length} referrals from API');
        } catch (e) {
          debugPrint('❌ API fetch failed: $e, falling back to local DB');
          _referrals = await _databaseService.getReferralsByCHW(chwId);
        }
      } else {
        // Offline: Load from local database
        _referrals = await _databaseService.getReferralsByCHW(chwId);
        debugPrint('📱 Loaded ${_referrals.length} referrals from local DB (offline)');
      }
      
      _errorMessage = null;
    } catch (e) {
      debugPrint('Error fetching referrals: $e');
      _errorMessage = 'Failed to fetch referrals: $e';
    } finally {
      setLoading(false);
    }
  }

  /// Create a new referral
  /// - If online: creates via API and saves to local DB
  /// - If offline: saves to local DB with pendingSync flag
  Future<void> addReferral(Referral referral) async {
    setLoading(true);
    try {
      debugPrint('Adding referral for patient ${referral.patientId}');
      
      if (isOnline) {
        // Online: Create via API
        final request = ReferralCreateRequest(
          patientId: referral.patientId,
          referralReason: referral.referralReason,
          referredTo: referral.referredTo,
          clinicalNotes: referral.notes,
          facilityType: referral.facilityType,
          department: referral.department,
          urgency: referral.urgency,
          transportArranged: referral.transportMethod != null,
          transportType: referral.transportMethod,
          accompaniedBy: referral.accompaniedBy,
          appointmentDate: referral.estimatedArrivalTime,
          notes: referral.notes,
        );
        
        final apiResponse = await _apiService.createReferral(request);
        
        // Save to local DB with API-assigned ID
        final syncedReferral = _convertApiToLocal(apiResponse).copyWith(
          isSynced: true,
          pendingSync: false,
          lastSyncedAt: DateTime.now(),
        );
        await _databaseService.createOrUpdateReferral(syncedReferral);
        
        debugPrint('✅ Referral created via API: ${apiResponse.id}');
      } else {
        // Offline: Save to local DB with pending sync
        final offlineReferral = referral.copyWith(
          isSynced: false,
          pendingSync: true,
        );
        await _databaseService.createReferral(offlineReferral);
        debugPrint('📱 Referral saved locally (pending sync)');
      }
      
      _errorMessage = null;
      await fetchReferrals(referral.chwId);
    } catch (e) {
      debugPrint('Error adding referral: $e');
      _errorMessage = 'Failed to add referral: $e';
    } finally {
      setLoading(false);
    }
  }

  /// Update an existing referral
  Future<void> updateReferral(Referral referral) async {
    setLoading(true);
    try {
      if (isOnline && referral.isSynced) {
        // Online: Update via API
        final request = ReferralUpdateRequest(
          referralReason: referral.referralReason,
          referredTo: referral.referredTo,
          clinicalNotes: referral.notes,
          facilityType: referral.facilityType,
          department: referral.department,
          urgency: referral.urgency,
          transportArranged: referral.transportMethod != null,
          transportType: referral.transportMethod,
          accompaniedBy: referral.accompaniedBy,
          appointmentDate: referral.estimatedArrivalTime,
          notes: referral.notes,
        );
        
        await _apiService.updateReferral(referral.id, request);
        debugPrint('✅ Referral updated via API');
      }
      
      // Always update local DB
      await _databaseService.updateReferral(referral.copyWith(
        pendingSync: !isOnline || !referral.isSynced,
        lastSyncedAt: isOnline ? DateTime.now() : referral.lastSyncedAt,
      ));
      
      _errorMessage = null;
      await fetchReferrals(referral.chwId);
    } catch (e) {
      debugPrint('Error updating referral: $e');
      _errorMessage = 'Failed to update referral: $e';
    } finally {
      setLoading(false);
    }
  }
  
  /// Update referral status
  Future<void> updateReferralStatus(String referralId, String status, {
    String? outcome,
    String? outcomeDate,
    String? facilityFeedback,
    String? facilityDiagnosis,
    String? facilityTreatment,
    String? followUpInstructions,
  }) async {
    setLoading(true);
    try {
      if (isOnline) {
        final request = ReferralStatusUpdateRequest(
          status: status,
          outcome: outcome,
          outcomeDate: outcomeDate,
          facilityFeedback: facilityFeedback,
          facilityDiagnosis: facilityDiagnosis,
          facilityTreatment: facilityTreatment,
          followUpInstructions: followUpInstructions,
        );
        
        await _apiService.updateReferralStatus(referralId, request);
        debugPrint('✅ Referral status updated via API');
      }
      
      // Update local DB
      final referral = _referrals.firstWhere((r) => r.id == referralId);
      final updatedReferral = referral.copyWith(
        status: status,
        outcome: outcome,
        outcomeDate: DateTime.now(),
        pendingSync: !isOnline,
        lastSyncedAt: isOnline ? DateTime.now() : referral.lastSyncedAt,
      );
      
      await _databaseService.updateReferral(updatedReferral);
      await fetchReferrals(referral.chwId);
      
      _errorMessage = null;
    } catch (e) {
      debugPrint('Error updating referral status: $e');
      _errorMessage = 'Failed to update status: $e';
    } finally {
      setLoading(false);
    }
  }
  
  /// Delete a referral
  Future<void> deleteReferral(String referralId) async {
    setLoading(true);
    try {
      final referral = _referrals.firstWhere((r) => r.id == referralId);
      
      if (isOnline && referral.isSynced) {
        await _apiService.deleteReferral(referralId);
        debugPrint('✅ Referral deleted via API');
      }
      
      await _databaseService.deleteReferral(referralId);
      _referrals.removeWhere((r) => r.id == referralId);
      
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting referral: $e');
      _errorMessage = 'Failed to delete referral: $e';
    } finally {
      setLoading(false);
    }
  }
  
  /// Convert API ReferralResponse to local Referral model
  Referral _convertApiToLocal(ReferralResponse apiReferral) {
    return Referral(
      id: apiReferral.id,
      patientId: apiReferral.patientId,
      chwId: apiReferral.chwId ?? '',
      referralDate: apiReferral.referralDate != null 
          ? (DateTime.tryParse(apiReferral.referralDate!) ?? DateTime.now())
          : DateTime.now(),
      referralReason: apiReferral.referralReason,
      referredTo: apiReferral.referredTo,
      urgency: apiReferral.urgency,
      status: apiReferral.status,
      facilityType: apiReferral.facilityType,
      department: apiReferral.department,
      transportMethod: apiReferral.transportType,
      estimatedArrivalTime: apiReferral.appointmentDate,
      accompaniedBy: apiReferral.accompaniedBy,
      reminderSent: apiReferral.reminderSent,
      reminderSentAt: apiReferral.reminderSentAt != null ? DateTime.tryParse(apiReferral.reminderSentAt!) : null,
      outcome: apiReferral.outcome,
      outcomeDate: apiReferral.outcomeDate != null ? DateTime.tryParse(apiReferral.outcomeDate!) : null,
      notes: apiReferral.notes,
      createdAt: apiReferral.createdAt != null ? DateTime.tryParse(apiReferral.createdAt!) : null,
      updatedAt: apiReferral.updatedAt != null ? DateTime.tryParse(apiReferral.updatedAt!) : null,
      syncVersion: apiReferral.syncVersion,
      lastSyncedAt: apiReferral.lastSyncedAt != null ? DateTime.tryParse(apiReferral.lastSyncedAt!) : null,
      isSynced: true,
      pendingSync: false,
    );
  }
}

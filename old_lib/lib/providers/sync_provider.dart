import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';

/// SyncProvider wraps SyncService for use with Provider state management
class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService.instance;
  
  SyncStatus get status => _syncService.status;
  SyncResult? get lastSyncResult => _syncService.lastSyncResult;
  DateTime? get lastSyncTime => _syncService.lastSyncTime;
  List<SyncResult> get syncHistory => _syncService.syncHistory;
  bool get isSyncing => _syncService.isSyncing;
  
  SyncProvider() {
    _syncService.addListener(_onSyncServiceUpdate);
  }
  
  void _onSyncServiceUpdate() {
    notifyListeners();
  }
  
  /// Initialize the sync service
  Future<void> initialize({Duration? autoSyncInterval}) async {
    await _syncService.initialize(autoSyncInterval: autoSyncInterval);
  }
  
  /// Trigger a full sync
  Future<SyncResult> syncAll() async {
    return await _syncService.syncAll();
  }
  
  /// Start automatic synchronization
  void startAutoSync(Duration interval) {
    _syncService.startAutoSync(interval);
  }
  
  /// Stop automatic synchronization
  void stopAutoSync() {
    _syncService.stopAutoSync();
  }
  
  /// Get sync statistics
  Future<Map<String, int>> getSyncStatistics() async {
    return await _syncService.getSyncStatistics();
  }
  
  /// Prepare data for export
  Future<Map<String, List<Map<String, dynamic>>>> prepareDataForExport(String chwId) async {
    return await _syncService.prepareDataForExport(chwId);
  }
  
  /// Clear sync history
  void clearSyncHistory() {
    _syncService.clearSyncHistory();
  }
  
  @override
  void dispose() {
    _syncService.removeListener(_onSyncServiceUpdate);
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';

/// Types of audit log operations
enum AuditOperation {
  create,
  update,
  delete,
  login,
  logout,
  sync,
  view,
}

/// Types of entities that can be audited
enum AuditEntity {
  patient,
  visit,
  reminder,
  referral,
  family,
  chatMessage,
  user,
  system,
}

/// Represents a single audit log entry
class AuditLogEntry {
  final String id;
  final String userId;
  final AuditOperation operation;
  final AuditEntity entity;
  final String? entityId;
  final String? description;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final bool wasOffline;
  final bool isSynced;
  final DateTime timestamp;

  AuditLogEntry({
    required this.id,
    required this.userId,
    required this.operation,
    required this.entity,
    this.entityId,
    this.description,
    this.oldValue,
    this.newValue,
    required this.wasOffline,
    this.isSynced = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'operation': operation.name,
      'entity': entity.name,
      'entity_id': entityId,
      'description': description,
      'old_value': oldValue != null ? jsonEncode(oldValue) : null,
      'new_value': newValue != null ? jsonEncode(newValue) : null,
      'was_offline': wasOffline ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id'],
      userId: map['user_id'],
      operation: AuditOperation.values.firstWhere(
        (e) => e.name == map['operation'],
        orElse: () => AuditOperation.view,
      ),
      entity: AuditEntity.values.firstWhere(
        (e) => e.name == map['entity'],
        orElse: () => AuditEntity.system,
      ),
      entityId: map['entity_id'],
      description: map['description'],
      oldValue: map['old_value'] != null ? jsonDecode(map['old_value']) : null,
      newValue: map['new_value'] != null ? jsonDecode(map['new_value']) : null,
      wasOffline: map['was_offline'] == 1,
      isSynced: map['is_synced'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

/// Service for recording and managing audit logs
/// Tracks all operations performed in the app, both online and offline
class AuditLogService extends ChangeNotifier {
  static final AuditLogService instance = AuditLogService._init();
  AuditLogService._init();

  final DatabaseService _dbService = DatabaseService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final AuthService _authService = AuthService.instance;

  bool _isInitialized = false;

  /// Initialize the audit log service and create table if needed
  Future<void> initialize() async {
    if (_isInitialized) return;

    final db = await _dbService.database;

    // Create audit_logs table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        entity TEXT NOT NULL,
        entity_id TEXT,
        description TEXT,
        old_value TEXT,
        new_value TEXT,
        was_offline INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_logs(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity, entity_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_logs(timestamp DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_synced ON audit_logs(is_synced)');

    _isInitialized = true;
    debugPrint('📋 AuditLogService initialized');
  }

  /// Log an operation
  Future<void> log({
    required AuditOperation operation,
    required AuditEntity entity,
    String? entityId,
    String? description,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      final currentUser = await _authService.getCurrentCHW();
      final userId = currentUser?.id ?? 'unknown';
      final wasOffline = !_connectivity.isOnline;

      final entry = AuditLogEntry(
        id: '${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 8)}',
        userId: userId,
        operation: operation,
        entity: entity,
        entityId: entityId,
        description: description,
        oldValue: oldValue,
        newValue: newValue,
        wasOffline: wasOffline,
        isSynced: false,
      );

      final db = await _dbService.database;
      await db.insert('audit_logs', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      debugPrint('📋 Audit: ${operation.name} ${entity.name} ${entityId ?? ''} (offline: $wasOffline)');
    } catch (e) {
      debugPrint('❌ Failed to write audit log: $e');
    }
  }

  /// Log a patient operation
  Future<void> logPatient({
    required AuditOperation operation,
    required String patientId,
    String? description,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    await log(
      operation: operation,
      entity: AuditEntity.patient,
      entityId: patientId,
      description: description,
      oldValue: oldValue,
      newValue: newValue,
    );
  }

  /// Log a visit operation
  Future<void> logVisit({
    required AuditOperation operation,
    required String visitId,
    String? description,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    await log(
      operation: operation,
      entity: AuditEntity.visit,
      entityId: visitId,
      description: description,
      oldValue: oldValue,
      newValue: newValue,
    );
  }

  /// Log a user action (login, logout, etc.)
  Future<void> logUserAction({
    required AuditOperation operation,
    String? description,
  }) async {
    await log(
      operation: operation,
      entity: AuditEntity.user,
      description: description,
    );
  }

  /// Log a sync operation
  Future<void> logSync({
    required String description,
    Map<String, dynamic>? details,
  }) async {
    await log(
      operation: AuditOperation.sync,
      entity: AuditEntity.system,
      description: description,
      newValue: details,
    );
  }

  /// Get audit logs for a specific entity
  Future<List<AuditLogEntry>> getLogsForEntity(AuditEntity entity, String entityId) async {
    final db = await _dbService.database;
    final result = await db.query(
      'audit_logs',
      where: 'entity = ? AND entity_id = ?',
      whereArgs: [entity.name, entityId],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => AuditLogEntry.fromMap(map)).toList();
  }

  /// Get audit logs for a user
  Future<List<AuditLogEntry>> getLogsForUser(String userId, {int? limit}) async {
    final db = await _dbService.database;
    final result = await db.query(
      'audit_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result.map((map) => AuditLogEntry.fromMap(map)).toList();
  }

  /// Get all unsynced audit logs
  Future<List<AuditLogEntry>> getUnsyncedLogs() async {
    final db = await _dbService.database;
    final result = await db.query(
      'audit_logs',
      where: 'is_synced = 0',
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => AuditLogEntry.fromMap(map)).toList();
  }

  /// Get logs that occurred while offline
  Future<List<AuditLogEntry>> getOfflineLogs() async {
    final db = await _dbService.database;
    final result = await db.query(
      'audit_logs',
      where: 'was_offline = 1',
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => AuditLogEntry.fromMap(map)).toList();
  }

  /// Mark logs as synced
  Future<void> markAsSynced(List<String> logIds) async {
    if (logIds.isEmpty) return;

    final db = await _dbService.database;
    final placeholders = logIds.map((_) => '?').join(',');
    await db.rawUpdate(
      'UPDATE audit_logs SET is_synced = 1 WHERE id IN ($placeholders)',
      logIds,
    );
  }

  /// Get audit statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _dbService.database;

    final totalLogs = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM audit_logs'),
    ) ?? 0;

    final unsyncedLogs = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM audit_logs WHERE is_synced = 0'),
    ) ?? 0;

    final offlineLogs = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM audit_logs WHERE was_offline = 1'),
    ) ?? 0;

    final operationCounts = await db.rawQuery('''
      SELECT operation, COUNT(*) as count 
      FROM audit_logs 
      GROUP BY operation
    ''');

    final entityCounts = await db.rawQuery('''
      SELECT entity, COUNT(*) as count 
      FROM audit_logs 
      GROUP BY entity
    ''');

    return {
      'totalLogs': totalLogs,
      'unsyncedLogs': unsyncedLogs,
      'offlineLogs': offlineLogs,
      'operationCounts': Map.fromEntries(
        operationCounts.map((r) => MapEntry(r['operation'] as String, r['count'] as int)),
      ),
      'entityCounts': Map.fromEntries(
        entityCounts.map((r) => MapEntry(r['entity'] as String, r['count'] as int)),
      ),
    };
  }

  /// Sync audit logs with backend
  /// Returns the number of logs synced
  Future<int> syncWithBackend() async {
    if (!_connectivity.isOnline) {
      debugPrint('📋 Cannot sync audit logs - offline');
      return 0;
    }

    try {
      final unsyncedLogs = await getUnsyncedLogs();
      if (unsyncedLogs.isEmpty) {
        debugPrint('📋 No audit logs to sync');
        return 0;
      }

      debugPrint('📋 Syncing ${unsyncedLogs.length} audit logs...');

      // TODO: Send logs to backend API
      // For now, just mark them as synced
      // In production, you would:
      // 1. Send batch to /api/v1/sync/audit-logs
      // 2. On success, mark as synced
      // 3. Handle failures gracefully

      final logIds = unsyncedLogs.map((l) => l.id).toList();
      await markAsSynced(logIds);

      debugPrint('📋 Synced ${logIds.length} audit logs');
      return logIds.length;
    } catch (e) {
      debugPrint('❌ Failed to sync audit logs: $e');
      return 0;
    }
  }

  /// Clear old synced logs (keep last 30 days)
  Future<int> cleanupOldLogs({int daysToKeep = 30}) async {
    final db = await _dbService.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    final deleted = await db.delete(
      'audit_logs',
      where: 'is_synced = 1 AND timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    debugPrint('📋 Cleaned up $deleted old audit logs');
    return deleted;
  }
}

// Database Schema Definitions for UbuntuHealth CHW App
// This file defines the SQL DDL statements for all database tables.
// These schemas can be used with the existing sqflite-based database_service.dart
// or migrated to Drift when code generation is set up.

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Database schema version for migrations
const int schemaVersion = 2;

/// SQL DDL statements for creating all database tables
class DatabaseSchemas {
  /// CHW Users table - stores community health worker information
  static const String createChwUsersTable = '''
    CREATE TABLE IF NOT EXISTS chw_users (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      full_name TEXT NOT NULL,
      phone_number TEXT,
      profile_picture TEXT,
      role TEXT DEFAULT 'chw',
      supervisor_id TEXT,
      facility_id TEXT,
      region TEXT,
      languages TEXT,
      is_active INTEGER DEFAULT 1,
      last_sync TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT
    )
  ''';

  /// Households table - stores household information
  static const String createHouseholdsTable = '''
    CREATE TABLE IF NOT EXISTS households (
      id TEXT PRIMARY KEY,
      head_of_household_name TEXT NOT NULL,
      head_of_household_phone TEXT,
      number_of_members INTEGER DEFAULT 1,
      address TEXT,
      latitude REAL,
      longitude REAL,
      region TEXT,
      landmark TEXT,
      assigned_chw_id TEXT,
      risk_level TEXT DEFAULT 'low',
      notes TEXT,
      is_synced INTEGER DEFAULT 0,
      last_visit_date TEXT,
      next_visit_date TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT,
      FOREIGN KEY (assigned_chw_id) REFERENCES chw_users(id)
    )
  ''';

  /// Patients table - stores patient information
  static const String createPatientsTable = '''
    CREATE TABLE IF NOT EXISTS patients (
      id TEXT PRIMARY KEY,
      household_id TEXT,
      full_name TEXT NOT NULL,
      date_of_birth TEXT,
      gender TEXT,
      phone_number TEXT,
      national_id TEXT,
      nhif_number TEXT,
      blood_type TEXT,
      allergies TEXT,
      chronic_conditions TEXT,
      current_medications TEXT,
      emergency_contact TEXT,
      emergency_phone TEXT,
      notes TEXT,
      is_pregnant INTEGER DEFAULT 0,
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT,
      FOREIGN KEY (household_id) REFERENCES households(id)
    )
  ''';

  /// Visits table - stores visit records
  static const String createVisitsTable = '''
    CREATE TABLE IF NOT EXISTS visits (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      household_id TEXT,
      chw_id TEXT NOT NULL,
      visit_type TEXT NOT NULL,
      scheduled_date TEXT NOT NULL,
      actual_date TEXT,
      status TEXT DEFAULT 'scheduled',
      latitude REAL,
      longitude REAL,
      location_verified TEXT,
      notes TEXT,
      symptoms TEXT,
      diagnosis TEXT,
      treatment TEXT,
      referral_needed TEXT,
      follow_up_required TEXT,
      next_visit_date TEXT,
      duration_minutes INTEGER,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT,
      FOREIGN KEY (patient_id) REFERENCES patients(id),
      FOREIGN KEY (household_id) REFERENCES households(id),
      FOREIGN KEY (chw_id) REFERENCES chw_users(id)
    )
  ''';

  /// Health Records table - stores vital signs and screening results
  static const String createHealthRecordsTable = '''
    CREATE TABLE IF NOT EXISTS health_records (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      visit_id TEXT,
      record_type TEXT NOT NULL,
      record_date TEXT NOT NULL,
      temperature REAL,
      blood_pressure_systolic INTEGER,
      blood_pressure_diastolic INTEGER,
      heart_rate INTEGER,
      respiratory_rate INTEGER,
      oxygen_saturation REAL,
      weight REAL,
      height REAL,
      bmi REAL,
      blood_glucose REAL,
      muac_cm REAL,
      nutrition_status TEXT,
      notes TEXT,
      abnormal_findings TEXT,
      requires_follow_up INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (patient_id) REFERENCES patients(id),
      FOREIGN KEY (visit_id) REFERENCES visits(id)
    )
  ''';

  /// Referrals table - stores referral information
  static const String createReferralsTable = '''
    CREATE TABLE IF NOT EXISTS referrals (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      visit_id TEXT,
      referring_chw_id TEXT NOT NULL,
      referred_to_facility TEXT NOT NULL,
      referred_to_doctor TEXT,
      urgency TEXT DEFAULT 'routine',
      reason TEXT NOT NULL,
      clinical_notes TEXT,
      status TEXT DEFAULT 'pending',
      referral_date TEXT NOT NULL,
      appointment_date TEXT,
      facility_feedback TEXT,
      outcome TEXT,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT,
      FOREIGN KEY (patient_id) REFERENCES patients(id),
      FOREIGN KEY (visit_id) REFERENCES visits(id),
      FOREIGN KEY (referring_chw_id) REFERENCES chw_users(id)
    )
  ''';

  /// Medications table - stores dispensed medications
  static const String createMedicationsTable = '''
    CREATE TABLE IF NOT EXISTS medications (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      visit_id TEXT,
      dispensed_by_chw_id TEXT NOT NULL,
      medication_name TEXT NOT NULL,
      dosage TEXT NOT NULL,
      frequency TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit TEXT DEFAULT 'tablets',
      start_date TEXT NOT NULL,
      end_date TEXT,
      instructions TEXT,
      side_effects TEXT,
      batch_number TEXT,
      expiry_date TEXT,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (patient_id) REFERENCES patients(id),
      FOREIGN KEY (visit_id) REFERENCES visits(id),
      FOREIGN KEY (dispensed_by_chw_id) REFERENCES chw_users(id)
    )
  ''';

  /// AI Interactions table - stores AI assistant usage
  static const String createAiInteractionsTable = '''
    CREATE TABLE IF NOT EXISTS ai_interactions (
      id TEXT PRIMARY KEY,
      chw_id TEXT NOT NULL,
      patient_id TEXT,
      session_id TEXT NOT NULL,
      interaction_type TEXT NOT NULL,
      user_query TEXT NOT NULL,
      ai_response TEXT NOT NULL,
      model_used TEXT,
      was_helpful INTEGER,
      feedback_rating INTEGER,
      feedback_notes TEXT,
      response_time_ms INTEGER,
      is_offline INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (chw_id) REFERENCES chw_users(id),
      FOREIGN KEY (patient_id) REFERENCES patients(id)
    )
  ''';

  /// Enhanced Messages table - stores chat messages
  static const String createMessagesTable = '''
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      sender_id TEXT NOT NULL,
      sender_name TEXT NOT NULL,
      sender_avatar TEXT,
      recipient_id TEXT,
      group_id TEXT,
      message_type TEXT DEFAULT 'text',
      text_content TEXT,
      media_url TEXT,
      media_thumbnail_url TEXT,
      media_duration INTEGER,
      media_size INTEGER,
      mime_type TEXT,
      location TEXT,
      call_data TEXT,
      reply_to_message_id TEXT,
      forwarded_from_id TEXT,
      status TEXT DEFAULT 'sending',
      timestamp TEXT NOT NULL,
      edited_at TEXT,
      read_at TEXT,
      delivered_at TEXT,
      is_deleted INTEGER DEFAULT 0,
      metadata TEXT,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Conversations table - stores conversation metadata
  static const String createConversationsTable = '''
    CREATE TABLE IF NOT EXISTS conversations (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      avatar TEXT,
      is_group INTEGER DEFAULT 0,
      conversation_type TEXT NOT NULL,
      last_message_id TEXT,
      unread_count INTEGER DEFAULT 0,
      is_online INTEGER DEFAULT 0,
      last_seen TEXT,
      is_muted INTEGER DEFAULT 0,
      is_pinned INTEGER DEFAULT 0,
      member_ids TEXT,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT
    )
  ''';

  /// Offline Message Queue table - stores messages pending sync
  static const String createOfflineMessageQueueTable = '''
    CREATE TABLE IF NOT EXISTS offline_message_queue (
      id TEXT PRIMARY KEY,
      message_data TEXT NOT NULL,
      queued_at TEXT NOT NULL,
      retry_count INTEGER DEFAULT 0,
      last_error TEXT
    )
  ''';

  /// Sync Queue table - stores all offline operations pending sync
  static const String createSyncQueueTable = '''
    CREATE TABLE IF NOT EXISTS sync_queue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      data TEXT NOT NULL,
      priority INTEGER DEFAULT 0,
      retry_count INTEGER DEFAULT 0,
      last_error TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Training Modules table - stores training content
  static const String createTrainingModulesTable = '''
    CREATE TABLE IF NOT EXISTS training_modules (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      category TEXT NOT NULL,
      difficulty TEXT DEFAULT 'beginner',
      duration_minutes INTEGER NOT NULL,
      content TEXT NOT NULL,
      quiz_questions TEXT,
      passing_score INTEGER DEFAULT 70,
      is_required INTEGER DEFAULT 0,
      prerequisites TEXT,
      is_available_offline INTEGER DEFAULT 1,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT
    )
  ''';

  /// Training Progress table - stores CHW training progress
  static const String createTrainingProgressTable = '''
    CREATE TABLE IF NOT EXISTS training_progress (
      id TEXT PRIMARY KEY,
      chw_id TEXT NOT NULL,
      module_id TEXT NOT NULL,
      progress_percent INTEGER DEFAULT 0,
      quiz_score INTEGER,
      is_completed INTEGER DEFAULT 0,
      started_at TEXT,
      completed_at TEXT,
      time_spent_minutes INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT,
      FOREIGN KEY (chw_id) REFERENCES chw_users(id),
      FOREIGN KEY (module_id) REFERENCES training_modules(id)
    )
  ''';

  /// User Presence table - stores online status
  static const String createUserPresenceTable = '''
    CREATE TABLE IF NOT EXISTS user_presence (
      user_id TEXT PRIMARY KEY,
      is_online INTEGER DEFAULT 0,
      last_seen TEXT,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Get all table creation statements
  static List<String> getAllTableCreationStatements() {
    return [
      createChwUsersTable,
      createHouseholdsTable,
      createPatientsTable,
      createVisitsTable,
      createHealthRecordsTable,
      createReferralsTable,
      createMedicationsTable,
      createAiInteractionsTable,
      createMessagesTable,
      createConversationsTable,
      createOfflineMessageQueueTable,
      createSyncQueueTable,
      createTrainingModulesTable,
      createTrainingProgressTable,
      createUserPresenceTable,
    ];
  }

  /// Get all index creation statements for better query performance
  static List<String> getAllIndexCreationStatements() {
    return [
      'CREATE INDEX IF NOT EXISTS idx_patients_household ON patients(household_id)',
      'CREATE INDEX IF NOT EXISTS idx_visits_patient ON visits(patient_id)',
      'CREATE INDEX IF NOT EXISTS idx_visits_chw ON visits(chw_id)',
      'CREATE INDEX IF NOT EXISTS idx_visits_date ON visits(scheduled_date DESC)',
      'CREATE INDEX IF NOT EXISTS idx_health_records_patient ON health_records(patient_id)',
      'CREATE INDEX IF NOT EXISTS idx_referrals_patient ON referrals(patient_id)',
      'CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status)',
      'CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id)',
      'CREATE INDEX IF NOT EXISTS idx_messages_group ON messages(group_id)',
      'CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp DESC)',
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_priority ON sync_queue(priority DESC, created_at ASC)',
      'CREATE INDEX IF NOT EXISTS idx_training_progress_chw ON training_progress(chw_id)',
    ];
  }
}

/// Enhanced database service with Drift-like type-safe operations
/// This wraps the existing sqflite database with typed methods
class EnhancedDatabaseService {
  static final EnhancedDatabaseService _instance = EnhancedDatabaseService._internal();
  factory EnhancedDatabaseService() => _instance;
  EnhancedDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'ubuntuhealth_v2.db');

    return await openDatabase(
      dbPath,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database schema version $version');
    
    // Create all tables
    for (final statement in DatabaseSchemas.getAllTableCreationStatements()) {
      await db.execute(statement);
    }
    
    // Create all indexes
    for (final statement in DatabaseSchemas.getAllIndexCreationStatements()) {
      await db.execute(statement);
    }
    
    debugPrint('Database schema created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    
    // Add migration logic here as schema evolves
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE patients ADD COLUMN new_field TEXT');
    // }
  }

  Future<void> _onOpen(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ==================== Generic CRUD Operations ====================

  /// Insert a record and return the ID
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  /// Insert a record with conflict resolution
  Future<int> insertOrReplace(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update records matching the where clause
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  /// Delete records matching the where clause
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Query records
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Execute raw SQL
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// Execute raw query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  // ==================== Sync Queue Operations ====================

  /// Add item to sync queue
  Future<void> addToSyncQueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    await insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data.toString(),
      'priority': priority,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get pending sync items
  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 50}) async {
    return await query(
      'sync_queue',
      orderBy: 'priority DESC, created_at ASC',
      limit: limit,
    );
  }

  /// Remove synced item from queue
  Future<void> removeSyncItem(int id) async {
    await delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Get count of unsynced records
  Future<int> getUnsyncedCount() async {
    final result = await rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM patients WHERE is_synced = 0) +
        (SELECT COUNT(*) FROM visits WHERE is_synced = 0) +
        (SELECT COUNT(*) FROM health_records WHERE is_synced = 0) +
        (SELECT COUNT(*) FROM messages WHERE is_synced = 0) +
        (SELECT COUNT(*) FROM sync_queue)
      AS total_unsynced
    ''');
    return result.first['total_unsynced'] as int? ?? 0;
  }

  // ==================== Message Operations ====================

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getMessagesForConversation(
    String recipientId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return await rawQuery('''
      SELECT * FROM messages 
      WHERE recipient_id = ? OR sender_id = ?
      ORDER BY timestamp DESC
      LIMIT ? OFFSET ?
    ''', [recipientId, recipientId, limit, offset]);
  }

  /// Get group messages
  Future<List<Map<String, dynamic>>> getGroupMessages(
    String groupId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return await query(
      'messages',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String senderId) async {
    await update(
      'messages',
      {
        'read_at': DateTime.now().toIso8601String(),
        'status': 'read',
      },
      where: 'sender_id = ? AND read_at IS NULL',
      whereArgs: [senderId],
    );
  }

  // ==================== Utility Operations ====================

  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    final tables = [
      'training_progress',
      'ai_interactions',
      'offline_message_queue',
      'messages',
      'conversations',
      'medications',
      'referrals',
      'health_records',
      'visits',
      'patients',
      'households',
      'sync_queue',
      'user_presence',
    ];
    
    for (final table in tables) {
      await delete(table);
    }
    
    debugPrint('All data cleared from database');
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

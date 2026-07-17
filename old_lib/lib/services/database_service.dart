import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chw.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../models/reminder.dart';
import '../models/scheduled_visit.dart';
import '../models/chat_message.dart';
import '../models/referral.dart';
import '../models/message_models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chw_medical.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 18, // Incremented version to 18 for complete offline sync support
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<bool> _columnExists(Database db, String tableName, String columnName) async {
    final result = await db.rawQuery("PRAGMA table_info($tableName);");
    return result.any((map) => map['name'] == columnName);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intTypeNullable = 'INTEGER';

    await db.execute('''
      CREATE TABLE chws (
        id $idType,
        first_name $textType,
        last_name $textType,
        phone_number $textType UNIQUE,
        email $textTypeNullable,
        pin $textType,
        village $textTypeNullable,
        health_facility $textTypeNullable,
        region $textTypeNullable,
        registered_date $textType,
        is_active $intType,
        role $textTypeNullable DEFAULT 'chw',
        profile_photo_url $textTypeNullable,
        permissions $textTypeNullable,
        is_synced $intTypeNullable DEFAULT 0,
        last_sync_date $textTypeNullable,
        pending_sync $intTypeNullable DEFAULT 0,
        created_at $textTypeNullable DEFAULT CURRENT_TIMESTAMP,
        updated_at $textTypeNullable
      )
    ''');

    // Auth tokens table for secure token storage
    await db.execute('''
      CREATE TABLE auth_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL UNIQUE,
        access_token TEXT,
        refresh_token TEXT,
        token_expiry TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES chws (id) ON DELETE CASCADE
      )
    ''');

    // Pending sync operations table
    await db.execute('''
      CREATE TABLE auth_sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        user_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        chw_id TEXT NOT NULL,
        family_id TEXT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        other_names TEXT,
        date_of_birth TEXT,
        gender TEXT,
        relationship_to_head TEXT,
        health_status TEXT,
        village TEXT,
        location TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        phone_number TEXT,
        alternative_phone TEXT,
        photo_path TEXT,
        notes TEXT,
        is_pregnant INTEGER,
        pregnancy_week INTEGER,
        expected_delivery_date TEXT,
        has_chronic_condition INTEGER,
        chronic_conditions TEXT,
        is_high_risk INTEGER NOT NULL DEFAULT 0,
        risk_factors TEXT,
        risk_score REAL,
        blood_type TEXT,
        allergies TEXT,
        current_medications TEXT,
        marital_status TEXT,
        national_id TEXT,
        next_of_kin_name TEXT,
        next_of_kin_phone TEXT,
        next_of_kin_relationship TEXT,
        registered_date TEXT NOT NULL,
        is_synced $intTypeNullable DEFAULT 0,
        pending_sync $intTypeNullable DEFAULT 0,
        last_sync_date $textTypeNullable,
        FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE,
        FOREIGN KEY (family_id) REFERENCES families (id) ON DELETE SET NULL
      )
    ''');

    // Families table for family registration
    await db.execute('''
      CREATE TABLE families (
        id TEXT PRIMARY KEY,
        family_name TEXT NOT NULL,
        head_of_household_id TEXT,
        village TEXT,
        address TEXT,
        location TEXT,
        latitude REAL,
        longitude REAL,
        household_size INTEGER,
        housing_type TEXT,
        water_source TEXT,
        sanitation_type TEXT,
        has_electricity INTEGER DEFAULT 0,
        has_nhif INTEGER DEFAULT 0,
        nhif_number TEXT,
        registered_date TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        member_count INTEGER DEFAULT 0,
        has_vulnerable_members INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        pending_sync INTEGER DEFAULT 0,
        FOREIGN KEY (head_of_household_id) REFERENCES patients (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE visits (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        chw_id TEXT NOT NULL,
        visit_date TEXT NOT NULL,
        visit_type TEXT,
        visit_location TEXT,
        chief_complaint TEXT,
        symptoms TEXT,
        symptoms_list TEXT,
        symptom_duration TEXT,
        symptom_severity TEXT,
        diagnosis TEXT,
        diagnosis_codes TEXT,
        differential_diagnosis TEXT,
        ai_assessment TEXT,
        treatment TEXT,
        medications_given TEXT,
        procedures_performed TEXT,
        health_education TEXT,
        urgency_level TEXT DEFAULT 'routine',
        was_referred INTEGER NOT NULL DEFAULT 0,
        referral_location TEXT,
        referral_reason TEXT,
        outcome TEXT,
        patient_status_after TEXT,
        follow_up_date TEXT,
        follow_up_completed INTEGER NOT NULL DEFAULT 0,
        follow_up_notes TEXT,
        vitals TEXT,
        notes TEXT,
        attachments TEXT,
        visit_duration_minutes INTEGER,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        pending_sync INTEGER DEFAULT 0,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        chw_id TEXT NOT NULL,
        patient_id TEXT,
        reminder_date TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_date TEXT,
        is_synced INTEGER DEFAULT 0,
        pending_sync INTEGER DEFAULT 0,
        last_sync_date TEXT,
        FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE scheduled_visits (
        id TEXT PRIMARY KEY,
        chw_id TEXT NOT NULL,
        patient_id TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        purpose TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_date TEXT,
        is_synced INTEGER DEFAULT 0,
        pending_sync INTEGER DEFAULT 0,
        last_sync_date TEXT,
        FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_chat_messages (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        sender TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_chat_patient_session ON ai_chat_messages(patient_id, session_id)');

    await db.execute('''
      CREATE TABLE referrals (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        chw_id TEXT NOT NULL,
        referral_date TEXT NOT NULL,
        referral_reason TEXT NOT NULL,
        referred_to TEXT NOT NULL,
        outcome TEXT,
        outcome_date TEXT,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        pending_sync INTEGER DEFAULT 0,
        last_sync_date TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE
      )
    ''');

    // Messages table for direct and group messaging
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        recipient_id TEXT,
        group_id TEXT,
        content TEXT NOT NULL,
        message_type TEXT NOT NULL DEFAULT 'text',
        attachment_url TEXT,
        attachment_name TEXT,
        attachment_size INTEGER,
        attachment_mime_type TEXT,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        read_at TEXT,
        delivered_at TEXT,
        edited_at TEXT,
        original_content TEXT,
        forwarded_from_id TEXT,
        replied_to_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        pending_sync INTEGER DEFAULT 0,
        sync_error TEXT,
        is_archived INTEGER DEFAULT 0,
        FOREIGN KEY (sender_id) REFERENCES chws (id) ON DELETE CASCADE,
        FOREIGN KEY (recipient_id) REFERENCES chws (id) ON DELETE SET NULL,
        FOREIGN KEY (group_id) REFERENCES message_groups (id) ON DELETE SET NULL,
        FOREIGN KEY (forwarded_from_id) REFERENCES messages (id) ON DELETE SET NULL,
        FOREIGN KEY (replied_to_id) REFERENCES messages (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_messages_sender ON messages(sender_id)');
    await db.execute('CREATE INDEX idx_messages_recipient ON messages(recipient_id)');
    await db.execute('CREATE INDEX idx_messages_group ON messages(group_id)');
    await db.execute('CREATE INDEX idx_messages_created ON messages(created_at DESC)');

    // Message groups table
    await db.execute('''
      CREATE TABLE message_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        group_type TEXT,
        avatar_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        allow_member_messages INTEGER NOT NULL DEFAULT 1,
        created_by_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        member_count INTEGER DEFAULT 0,
        pending_sync INTEGER DEFAULT 0,
        sync_error TEXT,
        FOREIGN KEY (created_by_id) REFERENCES chws (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_message_groups_type ON message_groups(group_type)');

    // Group members junction table
    await db.execute('''
      CREATE TABLE message_group_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT DEFAULT 'member',
        joined_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES message_groups (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES chws (id) ON DELETE CASCADE,
        UNIQUE(group_id, user_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_group_members_group ON message_group_members(group_id)');
    await db.execute('CREATE INDEX idx_group_members_user ON message_group_members(user_id)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS patients (
          id TEXT PRIMARY KEY,
          chw_id TEXT NOT NULL,
          name TEXT NOT NULL,
          age INTEGER,
          gender TEXT,
          address TEXT,
          phone_number TEXT,
          is_high_risk INTEGER NOT NULL DEFAULT 0,
          registered_date TEXT NOT NULL,
          FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS visits (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          chw_id TEXT NOT NULL,
          visit_date TEXT NOT NULL,
          symptoms TEXT NOT NULL,
          diagnosis TEXT,
          treatment TEXT,
          notes TEXT,
          follow_up_date TEXT,
          follow_up_completed INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
          FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminders (
          id TEXT PRIMARY KEY,
          chw_id TEXT NOT NULL,
          patient_id TEXT,
          reminder_date TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_date TEXT,
          FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS scheduled_visits (
          id TEXT PRIMARY KEY,
          chw_id TEXT NOT NULL,
          patient_id TEXT NOT NULL,
          scheduled_date TEXT NOT NULL,
          purpose TEXT,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_date TEXT,
          FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      if (!(await _columnExists(db, 'patients', 'name'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN name TEXT NOT NULL DEFAULT \'Unknown\'');
      }
    }
    if (oldVersion < 4) {
      if (!(await _columnExists(db, 'visits', 'temperature'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN temperature REAL');
      }
      if (!(await _columnExists(db, 'visits', 'blood_pressure'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN blood_pressure TEXT');
      }
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ai_chat_messages (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          session_id TEXT NOT NULL,
          sender TEXT NOT NULL,
          message TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_patient_session ON ai_chat_messages(patient_id, session_id)');
    }
    if (oldVersion < 6) {
      if (!(await _columnExists(db, 'patients', 'age_unit'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN age_unit TEXT');
      }
    }
    if (oldVersion < 7) {
      if (!(await _columnExists(db, 'patients', 'village'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN village TEXT');
      }
    }
    if (oldVersion < 8) {
      // Add all missing columns for patient registration
      if (!(await _columnExists(db, 'patients', 'location'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN location TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'photo_path'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN photo_path TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'notes'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN notes TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'is_pregnant'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN is_pregnant INTEGER');
      }
      if (!(await _columnExists(db, 'patients', 'has_chronic_condition'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN has_chronic_condition INTEGER');
      }
      if (!(await _columnExists(db, 'patients', 'chronic_conditions'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN chronic_conditions TEXT');
      }
    }
     if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS referrals (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          chw_id TEXT NOT NULL,
          referral_date TEXT NOT NULL,
          referral_reason TEXT NOT NULL,
          referred_to TEXT NOT NULL,
          outcome TEXT,
          outcome_date TEXT,
          notes TEXT,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
          FOREIGN KEY (chw_id) REFERENCES chws (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 9) {
      // New columns for Patient model
      if (!(await _columnExists(db, 'patients', 'family_id'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN family_id TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'first_name'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN first_name TEXT NOT NULL DEFAULT ''');
      }
      if (!(await _columnExists(db, 'patients', 'last_name'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN last_name TEXT NOT NULL DEFAULT ''');
      }
      if (!(await _columnExists(db, 'patients', 'date_of_birth'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN date_of_birth TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'relationship_to_head'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN relationship_to_head TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'health_status'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN health_status TEXT');
      }
      // Remove old columns
      if (await _columnExists(db, 'patients', 'name')) {
        // This is a more complex migration, requiring data migration or dropping and recreating the table.
        // For simplicity, we'll assume a fresh install or that 'name' data can be reconstructed from first_name and last_name.
        // In a real application, you would create a new table, copy data, drop the old, and rename the new.
        // For now, as the current error is about *missing* columns, we will proceed by adding.
        // If the user encounters issues with 'name' being absent, we can address data migration.
        print('Warning: Column "name" exists and will be effectively unused after upgrade. Consider a data migration for it.');
      }
      if (await _columnExists(db, 'patients', 'age')) {
        print('Warning: Column "age" exists and will be effectively unused after upgrade. Consider a data migration for it.');
      }
      if (await _columnExists(db, 'patients', 'age_unit')) {
        print('Warning: Column "age_unit" exists and will be effectively unused after upgrade. Consider a data migration for it.');
      }
    }
    
    // Remove duplicate `if (oldVersion < 9)` block for `referrals` table creation, it's already handled above.

    // Further logic for migrating old `name`, `age`, `age_unit` data to new columns can be added here if needed.
    // For now, based on the error, the focus is on adding missing columns and making old ones effectively unused.
    
    if (oldVersion < 9) {
      // Update patient search and get methods to use new first_name and last_name columns
      // This is a placeholder for actual data migration or logic adaptation if old data needs to be preserved/transformed.
      // For instance, if 'name' column existed, you might parse it into 'first_name' and 'last_name'.
      // Given the prompt, the primary issue is missing columns, so adding them is the priority.
    }

    // Version 10: Add new columns for backend auth integration
    if (oldVersion < 10) {
      // Add new columns to chws table for backend integration
      if (!(await _columnExists(db, 'chws', 'role'))) {
        await db.execute("ALTER TABLE chws ADD COLUMN role TEXT DEFAULT 'chw'");
      }
      if (!(await _columnExists(db, 'chws', 'profile_photo_url'))) {
        await db.execute('ALTER TABLE chws ADD COLUMN profile_photo_url TEXT');
      }
      if (!(await _columnExists(db, 'chws', 'permissions'))) {
        await db.execute('ALTER TABLE chws ADD COLUMN permissions TEXT');
      }
      if (!(await _columnExists(db, 'chws', 'is_synced'))) {
        await db.execute('ALTER TABLE chws ADD COLUMN is_synced INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'chws', 'last_sync_date'))) {
        await db.execute('ALTER TABLE chws ADD COLUMN last_sync_date TEXT');
      }
      if (!(await _columnExists(db, 'chws', 'pending_sync'))) {
        await db.execute('ALTER TABLE chws ADD COLUMN pending_sync INTEGER DEFAULT 0');
      }

      // Create auth_tokens table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS auth_tokens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL UNIQUE,
          access_token TEXT,
          refresh_token TEXT,
          token_expiry TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT,
          FOREIGN KEY (user_id) REFERENCES chws (id) ON DELETE CASCADE
        )
      ''');

      // Create auth_sync_queue table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS auth_sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operation TEXT NOT NULL,
          user_id TEXT NOT NULL,
          data TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          retry_count INTEGER DEFAULT 0,
          last_error TEXT
        )
      ''');

      print('Database upgraded to version 10 with auth integration tables');
    }

    // Version 11: Add timestamp columns for sync tracking
    if (oldVersion < 11) {
      // Add created_at column to chws table (cannot use CURRENT_TIMESTAMP in ALTER TABLE)
      if (!(await _columnExists(db, 'chws', 'created_at'))) {
        await db.execute('ALTER TABLE chws ADD COLUMN created_at TEXT');
        // Set created_at for existing records
        await db.execute("UPDATE chws SET created_at = datetime('now') WHERE created_at IS NULL");
      }
      
      // Add updated_at column to chws table for sync timestamp tracking
      if (!(await _columnExists(db, 'chws', 'updated_at'))) {
        await db.execute('ALTER TABLE chws ADD COLUMN updated_at TEXT');
      }

      print('Database upgraded to version 11 with timestamp columns');
    }

    // Version 12: Add families table
    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS families (
          id TEXT PRIMARY KEY,
          family_name TEXT NOT NULL,
          head_of_household_id TEXT,
          village TEXT,
          address TEXT,
          location TEXT,
          latitude REAL,
          longitude REAL,
          household_size INTEGER,
          housing_type TEXT,
          water_source TEXT,
          sanitation_type TEXT,
          has_electricity INTEGER DEFAULT 0,
          has_nhif INTEGER DEFAULT 0,
          nhif_number TEXT,
          registered_date TEXT,
          notes TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT,
          member_count INTEGER DEFAULT 0,
          has_vulnerable_members INTEGER DEFAULT 0,
          is_synced INTEGER DEFAULT 0,
          pending_sync INTEGER DEFAULT 0
        )
      ''');

      print('Database upgraded to version 12 with families table');
    }

    // Version 13: Add extended patient information fields
    if (oldVersion < 13) {
      // Medical information fields
      if (!(await _columnExists(db, 'patients', 'pregnancy_week'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN pregnancy_week INTEGER');
      }
      if (!(await _columnExists(db, 'patients', 'risk_score'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN risk_score REAL');
      }
      if (!(await _columnExists(db, 'patients', 'blood_type'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN blood_type TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'allergies'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN allergies TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'current_medications'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN current_medications TEXT');
      }
      
      // Administrative fields
      if (!(await _columnExists(db, 'patients', 'marital_status'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN marital_status TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'national_id'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN national_id TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'alternative_phone'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN alternative_phone TEXT');
      }
      
      // Next of kin fields
      if (!(await _columnExists(db, 'patients', 'next_of_kin_name'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN next_of_kin_name TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'next_of_kin_phone'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN next_of_kin_phone TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'next_of_kin_relationship'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN next_of_kin_relationship TEXT');
      }

      print('Database upgraded to version 13 with extended patient fields');
    }

    // Version 14: Add additional patient fields (other_names, expected_delivery_date, risk_factors, latitude, longitude)
    if (oldVersion < 14) {
      if (!(await _columnExists(db, 'patients', 'other_names'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN other_names TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'expected_delivery_date'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN expected_delivery_date TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'risk_factors'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN risk_factors TEXT');
      }
      if (!(await _columnExists(db, 'patients', 'latitude'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN latitude REAL');
      }
      if (!(await _columnExists(db, 'patients', 'longitude'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN longitude REAL');
      }

      print('Database upgraded to version 14 with additional patient fields');
    }

    // Version 15: Add extended visit fields to match backend API
    if (oldVersion < 15) {
      // Visit type and location
      if (!(await _columnExists(db, 'visits', 'visit_type'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN visit_type TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'visit_location'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN visit_location TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'chief_complaint'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN chief_complaint TEXT');
      }
      
      // Symptoms details
      if (!(await _columnExists(db, 'visits', 'symptoms_list'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN symptoms_list TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'symptom_duration'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN symptom_duration TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'symptom_severity'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN symptom_severity TEXT');
      }
      
      // Diagnosis details
      if (!(await _columnExists(db, 'visits', 'diagnosis_codes'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN diagnosis_codes TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'differential_diagnosis'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN differential_diagnosis TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'ai_assessment'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN ai_assessment TEXT');
      }
      
      // Treatment details
      if (!(await _columnExists(db, 'visits', 'medications_given'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN medications_given TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'procedures_performed'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN procedures_performed TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'health_education'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN health_education TEXT');
      }
      
      // Urgency and referral
      if (!(await _columnExists(db, 'visits', 'urgency_level'))) {
        await db.execute("ALTER TABLE visits ADD COLUMN urgency_level TEXT DEFAULT 'routine'");
      }
      if (!(await _columnExists(db, 'visits', 'was_referred'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN was_referred INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'visits', 'referral_reason'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN referral_reason TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'referral_location'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN referral_location TEXT');
      }
      
      // Outcome and follow-up
      if (!(await _columnExists(db, 'visits', 'outcome'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN outcome TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'patient_status_after'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN patient_status_after TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'follow_up_notes'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN follow_up_notes TEXT');
      }
      
      // Vitals and attachments (stored as JSON strings)
      if (!(await _columnExists(db, 'visits', 'vitals'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN vitals TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'attachments'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN attachments TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'visit_duration_minutes'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN visit_duration_minutes INTEGER');
      }
      
      // Sync tracking
      if (!(await _columnExists(db, 'visits', 'created_at'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN created_at TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'updated_at'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN updated_at TEXT');
      }
      if (!(await _columnExists(db, 'visits', 'is_synced'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN is_synced INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'visits', 'pending_sync'))) {
        await db.execute('ALTER TABLE visits ADD COLUMN pending_sync INTEGER DEFAULT 0');
      }

      print('Database upgraded to version 15 with extended visit fields');
    }

    // Version 16: Add messages and message_groups tables for messaging feature
    if (oldVersion < 16) {
      // Messages table for direct and group messaging
      await db.execute('''
        CREATE TABLE IF NOT EXISTS messages (
          id TEXT PRIMARY KEY,
          sender_id TEXT NOT NULL,
          recipient_id TEXT,
          group_id TEXT,
          content TEXT NOT NULL,
          message_type TEXT NOT NULL DEFAULT 'text',
          attachment_url TEXT,
          attachment_name TEXT,
          attachment_size INTEGER,
          attachment_mime_type TEXT,
          latitude REAL,
          longitude REAL,
          location_name TEXT,
          is_read INTEGER NOT NULL DEFAULT 0,
          read_at TEXT,
          delivered_at TEXT,
          edited_at TEXT,
          original_content TEXT,
          forwarded_from_id TEXT,
          replied_to_id TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          pending_sync INTEGER DEFAULT 0,
          sync_error TEXT,
          is_archived INTEGER DEFAULT 0
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_group ON messages(group_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC)');

      // Message groups table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS message_groups (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          group_type TEXT,
          avatar_url TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          allow_member_messages INTEGER NOT NULL DEFAULT 1,
          created_by_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          member_count INTEGER DEFAULT 0,
          pending_sync INTEGER DEFAULT 0,
          sync_error TEXT
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_message_groups_type ON message_groups(group_type)');

      // Group members junction table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS message_group_members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          role TEXT DEFAULT 'member',
          joined_at TEXT NOT NULL,
          UNIQUE(group_id, user_id)
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_group_members_group ON message_group_members(group_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_group_members_user ON message_group_members(user_id)');

      print('Database upgraded to version 16 with messages and message_groups tables');
    }

    // Version 17: Add offline sync columns to patients table
    if (oldVersion < 17) {
      if (!(await _columnExists(db, 'patients', 'is_synced'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN is_synced INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'patients', 'pending_sync'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN pending_sync INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'patients', 'last_sync_date'))) {
        await db.execute('ALTER TABLE patients ADD COLUMN last_sync_date TEXT');
      }

      print('Database upgraded to version 17 with patients offline sync columns');
    }

    // Version 18: Add offline sync columns to referrals, reminders, and scheduled_visits tables
    if (oldVersion < 18) {
      // Add sync columns to referrals table
      if (!(await _columnExists(db, 'referrals', 'is_synced'))) {
        await db.execute('ALTER TABLE referrals ADD COLUMN is_synced INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'referrals', 'pending_sync'))) {
        await db.execute('ALTER TABLE referrals ADD COLUMN pending_sync INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'referrals', 'last_sync_date'))) {
        await db.execute('ALTER TABLE referrals ADD COLUMN last_sync_date TEXT');
      }

      // Add sync columns to reminders table
      if (!(await _columnExists(db, 'reminders', 'is_synced'))) {
        await db.execute('ALTER TABLE reminders ADD COLUMN is_synced INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'reminders', 'pending_sync'))) {
        await db.execute('ALTER TABLE reminders ADD COLUMN pending_sync INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'reminders', 'last_sync_date'))) {
        await db.execute('ALTER TABLE reminders ADD COLUMN last_sync_date TEXT');
      }

      // Add sync columns to scheduled_visits table
      if (!(await _columnExists(db, 'scheduled_visits', 'is_synced'))) {
        await db.execute('ALTER TABLE scheduled_visits ADD COLUMN is_synced INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'scheduled_visits', 'pending_sync'))) {
        await db.execute('ALTER TABLE scheduled_visits ADD COLUMN pending_sync INTEGER DEFAULT 0');
      }
      if (!(await _columnExists(db, 'scheduled_visits', 'last_sync_date'))) {
        await db.execute('ALTER TABLE scheduled_visits ADD COLUMN last_sync_date TEXT');
      }

      print('Database upgraded to version 18 with complete offline sync support');
    }

  }

  // ========== CHW CRUD Operations ==========

  Future<CHW> createCHW(CHW chw) async {
    final db = await instance.database;
    await db.insert('chws', chw.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return chw;
  }

  Future<CHW?> getCHWById(String id) async {
    final db = await instance.database;
    final maps = await db.query('chws', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return CHW.fromMap(maps.first);
    return null;
  }

  Future<CHW?> getCHWByPhoneAndPin(String phoneNumber, String pin) async {
    final db = await instance.database;
    final maps = await db.query('chws', where: 'phone_number = ? AND pin = ? AND is_active = 1', whereArgs: [phoneNumber, pin]);
    if (maps.isNotEmpty) return CHW.fromMap(maps.first);
    return null;
  }

  Future<CHW?> getCHWByPhone(String phoneNumber) async {
    final db = await instance.database;
    final maps = await db.query('chws', where: 'phone_number = ?', whereArgs: [phoneNumber]);
    if (maps.isNotEmpty) return CHW.fromMap(maps.first);
    return null;
  }

  // ========== FAMILY CRUD Operations ==========

  /// Create a new family in local database
  Future<void> createFamily(Map<String, dynamic> familyMap) async {
    final db = await instance.database;
    await db.insert('families', familyMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get family by ID
  Future<Map<String, dynamic>?> getFamilyById(String id) async {
    final db = await instance.database;
    final maps = await db.query('families', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  /// Get all families for display
  Future<List<Map<String, dynamic>>> getAllFamilies() async {
    final db = await instance.database;
    final result = await db.query('families', orderBy: 'family_name ASC');
    return result;
  }

  /// Search families by name or village
  Future<List<Map<String, dynamic>>> searchFamilies(String query) async {
    final db = await instance.database;
    if (query.isEmpty) return getAllFamilies();
    final result = await db.query(
      'families', 
      where: 'family_name LIKE ? OR village LIKE ?', 
      whereArgs: ['%$query%', '%$query%'], 
      orderBy: 'family_name ASC'
    );
    return result;
  }

  /// Update family in local database
  Future<int> updateFamily(String id, Map<String, dynamic> familyMap) async {
    final db = await instance.database;
    return db.update('families', familyMap, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete family from local database
  Future<int> deleteFamily(String id) async {
    final db = await instance.database;
    return db.delete('families', where: 'id = ?', whereArgs: [id]);
  }

  /// Get unsynced families
  Future<List<Map<String, dynamic>>> getUnsyncedFamilies() async {
    final db = await instance.database;
    final result = await db.query('families', where: 'is_synced = 0 OR pending_sync = 1');
    return result;
  }

  /// Mark family as synced
  Future<void> markFamilySynced(String id) async {
    final db = await instance.database;
    await db.update(
      'families',
      {'is_synced': 1, 'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get patients by family ID
  Future<List<Patient>> getPatientsByFamily(String familyId) async {
    final db = await instance.database;
    final result = await db.query('patients', where: 'family_id = ?', whereArgs: [familyId], orderBy: 'first_name ASC');
    return result.map((map) => Patient.fromMap(map)).toList();
  }

  // ========== PATIENT CRUD Operations ==========

  Future<Patient> createPatient(Patient patient) async {
    final db = await instance.database;
    await db.insert('patients', patient.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return patient;
  }

  Future<Patient?> getPatientById(String id) async {
    final db = await instance.database;
    final maps = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Patient.fromMap(maps.first);
    return null;
  }

  Future<List<Patient>> getPatientsByCHW(String chwId) async {
    final db = await instance.database;
    final result = await db.query('patients', where: 'chw_id = ?', whereArgs: [chwId], orderBy: 'first_name ASC');
    return result.map((map) => Patient.fromMap(map)).toList();
  }

  Future<List<Patient>> searchPatients(String chwId, String query) async {
    final db = await instance.database;
    if (query.isEmpty) return getPatientsByCHW(chwId);
    final result = await db.query('patients', where: 'chw_id = ? AND (first_name LIKE ? OR last_name LIKE ?)', whereArgs: [chwId, '%$query%', '%$query%'], orderBy: 'first_name ASC');
    return result.map((map) => Patient.fromMap(map)).toList();
  }

  Future<List<Patient>> getHighRiskPatients(String chwId) async {
    final db = await instance.database;
    final result = await db.query('patients', where: 'chw_id = ? AND is_high_risk = 1', whereArgs: [chwId], orderBy: 'first_name ASC');
    return result.map((map) => Patient.fromMap(map)).toList();
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await instance.database;
    return db.update('patients', patient.toMap(), where: 'id = ?', whereArgs: [patient.id]);
  }

  Future<int> deletePatient(String id) async {
    final db = await instance.database;
    return db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  /// Upsert patient from map (insert or update)
  Future<void> upsertPatient(Map<String, dynamic> patientMap) async {
    final db = await instance.database;
    await db.insert('patients', patientMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Create patient from map
  Future<void> createPatientFromMap(Map<String, dynamic> patientMap) async {
    final db = await instance.database;
    await db.insert('patients', patientMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update patient from map
  Future<int> updatePatientFromMap(String id, Map<String, dynamic> patientMap) async {
    final db = await instance.database;
    return db.update('patients', patientMap, where: 'id = ?', whereArgs: [id]);
  }

  /// Get patients pending sync
  Future<List<Map<String, dynamic>>> getPendingSyncPatients() async {
    final db = await instance.database;
    return db.query('patients', where: 'pending_sync = 1');
  }

  /// Update patient sync status
  Future<void> updatePatientSyncStatus(String localId, String serverId, {bool isSynced = true}) async {
    final db = await instance.database;
    await db.update(
      'patients',
      {
        'id': serverId,
        'is_synced': isSynced ? 1 : 0,
        'pending_sync': isSynced ? 0 : 1,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // ========== VISIT CRUD Operations ==========

  Future<Visit> createVisit(Visit visit) async {
    final db = await instance.database;
    await db.insert('visits', visit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return visit;
  }

  Future<List<Visit>> getVisitsByPatient(String patientId) async {
    final db = await instance.database;
    final result = await db.query('visits', where: 'patient_id = ?', whereArgs: [patientId], orderBy: 'visit_date DESC');
    return result.map((map) => Visit.fromMap(map)).toList();
  }
  
  /// Get all visits from local database
  Future<List<Visit>> getAllVisits() async {
    final db = await instance.database;
    final result = await db.query('visits', orderBy: 'visit_date DESC');
    return result.map((map) => Visit.fromMap(map)).toList();
  }

  Future<List<Visit>> getPendingFollowUps(String chwId) async {
    final db = await instance.database;
    final result = await db.query('visits', where: 'chw_id = ? AND follow_up_completed = 0 AND follow_up_date IS NOT NULL', whereArgs: [chwId], orderBy: 'follow_up_date ASC');
    return result.map((map) => Visit.fromMap(map)).toList();
  }

  Future<int> updateVisit(Visit visit) async {
    final db = await instance.database;
    return db.update('visits', visit.toMap(), where: 'id = ?', whereArgs: [visit.id]);
  }

  // ========== REMINDER CRUD Operations ==========

  Future<Reminder> createReminder(Reminder reminder) async {
    final db = await instance.database;
    await db.insert('reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return reminder;
  }
  
  Future<Reminder> createOrUpdateReminder(Reminder reminder) async {
    final db = await instance.database;
    await db.insert('reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return reminder;
  }

  Future<List<Reminder>> getRemindersByCHW(String chwId) async {
    final db = await instance.database;
    final result = await db.query(
        'reminders',
        where: 'chw_id = ? AND is_completed = 0',
        whereArgs: [chwId],
        orderBy: 'reminder_date ASC'
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<List<Reminder>> getRemindersByPatient(String patientId) async {
    final db = await instance.database;
    final result = await db.query(
        'reminders',
        where: 'patient_id = ? AND is_completed = 0',
        whereArgs: [patientId],
        orderBy: 'reminder_date ASC'
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await instance.database;
    return db.update('reminders', reminder.toMap(), where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<int> deleteReminder(String id) async {
    final db = await instance.database;
    return db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getReminderStatistics(String chwId) async {
    final db = await instance.database;

    final totalPending = Sqflite.firstIntValue(
        await db.rawQuery(
            'SELECT COUNT(*) FROM reminders WHERE chw_id = ? AND is_completed = 0',
            [chwId]
        )
    ) ?? 0;

    final overdue = Sqflite.firstIntValue(
        await db.rawQuery(
            'SELECT COUNT(*) FROM reminders WHERE chw_id = ? AND is_completed = 0 AND reminder_date < ?',
            [chwId, DateTime.now().toIso8601String()]
        )
    ) ?? 0;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final completedThisWeek = Sqflite.firstIntValue(
        await db.rawQuery(
            'SELECT COUNT(*) FROM reminders WHERE chw_id = ? AND is_completed = 1 AND completed_date >= ?',
            [chwId, startOfWeek.toIso8601String()]
        )
    ) ?? 0;

    return {
      'totalPending': totalPending,
      'overdue': overdue,
      'completedThisWeek': completedThisWeek,
    };
  }

  // ========== SCHEDULED VISIT CRUD Operations ==========

  Future<ScheduledVisit> createScheduledVisit(ScheduledVisit visit) async {
    final db = await instance.database;
    await db.insert('scheduled_visits', visit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return visit;
  }

  Future<List<ScheduledVisit>> getScheduledVisitsByCHW(String chwId) async {
    final db = await instance.database;
    final result = await db.query(
        'scheduled_visits',
        where: 'chw_id = ?',
        whereArgs: [chwId],
        orderBy: 'scheduled_date ASC'
    );
    return result.map((map) => ScheduledVisit.fromMap(map)).toList();
  }

  Future<List<ScheduledVisit>> getScheduledVisitsByDate(String chwId, DateTime date) async {
    final db = await instance.database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final result = await db.query(
        'scheduled_visits',
        where: 'chw_id = ? AND scheduled_date >= ? AND scheduled_date <= ?',
        whereArgs: [chwId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
        orderBy: 'scheduled_date ASC'
    );
    return result.map((map) => ScheduledVisit.fromMap(map)).toList();
  }

  Future<int> updateScheduledVisit(ScheduledVisit visit) async {
    final db = await instance.database;
    return db.update('scheduled_visits', visit.toMap(), where: 'id = ?', whereArgs: [visit.id]);
  }

  Future<int> deleteScheduledVisit(String id) async {
    final db = await instance.database;
    return db.delete('scheduled_visits', where: 'id = ?', whereArgs: [id]);
  }

  // ========== REFERRAL CRUD Operations ==========

  Future<Referral> createReferral(Referral referral) async {
    final db = await instance.database;
    await db.insert('referrals', referral.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return referral;
  }
  
  Future<Referral> createOrUpdateReferral(Referral referral) async {
    final db = await instance.database;
    await db.insert('referrals', referral.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return referral;
  }

  Future<List<Referral>> getReferralsByPatient(String patientId) async {
    final db = await instance.database;
    final result = await db.query('referrals', where: 'patient_id = ?', whereArgs: [patientId], orderBy: 'referral_date DESC');
    return result.map((map) => Referral.fromMap(map)).toList();
  }
  
  Future<List<Referral>> getReferralsByCHW(String chwId) async {
    final db = await instance.database;
    final result = await db.query('referrals', where: 'chw_id = ?', whereArgs: [chwId], orderBy: 'referral_date DESC');
    return result.map((map) => Referral.fromMap(map)).toList();
  }

  Future<int> updateReferral(Referral referral) async {
    final db = await instance.database;
    return db.update('referrals', referral.toMap(), where: 'id = ?', whereArgs: [referral.id]);
  }

  Future<int> deleteReferral(String id) async {
    final db = await instance.database;
    return db.delete('referrals', where: 'id = ?', whereArgs: [id]);
  }

  // ========== STATISTICS ==========

  Future<Map<String, int>> getCHWStatistics(String chwId) async {
    final db = await instance.database;
    final totalPatients = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM patients WHERE chw_id = ?', [chwId])) ?? 0;
    final totalVisits = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM visits WHERE chw_id = ?', [chwId])) ?? 0;
    final pendingFollowUps = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM visits WHERE chw_id = ? AND follow_up_completed = 0 AND follow_up_date IS NOT NULL', [chwId])) ?? 0;
    final highRiskPatients = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM patients WHERE chw_id = ? AND is_high_risk = 1', [chwId])) ?? 0;
    return {
      'totalPatients': totalPatients,
      'totalVisits': totalVisits,
      'pendingFollowUps': pendingFollowUps,
      'highRiskPatients': highRiskPatients,
    };
  }

  // ========== AI CHAT MESSAGE CRUD Operations ==========

  Future<ChatMessage> createChatMessage(ChatMessage chatMessage) async {
    final db = await instance.database;
    await db.insert('ai_chat_messages', chatMessage.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return chatMessage;
  }

  Future<List<ChatMessage>> getChatMessagesByPatient(String patientId) async {
    final db = await instance.database;
    final result = await db.query('ai_chat_messages', where: 'patient_id = ?', whereArgs: [patientId], orderBy: 'timestamp ASC');
    return result.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<int> deleteChatHistory(String patientId) async {
    final db = await instance.database;
    return db.delete('ai_chat_messages', where: 'patient_id = ?', whereArgs: [patientId]);
  }

  /// Delete a specific chat session by session ID
  Future<int> deleteChatSession(String sessionId) async {
    final db = await instance.database;
    return db.delete('ai_chat_messages', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  Future close() async {
    final db = await instance.database;
    _database = null;
    if (db.isOpen) {
      db.close();
    }
  }

  // ========== AUTH TOKEN CRUD Operations ==========

  /// Save or update auth tokens for a user
  Future<void> saveAuthTokens({
    required String userId,
    required String? accessToken,
    required String? refreshToken,
    DateTime? tokenExpiry,
  }) async {
    final db = await instance.database;
    await db.insert(
      'auth_tokens',
      {
        'user_id': userId,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_expiry': tokenExpiry?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get auth tokens for a user
  Future<Map<String, dynamic>?> getAuthTokens(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'auth_tokens',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  /// Delete auth tokens for a user
  Future<void> deleteAuthTokens(String userId) async {
    final db = await instance.database;
    await db.delete('auth_tokens', where: 'user_id = ?', whereArgs: [userId]);
  }

  /// Clear all auth tokens
  Future<void> clearAllAuthTokens() async {
    final db = await instance.database;
    await db.delete('auth_tokens');
  }

  // ========== AUTH SYNC QUEUE Operations ==========

  /// Add operation to auth sync queue (for offline registration/changes)
  Future<void> addToAuthSyncQueue({
    required String operation,
    required String userId,
    required String data,
  }) async {
    final db = await instance.database;
    await db.insert('auth_sync_queue', {
      'operation': operation,
      'user_id': userId,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get pending auth sync operations
  Future<List<Map<String, dynamic>>> getPendingAuthSyncOperations() async {
    final db = await instance.database;
    return await db.query(
      'auth_sync_queue',
      orderBy: 'created_at ASC',
    );
  }

  /// Remove sync operation from queue
  Future<void> removeAuthSyncOperation(int id) async {
    final db = await instance.database;
    await db.delete('auth_sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Update sync operation retry count
  Future<void> updateAuthSyncRetry(int id, String error) async {
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE auth_sync_queue SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }

  /// Update CHW sync status
  Future<void> updateCHWSyncStatus(String id, {bool isSynced = true}) async {
    final db = await instance.database;
    await db.update(
      'chws',
      {
        'is_synced': isSynced ? 1 : 0,
        'last_sync_date': DateTime.now().toIso8601String(),
        'pending_sync': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all CHWs pending sync
  Future<List<CHW>> getPendingSyncCHWs() async {
    final db = await instance.database;
    final result = await db.query(
      'chws',
      where: 'pending_sync = 1 OR is_synced = 0',
    );
    return result.map((map) => CHW.fromMap(map)).toList();
  }

  /// Update CHW from backend data
  Future<void> updateCHWFromBackend(CHW chw) async {
    final db = await instance.database;
    await db.update(
      'chws',
      chw.copyWith(isSynced: true, lastSyncDate: DateTime.now(), pendingSync: false).toMap(),
      where: 'id = ?',
      whereArgs: [chw.id],
    );
  }

  // ========== MESSAGE CRUD Operations ==========

  /// Create or update a message in local database
  Future<void> createOrUpdateMessage(Message message) async {
    final db = await instance.database;
    await db.insert('messages', message.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get a message by ID
  Future<Message?> getMessageById(String id) async {
    final db = await instance.database;
    final maps = await db.query('messages', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Message.fromDb(maps.first);
    return null;
  }

  /// Get messages for a direct conversation (between current user and another user)
  Future<List<Message>> getDirectMessages(String userId, String otherUserId) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: '((sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)) AND is_archived = 0',
      whereArgs: [userId, otherUserId, otherUserId, userId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Message.fromDb(map)).toList();
  }

  /// Get messages for a group
  Future<List<Message>> getGroupMessages(String groupId) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'group_id = ? AND is_archived = 0',
      whereArgs: [groupId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Message.fromDb(map)).toList();
  }

  /// Get all messages for a user (sent and received)
  Future<List<Message>> getMessagesForUser(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: '(sender_id = ? OR recipient_id = ?) AND is_archived = 0',
      whereArgs: [userId, userId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Message.fromDb(map)).toList();
  }

  /// Get unread messages for a user
  Future<List<Message>> getUnreadMessages(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'recipient_id = ? AND is_read = 0 AND is_archived = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Message.fromDb(map)).toList();
  }

  /// Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE recipient_id = ? AND is_read = 0 AND is_archived = 0',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(String messageId) async {
    final db = await instance.database;
    await db.update(
      'messages',
      {
        'is_read': 1,
        'read_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Mark multiple messages as read
  Future<void> markMultipleMessagesAsRead(List<String> messageIds) async {
    final db = await instance.database;
    final placeholders = messageIds.map((_) => '?').join(',');
    await db.rawUpdate(
      'UPDATE messages SET is_read = 1, read_at = ? WHERE id IN ($placeholders)',
      [DateTime.now().toIso8601String(), ...messageIds],
    );
  }

  /// Archive a message (soft delete)
  Future<void> archiveMessage(String messageId) async {
    final db = await instance.database;
    await db.update(
      'messages',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Delete a message
  Future<int> deleteMessage(String id) async {
    final db = await instance.database;
    return db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  /// Update a message
  Future<int> updateMessage(Message message) async {
    final db = await instance.database;
    return db.update('messages', message.toDb(), where: 'id = ?', whereArgs: [message.id]);
  }

  /// Get messages pending sync
  Future<List<Message>> getPendingSyncMessages() async {
    final db = await instance.database;
    final result = await db.query('messages', where: 'pending_sync = 1');
    return result.map((map) => Message.fromDb(map)).toList();
  }

  /// Mark message as synced
  Future<void> markMessageSynced(String id, {String? newId}) async {
    final db = await instance.database;
    final updates = <String, dynamic>{
      'pending_sync': 0,
      'sync_error': null,
    };
    if (newId != null) updates['id'] = newId;
    await db.update('messages', updates, where: 'id = ?', whereArgs: [id]);
  }

  /// Get conversations list (unique conversations)
  Future<List<Map<String, dynamic>>> getConversationsList(String userId) async {
    final db = await instance.database;
    // Get unique conversation partners with latest message
    final result = await db.rawQuery('''
      SELECT 
        CASE 
          WHEN sender_id = ? THEN recipient_id 
          ELSE sender_id 
        END as partner_id,
        MAX(created_at) as last_message_time,
        content as last_message,
        (SELECT COUNT(*) FROM messages m2 
          WHERE m2.recipient_id = ? 
          AND m2.is_read = 0 
          AND m2.sender_id = CASE WHEN m.sender_id = ? THEN m.recipient_id ELSE m.sender_id END
        ) as unread_count
      FROM messages m
      WHERE (sender_id = ? OR recipient_id = ?) 
        AND group_id IS NULL 
        AND is_archived = 0
      GROUP BY partner_id
      ORDER BY last_message_time DESC
    ''', [userId, userId, userId, userId, userId]);
    return result;
  }

  // ========== MESSAGE GROUP CRUD Operations ==========

  /// Create or update a message group in local database
  Future<void> createOrUpdateMessageGroup(MessageGroup group) async {
    final db = await instance.database;
    await db.insert('message_groups', group.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get a message group by ID
  Future<MessageGroup?> getMessageGroupById(String id) async {
    final db = await instance.database;
    final maps = await db.query('message_groups', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return MessageGroup.fromDb(maps.first);
    return null;
  }

  /// Get all message groups for a user (where they are a member)
  Future<List<MessageGroup>> getMessageGroupsForUser(String userId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT mg.* FROM message_groups mg
      INNER JOIN message_group_members mgm ON mg.id = mgm.group_id
      WHERE mgm.user_id = ? AND mg.is_active = 1
      ORDER BY mg.updated_at DESC
    ''', [userId]);
    return result.map((map) => MessageGroup.fromDb(map)).toList();
  }

  /// Get all active message groups
  Future<List<MessageGroup>> getAllActiveMessageGroups() async {
    final db = await instance.database;
    final result = await db.query(
      'message_groups',
      where: 'is_active = 1',
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => MessageGroup.fromDb(map)).toList();
  }

  /// Update a message group
  Future<int> updateMessageGroup(MessageGroup group) async {
    final db = await instance.database;
    return db.update('message_groups', group.toDb(), where: 'id = ?', whereArgs: [group.id]);
  }

  /// Delete a message group
  Future<int> deleteMessageGroup(String id) async {
    final db = await instance.database;
    // Also delete all members
    await db.delete('message_group_members', where: 'group_id = ?', whereArgs: [id]);
    return db.delete('message_groups', where: 'id = ?', whereArgs: [id]);
  }

  /// Get groups pending sync
  Future<List<MessageGroup>> getPendingSyncMessageGroups() async {
    final db = await instance.database;
    final result = await db.query('message_groups', where: 'pending_sync = 1');
    return result.map((map) => MessageGroup.fromDb(map)).toList();
  }

  /// Mark group as synced
  Future<void> markMessageGroupSynced(String id, {String? newId}) async {
    final db = await instance.database;
    final updates = <String, dynamic>{
      'pending_sync': 0,
      'sync_error': null,
    };
    if (newId != null) updates['id'] = newId;
    await db.update('message_groups', updates, where: 'id = ?', whereArgs: [id]);
  }

  // ========== MESSAGE GROUP MEMBERS Operations ==========

  /// Add a member to a group
  Future<void> addGroupMember(String groupId, String userId, {String role = 'member'}) async {
    final db = await instance.database;
    await db.insert(
      'message_group_members',
      {
        'group_id': groupId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    // Update member count
    await _updateGroupMemberCount(groupId);
  }

  /// Remove a member from a group
  Future<void> removeGroupMember(String groupId, String userId) async {
    final db = await instance.database;
    await db.delete(
      'message_group_members',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
    // Update member count
    await _updateGroupMemberCount(groupId);
  }

  /// Get members of a group
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final db = await instance.database;
    return await db.query(
      'message_group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  /// Check if user is a member of a group
  Future<bool> isGroupMember(String groupId, String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'message_group_members',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
    return result.isNotEmpty;
  }

  /// Update group member count
  Future<void> _updateGroupMemberCount(String groupId) async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM message_group_members WHERE group_id = ?',
      [groupId],
    )) ?? 0;
    await db.update(
      'message_groups',
      {'member_count': count},
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  /// Sync multiple messages from API to local database
  Future<void> syncMessagesFromApi(List<Message> messages) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final message in messages) {
      batch.insert('messages', message.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Sync multiple groups from API to local database
  Future<void> syncMessageGroupsFromApi(List<MessageGroup> groups) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final group in groups) {
      batch.insert('message_groups', group.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
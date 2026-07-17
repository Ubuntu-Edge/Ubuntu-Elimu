
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:chw_augment/models/visit.dart';
import 'package:chw_augment/models/visit_note.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chw_augment.db');
    return await openDatabase(
      path,
      version: 1, // Keep version 1 for now, or increment and handle migrations
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Added onUpgrade callback
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS visits(
        id TEXT PRIMARY KEY,
        patientId TEXT,
        visitDate TEXT,
        chwId TEXT,
        visitType TEXT,
        visitLocation TEXT,
        chiefComplaint TEXT,
        symptoms TEXT,
        symptomsList TEXT,
        symptomDuration TEXT,
        symptomSeverity TEXT,
        diagnosis TEXT,
        diagnosisCodes TEXT,
        differentialDiagnosis TEXT,
        aiAssessment TEXT,
        treatment TEXT,
        medicationsGiven TEXT,
        proceduresPerformed TEXT,
        healthEducation TEXT,
        urgencyLevel TEXT DEFAULT 'routine',
        wasReferred INTEGER DEFAULT 0,
        referralLocation TEXT,
        referralReason TEXT,
        outcome TEXT,
        patientStatusAfter TEXT,
        followUpDate TEXT,
        followUpCompleted INTEGER DEFAULT 0,
        followUpNotes TEXT,
        vitals TEXT,
        notes TEXT,
        attachments TEXT,
        visitDurationMinutes INTEGER,
        createdAt TEXT,
        updatedAt TEXT
      )
      '''
    );
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS visit_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visitId TEXT,
        timestamp TEXT,
        content TEXT,
        FOREIGN KEY (visitId) REFERENCES visits (id) ON DELETE CASCADE
      )
      '''
    );
  }

  // Added onUpgrade method for database migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // For simplicity, if upgrading from an older version, we recreate tables if they don't exist.
    // In a real-world scenario, you would perform specific ALTER TABLE statements here for each version.
    if (oldVersion < newVersion) {
      await _onCreate(db, newVersion);
    }
  }

  // Visit operations
  Future<int> insertVisit(Visit visit) async {
    Database db = await database;
    return await db.insert('visits', visit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Visit>> getVisitsForPatient(String patientId) async { // Changed patientId to String
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'visitDate DESC', // Use visitDate
    );
    return List.generate(maps.length, (i) {
      return Visit.fromMap(maps[i]); // Use the fromMap constructor
    });
  }

  Future<int> updateVisit(Visit visit) async {
    Database db = await database;
    return await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> deleteVisit(String id) async {
    Database db = await database;
    return await db.delete(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // VisitNote operations
  Future<int> insertVisitNote(VisitNote note) async {
    Database db = await database;
    return await db.insert('visit_notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<VisitNote>> getVisitNotesForVisit(String visitId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visit_notes',
      where: 'visitId = ?',
      whereArgs: [visitId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) {
      return VisitNote(
        id: maps[i]['id'],
        visitId: maps[i]['visitId']?.toString() ?? '',
        timestamp: DateTime.parse(maps[i]['timestamp']),
        content: maps[i]['content'],
      );
    });
  }

  Future<int> updateVisitNote(VisitNote note) async {
    Database db = await database;
    return await db.update(
      'visit_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteVisitNote(int id) async {
    Database db = await database;
    return await db.delete(
      'visit_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

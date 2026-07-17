import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/user_feedback.dart';
import 'database_service.dart';

/// Service for handling user feedback submission and management
class FeedbackService {
  static final FeedbackService instance = FeedbackService._init();
  
  FeedbackService._init();
  
  final DatabaseService _dbService = DatabaseService.instance;
  final _uuid = const Uuid();
  
  // In-memory storage for feedback (will be synced to backend later)
  final List<UserFeedback> _feedbackList = [];
  
  /// Initialize feedback service and create table if needed
  Future<void> initialize() async {
    await _createFeedbackTable();
    await _loadFeedback();
    debugPrint('💬 FeedbackService initialized');
  }
  
  /// Create feedback table in database
  Future<void> _createFeedbackTable() async {
    final db = await _dbService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_feedback (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        rating INTEGER,
        screenshot_path TEXT,
        device_info TEXT,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL,
        response_message TEXT,
        responded_at TEXT
      )
    ''');
  }
  
  /// Load all feedback from database
  Future<void> _loadFeedback() async {
    final db = await _dbService.database;
    final result = await db.query('user_feedback', orderBy: 'created_at DESC');
    _feedbackList.clear();
    _feedbackList.addAll(result.map((map) => UserFeedback.fromMap(map)));
  }
  
  /// Submit new feedback
  Future<UserFeedback> submitFeedback({
    required String userId,
    required FeedbackType type,
    required FeedbackCategory category,
    required String title,
    required String description,
    int? rating,
    String? screenshotPath,
  }) async {
    final deviceInfo = await _getDeviceInfo();
    
    final feedback = UserFeedback(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      category: category,
      title: title,
      description: description,
      rating: rating,
      screenshotPath: screenshotPath,
      deviceInfo: deviceInfo,
      createdAt: DateTime.now(),
      status: FeedbackStatus.pending,
    );
    
    final db = await _dbService.database;
    await db.insert('user_feedback', feedback.toMap());
    _feedbackList.insert(0, feedback);
    
    debugPrint('✅ Feedback submitted: ${feedback.id}');
    return feedback;
  }
  
  /// Get all feedback for a user
  Future<List<UserFeedback>> getFeedbackByUser(String userId) async {
    return _feedbackList.where((f) => f.userId == userId).toList();
  }
  
  /// Get all feedback (for supervisors/admins)
  Future<List<UserFeedback>> getAllFeedback() async {
    return List.unmodifiable(_feedbackList);
  }
  
  /// Get feedback by status
  Future<List<UserFeedback>> getFeedbackByStatus(FeedbackStatus status) async {
    return _feedbackList.where((f) => f.status == status).toList();
  }
  
  /// Get feedback statistics
  Future<Map<String, int>> getFeedbackStatistics() async {
    final pending = _feedbackList.where((f) => f.status == FeedbackStatus.pending).length;
    final inReview = _feedbackList.where((f) => f.status == FeedbackStatus.inReview).length;
    final resolved = _feedbackList.where((f) => f.status == FeedbackStatus.resolved).length;
    final bugs = _feedbackList.where((f) => f.type == FeedbackType.bug).length;
    final suggestions = _feedbackList.where((f) => f.type == FeedbackType.suggestion).length;
    
    double avgRating = 0;
    final ratedFeedback = _feedbackList.where((f) => f.rating != null);
    if (ratedFeedback.isNotEmpty) {
      avgRating = ratedFeedback.map((f) => f.rating!).reduce((a, b) => a + b) / ratedFeedback.length;
    }
    
    return {
      'total': _feedbackList.length,
      'pending': pending,
      'inReview': inReview,
      'resolved': resolved,
      'bugs': bugs,
      'suggestions': suggestions,
      'averageRating': (avgRating * 10).round(), // Stored as int (e.g., 45 = 4.5)
    };
  }
  
  /// Update feedback status (for supervisors/admins)
  Future<void> updateFeedbackStatus(
    String feedbackId, 
    FeedbackStatus status, 
    {String? responseMessage}
  ) async {
    final index = _feedbackList.indexWhere((f) => f.id == feedbackId);
    if (index == -1) return;
    
    final updated = _feedbackList[index].copyWith(
      status: status,
      responseMessage: responseMessage,
      respondedAt: DateTime.now(),
    );
    
    final db = await _dbService.database;
    await db.update(
      'user_feedback',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [feedbackId],
    );
    
    _feedbackList[index] = updated;
    debugPrint('✅ Feedback status updated: $feedbackId -> ${status.name}');
  }
  
  /// Delete feedback
  Future<void> deleteFeedback(String feedbackId) async {
    final db = await _dbService.database;
    await db.delete('user_feedback', where: 'id = ?', whereArgs: [feedbackId]);
    _feedbackList.removeWhere((f) => f.id == feedbackId);
    debugPrint('🗑️ Feedback deleted: $feedbackId');
  }
  
  /// Get device info for debugging
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'platform': Platform.operatingSystem,
        'platformVersion': Platform.operatingSystemVersion,
        'locale': Platform.localeName,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Could not get device info',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}

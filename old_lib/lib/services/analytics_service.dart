import 'package:flutter/foundation.dart';
import 'database_service.dart';

/// Analytics data point for charting
class AnalyticsDataPoint {
  final DateTime date;
  final double value;
  final String? label;

  AnalyticsDataPoint({
    required this.date,
    required this.value,
    this.label,
  });
}

/// Analytics summary for dashboard display
class AnalyticsSummary {
  final int totalPatients;
  final int newPatientsThisWeek;
  final int newPatientsThisMonth;
  final int totalVisits;
  final int visitsThisWeek;
  final int visitsThisMonth;
  final int highRiskPatients;
  final int pendingFollowups;
  final int completedFollowups;
  final int referralsMade;
  final int referralsCompleted;
  final double followupCompletionRate;
  final double averageVisitsPerPatient;
  final Map<String, int> patientsByGender;
  final Map<String, int> patientsByAgeGroup;
  final Map<String, int> visitsByMonth;
  final Map<String, int> commonDiagnoses;
  final Map<String, int> triageLevelDistribution;

  AnalyticsSummary({
    required this.totalPatients,
    required this.newPatientsThisWeek,
    required this.newPatientsThisMonth,
    required this.totalVisits,
    required this.visitsThisWeek,
    required this.visitsThisMonth,
    required this.highRiskPatients,
    required this.pendingFollowups,
    required this.completedFollowups,
    required this.referralsMade,
    required this.referralsCompleted,
    required this.followupCompletionRate,
    required this.averageVisitsPerPatient,
    required this.patientsByGender,
    required this.patientsByAgeGroup,
    required this.visitsByMonth,
    required this.commonDiagnoses,
    required this.triageLevelDistribution,
  });
}

/// AnalyticsService provides comprehensive analytics for the CHW app
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._init();
  
  AnalyticsService._init();
  
  final DatabaseService _dbService = DatabaseService.instance;
  
  /// Get comprehensive analytics summary for a CHW
  Future<AnalyticsSummary> getAnalyticsSummary(String chwId) async {
    final db = await _dbService.database;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    // Total patients
    final totalPatients = await _getCount(db, 'patients', 'chw_id = ?', [chwId]);
    
    // New patients this week
    final newPatientsThisWeek = await _getCount(
      db, 'patients',
      'chw_id = ? AND registered_date >= ?',
      [chwId, startOfWeek.toIso8601String()],
    );
    
    // New patients this month
    final newPatientsThisMonth = await _getCount(
      db, 'patients',
      'chw_id = ? AND registered_date >= ?',
      [chwId, startOfMonth.toIso8601String()],
    );
    
    // Total visits
    final totalVisits = await _getCount(db, 'visits', 'chw_id = ?', [chwId]);
    
    // Visits this week
    final visitsThisWeek = await _getCount(
      db, 'visits',
      'chw_id = ? AND visit_date >= ?',
      [chwId, startOfWeek.toIso8601String()],
    );
    
    // Visits this month
    final visitsThisMonth = await _getCount(
      db, 'visits',
      'chw_id = ? AND visit_date >= ?',
      [chwId, startOfMonth.toIso8601String()],
    );
    
    // High risk patients
    final highRiskPatients = await _getCount(
      db, 'patients',
      'chw_id = ? AND is_high_risk = 1',
      [chwId],
    );
    
    // Follow-ups
    final pendingFollowups = await _getCount(
      db, 'visits',
      'chw_id = ? AND follow_up_completed = 0 AND follow_up_date IS NOT NULL',
      [chwId],
    );
    
    final completedFollowups = await _getCount(
      db, 'visits',
      'chw_id = ? AND follow_up_completed = 1',
      [chwId],
    );
    
    // Referrals
    final referralsMade = await _getCount(db, 'referrals', 'chw_id = ?', [chwId]);
    final referralsCompleted = await _getCount(
      db, 'referrals',
      'chw_id = ? AND outcome IS NOT NULL',
      [chwId],
    );
    
    // Follow-up completion rate
    final totalFollowups = pendingFollowups + completedFollowups;
    final followupCompletionRate = totalFollowups > 0
        ? (completedFollowups / totalFollowups) * 100
        : 0.0;
    
    // Average visits per patient
    final averageVisitsPerPatient = totalPatients > 0
        ? totalVisits / totalPatients
        : 0.0;
    
    // Patients by gender
    final patientsByGender = await _getDistribution(
      db, 'patients', 'gender', 'chw_id = ?', [chwId],
    );
    
    // Patients by age group
    final patientsByAgeGroup = await _getPatientsByAgeGroup(db, chwId);
    
    // Visits by month (last 6 months)
    final visitsByMonth = await _getVisitsByMonth(db, chwId, 6);
    
    // Common diagnoses
    final commonDiagnoses = await _getDistribution(
      db, 'visits', 'diagnosis', 'chw_id = ? AND diagnosis IS NOT NULL', [chwId],
    );
    
    // Triage level distribution - calculated from real visit data
    final triageLevelDistribution = await _getDistribution(
      db, 'visits', 'triage_level', 'chw_id = ? AND triage_level IS NOT NULL', [chwId],
    );
    
    return AnalyticsSummary(
      totalPatients: totalPatients,
      newPatientsThisWeek: newPatientsThisWeek,
      newPatientsThisMonth: newPatientsThisMonth,
      totalVisits: totalVisits,
      visitsThisWeek: visitsThisWeek,
      visitsThisMonth: visitsThisMonth,
      highRiskPatients: highRiskPatients,
      pendingFollowups: pendingFollowups,
      completedFollowups: completedFollowups,
      referralsMade: referralsMade,
      referralsCompleted: referralsCompleted,
      followupCompletionRate: followupCompletionRate,
      averageVisitsPerPatient: averageVisitsPerPatient,
      patientsByGender: patientsByGender,
      patientsByAgeGroup: patientsByAgeGroup,
      visitsByMonth: visitsByMonth,
      commonDiagnoses: commonDiagnoses,
      triageLevelDistribution: triageLevelDistribution,
    );
  }
  
  /// Get visit trend data for charting
  Future<List<AnalyticsDataPoint>> getVisitTrend(String chwId, int days) async {
    final db = await _dbService.database;
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final result = await db.rawQuery('''
      SELECT DATE(visit_date) as date, COUNT(*) as count
      FROM visits
      WHERE chw_id = ? AND visit_date >= ?
      GROUP BY DATE(visit_date)
      ORDER BY date ASC
    ''', [chwId, startDate.toIso8601String()]);
    
    return result.map((row) {
      return AnalyticsDataPoint(
        date: DateTime.parse(row['date'] as String),
        value: (row['count'] as int).toDouble(),
      );
    }).toList();
  }
  
  /// Get patient registration trend
  Future<List<AnalyticsDataPoint>> getPatientRegistrationTrend(String chwId, int days) async {
    final db = await _dbService.database;
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final result = await db.rawQuery('''
      SELECT DATE(registered_date) as date, COUNT(*) as count
      FROM patients
      WHERE chw_id = ? AND registered_date >= ?
      GROUP BY DATE(registered_date)
      ORDER BY date ASC
    ''', [chwId, startDate.toIso8601String()]);
    
    return result.map((row) {
      return AnalyticsDataPoint(
        date: DateTime.parse(row['date'] as String),
        value: (row['count'] as int).toDouble(),
      );
    }).toList();
  }
  
  /// Get performance metrics for a CHW
  Future<Map<String, double>> getPerformanceMetrics(String chwId) async {
    final summary = await getAnalyticsSummary(chwId);
    
    return {
      'patientCoverage': summary.totalPatients.toDouble(),
      'visitFrequency': summary.averageVisitsPerPatient,
      'followupRate': summary.followupCompletionRate,
      'referralSuccessRate': summary.referralsMade > 0
          ? (summary.referralsCompleted / summary.referralsMade) * 100
          : 0.0,
      'highRiskManagement': summary.totalPatients > 0
          ? (summary.highRiskPatients / summary.totalPatients) * 100
          : 0.0,
    };
  }
  
  /// Get weekly activity summary
  Future<Map<String, int>> getWeeklyActivitySummary(String chwId) async {
    final db = await _dbService.database;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    final visits = await _getCount(
      db, 'visits',
      'chw_id = ? AND visit_date >= ?',
      [chwId, startOfWeek.toIso8601String()],
    );
    
    final newPatients = await _getCount(
      db, 'patients',
      'chw_id = ? AND registered_date >= ?',
      [chwId, startOfWeek.toIso8601String()],
    );
    
    final followupsCompleted = await _getCount(
      db, 'visits',
      'chw_id = ? AND follow_up_completed = 1 AND visit_date >= ?',
      [chwId, startOfWeek.toIso8601String()],
    );
    
    final referrals = await _getCount(
      db, 'referrals',
      'chw_id = ? AND referral_date >= ?',
      [chwId, startOfWeek.toIso8601String()],
    );
    
    return {
      'visits': visits,
      'newPatients': newPatients,
      'followupsCompleted': followupsCompleted,
      'referrals': referrals,
    };
  }
  
  /// Helper: Get count from a table
  Future<int> _getCount(
    dynamic db,
    String table,
    String? where,
    List<dynamic>? whereArgs,
  ) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table ${where != null ? "WHERE $where" : ""}',
      whereArgs ?? [],
    );
    return result.first['count'] as int;
  }
  
  /// Helper: Get distribution of a column
  Future<Map<String, int>> _getDistribution(
    dynamic db,
    String table,
    String column,
    String? where,
    List<dynamic>? whereArgs,
  ) async {
    final result = await db.rawQuery('''
      SELECT $column, COUNT(*) as count
      FROM $table
      ${where != null ? "WHERE $where" : ""}
      GROUP BY $column
      ORDER BY count DESC
      LIMIT 10
    ''', whereArgs ?? []);
    
    final distribution = <String, int>{};
    for (final row in result) {
      final key = row[column]?.toString() ?? 'Unknown';
      distribution[key] = row['count'] as int;
    }
    return distribution;
  }
  
  /// Helper: Get patients by age group
  Future<Map<String, int>> _getPatientsByAgeGroup(dynamic db, String chwId) async {
    // Since age calculation depends on date_of_birth, we'll categorize
    final ageGroups = <String, int>{
      '0-5': 0,
      '6-17': 0,
      '18-35': 0,
      '36-55': 0,
      '56+': 0,
    };
    
    final patients = await db.query(
      'patients',
      columns: ['date_of_birth'],
      where: 'chw_id = ? AND date_of_birth IS NOT NULL',
      whereArgs: [chwId],
    );
    
    final now = DateTime.now();
    for (final patient in patients) {
      final dobStr = patient['date_of_birth'] as String?;
      if (dobStr == null) continue;
      
      try {
        final dob = DateTime.parse(dobStr);
        final age = now.year - dob.year;
        
        if (age <= 5) {
          ageGroups['0-5'] = (ageGroups['0-5'] ?? 0) + 1;
        } else if (age <= 17) {
          ageGroups['6-17'] = (ageGroups['6-17'] ?? 0) + 1;
        } else if (age <= 35) {
          ageGroups['18-35'] = (ageGroups['18-35'] ?? 0) + 1;
        } else if (age <= 55) {
          ageGroups['36-55'] = (ageGroups['36-55'] ?? 0) + 1;
        } else {
          ageGroups['56+'] = (ageGroups['56+'] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('Error parsing date_of_birth: $e');
      }
    }
    
    return ageGroups;
  }
  
  /// Helper: Get visits by month
  Future<Map<String, int>> _getVisitsByMonth(dynamic db, String chwId, int months) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    
    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', visit_date) as month, COUNT(*) as count
      FROM visits
      WHERE chw_id = ? AND visit_date >= ?
      GROUP BY month
      ORDER BY month ASC
    ''', [chwId, startDate.toIso8601String()]);
    
    final visitsByMonth = <String, int>{};
    for (final row in result) {
      final month = row['month'] as String;
      visitsByMonth[month] = row['count'] as int;
    }
    return visitsByMonth;
  }
}

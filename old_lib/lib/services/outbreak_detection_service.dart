import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../models/outbreak_detection.dart';
import 'database_service.dart';

/// Outbreak Detection Service
/// Implements Community Health Mapping & Outbreak Detection
/// 
/// Features:
/// - Detect disease clusters in communities
/// - Track case counts by location
/// - Generate outbreak alerts
/// - Provide community health statistics
class OutbreakDetectionService {
  static final OutbreakDetectionService instance = OutbreakDetectionService._init();
  final _uuid = const Uuid();
  
  OutbreakDetectionService._init();

  /// Scan all visits and detect potential outbreaks
  Future<List<OutbreakAlert>> detectOutbreaks(String chwId) async {
    final patients = await DatabaseService.instance.getPatientsByCHW(chwId);
    
    // Build case records from recent visits
    List<CaseRecord> allCases = [];
    
    for (var patient in patients) {
      final visits = await DatabaseService.instance.getVisitsByPatient(patient.id);
      
      // Check last 30 days of visits
      for (var visit in visits) {
        if (DateTime.now().difference(visit.visitDate).inDays > 30) continue;
        if (visit.diagnosis == null || visit.diagnosis!.isEmpty) continue;
        
        allCases.add(CaseRecord(
          patientId: patient.id,
          patientName: '${patient.firstName} ${patient.lastName}',
          disease: visit.diagnosis!,
          village: patient.village ?? 'Unknown',
          diagnosisDate: visit.visitDate,
          symptoms: visit.symptoms,
          outcome: visit.outcome,
        ));
      }
    }
    
    // Group cases by disease and location
    Map<String, List<CaseRecord>> clusters = {};
    
    for (var caseRecord in allCases) {
      // Normalize disease name
      final diseaseKey = _normalizeDiagnosis(caseRecord.disease);
      final locationKey = caseRecord.village.toLowerCase();
      final clusterKey = '$diseaseKey|$locationKey';
      
      clusters.putIfAbsent(clusterKey, () => []);
      clusters[clusterKey]!.add(caseRecord);
    }
    
    // Analyze clusters for potential outbreaks
    List<OutbreakAlert> alerts = [];
    
    for (var entry in clusters.entries) {
      final parts = entry.key.split('|');
      final disease = parts[0];
      final village = parts[1];
      final cases = entry.value;
      
      // Check if this meets outbreak threshold
      final threshold = TrackableDiseases.getOutbreakThreshold(disease);
      
      if (cases.length >= threshold) {
        final alert = _createOutbreakAlert(disease, village, cases);
        if (alert != null) {
          alerts.add(alert);
        }
      }
    }
    
    // Sort by severity
    alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    
    return alerts;
  }

  /// Get community health statistics for a village
  Future<CommunityHealthStats> getCommunityStats(String chwId, String village) async {
    final patients = await DatabaseService.instance.getPatientsByCHW(chwId);
    final villagePatients = patients.where((p) => 
      p.village?.toLowerCase() == village.toLowerCase()
    ).toList();
    
    Map<String, int> diseaseBreakdown = {};
    int visitsLast30Days = 0;
    
    for (var patient in villagePatients) {
      final visits = await DatabaseService.instance.getVisitsByPatient(patient.id);
      
      for (var visit in visits) {
        if (DateTime.now().difference(visit.visitDate).inDays <= 30) {
          visitsLast30Days++;
          
          if (visit.diagnosis != null) {
            final normalizedDisease = _normalizeDiagnosis(visit.diagnosis!);
            diseaseBreakdown[normalizedDisease] = 
              (diseaseBreakdown[normalizedDisease] ?? 0) + 1;
          }
        }
      }
    }
    
    // Get active alerts for this village
    final allAlerts = await detectOutbreaks(chwId);
    final villageAlerts = allAlerts.where((a) => 
      a.village.toLowerCase() == village.toLowerCase() && !a.isResolved
    ).toList();
    
    // Calculate health score
    double healthScore = 100;
    if (villageAlerts.isNotEmpty) {
      healthScore -= villageAlerts.length * 10;
      for (var alert in villageAlerts) {
        switch (alert.severity) {
          case OutbreakSeverity.critical:
            healthScore -= 20;
            break;
          case OutbreakSeverity.high:
            healthScore -= 15;
            break;
          case OutbreakSeverity.moderate:
            healthScore -= 10;
            break;
          case OutbreakSeverity.low:
            healthScore -= 5;
            break;
        }
      }
    }
    
    // Identify top concerns
    List<String> topConcerns = [];
    if (villageAlerts.isNotEmpty) {
      topConcerns.addAll(villageAlerts.map((a) => a.disease));
    }
    
    // Add diseases with high case counts
    final sortedDiseases = diseaseBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var entry in sortedDiseases.take(3)) {
      if (!topConcerns.contains(entry.key)) {
        topConcerns.add('${entry.key} (${entry.value} cases)');
      }
    }
    
    return CommunityHealthStats(
      village: village,
      totalPatients: villagePatients.length,
      totalVisitsLast30Days: visitsLast30Days,
      diseaseBreakdown: diseaseBreakdown,
      activeAlerts: villageAlerts,
      healthScore: healthScore.clamp(0, 100),
      topConcerns: topConcerns,
    );
  }

  /// Get all villages with their statistics
  Future<List<CommunityHealthStats>> getAllCommunityStats(String chwId) async {
    final patients = await DatabaseService.instance.getPatientsByCHW(chwId);
    
    // Get unique villages
    final villages = patients
      .where((p) => p.village != null && p.village!.isNotEmpty)
      .map((p) => p.village!)
      .toSet();
    
    List<CommunityHealthStats> stats = [];
    
    for (var village in villages) {
      final stat = await getCommunityStats(chwId, village);
      stats.add(stat);
    }
    
    // Sort by health score (lowest first - most concerning)
    stats.sort((a, b) => a.healthScore.compareTo(b.healthScore));
    
    return stats;
  }

  /// Process a new visit and check for outbreak implications
  Future<OutbreakAlert?> processNewVisit(
    Patient patient,
    Visit visit,
    String chwId,
  ) async {
    if (visit.diagnosis == null || visit.diagnosis!.isEmpty) return null;
    if (patient.village == null || patient.village!.isEmpty) return null;
    
    final disease = _normalizeDiagnosis(visit.diagnosis!);
    
    // Check if this is a high-priority disease
    if (!TrackableDiseases.isHighPriority(visit.diagnosis!)) return null;
    
    // Get existing cases of this disease in this village
    final patients = await DatabaseService.instance.getPatientsByCHW(chwId);
    final villagePatients = patients.where((p) => 
      p.village?.toLowerCase() == patient.village!.toLowerCase()
    ).toList();
    
    List<CaseRecord> recentCases = [];
    
    for (var vp in villagePatients) {
      final visits = await DatabaseService.instance.getVisitsByPatient(vp.id);
      
      for (var v in visits) {
        if (DateTime.now().difference(v.visitDate).inDays > 14) continue;
        if (v.diagnosis == null) continue;
        
        final vDisease = _normalizeDiagnosis(v.diagnosis!);
        if (vDisease == disease) {
          recentCases.add(CaseRecord(
            patientId: vp.id,
            patientName: '${vp.firstName} ${vp.lastName}',
            disease: v.diagnosis!,
            village: vp.village!,
            diagnosisDate: v.visitDate,
            symptoms: v.symptoms,
          ));
        }
      }
    }
    
    // Check if we've crossed the outbreak threshold
    final threshold = TrackableDiseases.getOutbreakThreshold(disease);
    
    if (recentCases.length >= threshold) {
      return _createOutbreakAlert(disease, patient.village!, recentCases);
    }
    
    return null;
  }

  /// Get summary statistics for dashboard
  Future<Map<String, dynamic>> getDashboardStats(String chwId) async {
    final allAlerts = await detectOutbreaks(chwId);
    final communityStats = await getAllCommunityStats(chwId);
    
    int criticalAlerts = allAlerts.where((a) => 
      a.severity == OutbreakSeverity.critical && !a.isResolved
    ).length;
    
    int highAlerts = allAlerts.where((a) => 
      a.severity == OutbreakSeverity.high && !a.isResolved
    ).length;
    
    int affectedCommunities = communityStats.where((s) => 
      s.activeAlerts.isNotEmpty
    ).length;
    
    int totalCases = allAlerts.fold(0, (sum, a) => sum + a.caseCount);
    
    return {
      'criticalAlerts': criticalAlerts,
      'highAlerts': highAlerts,
      'totalAlerts': allAlerts.where((a) => !a.isResolved).length,
      'affectedCommunities': affectedCommunities,
      'totalCommunities': communityStats.length,
      'totalCases': totalCases,
      'alerts': allAlerts,
      'communityStats': communityStats,
    };
  }

  // ========== Private Helper Methods ==========

  String _normalizeDiagnosis(String diagnosis) {
    // Normalize to lowercase and extract main disease name
    final lower = diagnosis.toLowerCase().trim();
    
    // Common mappings
    if (lower.contains('malaria')) return 'Malaria';
    if (lower.contains('diarrhea') || lower.contains('diarrhoea')) return 'Diarrhea';
    if (lower.contains('cholera')) return 'Cholera';
    if (lower.contains('typhoid')) return 'Typhoid';
    if (lower.contains('pneumonia')) return 'Pneumonia';
    if (lower.contains('tuberculosis') || lower == 'tb') return 'Tuberculosis';
    if (lower.contains('covid') || lower.contains('corona')) return 'COVID-19';
    if (lower.contains('measles')) return 'Measles';
    if (lower.contains('chicken pox') || lower.contains('chickenpox')) return 'Chicken Pox';
    if (lower.contains('dengue')) return 'Dengue';
    if (lower.contains('meningitis')) return 'Meningitis';
    
    // Return original with first letter capitalized
    return diagnosis.split(' ').map((w) => 
      w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : ''
    ).join(' ');
  }

  OutbreakAlert? _createOutbreakAlert(
    String disease,
    String village,
    List<CaseRecord> cases,
  ) {
    if (cases.isEmpty) return null;
    
    // Sort cases by date
    cases.sort((a, b) => a.diagnosisDate.compareTo(b.diagnosisDate));
    
    final firstCase = cases.first.diagnosisDate;
    final lastCase = cases.last.diagnosisDate;
    
    // Calculate new cases in last 7 days
    final newCases = cases.where((c) => 
      DateTime.now().difference(c.diagnosisDate).inDays <= 7
    ).length;
    
    // Calculate growth rate
    final olderCases = cases.length - newCases;
    double growthRate = 0;
    if (olderCases > 0) {
      growthRate = ((newCases - olderCases) / olderCases) * 100;
    } else if (newCases > 0) {
      growthRate = 100;
    }
    
    // Determine severity
    OutbreakSeverity severity = _determineSeverity(cases.length, growthRate, disease);
    
    // Generate description
    String description = _generateDescription(disease, village, cases.length, newCases);
    
    // Get recommended action
    String action = TrackableDiseases.getOutbreakResponse(disease);
    
    return OutbreakAlert(
      id: _uuid.v4(),
      disease: disease,
      village: village.isNotEmpty ? village[0].toUpperCase() + village.substring(1) : village,
      caseCount: cases.length,
      newCasesLast7Days: newCases,
      growthRate: growthRate,
      severity: severity,
      description: description,
      recommendedAction: action,
      affectedPatientIds: cases.map((c) => c.patientId).toList(),
      firstCaseDate: firstCase,
      lastCaseDate: lastCase,
      detectedAt: DateTime.now(),
    );
  }

  OutbreakSeverity _determineSeverity(int caseCount, double growthRate, String disease) {
    // High-priority diseases get elevated severity
    final isHighPriority = TrackableDiseases.isHighPriority(disease);
    
    if (caseCount >= 15 || growthRate > 100) {
      return OutbreakSeverity.critical;
    }
    if (caseCount >= 10 || growthRate > 50 || (isHighPriority && caseCount >= 5)) {
      return OutbreakSeverity.high;
    }
    if (caseCount >= 5 || growthRate > 25) {
      return OutbreakSeverity.moderate;
    }
    return OutbreakSeverity.low;
  }

  String _generateDescription(String disease, String village, int totalCases, int newCases) {
    if (newCases == totalCases) {
      return '$totalCases cases of $disease reported in $village in the last 7 days. Possible outbreak developing.';
    }
    
    if (newCases > totalCases / 2) {
      return '$totalCases cases of $disease in $village, with $newCases new cases this week. Outbreak is growing rapidly.';
    }
    
    return '$totalCases cases of $disease detected in $village. $newCases new cases in the last 7 days.';
  }
}

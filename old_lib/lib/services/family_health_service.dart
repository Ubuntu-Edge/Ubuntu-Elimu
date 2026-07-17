import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../models/family_health_profile.dart';
import 'database_service.dart';

/// Family Health Service
/// Implements the "Connect-the-Dots" System for family health tracking
/// 
/// Features:
/// - Track inherited genetic risks across family members
/// - Detect household exposure to infectious diseases
/// - Generate alerts when one family member's diagnosis affects others
class FamilyHealthService {
  static final FamilyHealthService instance = FamilyHealthService._init();
  final _uuid = const Uuid();
  
  FamilyHealthService._init();

  /// Build a complete family health profile
  Future<FamilyHealthProfile?> getFamilyHealthProfile(String familyId) async {
    // Get all patients in this family
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'patients',
      where: 'family_id = ?',
      whereArgs: [familyId],
    );
    
    if (result.isEmpty) return null;
    
    final patients = result.map((r) => Patient.fromMap(r)).toList();
    
    // Get head of household
    final head = patients.firstWhere(
      (p) => p.relationshipToHead?.toLowerCase() == 'head' || 
             p.relationshipToHead?.toLowerCase() == 'self',
      orElse: () => patients.first,
    );
    
    // Build member health profiles
    List<FamilyMemberHealth> members = [];
    List<InheritedRisk> inheritedRisks = [];
    List<EnvironmentalRisk> environmentalRisks = [];
    List<FamilyHealthAlert> alerts = [];
    
    for (var patient in patients) {
      final visits = await DatabaseService.instance.getVisitsByPatient(patient.id);
      
      // Build member profile
      final memberHealth = await _buildMemberHealth(patient, visits);
      members.add(memberHealth);
      
      // Check for inherited risks from this patient
      if (patient.hasChronicCondition == true && patient.chronicConditions != null) {
        final risks = _detectInheritedRisks(patient, patients);
        inheritedRisks.addAll(risks);
      }
      
      // Check for environmental/infectious risks
      for (var visit in visits.take(5)) { // Check last 5 visits
        if (visit.diagnosis != null) {
          final envRisks = _detectEnvironmentalRisks(patient, visit, patients);
          environmentalRisks.addAll(envRisks);
        }
      }
    }
    
    // Generate alerts from risks
    alerts.addAll(_generateAlertsFromInheritedRisks(inheritedRisks, familyId));
    alerts.addAll(_generateAlertsFromEnvironmentalRisks(environmentalRisks, familyId));
    
    // Calculate overall family risk score
    double familyRiskScore = _calculateFamilyRiskScore(members, alerts);
    
    return FamilyHealthProfile(
      familyId: familyId,
      familyName: head.lastName,
      headOfHouseholdId: head.id,
      members: members,
      alerts: alerts,
      inheritedRisks: inheritedRisks,
      environmentalRisks: environmentalRisks,
      overallFamilyRiskScore: familyRiskScore,
      lastUpdated: DateTime.now(),
    );
  }

  /// Process a new diagnosis and check for family implications
  Future<List<FamilyHealthAlert>> processNewDiagnosis(
    Patient patient,
    String diagnosis,
  ) async {
    List<FamilyHealthAlert> newAlerts = [];
    
    if (patient.familyId == null) return newAlerts;
    
    // Get family members
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'patients',
      where: 'family_id = ? AND id != ?',
      whereArgs: [patient.familyId, patient.id],
    );
    
    if (result.isEmpty) return newAlerts;
    
    final familyMembers = result.map((r) => Patient.fromMap(r)).toList();
    
    // Check for infectious disease exposure
    if (InfectiousDiseases.isHouseholdRisk(diagnosis)) {
      final alert = FamilyHealthAlert(
        id: _uuid.v4(),
        familyId: patient.familyId!,
        title: '⚠️ Household Exposure Alert',
        description: '${patient.firstName} diagnosed with $diagnosis. All household members may be at risk.',
        priority: AlertPriority.critical,
        type: AlertType.infectiousExposure,
        sourcePatientId: patient.id,
        affectedMemberIds: familyMembers.map((m) => m.id).toList(),
        recommendedAction: InfectiousDiseases.getHouseholdAction(diagnosis),
        createdAt: DateTime.now(),
      );
      newAlerts.add(alert);
    }
    
    // Check for heritable condition
    if (GeneticConditions.isHeritable(diagnosis)) {
      // Find children of this patient
      final children = familyMembers.where((m) {
        final rel = m.relationshipToHead?.toLowerCase() ?? '';
        return rel.contains('son') || rel.contains('daughter') || rel.contains('child');
      }).toList();
      
      if (children.isNotEmpty) {
        final alert = FamilyHealthAlert(
          id: _uuid.v4(),
          familyId: patient.familyId!,
          title: '🧬 Genetic Risk Detected',
          description: '${patient.firstName} diagnosed with $diagnosis. Children may be at increased risk.',
          priority: AlertPriority.medium,
          type: AlertType.geneticRisk,
          sourcePatientId: patient.id,
          affectedMemberIds: children.map((c) => c.id).toList(),
          recommendedAction: GeneticConditions.getScreeningRecommendation(diagnosis),
          createdAt: DateTime.now(),
        );
        newAlerts.add(alert);
      }
    }
    
    return newAlerts;
  }

  /// Get all family alerts for a CHW
  Future<List<FamilyHealthAlert>> getAllFamilyAlerts(String chwId) async {
    final patients = await DatabaseService.instance.getPatientsByCHW(chwId);
    
    // Get unique family IDs
    final familyIds = patients
        .where((p) => p.familyId != null)
        .map((p) => p.familyId!)
        .toSet();
    
    List<FamilyHealthAlert> allAlerts = [];
    
    for (var familyId in familyIds) {
      final profile = await getFamilyHealthProfile(familyId);
      if (profile != null) {
        allAlerts.addAll(profile.alerts);
      }
    }
    
    // Sort by priority and date
    allAlerts.sort((a, b) {
      final priorityCompare = a.priority.index.compareTo(b.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return allAlerts;
  }

  /// Get critical alerts that need immediate attention
  Future<List<FamilyHealthAlert>> getCriticalAlerts(String chwId) async {
    final allAlerts = await getAllFamilyAlerts(chwId);
    return allAlerts.where((a) => 
      a.priority == AlertPriority.critical && !a.isAcknowledged
    ).toList();
  }

  // ========== Private Helper Methods ==========

  Future<FamilyMemberHealth> _buildMemberHealth(
    Patient patient,
    List<Visit> visits,
  ) async {
    List<String> conditions = [];
    List<String> pendingScreenings = [];
    bool needsAttention = false;
    
    // Add chronic conditions
    if (patient.hasChronicCondition == true && patient.chronicConditions != null) {
      conditions.addAll(patient.chronicConditions!.split(',').map((c) => c.trim()));
    }
    
    // Check for pending follow-ups
    final pendingFollowups = visits.where((v) => 
      v.followUpDate != null && 
      !v.followUpCompleted &&
      v.followUpDate!.isBefore(DateTime.now())
    ).length;
    
    if (pendingFollowups > 0) {
      needsAttention = true;
      pendingScreenings.add('$pendingFollowups missed follow-up(s)');
    }
    
    // Check if pregnant
    if (patient.isPregnant == true) {
      needsAttention = true;
      pendingScreenings.add('Prenatal checkup');
    }
    
    // Check if under-5 child
    if (patient.age < 5) {
      pendingScreenings.add('Growth monitoring');
    }
    
    // Calculate individual risk score (simplified)
    double riskScore = 0;
    if (patient.isHighRisk) riskScore += 40;
    if (patient.isPregnant == true) riskScore += 20;
    if (patient.hasChronicCondition == true) riskScore += 25;
    if (pendingFollowups > 0) riskScore += pendingFollowups * 10;
    
    return FamilyMemberHealth(
      patientId: patient.id,
      name: '${patient.firstName} ${patient.lastName}',
      relationship: patient.relationshipToHead ?? 'Unknown',
      age: patient.age,
      conditions: conditions,
      pendingScreenings: pendingScreenings,
      riskScore: riskScore.clamp(0, 100),
      needsAttention: needsAttention || riskScore > 50,
    );
  }

  List<InheritedRisk> _detectInheritedRisks(
    Patient sourcePatient,
    List<Patient> allFamilyMembers,
  ) {
    List<InheritedRisk> risks = [];
    
    if (sourcePatient.chronicConditions == null) return risks;
    
    final conditions = sourcePatient.chronicConditions!.split(',').map((c) => c.trim());
    
    for (var condition in conditions) {
      if (!GeneticConditions.isHeritable(condition)) continue;
      
      // Find at-risk family members (children, siblings)
      final atRiskMembers = allFamilyMembers.where((m) {
        if (m.id == sourcePatient.id) return false;
        
        final rel = m.relationshipToHead?.toLowerCase() ?? '';
        
        // Children of source patient are at risk
        if (sourcePatient.relationshipToHead?.toLowerCase() == 'head') {
          return rel.contains('son') || rel.contains('daughter') || rel.contains('child');
        }
        
        // Siblings share genetic risk
        if (rel.contains('brother') || rel.contains('sister') || rel.contains('sibling')) {
          return true;
        }
        
        return false;
      }).toList();
      
      if (atRiskMembers.isNotEmpty) {
        risks.add(InheritedRisk(
          riskName: condition,
          sourcePatientId: sourcePatient.id,
          sourceName: '${sourcePatient.firstName} ${sourcePatient.lastName}',
          sourceRelationship: sourcePatient.relationshipToHead ?? 'Family member',
          atRiskMemberIds: atRiskMembers.map((m) => m.id).toList(),
          inheritanceProbability: 0.5, // Simplified probability
          screeningRecommendation: GeneticConditions.getScreeningRecommendation(condition),
        ));
      }
    }
    
    return risks;
  }

  List<EnvironmentalRisk> _detectEnvironmentalRisks(
    Patient sourcePatient,
    Visit visit,
    List<Patient> allFamilyMembers,
  ) {
    List<EnvironmentalRisk> risks = [];
    
    if (visit.diagnosis == null) return risks;
    
    if (!InfectiousDiseases.isHouseholdRisk(visit.diagnosis!)) return risks;
    
    // Check if this is a recent diagnosis (within last 30 days)
    final isRecent = DateTime.now().difference(visit.visitDate).inDays <= 30;
    if (!isRecent) return risks;
    
    final otherMembers = allFamilyMembers.where((m) => m.id != sourcePatient.id).toList();
    
    if (otherMembers.isEmpty) return risks;
    
    EnvironmentalRiskType riskType = EnvironmentalRiskType.infectious;
    final diagLower = visit.diagnosis!.toLowerCase();
    
    if (diagLower.contains('cholera') || diagLower.contains('typhoid') || diagLower.contains('diarrhea')) {
      riskType = EnvironmentalRiskType.waterBorne;
    } else if (diagLower.contains('malaria') || diagLower.contains('dengue')) {
      riskType = EnvironmentalRiskType.vectorBorne;
    }
    
    risks.add(EnvironmentalRisk(
      riskName: visit.diagnosis!,
      description: '${sourcePatient.firstName} diagnosed with ${visit.diagnosis}. Household members may be exposed.',
      type: riskType,
      sourcePatientId: sourcePatient.id,
      affectedMemberIds: otherMembers.map((m) => m.id).toList(),
      immediateAction: InfectiousDiseases.getHouseholdAction(visit.diagnosis!),
      detectedAt: visit.visitDate,
    ));
    
    return risks;
  }

  List<FamilyHealthAlert> _generateAlertsFromInheritedRisks(
    List<InheritedRisk> risks,
    String familyId,
  ) {
    return risks.where((r) => !r.screeningCompleted).map((risk) {
      return FamilyHealthAlert(
        id: _uuid.v4(),
        familyId: familyId,
        title: '🧬 Screening Recommended',
        description: '${risk.sourceName} has ${risk.riskName}. Family members should be screened.',
        priority: AlertPriority.medium,
        type: AlertType.geneticRisk,
        sourcePatientId: risk.sourcePatientId,
        affectedMemberIds: risk.atRiskMemberIds,
        recommendedAction: risk.screeningRecommendation,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  List<FamilyHealthAlert> _generateAlertsFromEnvironmentalRisks(
    List<EnvironmentalRisk> risks,
    String familyId,
  ) {
    return risks.where((r) => !r.actionTaken).map((risk) {
      return FamilyHealthAlert(
        id: _uuid.v4(),
        familyId: familyId,
        title: '⚠️ Household Exposure',
        description: risk.description,
        priority: AlertPriority.critical,
        type: AlertType.infectiousExposure,
        sourcePatientId: risk.sourcePatientId,
        affectedMemberIds: risk.affectedMemberIds,
        recommendedAction: risk.immediateAction,
        createdAt: risk.detectedAt,
      );
    }).toList();
  }

  double _calculateFamilyRiskScore(
    List<FamilyMemberHealth> members,
    List<FamilyHealthAlert> alerts,
  ) {
    if (members.isEmpty) return 0;
    
    // Average member risk
    double avgMemberRisk = members.fold(0.0, (sum, m) => sum + m.riskScore) / members.length;
    
    // Alert contribution
    double alertContribution = 0;
    for (var alert in alerts) {
      switch (alert.priority) {
        case AlertPriority.critical:
          alertContribution += 25;
          break;
        case AlertPriority.high:
          alertContribution += 15;
          break;
        case AlertPriority.medium:
          alertContribution += 10;
          break;
        case AlertPriority.low:
          alertContribution += 5;
          break;
      }
    }
    
    return (avgMemberRisk * 0.6 + alertContribution * 0.4).clamp(0, 100);
  }
}

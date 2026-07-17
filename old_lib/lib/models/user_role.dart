/// User roles in the CHW application
enum UserRole {
  chw,        // Community Health Worker - field worker
  supervisor, // Supervisor - manages CHWs
  admin,      // Administrator - full access
}

/// Extension methods for UserRole
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.chw:
        return 'Community Health Worker';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get shortName {
    switch (this) {
      case UserRole.chw:
        return 'CHW';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Check if this role can access supervisor features
  bool get canAccessSupervisorDashboard {
    return this == UserRole.supervisor || this == UserRole.admin;
  }

  /// Check if this role can manage users
  bool get canManageUsers {
    return this == UserRole.admin;
  }

  /// Check if this role can view analytics
  bool get canViewAnalytics {
    return this == UserRole.supervisor || this == UserRole.admin;
  }

  /// Check if this role can modify system settings
  bool get canModifySettings {
    return this == UserRole.admin;
  }

  /// Check if this role can approve referrals
  bool get canApproveReferrals {
    return this == UserRole.supervisor || this == UserRole.admin;
  }

  /// Check if this role can respond to feedback
  bool get canRespondToFeedback {
    return this == UserRole.supervisor || this == UserRole.admin;
  }

  /// Check if this role can view all CHW data
  bool get canViewAllCHWData {
    return this == UserRole.supervisor || this == UserRole.admin;
  }

  /// Check if this role can export data
  bool get canExportData {
    return this == UserRole.supervisor || this == UserRole.admin;
  }

  /// Get list of accessible features for this role
  List<String> get accessibleFeatures {
    final features = <String>[
      'patients',
      'visits',
      'triage',
      'training',
      'medical_library',
      'health_cards',
      'referrals',
      'followups',
      'ai_assistant',
      'visual_diagnosis',
    ];

    if (canAccessSupervisorDashboard) {
      features.addAll([
        'supervisor_dashboard',
        'chw_management',
        'outbreak_monitoring',
        'performance_reports',
      ]);
    }

    if (canManageUsers) {
      features.addAll([
        'user_management',
        'system_settings',
        'audit_logs',
        'data_backup',
      ]);
    }

    return features;
  }
}

/// Permission types for granular access control
enum Permission {
  // Patient permissions
  viewPatients,
  createPatients,
  editPatients,
  deletePatients,
  
  // Visit permissions
  viewVisits,
  createVisits,
  editVisits,
  deleteVisits,
  
  // Triage permissions
  performTriage,
  viewTriageHistory,
  
  // Training permissions
  accessTraining,
  manageTraining,
  
  // Referral permissions
  createReferrals,
  approveReferrals,
  viewAllReferrals,
  
  // Dashboard permissions
  viewPersonalDashboard,
  viewTeamDashboard,
  viewSystemDashboard,
  
  // Analytics permissions
  viewPersonalAnalytics,
  viewTeamAnalytics,
  exportAnalytics,
  
  // User management permissions
  viewUsers,
  createUsers,
  editUsers,
  deactivateUsers,
  
  // System permissions
  viewSettings,
  editSettings,
  viewAuditLogs,
  performBackup,
  
  // Feedback permissions
  submitFeedback,
  viewAllFeedback,
  respondToFeedback,
}

/// Role permissions mapping
class RolePermissions {
  static Set<Permission> getPermissions(UserRole role) {
    switch (role) {
      case UserRole.chw:
        return {
          Permission.viewPatients,
          Permission.createPatients,
          Permission.editPatients,
          Permission.viewVisits,
          Permission.createVisits,
          Permission.editVisits,
          Permission.performTriage,
          Permission.viewTriageHistory,
          Permission.accessTraining,
          Permission.createReferrals,
          Permission.viewPersonalDashboard,
          Permission.viewPersonalAnalytics,
          Permission.submitFeedback,
        };
      
      case UserRole.supervisor:
        return {
          ...getPermissions(UserRole.chw),
          Permission.deletePatients,
          Permission.deleteVisits,
          Permission.manageTraining,
          Permission.approveReferrals,
          Permission.viewAllReferrals,
          Permission.viewTeamDashboard,
          Permission.viewTeamAnalytics,
          Permission.exportAnalytics,
          Permission.viewUsers,
          Permission.viewAllFeedback,
          Permission.respondToFeedback,
        };
      
      case UserRole.admin:
        return Permission.values.toSet();
    }
  }

  static bool hasPermission(UserRole role, Permission permission) {
    return getPermissions(role).contains(permission);
  }
}

import 'package:flutter/material.dart';

enum TriageLevel {
  minimal,
  routine,
  moderate,
  urgent,
  critical;

  String get displayName {
    switch (this) {
      case TriageLevel.minimal:
        return 'MINIMAL';
      case TriageLevel.routine:
        return 'ROUTINE';
      case TriageLevel.moderate:
        return 'MODERATE';
      case TriageLevel.urgent:
        return 'URGENT';
      case TriageLevel.critical:
        return 'CRITICAL';
    }
  }

  String get description {
    switch (this) {
      case TriageLevel.minimal:
        return 'Can be managed at home';
      case TriageLevel.routine:
        return 'Monitor closely';
      case TriageLevel.moderate:
        return 'Clinic visit needed';
      case TriageLevel.urgent:
        return 'Seek care soon';
      case TriageLevel.critical:
        return 'Hospital NOW';
    }
  }

  Color get color {
    switch (this) {
      case TriageLevel.minimal:
        return Colors.green;
      case TriageLevel.routine:
        return Colors.yellow.shade700;
      case TriageLevel.moderate:
        return Colors.orange;
      case TriageLevel.urgent:
        return Colors.red.shade700;
      case TriageLevel.critical:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case TriageLevel.minimal:
        return Icons.check_circle;
      case TriageLevel.routine:
        return Icons.info;
      case TriageLevel.moderate:
        return Icons.warning;
      case TriageLevel.urgent:
        return Icons.local_hospital;
      case TriageLevel.critical:
        return Icons.emergency;
    }
  }

  static TriageLevel fromString(String level) {
    switch (level.toUpperCase()) {
      case 'MINIMAL':
        return TriageLevel.minimal;
      case 'ROUTINE':
        return TriageLevel.routine;
      case 'MODERATE':
        return TriageLevel.moderate;
      case 'URGENT':
        return TriageLevel.urgent;
      case 'CRITICAL':
        return TriageLevel.critical;
      default:
        return TriageLevel.moderate;
    }
  }
}
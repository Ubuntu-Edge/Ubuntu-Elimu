/// Health Card Service
/// Implements QR code and SMS communication functionality
///
/// Features:
/// - QR code generation for patient health cards
/// - SMS template management
/// - Reminder scheduling
/// - Vaccination record tracking
library;

import 'dart:convert';
import '../models/patient_health_card.dart';
import '../models/patient.dart';

class HealthCardService {
  static final HealthCardService _instance = HealthCardService._internal();
  factory HealthCardService() => _instance;
  HealthCardService._internal();

  // In-memory storage
  final Map<String, PatientHealthCard> _healthCards = {};
  final List<SMSReminder> _pendingReminders = [];
  final List<SMSReminder> _sentReminders = [];

  /// Generate health card for a patient
  PatientHealthCard generateHealthCard({
    required Patient patient,
    List<VaccinationRecord>? vaccinations,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? bloodType,
    String? emergencyContact,
    String? emergencyPhone,
    required String chwId,
    String? chwName,
    String? chwPhone,
  }) {
    PatientHealthCard card = PatientHealthCard(
      patientId: patient.id,
      firstName: patient.firstName,
      lastName: patient.lastName,
      dateOfBirth: patient.dateOfBirth,
      gender: patient.gender,
      bloodType: bloodType,
      allergies: allergies ?? [],
      chronicConditions: chronicConditions ?? [],
      currentMedications: [],
      vaccinations: vaccinations ?? [],
      emergencyContact: emergencyContact,
      emergencyPhone: emergencyPhone,
      lastUpdated: DateTime.now(),
      chwId: chwId,
      chwName: chwName,
      chwPhone: chwPhone,
    );

    _healthCards[patient.id] = card;
    return card;
  }

  /// Get health card for patient
  PatientHealthCard? getHealthCard(String patientId) {
    return _healthCards[patientId];
  }

  /// Parse QR code data
  Map<String, dynamic>? parseQRCode(String qrData) {
    try {
      return jsonDecode(qrData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Add vaccination record
  void addVaccination({
    required String patientId,
    required String vaccineName,
    required DateTime dateGiven,
    String? batchNumber,
    required String givenBy,
    DateTime? nextDueDate,
  }) {
    var card = _healthCards[patientId];
    if (card == null) return;

    var vaccination = VaccinationRecord(
      name: vaccineName,
      date: dateGiven,
      batchNumber: batchNumber,
      administrator: givenBy,
      nextDoseDate: nextDueDate,
    );

    List<VaccinationRecord> updatedVaccinations = [
      ...card.vaccinations,
      vaccination
    ];

    _healthCards[patientId] = PatientHealthCard(
      patientId: card.patientId,
      firstName: card.firstName,
      lastName: card.lastName,
      dateOfBirth: card.dateOfBirth,
      gender: card.gender,
      bloodType: card.bloodType,
      allergies: card.allergies,
      chronicConditions: card.chronicConditions,
      currentMedications: card.currentMedications,
      vaccinations: updatedVaccinations,
      emergencyContact: card.emergencyContact,
      emergencyPhone: card.emergencyPhone,
      lastUpdated: DateTime.now(),
      chwId: card.chwId,
      chwName: card.chwName,
      chwPhone: card.chwPhone,
    );

    // Schedule reminder if next dose is due
    if (nextDueDate != null && card.emergencyPhone != null) {
      scheduleReminder(
        patientId: patientId,
        phoneNumber: card.emergencyPhone!,
        reminderType: SMSReminderType.vaccination,
        scheduledDate: nextDueDate.subtract(const Duration(days: 3)),
        customMessage:
            'Reminder: ${card.firstName} ${card.lastName} is due for $vaccineName on ${_formatDate(nextDueDate)}',
      );
    }
  }

  /// Generate SMS message from template
  String generateSMS({
    required SMSReminderType templateType,
    required String patientName,
    String? appointmentDate,
    String? medicationName,
    String? additionalInfo,
  }) {
    switch (templateType) {
      case SMSReminderType.appointment:
        return SMSTemplates.appointmentReminder(
          patientName: patientName,
          date: appointmentDate ?? 'your scheduled date',
          time: additionalInfo ?? 'the scheduled time',
        );
      case SMSReminderType.medication:
        return SMSTemplates.medicationReminder(
          patientName: patientName,
          medication: medicationName ?? 'your medication',
        );
      case SMSReminderType.followUp:
        return SMSTemplates.followUpReminder(
          patientName: patientName,
          reason: additionalInfo ?? 'follow-up care',
          date: appointmentDate ?? 'soon',
        );
      case SMSReminderType.vaccination:
        return SMSTemplates.vaccinationReminder(
          patientName: patientName,
          vaccine: medicationName ?? 'scheduled vaccination',
          date: appointmentDate ?? 'the scheduled date',
        );
      case SMSReminderType.outbreakAlert:
        return SMSTemplates.outbreakAlert(
          disease: medicationName ?? 'health concern',
          village: additionalInfo ?? 'your area',
        );
      case SMSReminderType.antenatal:
        return SMSTemplates.antenatalReminder(
          patientName: patientName,
          date: appointmentDate ?? 'your scheduled date',
        );
      case SMSReminderType.general:
        return SMSTemplates.generalHealthTip(additionalInfo ?? 'Stay healthy!');
    }
  }

  /// Schedule an SMS reminder
  SMSReminder scheduleReminder({
    required String patientId,
    required String phoneNumber,
    required SMSReminderType reminderType,
    required DateTime scheduledDate,
    String? customMessage,
  }) {
    String message = customMessage ?? _getDefaultMessage(reminderType);

    SMSReminder reminder = SMSReminder(
      id: 'sms_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      patientPhone: phoneNumber,
      message: message,
      type: reminderType,
      scheduledDate: scheduledDate,
      isSent: false,
    );

    _pendingReminders.add(reminder);
    return reminder;
  }

  /// Get pending reminders
  List<SMSReminder> getPendingReminders() {
    return _pendingReminders.where((r) => !r.isSent).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  /// Get reminders due today
  List<SMSReminder> getDueReminders() {
    DateTime today = DateTime.now();
    return _pendingReminders
        .where((r) =>
            !r.isSent &&
            r.scheduledDate.year == today.year &&
            r.scheduledDate.month == today.month &&
            r.scheduledDate.day == today.day)
        .toList();
  }

  /// Mark reminder as sent
  void markReminderSent(String reminderId) {
    int index = _pendingReminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      var reminder = _pendingReminders[index];
      _pendingReminders.removeAt(index);
      _sentReminders.add(SMSReminder(
        id: reminder.id,
        patientId: reminder.patientId,
        patientPhone: reminder.patientPhone,
        message: reminder.message,
        type: reminder.type,
        scheduledDate: reminder.scheduledDate,
        isSent: true,
        sentDate: DateTime.now(),
      ));
    }
  }

  /// Get vaccination schedule for age
  List<Map<String, dynamic>> getVaccinationSchedule(int ageInMonths) {
    List<Map<String, dynamic>> schedule = [];

    // WHO Recommended immunization schedule
    Map<int, List<String>> vaccineSchedule = {
      0: ['BCG', 'OPV-0', 'Hepatitis B-Birth'],
      6: ['OPV-1', 'Pentavalent-1', 'PCV-1', 'Rotavirus-1'],
      10: ['OPV-2', 'Pentavalent-2', 'PCV-2', 'Rotavirus-2'],
      14: ['OPV-3', 'Pentavalent-3', 'PCV-3', 'IPV'],
      36: ['Rotavirus-3'], // 3 weeks
      9: ['Measles-1', 'Yellow Fever'],
      15: ['Measles-2'],
    };

    vaccineSchedule.forEach((month, vaccines) {
      for (var vaccine in vaccines) {
        bool isDue = ageInMonths >= month;
        schedule.add({
          'vaccine': vaccine,
          'dueMonth': month,
          'isDue': isDue,
          'isOverdue': ageInMonths > month + 2,
        });
      }
    });

    schedule
        .sort((a, b) => (a['dueMonth'] as int).compareTo(b['dueMonth'] as int));
    return schedule;
  }

  /// Check for overdue vaccinations
  List<Map<String, dynamic>> getOverdueVaccinations(
      String patientId, int ageInMonths) {
    var card = _healthCards[patientId];
    var schedule = getVaccinationSchedule(ageInMonths);

    List<String> receivedVaccines = [];
    if (card != null) {
      receivedVaccines = card.vaccinations.map((v) => v.name).toList();
    }

    return schedule
        .where((v) =>
            v['isOverdue'] == true && !receivedVaccines.contains(v['vaccine']))
        .toList();
  }

  /// Get default message for reminder type
  String _getDefaultMessage(SMSReminderType type) {
    switch (type) {
      case SMSReminderType.appointment:
        return 'Reminder: You have an appointment scheduled. Please attend on time.';
      case SMSReminderType.medication:
        return 'Reminder: Please take your medication as prescribed.';
      case SMSReminderType.vaccination:
        return 'Reminder: Vaccination is due. Please visit the health center.';
      case SMSReminderType.followUp:
        return 'Reminder: Your follow-up visit is due. Please contact your CHW.';
      case SMSReminderType.outbreakAlert:
        return 'HEALTH ALERT: Please take precautions and seek care if symptoms appear.';
      case SMSReminderType.antenatal:
        return 'Reminder: Your antenatal care visit is due. Please visit the health center.';
      case SMSReminderType.general:
        return 'Health reminder from your Community Health Worker.';
    }
  }

  /// Format date for SMS
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Generate printable card data
  Map<String, dynamic> getPrintableCardData(String patientId) {
    var card = _healthCards[patientId];
    if (card == null) return {};

    return {
      'name': '${card.firstName} ${card.lastName}',
      'dob':
          card.dateOfBirth != null ? _formatDate(card.dateOfBirth!) : 'Unknown',
      'gender': card.gender ?? 'Unknown',
      'bloodType': card.bloodType ?? 'Unknown',
      'allergies': card.allergies.join(', '),
      'conditions': card.chronicConditions.join(', '),
      'emergency':
          '${card.emergencyContact ?? ''} - ${card.emergencyPhone ?? ''}',
      'vaccinations': card.vaccinations
          .map((v) => '${v.name}: ${_formatDate(v.date)}')
          .join('\n'),
      'qrData': card.toQRCodeData(),
      'generated': _formatDate(card.lastUpdated),
    };
  }

  /// Update health card
  void updateHealthCard({
    required String patientId,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? emergencyContact,
    String? emergencyPhone,
  }) {
    var existing = _healthCards[patientId];
    if (existing == null) return;

    _healthCards[patientId] = PatientHealthCard(
      patientId: existing.patientId,
      firstName: existing.firstName,
      lastName: existing.lastName,
      dateOfBirth: existing.dateOfBirth,
      gender: existing.gender,
      bloodType: bloodType ?? existing.bloodType,
      allergies: allergies ?? existing.allergies,
      chronicConditions: chronicConditions ?? existing.chronicConditions,
      currentMedications: existing.currentMedications,
      vaccinations: existing.vaccinations,
      emergencyContact: emergencyContact ?? existing.emergencyContact,
      emergencyPhone: emergencyPhone ?? existing.emergencyPhone,
      lastUpdated: DateTime.now(),
      chwId: existing.chwId,
      chwName: existing.chwName,
      chwPhone: existing.chwPhone,
    );
  }

  /// Get SMS Templates
  List<SMSTemplate> getTemplates() {
    return [
      SMSTemplate(
        id: 'appointment',
        name: 'Appointment Reminder',
        description: 'Remind patient of upcoming appointment',
        type: SMSReminderType.appointment,
        messageTemplate:
            'Hello {name}, reminder of your appointment on {date} at {time}.',
      ),
      SMSTemplate(
        id: 'medication',
        name: 'Medication Reminder',
        description: 'Remind patient to take medication',
        type: SMSReminderType.medication,
        messageTemplate: 'Hello {name}, reminder to take your {medication}.',
      ),
      SMSTemplate(
        id: 'followup',
        name: 'Follow-up Reminder',
        description: 'Remind patient of follow-up visit',
        type: SMSReminderType.followUp,
        messageTemplate:
            'Hello {name}, you are due for a follow-up visit for {reason}.',
      ),
      SMSTemplate(
        id: 'vaccination',
        name: 'Vaccination Reminder',
        description: 'Remind patient of vaccination appointment',
        type: SMSReminderType.vaccination,
        messageTemplate:
            'Hello {name}, vaccination ({vaccine}) is scheduled for {date}.',
      ),
      SMSTemplate(
        id: 'general',
        name: 'General Health Tip',
        description: 'Send general health advice',
        type: SMSReminderType.general,
        messageTemplate: 'Health Tip: {message}',
      ),
    ];
  }

  /// Get sent reminders
  List<SMSReminder> getSentReminders() {
    return _sentReminders;
  }
}

/// SMS Template object for UI display
class SMSTemplate {
  final String id;
  final String name;
  final String description;
  final SMSReminderType type;
  final String messageTemplate;

  SMSTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.messageTemplate,
  });
}

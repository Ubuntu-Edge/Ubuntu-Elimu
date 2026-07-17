import 'dart:convert';

/// Patient Health Card Model
/// Implements SMS & Low-Tech Communication with QR codes
/// 
/// Features:
/// - QR code generation for patient records
/// - SMS reminder system
/// - Portable health summary

class PatientHealthCard {
  final String patientId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final List<VaccinationRecord> vaccinations;
  final String? emergencyContact;
  final String? emergencyPhone;
  final DateTime lastUpdated;
  final String chwId;
  final String? chwName;
  final String? chwPhone;

  PatientHealthCard({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    required this.allergies,
    required this.chronicConditions,
    required this.currentMedications,
    required this.vaccinations,
    this.emergencyContact,
    this.emergencyPhone,
    required this.lastUpdated,
    required this.chwId,
    this.chwName,
    this.chwPhone,
  });

  /// Generate compact JSON for QR code
  String toQRCodeData() {
    final compactData = {
      'id': patientId.substring(0, 8), // Short ID
      'n': '$firstName $lastName',
      'dob': dateOfBirth?.toIso8601String().substring(0, 10),
      'g': gender?.substring(0, 1),
      'bt': bloodType,
      'al': allergies.take(3).toList(),
      'cc': chronicConditions.take(3).toList(),
      'med': currentMedications.take(5).toList(),
      'ec': emergencyContact,
      'ep': emergencyPhone,
      'upd': lastUpdated.toIso8601String().substring(0, 10),
      'chw': chwName,
    };
    
    // Remove null values
    compactData.removeWhere((key, value) => value == null);
    
    return jsonEncode(compactData);
  }

  /// Generate printable health summary
  String toPrintableSummary() {
    final buffer = StringBuffer();
    
    buffer.writeln('='.padRight(40, '='));
    buffer.writeln('PATIENT HEALTH CARD');
    buffer.writeln('='.padRight(40, '='));
    buffer.writeln();
    buffer.writeln('Name: $firstName $lastName');
    if (dateOfBirth != null) {
      buffer.writeln('DOB: ${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}');
    }
    if (gender != null) buffer.writeln('Gender: $gender');
    if (bloodType != null) buffer.writeln('Blood Type: $bloodType');
    buffer.writeln();
    
    if (allergies.isNotEmpty) {
      buffer.writeln('ALLERGIES:');
      for (var allergy in allergies) {
        buffer.writeln('  • $allergy');
      }
      buffer.writeln();
    }
    
    if (chronicConditions.isNotEmpty) {
      buffer.writeln('CHRONIC CONDITIONS:');
      for (var condition in chronicConditions) {
        buffer.writeln('  • $condition');
      }
      buffer.writeln();
    }
    
    if (currentMedications.isNotEmpty) {
      buffer.writeln('CURRENT MEDICATIONS:');
      for (var med in currentMedications) {
        buffer.writeln('  • $med');
      }
      buffer.writeln();
    }
    
    if (vaccinations.isNotEmpty) {
      buffer.writeln('VACCINATIONS:');
      for (var vax in vaccinations.take(5)) {
        buffer.writeln('  • ${vax.name} - ${vax.date.day}/${vax.date.month}/${vax.date.year}');
      }
      buffer.writeln();
    }
    
    if (emergencyContact != null) {
      buffer.writeln('EMERGENCY CONTACT:');
      buffer.writeln('  $emergencyContact');
      if (emergencyPhone != null) buffer.writeln('  Tel: $emergencyPhone');
      buffer.writeln();
    }
    
    buffer.writeln('-'.padRight(40, '-'));
    buffer.writeln('CHW: $chwName');
    buffer.writeln('Last Updated: ${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year}');
    buffer.writeln('='.padRight(40, '='));
    
    return buffer.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'currentMedications': currentMedications,
      'vaccinations': vaccinations.map((v) => v.toMap()).toList(),
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'lastUpdated': lastUpdated.toIso8601String(),
      'chwId': chwId,
      'chwName': chwName,
      'chwPhone': chwPhone,
    };
  }

  factory PatientHealthCard.fromMap(Map<String, dynamic> map) {
    return PatientHealthCard(
      patientId: map['patientId'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth']) 
          : null,
      gender: map['gender'],
      bloodType: map['bloodType'],
      allergies: List<String>.from(map['allergies'] ?? []),
      chronicConditions: List<String>.from(map['chronicConditions'] ?? []),
      currentMedications: List<String>.from(map['currentMedications'] ?? []),
      vaccinations: (map['vaccinations'] as List?)
          ?.map((v) => VaccinationRecord.fromMap(v))
          .toList() ?? [],
      emergencyContact: map['emergencyContact'],
      emergencyPhone: map['emergencyPhone'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
      chwId: map['chwId'],
      chwName: map['chwName'],
      chwPhone: map['chwPhone'],
    );
  }
}

class VaccinationRecord {
  final String name;
  final DateTime date;
  final String? batchNumber;
  final String? administrator;
  final DateTime? nextDoseDate;

  VaccinationRecord({
    required this.name,
    required this.date,
    this.batchNumber,
    this.administrator,
    this.nextDoseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'batchNumber': batchNumber,
      'administrator': administrator,
      'nextDoseDate': nextDoseDate?.toIso8601String(),
    };
  }

  factory VaccinationRecord.fromMap(Map<String, dynamic> map) {
    return VaccinationRecord(
      name: map['name'],
      date: DateTime.parse(map['date']),
      batchNumber: map['batchNumber'],
      administrator: map['administrator'],
      nextDoseDate: map['nextDoseDate'] != null 
          ? DateTime.parse(map['nextDoseDate']) 
          : null,
    );
  }
}

/// SMS Message Templates
class SMSTemplates {
  static String appointmentReminder({
    required String patientName,
    required String date,
    required String time,
    String? location,
  }) {
    return 'Hello $patientName, this is a reminder of your health appointment on $date at $time.${location != null ? ' Location: $location.' : ''} Please attend. - CHW';
  }

  static String medicationReminder({
    required String patientName,
    required String medication,
    String? dosage,
  }) {
    return 'Hello $patientName, reminder to take your $medication${dosage != null ? ' ($dosage)' : ''}. Stay healthy! - CHW';
  }

  static String followUpReminder({
    required String patientName,
    required String reason,
    required String date,
  }) {
    return 'Hello $patientName, you are due for a follow-up visit for $reason. Please visit on $date. - CHW';
  }

  static String vaccinationReminder({
    required String patientName,
    required String vaccine,
    required String date,
  }) {
    return 'Hello $patientName, vaccination ($vaccine) is scheduled for $date. Please bring immunization card. - CHW';
  }

  static String outbreakAlert({
    required String disease,
    required String village,
  }) {
    return 'HEALTH ALERT: Cases of $disease reported in $village. Take precautions, seek care if symptoms appear. - Health Dept';
  }

  static String antenatalReminder({
    required String patientName,
    required String date,
  }) {
    return 'Hello $patientName, your antenatal care visit is scheduled for $date. Please attend for your baby\'s health. - CHW';
  }

  static String generalHealthTip(String tip) {
    return 'Health Tip: $tip - Your CHW';
  }
}

/// SMS Reminder Schedule
class SMSReminder {
  final String id;
  final String patientId;
  final String patientPhone;
  final String message;
  final SMSReminderType type;
  final DateTime scheduledDate;
  final DateTime? sentDate;
  final bool isSent;
  final bool isFailed;
  final String? failureReason;

  SMSReminder({
    required this.id,
    required this.patientId,
    required this.patientPhone,
    required this.message,
    required this.type,
    required this.scheduledDate,
    this.sentDate,
    this.isSent = false,
    this.isFailed = false,
    this.failureReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientPhone': patientPhone,
      'message': message,
      'type': type.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'sentDate': sentDate?.toIso8601String(),
      'isSent': isSent,
      'isFailed': isFailed,
      'failureReason': failureReason,
    };
  }

  factory SMSReminder.fromMap(Map<String, dynamic> map) {
    return SMSReminder(
      id: map['id'],
      patientId: map['patientId'],
      patientPhone: map['patientPhone'],
      message: map['message'],
      type: SMSReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SMSReminderType.general,
      ),
      scheduledDate: DateTime.parse(map['scheduledDate']),
      sentDate: map['sentDate'] != null 
          ? DateTime.parse(map['sentDate']) 
          : null,
      isSent: map['isSent'] ?? false,
      isFailed: map['isFailed'] ?? false,
      failureReason: map['failureReason'],
    );
  }
}

enum SMSReminderType {
  appointment,
  medication,
  followUp,
  vaccination,
  outbreakAlert,
  antenatal,
  general,
}

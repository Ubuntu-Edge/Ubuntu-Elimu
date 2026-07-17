import 'package:chw_augment/models/patient.dart';

class Family {
  final String id;
  final String familyName;
  final String headOfHouseholdId;
  final List<Patient> members;

  Family({
    required this.id,
    required this.familyName,
    required this.headOfHouseholdId,
    required this.members,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyName': familyName,
      'headOfHouseholdId': headOfHouseholdId,
      'members': members.map((x) => x.toMap()).toList(),
    };
  }

  factory Family.fromMap(Map<String, dynamic> map) {
    return Family(
      id: map['id'],
      familyName: map['familyName'],
      headOfHouseholdId: map['headOfHouseholdId'],
      members: List<Patient>.from(map['members']?.map((x) => Patient.fromMap(x))),
    );
  }

  Family copyWith({
    String? id,
    String? familyName,
    String? headOfHouseholdId,
    List<Patient>? members,
  }) {
    return Family(
      id: id ?? this.id,
      familyName: familyName ?? this.familyName,
      headOfHouseholdId: headOfHouseholdId ?? this.headOfHouseholdId,
      members: members ?? this.members,
    );
  }
}

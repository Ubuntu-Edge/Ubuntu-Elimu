import 'package:flutter/material.dart';
import 'package:chw_augment/models/patient.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:chw_augment/providers/auth_provider.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _chronicConditionsController = TextEditingController();
  final _notesController = TextEditingController();
  final _villageController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isPregnant = false;
  bool _isHighRisk = false;
  bool _hasChronicCondition = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _relationshipController.dispose();
    _chronicConditionsController.dispose();
    _notesController.dispose();
    _villageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chwId = authProvider.currentCHW?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Patient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a date of birth';
                    }
                    // TODO: Add more robust date validation
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _genderController,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship to Head of Household',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a relationship';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _villageController,
                  decoration: const InputDecoration(
                    labelText: 'Village',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Specific Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('Is Pregnant'),
                  value: _isPregnant,
                  onChanged: (bool? value) {
                    setState(() {
                      _isPregnant = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Is High Risk'),
                  value: _isHighRisk,
                  onChanged: (bool? value) {
                    setState(() {
                      _isHighRisk = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Has Chronic Condition'),
                  value: _hasChronicCondition,
                  onChanged: (bool? value) {
                    setState(() {
                      _hasChronicCondition = value ?? false;
                    });
                  },
                ),
                if (_hasChronicCondition)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
                    child: TextFormField(
                      controller: _chronicConditionsController,
                      decoration: const InputDecoration(
                        labelText: 'Chronic Conditions (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (chwId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CHW ID not available. Cannot add patient.')),
                        );
                        return;
                      }
                      final patient = Patient(
                        id: const Uuid().v4(),
                        chwId: chwId,
                        familyId: null, // familyId will be assigned when the family is created, so it can be null initially
                        firstName: _firstNameController.text,
                        lastName: _lastNameController.text,
                        dateOfBirth: DateTime.parse(_dobController.text),
                        gender: _genderController.text,
                        relationshipToHead: _relationshipController.text,
                        healthStatus: null, // Health status should be a String? now
                        isPregnant: _isPregnant,
                        isHighRisk: _isHighRisk,
                        hasChronicCondition: _hasChronicCondition,
                        chronicConditions: _chronicConditionsController.text.isNotEmpty ? _chronicConditionsController.text : null,
                        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                        village: _villageController.text.isNotEmpty ? _villageController.text : null,
                        location: _locationController.text.isNotEmpty ? _locationController.text : null,
                        registeredDate: DateTime.now(),
                      );
                      Navigator.pop(context, patient);
                    }
                  },
                  child: const Text('Add Patient'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
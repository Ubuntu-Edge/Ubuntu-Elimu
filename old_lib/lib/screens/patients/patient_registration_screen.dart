import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/patient.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/typeable_dropdown.dart';
import '../../widgets/phone_number_field.dart';
import '../../utils/age_calculator.dart';
import '../../utils/phone_formatter.dart';

// Custom TextInputFormatter to capitalize first letter of each word
class CapitalizeTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Split text by spaces and capitalize first letter of each word
    final words = newValue.text.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    final capitalizedText = capitalizedWords.join(' ');

    return TextEditingValue(
      text: capitalizedText,
      selection: newValue.selection,
    );
  }
}

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _alternativePhoneController = TextEditingController();
  final _nextOfKinNameController = TextEditingController();
  final _nextOfKinPhoneController = TextEditingController();

  // Note: We keep chronicConditionsController for *specific* chronic input
  final _chronicConditionsController = TextEditingController();

  String _selectedGender = 'male';
  DateTime? _selectedDateOfBirth;
  String? _selectedMaritalStatus;
  String? _selectedBloodType;
  String? _selectedRelationshipToHead;
  String? _selectedNextOfKinRelationship;

  File? _photoFile;
  final ImagePicker _picker = ImagePicker();

  // Lists for chip input fields
  List<String> _selectedChronicConditions = [];
  List<String> _selectedAllergies = [];
  List<String> _selectedMedications = [];

  // NEW: Multi-select Health Status
  List<String> _selectedHealthStatuses = [];
  bool _showHealthStatusOkButton = false;

  // Define possible health statuses for the dropdown
  static const List<String> _possibleHealthStatuses = [
    'Normal/Healthy',
    'Pregnant',
    'Chronic Condition',
    'High Risk Patient',
    'Disabled',
    'Malnourished',
  ];

  // Common options for dropdowns
  // TODO: May be needed later
  // static const List<String> _genderOptions = ['male', 'female', 'other'];
  static const List<String> _maritalStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Separated',
  ];
  static const List<String> _bloodTypeOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  static const List<String> _relationshipOptions = [
    'Head',
    'Spouse',
    'Son',
    'Daughter',
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Grandchild',
    'Other Relative',
  ];

  // Common chronic conditions
  static const List<String> _commonChronicConditions = [
    'Diabetes',
    'Hypertension',
    'HIV/AIDS',
    'Asthma',
    'Heart Disease',
    'Cancer',
    'Tuberculosis',
    'Epilepsy',
    'Kidney Disease',
    'Arthritis',
  ];

  // Common allergies
  static const List<String> _commonAllergies = [
    'Penicillin',
    'Peanuts',
    'Shellfish',
    'Latex',
    'Aspirin',
    'Sulfa Drugs',
    'Dust',
    'Pollen',
    'Eggs',
    'Milk',
  ];

  // Common medications
  static const List<String> _commonMedications = [
    'Metformin',
    'Amlodipine',
    'Atenolol',
    'Aspirin',
    'ARVs',
    'Insulin',
    'Paracetamol',
    'Ibuprofen',
  ];

  // Helper methods to derive model properties from the multi-select dropdown
  bool get _isPregnant => _selectedHealthStatuses.contains('Pregnant');
  bool get _hasChronicCondition =>
      _selectedHealthStatuses.contains('Chronic Condition') ||
      _selectedChronicConditions.isNotEmpty;
  bool get _isHighRisk => _selectedHealthStatuses.contains('High Risk Patient');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _chronicConditionsController.dispose();
    _nationalIdController.dispose();
    _alternativePhoneController.dispose();
    _nextOfKinNameController.dispose();
    _nextOfKinPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _photoFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      final ctx = context;
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_photoFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _photoFile = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date of birth
    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date of birth'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ctx = context;

    final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
    final patientProvider = Provider.of<PatientProvider>(ctx, listen: false);
    final chwId = authProvider.currentCHW?.id;

    if (chwId == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
            content: Text('CHW ID not available. Cannot register patient.')),
      );
      return;
    }

    // Derive model properties from the multi-select list
    final bool isPregnant = _isPregnant;
    final bool hasChronicCondition = _hasChronicCondition;
    final bool isHighRisk = _isHighRisk;

    // --- NEW PATIENT OBJECT CREATION WITH BACKEND-ALIGNED FIELDS ---
    final nameParts = _nameController.text.trim().split(' ');
    final String firstName = nameParts.isNotEmpty ? nameParts.first : 'Unnamed';
    final String lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Patient';

    // Format phone numbers to international format (+254)
    final String? formattedPhone = PhoneFormatter.formatToInternational(
        _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null);
    // Note: Alt phone and next of kin phone formatted when needed
    // final String? formattedAltPhone = PhoneFormatter.formatToInternational(
    //   _alternativePhoneController.text.trim().isNotEmpty ? _alternativePhoneController.text.trim() : null
    // );
    // final String? formattedNextOfKinPhone = PhoneFormatter.formatToInternational(
    //   _nextOfKinPhoneController.text.trim().isNotEmpty ? _nextOfKinPhoneController.text.trim() : null
    // );

    // Combine chronic conditions from both multi-select and text input
    String? chronicConditionsStr;
    if (_selectedChronicConditions.isNotEmpty ||
        _chronicConditionsController.text.isNotEmpty) {
      final allConditions = <String>[
        ..._selectedChronicConditions,
        if (_chronicConditionsController.text.isNotEmpty)
          _chronicConditionsController.text.trim(),
      ];
      chronicConditionsStr = allConditions.join(', ');
    }

    final patient = Patient(
      id: const Uuid().v4(),
      chwId: chwId,
      familyId: null,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: _selectedDateOfBirth!,
      gender: _selectedGender,
      phoneNumber: formattedPhone,
      relationshipToHead: _selectedRelationshipToHead ?? 'Head',
      healthStatus: _selectedHealthStatuses.isNotEmpty
          ? _selectedHealthStatuses.join(', ')
          : null,
      village: _villageController.text.trim().isNotEmpty
          ? _villageController.text.trim()
          : null,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      photoPath: _photoFile?.path,
      registeredDate: DateTime.now(),
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isPregnant: isPregnant,
      hasChronicCondition: hasChronicCondition,
      chronicConditions: chronicConditionsStr,
      isHighRisk: isHighRisk,
      // Additional fields not in local Patient model but available in API
      // These will be passed via the provider conversion to API request
    );

    final success = await patientProvider.addPatient(patient);

    if (!ctx.mounted) return;

    if (success) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Patient registered successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      // Navigate back with success result to trigger refresh
      Navigator.pop(ctx, true);
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(patientProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Register Patient')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Patient Information',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All information is kept anonymous and secure',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: 'Full Name',
                        hint: 'Enter full name',
                        controller: _nameController,
                        prefixIcon: Icons.person,
                        inputFormatters: [CapitalizeTextFormatter()],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _photoFile != null
                                    ? FileImage(_photoFile!)
                                    : null,
                                child: _photoFile == null
                                    ? Icon(Icons.person,
                                        size: 60, color: Colors.grey[400])
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tap to add photo (optional)',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Demographics'),
                      const SizedBox(height: 16),
                      _buildAgeAndGenderSection(),
                      const SizedBox(height: 16),

                      // Marital Status
                      TypeableDropdownField(
                        label: 'Marital Status',
                        hint: 'Select or type marital status',
                        options: _maritalStatusOptions,
                        initialValue: _selectedMaritalStatus,
                        onChanged: (value) {
                          setState(() {
                            _selectedMaritalStatus = value;
                          });
                        },
                        prefixIcon: Icons.people,
                      ),
                      const SizedBox(height: 16),

                      // Relationship to Head of Household
                      TypeableDropdownField(
                        label: 'Relationship to Head',
                        hint: 'Select or type relationship',
                        options: _relationshipOptions,
                        initialValue: _selectedRelationshipToHead,
                        onChanged: (value) {
                          setState(() {
                            _selectedRelationshipToHead = value;
                          });
                        },
                        prefixIcon: Icons.family_restroom,
                      ),
                      const SizedBox(height: 32),

                      _buildSectionHeader('Contact Information'),
                      const SizedBox(height: 16),
                      PhoneNumberField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'e.g., 0712345678',
                        isRequired: false,
                      ),
                      const SizedBox(height: 16),
                      PhoneNumberField(
                        controller: _alternativePhoneController,
                        label: 'Alternative Phone',
                        hint: 'e.g., 0712345678',
                        isRequired: false,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'National ID',
                        hint: 'Enter national ID number',
                        controller: _nationalIdController,
                        prefixIcon: Icons.badge,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Location'),
                      const SizedBox(height: 16),
                      TypeableDropdownField(
                        label: 'Village/Area',
                        hint: 'Select or type village name',
                        options: const [
                          'Kibera',
                          'Mathare',
                          'Dandora',
                          'Korogocho',
                          'Mukuru'
                        ], // Common villages
                        onChanged: (value) {
                          _villageController.text = value ?? '';
                        },
                        prefixIcon: Icons.location_city,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Specific Location',
                        hint: 'e.g., House number, landmark',
                        controller: _locationController,
                        prefixIcon: Icons.home,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Health Information'),
                      const SizedBox(height: 16),
                      // CHANGED: Use the new dropdown health section
                      _buildHealthSection(),
                      const SizedBox(height: 16),

                      // Blood Type
                      TypeableDropdownField(
                        label: 'Blood Type',
                        hint: 'Select or type blood type',
                        options: _bloodTypeOptions,
                        initialValue: _selectedBloodType,
                        onChanged: (value) {
                          setState(() {
                            _selectedBloodType = value;
                          });
                        },
                        prefixIcon: Icons.bloodtype,
                      ),
                      const SizedBox(height: 16),

                      // Chronic Conditions with chip input
                      if (_hasChronicCondition) ...[
                        ChipInputField(
                          label: 'Chronic Conditions',
                          hint: 'Type and add conditions',
                          suggestedItems: _commonChronicConditions,
                          selectedItems: _selectedChronicConditions,
                          onChanged: (items) {
                            setState(() {
                              _selectedChronicConditions = items;
                            });
                          },
                          prefixIcon: Icons.medical_services,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Allergies
                      ChipInputField(
                        label: 'Allergies',
                        hint: 'Type and add allergies',
                        suggestedItems: _commonAllergies,
                        selectedItems: _selectedAllergies,
                        onChanged: (items) {
                          setState(() {
                            _selectedAllergies = items;
                          });
                        },
                        prefixIcon: Icons.warning_amber,
                      ),
                      const SizedBox(height: 16),

                      // Current Medications
                      ChipInputField(
                        label: 'Current Medications',
                        hint: 'Type and add medications',
                        suggestedItems: _commonMedications,
                        selectedItems: _selectedMedications,
                        onChanged: (items) {
                          setState(() {
                            _selectedMedications = items;
                          });
                        },
                        prefixIcon: Icons.medication,
                      ),
                      const SizedBox(height: 32),

                      _buildSectionHeader('Next of Kin'),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Next of Kin Name',
                        hint: 'Enter full name',
                        controller: _nextOfKinNameController,
                        prefixIcon: Icons.person_outline,
                        inputFormatters: [CapitalizeTextFormatter()],
                      ),
                      const SizedBox(height: 16),
                      PhoneNumberField(
                        controller: _nextOfKinPhoneController,
                        label: 'Next of Kin Phone',
                        hint: 'e.g., 0712345678',
                        isRequired: false,
                      ),
                      const SizedBox(height: 16),
                      TypeableDropdownField(
                        label: 'Relationship',
                        hint: 'Select or type relationship',
                        options: const [
                          'Spouse',
                          'Parent',
                          'Child',
                          'Sibling',
                          'Friend',
                          'Other'
                        ],
                        initialValue: _selectedNextOfKinRelationship,
                        onChanged: (value) {
                          setState(() {
                            _selectedNextOfKinRelationship = value;
                          });
                        },
                        prefixIcon: Icons.family_restroom,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Additional Notes'),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Notes (Optional)',
                        hint: 'Any additional information...',
                        controller: _notesController,
                        maxLines: 4,
                        prefixIcon: Icons.note,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Register Patient',
                        onPressed: _handleRegistration,
                        isLoading: patientProvider.isLoading,
                        icon: Icons.person_add,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Cancel',
                        onPressed: () => Navigator.pop(context),
                        isOutlined: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // REVISED: Date of Birth picker and Gender
  Widget _buildAgeAndGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date of Birth Picker
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDateOfBirth ??
                  DateTime.now().subtract(const Duration(days: 365 * 25)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              helpText: 'Select Date of Birth',
              fieldLabelText: 'Date of Birth',
            );
            if (picked != null) {
              setState(() {
                _selectedDateOfBirth = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDateOfBirth == null
                    ? Colors.red[300]!
                    : Colors.grey[300]!,
                width: _selectedDateOfBirth == null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _selectedDateOfBirth == null
                      ? Colors.red
                      : Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth *',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDateOfBirth == null
                            ? 'Tap to select date of birth'
                            : AgeCalculator.formatDateForApi(
                                _selectedDateOfBirth!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDateOfBirth == null
                              ? Colors.grey[400]
                              : Colors.black87,
                        ),
                      ),
                      if (_selectedDateOfBirth != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Age: ${AgeCalculator.getAgeString(_selectedDateOfBirth!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),

        if (_selectedDateOfBirth == null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              'Date of birth is required',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Gender *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          initialValue: _selectedGender,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Gender is required';
            }
            return null;
          },
          builder: (FormFieldState<String> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildGenderOption('Male', 'male', Icons.man)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildGenderOption(
                            'Female', 'female', Icons.woman)),
                  ],
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // NEW: Multi-select Health Status section
  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Health Status',
            hintText: 'Select all applicable statuses',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            prefixIcon: Icon(Icons.medical_services_outlined),
          ),
          // We use this dummy value to trick DropdownButtonFormField into showing a hint/label
          // when multiple items are selected (which DropdownButtonFormField doesn't support natively).
          initialValue: _selectedHealthStatuses.isEmpty
              ? null
              : _selectedHealthStatuses.first,
          // Custom display text for multi-selection
          selectedItemBuilder: (context) {
            return _possibleHealthStatuses.map((String item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedHealthStatuses.isEmpty
                      ? 'Select all applicable statuses'
                      : '${_selectedHealthStatuses.length} selected',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: _possibleHealthStatuses
              .map((String status) {
                return DropdownMenuItem(
                  value: status,
                  // Use a custom widget to enable multi-selection via checkbox
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter menuSetState) {
                      final isSelected =
                          _selectedHealthStatuses.contains(status);

                      // Condition to handle 'Pregnant' visibility based on 'Gender'
                      if (status == 'Pregnant' && _selectedGender != 'female') {
                        return const SizedBox.shrink();
                      }

                      return InkWell(
                        onTap: () {
                          // Handle the selection logic
                          menuSetState(() {
                            setState(() {
                              if (isSelected) {
                                _selectedHealthStatuses.remove(status);
                                // If 'Chronic Condition' is removed, clear the notes field
                                if (status == 'Chronic Condition') {
                                  _chronicConditionsController.clear();
                                }
                              } else {
                                // If 'Normal' is selected, deselect all others
                                if (status == 'Normal/Healthy') {
                                  _selectedHealthStatuses = [status];
                                }
                                // If any other status is selected, remove 'Normal'
                                else if (_selectedHealthStatuses
                                    .contains('Normal/Healthy')) {
                                  _selectedHealthStatuses = [status];
                                } else {
                                  _selectedHealthStatuses.add(status);
                                }
                              }
                              _showHealthStatusOkButton = true;
                            });
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (v) {
                                  // Handle checkbox click
                                  menuSetState(() {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedHealthStatuses.remove(status);
                                        if (status == 'Chronic Condition') {
                                          _chronicConditionsController.clear();
                                        }
                                      } else {
                                        if (status == 'Normal/Healthy') {
                                          _selectedHealthStatuses = [status];
                                        } else if (_selectedHealthStatuses
                                            .contains('Normal/Healthy')) {
                                          _selectedHealthStatuses = [status];
                                        } else {
                                          _selectedHealthStatuses.add(status);
                                        }
                                      }
                                      _showHealthStatusOkButton = true;
                                    });
                                  });
                                },
                              ),
                              Expanded(child: Text(status)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              })
              .where((widget) => widget.child is! SizedBox)
              .toList(), // Remove the hidden 'Pregnant' item
          onChanged: (value) {
            // DropdownButtonFormField requires an onChanged, but the logic is handled by InkWell
            // in the custom DropdownMenuItem builder
          },
        ),

        // Show specific chronic conditions field only if 'Chronic Condition' is selected
        if (_hasChronicCondition) ...[
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Specific Chronic Conditions',
            hint: 'e.g., Diabetes, Hypertension, HIV',
            controller: _chronicConditionsController,
            prefixIcon: Icons.description,
            maxLines: 2,
          ),
        ],

        // Show OK button when health status is being selected
        if (_showHealthStatusOkButton) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showHealthStatusOkButton = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _selectedHealthStatuses.isEmpty
                        ? 'No health status selected'
                        : 'Health status saved: ${_selectedHealthStatuses.join(", ")}',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK - Save Health Status'),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );

  Widget _buildGenderOption(String label, String value, IconData icon) {
    final isSelected = _selectedGender == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = value;
          // If gender changes from female, remove 'Pregnant' status
          if (value != 'female' &&
              _selectedHealthStatuses.contains('Pregnant')) {
            _selectedHealthStatuses.remove('Pregnant');
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withAlpha((255 * 0.1).round())
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600]),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

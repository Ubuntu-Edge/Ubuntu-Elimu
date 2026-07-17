import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/patient_provider.dart';
import '../../models/patient.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/typeable_dropdown.dart';
import '../../widgets/phone_number_field.dart';
import '../../utils/age_calculator.dart';
import '../../utils/phone_formatter.dart';
import '../../theme/app_theme.dart';

// Custom TextInputFormatter to capitalize first letter of each word
class _CapitalizeTextFormatter extends TextInputFormatter {
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

class PatientEditScreen extends StatefulWidget {
  final Patient patient;

  const PatientEditScreen({super.key, required this.patient});

  @override
  State<PatientEditScreen> createState() => _PatientEditScreenState();
}

class _PatientEditScreenState extends State<PatientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _villageController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late final TextEditingController _chronicConditionsController;

  late String _selectedGender;
  DateTime? _selectedDateOfBirth;
  // TODO: May be needed later
  // String? _selectedMaritalStatus;
  // String? _selectedBloodType;
  String? _selectedRelationshipToHead;
  
  File? _photoFile;
  final ImagePicker _picker = ImagePicker();

  // Lists for chip input fields
  late List<String> _selectedChronicConditions;
  // ignore: unused_field
  late List<String> _selectedAllergies;
  // ignore: unused_field
  late List<String> _selectedMedications;
  late List<String> _selectedHealthStatuses;
  // TODO: May be needed later
  // bool _showHealthStatusOkButton = false;

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
  static const List<String> _genderOptions = ['male', 'female', 'other'];
  // TODO: May be needed later
  // static const List<String> _maritalStatusOptions = [
  //   'Single',
  //   'Married',
  //   'Divorced',
  //   'Widowed',
  //   'Separated',
  //   'Other',
  // ];
  // TODO: May be needed later
  // // static const List<String> _bloodTypeOptions = [
  //   'A+',
  //   'A-',
  //   'B+',
  //   'B-',
  //   'O+',
  //   'O-',
  //   'AB+',
  //   'AB-',
  //   'Unknown',
  // ];
  static const List<String> _relationshipOptions = [
    'Head',
    'Spouse',
    'Child',
    'Parent',
    'Sibling',
    'Grandparent',
    'Grandchild',
    'Other',
  ];

  // Common chronic conditions
  static const List<String> _commonChronicConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'HIV/AIDS',
    'Tuberculosis',
    'Cancer',
    'Kidney Disease',
    'Epilepsy',
    'Arthritis',
    'Sickle Cell Disease',
  ];

  // TODO: May be needed later
  // Common allergies
  // static const List<String> _commonAllergies = [
  //   'Penicillin',
  //   'Sulfa drugs',
  //   'Aspirin',
  //   'Ibuprofen',
  //   'Peanuts',
  //   'Tree nuts',
  //   'Shellfish',
  //   'Eggs',
  //   'Milk',
  //   'Latex',
  //   'Bee stings',
  // ];

  @override
  void initState() {
    super.initState();
    _initializeFromPatient();
  }

  void _initializeFromPatient() {
    final patient = widget.patient;
    
    // Initialize text controllers with patient data
    _nameController = TextEditingController(text: '${patient.firstName} ${patient.lastName}');
    _phoneController = TextEditingController(text: patient.phoneNumber ?? '');
    _villageController = TextEditingController(text: patient.village ?? '');
    _locationController = TextEditingController(text: patient.location ?? '');
    _notesController = TextEditingController(text: patient.notes ?? '');
    _chronicConditionsController = TextEditingController();

    // Initialize other fields
    _selectedGender = patient.gender ?? 'male';
    _selectedDateOfBirth = patient.dateOfBirth;
    _selectedRelationshipToHead = patient.relationshipToHead;
    
    // Parse chronic conditions from comma-separated string
    _selectedChronicConditions = patient.chronicConditions != null && patient.chronicConditions!.isNotEmpty
        ? patient.chronicConditions!.split(',').map((e) => e.trim()).toList()
        : [];
    
    _selectedAllergies = [];
    _selectedMedications = [];
    
    // Initialize health statuses based on patient flags
    _selectedHealthStatuses = [];
    if (patient.healthStatus != null && patient.healthStatus!.isNotEmpty) {
      _selectedHealthStatuses.add(patient.healthStatus!);
    }
    if (patient.isPregnant == true && !_selectedHealthStatuses.contains('Pregnant')) {
      _selectedHealthStatuses.add('Pregnant');
    }
    if (patient.hasChronicCondition == true && !_selectedHealthStatuses.contains('Chronic Condition')) {
      _selectedHealthStatuses.add('Chronic Condition');
    }
    if (patient.isHighRisk == true && !_selectedHealthStatuses.contains('High Risk Patient')) {
      _selectedHealthStatuses.add('High Risk Patient');
    }
    if (_selectedHealthStatuses.isEmpty) {
      _selectedHealthStatuses.add('Normal/Healthy');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _chronicConditionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime initialDate = _selectedDateOfBirth ?? DateTime(2000, 1, 1);
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
      fieldLabelText: 'Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  String _formatDateOfBirth() {
    if (_selectedDateOfBirth == null) return 'Select Date of Birth';
    final dob = _selectedDateOfBirth!;
    final ageString = AgeCalculator.getAgeString(dob);
    return '${dob.day}/${dob.month}/${dob.year} ($ageString)';
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _photoFile = File(image.path);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _photoFile = File(image.path);
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if (_photoFile != null || widget.patient.photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
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

  Future<void> _updatePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);

      // Parse name into first and last
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Format phone number
      final formattedPhone = PhoneFormatter.formatToInternational(_phoneController.text.trim());

      // Determine health flags from selected statuses
      final isPregnant = _selectedHealthStatuses.contains('Pregnant');
      final hasChronicCondition = _selectedHealthStatuses.contains('Chronic Condition') ||
          _selectedChronicConditions.isNotEmpty;
      final isHighRisk = _selectedHealthStatuses.contains('High Risk Patient');

      // Create updated patient
      final updatedPatient = widget.patient.copyWith(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: _selectedDateOfBirth,
        gender: _selectedGender,
        phoneNumber: (formattedPhone != null && formattedPhone.isNotEmpty) ? formattedPhone : null,
        village: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        relationshipToHead: _selectedRelationshipToHead,
        healthStatus: _selectedHealthStatuses.isNotEmpty ? _selectedHealthStatuses.first : 'Normal/Healthy',
        isPregnant: isPregnant,
        hasChronicCondition: hasChronicCondition,
        chronicConditions: _selectedChronicConditions.isNotEmpty ? _selectedChronicConditions.join(', ') : null,
        isHighRisk: isHighRisk,
        photoPath: _photoFile?.path ?? widget.patient.photoPath,
      );

      final success = await patientProvider.updatePatient(updatedPatient);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(patientProvider.errorMessage ?? 'Failed to update patient'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating patient: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Patient'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updatePatient,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Section
                    _buildPhotoSection(),
                    const SizedBox(height: 24),

                    // Basic Information Section
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),

                    // Health Status Section
                    _buildSectionHeader('Health Status'),
                    const SizedBox(height: 16),
                    _buildHealthStatusSection(),
                    const SizedBox(height: 24),

                    // Location Section
                    _buildSectionHeader('Location'),
                    const SizedBox(height: 16),
                    _buildLocationSection(),
                    const SizedBox(height: 24),

                    // Notes Section
                    _buildSectionHeader('Notes'),
                    const SizedBox(height: 16),
                    _buildNotesSection(),
                    const SizedBox(height: 32),

                    // Save Button
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _updatePatient,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: GestureDetector(
        onTap: _showImageOptions,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: _photoFile != null
                  ? FileImage(_photoFile!)
                  : (widget.patient.photoPath != null
                      ? FileImage(File(widget.patient.photoPath!))
                      : null),
              child: (_photoFile == null && widget.patient.photoPath == null)
                  ? Icon(
                      _selectedGender == 'male' ? Icons.man : Icons.woman,
                      size: 50,
                      color: AppColors.primary,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        // Full Name
        CustomTextField(
          controller: _nameController,
          label: 'Full Name *',
          prefixIcon: Icons.person,
          inputFormatters: [_CapitalizeTextFormatter()],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter patient name';
            }
            if (value.trim().split(' ').length < 2) {
              return 'Please enter first and last name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Date of Birth
        InkWell(
          onTap: _selectDateOfBirth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth *',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateOfBirth(),
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDateOfBirth != null
                              ? Colors.black87
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Gender
        TypeableDropdownField(
          label: 'Gender *',
          initialValue: _selectedGender,
          options: _genderOptions,
          prefixIcon: Icons.wc,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedGender = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),

        // Phone Number
        PhoneNumberField(
          controller: _phoneController,
          label: 'Phone Number',
        ),
        const SizedBox(height: 16),

        // Relationship to Head
        TypeableDropdownField(
          label: 'Relationship to Household Head',
          initialValue: _selectedRelationshipToHead,
          options: _relationshipOptions,
          prefixIcon: Icons.family_restroom,
          onChanged: (value) {
            setState(() {
              _selectedRelationshipToHead = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHealthStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Multi-select health status
        _buildHealthStatusMultiSelect(),
        const SizedBox(height: 16),

        // Chronic Conditions
        if (_selectedHealthStatuses.contains('Chronic Condition')) ...[
          _buildChipInputField(
            label: 'Chronic Conditions',
            selectedItems: _selectedChronicConditions,
            suggestedItems: _commonChronicConditions,
            controller: _chronicConditionsController,
            onChanged: (items) {
              setState(() {
                _selectedChronicConditions = items;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildHealthStatusMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _possibleHealthStatuses.map((status) {
            final isSelected = _selectedHealthStatuses.contains(status);
            return FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    // If selecting Normal/Healthy, clear other statuses
                    if (status == 'Normal/Healthy') {
                      _selectedHealthStatuses = ['Normal/Healthy'];
                    } else {
                      // Remove Normal/Healthy if selecting another status
                      _selectedHealthStatuses.remove('Normal/Healthy');
                      _selectedHealthStatuses.add(status);
                    }
                  } else {
                    _selectedHealthStatuses.remove(status);
                    // If no statuses selected, default to Normal/Healthy
                    if (_selectedHealthStatuses.isEmpty) {
                      _selectedHealthStatuses = ['Normal/Healthy'];
                    }
                  }
                });
              },
              selectedColor: _getStatusColor(status).withValues(alpha: 0.3),
              checkmarkColor: _getStatusColor(status),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Normal/Healthy':
        return Colors.green;
      case 'Pregnant':
        return Colors.purple;
      case 'Chronic Condition':
        return Colors.orange;
      case 'High Risk Patient':
        return Colors.red;
      case 'Disabled':
        return Colors.blue;
      case 'Malnourished':
        return Colors.amber;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildChipInputField({
    required String label,
    required List<String> selectedItems,
    required List<String> suggestedItems,
    required TextEditingController controller,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected chips
              if (selectedItems.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedItems.map((item) {
                    return Chip(
                      label: Text(item),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        final updated = List<String>.from(selectedItems);
                        updated.remove(item);
                        onChanged(updated);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              // Input field
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type to add...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    final updated = List<String>.from(selectedItems);
                    if (!updated.contains(value.trim())) {
                      updated.add(value.trim());
                      onChanged(updated);
                    }
                    controller.clear();
                  }
                },
              ),
              // Suggested items
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestedItems
                    .where((item) => !selectedItems.contains(item))
                    .take(5)
                    .map((item) {
                  return ActionChip(
                    label: Text(item, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      final updated = List<String>.from(selectedItems);
                      if (!updated.contains(item)) {
                        updated.add(item);
                        onChanged(updated);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _villageController,
          label: 'Village/Community',
          prefixIcon: Icons.location_city,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _locationController,
          label: 'Detailed Location/Address',
          prefixIcon: Icons.location_on,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return CustomTextField(
      controller: _notesController,
      label: 'Additional Notes',
      prefixIcon: Icons.notes,
      maxLines: 4,
    );
  }
}

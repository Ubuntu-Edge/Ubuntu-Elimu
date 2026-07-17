import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/family_models.dart';
import '../../models/patient.dart';
import '../../providers/auth_provider.dart';
import '../../services/family_api_service.dart';
import '../../services/patient_api_service.dart';
import '../../services/database_service.dart';
import '../../services/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Family Registration Screen
/// Allows CHWs to register new families/households with full details
/// Supports offline-first functionality with backend sync
class FamilyRegistrationScreen extends StatefulWidget {
  const FamilyRegistrationScreen({super.key});

  @override
  State<FamilyRegistrationScreen> createState() =>
      _FamilyRegistrationScreenState();
}

class _FamilyRegistrationScreenState extends State<FamilyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingPatients = false;

  // Controllers
  final _familyNameController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  final _householdSizeController = TextEditingController();
  final _nhifNumberController = TextEditingController();
  final _notesController = TextEditingController();

  // Dropdown values
  String? _selectedHousingType;
  String? _selectedWaterSource;
  String? _selectedSanitationType;
  bool _hasElectricity = false;
  bool _hasNhif = false;

  // Head of household selection
  String? _selectedHeadOfHouseholdId;
  List<Patient> _availablePatients = [];

  // Dropdown options
  static const List<String> _housingTypes = [
    'Permanent',
    'Semi-Permanent',
    'Temporary',
    'Traditional',
    'Other',
  ];

  static const List<String> _waterSources = [
    'Piped Water',
    'Borehole',
    'Well (Protected)',
    'Well (Unprotected)',
    'Spring',
    'River/Stream',
    'Rainwater',
    'Water Vendor',
    'Other',
  ];

  static const List<String> _sanitationTypes = [
    'Flush Toilet',
    'VIP Latrine',
    'Pit Latrine',
    'Composting Toilet',
    'No Facility',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailablePatients();
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _householdSizeController.dispose();
    _nhifNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Load available patients for head of household selection
  /// Fetches from server when online, falls back to local database
  Future<void> _loadAvailablePatients() async {
    setState(() => _isLoadingPatients = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final chwId = authProvider.currentCHW?.id;

      if (chwId != null) {
        List<Patient> patients = [];

        // Try to fetch from server when online
        if (ConnectivityService.instance.isOnline) {
          try {
            final response =
                await PatientApiService.instance.listPatients(perPage: 100);
            // Convert API response to Patient model and update local DB
            for (final serverPatient in response.data) {
              final dbMap = serverPatient.toDbMap();
              dbMap['chw_id'] = chwId;
              dbMap['is_synced'] = 1;
              await DatabaseService.instance.upsertPatient(dbMap);
            }
            debugPrint(
                '✅ Synced ${response.data.length} patients for dropdown');
          } catch (e) {
            debugPrint('⚠️ Failed to fetch patients from server: $e');
          }
        }

        // Load from local database
        patients = await DatabaseService.instance.getPatientsByCHW(chwId);
        setState(() {
          _availablePatients = patients;
        });
      }
    } catch (e) {
      debugPrint('Error loading patients: $e');
    } finally {
      setState(() => _isLoadingPatients = false);
    }
  }

  /// Handle family registration
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = FamilyCreateRequest(
        familyName: _familyNameController.text.trim(),
        village: _villageController.text.trim().isEmpty
            ? null
            : _villageController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        headOfHouseholdId: _selectedHeadOfHouseholdId,
        householdSize: _householdSizeController.text.isNotEmpty
            ? int.tryParse(_householdSizeController.text)
            : null,
        housingType: _selectedHousingType,
        waterSource: _selectedWaterSource,
        sanitationType: _selectedSanitationType,
        hasElectricity: _hasElectricity,
        hasNhif: _hasNhif,
        nhifNumber: _hasNhif && _nhifNumberController.text.trim().isNotEmpty
            ? _nhifNumberController.text.trim()
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final isOnline = ConnectivityService.instance.isOnline;

      if (isOnline) {
        // Create on server
        final response = await FamilyApiService.instance.createFamily(request);

        // Save to local database
        await DatabaseService.instance.createFamily(response.toDbMap());

        if (mounted) {
          _showSuccessDialog(response.familyName);
        }
      } else {
        // Offline mode: Save locally with pending sync flag
        final localId = DateTime.now().millisecondsSinceEpoch.toString();
        final familyMap = {
          'id': localId,
          'family_name': request.familyName,
          'head_of_household_id': request.headOfHouseholdId,
          'village': request.village,
          'address': request.address,
          'location': request.location,
          'household_size': request.householdSize,
          'housing_type': request.housingType,
          'water_source': request.waterSource,
          'sanitation_type': request.sanitationType,
          'has_electricity': request.hasElectricity == true ? 1 : 0,
          'has_nhif': request.hasNhif == true ? 1 : 0,
          'nhif_number': request.nhifNumber,
          'notes': request.notes,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'registered_date': DateTime.now().toIso8601String(),
          'is_synced': 0,
          'pending_sync': 1,
        };

        await DatabaseService.instance.createFamily(familyMap);

        if (mounted) {
          _showSuccessDialog(request.familyName, isOffline: true);
        }
      }
    } on FamilyApiException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to register family: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String familyName, {bool isOffline = false}) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isOffline ? Icons.cloud_off : Icons.check_circle,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            Text(l10n.translate('success') ?? 'Success'),
          ],
        ),
        content: Text(
          isOffline
              ? '$familyName has been registered locally and will sync when online.'
              : '$familyName has been registered successfully!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .pop(true); // Return to previous screen with success
            },
            child: Text(l10n.translate('ok') ?? 'OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 8),
            Text(l10n.translate('error') ?? 'Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('ok') ?? 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.translate('registerFamily') ?? 'Register Family'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Basic Information
              _buildSectionHeader(
                l10n.translate('basicInformation') ?? 'Basic Information',
                FontAwesomeIcons.house,
              ),
              _buildCard([
                _buildTextField(
                  controller: _familyNameController,
                  label: l10n.translate('familyName') ?? 'Family Name',
                  hint: 'e.g., Ogembo Family',
                  icon: FontAwesomeIcons.users,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.translate('familyNameRequired') ??
                          'Family name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _villageController,
                  label: l10n.translate('village') ?? 'Village',
                  hint: 'e.g., Kibera',
                  icon: FontAwesomeIcons.locationDot,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: l10n.translate('address') ?? 'Address',
                  hint: 'e.g., 123 Main Street',
                  icon: FontAwesomeIcons.mapLocationDot,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: l10n.translate('location') ?? 'Location Description',
                  hint: 'e.g., Near the market',
                  icon: FontAwesomeIcons.mapPin,
                ),
              ]),

              const SizedBox(height: 24),

              // Section: Head of Household
              _buildSectionHeader(
                l10n.translate('headOfHousehold') ??
                    'Head of Household (Optional)',
                FontAwesomeIcons.userTie,
              ),
              _buildCard([
                _buildPatientDropdown(),
              ]),

              const SizedBox(height: 24),

              // Section: Household Details
              _buildSectionHeader(
                l10n.translate('householdDetails') ?? 'Household Details',
                FontAwesomeIcons.peopleGroup,
              ),
              _buildCard([
                _buildTextField(
                  controller: _householdSizeController,
                  label: l10n.translate('householdSize') ?? 'Household Size',
                  hint: 'Number of family members',
                  icon: FontAwesomeIcons.peopleRoof,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: l10n.translate('housingType') ?? 'Housing Type',
                  value: _selectedHousingType,
                  items: _housingTypes,
                  icon: FontAwesomeIcons.houseChimney,
                  onChanged: (value) =>
                      setState(() => _selectedHousingType = value),
                ),
              ]),

              const SizedBox(height: 24),

              // Section: Water & Sanitation
              _buildSectionHeader(
                l10n.translate('waterAndSanitation') ?? 'Water & Sanitation',
                FontAwesomeIcons.droplet,
              ),
              _buildCard([
                _buildDropdown(
                  label: l10n.translate('waterSource') ?? 'Water Source',
                  value: _selectedWaterSource,
                  items: _waterSources,
                  icon: FontAwesomeIcons.faucetDrip,
                  onChanged: (value) =>
                      setState(() => _selectedWaterSource = value),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: l10n.translate('sanitationType') ?? 'Sanitation Type',
                  value: _selectedSanitationType,
                  items: _sanitationTypes,
                  icon: FontAwesomeIcons.toiletPaper,
                  onChanged: (value) =>
                      setState(() => _selectedSanitationType = value),
                ),
              ]),

              const SizedBox(height: 24),

              // Section: Utilities & Insurance
              _buildSectionHeader(
                l10n.translate('utilitiesAndInsurance') ??
                    'Utilities & Insurance',
                FontAwesomeIcons.bolt,
              ),
              _buildCard([
                _buildSwitchTile(
                  title: l10n.translate('hasElectricity') ?? 'Has Electricity',
                  value: _hasElectricity,
                  icon: FontAwesomeIcons.lightbulb,
                  onChanged: (value) => setState(() => _hasElectricity = value),
                ),
                const Divider(),
                _buildSwitchTile(
                  title: l10n.translate('hasNhif') ?? 'Has NHIF Insurance',
                  value: _hasNhif,
                  icon: FontAwesomeIcons.shieldHeart,
                  onChanged: (value) => setState(() => _hasNhif = value),
                ),
                if (_hasNhif) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nhifNumberController,
                    label: l10n.translate('nhifNumber') ?? 'NHIF Number',
                    hint: 'e.g., NHIF123456',
                    icon: FontAwesomeIcons.idCard,
                  ),
                ],
              ]),

              const SizedBox(height: 24),

              // Section: Notes
              _buildSectionHeader(
                l10n.translate('additionalNotes') ?? 'Additional Notes',
                FontAwesomeIcons.noteSticky,
              ),
              _buildCard([
                _buildTextField(
                  controller: _notesController,
                  label: l10n.translate('notes') ?? 'Notes',
                  hint: 'Any additional information about the family',
                  icon: FontAwesomeIcons.penToSquare,
                  maxLines: 3,
                ),
              ]),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.userPlus, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              l10n.translate('registerFamily') ??
                                  'Register Family',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          FaIcon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: FaIcon(icon, size: 18, color: AppColors.textSecondary),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: FaIcon(icon, size: 18, color: AppColors.textSecondary),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPatientDropdown() {
    final l10n = AppLocalizations.of(context);

    if (_isLoadingPatients) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedHeadOfHouseholdId,
      decoration: InputDecoration(
        labelText: l10n.translate('selectHeadOfHousehold') ??
            'Select Head of Household',
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: FaIcon(FontAwesomeIcons.userTie,
              size: 18, color: AppColors.textSecondary),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      hint: Text(
        _availablePatients.isEmpty
            ? (l10n.translate('noPatientsAvailable') ?? 'No patients available')
            : (l10n.translate('selectPatient') ?? 'Select a patient'),
        style: TextStyle(color: AppColors.textSecondary),
      ),
      items: _availablePatients.map((patient) {
        return DropdownMenuItem<String>(
          value: patient.id,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${patient.firstName} ${patient.lastName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (patient.phoneNumber != null)
                Text(
                  patient.phoneNumber!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedHeadOfHouseholdId = value),
      isExpanded: true,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required IconData icon,
    required void Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Row(
        children: [
          FaIcon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}

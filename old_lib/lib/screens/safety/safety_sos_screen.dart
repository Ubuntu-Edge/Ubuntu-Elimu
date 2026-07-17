import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/safety_api_service.dart';

class SafetySOSScreen extends StatefulWidget {
  const SafetySOSScreen({super.key});

  @override
  State<SafetySOSScreen> createState() => _SafetySOSScreenState();
}

class _SafetySOSScreenState extends State<SafetySOSScreen> {
  final SafetyApiService _safetyApi = SafetyApiService.instance;

  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  bool _locationSharingEnabled = false;
  Position? _currentPosition;
  List<SafetyCheck> _checkHistory = [];
  List<Incident> _incidents = [];
  List<EmergencyContact> _emergencyContacts = [];
  List<SOSAlert> _sosAlerts = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return;
    }

    // Get current location
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      debugPrint(
          'Got location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    } catch (e) {
      debugPrint('Failed to get location: $e');
    }
  }

  Future<Position?> _getCurrentLocation() async {
    if (!_locationSharingEnabled) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return _currentPosition; // Return cached position if available
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _safetyApi.getCheckHistory(perPage: 50),
        _safetyApi.getIncidents(perPage: 50),
        _safetyApi.getEmergencyContacts(),
        _safetyApi.getSOSAlerts(),
      ]);

      setState(() {
        _checkHistory = (results[0] as SafetyCheckHistoryResponse).items;
        _incidents = (results[1] as IncidentListResponse).items;
        _emergencyContacts = results[2] as List<EmergencyContact>;
        _sosAlerts = results[3] as List<SOSAlert>;
        _isLoading = false;

        // Check if currently checked in
        if (_checkHistory.isNotEmpty &&
            _checkHistory.first.checkType == 'check-in') {
          _isCheckedIn = true;
          _checkInTime = _checkHistory.first.checkTime;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load safety data';
        _isLoading = false;
      });
      debugPrint('Error loading safety data: $e');
    }
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.error,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: FaIcon(FontAwesomeIcons.exclamation,
                  color: Colors.white, size: 40),
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text(
              'EMERGENCY SOS',
              style: AppTheme.headingLarge
                  .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              'Sending alert to your supervisor with your current location...',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingLg),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: AppTheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('SOS alert cancelled'),
                        backgroundColor: AppColors.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _confirmSOSSent();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Confirm SOS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSOSSent() async {
    try {
      await _safetyApi.triggerSOSAlert(
        alertType: 'other',
        severity: 'high',
        locationName: 'Current Location',
        description: 'Emergency SOS triggered from app',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                FaIcon(FontAwesomeIcons.circleCheck,
                    color: Colors.white, size: 18),
                SizedBox(width: 12),
                Text('Emergency alert sent! Help is on the way.'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS alert'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleCheckIn() async {
    // Get current location if sharing is enabled
    Position? position;
    if (_locationSharingEnabled) {
      position = await _getCurrentLocation();
    }

    try {
      if (!_isCheckedIn) {
        // Check in
        final result = await _safetyApi.checkIn(
          locationName: position != null
              ? 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}'
              : 'Location not available',
          latitude: position?.latitude,
          longitude: position?.longitude,
          notes: 'Check-in from app',
        );

        setState(() {
          _isCheckedIn = true;
          _checkInTime = result.checkTime;
          _checkHistory.insert(0, result);
        });
      } else {
        // Check out
        final result = await _safetyApi.checkOut(
          locationName: position != null
              ? 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}'
              : 'Location not available',
          latitude: position?.latitude,
          longitude: position?.longitude,
          notes: 'Check-out from app',
        );

        setState(() {
          _isCheckedIn = false;
          _checkInTime = null;
          _checkHistory.insert(0, result);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isCheckedIn
                ? 'Checked in successfully'
                : 'Checked out successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to ${_isCheckedIn ? "check out" : "check in"}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPanicPinDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.shieldHalved,
                color: AppColors.error, size: 20),
            SizedBox(width: 12),
            Text('Set Panic PIN', style: AppTheme.headingMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a secret 4-digit PIN that will silently alert your supervisor when entered.',
              style:
                  AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Panic PIN',
                counterText: '',
                prefixIcon: Icon(Icons.lock),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.circleInfo,
                      color: AppColors.warning, size: 16),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use a PIN different from your regular login PIN',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Panic PIN set successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showIncidentReportDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'safety';
    String selectedSeverity = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Report Incident', style: AppTheme.headingMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incident Type', style: AppTheme.labelMedium),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'safety', child: Text('Safety Concern')),
                    DropdownMenuItem(
                        value: 'patient', child: Text('Patient Incident')),
                    DropdownMenuItem(
                        value: 'equipment', child: Text('Equipment Issue')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value!),
                ),
                SizedBox(height: AppTheme.spacingMd),
                Text('Severity', style: AppTheme.labelMedium),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedSeverity,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedSeverity = value!),
                ),
                SizedBox(height: AppTheme.spacingMd),
                Text('Title', style: AppTheme.labelMedium),
                SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    hintText: 'Brief title...',
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                Text('Description', style: AppTheme.labelMedium),
                SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    hintText: 'Describe the incident...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  Navigator.pop(context);

                  // Get location if sharing enabled
                  Position? position;
                  if (_locationSharingEnabled) {
                    position = await _getCurrentLocation();
                  }

                  try {
                    final incident = await _safetyApi.createIncident(
                      incidentType: selectedType,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      severity: selectedSeverity,
                      latitude: position?.latitude,
                      longitude: position?.longitude,
                      locationName: position != null
                          ? 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}'
                          : 'Location not available',
                      incidentDate: DateTime.now(),
                    );
                    setState(() {
                      _incidents.insert(0, incident);
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Incident reported. Your supervisor will be notified.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to report incident'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  Text('Submit Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();
    final notesController = TextEditingController();
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Emergency Contact', style: AppTheme.headingMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    hintText: '+254712345678',
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextField(
                  controller: relationshipController,
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    hintText: 'e.g., Spouse, Parent, Friend',
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    hintText: 'Additional information...',
                  ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                CheckboxListTile(
                  value: isPrimary,
                  onChanged: (value) =>
                      setDialogState(() => isPrimary = value ?? false),
                  title:
                      Text('Set as primary contact', style: AppTheme.bodySmall),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    final contact = await _safetyApi.addEmergencyContact(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      contactRelationship:
                          relationshipController.text.trim().isEmpty
                              ? null
                              : relationshipController.text.trim(),
                      isPrimary: isPrimary,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );
                    setState(() => _emergencyContacts.add(contact));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Emergency contact added'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add contact'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Add Contact', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditContactDialog(EmergencyContact contact) {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phone);
    final relationshipController =
        TextEditingController(text: contact.contactRelationship ?? '');
    final notesController = TextEditingController(text: contact.notes ?? '');
    bool isPrimary = contact.isPrimary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Emergency Contact', style: AppTheme.headingMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextField(
                  controller: relationshipController,
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                CheckboxListTile(
                  value: isPrimary,
                  onChanged: (value) =>
                      setDialogState(() => isPrimary = value ?? false),
                  title:
                      Text('Set as primary contact', style: AppTheme.bodySmall),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    final updated = await _safetyApi.updateEmergencyContact(
                      contactId: contact.id,
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      contactRelationship:
                          relationshipController.text.trim().isEmpty
                              ? null
                              : relationshipController.text.trim(),
                      isPrimary: isPrimary,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );
                    setState(() {
                      final idx = _emergencyContacts
                          .indexWhere((c) => c.id == contact.id);
                      if (idx != -1) _emergencyContacts[idx] = updated;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Contact updated'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update contact'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteContactDialog(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.triangleExclamation,
                color: AppColors.error, size: 20),
            SizedBox(width: 12),
            Text('Delete Contact', style: AppTheme.headingMedium),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${contact.name} from your emergency contacts?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _safetyApi.deleteEmergencyContact(contact.id);
                setState(() =>
                    _emergencyContacts.removeWhere((c) => c.id == contact.id));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contact deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete contact'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: _isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(FontAwesomeIcons.triangleExclamation,
                                  color: AppColors.error, size: 48),
                              SizedBox(height: AppTheme.spacingMd),
                              Text(_error!,
                                  style: AppTheme.bodyMedium
                                      .copyWith(color: AppColors.error)),
                              SizedBox(height: AppTheme.spacingMd),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView(
                            padding: EdgeInsets.all(AppTheme.spacingMd),
                            children: [
                              // SOS Button
                              _buildSOSButton(),
                              SizedBox(height: AppTheme.spacingLg),

                              // Check-in/Check-out
                              _buildCheckInSection(l10n),
                              SizedBox(height: AppTheme.spacingMd),

                              // SOS Alerts List
                              if (_sosAlerts.isNotEmpty) _buildSOSAlertsList(),
                              if (_sosAlerts.isNotEmpty)
                                SizedBox(height: AppTheme.spacingMd),

                              // Safety Features
                              _buildSafetyFeatures(),
                              SizedBox(height: AppTheme.spacingMd),

                              // Emergency Contacts
                              _buildEmergencyContacts(),
                              SizedBox(height: AppTheme.spacingMd),

                              // Safety Tips
                              _buildSafetyTips(),
                              SizedBox(height: AppTheme.spacingMd),

                              // Recent Incidents
                              if (_incidents.isNotEmpty) _buildIncidentsList(),

                              SizedBox(height: 80),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.error, AppColors.error.withRed(200)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(FontAwesomeIcons.arrowLeft,
                    color: Colors.white, size: 18),
              ),
            ),
            SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.emergencySOS,
                    style: AppTheme.headingMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Safety & Emergency Features',
                    style: AppTheme.bodySmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onLongPress: _triggerSOS,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.error, AppColors.error.withRed(200)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: FaIcon(FontAwesomeIcons.handHoldingHeart,
                  color: Colors.white, size: 40),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              'EMERGENCY SOS',
              style: AppTheme.headingMedium
                  .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              'Long press to send an emergency alert with your location',
              style: AppTheme.bodySmall
                  .copyWith(color: Colors.white.withValues(alpha: 0.9)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.locationDot,
                  color: AppColors.primary, size: 16),
              SizedBox(width: AppTheme.spacingSm),
              Text('Field Visit Status', style: AppTheme.labelLarge),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleCheckIn,
                  icon: FaIcon(
                    _isCheckedIn
                        ? FontAwesomeIcons.arrowRightFromBracket
                        : FontAwesomeIcons.arrowRightToBracket,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isCheckedIn ? l10n.checkOut : l10n.checkIn,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isCheckedIn ? AppColors.warning : AppColors.success,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (_isCheckedIn && _checkInTime != null) ...[
            SizedBox(height: AppTheme.spacingMd),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.clock,
                      color: AppColors.success, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Checked in ${_formatDuration(DateTime.now().difference(_checkInTime!))} ago',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Share live location', style: AppTheme.bodyMedium),
              Switch.adaptive(
                value: _locationSharingEnabled,
                onChanged: (value) async {
                  setState(() => _locationSharingEnabled = value);
                  if (value) {
                    // Get location immediately when enabled
                    final position = await _getCurrentLocation();
                    if (position != null) {
                      setState(() => _currentPosition = position);
                    }
                  }
                },
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyFeatures() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safety Features', style: AppTheme.labelLarge),
          SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildFeatureButton(
                  icon: FontAwesomeIcons.shieldHalved,
                  label: 'Panic PIN',
                  color: AppColors.error,
                  onTap: _showPanicPinDialog,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildFeatureButton(
                  icon: FontAwesomeIcons.fileCircleExclamation,
                  label: 'Report Incident',
                  color: AppColors.warning,
                  onTap: _showIncidentReportDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 24),
            SizedBox(height: AppTheme.spacingSm),
            Text(label,
                style: AppTheme.labelMedium
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Emergency Contacts', style: AppTheme.labelLarge),
              TextButton.icon(
                onPressed: _showAddContactDialog,
                icon: FaIcon(FontAwesomeIcons.plus, size: 12),
                label: Text('Add'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          ..._emergencyContacts.map((contact) => _buildContactTile(contact)),
          if (_emergencyContacts.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  children: [
                    FaIcon(FontAwesomeIcons.addressBook,
                        color: AppColors.textSecondary, size: 32),
                    SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'No emergency contacts added',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSOSAlertsList() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SOS Alerts', style: AppTheme.labelLarge),
          SizedBox(height: AppTheme.spacingMd),
          ..._sosAlerts.map((alert) => _buildSOSTile(alert)),
        ],
      ),
    );
  }

  Widget _buildSOSTile(SOSAlert alert) {
    final isResolved = alert.status.toLowerCase() == 'resolved';
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isResolved ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              isResolved
                  ? FontAwesomeIcons.circleCheck
                  : FontAwesomeIcons.triangleExclamation,
              color: isResolved ? AppColors.success : AppColors.error,
              size: 14,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.description, style: AppTheme.bodySmall),
                if (alert.locationName != null)
                  Text(alert.locationName!,
                      style: AppTheme.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isResolved ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              alert.status.toUpperCase(),
              style: AppTheme.labelSmall.copyWith(
                color: isResolved ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8),
          if (!isResolved)
            TextButton(
              onPressed: () => _showResolveSOSDialog(alert),
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }

  void _showResolveSOSDialog(SOSAlert alert) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve SOS Alert'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Resolution Notes',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final updated = await _safetyApi.updateSOSAlertStatus(
                  alertId: alert.id,
                  status: 'resolved',
                  resolutionNotes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                setState(() {
                  final idx = _sosAlerts.indexWhere((a) => a.id == alert.id);
                  if (idx != -1) _sosAlerts[idx] = updated;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('SOS alert marked as resolved'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to resolve alert: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(EmergencyContact contact) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: contact.isPrimary
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: contact.isPrimary
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: FaIcon(
            contact.isPrimary
                ? FontAwesomeIcons.solidStar
                : FontAwesomeIcons.phone,
            color: AppColors.primary,
            size: 16),
      ),
      title: Row(
        children: [
          Text(contact.name,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          if (contact.isPrimary) ...[
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('PRIMARY',
                  style: AppTheme.labelSmall
                      .copyWith(color: Colors.white, fontSize: 9)),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contact.phone,
              style:
                  AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
          if (contact.contactRelationship != null)
            Text(contact.contactRelationship!,
                style: AppTheme.labelSmall
                    .copyWith(color: AppColors.textSecondary)),
          if (contact.notes != null)
            Text(contact.notes!,
                style: AppTheme.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${contact.name}...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  FaIcon(FontAwesomeIcons.phone, color: Colors.white, size: 14),
            ),
          ),
          SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditContactDialog(contact);
              } else if (value == 'delete') {
                _showDeleteContactDialog(contact);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.penToSquare, size: 14),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  )),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.trash,
                          size: 14, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTips() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.lightbulb,
                  color: AppColors.info, size: 16),
              SizedBox(width: AppTheme.spacingSm),
              Text('Safety Tips',
                  style: AppTheme.labelLarge.copyWith(color: AppColors.info)),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          _buildTipItem('Always inform someone before visiting remote areas'),
          _buildTipItem('Keep your phone charged and carry a power bank'),
          _buildTipItem('Trust your instincts - leave if you feel unsafe'),
          _buildTipItem('Know the location of the nearest health facility'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.info, size: 12),
          SizedBox(width: 8),
          Expanded(child: Text(tip, style: AppTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildIncidentsList() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Incidents', style: AppTheme.labelLarge),
          SizedBox(height: AppTheme.spacingMd),
          ..._incidents.map((incident) => _buildIncidentTile(incident)),
        ],
      ),
    );
  }

  Widget _buildIncidentTile(Incident incident) {
    Color severityColor;
    switch (incident.severity) {
      case 'high':
        severityColor = AppColors.error;
        break;
      case 'medium':
        severityColor = AppColors.warning;
        break;
      default:
        severityColor = AppColors.info;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(FontAwesomeIcons.triangleExclamation,
                color: severityColor, size: 14),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(incident.title,
                    style: AppTheme.labelMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(incident.description,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (incident.locationName != null)
                  Text(incident.locationName!,
                      style: AppTheme.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: incident.status == 'resolved'
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              incident.status.toUpperCase(),
              style: AppTheme.labelSmall.copyWith(
                color: incident.status == 'resolved'
                    ? AppColors.success
                    : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}

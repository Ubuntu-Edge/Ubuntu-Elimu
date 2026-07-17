import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/patient_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/patient.dart';
import '../../models/visit.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../followups/schedule_visit_screen.dart';
import '../patient_visit_history_screen.dart'; // Import the new visit history screen
import '../ai/ai_streaming_screen.dart'; // Import the AI streaming chat screen
import '../../services/ai_service.dart';
import '../referrals/create_referral_screen.dart';
import 'patient_edit_screen.dart'; // Import the patient edit screen
import '../../utils/phone_formatter.dart'; // Import phone formatter

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Patient? _patient;
  List<Visit> _visits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Force refresh from server if online to get latest data
    final chwId = authProvider.currentCHW?.id;
    if (chwId != null) {
      await patientProvider.loadPatients(chwId);
    }
    
    final patient = await patientProvider.getPatient(widget.patientId);
    // We are no longer directly showing the full visit history on this screen,
    // but we still need to load it if the _buildVisitHistorySection() needs it for count or summary.
    // For now, keeping this call, but if performance is an issue, it can be lazy-loaded in the history screen.
    final visits = await patientProvider.getPatientVisits(widget.patientId);

    if (!mounted) return;

    setState(() {
      _patient = patient;
      _visits = visits;
      _isLoading = false;
    });
  }

  Future<void> _handleEdit() async {
    if (_patient == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientEditScreen(patient: _patient!),
      ),
    );
    
    if (result == true && mounted) {
      _loadPatientData(); // Refresh after edit
    }
  }

  Future<void> _handleDelete() async {
    final ctx = context;
    if (_patient == null) return;

    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => _buildProfessionalDeleteDialog(dialogCtx, _patient!),
    );

    if (confirmed != true || !ctx.mounted) return;

    final patientProvider = Provider.of<PatientProvider>(ctx, listen: false);
    final success = await patientProvider.deletePatient(widget.patientId);

    if (!ctx.mounted) return;

    if (success) {
      // Navigate back first
      Navigator.pop(ctx);
      
      // Show success message after navigation
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Patient deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(patientProvider.errorMessage ?? 'Failed to delete patient'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfessionalDeleteDialog(BuildContext dialogCtx, Patient patient) {
    final expectedText = '${patient.firstName} ${patient.lastName}'.toLowerCase().trim();
    
    return _ProfessionalDeleteDialog(
      patient: patient,
      expectedText: expectedText,
      buildDeleteDialogRow: _buildDeleteDialogRow,
      buildWarningChip: _buildWarningChip,
      buildDeleteItem: _buildDeleteItem,
    );
  }

  Widget _buildDeleteDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.close, size: 16, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text('Patient Details', style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        ),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_patient == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text('Patient Details', style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        ),
        body: Center(
          child: Text('Patient not found', style: AppTheme.bodyMedium),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(_patient!.displayId, style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _handleDelete();
              } else if (value == 'edit') {
                _handleEdit();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Edit Patient', style: AppTheme.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('Delete Patient', style: AppTheme.bodyMedium.copyWith(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPatientData,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            // AI Assistant Card
            _buildAIAssistantCard(),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Demographics',
              Icons.person,
              Colors.blue,
              [
                _buildInfoRow('Full Name', '${_patient!.firstName} ${_patient!.lastName}'),
                _buildInfoRow('Age', _patient!.ageDisplay),
                if (_patient!.dateOfBirth != null)
                  _buildInfoRow('Date of Birth', DateFormat('MMM dd, yyyy').format(_patient!.dateOfBirth!)),
                _buildInfoRow('Gender', _patient!.gender?.toUpperCase() ?? 'N/A'),
                if (_patient!.relationshipToHead != null)
                  _buildInfoRow('Relationship to Head', _patient!.relationshipToHead!),
                _buildInfoRow(
                  'Registered',
                  DateFormat('MMM dd, yyyy').format(_patient!.registeredDate),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_patient!.phoneNumber != null || _patient!.alternativePhone != null)
              _buildInfoCard(
                'Contact Information',
                Icons.phone,
                Colors.teal,
                [
                  if (_patient!.phoneNumber != null)
                    _buildInfoRow(
                      'Phone Number', 
                      PhoneFormatter.getDisplayFormat(_patient!.phoneNumber) ?? _patient!.phoneNumber!
                    ),
                  if (_patient!.alternativePhone != null)
                    _buildInfoRow(
                      'Alternative Phone',
                      PhoneFormatter.getDisplayFormat(_patient!.alternativePhone) ?? _patient!.alternativePhone!
                    ),
                  if (_patient!.address != null)
                    _buildInfoRow('Address', _patient!.address!),
                ],
              ),
            if (_patient!.phoneNumber != null || _patient!.alternativePhone != null)
              const SizedBox(height: 16),
            if (_patient!.village != null || _patient!.location != null)
              _buildInfoCard(
                'Location',
                Icons.location_on,
                Colors.green,
                [
                  if (_patient!.village != null)
                    _buildInfoRow('Village', _patient!.village!),
                  if (_patient!.location != null)
                    _buildInfoRow('Specific Location', _patient!.location!),
                ],
              ),
            if (_patient!.village != null || _patient!.location != null)
              const SizedBox(height: 16),
            _buildHealthStatusCard(),
            const SizedBox(height: 16),
            
            // Medical Information Card
            if (_patient!.bloodType != null ||
                _patient!.allergies != null ||
                _patient!.currentMedications != null)
              _buildInfoCard(
                'Medical Information',
                Icons.medical_services,
                Colors.red,
                [
                  if (_patient!.bloodType != null)
                    _buildInfoRow('Blood Type', _patient!.bloodType!),
                  if (_patient!.allergies != null)
                    _buildInfoRow('Allergies', _patient!.allergies!),
                  if (_patient!.currentMedications != null)
                    _buildInfoRow('Current Medications', _patient!.currentMedications!),
                ],
              ),
            if (_patient!.bloodType != null ||
                _patient!.allergies != null ||
                _patient!.currentMedications != null)
              const SizedBox(height: 16),
            
            // Next of Kin Information
            if (_patient!.nextOfKinName != null ||
                _patient!.nextOfKinPhone != null ||
                _patient!.nextOfKinRelationship != null)
              _buildInfoCard(
                'Emergency Contact',
                Icons.contact_emergency,
                Colors.orange,
                [
                  if (_patient!.nextOfKinName != null)
                    _buildInfoRow('Name', _patient!.nextOfKinName!),
                  if (_patient!.nextOfKinRelationship != null)
                    _buildInfoRow('Relationship', _patient!.nextOfKinRelationship!),
                  if (_patient!.nextOfKinPhone != null)
                    _buildInfoRow(
                      'Phone Number',
                      PhoneFormatter.getDisplayFormat(_patient!.nextOfKinPhone) ?? _patient!.nextOfKinPhone!
                    ),
                ],
              ),
            if (_patient!.nextOfKinName != null ||
                _patient!.nextOfKinPhone != null ||
                _patient!.nextOfKinRelationship != null)
              const SizedBox(height: 16),
            
            // Additional Information
            if (_patient!.maritalStatus != null || _patient!.nationalId != null)
              _buildInfoCard(
                'Additional Information',
                Icons.info,
                Colors.purple,
                [
                  if (_patient!.maritalStatus != null)
                    _buildInfoRow('Marital Status', _patient!.maritalStatus!),
                  if (_patient!.nationalId != null)
                    _buildInfoRow('National ID', _patient!.nationalId!),
                ],
              ),
            if (_patient!.maritalStatus != null || _patient!.nationalId != null)
              const SizedBox(height: 16),
            
            if (_patient!.notes != null)
              _buildInfoCard(
                'Notes',
                Icons.note,
                Colors.purple,
                [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _patient!.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            if (_patient!.notes != null)
              const SizedBox(height: 16),
            
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            
            // New: View Visit History Action Card
            _buildActionCard(
              'View Visit History',
              _visits.isEmpty 
                  ? 'No visits recorded yet'
                  : 'See all ${_visits.length} past visits and notes for this patient',
              Icons.history,
              Colors.teal,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PatientVisitHistoryScreen(patient: _patient!),
                  ),
                ).then(
                    (_) => _loadPatientData()); // Refresh data when returning
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'Refer Patient',
              'Refer this patient to a health facility',
              Icons.local_shipping,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateReferralScreen(patient: _patient!),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // The _buildVisitHistorySection() is removed or commented out if no longer needed directly here.
            // If it was providing a summary count, consider moving that into the action card itself.
            // For now, I will remove it to avoid confusion and redundant display.
            // _buildVisitHistorySection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_patient == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Patient data not loaded yet. Please wait.', style: AppTheme.bodyMedium),
                backgroundColor: AppColors.warning,
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleVisitScreen(patient: _patient!),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Visit', style: AppTheme.labelMedium.copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            if (_patient!.photoPath != null &&
                File(_patient!.photoPath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.file(
                  File(_patient!.photoPath!),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              )
            else
              CircleAvatar(
                radius: 60,
                backgroundColor: _getAvatarColor(),
                child: Icon(
                  _getAvatarIcon(),
                  size: 60,
                  color: Colors.white,
                ),
              ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              _patient!.displayId,
              style: AppTheme.headingLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              alignment: WrapAlignment.center,
              children: [
                if (_patient!.isPregnant ?? false)
                  _buildStatusBadge('Pregnant', AppColors.secondary, Icons.pregnant_woman),
                if (_patient!.isHighRisk)
                  _buildStatusBadge('High Risk', AppColors.error, Icons.warning),
                if (_patient!.hasChronicCondition ?? false)
                  _buildStatusBadge('Chronic', AppColors.warning, Icons.local_hospital),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssistantCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowMd,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIStreamingScreen(patient: _patient!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Triage Assistant',
                          style: AppTheme.headingSmall.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AIService.instance.isLoaded
                              ? AIService.instance.getModelInfo()
                              : 'Get diagnosis assistance for this patient',
                          style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final scaffold = ScaffoldMessenger.of(context);
                      scaffold.showSnackBar(SnackBar(
                        content: Text('Loading MedGemma model...', style: AppTheme.bodyMedium),
                        backgroundColor: AppColors.info,
                      ));
                      try {
                        await AIService.instance.loadModel();
                        scaffold.hideCurrentSnackBar();
                        scaffold.showSnackBar(SnackBar(
                          content: Text('Model loaded successfully', style: AppTheme.bodyMedium),
                          backgroundColor: AppColors.success,
                        ));
                        setState(() {});
                      } catch (e) {
                        scaffold.hideCurrentSnackBar();
                        scaffold.showSnackBar(SnackBar(
                          content: Text('Failed to load model: ${e.toString()}', style: AppTheme.bodyMedium),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: Text('Load Model', style: AppTheme.labelMedium),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AIStreamingScreen(patient: _patient!),
                        ),
                      );
                    },
                    child: Text('Open Chat', style: AppTheme.labelMedium.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(
                        (255 * 0.1).round()), // Corrected opacity usage
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(
                        (255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.favorite, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Health Status & Medical Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Health Status
            if (_patient!.healthStatus != null)
              _buildInfoRow('Status', _patient!.healthStatus!),
            
            // Pregnancy Information
            if (_patient!.isPregnant ?? false) ...[
              _buildStatusRow('Pregnant', true, Colors.pink),
              if (_patient!.pregnancyWeek != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4),
                  child: Text(
                    'Week ${_patient!.pregnancyWeek}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            
            // Chronic Conditions
            if (_patient!.hasChronicCondition ?? false) ...[
              _buildStatusRow('Chronic Condition', true, Colors.orange),
              if (_patient!.chronicConditions != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4),
                  child: Text(
                    _patient!.chronicConditions!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            
            // High Risk Status
            if (_patient!.isHighRisk) ...[
              _buildStatusRow('High Risk Patient', true, Colors.red),
              if (_patient!.riskScore != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4),
                  child: Text(
                    'Risk Score: ${_patient!.riskScore}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            
            if (!(_patient!.isPregnant ?? false) &&
                !(_patient!.hasChronicCondition ?? false) &&
                !_patient!.isHighRisk)
              Text(
                'No special health concerns reported',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // TODO: May be needed later
  // Widget _buildRecentVisitsSummary() {
  //   // Show the 3 most recent visits
  //   final recentVisits = _visits.take(3).toList();
  //   
  // //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.05),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'Recent Visits',
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.grey[800],
  //               ),
  //             ),
  //             Text(
  //               '${_visits.length} total',
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 color: Colors.grey[600],
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         ...recentVisits.map((visit) => Padding(
  //           padding: const EdgeInsets.only(bottom: 8),
  //           child: Row(
  //             children: [
  //               Icon(Icons.circle, size: 8, color: AppColors.primary),
  //               const SizedBox(width: 8),
  //               Expanded(
  //                 child: Text(
  //                   '${DateFormat('MMM dd, yyyy').format(visit.visitDate)}${visit.chiefComplaint != null ? ' - ${visit.chiefComplaint}' : ''}',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     color: Colors.grey[700],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         )).toList(),
  //       ],
  //     ),
  //   );
  // }

  // REMOVED _buildVisitHistorySection() from here, as it's now accessed via a button.

  // TODO: May be needed later
  // Widget _buildVisitCard(Visit visit) {
  //   Color urgencyColor;
  //   IconData urgencyIcon;
  //
  //   switch (visit.urgencyLevel) {
  //     case 'emergency':
  //       urgencyColor = Colors.red;
  //       urgencyIcon = Icons.emergency;
  //       break;
  //     case 'high':
  //       urgencyColor = Colors.orange;
  //       urgencyIcon = Icons.priority_high;
  //       break;
  //     case 'moderate':
  //       urgencyColor = Colors.yellow;
  //       urgencyIcon = Icons.warning_amber;
  //       break;
  //     default:
  //       urgencyColor = Colors.green;
  //       urgencyIcon = Icons.check_circle;
  //   }
  //
  //   return Card(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: InkWell(
  //       onTap: () => _showVisitDetails(context, visit),
  //       borderRadius: BorderRadius.circular(12),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Row(
  //                   children: [
  //                     Icon(Icons.calendar_today,
  //                         size: 16, color: Colors.grey[600]),
  //                     const SizedBox(width: 8),
  //                     Text(
  //                       DateFormat('MMM dd, yyyy').format(visit.visitDate),
  //                       style: const TextStyle(
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: urgencyColor.withAlpha(
  //                         (255 * 0.1).round()), // Corrected opacity usage
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Icon(urgencyIcon, size: 14, color: urgencyColor),
  //                       const SizedBox(width: 4),
  //                       Text(
  //                         visit.urgencyLevel.toUpperCase(),
  //                         style: TextStyle(
  //                           fontSize: 11,
  //                           fontWeight: FontWeight.bold,
  //                           color: urgencyColor,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 12),
  //             if (visit.chiefComplaint !=
  //                 null) // Check for null before displaying
  //               Text(
  //                 visit.chiefComplaint!,
  //                 style: const TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             if (visit.diagnosis != null) ...[
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   Icon(Icons.medical_services,
  //                       size: 16, color: Colors.grey[600]),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       'Diagnosis: ${visit.diagnosis}',
  //                       style: TextStyle(
  //                         fontSize: 13,
  //                         color: Colors.grey[700],
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //             if (visit.wasReferred) ...[
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   const Icon(Icons.local_hospital,
  //                       size: 16, color: Colors.blue),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     'Referred to: ${visit.referralLocation ?? "Hospital"}',
  //                     style: const TextStyle(
  //                       fontSize: 13,
  //                       color: Colors.blue,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //             if (visit.followUpDate != null && !visit.followUpCompleted) ...[
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   Icon(Icons.event, size: 16, color: Colors.orange[700]),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     'Follow-up due: ${DateFormat('MMM dd').format(visit.followUpDate!)}',
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       color: Colors.orange[700],
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // TODO: May be needed later
  /*
  Future<void> _showVisitDetails(BuildContext context, Visit visit) async {
    final ctx = context;

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomCtx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (scrollCtx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Visit Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMMM dd, yyyy - hh:mm a').format(visit.visitDate),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (visit.chiefComplaint !=
                null) // Check for null before displaying
              _buildDetailRow(
                  'Chief Complaint', visit.chiefComplaint!, Icons.report),
            if (visit.symptoms != null)
              _buildDetailRow('Symptoms', visit.symptoms!, Icons.description),
            if (visit.diagnosis != null)
              _buildDetailRow(
                  'Diagnosis', visit.diagnosis!, Icons.medical_services),
            if (visit.treatment != null)
              _buildDetailRow(
                  'Treatment Given', visit.treatment!, Icons.healing),
            _buildDetailRow(
              'Urgency Level',
              visit.urgencyLevel.toUpperCase(),
              Icons.priority_high,
            ),
            if (visit.wasReferred)
              _buildDetailRow(
                'Referral Location',
                visit.referralLocation ?? 'Hospital',
                Icons.local_hospital,
              ),
            if (visit.outcome != null)
              _buildDetailRow('Outcome', visit.outcome!, Icons.check_circle),
            if (visit.followUpDate != null)
              _buildDetailRow(
                'Follow-up Date',
                DateFormat('MMM dd, yyyy').format(visit.followUpDate!),
                Icons.event,
              ),
            if (visit.notes != null)
              _buildDetailRow('Notes', visit.notes!, Icons.note),
            const SizedBox(height: 24),
            if (visit.followUpDate != null && !visit.followUpCompleted)
              ElevatedButton.icon(
                onPressed: () async {
                  final confirmCtx = bottomCtx;
                  final confirmed = await showDialog<bool>(
                    context: confirmCtx,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Mark as Completed'),
                      content: const Text('Mark this follow-up as completed?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text('Complete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true || !confirmCtx.mounted) return;

                  final patientProvider =
                      Provider.of<PatientProvider>(confirmCtx, listen: false);
                  await patientProvider.updateVisit(
                    visit.copyWith(followUpCompleted: true),
                  );

                  if (!confirmCtx.mounted) return;

                  Navigator.pop(confirmCtx);
                  _loadPatientData();
                  ScaffoldMessenger.of(confirmCtx).showSnackBar(
                    const SnackBar(
                      content: Text('Follow-up marked as completed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Mark Follow-up Complete'),
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
          ],
        ),
      ),
    );
  }
  */

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isActive ? Icons.check_circle : Icons.cancel,
              size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()), // Corrected opacity usage
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Re-creating _buildActionCard from HomeScreen for consistency within PatientDetailScreen
  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // TODO: May be needed later
  // Widget _buildDetailRow(String label, String value, IconData icon) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(icon, size: 18, color: Colors.grey[600]),
  //             const SizedBox(width: 8),
  //             Text(
  //               label,
  //               style: TextStyle(
  //                 fontSize: 12,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.grey[600],
  //                 letterSpacing: 0.5,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 6),
  //         Text(
  //           value,
  //           style: const TextStyle(fontSize: 15, height: 1.4),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Color _getAvatarColor() {
    if ((_patient?.isPregnant ?? false)) return AppColors.secondary;
    if (_patient?.isHighRisk ?? false) return AppColors.error;
    if ((_patient?.hasChronicCondition ?? false)) return AppColors.warning;
    return _patient?.gender == 'male' ? AppColors.info : AppColors.primary;
  }

  IconData _getAvatarIcon() {
    if (_patient?.isPregnant ?? false) return Icons.pregnant_woman;
    if ((_patient?.age ?? 0) < 18) {
      return Icons.child_care;
    }
    return _patient?.gender == 'male' ? Icons.man : Icons.woman;
  }
}

/// Professional delete dialog with proper state management
class _ProfessionalDeleteDialog extends StatefulWidget {
  final Patient patient;
  final String expectedText;
  final Widget Function(String, String) buildDeleteDialogRow;
  final Widget Function(String, IconData, Color) buildWarningChip;
  final Widget Function(String) buildDeleteItem;

  const _ProfessionalDeleteDialog({
    required this.patient,
    required this.expectedText,
    required this.buildDeleteDialogRow,
    required this.buildWarningChip,
    required this.buildDeleteItem,
  });

  @override
  State<_ProfessionalDeleteDialog> createState() => _ProfessionalDeleteDialogState();
}

class _ProfessionalDeleteDialogState extends State<_ProfessionalDeleteDialog> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    final inputText = _controller.text.toLowerCase().trim();
    final isValid = inputText == widget.expectedText;
    if (isValid != _isValid) {
      setState(() => _isValid = isValid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Patient Deletion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Patient Summary
            Text(
              'Patient Details:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            widget.buildDeleteDialogRow('Name', '${patient.firstName} ${patient.lastName}'),
            widget.buildDeleteDialogRow('Gender', patient.gender ?? 'N/A'),
            if (patient.dateOfBirth != null)
              widget.buildDeleteDialogRow(
                'Age',
                '${patient.age} years old',
              ),
            if (patient.village != null)
              widget.buildDeleteDialogRow('Village', patient.village!),
            const SizedBox(height: 12),
            
            // Health Status Badges
            if (patient.isPregnant == true ||
                patient.isHighRisk == true ||
                patient.hasChronicCondition == true) ...[
              Text(
                'Health Status:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (patient.isPregnant == true)
                    widget.buildWarningChip('Pregnant', Icons.pregnant_woman, Colors.purple),
                  if (patient.isHighRisk == true)
                    widget.buildWarningChip('High Risk', Icons.warning, Colors.red),
                  if (patient.hasChronicCondition == true)
                    widget.buildWarningChip('Chronic Condition', Icons.medical_services, Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            const Divider(),
            const SizedBox(height: 12),
            
            // Warning message
            Text(
              'This will permanently delete:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            widget.buildDeleteItem('All patient records and personal information'),
            widget.buildDeleteItem('Visit history and medical records'),
            widget.buildDeleteItem('Associated consultations and referrals'),
            widget.buildDeleteItem('Follow-up schedules and reminders'),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Confirmation input
            Text(
              'To confirm, type the patient\'s full name:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${patient.firstName} ${patient.lastName}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type full name to confirm',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[600],
          ),
          child: const Text(
            'Delete Patient',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

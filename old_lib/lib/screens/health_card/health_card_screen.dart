import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../models/patient_health_card.dart';
import '../../services/health_card_service.dart';
import '../../services/health_card_api_service.dart' as api;

class HealthCardScreen extends StatefulWidget {
  const HealthCardScreen({super.key});

  @override
  State<HealthCardScreen> createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends State<HealthCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthCardService _localHealthCardService = HealthCardService();
  final api.HealthCardApiService _apiService =
      api.HealthCardApiService.instance;

  // Backend data
  List<api.HealthCard> _apiHealthCards = [];
  // TODO: May be needed later for vaccination display
  // List<api.VaccinationRecord> _apiVaccinations = [];
  // TODO: May be needed later for print queue management
  // List<api.PrintQueueEntry> _printQueue = [];
  // TODO: May be needed later for stats display
  // api.HealthCardStats? _stats;
  // Loading states
  // ignore: unused_field
  bool _isLoadingCards = false;
  // TODO: May be needed later for loading states
  // bool _isLoadingVaccinations = false;
  final bool _useBackend = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBackendData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendData() async {
    if (!_useBackend) return;

    await Future.wait([
      _loadHealthCards(),
      _loadPrintQueue(),
      _loadStats(),
    ]);
  }

  Future<void> _loadHealthCards() async {
    setState(() => _isLoadingCards = true);
    try {
      final result = await _apiService.listCards();
      setState(() {
        _apiHealthCards = result.items;
        _isLoadingCards = false;
      });
    } catch (e) {
      setState(() => _isLoadingCards = false);
      debugPrint('Backend unavailable for health cards: $e');
    }
  }

  // TODO: May be needed later for patient vaccination display
  // Future<void> _loadVaccinations(String patientId) async {
  //   setState(() => _isLoadingVaccinations = true);
  //   try {
  //     final result = await _apiService.getPatientVaccinations(patientId);
  //     setState(() {
  //       _apiVaccinations = result.items;
  //       _isLoadingVaccinations = false;
  //     });
  //   } catch (e) {
  //     setState(() => _isLoadingVaccinations = false);
  //     debugPrint('Backend unavailable for vaccinations: $e');
  //   }
  // }

  Future<void> _loadPrintQueue() async {
    try {
      // TODO: Use print queue data when UI is implemented
      await _apiService.getPrintQueue();
    } catch (e) {
      debugPrint('Backend unavailable for print queue: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      // TODO: Use stats data when UI is implemented
      await _apiService.getStats();
    } catch (e) {
      debugPrint('Backend unavailable for stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Health Cards & SMS',
            style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTheme.labelMedium,
          tabs: const [
            Tab(text: 'QR Cards'),
            Tab(text: 'SMS'),
            Tab(text: 'Vaccinations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRCardsTab(),
          _buildSMSTab(),
          _buildVaccinationsTab(),
        ],
      ),
    );
  }

  Widget _buildQRCardsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.qr_code, color: AppColors.info, size: 32),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Health Cards', style: AppTheme.labelMedium),
                    Text(
                      'Generate QR codes containing patient health information for easy access at health facilities.',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Actions
        Text('Quick Actions', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),

        AppWidgets.actionCard(
          title: 'Generate New Card',
          subtitle: 'Create a health card for a patient',
          icon: Icons.add_card,
          iconColor: AppColors.primary,
          onTap: () => _showGenerateCardDialog(),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        AppWidgets.actionCard(
          title: 'Scan QR Code',
          subtitle: 'Read patient information from QR',
          icon: Icons.qr_code_scanner,
          iconColor: AppColors.secondary,
          onTap: () => _showScanDialog(),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        AppWidgets.actionCard(
          title: 'Print Cards',
          subtitle: 'Print health cards for distribution',
          icon: Icons.print,
          iconColor: AppColors.info,
          onTap: () => _printHealthCards(),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Sample Card Preview
        Text('Card Preview', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),
        _buildSampleCardPreview(),
      ],
    );
  }

  Widget _buildSampleCardPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd)),
            ),
            child: Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.white, size: 24),
                const SizedBox(width: AppTheme.spacingSm),
                Text('UbuntuHealth Card',
                    style: AppTheme.headingSmall.copyWith(color: Colors.white)),
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sample Patient', style: AppTheme.labelMedium),
                      const SizedBox(height: AppTheme.spacingXs),
                      _buildCardInfoRow(Icons.cake, 'DOB: 01/01/1990'),
                      _buildCardInfoRow(Icons.person, 'Gender: Female'),
                      _buildCardInfoRow(Icons.location_on, 'Village: Kiambu'),
                      _buildCardInfoRow(Icons.water_drop, 'Blood: A+'),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text('Allergies:',
                          style: AppTheme.labelSmall
                              .copyWith(color: AppColors.error)),
                      Text('Penicillin', style: AppTheme.bodySmall),
                    ],
                  ),
                ),

                // QR Code placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(Icons.qr_code_2,
                      size: 64, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Card Footer
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusMd)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ID: PAT-001234',
                    style: AppTheme.labelSmall
                        .copyWith(color: AppColors.textSecondary)),
                Text('Valid until: 12/2025',
                    style: AppTheme.labelSmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSMSTab() {
    final templates = _localHealthCardService.getTemplates();
    final pendingReminders = _localHealthCardService.getPendingReminders();
    final dueReminders = _localHealthCardService.getDueReminders();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Due Today
        if (dueReminders.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active, color: AppColors.warning),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text('${dueReminders.length} SMS Due Today',
                        style: AppTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                ElevatedButton(
                  onPressed: () => _sendDueReminders(dueReminders),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Send All',
                      style:
                          AppTheme.labelMedium.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],

        // Quick Send
        Text('Quick Send', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),

        AppWidgets.actionCard(
          title: 'Send SMS Reminder',
          subtitle: 'Send a reminder to a patient',
          icon: Icons.sms,
          iconColor: AppColors.primary,
          onTap: () => _showSendSMSDialog(),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Templates
        Text('SMS Templates', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),
        ...templates.map((t) => _buildTemplateCard(t)),
        const SizedBox(height: AppTheme.spacingMd),

        // Pending Reminders
        if (pendingReminders.isNotEmpty) ...[
          Text('Scheduled Reminders', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingSm),
          ...pendingReminders.take(5).map((r) => _buildReminderCard(r)),
        ],
      ],
    );
  }

  Widget _buildTemplateCard(SMSTemplate template) {
    IconData icon;
    Color color;
    switch (template.type) {
      case SMSReminderType.appointment:
        icon = Icons.calendar_today;
        color = AppColors.primary;
        break;
      case SMSReminderType.medication:
        icon = Icons.medication;
        color = AppColors.info;
        break;
      case SMSReminderType.vaccination:
        icon = Icons.vaccines;
        color = AppColors.success;
        break;
      case SMSReminderType.followUp:
        icon = Icons.replay;
        color = AppColors.warning;
        break;
      case SMSReminderType.antenatal:
        icon = Icons.pregnant_woman;
        color = AppColors.secondary;
        break;
      case SMSReminderType.outbreakAlert:
        icon = Icons.warning_amber;
        color = AppColors.error;
        break;
      case SMSReminderType.general:
        icon = Icons.message;
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(template.name, style: AppTheme.labelMedium),
        subtitle: Text(
          template.messageTemplate,
          style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(Icons.send, color: AppColors.primary),
          onPressed: () => _showSendFromTemplateDialog(template),
        ),
      ),
    );
  }

  Widget _buildReminderCard(SMSReminder reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(Icons.schedule, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.patientPhone, style: AppTheme.labelMedium),
                Text(
                  reminder.message,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Scheduled: ${_formatDate(reminder.scheduledDate)}',
                  style: AppTheme.labelSmall.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {
              // Cancel reminder
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Info
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Icon(Icons.vaccines, color: AppColors.success, size: 32),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vaccination Tracking', style: AppTheme.labelMedium),
                    Text(
                      'Track immunizations and send vaccination reminders to patients.',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Vaccination Schedule Reference
        Text('WHO Vaccination Schedule', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),
        _buildVaccinationSchedule(),
      ],
    );
  }

  Widget _buildVaccinationSchedule() {
    final schedule = [
      {
        'age': 'At birth',
        'vaccines': ['BCG', 'OPV-0', 'Hepatitis B']
      },
      {
        'age': '6 weeks',
        'vaccines': ['OPV-1', 'Pentavalent-1', 'PCV-1', 'Rotavirus-1']
      },
      {
        'age': '10 weeks',
        'vaccines': ['OPV-2', 'Pentavalent-2', 'PCV-2', 'Rotavirus-2']
      },
      {
        'age': '14 weeks',
        'vaccines': ['OPV-3', 'Pentavalent-3', 'PCV-3', 'IPV']
      },
      {
        'age': '9 months',
        'vaccines': ['Measles-1', 'Yellow Fever']
      },
      {
        'age': '15 months',
        'vaccines': ['Measles-2']
      },
    ];

    return Column(
      children: schedule
          .map((item) => Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        item['age'] as String,
                        style: AppTheme.labelSmall
                            .copyWith(color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Wrap(
                        spacing: AppTheme.spacingXs,
                        runSpacing: AppTheme.spacingXs,
                        children: (item['vaccines'] as List<String>)
                            .map((v) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusFull),
                                  ),
                                  child: Text(v, style: AppTheme.labelSmall),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  void _showGenerateCardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text('Generate Health Card', style: AppTheme.headingSmall),
        content: Text('Select a patient to generate their health card.',
            style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (_useBackend) {
                try {
                  // Show loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text('Creating health card...',
                              style: AppTheme.bodyMedium),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  // Create card via API
                  final card = await _apiService.createCard(
                    patientId:
                        'sample_patient_id', // Get from patient selection
                    cardType: api.CardType.standard,
                  );

                  // Generate QR code
                  final qrResult = await _apiService.generateQRCode(
                    patientId: card.patientId,
                  );

                  // Refresh list
                  await _loadHealthCards();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Health card created successfully',
                          style: AppTheme.bodyMedium),
                      backgroundColor: AppColors.success,
                    ),
                  );

                  // Show the generated QR code
                  _showQRCodeDialog(qrResult);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create card: $e',
                          style: AppTheme.bodyMedium),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Navigate to patient list to select',
                        style: AppTheme.bodyMedium),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Select Patient',
                style: AppTheme.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(api.QRCodeResult qrResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text('Health Card QR Code', style: AppTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: qrResult.qrCodeBase64.isNotEmpty
                  ? Image.memory(
                      Uri.parse(
                              'data:image/png;base64,${qrResult.qrCodeBase64}')
                          .data!
                          .contentAsBytes(),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.qr_code_2,
                          size: 120, color: AppColors.textSecondary),
                    )
                  : Icon(Icons.qr_code_2,
                      size: 120, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Card Number: ${qrResult.cardNumber}',
                style: AppTheme.labelSmall),
            Text(
              'Generated: ${_formatDate(qrResult.generatedAt)}',
              style:
                  AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTheme.bodyMedium),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await _apiService.addToPrintQueue(qrResult.patientId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to print queue',
                        style: AppTheme.bodyMedium),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadPrintQueue();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add to print queue',
                        style: AppTheme.bodyMedium),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.print),
            label: Text('Print',
                style: AppTheme.labelMedium.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  void _showScanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text('Scan QR Code', style: AppTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text('Camera preview',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Point camera at QR code', style: AppTheme.bodyMedium),
            if (_useBackend) ...[
              const SizedBox(height: AppTheme.spacingMd),
              OutlinedButton(
                onPressed: () async {
                  // Simulate scanning with a test QR code
                  Navigator.pop(context);
                  try {
                    final result =
                        await _apiService.scanQRCode(qrData: 'test_qr_data');
                    _showScannedPatientInfo(result);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to scan QR code: $e',
                            style: AppTheme.bodyMedium),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: Text('Test Scan', style: AppTheme.labelMedium),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showScannedPatientInfo(api.QRScanResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(Icons.check_circle,
                        color: AppColors.success, size: 32),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QR Code Scanned', style: AppTheme.headingSmall),
                        Text(
                          'Patient information retrieved',
                          style: AppTheme.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  _buildInfoRow('Patient ID', result.patientId ?? 'N/A'),
                  _buildInfoRow('Card Number', result.cardNumber ?? 'N/A'),
                  _buildInfoRow('Name', result.patientName ?? 'N/A'),
                  if (result.dateOfBirth != null)
                    _buildInfoRow(
                        'Date of Birth', _formatDate(result.dateOfBirth!)),
                  _buildInfoRow('Blood Type', result.bloodGroup ?? 'N/A'),
                  if (result.allergies.isNotEmpty)
                    _buildInfoRow('Allergies', result.allergies.join(', ')),
                  if (result.chronicConditions.isNotEmpty)
                    _buildInfoRow(
                        'Conditions', result.chronicConditions.join(', ')),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: result.isValid
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          result.isValid ? Icons.verified : Icons.warning,
                          color: result.isValid
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          result.isValid
                              ? 'Card is valid'
                              : 'Card validation failed',
                          style: AppTheme.labelMedium.copyWith(
                            color: result.isValid
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: Text('Close',
                      style:
                          AppTheme.labelMedium.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTheme.labelSmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _showSendSMSDialog() {
    final phoneController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text('Send SMS', style: AppTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: AppTheme.labelMedium,
                prefixIcon: Icon(Icons.phone, color: AppColors.primary),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: AppTheme.labelMedium,
                prefixIcon: Icon(Icons.message, color: AppColors.primary),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('SMS sent successfully', style: AppTheme.bodyMedium),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Send',
                style: AppTheme.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSendFromTemplateDialog(SMSTemplate template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template: ${template.name}', style: AppTheme.bodyMedium),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _sendDueReminders(List<SMSReminder> reminders) async {
    if (_useBackend) {
      // Send via backend API
      for (var reminder in reminders) {
        try {
          await _apiService.sendCardViaSMS(
            patientId: reminder.patientId,
            phoneNumber: reminder.patientPhone,
            messageType: api.SMSMessageType.reminder,
          );
        } catch (e) {
          debugPrint('Failed to send SMS via backend: $e');
        }
      }
    }

    // Mark as sent locally
    for (var reminder in reminders) {
      _localHealthCardService.markReminderSent(reminder.id);
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${reminders.length} SMS sent', style: AppTheme.bodyMedium),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _printHealthCards() async {
    // Show dialog to select cards to print
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.print, color: AppColors.info),
            SizedBox(width: 8),
            Text('Print Health Cards', style: AppTheme.headingSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select cards to print:', style: AppTheme.bodyMedium),
            SizedBox(height: AppTheme.spacingMd),
            ListTile(
              leading: Icon(Icons.person, color: AppColors.primary),
              title: Text('Print Sample Card'),
              subtitle: Text('Preview the card format'),
              onTap: () {
                Navigator.pop(context);
                _printSampleCard();
              },
            ),
            if (_apiHealthCards.isNotEmpty)
              ListTile(
                leading: Icon(Icons.people, color: AppColors.secondary),
                title: Text('Print All Cards (${_apiHealthCards.length})'),
                subtitle: Text('Print all patient cards'),
                onTap: () {
                  Navigator.pop(context);
                  _printAllCards();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _printSampleCard() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (context) => _buildPdfCard(
          patientName: 'Sample Patient',
          dateOfBirth: '01/01/1990',
          gender: 'Female',
          village: 'Kiambu',
          bloodType: 'A+',
          allergies: 'Penicillin',
          cardId: 'SAMPLE-001',
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'UbuntuHealth_Sample_Card',
    );
  }

  Future<void> _printAllCards() async {
    final pdf = pw.Document();

    for (var card in _apiHealthCards) {
      // Use card data available from the API model
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6,
          build: (context) => _buildPdfCard(
            patientName: 'Patient ${card.patientId.substring(0, 8)}',
            dateOfBirth: _formatDate(card.validFrom),
            gender: 'N/A',
            village: 'N/A',
            bloodType: 'N/A',
            allergies: card.includeAllergies ? 'See record' : 'None recorded',
            cardId: card.cardNumber,
          ),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'UbuntuHealth_Cards_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  pw.Widget _buildPdfCard({
    required String patientName,
    required String dateOfBirth,
    required String gender,
    required String village,
    required String bloodType,
    required String allergies,
    required String cardId,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal, width: 2),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Container(
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Icon(pw.IconData(0xe25d), color: PdfColors.white, size: 20),
                pw.SizedBox(width: 8),
                pw.Text(
                  'UbuntuHealth Card',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Patient Info
          pw.Text(
            patientName,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),

          _buildPdfInfoRow('DOB', dateOfBirth),
          _buildPdfInfoRow('Gender', gender),
          _buildPdfInfoRow('Village', village),
          _buildPdfInfoRow('Blood Type', bloodType),

          pw.SizedBox(height: 8),
          pw.Text(
            'Allergies: $allergies',
            style: pw.TextStyle(
              color: PdfColors.red,
              fontSize: 10,
            ),
          ),

          pw.Spacer(),

          // Footer with Card ID
          pw.Container(
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Card ID: $cardId',
                  style: pw.TextStyle(fontSize: 8),
                ),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: cardId,
                  width: 40,
                  height: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

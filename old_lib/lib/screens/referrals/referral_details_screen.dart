import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/referral.dart';
import '../../providers/referral_provider.dart';
import '../../providers/followup_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/reminder_dialog.dart';
import '../../models/reminder_models.dart';

class ReferralDetailsScreen extends StatefulWidget {
  final Referral referral;

  const ReferralDetailsScreen({super.key, required this.referral});

  @override
  State<ReferralDetailsScreen> createState() => _ReferralDetailsScreenState();
}

class _ReferralDetailsScreenState extends State<ReferralDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _outcome;
  late DateTime _outcomeDate;

  @override
  void initState() {
    super.initState();
    _outcome = widget.referral.outcome ?? '';
    _outcomeDate = widget.referral.outcomeDate ?? DateTime.now();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final updatedReferral = Referral(
        id: widget.referral.id,
        patientId: widget.referral.patientId,
        chwId: widget.referral.chwId,
        referralDate: widget.referral.referralDate,
        referralReason: widget.referral.referralReason,
        referredTo: widget.referral.referredTo,
        outcome: _outcome,
        outcomeDate: _outcomeDate,
      );
      await context.read<ReferralProvider>().updateReferral(updatedReferral);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _createReminder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final followupProvider = Provider.of<FollowupProvider>(context, listen: false);
    final chwId = authProvider.currentCHW?.id ?? '';

    final result = await showDialog<ReminderCreateRequest>(
      context: context,
      builder: (context) => ReminderDialog(
        patientId: widget.referral.patientId,
        chwId: chwId,
        referralId: widget.referral.id,
      ),
    );

    if (result != null && mounted) {
      final success = await followupProvider.createReminderFromRequest(result, chwId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Reminder created!' : 'Failed to create reminder'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_add),
            tooltip: 'Create Reminder',
            onPressed: _createReminder,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Referral Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referral Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('Patient ID', widget.referral.patientId),
                      _buildInfoRow('Referred on', DateFormat('MMM dd, yyyy').format(widget.referral.referralDate)),
                      _buildInfoRow('Reason', widget.referral.referralReason),
                      _buildInfoRow('Referred to', widget.referral.referredTo),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Outcome Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outcome',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _outcome,
                        decoration: const InputDecoration(
                          labelText: 'Outcome',
                          border: OutlineInputBorder(),
                          hintText: 'Enter referral outcome',
                        ),
                        maxLines: 3,
                        onSaved: (value) => _outcome = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save),
                        label: const Text('Update Outcome'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Quick Actions Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _createReminder,
                        icon: const Icon(Icons.notification_add),
                        label: const Text('Create Follow-up Reminder'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/patient.dart';
import '../../models/referral.dart';
import '../../providers/auth_provider.dart';
import '../../providers/referral_provider.dart';
import '../../widgets/custom_text_field.dart'; // Import CustomTextField
import '../../widgets/custom_button.dart';   // Import CustomButton

class CreateReferralScreen extends StatefulWidget {
  final Patient patient;

  const CreateReferralScreen({super.key, required this.patient});

  @override
  State<CreateReferralScreen> createState() => _CreateReferralScreenState();
}

class _CreateReferralScreenState extends State<CreateReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _referredToController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _referredToController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return; // Validate form first

    _formKey.currentState!.save(); // Save form fields

    final authProvider = context.read<AuthProvider>();
    final chwId = authProvider.currentCHW?.id; // Safely get chwId

    if (chwId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CHW ID not available. Cannot create referral.')),
      );
      return; // Stop if chwId is null
    }

    final newReferral = Referral(
      id: const Uuid().v4(),
      patientId: widget.patient.id,
      chwId: chwId,
      referralDate: DateTime.now(),
      referralReason: _reasonController.text.trim(),
      referredTo: _referredToController.text.trim(),
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    await context.read<ReferralProvider>().addReferral(newReferral);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer Patient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0), // Increased padding
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Patient Name Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.teal.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Patient: ${widget.patient.displayId}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Spacing after patient name

              // Reason for Referral
              CustomTextField(
                controller: _reasonController,
                label: 'Reason for Referral',
                hint: 'e.g., Severe fever, Injury, Chronic condition exacerbation',
                prefixIcon: Icons.assignment,
                validator: (value) => value!.trim().isEmpty ? 'Please enter a reason for referral' : null,
              ),
              const SizedBox(height: 16), // Spacing between fields

              // Referred to (Facility)
              CustomTextField(
                controller: _referredToController,
                label: 'Referred to (Facility)',
                hint: 'e.g., District Hospital, Kenyatta National Hospital',
                prefixIcon: Icons.local_hospital,
                validator: (value) => value!.trim().isEmpty ? 'Please enter the facility to refer to' : null,
              ),
              const SizedBox(height: 16), // Spacing between fields

              // Notes (Optional)
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Any additional relevant information',
                prefixIcon: Icons.note_alt,
                maxLines: 3,
              ),
              const SizedBox(height: 32), // Spacing before button

              // Create Referral Button
              CustomButton(
                text: 'Create Referral',
                onPressed: _submit,
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

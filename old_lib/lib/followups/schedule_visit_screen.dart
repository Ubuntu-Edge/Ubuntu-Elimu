import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../providers/auth_provider.dart';
import '../../providers/followup_provider.dart';
import '../../models/patient.dart';
import '../../models/scheduled_visit.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ScheduleVisitScreen extends StatefulWidget {
  final Patient patient;

  const ScheduleVisitScreen({super.key, required this.patient});

  @override
  State<ScheduleVisitScreen> createState() => _ScheduleVisitScreenState();
}

class _ScheduleVisitScreenState extends State<ScheduleVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026, 12, 31),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleVisit() async {
    final ctx = context; // Capture context before async operations

    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields (Purpose, Date, Time)')),
        );
      }
      return;
    }

    final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
    final followupProvider = Provider.of<FollowupProvider>(ctx, listen: false);

    final chwId = authProvider.currentCHW?.id; // Safely get chwId
    if (chwId == null) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('CHW ID not available. Cannot schedule visit.')),
        );
      }
      return;
    }

    final visitDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final scheduledVisit = ScheduledVisit(
      id: const Uuid().v4(), // Generate unique ID
      patientId: widget.patient.id,
      chwId: chwId,
      scheduledDate: visitDateTime,
      purpose: _purposeController.text.trim(),
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    // Loading state handled internally by provider

    try {
      final success = await followupProvider.createScheduledVisit(scheduledVisit);
      if (success && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Visit scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(ctx);
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule visit: ${followupProvider.errorMessage ?? e}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // Loading state is managed internally by the provider
  }

  @override
  Widget build(BuildContext context) {
    final followupProvider = Provider.of<FollowupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Visit for ${widget.patient.displayId}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Visit Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Purpose',
                  hint: 'Enter purpose of visit',
                  controller: _purposeController,
                  prefixIcon: Icons.description,
                  validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Purpose is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                                : 'Select date',
                            style: TextStyle(
                                color: _selectedDate != null ? Colors.black : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Time',
                            prefixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _selectedTime != null
                                ? _selectedTime!.format(context)
                                : 'Select time',
                            style: TextStyle(
                                color: _selectedTime != null ? Colors.black : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Notes (Optional)',
                  hint: 'Additional notes...',
                  controller: _notesController,
                  maxLines: 4,
                  prefixIcon: Icons.note,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Schedule Visit',
                  onPressed: followupProvider.isLoading ? null : _scheduleVisit,
                  isLoading: followupProvider.isLoading,
                  icon: Icons.calendar_month,
                ),
                const SizedBox(height: 10),
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
  }
}
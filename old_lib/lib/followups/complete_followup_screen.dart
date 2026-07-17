import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../models/patient.dart';
import '../services/database_helper.dart';
import '../models/visit.dart';
import '../models/visit_note.dart';
import '../models/scheduled_visit.dart';
import '../providers/followup_provider.dart';
import '../widgets/reminder_dialog.dart';
import '../models/reminder_models.dart';

class CompleteFollowupScreen extends StatefulWidget {
  final Patient patient;
  final ScheduledVisit? pendingVisit;

  const CompleteFollowupScreen({
    super.key,
    required this.patient,
    this.pendingVisit,
  });

  @override
  State<CompleteFollowupScreen> createState() => _CompleteFollowupScreenState();
}

class _CompleteFollowupScreenState extends State<CompleteFollowupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  bool _isCompleted = false;
  DateTime? _nextFollowUpDate;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _createdVisitId;

  @override
  void initState() {
    super.initState();
    if (widget.pendingVisit != null) {
      _notesController.text = widget.pendingVisit!.notes ?? '';
      _isCompleted = widget.pendingVisit!.isCompleted;
      _nextFollowUpDate = widget.pendingVisit!.scheduledDate;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextFollowUpDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _nextFollowUpDate = picked);
    }
  }

  Future<void> _createReminder() async {
    if (_createdVisitId == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final followupProvider = Provider.of<FollowupProvider>(context, listen: false);
    final chwId = authProvider.currentCHW?.id ?? '';

    final result = await showDialog<ReminderCreateRequest>(
      context: context,
      builder: (context) => ReminderDialog(
        patientId: widget.patient.id,
        chwId: chwId,
        visitId: _createdVisitId,
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final followupProvider = Provider.of<FollowupProvider>(context, listen: false);
      
      String visitId;

      if (widget.pendingVisit != null) {
        final updatedScheduledVisit = widget.pendingVisit!.copyWith(
          isCompleted: _isCompleted,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          completedAt: _isCompleted ? DateTime.now() : null,
          scheduledDate: _nextFollowUpDate ?? widget.pendingVisit!.scheduledDate,
        );

        final success = await followupProvider.updateScheduledVisit(updatedScheduledVisit);

        if (success) {
          visitId = const Uuid().v4();
          _createdVisitId = visitId;
          
          final newVisit = Visit(
            id: visitId,
            patientId: widget.patient.id,
            visitDate: _isCompleted ? DateTime.now() : updatedScheduledVisit.scheduledDate,
            chwId: authProvider.currentCHW!.id,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
            followUpDate: _nextFollowUpDate,
            followUpCompleted: _isCompleted,
          );

          await _dbHelper.insertVisit(newVisit);

          if (_notesController.text.isNotEmpty) {
            final visitNote = VisitNote(
              visitId: visitId,
              timestamp: DateTime.now(),
              content: _notesController.text,
            );
            await _dbHelper.insertVisitNote(visitNote);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Follow-up updated and visit recorded!')),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update follow-up: ${followupProvider.errorMessage}')),
            );
          }
        }
      } else {
        visitId = const Uuid().v4();
        _createdVisitId = visitId;
        
        final newVisit = Visit(
          id: visitId,
          patientId: widget.patient.id,
          visitDate: DateTime.now(),
          chwId: authProvider.currentCHW!.id,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          followUpDate: _nextFollowUpDate,
          followUpCompleted: _isCompleted,
        );

        await _dbHelper.insertVisit(newVisit);

        if (_notesController.text.isNotEmpty) {
          final visitNote = VisitNote(
            visitId: visitId,
            timestamp: DateTime.now(),
            content: _notesController.text,
          );
          await _dbHelper.insertVisitNote(visitNote);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New follow-up created and notes saved!')),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: Text('Follow-up – ${patient.displayId}'),
        actions: [
          if (_createdVisitId != null)
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
              Text(
                'Patient ID: ${patient.displayId}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('Gender: ${patient.gender}'),
              Text('Age: ${patient.ageDisplay}'),
              if (patient.village != null)
                Text('Village: ${patient.village}'),
              const SizedBox(height: 20),

              SwitchListTile(
                title: const Text('Mark follow-up as completed'),
                value: _isCompleted,
                onChanged: (v) => setState(() => _isCompleted = v),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Follow-up Notes',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter notes before saving.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _nextFollowUpDate == null
                          ? 'No next date selected'
                          : 'Next Follow-up: ${_nextFollowUpDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              if (_createdVisitId != null) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.notification_add),
                  label: const Text('Create Follow-up Reminder'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _createReminder,
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(widget.pendingVisit != null ? 'Update Follow-up' : 'Save Follow-up'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

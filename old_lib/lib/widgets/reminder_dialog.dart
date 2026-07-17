import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../models/reminder_models.dart';

class ReminderDialog extends StatefulWidget {
  final Reminder? reminder; // For editing
  final String patientId;
  final String chwId;
  final String? visitId;
  final String? referralId;

  const ReminderDialog({
    super.key,
    this.reminder,
    required this.patientId,
    required this.chwId,
    this.visitId,
    this.referralId,
  });

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  String _selectedType = 'followup';
  String _selectedPriority = 'medium';
  String _selectedRecurrence = 'none';
  DateTime _reminderDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _notificationTime;
  DateTime? _recurrenceEndDate;

  final List<Map<String, String>> _reminderTypes = [
    {'value': 'followup', 'label': 'Follow-up'},
    {'value': 'medication', 'label': 'Medication'},
    {'value': 'vaccination', 'label': 'Vaccination'},
    {'value': 'appointment', 'label': 'Appointment'},
    {'value': 'antenatal', 'label': 'Antenatal'},
    {'value': 'postnatal', 'label': 'Postnatal'},
    {'value': 'chronic_care', 'label': 'Chronic Care'},
    {'value': 'growth_monitoring', 'label': 'Growth Monitoring'},
    {'value': 'home_visit', 'label': 'Home Visit'},
    {'value': 'general', 'label': 'General'},
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'high', 'label': 'High'},
    {'value': 'medium', 'label': 'Medium'},
    {'value': 'low', 'label': 'Low'},
  ];

  final List<Map<String, String>> _recurrenceOptions = [
    {'value': 'none', 'label': 'None (One-time)'},
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'biweekly', 'label': 'Every 2 Weeks'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'quarterly', 'label': 'Every 3 Months'},
  ];

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(text: widget.reminder?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.reminder?.description ?? '');

    if (widget.reminder != null) {
      _selectedType = widget.reminder!.type;
      _selectedPriority = widget.reminder!.priority ?? 'medium';
      _selectedRecurrence = widget.reminder!.recurrence ?? 'none';
      _reminderDate = widget.reminder!.reminderDate;
      _notificationTime = widget.reminder!.notificationTime;
      _recurrenceEndDate = widget.reminder!.recurrenceEndDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2026, 12, 31),
    );

    if (picked != null && mounted) {
      setState(() {
        _reminderDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_notificationTime ?? _reminderDate),
    );

    if (picked != null && mounted) {
      setState(() {
        final now = DateTime.now();
        _notificationTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectRecurrenceEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ?? _reminderDate.add(const Duration(days: 30)),
      firstDate: _reminderDate,
      lastDate: DateTime(2026, 12, 31),
    );

    if (picked != null && mounted) {
      setState(() {
        _recurrenceEndDate = picked;
      });
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final data = ReminderCreateRequest(
      patientId: widget.patientId,
      type: _selectedType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      reminderDate: _reminderDate.toIso8601String().split('T')[0],
      notificationTime: _notificationTime?.toIso8601String(),
      priority: _selectedPriority,
      recurrence: _selectedRecurrence == 'none' ? null : _selectedRecurrence,
      recurrenceEndDate: _selectedRecurrence != 'none'
          ? _recurrenceEndDate?.toIso8601String().split('T')[0]
          : null,
      visitId: widget.visitId,
      referralId: widget.referralId,
    );

    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reminder != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Reminder' : 'Create Reminder',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Type Selection
                  const Text(
                    'Reminder Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _reminderTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Follow-up for diabetes check',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Additional details about the reminder',
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Date and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reminder Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _selectDate(context),
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(DateFormat('MMM dd, yyyy')
                                  .format(_reminderDate)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notification Time',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _selectTime(context),
                              icon: const Icon(Icons.access_time, size: 18),
                              label: Text(
                                _notificationTime != null
                                    ? DateFormat('h:mm a')
                                        .format(_notificationTime!)
                                    : 'Set Time',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Priority Selection
                  const Text(
                    'Priority',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: _priorities.map((priority) {
                      return ButtonSegment(
                        value: priority['value']!,
                        label: Text(priority['label']!),
                      );
                    }).toList(),
                    selected: {_selectedPriority},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedPriority = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Recurrence Selection
                  const Text(
                    'Recurrence',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRecurrence,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _recurrenceOptions.map((option) {
                      return DropdownMenuItem(
                        value: option['value'],
                        child: Text(option['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRecurrence = value);
                      }
                    },
                  ),

                  // Recurrence End Date (only if recurring)
                  if (_selectedRecurrence != 'none') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Recurrence End Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _selectRecurrenceEndDate(context),
                      icon: const Icon(Icons.event_repeat, size: 18),
                      label: Text(
                        _recurrenceEndDate != null
                            ? DateFormat('MMM dd, yyyy')
                                .format(_recurrenceEndDate!)
                            : 'Select End Date (Optional)',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _handleSave,
                        icon: const Icon(Icons.check),
                        label: Text(isEdit ? 'Update' : 'Create'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/alerts_api_service.dart';
import '../../services/auth_service.dart';

class AlertDetailScreen extends StatefulWidget {
  final String alertId;

  const AlertDetailScreen({super.key, required this.alertId});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final AlertsApiService _alertsApi = AlertsApiService.instance;
  Alert? _alert;
  bool _isLoading = true;
  String? _error;
  bool _isAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _loadAlert();
  }

  Future<void> _loadAlert() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final alert = await _alertsApi.getAlert(widget.alertId);
      setState(() {
        _alert = alert;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _canManageAlerts() async {
    final chw = await AuthService.instance.getCurrentCHW();
    return chw?.role == 'admin' || chw?.role == 'supervisor';
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'severe':
      case 'high':
        return Colors.orange;
      case 'warning':
      case 'medium':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getAlertTypeIcon(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'weather':
        return Icons.cloud;
      case 'disease':
        return Icons.coronavirus;
      case 'hazard':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _acknowledgeAlert() async {
    if (_alert == null || _isAcknowledged) return;

    try {
      await _alertsApi.acknowledgeAlert(_alert!.id);
      setState(() => _isAcknowledged = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert acknowledged successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to acknowledge alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareAlert() {
    if (_alert == null) return;

    final message = '''
🚨 ${_alert!.title}

${_alert!.description}

📍 Area: ${_alert!.area}, ${_alert!.region}
⚠️ Severity: ${_alert!.severity.toUpperCase()}
🕐 Start: ${_formatDateTime(_alert!.startTime)}
${_alert!.endTime != null ? '🕐 End: ${_formatDateTime(_alert!.endTime!)}' : ''}
${_alert!.actionRequired != null ? '\n✅ Action Required:\n${_alert!.actionRequired}' : ''}
${_alert!.source != null ? '\n📢 Source: ${_alert!.source}' : ''}
''';

    Share.share(message, subject: '🚨 Alert: ${_alert!.title}');
  }

  Future<void> _editAlert() async {
    if (_alert == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _EditAlertDialog(alert: _alert!),
    );

    if (result == true) {
      _loadAlert(); // Reload to show updated data
    }
  }

  Future<void> _deleteAlert() async {
    if (_alert == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text(
            'Are you sure you want to delete "${_alert!.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _alertsApi.deleteAlert(_alert!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return to previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete alert: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
        actions: [
          if (_alert != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareAlert,
              tooltip: 'Share Alert',
            ),
            FutureBuilder<bool>(
              future: _canManageAlerts(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editAlert();
                      } else if (value == 'delete') {
                        _deleteAlert();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit Alert'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Alert',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _alert != null && !_isAcknowledged
          ? FloatingActionButton.extended(
              onPressed: _acknowledgeAlert,
              icon: const Icon(Icons.check_circle),
              label: const Text('Acknowledge'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAlert,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_alert == null) {
      return const Center(child: Text('Alert not found'));
    }

    return RefreshIndicator(
      onRefresh: _loadAlert,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Header Card
            Card(
              elevation: 4,
              color: _getSeverityColor(_alert!.severity).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getAlertTypeIcon(_alert!.alertType),
                          size: 32,
                          color: _getSeverityColor(_alert!.severity),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _alert!.alertType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getSeverityColor(_alert!.severity),
                                ),
                              ),
                              Text(
                                _alert!.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(_alert!.severity),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _alert!.severity.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description Card
            _buildInfoCard('Description', _alert!.description),

            // Location Info
            _buildInfoCard(
              'Location',
              '${_alert!.area}, ${_alert!.region}',
              icon: Icons.location_on,
            ),

            // Time Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.schedule, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Timeline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                        'Start Time', _formatDateTime(_alert!.startTime)),
                    if (_alert!.endTime != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          'End Time', _formatDateTime(_alert!.endTime!)),
                    ],
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        'Status', _alert!.isActive ? 'Active' : 'Inactive'),
                    if (_alert!.isExpired) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ This alert has expired',
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action Required
            if (_alert!.actionRequired != null)
              _buildInfoCard(
                'Action Required',
                _alert!.actionRequired!,
                icon: Icons.task_alt,
                color: Colors.orange,
              ),

            // Source
            if (_alert!.source != null)
              _buildInfoCard(
                'Source',
                _alert!.source!,
                icon: Icons.source,
              ),

            // Additional Metadata
            if (_alert!.alertMetadata != null &&
                _alert!.alertMetadata!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Additional Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._alert!.alertMetadata!.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildInfoRow(
                            entry.key.replaceAll('_', ' ').toUpperCase(),
                            entry.value.toString(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Broadcast Status
            if (_alert!.isBroadcast)
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.broadcast_on_personal, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'This is a broadcast alert',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content,
      {IconData? icon, Color? color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// Edit Alert Dialog
class _EditAlertDialog extends StatefulWidget {
  final Alert alert;

  const _EditAlertDialog({required this.alert});

  @override
  State<_EditAlertDialog> createState() => _EditAlertDialogState();
}

class _EditAlertDialogState extends State<_EditAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  final AlertsApiService _alertsApi = AlertsApiService.instance;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _areaController;
  late TextEditingController _regionController;
  late TextEditingController _actionRequiredController;
  late bool _isActive;
  bool _isLoading = false;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.alert.title);
    _descriptionController =
        TextEditingController(text: widget.alert.description);
    _areaController = TextEditingController(text: widget.alert.area);
    _regionController = TextEditingController(text: widget.alert.region);
    _actionRequiredController =
        TextEditingController(text: widget.alert.actionRequired ?? '');
    _isActive = widget.alert.isActive;
    _endTime = widget.alert.endTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _regionController.dispose();
    _actionRequiredController.dispose();
    super.dispose();
  }

  Future<void> _selectEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _endTime =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _alertsApi.updateAlert(
        alertId: widget.alert.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        area: _areaController.text.trim(),
        region: _regionController.text.trim(),
        actionRequired: _actionRequiredController.text.trim().isEmpty
            ? null
            : _actionRequiredController.text.trim(),
        endTime: _endTime,
        isActive: _isActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Alert'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'Area *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regionController,
                  decoration: const InputDecoration(
                    labelText: 'Region *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _actionRequiredController,
                  decoration: const InputDecoration(
                    labelText: 'Action Required',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Time'),
                  subtitle: Text(_endTime != null
                      ? DateFormat('MMM d, yyyy h:mm a').format(_endTime!)
                      : 'Not set'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectEndTime,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

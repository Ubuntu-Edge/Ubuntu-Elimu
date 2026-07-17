import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';

class FollowupCard extends StatelessWidget {
  final Reminder reminder;
  final String patientDisplayId;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onReschedule;
  final VoidCallback? onSnooze;

  const FollowupCard({
    super.key,
    required this.reminder,
    required this.patientDisplayId,
    required this.onTap,
    this.onComplete,
    this.onReschedule,
    this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor();
    final urgencyIcon = _getUrgencyIcon();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: urgencyColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Urgency Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(urgencyIcon, size: 16, color: urgencyColor),
                        const SizedBox(width: 6),
                        Text(
                          _getUrgencyText(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: urgencyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Type Badge
                  _buildTypeBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Patient ID
              Text(
                'Patient: $patientDisplayId',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Reminder Title
              Text(
                reminder.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (reminder.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  reminder.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Date Info
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy').format(reminder.reminderDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (reminder.isOverdue)
                    Text(
                      '${reminder.daysOverdue} days overdue',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (reminder.isDueToday)
                    const Text(
                      'Due today',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      'In ${reminder.daysUntilDue} days',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),

              // Snooze badge if snoozed
              if (reminder.isSnoozed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.snooze, size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'Snoozed until ${DateFormat('MMM dd, h:mm a').format(reminder.snoozedUntil!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action Buttons
              if (onComplete != null || onReschedule != null || onSnooze != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onSnooze != null && !reminder.isCompleted)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSnooze,
                          icon: const Icon(Icons.snooze, size: 18),
                          label: const Text('Snooze'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    if (onSnooze != null && onComplete != null)
                      const SizedBox(width: 8),
                    if (onComplete != null && !reminder.isCompleted)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onComplete,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Complete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                    if ((onComplete != null || onSnooze != null) && onReschedule != null)
                      const SizedBox(width: 8),
                    if (onReschedule != null && !reminder.isCompleted)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReschedule,
                          icon: const Icon(Icons.event, size: 18),
                          label: const Text('Reschedule'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    IconData icon;
    Color color;

    switch (reminder.type) {
      case 'followup':
        icon = Icons.medical_services;
        color = Colors.blue;
        break;
      case 'medication':
        icon = Icons.medication;
        color = Colors.purple;
        break;
      case 'vaccination':
        icon = Icons.vaccines;
        color = Colors.green;
        break;
      case 'appointment':
        icon = Icons.event;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Color _getUrgencyColor() {
    if (reminder.isOverdue) return Colors.red;
    if (reminder.isDueToday) return Colors.orange;
    if (reminder.isDueTomorrow) return Colors.yellow[700]!;
    return Colors.green;
  }

  IconData _getUrgencyIcon() {
    if (reminder.isOverdue) return Icons.error;
    if (reminder.isDueToday) return Icons.warning;
    if (reminder.isDueTomorrow) return Icons.info;
    return Icons.check_circle;
  }

  String _getUrgencyText() {
    if (reminder.isOverdue) return 'OVERDUE';
    if (reminder.isDueToday) return 'TODAY';
    if (reminder.isDueTomorrow) return 'TOMORROW';
    return 'UPCOMING';
  }
}
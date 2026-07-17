import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/visit.dart';

class VisitCard extends StatelessWidget {
  final Visit visit;
  final VoidCallback? onTap;
  final bool showDetails;

  const VisitCard({
    super.key, 
    required this.visit, 
    this.onTap,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with date and urgency
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEE, MMM dd, yyyy').format(visit.visitDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (visit.visitType != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            visit.visitTypeDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      visit.urgencyLevelDisplay,
                      style: TextStyle(
                        color: _getUrgencyColor(visit.urgencyLevel),
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: _getUrgencyColor(visit.urgencyLevel).withValues(alpha: 0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Chief Complaint
              _buildInfoRow(
                icon: Icons.description,
                label: 'Chief Complaint',
                value: visit.chiefComplaint ?? 'Not recorded',
                isPlaceholder: visit.chiefComplaint == null,
              ),
              
              // Symptoms
              if (visit.symptoms != null || visit.symptomsList?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.sick,
                  label: 'Symptoms',
                  value: visit.symptomsList?.join(', ') ?? visit.symptoms ?? 'None',
                ),
              ],
              
              // Diagnosis
              if (visit.diagnosis != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.medical_services,
                  label: 'Diagnosis',
                  value: visit.diagnosis!,
                  valueStyle: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
              
              // Treatment
              if (visit.treatment != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.healing,
                  label: 'Treatment',
                  value: visit.treatment!,
                ),
              ],
              
              // Vitals summary (if available)
              if (visit.vitals != null && !visit.vitals!.isEmpty) ...[
                const SizedBox(height: 8),
                _buildVitalsSummary(),
              ],
              
              // Referral info
              if (visit.wasReferred) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_hospital, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Referred to: ${visit.referralLocation ?? 'Not specified'}',
                              style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                            if (visit.referralReason != null)
                              Text(
                                'Reason: ${visit.referralReason}',
                                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Follow-up info
              if (visit.followUpDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: visit.followUpCompleted ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        visit.followUpCompleted ? Icons.check_circle : Icons.event,
                        size: 16,
                        color: visit.followUpCompleted ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Follow-up: ${DateFormat('MMM dd, yyyy').format(visit.followUpDate!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: visit.followUpCompleted ? Colors.green : Colors.blue,
                        ),
                      ),
                      if (visit.followUpCompleted)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text('✓ Completed', style: TextStyle(fontSize: 12, color: Colors.green)),
                        ),
                    ],
                  ),
                ),
              ],
              
              // Medications given
              if (showDetails && visit.medicationsGiven?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildMedicationsSection(),
              ],
              
              // Notes
              if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${visit.notes}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: showDetails ? null : 2,
                  overflow: showDetails ? null : TextOverflow.ellipsis,
                ),
              ],
              
              // Duration and outcome
              if (showDetails) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (visit.visitDurationMinutes != null) ...[
                      Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${visit.visitDurationMinutes} min',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (visit.outcome != null) ...[
                      Icon(Icons.check_circle_outline, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Outcome: ${visit.outcome}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
    bool isPlaceholder = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: value,
                  style: valueStyle ?? TextStyle(
                    color: isPlaceholder ? Colors.grey.shade500 : null,
                    fontStyle: isPlaceholder ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildVitalsSummary() {
    final vitals = visit.vitals!;
    final vitalItems = <String>[];
    
    if (vitals.temperature != null) vitalItems.add('Temp: ${vitals.temperature}°C');
    if (vitals.bloodPressureSystolic != null && vitals.bloodPressureDiastolic != null) {
      vitalItems.add('BP: ${vitals.bloodPressureDisplay}');
    }
    if (vitals.pulseRate != null) vitalItems.add('Pulse: ${vitals.pulseRate} bpm');
    if (vitals.oxygenSaturation != null) vitalItems.add('SpO2: ${vitals.oxygenSaturation}%');
    
    if (vitalItems.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, size: 16, color: Colors.purple.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vitalItems.join(' • '),
              style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medication, size: 16, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              'Medications Given:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.orange.shade800),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...visit.medicationsGiven!.map((med) => Padding(
          padding: const EdgeInsets.only(left: 24, top: 2),
          child: Text(
            '• ${med.displayString}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        )),
      ],
    );
  }

  Color _getUrgencyColor(String urgencyLevel) {
    switch (urgencyLevel.toLowerCase()) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      case 'standard':
        return Colors.amber;
      case 'low':
        return Colors.green;
      case 'routine':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
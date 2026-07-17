import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../theme/app_theme.dart';
import 'dart:io';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const PatientCard({
    super.key,
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // 🧑‍⚕️ Avatar Section
              _buildAvatar(),
              const SizedBox(width: AppTheme.spacingMd),

              // 👤 Patient Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      patient.displayId,
                      style: AppTheme.labelMedium,
                    ),

                    const SizedBox(height: AppTheme.spacingXs),

                    // ID + Risk Badge Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.id,
                            style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _buildRiskBadge(),
                      ],
                    ),

                    const SizedBox(height: AppTheme.spacingXs),

                    // Age + Gender
                    Text(
                      '${patient.ageDisplay} • ${_getGenderIcon()} ${(patient.gender?.toUpperCase() ?? 'N/A')}',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),

                    if (patient.village != null && patient.village!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppTheme.spacingXs),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              patient.village!,
                              style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ➡️ Arrow Icon
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // 🖼 Avatar Builder
  Widget _buildAvatar() {
    if (patient.photoPath != null &&
        patient.photoPath!.isNotEmpty &&
        File(patient.photoPath!).existsSync()) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: FileImage(File(patient.photoPath!)),
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: _getAvatarColor(),
      child: Icon(
        _getAvatarIcon(),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // ⚠️ Risk Badge Builder
  Widget _buildRiskBadge() {
    if (patient.isPregnant ?? false) {
      return _badge(
        icon: Icons.pregnant_woman,
        text: 'Pregnant',
        color: AppColors.secondary,
      );
    }

    if (patient.isHighRisk) {
      return _badge(
        icon: Icons.warning,
        text: 'High Risk',
        color: AppColors.error,
      );
    }

    if (patient.hasChronicCondition ?? false) {
      return _badge(
        icon: Icons.local_hospital,
        text: 'Chronic',
        color: AppColors.warning,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _badge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTheme.labelSmall.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // 🎨 Avatar Color
  Color _getAvatarColor() {
    if (patient.isPregnant ?? false) return AppColors.secondary;
    if (patient.isHighRisk) return AppColors.error;
    if (patient.hasChronicCondition ?? false) return AppColors.warning;
    return patient.gender == 'male' ? AppColors.info : AppColors.primary;
  }

  // 👥 Avatar Icon
  IconData _getAvatarIcon() {
    if (patient.isPregnant ?? false) return Icons.pregnant_woman;
    if (patient.age < 18) {
      return Icons.child_care;
    }
    return patient.gender == 'male' ? Icons.man : Icons.woman;
  }

  // 🚻 Gender Symbol
  String _getGenderIcon() {
    return patient.gender == 'male' ? '♂' : '♀';
  }
}
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Export all widget files for easy importing
export 'empty_state_widget.dart';
export 'loading_widgets.dart';
export 'custom_button.dart';
export 'custom_text_field.dart';
export 'patient_card.dart';
export 'visit_card.dart';
export 'followup_card.dart';

/// Common reusable styled widgets for CHW Augment
/// Following the professional medical app UI design

class AppWidgets {
  /// Professional styled card with icon, title, and action
  static Widget actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? color,
    Color? iconColor,
    required VoidCallback onTap,
    String? badge,
    bool showArrow = true,
  }) {
    final effectiveColor = iconColor ?? color ?? AppTheme.primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: effectiveColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(icon, color: effectiveColor, size: 24),
                ),
                const SizedBox(width: AppTheme.spacingLG),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeLG,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSM,
                                vertical: AppTheme.spacingXS,
                              ),
                              decoration: BoxDecoration(
                                color: effectiveColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeXS,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSM,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showArrow)
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textLight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Stat card for displaying metrics
  static Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final effectiveColor = iconColor ?? color ?? AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: effectiveColor.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: effectiveColor.withAlpha(51)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: effectiveColor, size: 22),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeHeading,
                    fontWeight: FontWeight.bold,
                    color: effectiveColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSM,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Risk badge indicator
  static Widget riskBadge({
    required String level,
    Color? color,
  }) {
    Color badgeColor;
    IconData badgeIcon;

    switch (level.toLowerCase()) {
      case 'critical':
        badgeColor = color ?? AppTheme.riskCritical;
        badgeIcon = Icons.dangerous;
        break;
      case 'high':
        badgeColor = color ?? AppTheme.riskHigh;
        badgeIcon = Icons.warning;
        break;
      case 'medium':
        badgeColor = color ?? AppTheme.riskMedium;
        badgeIcon = Icons.warning_amber;
        break;
      case 'low':
        badgeColor = color ?? AppTheme.riskLow;
        badgeIcon = Icons.check_circle;
        break;
      default:
        badgeColor = color ?? AppTheme.textLight;
        badgeIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSM,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(26),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: badgeColor.withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: AppTheme.spacingXS),
          Text(
            level.toUpperCase(),
            style: TextStyle(
              fontSize: AppTheme.fontSizeXS,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Professional header card with gradient
  static Widget headerCard({
    required String greeting,
    required String name,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowMD,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMD,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeHeading,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacingSM),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.white.withAlpha(204),
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMD,
                          color: Colors.white.withAlpha(204),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Section header
  static Widget sectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeSM,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Doctor/CHW profile card (based on image design)
  static Widget profileCard({
    required String name,
    required String specialty,
    String? rating,
    String? fee,
    String? imageUrl,
    VoidCallback? onTap,
    VoidCallback? onBook,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryLight,
            child: imageUrl != null
                ? ClipOval(child: Image.network(imageUrl, fit: BoxFit.cover))
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeXL,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLG,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialty,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSM,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (rating != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeXS,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (fee != null)
                Text(
                  fee,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMD,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              const SizedBox(height: AppTheme.spacingSM),
              if (onBook != null)
                ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                      vertical: AppTheme.spacingXS,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: AppTheme.fontSizeXS),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Category chip (for specialties)
  static Widget categoryChip({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(26),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(
            color: isSelected ? color : color.withAlpha(51),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSM,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search bar widget
  static Widget searchBar({
    required TextEditingController controller,
    required String hintText,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeMD,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: AppTheme.fontSizeMD,
            color: AppTheme.textLight,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppTheme.textLight,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textLight),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                )
              : suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLG,
            vertical: AppTheme.spacingMD,
          ),
        ),
      ),
    );
  }

  /// Empty state widget
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.textLight.withAlpha(128),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeXL,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMD,
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacingXL),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Loading indicator
  static Widget loading({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              message,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeMD,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

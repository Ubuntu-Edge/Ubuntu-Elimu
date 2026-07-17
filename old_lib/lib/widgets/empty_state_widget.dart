import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable empty state widget for displaying when there's no data
/// Use this widget throughout the app for consistent empty state handling
class EmptyStateWidget extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// The main title message
  final String title;
  
  /// Optional subtitle/description
  final String? subtitle;
  
  /// Optional action button text
  final String? actionText;
  
  /// Optional callback for the action button
  final VoidCallback? onAction;
  
  /// Optional secondary action button text
  final String? secondaryActionText;
  
  /// Optional callback for the secondary action button
  final VoidCallback? onSecondaryAction;
  
  /// Icon size (default: 80)
  final double iconSize;
  
  /// Icon color (default: AppColors.textLight)
  final Color? iconColor;
  
  /// Whether to show the icon in a circle background
  final bool showIconBackground;
  
  /// Custom widget to display instead of icon
  final Widget? customIcon;
  
  /// Padding around the widget
  final EdgeInsets padding;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.iconSize = 80,
    this.iconColor,
    this.showIconBackground = true,
    this.customIcon,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon or custom widget
            if (customIcon != null)
              customIcon!
            else if (showIconBackground)
              Container(
                width: iconSize + 40,
                height: iconSize + 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.textLight).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ?? AppColors.textLight,
                ),
              )
            else
              Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppColors.textLight,
              ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action buttons
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
            
            if (secondaryActionText != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pre-configured empty state for no patients
class NoPatientEmptyState extends StatelessWidget {
  final VoidCallback? onRegisterPatient;

  const NoPatientEmptyState({super.key, this.onRegisterPatient});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'No Patients Yet',
      subtitle: 'Start by registering your first patient to begin tracking their health.',
      actionText: onRegisterPatient != null ? 'Register Patient' : null,
      onAction: onRegisterPatient,
      iconColor: AppColors.primary,
    );
  }
}

/// Pre-configured empty state for no messages
class NoMessagesEmptyState extends StatelessWidget {
  final VoidCallback? onComposeMessage;

  const NoMessagesEmptyState({super.key, this.onComposeMessage});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: 'No Messages',
      subtitle: 'Your inbox is empty. Messages from supervisors and colleagues will appear here.',
      actionText: onComposeMessage != null ? 'Send Message' : null,
      onAction: onComposeMessage,
      iconColor: AppColors.info,
    );
  }
}

/// Pre-configured empty state for no referrals
class NoReferralsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateReferral;

  const NoReferralsEmptyState({super.key, this.onCreateReferral});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.send_outlined,
      title: 'No Referrals',
      subtitle: 'Patient referrals will appear here when you create them.',
      actionText: onCreateReferral != null ? 'Create Referral' : null,
      onAction: onCreateReferral,
      iconColor: AppColors.warning,
    );
  }
}

/// Pre-configured empty state for no visits
class NoVisitsEmptyState extends StatelessWidget {
  final VoidCallback? onRecordVisit;

  const NoVisitsEmptyState({super.key, this.onRecordVisit});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.calendar_today_outlined,
      title: 'No Visits Recorded',
      subtitle: 'Patient visits will be displayed here after you record them.',
      actionText: onRecordVisit != null ? 'Record Visit' : null,
      onAction: onRecordVisit,
      iconColor: AppColors.success,
    );
  }
}

/// Pre-configured empty state for no reminders
class NoRemindersEmptyState extends StatelessWidget {
  final VoidCallback? onCreateReminder;

  const NoRemindersEmptyState({super.key, this.onCreateReminder});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.alarm_outlined,
      title: 'No Reminders',
      subtitle: 'Set reminders for follow-ups and important tasks.',
      actionText: onCreateReminder != null ? 'Create Reminder' : null,
      onAction: onCreateReminder,
      iconColor: AppColors.secondary,
    );
  }
}

/// Pre-configured empty state for no notifications
class NoNotificationsEmptyState extends StatelessWidget {
  const NoNotificationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.notifications_none_outlined,
      title: 'All Caught Up!',
      subtitle: 'You have no new notifications at the moment.',
      iconColor: AppColors.success,
    );
  }
}

/// Pre-configured empty state for no training modules
class NoTrainingEmptyState extends StatelessWidget {
  const NoTrainingEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.school_outlined,
      title: 'No Training Modules',
      subtitle: 'Training modules will appear here when they become available.',
      iconColor: AppColors.primary,
    );
  }
}

/// Pre-configured empty state for no search results
class NoSearchResultsEmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onClearSearch;

  const NoSearchResultsEmptyState({
    super.key,
    required this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_outlined,
      title: 'No Results Found',
      subtitle: 'No results found for "$searchQuery". Try a different search term.',
      actionText: onClearSearch != null ? 'Clear Search' : null,
      onAction: onClearSearch,
      iconColor: AppColors.textLight,
    );
  }
}

/// Pre-configured empty state for no families
class NoFamiliesEmptyState extends StatelessWidget {
  final VoidCallback? onRegisterFamily;

  const NoFamiliesEmptyState({super.key, this.onRegisterFamily});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.family_restroom_outlined,
      title: 'No Families Registered',
      subtitle: 'Register family units to group patients by household.',
      actionText: onRegisterFamily != null ? 'Register Family' : null,
      onAction: onRegisterFamily,
      iconColor: AppColors.primary,
    );
  }
}

/// Pre-configured empty state for no feedback
class NoFeedbackEmptyState extends StatelessWidget {
  final VoidCallback? onSubmitFeedback;

  const NoFeedbackEmptyState({super.key, this.onSubmitFeedback});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.feedback_outlined,
      title: 'No Feedback Yet',
      subtitle: 'Your submitted feedback will appear here.',
      actionText: onSubmitFeedback != null ? 'Submit Feedback' : null,
      onAction: onSubmitFeedback,
      iconColor: AppColors.info,
    );
  }
}

/// Pre-configured empty state for network/connection error
class NetworkErrorEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorMessage;

  const NetworkErrorEmptyState({
    super.key,
    this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_outlined,
      title: 'Connection Error',
      subtitle: errorMessage ?? 'Unable to connect to the server. Please check your internet connection.',
      actionText: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      iconColor: AppColors.error,
    );
  }
}

/// Pre-configured empty state for general errors
class ErrorEmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorEmptyState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: title ?? 'Something Went Wrong',
      subtitle: message ?? 'An unexpected error occurred. Please try again.',
      actionText: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      iconColor: AppColors.error,
    );
  }
}

/// Pre-configured empty state for offline mode
class OfflineEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineEmptyState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.cloud_off_outlined,
      title: 'You\'re Offline',
      subtitle: 'Some features may be limited while offline. Connect to the internet to sync your data.',
      actionText: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
      iconColor: AppColors.warning,
    );
  }
}

/// Pre-configured empty state for no supplies
class NoSuppliesEmptyState extends StatelessWidget {
  final VoidCallback? onAddSupply;

  const NoSuppliesEmptyState({super.key, this.onAddSupply});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: 'No Supplies',
      subtitle: 'Track your medical supplies by adding them here.',
      actionText: onAddSupply != null ? 'Add Supply' : null,
      onAction: onAddSupply,
      iconColor: AppColors.primary,
    );
  }
}

/// Pre-configured empty state for no alerts
class NoAlertsEmptyState extends StatelessWidget {
  const NoAlertsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.notifications_active_outlined,
      title: 'No Active Alerts',
      subtitle: 'Weather, disease, and hazard alerts will appear here when issued.',
      iconColor: AppColors.success,
    );
  }
}

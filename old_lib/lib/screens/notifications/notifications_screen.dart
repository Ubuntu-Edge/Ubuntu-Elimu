import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notification_api_service.dart' as api;

/// Local Notification Type Enum for UI
enum NotificationType {
  task,
  alert,
  message,
  reminder,
  system,
  other,
  followup,
  sync,
  emergency,
}

/// Notification model for UI
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String priority;
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = 'normal',
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
    this.data,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      priority: priority,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute,
      data: data,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.task:
        return FontAwesomeIcons.listCheck;
      case NotificationType.followup:
        return FontAwesomeIcons.calendarCheck;
      case NotificationType.sync:
        return FontAwesomeIcons.arrowsRotate;
      case NotificationType.alert:
        return FontAwesomeIcons.triangleExclamation;
      case NotificationType.message:
        return FontAwesomeIcons.comment;
      case NotificationType.system:
        return FontAwesomeIcons.gear;
      case NotificationType.reminder:
        return FontAwesomeIcons.bell;
      case NotificationType.emergency:
        return FontAwesomeIcons.circleExclamation;
      case NotificationType.other:
        return FontAwesomeIcons.circleInfo;
    }
  }

  Color get color {
    // Check priority first for urgent/high items
    if (priority == 'urgent' || priority == 'high') {
      return AppColors.error;
    }
    
    switch (type) {
      case NotificationType.task:
        return AppColors.primary;
      case NotificationType.followup:
        return AppColors.info;
      case NotificationType.sync:
        return AppColors.success;
      case NotificationType.alert:
        return AppColors.warning;
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.system:
        return AppColors.textSecondary;
      case NotificationType.reminder:
        return AppColors.secondary;
      case NotificationType.emergency:
        return AppColors.error;
      case NotificationType.other:
        return AppColors.textSecondary;
    }
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final api.NotificationApiService _notificationApi = api.NotificationApiService.instance;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _unreadCountFromApi = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await _notificationApi.getNotifications(perPage: 100);
      final unreadResponse = await _notificationApi.getUnreadCount();
      
      setState(() {
        _notifications = response.items.map((apiNotif) => AppNotification(
          id: apiNotif.id,
          title: apiNotif.title,
          body: apiNotif.message,
          type: _mapApiTypeToLocalType(apiNotif.notificationType),
          priority: apiNotif.priority,
          createdAt: apiNotif.createdAt,
          isRead: apiNotif.isRead,
          actionRoute: apiNotif.actionUrl,
          data: apiNotif.actionData ?? apiNotif.notificationMetadata,
        )).toList();
        _unreadCountFromApi = unreadResponse.unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notifications';
        _isLoading = false;
      });
      debugPrint('Error loading notifications: $e');
    }
  }

  NotificationType _mapApiTypeToLocalType(String apiType) {
    switch (apiType.toLowerCase()) {
      case 'task':
        return NotificationType.task;
      case 'alert':
        return NotificationType.alert;
      case 'message':
        return NotificationType.message;
      case 'reminder':
        return NotificationType.reminder;
      case 'followup':
        return NotificationType.followup;
      case 'sync':
        return NotificationType.sync;
      case 'system':
        return NotificationType.system;
      case 'other':
      default:
        return NotificationType.other;
    }
  }

  void _markAsRead(String id) async {
    try {
      await _notificationApi.markAsRead(id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCountFromApi = _notifications.where((n) => !n.isRead).length;
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  void _markAllAsRead() async {
    try {
      await _notificationApi.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCountFromApi = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('allNotificationsMarkedRead') ?? 'All notifications marked as read'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearAll() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.translate('clearAllNotifications') ?? 'Clear All Notifications', style: AppTheme.headingMedium),
        content: Text(l10n.translate('clearAllNotificationsConfirm') ?? 'Are you sure you want to clear all notifications?', style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _notificationApi.clearReadNotifications();
                setState(() => _notifications.removeWhere((n) => n.isRead));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('allNotificationsCleared') ?? 'Read notifications cleared'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear notifications'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.translate('clearAction') ?? 'Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(String id) async {
    try {
      await _notificationApi.deleteNotification(id);
      setState(() {
        _notifications.removeWhere((n) => n.id == id);
        _unreadCountFromApi = _notifications.where((n) => !n.isRead).length;
      });
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int get _unreadCount => _unreadCountFromApi > 0 ? _unreadCountFromApi : _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? _buildErrorState()
                      : _notifications.isEmpty
                          ? _buildEmptyState()
                          : _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notifications,
                        style: AppTheme.headingMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      if (_unreadCount > 0)
                        Text(
                          '$_unreadCount unread',
                          style: AppTheme.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                        ),
                    ],
                  ),
                ),
                if (_notifications.isNotEmpty) ...[
                  GestureDetector(
                    onTap: _markAllAsRead,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(FontAwesomeIcons.checkDouble, color: Colors.white, size: 18),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  GestureDetector(
                    onTap: _clearAll,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(FontAwesomeIcons.trashCan, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(FontAwesomeIcons.triangleExclamation, color: AppColors.error, size: 48),
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text(
              l10n.translate('errorLoadingNotifications') ?? 'Error Loading Notifications',
              style: AppTheme.headingMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              _error ?? 'Unknown error occurred',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16),
              label: Text(l10n.translate('retry') ?? 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(FontAwesomeIcons.bellSlash, color: AppColors.primary, size: 48),
          ),
          SizedBox(height: AppTheme.spacingLg),
          Text(
            l10n.translate('noNotifications') ?? 'No Notifications',
            style: AppTheme.headingMedium.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppTheme.spacingSm),
          Text(
            l10n.translate('allCaughtUp') ?? 'You\'re all caught up!',
            style: AppTheme.bodyMedium.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final l10n = AppLocalizations.of(context);
    // Group notifications by date
    final today = DateTime.now();
    final todayNotifications = _notifications.where((n) => 
      n.createdAt.year == today.year && 
      n.createdAt.month == today.month && 
      n.createdAt.day == today.day
    ).toList();
    
    final olderNotifications = _notifications.where((n) => 
      !(n.createdAt.year == today.year && 
        n.createdAt.month == today.month && 
        n.createdAt.day == today.day)
    ).toList();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          if (todayNotifications.isNotEmpty) ...[
            _buildSectionHeader(l10n.translate('todayLabel') ?? 'Today'),
            ...todayNotifications.map((n) => _buildNotificationCard(n)),
          ],
          if (olderNotifications.isNotEmpty) ...[
            if (todayNotifications.isNotEmpty) SizedBox(height: AppTheme.spacingMd),
            _buildSectionHeader(l10n.translate('earlier') ?? 'Earlier'),
            ...olderNotifications.map((n) => _buildNotificationCard(n)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Text(
        title,
        style: AppTheme.labelLarge.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FaIcon(FontAwesomeIcons.trash, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () {
          _markAsRead(notification.id);
          _showNotificationDetail(notification);
        },
        child: Container(
          margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
          padding: EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : notification.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: notification.isRead ? null : Border.all(color: notification.color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(notification.icon, color: notification.color, size: 18),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: notification.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: AppTheme.labelSmall.copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatFullDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  void _showNotificationDetail(AppNotification notification) {
    final l10n = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: notification.color.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: notification.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FaIcon(notification.icon, color: notification.color, size: 22),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTypeLabel(notification.type),
                          style: AppTheme.labelSmall.copyWith(
                            color: notification.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          notification.title,
                          style: AppTheme.headingSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: FaIcon(FontAwesomeIcons.xmark, color: AppColors.textSecondary, size: 18),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message body
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notification.body,
                        style: AppTheme.bodyMedium.copyWith(height: 1.6),
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingLg),
                    
                    // Details section
                    Text(
                      l10n.translate('details') ?? 'Details',
                      style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    
                    _buildDetailRow(
                      FontAwesomeIcons.clock,
                      l10n.translate('receivedAt') ?? 'Received',
                      _formatFullDate(notification.createdAt),
                    ),
                    
                    _buildDetailRow(
                      FontAwesomeIcons.tag,
                      l10n.translate('type') ?? 'Type',
                      _getTypeLabel(notification.type),
                    ),
                    
                    _buildDetailRow(
                      FontAwesomeIcons.flag,
                      l10n.translate('priority') ?? 'Priority',
                      notification.priority.toUpperCase(),
                      valueColor: _getPriorityColor(notification.priority),
                    ),
                    
                    _buildDetailRow(
                      notification.isRead ? FontAwesomeIcons.envelopeOpen : FontAwesomeIcons.envelope,
                      l10n.translate('status') ?? 'Status',
                      notification.isRead 
                          ? (l10n.translate('read') ?? 'Read')
                          : (l10n.translate('unread') ?? 'Unread'),
                    ),
                    
                    // Action Data (if any)
                    if (notification.data != null && notification.data!.isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacingLg),
                      Text(
                        l10n.translate('additionalInfo') ?? 'Additional Information',
                        style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: AppTheme.spacingMd),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: notification.data!.entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_formatKey(entry.key)}: ',
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${entry.value}',
                                      style: AppTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Action button (if actionRoute exists)
                    if (notification.actionRoute != null) ...[
                      SizedBox(height: AppTheme.spacingLg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to action route
                            _handleNotificationAction(notification);
                          },
                          icon: FaIcon(FontAwesomeIcons.arrowRight, size: 14),
                          label: Text(l10n.translate('viewDetails') ?? 'View Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: notification.color,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: AppTheme.spacingMd),
                    
                    // Delete button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteNotification(notification.id);
                        },
                        icon: FaIcon(FontAwesomeIcons.trash, size: 14),
                        label: Text(l10n.translate('deleteNotification') ?? 'Delete Notification'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingLg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: FaIcon(icon, color: AppColors.primary, size: 14),
            ),
          ),
          SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.task:
        return 'Task';
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.message:
        return 'Message';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.system:
        return 'System';
      case NotificationType.followup:
        return 'Follow-up';
      case NotificationType.sync:
        return 'Sync';
      case NotificationType.emergency:
        return 'Emergency';
      case NotificationType.other:
        return 'Other';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'normal':
        return AppColors.info;
      case 'low':
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatKey(String key) {
    // Convert snake_case to Title Case
    return key.split('_').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  void _handleNotificationAction(AppNotification notification) {
    // Handle navigation based on notification type or action route
    if (notification.actionRoute != null) {
      // Could implement route-based navigation here
      debugPrint('Navigate to: ${notification.actionRoute}');
    }
  }
}

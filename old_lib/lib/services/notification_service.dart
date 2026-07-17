import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/reminder.dart';
import '../models/patient.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Nairobi'));

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ubuntu'); // Changed from ic_launcher

    // iOS/macOS initialization settings
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    final androidImplementation =
    _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final bool? grantedAndroid = await androidImplementation?.requestNotificationsPermission();

    final iosImplementation =
    _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final bool? grantedIOS = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (grantedAndroid ?? true) && (grantedIOS ?? true);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Handle navigation when notification tapped
  }

  Future<void> scheduleReminderNotification(Reminder reminder, Patient patient) async {
    if (!_isInitialized) await initialize();

    final notificationId = reminder.notificationId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'Patient follow-up and medication reminders',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true, // Show as full screen for critical reminders
      category: AndroidNotificationCategory.alarm,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'snooze_15',
          'Snooze 15 min',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'complete',
          'Mark Complete',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'reminderCategory',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final scheduledDate = reminder.notificationTime ?? reminder.reminderDate;
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      notificationId,
      _getNotificationTitle(reminder.type),
      _getNotificationBody(reminder, patient),
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'reminder_${reminder.id}',
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  /// Snooze a reminder notification by rescheduling it
  Future<void> snoozeReminderNotification(Reminder reminder, Patient patient, DateTime snoozeUntil) async {
    if (!_isInitialized) await initialize();

    // Cancel existing notification
    if (reminder.notificationId != null) {
      await cancelNotification(reminder.notificationId!);
    }

    final notificationId = reminder.notificationId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'Patient follow-up and medication reminders',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true, // Show as full screen on lock screen
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(snoozeUntil, tz.local);

    await _notifications.zonedSchedule(
      notificationId,
      '⏰ ${_getNotificationTitle(reminder.type)} (Snoozed)',
      _getNotificationBody(reminder, patient),
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'reminder_${reminder.id}_snoozed',
    );
  }
  
  /// Request exact alarm permission for Android 12+ (required for reliable reminders)
  Future<bool> requestExactAlarmPermission() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation == null) return true;
    
    // For Android 12+ (API 31+), check if exact alarm permission is granted
    final bool? canScheduleExactAlarms = await androidImplementation.canScheduleExactNotifications();
    
    if (canScheduleExactAlarms == false) {
      // Request permission by opening settings
      await androidImplementation.requestExactAlarmsPermission();
      
      // Check again after user returns from settings
      final bool? grantedAfter = await androidImplementation.canScheduleExactNotifications();
      return grantedAfter ?? false;
    }
    
    return canScheduleExactAlarms ?? true;
  }

  Future<void> scheduleDailySummary(String chwId, int pendingCount, int overdueCount) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 8, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_summary_channel',
      'Daily Summary',
      channelDescription: 'Daily summary of tasks and reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notifications.zonedSchedule(
      999999, // Fixed ID
      'Daily Summary',
      'You have $pendingCount pending follow-ups${overdueCount > 0 ? " ($overdueCount overdue)" : ""}',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'daily_summary',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'followup':
        return '📅 Follow-up Reminder';
      case 'medication':
        return '💊 Medication Reminder';
      case 'vaccination':
        return '💉 Vaccination Due';
      case 'appointment':
        return '🏥 Appointment Reminder';
      default:
        return '🔔 Reminder';
    }
  }

  String _getNotificationBody(Reminder reminder, Patient patient) {
    final patientId = patient.displayId;
    switch (reminder.type) {
      case 'followup':
        return 'Follow-up visit for patient $patientId: ${reminder.title}';
      case 'medication':
        return 'Patient $patientId needs medication refill: ${reminder.title}';
      case 'vaccination':
        return 'Patient $patientId is due for vaccination: ${reminder.title}';
      case 'appointment':
        return 'Appointment with patient $patientId: ${reminder.title}';
      default:
        return '${reminder.title} - Patient $patientId';
    }
  }

  Future<void> createNotificationChannels() async {
    const AndroidNotificationChannel remindersChannel = AndroidNotificationChannel(
      'reminders_channel',
      'Reminders',
      description: 'Patient follow-up and medication reminders',
      importance: Importance.high,
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_channel',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.high,
    );

    const AndroidNotificationChannel dailySummaryChannel = AndroidNotificationChannel(
      'daily_summary_channel',
      'Daily Summary',
      description: 'Daily summary of tasks and reminders',
      importance: Importance.high,
    );

    final androidImplementation =
    _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(remindersChannel);
    await androidImplementation?.createNotificationChannel(generalChannel);
    await androidImplementation?.createNotificationChannel(dailySummaryChannel);
  }
}

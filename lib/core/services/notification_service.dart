import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Request permissions for iOS/macOS
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        _handleNotificationTap(response.payload);
      },
    );
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null && payload.startsWith('debtor_')) {
      final debtorId = payload.replaceFirst('debtor_', '');
      // Navigate to CustomerDetailScreen
      // We will use a global navigator key to push the route
      if (navigatorKey.currentState != null) {
        // We'll dispatch an event or push directly if we can access the provider
        // Since we don't have direct access to ref here, we can use a custom route
        // or broadcast a stream that the main app listens to.
        // For simplicity, we'll push a named route or handle it in the UI layer.
        navigatorKey.currentState!.pushNamed('/customer', arguments: debtorId);
      }
    } else if (payload == 'daily_summary') {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed('/statistics');
      }
    }
  }

  Future<void> scheduleDebtReminder(String id, String debtorName, double amount, DateTime dueDate) async {
    // Cancel any existing notification for this debtor
    await cancelNotification(id.hashCode);

    // Schedule for the exact time specified by the user
    var scheduledDate = tz.TZDateTime.from(
      dueDate,
      tz.local,
    );

    // If the due date is in the past, don't schedule
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'debt_reminders_channel',
      'تذكيرات الديون',
      channelDescription: 'إشعارات للتذكير بمواعيد سداد الديون',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id.hashCode,
      title: 'موعد سداد دين',
      body: 'حان موعد سداد دين بقيمة $amount شيكل على $debtorName.',
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'debtor_$id',
    );
  }

  Future<void> scheduleDailySmartNotification() async {
    // Schedule a daily notification at 8:00 PM
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smart_insights_channel',
      'رؤى صافي الذكية',
      channelDescription: 'إشعارات يومية برؤى حول مبيعاتك وديونك',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 999999, // Fixed ID for daily notification
      title: 'صافي الذكي 💡',
      body: 'لا تنسَ مراجعة ملخص مبيعاتك وديونك لهذا اليوم!',
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
      payload: 'daily_summary',
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
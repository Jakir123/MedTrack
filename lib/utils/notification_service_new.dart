import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:med_track/utils/session_manager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

enum NotificationType {
  direct,
  scheduled,
}

@pragma('vm:entry-point')
class NotificationServiceV2 {
  static final NotificationServiceV2 _instance = NotificationServiceV2._internal();
  factory NotificationServiceV2() => _instance;
  NotificationServiceV2._internal();

  static const String _directChannelId = 'low_stock_channel';
  static const String _scheduledChannelId = 'daily_reminder_channel';
  
  static const String _directChannelName = 'Low Stock Alerts';
  static const String _scheduledChannelName = 'Daily Reminders';
  
  static const String _directChannelDesc = 'Notifications for low stock items';
  static const String _scheduledChannelDesc = 'Daily medication reminders';
  
  static const int _directNotificationId = 1000;
  static const int _scheduledNotificationId = 2000;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Initialize the notification service
  Future<void> initialize() async {
    await _setupTimeZone();
    await _initializeNotifications();
    await _createNotificationChannels();
    await _requestNotificationPermission();

    // Send a test notification
    // await _sendTestNotification();
  }

  // Set up timezone for scheduled notifications
  Future<void> _setupTimeZone() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  // Initialize notification plugin
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  // Create notification channels for different notification types
  Future<void> _createNotificationChannels() async {
    // Direct notification channel (for low stock alerts)
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        _directChannelId,
        _directChannelName,
        description: _directChannelDesc,
        importance: Importance.high,
        showBadge: true,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Scheduled notification channel (for daily reminders)
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        _scheduledChannelId,
        _scheduledChannelName,
        description: _scheduledChannelDesc,
        importance: Importance.high,
        showBadge: true,
        enableVibration: true,
        playSound: true,
      ),
    );
  }

  // Request notification permissions
  Future<bool> _requestNotificationPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return true;
    }
    return true;
  }

  // Show a direct notification (for low stock alerts)
  Future<void> showDirectNotification({
    required String title,
    required String body,
  }) async {
    final notificationsEnabled = await SessionManager.areNotificationsEnabled();
    if (!notificationsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      _directChannelId,
      _directChannelName,
      channelDescription: _directChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      enableLights: true,
      color: Colors.red,
      ticker: 'Low Stock Alert',
    );

    const iosDetails = DarwinNotificationDetails();

    await _notifications.show(
      _directNotificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  // We'll use inexact scheduling by default to avoid permission issues
  // This provides better battery life and doesn't require special permissions
  bool _useExactScheduling = false;
  
  // Check if we can use exact scheduling (for future reference)
  Future<void> _checkSchedulingCapabilities() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      _useExactScheduling = androidInfo.version.sdkInt < 31; // Only use exact on Android 11 or lower
    }
  }

  // Schedule a daily reminder notification
  Future<void> scheduleDailyNotification(TimeOfDay time) async {
    try {
      // Ensure notifications are properly initialized
      await _initializeNotifications();
      await _createNotificationChannels();

      // Cancel any existing scheduled notifications
      await _cancelScheduledNotifications();

      // Get current time in local timezone
      final now = tz.TZDateTime.now(tz.local);
      final location = tz.getLocation(await FlutterTimezone.getLocalTimezone());


      // Create scheduled date in local timezone
      var scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If the time has already passed today, schedule for next day
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      print('📅 Notification scheduled for: $scheduledDate');
      print('⏰ Current time is: $now');
      print('⏳ Time until notification: ${scheduledDate.difference(now)}');

      final androidDetails = const AndroidNotificationDetails(
        'test_channel',  // Using the test channel that works
        'MedTrack Reminders',
        channelDescription: 'Channel for medication reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        color: Colors.blue,
        enableLights: true,
        ledColor: Colors.blue,
        ledOnMs: 1000,
        ledOffMs: 500,
        styleInformation: BigTextStyleInformation(''),
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Schedule the notification
      await _notifications.zonedSchedule(
        _scheduledNotificationId,
        'Medication Reminder ZONE',
        'ZONE Time to check your out of stock medications and call the representative!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_reminder',
      );

      print('✅ Notification scheduled successfully!');

      // Debug: List all pending notifications
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      print('📋 Pending notifications:');
      for (var notif in pendingNotifications) {
        print('  - ID: ${notif.id}, Title: ${notif.title}, Scheduled for: ${notif.body}');
      }

    } catch (e, stackTrace) {
      print('❌ Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }

  }

  // Send a test notification to verify notifications are working
  Future<void> _sendTestNotification() async {
    try {
      print('Sending test notification...');

      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for testing notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notifications.show(
        9999, // Test notification ID
        'Test Notification',
        'This is a test notification',
        notificationDetails,
      );

      print('Test notification sent successfully');
    } catch (e) {
      print('Failed to send test notification: $e');
    }
  }

  // Check if a medicine is low in stock and show notification if needed
  Future<void> checkLowStockAndNotify(
    String medicineName,
    int currentStock,
  ) async {
    var isEnabled = await SessionManager.areNotificationsEnabled();
    if (!isEnabled) return;
    var threshold = int.parse(await SessionManager.getLowStockThreshold());
    if (currentStock <= threshold) {
      await showDirectNotification(
        title: 'Low Stock Alert',
        body: '$medicineName is running low! Only $currentStock left.',
      );
    }
  }

  // Cancel all scheduled notifications
  Future<void> _cancelScheduledNotifications() async {
    await _notifications.cancel(_scheduledNotificationId);
  }

  // Cancel all notifications and ensure channels are properly set up
  Future<void> cancelAllNotifications() async {
    try {
      // Cancel all pending notifications
      await _notifications.cancelAll();
      
      // Recreate notification channels to ensure they're properly set up
      await _createNotificationChannels();
      
      // Re-initialize the notification plugin to ensure clean state
      await _initializeNotifications();
    } catch (e) {
      print('Error in cancelAllNotifications: $e');
      // If there's an error, try to reinitialize the notification service
      await initialize();
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings({
    required bool enabled,
    TimeOfDay? scheduledTime,
  }) async {
    if(!enabled){
      await cancelAllNotifications();
    } else if (enabled && scheduledTime != null) {
      await scheduleDailyNotification(scheduledTime);
    } else {
      await _cancelScheduledNotifications();
    }
  }

}

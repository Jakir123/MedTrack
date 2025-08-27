import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:med_track/utils/session_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const channelId = 'medicine_reminders';
  static const channelName = 'Medicine Reminders';
  static const channelDescription = 'Notifications for low stock items';
  static const alarmId = 111;

  static Future<void> initialize() async {
    tz.initializeTimeZones();
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

    // Create notification channel
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        showBadge: true,
      ),
    );

    // Request notification permission
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          throw Exception('Notification permission is required');
        }
      }
    }
  }


  static Future<void> _showNotification(String title, String description, int id) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      enableLights: true,
      color: const Color(0xFF2196F3),
      ticker: 'Daily Reminder',
      groupKey: channelId,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      description,
      notificationDetails,
    );
  }


  static Future<bool> checkAndScheduleReminderUsingAlarmManager(
      TimeOfDay time,
      ) async {
    try {
      // First check exact alarms permission
      if (!Platform.isAndroid) {
        return false;
      }

      // Then check notification permission
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          throw Exception('Notification permission is required');
        }
      }

      // final location = tz.getLocation(await FlutterTimezone.getLocalTimezone());
      // // Convert dueDateTime to local time zone while preserving the time
      // final scheduledTime = tz.TZDateTime(
      //   location,
      //   dueDateTime.year,
      //   dueDateTime.month,
      //   dueDateTime.day,
      //   dueDateTime.hour,
      //   dueDateTime.minute,
      // );

      // Schedule the notification
      await _scheduleDailyAlarm(time);

      return true;
    } catch (e) {
      print('Error scheduling notification: $e');
      return false;
    }
  }

  static Future<void> _scheduleAlarm(
      DateTime dateTime,
      int alarmId
      ) async {
    print("Alarm Time: $dateTime");
    var status = await AndroidAlarmManager.oneShotAt(
      dateTime,
      alarmId,
      _alarmCallback,
      exact: false,
      wakeup: true,
    );
  }

  static Future<void> _scheduleDailyAlarm(TimeOfDay time) async {
    try {
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

      print('📅 Setting up daily alarm for');
      print('⏰ First alarm at: $scheduledDate');

      // Schedule the periodic alarm
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),  // Repeat every day
        alarmId,                  // Use the same ID for this alarm
        _alarmCallback,           // Your callback function
        startAt: scheduledDate,   // First trigger time
        exact: true,              // Exact timing
        wakeup: true,             // Wake up device if needed
        rescheduleOnReboot: true, // Reschedule after device reboot
      );

      print('✅ Daily alarm scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling daily alarm: $e');
      rethrow;
    }
  }

  static Future<void> _initializeFirebase() async {
    try {
      // Initialize Firebase for the current isolate if not already done
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      print('Error initializing Firebase in isolate: $e');
      rethrow; // Re-throw to handle it in the calling function
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _alarmCallback(int id) async {
    print("Alarm Triggered!");
    final title = "Medication Reminder";
    final description = "Time to check your out of stock medications and call the representative!";
    
    // Initialize Firebase before showing notification
    await _initializeFirebase();
    
    await _showNotification(title, description, id);
  }

  static Future<void> cancelAlarm() async {
    try {
      final success = await AndroidAlarmManager.cancel(alarmId);
      print(success ? "Alarm cancelled successfully" : "Failed to cancel alarm");
    } catch (e) {
      print('Error cancelling alarm: $e');
    }
  }


  // Check if a medicine is low in stock and show notification if needed
  static Future<void> checkLowStockAndNotify(
      String medicineName,
      int currentStock,
      ) async {
    var isEnabled = await SessionManager.areNotificationsEnabled();
    if (!isEnabled) return;
    var threshold = int.parse(await SessionManager.getLowStockThreshold());
    if (currentStock <= threshold) {
      await _showNotification("Low Stock Alert","$medicineName is running low! Only $currentStock left.",0);
    }
  }

}

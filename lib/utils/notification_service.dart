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
  static const channelId = 'todo_reminders';
  static const channelName = 'Todo Reminders';
  static const channelDescription = 'Notifications for upcoming todos';

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


  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }


  static Future<void> showNotification(String title, String description, int id) async {
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
      ticker: 'Todo Reminder',
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
    try {
    final docId = await SessionManager.getDocId(id);
    var user = FirebaseAuth.instance.currentUser;
    
    // Only proceed with Firebase operations if user is authenticated
    if (user != null) {
      bool isAuthenticated = !user.isAnonymous;
      try {
        await FirebaseService().updateTodoReminderStatus(
          userId: user.uid,
          docId: docId,
          reminder: false,
          isAnonymous: !isAuthenticated,
        );
      } catch (e) {
        print('Error updating Firebase status: $e');
      }
    }
  } catch (e) {
    print('Error in notification handling: $e');
  } finally {
    // Always clean up the notification info
    await removeNotificationInfo(id);
  }
  }


  static Future<bool> checkAndScheduleReminderUsingAlarmManager(
      BuildContext context,
      String title,
      String description,
      DateTime dueDateTime,
      String id,
      ) async {
    try {
      // First check exact alarms permission
      if (!Platform.isAndroid) {
        return false;
      }

      // final androidInfo = await DeviceInfoPlugin().androidInfo;
      // final sdkInt = androidInfo.version.sdkInt;
      //
      // if (sdkInt >= 31) { // Android 12 and above
      //   final hasPermission = await Permission.scheduleExactAlarm.isGranted;
      //   if (!hasPermission) {
      //     await showModalBottomSheet(
      //       context: context,
      //       isScrollControlled: true,
      //       shape: const RoundedRectangleBorder(
      //         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      //       ),
      //       builder: (context) => const PermissionScreen(),
      //     );
      //     return false;
      //   }
      // }

      // Then check notification permission
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          throw Exception('Notification permission is required');
        }
      }

      // Get the local time zone
      final localTimeZone = tz.local;
      final location = tz.getLocation(await FlutterTimezone.getLocalTimezone());
      // Convert dueDateTime to local time zone while preserving the time
      final scheduledTime = tz.TZDateTime(
        location,
        dueDateTime.year,
        dueDateTime.month,
        dueDateTime.day,
        dueDateTime.hour,
        dueDateTime.minute,
      );

      // Schedule the notification
      await scheduleAlarm(scheduledTime, title, description,id, id.hashCode);

      return true;
    } catch (e) {
      print('Error scheduling notification: $e');
      return false;
    }
  }

  static Future<void> scheduleAlarm(
      DateTime dateTime,
      String title,
      String description,
      String docId,
      int alarmId
      ) async {
    print("Alarm Time: $dateTime");
    var status = await AndroidAlarmManager.oneShotAt(
      dateTime,
      alarmId,
      alarmCallback,
      exact: false,
      wakeup: true,
    );
    if (status) {
      SessionManager.setDocId(docId, alarmId);
      SessionManager.setNotificationTitle(title, alarmId);
      SessionManager.setNotificationDescription(description, alarmId);
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
  static Future<void> alarmCallback(int id) async {
    print("Alarm Triggered!");
    final title = await SessionManager.getNotificationTitle(id);
    final description = await SessionManager.getNotificationDescription(id);
    
    // Initialize Firebase before showing notification
    await _initializeFirebase();
    
    await NotificationService.showNotification(title, description, id);
  }

  static Future<void> cancelAlarm(int id) async {
    try {
      final success = await AndroidAlarmManager.cancel(id);
      print(success ? "Alarm $id cancelled successfully" : "Failed to cancel alarm $id");
      if (success) {
        removeNotificationInfo(id);
      }
    } catch (e) {
      print('Error cancelling alarm: $e');
    }
  }

  static Future<void> removeNotificationInfo(int id) async {
    await SessionManager.removeNotification(id);
  }
}

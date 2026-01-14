import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/notification_service.dart';
import '../../utils/notification_service_new.dart';
import '../../utils/session_manager.dart';

class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({Key? key}) : super(key: key);

  @override
  _NotificationSettingsSheetState createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  TimeOfDay _notificationTime = TimeOfDay.now();
  final TextEditingController _thresholdController = TextEditingController();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final isNotificationSettingEnabled = await SessionManager.areNotificationsEnabled();
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (mounted) {
        setState(() {
          _notificationsEnabled = status.isGranted && isNotificationSettingEnabled;
        });
      }
    } else if (Platform.isIOS) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final settings = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      if (settings != null && mounted) {
        setState(() {
          _notificationsEnabled = settings.isEnabled && isNotificationSettingEnabled;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final notificationTime = await SessionManager.getDailyNotificationTime();
      final hour = notificationTime.split(':').first;
      final minute = notificationTime.split(':').last;
      final threshold = await SessionManager.getLowStockThreshold();

      if (mounted) {
        setState(() {
          _notificationTime = TimeOfDay(hour: int.parse(hour), minute: int.parse(minute));
          _thresholdController.text = threshold.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // Set default values if there's an error
      if (mounted) {
        setState(() {
          _notificationTime = const TimeOfDay(hour: 9, minute: 0);
          _thresholdController.text = '5';
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    await SessionManager.setDailyNotificationTime("${_notificationTime.hour}:${_notificationTime.minute}");
    await SessionManager.setLowStockThreshold(_thresholdController.text);
    await SessionManager.setNotificationsEnabled(_notificationsEnabled);

    if (_notificationsEnabled) {
      // await NotificationServiceV2().updateNotificationSettings(
      //   enabled: true,
      //   scheduledTime: TimeOfDay(hour: _notificationTime.hour, minute: _notificationTime.minute),
      // );
      await NotificationService.checkAndScheduleReminderUsingAlarmManager(TimeOfDay(hour: _notificationTime.hour, minute: _notificationTime.minute));
    } else {
      // Cancel all notifications if disabled
      // await NotificationServiceV2().updateNotificationSettings(
      //   enabled: false,
      // );
      await NotificationService.cancelAlarm();
    }
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_notificationsEnabled 
          ? 'Notification settings saved' 
          : 'Notifications disabled')),
      );
    }
  }

  Future<void> _scheduleDailyNotification() async {

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      _notificationTime.hour,
      _notificationTime.minute,
    );

    // If the time has already passed for today, schedule for next day
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // TODO: Implement actual stock check logic here
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'low_stock_channel',
      'Low Stock Notifications',
      channelDescription: 'Notifications for low stock items',
      importance: Importance.high,
      priority: Priority.high,
    );

    const platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // await _flutterLocalNotificationsPlugin.zonedSchedule(
    //   0,
    //   'Low Stock Alert',
    //   'Some medicines are running low on stock!',
    //   scheduledDate,
    //   platformChannelSpecifics,
    //   androidAllowWhileIdle: true,
    //   uiLocalNotificationDateInterpretation:
    //       UILocalNotificationDateInterpretation.absoluteTime,
    //   matchDateTimeComponents: DateTimeComponents.time,
    //   payload: 'low_stock_notification',
    // );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Notification Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Notification Toggle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enable Notifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                FutureBuilder<bool>(
                  future: _getNotificationPermissionStatus(),
                  builder: (context, snapshot) {
                    final hasPermission = snapshot.data ?? false;
                    return Switch(
                      value: _notificationsEnabled && hasPermission,
                      onChanged: (bool value) async {
                        if (value) {
                          final granted = await _requestNotificationPermission();
                          if (granted) {
                            await SessionManager.setNotificationsEnabled(true);
                            if (mounted) {
                              setState(() {
                                _notificationsEnabled = true;
                              });
                            }
                          } else {
                            // Show a message that notification permission is required
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification permission is required to enable notifications'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              // Update the switch to reflect the actual state
                              final currentState = await SessionManager.areNotificationsEnabled();
                              if (mounted) {
                                setState(() {
                                  _notificationsEnabled = currentState;
                                });
                              }
                            }
                          }
                        } else {
                          await SessionManager.setNotificationsEnabled(false);
                          if (mounted) {
                            setState(() {
                              _notificationsEnabled = false;
                            });
                          }
                        }
                      },
                      activeColor: theme.primaryColor,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Daily Notification Time
          Opacity(
            opacity: _notificationsEnabled ? 1.0 : 0.6,
            child: AbsorbPointer(
              absorbing: !_notificationsEnabled,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Notification Time',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _notificationsEnabled ? () => _selectTime(context) : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _notificationTime.format(context),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.access_time, color: _notificationsEnabled ? theme.primaryColor : Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Low Stock Threshold
          Opacity(
            opacity: _notificationsEnabled ? 1.0 : 0.6,
            child: AbsorbPointer(
              absorbing: !_notificationsEnabled,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Low Stock Threshold',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _thresholdController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: _notificationsEnabled ? null : Colors.grey.shade100,
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get notified when stock falls below this number',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Settings'),
          ),
          const SizedBox(height: 16),
          ],
        ),
    );
  }

  Future<bool> _getNotificationPermissionStatus() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final settings = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return false;
  }

  Future<bool> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // Open app settings if permission is permanently denied
        await openAppSettings();
      }
      return false;
    } else if (Platform.isIOS) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return false;
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }
}

// Helper function to show the bottom sheet
void showNotificationSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const NotificationSettingsSheet(),
  );
}

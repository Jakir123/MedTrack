import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notificationTime = await SessionManager.getDailyNotificationTime();
    final hour = notificationTime.split(':').first;
    final minute = notificationTime.split(':').last;
    final threshold = await SessionManager.getLowStockThreshold();

    setState(() {
      _notificationTime = TimeOfDay(hour: int.parse(hour), minute: int.parse(minute));
      _thresholdController.text = threshold.toString();
    });
  }

  Future<void> _saveSettings() async {
    await SessionManager.setDailyNotificationTime("${_notificationTime.hour}:${_notificationTime.minute}");
    await SessionManager.setLowStockThreshold(_thresholdController.text);

    // Schedule the notification with new time
    await _scheduleDailyNotification();
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved')),
      );
    }
  }

  Future<void> _scheduleDailyNotification() async {
    await _flutterLocalNotificationsPlugin.cancelAll();

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
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Daily Notification Time', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              _notificationTime.format(context),
              style: const TextStyle(fontSize: 16),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: () => _selectTime(context),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  'Low Stock Threshold',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _thresholdController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'You will be notified when any medicine stock falls below this number',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
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

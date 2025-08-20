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
  bool _notificationsEnabled = true;
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
    final isEnabled = await SessionManager.areNotificationsEnabled();

    setState(() {
      _notificationTime = TimeOfDay(hour: int.parse(hour), minute: int.parse(minute));
      _thresholdController.text = threshold.toString();
      _notificationsEnabled = isEnabled;
    });
  }

  Future<void> _saveSettings() async {
    await SessionManager.setDailyNotificationTime("${_notificationTime.hour}:${_notificationTime.minute}");
    await SessionManager.setLowStockThreshold(_thresholdController.text);
    await SessionManager.setNotificationsEnabled(_notificationsEnabled);

    if (_notificationsEnabled) {
      // Schedule the notification with new time if notifications are enabled
      await _scheduleDailyNotification();
    } else {
      // Cancel all notifications if disabled
      await _flutterLocalNotificationsPlugin.cancelAll();
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
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeColor: theme.primaryColor,
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SessionManager{

  // user info
  static Future<String> getUserName() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString("userName") ?? "";
  }
  static Future<void> setUserName(String userName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("userName", userName);
  }

  // Onboarding flag
  static Future<bool> isOnboardingCompleted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', completed);
  }

  // Theme mode
  static Future<ThemeMode> getThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mode = prefs.getString('theme_mode');
    if (mode == 'dark') return ThemeMode.dark;
    if (mode == 'light') return ThemeMode.light;
    return ThemeMode.light;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String modeStr = mode == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString('theme_mode', modeStr);
  }

  // notification info
  static Future<String> getNotificationTitle(int id) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('alarm_${id}_title') ?? "";
  }
  static Future<String> getNotificationDescription(int id) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('alarm_${id}_description') ?? "";
  }
  static Future<void> setNotificationTitle(String title,int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('alarm_${id}_title', title);
  }
  static Future<void> setNotificationDescription(String description,int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('alarm_${id}_description', description);
  }

  static Future<void> setDocId(String docId,int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('alarm_${id}_docId', docId);
  }
  static Future<String> getDocId(int id) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('alarm_${id}_docId') ?? "";
  }

  static Future<void> removeNotification(int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var docIdKey = 'alarm_${id}_docId';
    var titleKey = 'alarm_${id}_title';
    var descriptionKey = 'alarm_${id}_description';
    if (prefs.containsKey(titleKey)) {
      await prefs.remove(titleKey);
    }
    if (prefs.containsKey(descriptionKey)) {
      await prefs.remove(descriptionKey);
    }
    if (prefs.containsKey(docIdKey)) {
      await prefs.remove(docIdKey);
    }
  }
}
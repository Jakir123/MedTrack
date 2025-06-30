import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:med_track/features/authentication/auth_screen.dart';
import 'package:med_track/features/authentication/auth_viewmodel.dart';
import 'package:med_track/features/companies/company_viewmodel.dart';
import 'package:med_track/features/home_screen.dart';
import 'package:med_track/features/onboarding_screen.dart';
import 'package:med_track/utils/notification_service.dart';
import 'package:med_track/utils/session_manager.dart';
import 'package:med_track/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones(); // <-- REQUIRED for scheduling
  await NotificationService.initialize();
  await AndroidAlarmManager.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;
  bool _initialized = false;
  bool _onboardingCompleted = false;
  bool _isLoggedIn = false;
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _initApp();
    _setupAuthListener();
  }


  void _setupAuthListener() {
    User? _previousUser;

    _authSubscription = FirebaseAuth.instance.userChanges().distinct().listen((User? user) async {
      // Skip if the user reference hasn't changed
      if (_previousUser == user) return;

      if (user != null) {
        // Only reload if the user was previously null or if the email verification status might have changed
        if (_previousUser == null || _previousUser?.emailVerified != user.emailVerified) {
          await user.reload();
          final updatedUser = FirebaseAuth.instance.currentUser;
          _previousUser = updatedUser;

          if (mounted) {
            setState(() {
              _isLoggedIn = updatedUser != null &&
                  !updatedUser.isAnonymous &&
                  updatedUser.emailVerified;
            });
          }
        }
      } else {
        _previousUser = null;
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }


  Future<void> _initApp() async {
    final themeMode = await SessionManager.getThemeMode();
    final onboardingCompleted = await SessionManager.isOnboardingCompleted();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      isDark = themeMode == ThemeMode.dark;
      _onboardingCompleted = onboardingCompleted;
      _isLoggedIn = user != null && !user.isAnonymous;
      _initialized = true;
    });
  }

  void toggleTheme() async {
    setState(() {
      isDark = !isDark;
    });
    await SessionManager.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void onboardingCompleted() async{
    await SessionManager.setOnboardingCompleted(true);
    setState(() {
      _onboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        ChangeNotifierProvider<CompanyViewModel>(create: (_) => CompanyViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Todo App',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: Builder(
          builder: (context) {

            if (!_initialized) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!_onboardingCompleted) {
              return OnboardingScreen(
                onFinish: onboardingCompleted,
                isDark: isDark,
              );
            }

            // Check authentication status
            if (!_isLoggedIn) {
              return AuthScreen(
                isDark: isDark,
              );
            }

            return HomeScreen(
              isDark: isDark,
              onThemeToggle: toggleTheme,
            );
          },
        ),
      ),
    );
  }
}

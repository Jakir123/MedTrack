import 'package:flutter/material.dart';
import 'colors.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: kLightPrimary,
  colorScheme: ColorScheme.light(
    primary: kLightPrimary,
    primaryContainer: kLightPrimaryVariant,
    secondary: kLightSecondary,
    tertiary: kLightTertiary,
    surface: kLightBackground,  // Replaced background with surface
    onSurface: kLightTextOnBg,  // Replaced onBackground with onSurface
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onTertiary: Colors.black,
    error: kLightError,
    onError: Colors.white,
    surfaceContainerHighest: kLightSurface,  // Replaced surfaceVariant with surfaceContainerHighest
  ),
  scaffoldBackgroundColor: kLightBackground,
  cardColor: kLightSurface,
  appBarTheme: AppBarTheme(
    backgroundColor: kLightPrimary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: kLightSurface,
    selectedItemColor: kLightPrimary,
    unselectedItemColor: kLightTextSecondary,
    selectedIconTheme: IconThemeData(color: kLightPrimary),
    unselectedIconTheme: IconThemeData(color: kLightTextSecondary),
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
    showUnselectedLabels: false,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kLightPrimary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kLightPrimary,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  textTheme: TextTheme(
    displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kLightTextOnBg),
    displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kLightTextOnBg),
    headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kLightTextOnBg),
    titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kLightTextOnBg),
    bodyLarge: TextStyle(fontSize: 16, color: kLightTextOnBg.withOpacity(0.9)),
    bodyMedium: TextStyle(fontSize: 14, color: kLightTextSecondary, height: 1.5),
    labelLarge: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
  ),
  iconTheme: const IconThemeData(color: kLightTextOnBg),
  dividerColor: Colors.grey.shade200,
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: kDarkPrimary,
  colorScheme: ColorScheme.dark(
    primary: kDarkPrimary,
    primaryContainer: kDarkPrimaryVariant,
    secondary: kDarkSecondary,
    tertiary: kDarkTertiary,
    surface: kDarkBackground,  // Replaced background with surface
    onSurface: kDarkTextOnBg,  // Replaced onBackground with onSurface
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onTertiary: Colors.black,
    error: kDarkError,
    onError: Colors.black,
    surfaceContainerHighest: kDarkSurface,  // Replaced surfaceVariant with surfaceContainerHighest
  ),
  scaffoldBackgroundColor: kDarkBackground,
  cardColor: kDarkSurface,
  appBarTheme: AppBarTheme(
    backgroundColor: kDarkSurface,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: kDarkTextOnBg,
    ),
    iconTheme: IconThemeData(color: kDarkTextOnBg),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: kDarkSurface,
    selectedItemColor: kDarkPrimary,
    unselectedItemColor: kDarkTextSecondary,
    selectedIconTheme: IconThemeData(color: kDarkPrimary),
    unselectedIconTheme: IconThemeData(color: kDarkTextSecondary),
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
    showUnselectedLabels: false,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    color: kDarkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kDarkPrimary,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kDarkPrimary,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade900,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kDarkTextOnBg),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kDarkTextOnBg),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kDarkTextOnBg),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kDarkTextOnBg),
    bodyLarge: TextStyle(fontSize: 16, color: kDarkTextOnBg.withOpacity(0.9)),
    bodyMedium: TextStyle(fontSize: 14, color: kDarkTextSecondary, height: 1.5),
    labelLarge: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
  ),
  iconTheme: IconThemeData(color: kDarkTextOnBg),
  dividerColor: Colors.grey.shade800,
);

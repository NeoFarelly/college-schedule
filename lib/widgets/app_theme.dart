import 'package:flutter/material.dart';

// Палитра: черный AMOLED, нейтральные поверхности, один янтарный акцент
// для кабинета следующей пары и индикатора идущей пары.
const Color kBackground = Color(0xFF000000);
const Color kSurface = Color(0xFF141414);
const Color kSurfaceHigh = Color(0xFF1E1E1E);
const Color kBorder = Color(0xFF2A2A2A);
const Color kTextPrimary = Color(0xFFF2F2F2);
const Color kTextSecondary = Color(0xFFA3A3A3);
const Color kAccent = Color(0xFFFFB000);
const Color kError = Color(0xFFFF6B6B);

// Переходы между экранами без анимации: требование к скорости интерфейса.
class InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: kAccent,
      onPrimary: Colors.black,
      secondary: kAccent,
      onSecondary: Colors.black,
      surface: kBackground,
      onSurface: kTextPrimary,
      secondaryContainer: kSurfaceHigh,
      onSecondaryContainer: kTextPrimary,
      outline: kBorder,
      error: kError,
      onError: Colors.black,
    ),
  );
  // Шрифт системный (Roboto/SF Pro): ноль ассетов, мгновенный первый кадр.
  return base.copyWith(
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      labelStyle: const TextStyle(color: kTextSecondary),
      hintStyle: const TextStyle(color: Color(0xFF8A8A8A)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.black,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimary,
        side: const BorderSide(color: kBorder),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kSurfaceHigh,
      contentTextStyle: TextStyle(color: kTextPrimary, fontSize: 14),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kAccent),
    dividerColor: kBorder,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: InstantPageTransitionsBuilder(),
        TargetPlatform.iOS: InstantPageTransitionsBuilder(),
      },
    ),
  );
}
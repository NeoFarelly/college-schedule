import 'dart:ui';

import 'package:flutter/material.dart';

// Направление владельца: iOS liquid glass, полный override R-10 (стекло везде).
// Обои-подложка нужны материалу стекла для преломления; акцент один, iOS blue.
const Color kBackground = Color(0xFF070B18);
const Color kTextPrimary = Color(0xFFF5F7FA);
const Color kTextSecondary = Color(0xFFC9CFDC);
const Color kAccent = Color(0xFF0A84FF);
const Color kError = Color(0xFFFFC9C2);

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

ThemeData buildGlassTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: kAccent,
      onPrimary: Colors.white,
      secondary: kAccent,
      onSecondary: Colors.white,
      surface: kBackground,
      onSurface: kTextPrimary,
      secondaryContainer: Colors.white,
      onSecondaryContainer: Colors.black,
      outline: Color(0x33FFFFFF),
      error: kError,
      onError: Colors.white,
    ),
  );
  // Шрифт системный (SF Pro/Roboto): нативный iOS-вид и ноль ассетов.
  return base.copyWith(
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
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
      fillColor: const Color(0x14FFFFFF),
      labelStyle: const TextStyle(color: kTextSecondary),
      hintStyle: const TextStyle(color: Color(0xFFC9CFDC)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x29FFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x29FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kError, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimary,
        backgroundColor: const Color(0x14FFFFFF),
        side: const BorderSide(color: Color(0x29FFFFFF)),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xE61C2333),
      contentTextStyle: TextStyle(color: kTextPrimary, fontSize: 14),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kAccent),
    dividerColor: const Color(0x29FFFFFF),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: InstantPageTransitionsBuilder(),
        TargetPlatform.iOS: InstantPageTransitionsBuilder(),
      },
    ),
  );
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.tint = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: tint),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: tint + 0.10),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.03),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class Wallpaper extends StatelessWidget {
  const Wallpaper({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: kBackground),
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF27407F).withValues(alpha: 0.25),
                  const Color(0xFF27407F).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -100,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0E3B43).withValues(alpha: 0.28),
                  const Color(0xFF0E3B43).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
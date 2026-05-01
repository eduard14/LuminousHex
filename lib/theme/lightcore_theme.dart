import 'package:flutter/material.dart';

import '../widgets/lightcore_screen_transition.dart';
import 'lightcore_palette.dart';

ThemeData buildLightcoreTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: LightcorePalette.aether,
        brightness: Brightness.dark,
      ).copyWith(
        primary: LightcorePalette.aether,
        secondary: LightcorePalette.ember,
        tertiary: LightcorePalette.solar,
        surface: LightcorePalette.panel,
        onSurface: LightcorePalette.mist,
        onSurfaceVariant: LightcorePalette.mist.withValues(alpha: 0.78),
        outline: LightcorePalette.stroke,
        outlineVariant: LightcorePalette.stroke.withValues(alpha: 0.56),
        surfaceContainer: LightcorePalette.panel,
        surfaceContainerHigh: LightcorePalette.panelRaised,
        surfaceContainerHighest: LightcorePalette.panelRaised,
        secondaryContainer: LightcorePalette.panelRaised,
        onSecondaryContainer: LightcorePalette.layer2,
      );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: LightcorePageTransitionsBuilder(),
        TargetPlatform.fuchsia: LightcorePageTransitionsBuilder(),
        TargetPlatform.iOS: LightcorePageTransitionsBuilder(),
        TargetPlatform.linux: LightcorePageTransitionsBuilder(),
        TargetPlatform.macOS: LightcorePageTransitionsBuilder(),
        TargetPlatform.windows: LightcorePageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: LightcorePalette.mist,
      elevation: 0,
      centerTitle: false,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: LightcorePalette.layer2),
    ),
    cardTheme: CardThemeData(
      color: LightcorePalette.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: LightcorePalette.stroke, width: 1.2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: LightcorePalette.panel.withValues(alpha: 0.9),
      indicatorColor: LightcorePalette.aether.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: const BorderSide(color: LightcorePalette.stroke),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: LightcorePalette.panelRaised,
      selectedColor: LightcorePalette.aether.withValues(alpha: 0.18),
      side: const BorderSide(color: LightcorePalette.stroke),
      labelStyle: const TextStyle(
        color: LightcorePalette.mist,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: const TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        height: 0.96,
        color: LightcorePalette.mist,
      ),
      headlineMedium: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: LightcorePalette.mist,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: LightcorePalette.mist,
      ),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: LightcorePalette.mist,
      ),
      titleMedium: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: LightcorePalette.mist,
      ),
      titleSmall: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: LightcorePalette.mist,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.4,
        color: LightcorePalette.mist,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: LightcorePalette.mist.withValues(alpha: 0.86),
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        height: 1.35,
        color: LightcorePalette.mist.withValues(alpha: 0.76),
      ),
      labelLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: LightcorePalette.mist,
      ),
      labelMedium: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: LightcorePalette.mist,
      ),
      labelSmall: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: LightcorePalette.mist.withValues(alpha: 0.78),
      ),
    ),
  );
}

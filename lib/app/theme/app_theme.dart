import 'package:flutter/material.dart';

import '../settings/app_preferences.dart';

class AppTheme {
  static const _slideTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData light(AppPreferences preferences) {
    return _build(preferences, Brightness.light);
  }

  static ThemeData dark(AppPreferences preferences) {
    return _build(preferences, Brightness.dark);
  }

  static ThemeData _build(AppPreferences preferences, Brightness brightness) {
    final colorScheme = _buildColorScheme(preferences, brightness);
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      visualDensity: preferences.compactMode
          ? const VisualDensity(horizontal: -1, vertical: -1)
          : VisualDensity.standard,
      pageTransitionsTheme: _slideTransitionsTheme,
    );
    final textTheme = _buildTextTheme(
      baseTheme.textTheme,
      preferences: preferences,
      colorScheme: colorScheme,
    );
    final cornerRadius = preferences.compactMode ? 22.0 : 30.0;
    final outlinedRadius = preferences.compactMode ? 18.0 : 22.0;
    final scaffoldBackground = brightness == Brightness.light
        ? _mix(colorScheme.surface, colorScheme.primary, 0.03)
        : const Color(0xFF091215);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          side: BorderSide(
            color: preferences.highContrast
                ? colorScheme.outline
                : colorScheme.outlineVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        dense: preferences.compactMode,
        contentPadding: EdgeInsets.symmetric(
          horizontal: preferences.compactMode ? 16 : 18,
          vertical: preferences.compactMode ? 4 : 6,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerLow,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: preferences.compactMode ? 14 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(outlinedRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(outlinedRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(outlinedRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerLow,
        indicatorColor: _mix(
          colorScheme.primaryContainer,
          colorScheme.primary,
          0.12,
        ),
        height: preferences.compactMode ? 72 : 78,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle();
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerLow,
        indicatorColor: _mix(
          colorScheme.primaryContainer,
          colorScheme.primary,
          0.12,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return brightness == Brightness.light
              ? Colors.white
              : colorScheme.surfaceContainerHighest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.14),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        trackHeight: preferences.compactMode ? 4 : 5,
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        labelStyle: textTheme.labelLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(outlinedRadius),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colorScheme.primary
                : brightness == Brightness.light
                ? Colors.white
                : colorScheme.surfaceContainerLow;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: preferences.compactMode ? 8 : 10,
              vertical: preferences.compactMode ? 10 : 12,
            ),
          ),
        ),
      ),
    );
  }

  static ColorScheme _buildColorScheme(
    AppPreferences preferences,
    Brightness brightness,
  ) {
    final base = ColorScheme.fromSeed(
      seedColor: preferences.themePreset.seedColor,
      brightness: brightness,
    );
    if (!preferences.highContrast) {
      return base;
    }

    return base.copyWith(
      outline: _mix(base.outline, base.onSurface, 0.26),
      outlineVariant: _mix(base.outlineVariant, base.onSurface, 0.18),
      primaryContainer: _mix(base.primaryContainer, base.primary, 0.12),
      secondaryContainer: _mix(base.secondaryContainer, base.secondary, 0.1),
      surfaceContainerHighest: _mix(
        base.surfaceContainerHighest,
        base.onSurface,
        brightness == Brightness.light ? 0.05 : 0.1,
      ),
    );
  }

  static TextTheme _buildTextTheme(
    TextTheme base, {
    required AppPreferences preferences,
    required ColorScheme colorScheme,
  }) {
    final family = preferences.fontPreset.fontFamily;
    final themed = base.apply(
      fontFamily: family,
      displayColor: colorScheme.onSurface,
      bodyColor: colorScheme.onSurface,
    );
    final letterSpacing = switch (preferences.fontPreset) {
      AppFontPreset.system => 0.0,
      AppFontPreset.serif => 0.12,
      AppFontPreset.mono => 0.18,
    };

    return themed.copyWith(
      headlineLarge: _scale(
        themed.headlineLarge,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      headlineMedium: _scale(
        themed.headlineMedium,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      headlineSmall: _scale(
        themed.headlineSmall,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      titleLarge: _scale(
        themed.titleLarge,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      titleMedium: _scale(
        themed.titleMedium,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      titleSmall: _scale(
        themed.titleSmall,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      bodyLarge: _scale(
        themed.bodyLarge,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      bodyMedium: _scale(
        themed.bodyMedium,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      bodySmall: _scale(
        themed.bodySmall,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      labelLarge: _scale(
        themed.labelLarge,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      labelMedium: _scale(
        themed.labelMedium,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
      labelSmall: _scale(
        themed.labelSmall,
        preferences.fontScale,
        letterSpacing: letterSpacing,
      ),
    );
  }

  static TextStyle? _scale(
    TextStyle? style,
    double factor, {
    required double letterSpacing,
  }) {
    if (style == null) {
      return null;
    }
    return style.copyWith(
      fontSize: (style.fontSize ?? 14) * factor,
      letterSpacing: (style.letterSpacing ?? 0) + letterSpacing,
    );
  }

  static Color _mix(Color base, Color tint, double amount) {
    return Color.lerp(base, tint, amount) ?? base;
  }
}

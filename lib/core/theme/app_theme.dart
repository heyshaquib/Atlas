/// Atlas Theme System
/// Material 3 with dynamic color, AMOLED override, custom typography & shapes.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Seed Color ───────────────────────────────────────────

const Color kSeedColor = Color(0xFF3D5A80); // Slate blue

// ─── Custom Color Roles ───────────────────────────────────

const Color kFavoriteColor = Color(0xFFFFB300); // Amber
const Color kDeadLinkColor = Color(0xFFD32F2F); // Error red
const Color kReadLaterColor = Color(0xFF7C4DFF); // Deep purple

// ─── AMOLED Override ──────────────────────────────────────

ColorScheme toAmoled(ColorScheme scheme) {
  return scheme.copyWith(
    surface: Colors.black,
    surfaceContainerLowest: Colors.black,
    surfaceContainerLow: const Color(0xFF0A0A0A),
    surfaceContainer: const Color(0xFF0F0F0F),
    surfaceContainerHigh: const Color(0xFF141414),
    surfaceContainerHighest: const Color(0xFF1A1A1A),
  );
}

// ─── Shape Tokens ─────────────────────────────────────────

const ShapeBorderTokens kShapeTokens = ShapeBorderTokens();

class ShapeBorderTokens {
  const ShapeBorderTokens();

  /// 4dp — chips
  BorderRadius get extraSmall => BorderRadius.circular(4);

  /// 8dp — cards
  BorderRadius get small => BorderRadius.circular(8);

  /// 12dp — dialogs
  BorderRadius get medium => BorderRadius.circular(12);

  /// 16dp — sheet corners
  BorderRadius get large => BorderRadius.circular(16);

  /// 28dp — FAB
  BorderRadius get extraLarge => BorderRadius.circular(28);
}

// ─── Typography ───────────────────────────────────────────

TextTheme buildTextTheme(TextTheme base) {
  final jakartaSans = GoogleFonts.plusJakartaSansTextTheme(base);
  final outfit = GoogleFonts.outfitTextTheme(base);

  return jakartaSans.copyWith(
    // Use Outfit for numeric displays
    displayLarge: outfit.displayLarge,
    displayMedium: outfit.displayMedium,
    displaySmall: outfit.displaySmall,
    headlineLarge: outfit.headlineLarge,
    headlineMedium: outfit.headlineMedium,
    headlineSmall: outfit.headlineSmall,
    // Jakarta Sans for body/UI
    titleLarge: jakartaSans.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: jakartaSans.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: jakartaSans.titleSmall?.copyWith(fontWeight: FontWeight.w500),
    bodyLarge: jakartaSans.bodyLarge,
    bodyMedium: jakartaSans.bodyMedium,
    bodySmall: jakartaSans.bodySmall,
    labelLarge: jakartaSans.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: jakartaSans.labelMedium,
    labelSmall: jakartaSans.labelSmall,
  );
}

/// Returns a TextStyle using Outfit font (for numeric values, badges, counters).
TextStyle outfitStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
}) {
  return GoogleFonts.outfit(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

// ─── Theme Builder ────────────────────────────────────────

ThemeData buildAtlasTheme({
  required Brightness brightness,
  ColorScheme? dynamicScheme,
  bool isAmoled = false,
}) {
  // Determine color scheme
  ColorScheme colorScheme;
  if (dynamicScheme != null) {
    colorScheme = dynamicScheme;
  } else {
    colorScheme = ColorScheme.fromSeed(
      seedColor: kSeedColor,
      brightness: brightness,
    );
  }

  // Apply AMOLED if needed
  if (isAmoled && brightness == Brightness.dark) {
    colorScheme = toAmoled(colorScheme);
  }

  final textTheme = buildTextTheme(
    brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: brightness,
    textTheme: textTheme,

    // App bar
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    ),

    // Navigation bar
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          );
        }
        return textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );
      }),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: kShapeTokens.small,
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // Chips
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: kShapeTokens.extraSmall,
      ),
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: kShapeTokens.medium,
      ),
    ),

    // Bottom sheets
    bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: kShapeTokens.large.topLeft,
          topRight: kShapeTokens.large.topRight,
        ),
      ),
      showDragHandle: true,
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: kShapeTokens.extraLarge,
      ),
      elevation: 0,
      highlightElevation: 0,
    ),

    // Snack bar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: kShapeTokens.small,
      ),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: kShapeTokens.small,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Dividers
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 0.5,
    ),

    // Splash
    splashFactory: InkSparkle.splashFactory,

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
  );
}

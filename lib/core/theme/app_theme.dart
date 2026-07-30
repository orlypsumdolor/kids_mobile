import 'package:flutter/material.dart';

class AppTheme {
  // ── Core palette ──────────────────────────────────────────────
  static const Color navy = Color(0xFF0E3D8C); // primary
  static const Color navyDark = Color(0xFF0A2F6E); // primary pressed/hover
  static const Color green = Color(0xFF2E9E4F); // success / check-out accent
  static const Color greenDark = Color(0xFF24803F);
  static const Color magenta = Color(0xFFB8447F); // check-in scan accent
  static const Color yellow = Color(0xFFEFC212);
  static const Color blue = Color(0xFF1F4E9C);

  static const Color error = Color(0xFFC0392B);
  static const Color errorBg = Color(0xFFFDF3F2);
  static const Color errorBorder = Color(0xFFF2C9C4);

  // "Gap note" amber used for warnings and honest not-yet-live callouts.
  static const Color warningText = Color(0xFF8A5A00);
  static const Color warningTextStrong = Color(0xFFB26A00);
  static const Color warningBg = Color(0xFFFDF8EC);
  static const Color warningBorder = Color(0xFFE0B44A);

  static const Color successBg = Color(0xFFF2FAF4);
  static const Color successBorder = Color(0xFFD6E8DB);
  static const Color successText = Color(0xFF4A7A58);

  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF8A93A2);
  static const Color textTertiary = Color(0xFF5A6472);

  static const Color pageBackground = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color hairline = Color(0xFFE6EAF0);
  static const Color inputBorder = Color(0xFFDCE1E9);
  static const Color hoverFill = Color(0xFFF2F5F9);
  static const Color chipNeutralBg = Color(0xFFEDEFF3);

  // ── Age-group badges ──────────────────────────────────────────
  // Backend slugs (Child.ageGroup enum) → display label.
  // Toddlers 0–3, Jr. Kids 4–6, Primary 7–9, Pre-Teens 10–12.
  static const Map<String, String> _ageGroupLabels = {
    'toddlers': 'Toddlers',
    'preschool': 'Jr. Kids',
    'elementary': 'Primary',
    'preteens': 'Pre-Teens',
  };

  static const Map<String, AgeGroupBadge> _ageGroupBadges = {
    'toddlers': AgeGroupBadge(Color(0xFFF7E7F0), Color(0xFF8E2E63)),
    'preschool': AgeGroupBadge(Color(0xFFE6F5EA), Color(0xFF1F6E39)),
    'elementary': AgeGroupBadge(Color(0xFFE7EEFA), Color(0xFF0E3D8C)),
    'preteens': AgeGroupBadge(Color(0xFFFBF2D8), Color(0xFF7A5C00)),
  };

  /// Maps a raw backend age-group slug (e.g. "preschool") to its display
  /// label (e.g. "Jr. Kids"). Falls back to the raw value if unrecognized.
  static String ageGroupLabel(String ageGroup) {
    final key = ageGroup.trim().toLowerCase();
    return _ageGroupLabels[key] ?? ageGroup;
  }

  static AgeGroupBadge ageGroupBadge(String ageGroup) {
    final key = ageGroup.trim().toLowerCase();
    return _ageGroupBadges[key] ??
        const AgeGroupBadge(chipNeutralBg, textTertiary);
  }

  // ── Shape tokens ──────────────────────────────────────────────
  static const double radiusPill = 999;
  static const double radiusButton = 14;
  static const double radiusCard = 16;
  static const double radiusCardLarge = 20;
  static const double radiusTile = 24;

  // ── Typography ────────────────────────────────────────────────
  static const String fontFamily = 'Poppins';
  static const String monoFontFamily = 'IBM Plex Mono';

  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = navy,
    double letterSpacing = 0.6,
  }) {
    return TextStyle(
      fontFamily: monoFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static const _fallbackFonts = ['Helvetica', 'sans-serif'];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    fontFamilyFallback: _fallbackFonts,
    scaffoldBackgroundColor: pageBackground,
    colorScheme: const ColorScheme.light(
      primary: navy,
      onPrimary: Colors.white,
      secondary: green,
      onSecondary: Colors.white,
      tertiary: magenta,
      onTertiary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    ),

    // App shell header is a custom widget (AppShellHeader), not a stock
    // AppBar — the design's border/shadow can't be expressed via AppBarTheme.
    // This theme is kept as a sane fallback for any page still using AppBar.
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
        side: const BorderSide(color: hairline),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        disabledBackgroundColor: chipNeutralBg,
        disabledForegroundColor: const Color(0xFFA6AEBB),
        elevation: 0,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 26),
        side: const BorderSide(color: inputBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: navy,
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusButton),
        borderSide: const BorderSide(color: inputBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusButton),
        borderSide: const BorderSide(color: inputBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusButton),
        borderSide: const BorderSide(color: navy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusButton),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusButton),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),

    dividerTheme: const DividerThemeData(color: hairline, thickness: 1),

    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? green
            : const Color(0xFF3A3F49),
      ),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: textSecondary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
      bodySmall: TextStyle(fontSize: 12.5, color: textSecondary),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
  );

  static ThemeData darkTheme = lightTheme;
}

class AgeGroupBadge {
  final Color bg;
  final Color fg;

  const AgeGroupBadge(this.bg, this.fg);
}

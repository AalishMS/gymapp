import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color terminalBackground = Color(0xFF0D0D0D);
const Color terminalSurface = Color(0xFF1A1A1A);
const Color terminalBorder = Color(0xFF333333);
const Color terminalTextPrimary = Color(0xFFE0E0E0);
const Color terminalTextSecondary = Color(0xFF666666);
const Color terminalError = Color(0xFFFF4444);

ThemeData buildTheme(Color accent) {
  final isLightAccent = accent.computeLuminance() > 0.5;
  final onAccent = isLightAccent ? Colors.black : Colors.white;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: terminalBackground,
    colorScheme: ColorScheme.dark(
      primary: accent,
      secondary: accent,
      surface: terminalSurface,
      error: terminalError,
      onPrimary: onAccent,
      onSecondary: onAccent,
      onSurface: terminalTextPrimary,
      onError: Colors.white,
    ),
    textTheme: _buildTextTheme(accent),
    appBarTheme: AppBarTheme(
      backgroundColor: terminalSurface,
      foregroundColor: terminalTextPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: terminalTextPrimary,
      ),
      iconTheme: IconThemeData(color: accent),
    ),
    cardTheme: CardThemeData(
      color: terminalSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: terminalBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: terminalBorder,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: accent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: accent, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: accent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: accent, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: terminalBorder, width: 1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: terminalBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: accent, width: 1),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: terminalError, width: 1),
      ),
      labelStyle: GoogleFonts.jetBrainsMono(color: terminalTextSecondary),
      hintStyle: GoogleFonts.jetBrainsMono(color: terminalTextSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: terminalSurface,
      selectedColor: accent,
      labelStyle: GoogleFonts.jetBrainsMono(color: terminalTextPrimary),
      secondaryLabelStyle: GoogleFonts.jetBrainsMono(color: onAccent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: terminalBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent;
        }
        return terminalTextSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent.withValues(alpha: 0.5);
        }
        return terminalBorder;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    listTileTheme: ListTileThemeData(
      tileColor: terminalSurface,
      textColor: terminalTextPrimary,
      iconColor: accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: terminalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: terminalBorder, width: 1),
      ),
      titleTextStyle: GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: terminalTextPrimary,
      ),
      contentTextStyle: GoogleFonts.jetBrainsMono(color: terminalTextPrimary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: terminalSurface,
      contentTextStyle: GoogleFonts.jetBrainsMono(color: terminalTextPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: terminalBorder, width: 1),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: accent,
      unselectedLabelColor: terminalTextSecondary,
      labelStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
      unselectedLabelStyle: GoogleFonts.jetBrainsMono(),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: accent, width: 2),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: terminalSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accent,
      circularTrackColor: terminalBorder,
      linearTrackColor: terminalBorder,
    ),
    iconTheme: IconThemeData(color: accent),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: terminalSurface,
        border: Border.all(color: terminalBorder, width: 1),
      ),
      textStyle: GoogleFonts.jetBrainsMono(color: terminalTextPrimary),
    ),
  );
}

TextTheme _buildTextTheme(Color accent) {
  return TextTheme(
    displayLarge: GoogleFonts.jetBrainsMono(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    displayMedium: GoogleFonts.jetBrainsMono(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    displaySmall: GoogleFonts.jetBrainsMono(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    headlineLarge: GoogleFonts.jetBrainsMono(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    headlineMedium: GoogleFonts.jetBrainsMono(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    headlineSmall: GoogleFonts.jetBrainsMono(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    titleLarge: GoogleFonts.jetBrainsMono(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    titleMedium: GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    titleSmall: GoogleFonts.jetBrainsMono(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    bodyLarge: GoogleFonts.jetBrainsMono(
      fontSize: 16,
      color: terminalTextPrimary,
    ),
    bodyMedium: GoogleFonts.jetBrainsMono(
      fontSize: 14,
      color: terminalTextPrimary,
    ),
    bodySmall: GoogleFonts.jetBrainsMono(
      fontSize: 12,
      color: terminalTextSecondary,
    ),
    labelLarge: GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    labelMedium: GoogleFonts.jetBrainsMono(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: terminalTextPrimary,
    ),
    labelSmall: GoogleFonts.jetBrainsMono(
      fontSize: 10,
      color: terminalTextSecondary,
    ),
  );
}

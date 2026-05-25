import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color deepTeal = Color(0xFF0A6E73);
  static const Color tealLight = Color(0xFF1BA39C);
  static const Color mint = Color(0xFF5EEAD4);
  static const Color mintGlow = Color(0xFFB8F5F2);
  static const Color ink = Color(0xFF0F2A2E);
  static const Color inkMuted = Color(0xFF5A7A7E);
  static const Color surfaceLight = Color(0xFFF8FDFD);
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentGold = Color(0xFFFFB347);
  static const Color cardWhite = Color(0xFFFFFFFF);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A6E73), Color(0xFF1BA39C), Color(0xFF5EEAD4)],
  );

  static const LinearGradient coralGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E72)],
  );

  static BoxShadow softShadow([double opacity = 0.12]) => BoxShadow(
    color: deepTeal.withValues(alpha: opacity),
    blurRadius: 24,
    offset: const Offset(0, 10),
  );

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepTeal,
        brightness: Brightness.light,
        primary: deepTeal,
        onPrimary: Colors.white,
        secondary: accentCoral,
        surface: surfaceLight,
        onSurface: ink,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
    );

    final font = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: deepTeal.withValues(alpha: 0.12)),
    );

    return base.copyWith(
      textTheme: font,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardWhite.withValues(alpha: 0.92),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.95),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: tealLight, width: 2),
        ),
        labelStyle: const TextStyle(color: inkMuted, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: deepTeal, fontWeight: FontWeight.w600),
        errorStyle: const TextStyle(
          color: accentCoral,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: accentCoral, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: accentCoral, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: deepTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: ink,
          side: BorderSide(color: deepTeal.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: deepTeal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: deepTeal.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return GoogleFonts.plusJakartaSans(
            fontWeight:
            selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
            color: selected ? deepTeal : inkMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? deepTeal : inkMuted,
            size: 26,
          );
        }),
      ),
    );
  }

  static LinearGradient scaffoldGradient(BuildContext context) {
    return const LinearGradient(
      begin: Alignment(-0.8, -1),
      end: Alignment(1.2, 1.2),
      colors: [mintGlow, Color(0xFFE8FAFA), Colors.white],
      stops: [0.0, 0.45, 1.0],
    );
  }
}
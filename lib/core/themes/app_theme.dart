import 'package:flutter/material.dart';

/// ----- COLORS -----
class OumiColors {
  // Primary palette (5 main colors)
  static const Color oumiRose = Color(0xFFE986A7);      // Identity
  static const Color bleuSante = Color(0xFF4A90E2);     // Medical trust
  static const Color vertSante = Color(0xFF4CAF50);     // Normal/fertile
  static const Color peachCorail = Color(0xFFD97D64);   // Cycle/ovulation
  static const Color violetOumi = Color(0xFF8E7CC3);    // Secondary/community

  // Medical status colors
  static const Color normal = Color(0xFF4CAF50);        // NORMAL
  static const Color surveillance = Color(0xFFFF9800);  // SURVEILLANCE
  static const Color urgence = Color(0xFFE53935);       // URGENT

  // Extended palette
  static const Color roseClair = Color(0xFFF8DCE6);
  static const Color bleuTresClair = Color(0xFFEAF4FC);
  static const Color grisTexte = Color(0xFF6B7280);
  static const Color noirDoux = Color(0xFF263238);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color grisFond = Color(0xFFF7F8FA);
  static const Color orangeAlerte = Color(0xFFFF9800);
  static const Color rougeUrgence = Color(0xFFE53935);
}

/// ----- TYPOGRAPHY -----
class OumiTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: OumiColors.noirDoux,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: OumiColors.noirDoux,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: OumiColors.grisTexte,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: OumiColors.grisTexte,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: OumiColors.oumiRose,
  );
}

/// ----- SHAPED DECORATIONS -----
class OumiDecorations {
  static const double radiusSm = 20.0;
  static const double defaultRadius = 28.0;

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 30,
    offset: const Offset(0, 8),
  );

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: OumiColors.oumiRose,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
    elevation: 4,
  );

  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: OumiColors.blanc,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: OumiColors.grisFond, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: OumiColors.bleuSante, width: 2),
        ),
      );
}

/// ----- GLOBAL THEME -----
class OumiTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: OumiColors.grisFond,
        appBarTheme: const AppBarTheme(
          backgroundColor: OumiColors.blanc,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardTheme(
          color: OumiColors.blanc,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(OumiDecorations.defaultRadius)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: OumiDecorations.primaryButton,
        ),
        inputDecorationTheme: OumiDecorations.inputDecorationTheme,
        textTheme: const TextTheme(
          displayLarge: OumiTypography.displayLarge,
          displayMedium: OumiTypography.displayMedium,
          bodyLarge: OumiTypography.bodyLarge,
          bodyMedium: OumiTypography.bodyMedium,
          headlineSmall: OumiTypography.headlineSmall,
        ),
        colorScheme: const ColorScheme.light(
          primary: OumiColors.oumiRose,
          secondary: OumiColors.bleuSante,
          surface: OumiColors.blanc,
          error: OumiColors.rougeUrgence,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: OumiColors.noirDoux,
        colorScheme: const ColorScheme.dark(
          primary: OumiColors.oumiRose,
          secondary: OumiColors.bleuSante,
          surface: Color(0xFF1E1E2F),
          error: OumiColors.rougeUrgence,
        ),
      );
}

/// ----- EXTENSIONS -----
extension MedicalStatus on BuildContext {
  Color get statusNormal => OumiColors.normal;
  Color get statusSurveillance => OumiColors.surveillance;
  Color get statusUrgent => OumiColors.urgence;
}

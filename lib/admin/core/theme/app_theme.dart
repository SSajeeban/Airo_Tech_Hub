import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(
    Brightness brightness, {
    bool isTamil = false,
    bool isSinhala = false,
  }) {
    final baseColor = brightness == Brightness.light
        ? AppColors.inkLight
        : AppColors.inkDark;
    final headingColor = brightness == Brightness.light
        ? AppColors.headingLight
        : AppColors.headingDark;

    final fontFamily = isTamil
        ? 'Noto Sans Tamil'
        : isSinhala
        ? 'Noto Sans Sinhala'
        : 'Inter';
    final theme = TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily),
      displayMedium: TextStyle(fontFamily: fontFamily),
      headlineLarge: TextStyle(fontFamily: fontFamily),
      headlineMedium: TextStyle(fontFamily: fontFamily),
      headlineSmall: TextStyle(fontFamily: fontFamily),
      titleLarge: TextStyle(fontFamily: fontFamily),
      titleMedium: TextStyle(fontFamily: fontFamily),
      titleSmall: TextStyle(fontFamily: fontFamily),
      bodyLarge: TextStyle(fontFamily: fontFamily),
      bodyMedium: TextStyle(fontFamily: fontFamily),
      bodySmall: TextStyle(fontFamily: fontFamily),
      labelLarge: TextStyle(fontFamily: fontFamily),
      labelMedium: TextStyle(fontFamily: fontFamily),
      labelSmall: TextStyle(fontFamily: fontFamily),
    );

    return theme.copyWith(
      displayLarge: theme.displayLarge?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: theme.displayMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineLarge: theme.headlineLarge?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: theme.headlineMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: theme.titleLarge?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: theme.titleMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: theme.bodyLarge?.copyWith(color: baseColor, height: 1.5),
      bodyMedium: theme.bodyMedium?.copyWith(color: baseColor, height: 1.4),
      bodySmall: theme.bodySmall?.copyWith(
        color: brightness == Brightness.light
            ? AppColors.mutedLight
            : AppColors.mutedDark,
      ),
    );
  }

  static ThemeData lightTheme({bool isTamil = false, bool isSinhala = false}) {
    final textTheme = _buildTextTheme(
      Brightness.light,
      isTamil: isTamil,
      isSinhala: isSinhala,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        primaryContainer: AppColors.accentLight,
        secondary: AppColors.brandBlue,
        tertiary: AppColors.brandGreen,
        surface: AppColors.cardLight,
        error: AppColors.danger,
        onPrimary: AppColors.accentInk,
        onSurface: AppColors.inkLight,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.headingLight),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.headingLight,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lineLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lineLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lineLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: TextStyle(color: AppColors.mutedLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentInk,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.headingLight,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.lineLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardLight,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.mutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData darkTheme({bool isTamil = false, bool isSinhala = false}) {
    final textTheme = _buildTextTheme(
      Brightness.dark,
      isTamil: isTamil,
      isSinhala: isSinhala,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.bgDark,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: TextStyle(color: AppColors.inkDark),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        primaryContainer: AppColors.accentHover,
        secondary: AppColors.brandBlue,
        tertiary: AppColors.brandGreen,
        surface: AppColors.cardDark,
        error: AppColors.danger,
        onPrimary: AppColors.accentInk,
        onSurface: AppColors.inkDark,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.headingDark),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.headingDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lineDark, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentInk,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.headingDark,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.lineDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.mutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

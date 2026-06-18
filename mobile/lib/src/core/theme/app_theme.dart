import 'package:flutter/material.dart';

class AppTheme {
  static const _silverMid = Color(0xFFC0C0C0);
  static const _silverDark = Color(0xFF8F8F8F);
  static const contactOrange = Color(0xFFFF9412);
  static const grayBoxFill = Color(0xFF0C1F49);
  static const grayBoxFillAlt = Color(0xFF152A55);

  static const orangeTextStyle = TextStyle(
    color: contactOrange,
    fontWeight: FontWeight.w600,
  );

  static ButtonStyle get contactButtonStyle => FilledButton.styleFrom(
        backgroundColor: contactOrange,
        foregroundColor: Colors.white,
      );

  static ButtonStyle get grayFilledButtonStyle => FilledButton.styleFrom(
        backgroundColor: grayBoxFill,
        foregroundColor: contactOrange,
      );

  static ButtonStyle get tonalButtonStyle => FilledButton.styleFrom(
        backgroundColor: grayBoxFillAlt,
        foregroundColor: contactOrange,
      );

  static ButtonStyle get grayOutlinedButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: contactOrange,
        side: BorderSide(color: contactOrange.withValues(alpha: 0.45)),
      );

  static ThemeData get darkTheme {
    const textStyle = TextStyle(color: _silverMid, fontFamily: 'sans-serif');

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF040F2E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2A62FF),
        brightness: Brightness.dark,
      ).copyWith(
        onSurface: _silverMid,
        onPrimary: _silverMid,
        secondaryContainer: grayBoxFillAlt,
        onSecondaryContainer: contactOrange,
      ),
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        displayLarge: textStyle,
        displayMedium: textStyle,
        displaySmall: textStyle,
        headlineLarge: textStyle,
        headlineMedium: textStyle,
        headlineSmall: textStyle,
        titleLarge: textStyle,
        titleMedium: textStyle,
        titleSmall: textStyle,
        bodyLarge: textStyle,
        bodyMedium: TextStyle(color: _silverDark),
        bodySmall: TextStyle(color: _silverDark),
        labelLarge: textStyle,
        labelMedium: TextStyle(color: _silverDark),
        labelSmall: TextStyle(color: _silverDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _silverMid,
        titleTextStyle: TextStyle(
          color: _silverMid,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFFC8D0D8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grayBoxFill,
        labelStyle: const TextStyle(color: contactOrange, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: contactOrange),
        hintStyle: TextStyle(color: contactOrange.withValues(alpha: 0.65)),
        errorStyle: const TextStyle(color: Color(0xFFFF8A8A)),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF304F92)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF304F92)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF5A7AB8)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: contactOrange,
        selectionColor: Color(0x44FF9412),
        selectionHandleColor: contactOrange,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: contactOrange),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: _silverMid,
        iconColor: Color(0xFFC8D0D8),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF0B1D48),
        contentTextStyle: TextStyle(color: _silverMid),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: grayFilledButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: grayOutlinedButtonStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: contactOrange,
        ),
      ),
    );
  }
}

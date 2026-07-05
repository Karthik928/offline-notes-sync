import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.editAccent,
      onSecondary: AppColors.onPrimary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.onPrimary,
      outline: AppColors.divider,
      outlineVariant: AppColors.textMuted,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.divider,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.onPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.onPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
      ),

      cardTheme: CardThemeData(
        color: AppColors.background,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.divider.withValues(alpha: 0.3)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.4)),
        shape: const StadiumBorder(),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textMuted),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 19,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        bodyLarge: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
        labelLarge: TextStyle(color: AppColors.onPrimaryMuted, fontSize: 12),
        labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

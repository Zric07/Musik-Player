import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accentBright,
      surface: AppColors.bg,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
    splashFactory: NoSplash.splashFactory,
    hoverColor: Colors.white.withValues(alpha: 0.06),
    highlightColor: Colors.white.withValues(alpha: 0.04),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.text, size: 24),
      titleTextStyle: AppText.section,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceTop,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      hintStyle: const TextStyle(
        color: AppColors.textFaint,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: AppColors.textDim,
      suffixIconColor: AppColors.textDim,
      border: _border(AppColors.hairline),
      enabledBorder: _border(AppColors.hairline),
      focusedBorder: _border(AppColors.text),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceHi,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      titleTextStyle: AppText.section,
      contentTextStyle: AppText.body,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        textStyle: AppText.button,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textDim,
        textStyle: AppText.button,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.text,
        highlightColor: Colors.white.withValues(alpha: 0.06),
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: Colors.transparent,
      strokeWidth: 2.5,
    ),

    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: AppColors.text,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.24),
      thumbColor: AppColors.text,
      overlayColor: Colors.white.withValues(alpha: 0.12),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      trackShape: const RoundedRectSliderTrackShape(),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
      space: 1,
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceTop,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: AppText.itemTitle,
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceTop,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      textStyle: const TextStyle(
        color: AppColors.text,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceTop,
      contentTextStyle: const TextStyle(
        color: AppColors.text,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      width: 360,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    ),

    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        Colors.white.withValues(alpha: 0.16),
      ),
      radius: const Radius.circular(AppRadius.pill),
      thickness: const WidgetStatePropertyAll(6),
    ),
  );
}

OutlineInputBorder _border(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    borderSide: BorderSide(color: color),
  );
}

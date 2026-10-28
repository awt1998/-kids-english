import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.mint,
    brightness: Brightness.light,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppFonts.arabic,
    textTheme: TextTheme(
      displayLarge: AppText.display,
      titleLarge: AppText.title,
      bodyLarge: AppText.body,
      bodyMedium: AppText.body,
      labelLarge: AppText.button,
    ),
    // Kids tap anywhere; no ripples flashing over the art.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

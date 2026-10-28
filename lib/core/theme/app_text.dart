import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Arabic UI text uses Baloo Bhaijaan 2; English learning content uses Baloo 2.
abstract final class AppFonts {
  static const arabic = 'BalooBhaijaan2';
  static const english = 'Baloo2';
}

TextStyle _style(String family, double size, int weight, {Color? color}) =>
    TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation.weight(weight.toDouble())],
      color: color ?? AppColors.ink,
      height: 1.25,
    );

abstract final class AppText {
  // Arabic interface text (mostly for parents and labels; kids hear audio).
  static final display = _style(AppFonts.arabic, 40, 800);
  static final title = _style(AppFonts.arabic, 28, 700);
  static final body = _style(AppFonts.arabic, 20, 500);
  static final caption = _style(
    AppFonts.arabic,
    16,
    500,
    color: AppColors.inkSoft,
  );
  static final button = _style(AppFonts.arabic, 26, 700, color: Colors.white);

  // English learning content: big and clear.
  static final word = _style(AppFonts.english, 48, 700);
  static final wordSmall = _style(AppFonts.english, 32, 600);
  static final letter = _style(AppFonts.english, 96, 800);
}

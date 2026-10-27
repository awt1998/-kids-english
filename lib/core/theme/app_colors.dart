import 'package:flutter/material.dart';

/// Colour tokens. See DESIGN.md before adding a new one.
abstract final class AppColors {
  // Brand
  static const sun = Color(0xFFFFC93C);
  static const coral = Color(0xFFFF6B6B);
  static const mint = Color(0xFF2EC4B6);
  static const sky = Color(0xFF4CC9F0);
  static const grape = Color(0xFF9B5DE5);
  static const leaf = Color(0xFF7BD389);

  // Surfaces
  static const background = Color(0xFFFFF8E7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFFFF1D6);

  // Text & lines
  static const ink = Color(0xFF2B2D42);
  static const inkSoft = Color(0xFF6B6F86);
  static const outline = Color(0xFFE9DCC0);

  // Feedback (never red for a wrong answer: we only highlight the right one)
  static const success = leaf;
  static const hint = sun;

  /// Button face colours paired with the darker "pressed edge" shown under them.
  static final buttonPalette = <Color, Color>{
    sun: Color(0xFFE0A800),
    coral: Color(0xFFD94C4C),
    mint: Color(0xFF1E9C90),
    sky: Color(0xFF2A9FCB),
    grape: Color(0xFF7A3FC4),
    leaf: Color(0xFF55AE64),
  };

  static Color edgeFor(Color face) =>
      buttonPalette[face] ?? Color.lerp(face, Colors.black, 0.2)!;
}

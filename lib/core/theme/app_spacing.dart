/// Spacing, radius and touch-size tokens. See DESIGN.md.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 32.0;
  static const pill = 999.0;
}

abstract final class AppTouch {
  /// Smallest tappable size anywhere in the child area.
  static const minTarget = 64.0;

  /// Default height of a primary kid button.
  static const button = 80.0;

  /// Answer cards in games (pictures to tap).
  static const answerCard = 140.0;
}

/// Width above which we switch to the tablet layout.
const tabletBreakpoint = 700.0;

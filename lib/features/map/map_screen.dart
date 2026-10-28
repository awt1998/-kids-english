import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/content_repository.dart';
import '../../content/models.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/shake.dart';
import '../../progress/child_profile.dart';
import '../../progress/profiles_store.dart';
import '../../progress/progress_rules.dart';
import '../lesson/lesson_screen.dart';

/// The adventure map: units as islands, lessons as stops on a winding path.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const _headerHeight = 130.0;
  static const _stopHeight = 150.0;
  static const _stopSize = 104.0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfilesStore>();
    final child = store.current!;
    final units = context.read<ContentRepository>().unitsFor(child.level);
    final next = nextLesson(child, units);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(child: child),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final layout = _layout(units, box.maxWidth);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    child: SizedBox(
                      height: layout.height,
                      width: box.maxWidth,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _PathPainter(
                                layout.stops.map((s) => s.center).toList(),
                              ),
                            ),
                          ),
                          for (final h in layout.headers)
                            Positioned(
                              top: h.top,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _UnitHeader(
                                  unit: h.unit,
                                  open: isUnitOpen(child, units, h.unit),
                                ),
                              ),
                            ),
                          for (final s in layout.stops)
                            Positioned(
                              left: s.center.dx - _stopSize / 2,
                              top: s.center.dy - _stopSize / 2,
                              child: _LessonStop(
                                lesson: s.lesson,
                                stars: child.lessonStars[s.lesson.key] ?? 0,
                                open: isLessonOpen(child, units, s.lesson),
                                isNext: s.lesson.key == next?.key,
                              ),
                            ),
                          if (next != null)
                            for (final s in layout.stops.where(
                              (s) => s.lesson.key == next.key,
                            ))
                              Positioned(
                                // The mascot waits beside the next stop, on the roomier side.
                                left: s.center.dx > box.maxWidth / 2
                                    ? s.center.dx - _stopSize / 2 - 110
                                    : s.center.dx + _stopSize / 2 + 6,
                                top: s.center.dy - 70,
                                child: const IgnorePointer(
                                  child: Mascot(size: 104),
                                ),
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _MapLayout _layout(List<Unit> units, double width) {
    final headers = <_HeaderPos>[];
    final stops = <_StopPos>[];
    final amplitude = math.min(width * 0.22, 160.0);
    var y = AppSpacing.lg;
    var k = 0;
    for (final unit in units) {
      headers.add(_HeaderPos(unit, y));
      y += _headerHeight;
      for (final lesson in ContentRepository.lessonsFor(unit)) {
        final x = width / 2 + amplitude * math.sin(k * 1.2);
        stops.add(_StopPos(lesson, Offset(x, y + _stopSize / 2)));
        y += _stopHeight;
        k++;
      }
    }
    return _MapLayout(headers, stops, y);
  }
}

class _HeaderPos {
  const _HeaderPos(this.unit, this.top);
  final Unit unit;
  final double top;
}

class _StopPos {
  const _StopPos(this.lesson, this.center);
  final Lesson lesson;
  final Offset center;
}

class _MapLayout {
  const _MapLayout(this.headers, this.stops, this.height);
  final List<_HeaderPos> headers;
  final List<_StopPos> stops;
  final double height;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('switch-child'),
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline, width: 4),
              ),
              child: SvgPicture.asset(child.avatarPath),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/images/ui/star.svg', width: 40),
                const SizedBox(width: AppSpacing.sm),
                Text('${child.totalStars}', style: AppText.title),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.unit, required this.open});

  final Unit unit;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: open ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: unit.color,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.edgeFor(unit.color),
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    Text(
                      unit.titleAr,
                      style: AppText.title.copyWith(color: Colors.white),
                    ),
                    if (!unit.isAvailable) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '(${Ar.comingSoon})',
                        style: AppText.body.copyWith(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                open ? unit.iconPath : 'assets/images/ui/lock.svg',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonStop extends StatelessWidget {
  const _LessonStop({
    required this.lesson,
    required this.stars,
    required this.open,
    required this.isNext,
  });

  final Lesson lesson;
  final int stars;
  final bool open;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final color = open ? lesson.unit.color : AppColors.outline;
    final icon = !open
        ? SvgPicture.asset('assets/images/ui/lock.svg', width: 48)
        : lesson.kind == LessonKind.review
        ? SvgPicture.asset('assets/images/ui/trophy.svg', width: 56)
        : SvgPicture.asset(lesson.words.first.imagePath, width: 56);

    return GestureDetector(
      key: ValueKey('stop-${lesson.key}'),
      onTap: () {
        final audio = context.read<AudioService>();
        if (!open) {
          audio.playSfx(Sfx.tryAgain);
          return;
        }
        audio.playSfx(Sfx.tap);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'lesson'),
            builder: (_) => LessonScreen(lesson: lesson),
          ),
        );
      },
      child: SizedBox(
        width: MapScreen._stopSize,
        height: MapScreen._stopSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Pulse(
              active: isNext,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.edgeFor(color),
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
              ),
            ),
            if (stars > 0)
              Positioned(
                bottom: -22,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Opacity(
                        opacity: i < stars ? 1 : 0.25,
                        child: SvgPicture.asset(
                          'assets/images/ui/star.svg',
                          width: 30,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dotted trail joining the lesson stops.
class _PathPainter extends CustomPainter {
  _PathPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()..color = AppColors.outline;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final control = Offset(b.dx, a.dy + (b.dy - a.dy) * 0.5);
      for (var t = 0.0; t <= 1.0; t += 0.07) {
        final p = _quad(a, control, b, t);
        canvas.drawCircle(p, 7, paint);
      }
    }
  }

  Offset _quad(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.points != points;
}

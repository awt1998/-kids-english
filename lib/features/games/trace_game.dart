import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/mascot.dart';
import 'game_common.dart';

/// Letter outlines exported from the app font by tool/gen_letter_paths.py.
class LetterShapes {
  LetterShapes._(this.box, this._paths);

  final double box;
  final Map<String, String> _paths;

  static LetterShapes? _cache;

  static Future<LetterShapes> load([AssetBundle? bundle]) async {
    if (_cache != null) return _cache!;
    final json = jsonDecode(
      await (bundle ?? rootBundle).loadString(
        'assets/content/letter_paths.json',
      ),
    ) as Map<String, dynamic>;
    return _cache = LetterShapes._(
      (json['box'] as num).toDouble(),
      (json['paths'] as Map<String, dynamic>).cast<String, String>(),
    );
  }

  /// The letter's outline scaled to a [size]×[size] square.
  Path pathFor(String letter, double size) {
    final proxy = _FlutterPath();
    writeSvgPathDataToPath(_paths[letter]!, proxy);
    final s = size / box;
    return proxy.path.transform(
      (Matrix4.identity()..scaleByDouble(s, s, 1, 1)).storage,
    );
  }
}

class _FlutterPath extends PathProxy {
  final path = Path();
  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
  @override
  void lineTo(double x, double y) => path.lineTo(x, y);
  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);
  @override
  void close() => path.close();
}

/// Measures how much of a letter a child has drawn over, without needing
/// stroke order: the letter is sampled on a grid and a sample counts once a
/// finger passes near it. Scribbling far outside the letter does not count.
class TraceScorer {
  TraceScorer(Path letter, double size, {int grid = 36})
    : radius = size * 0.075 {
    final step = size / grid;
    for (var gx = 0; gx < grid; gx++) {
      for (var gy = 0; gy < grid; gy++) {
        final p = Offset((gx + 0.5) * step, (gy + 0.5) * step);
        if (letter.contains(p)) _targets.add(p);
      }
    }
    _covered = List.filled(_targets.length, false);
  }

  final double radius;
  final _targets = <Offset>[];
  late final List<bool> _covered;
  var _coveredCount = 0;
  var _inside = 0;
  var _total = 0;

  void add(Offset p) {
    _total++;
    var near = false;
    for (var i = 0; i < _targets.length; i++) {
      if ((_targets[i] - p).distanceSquared <= radius * radius) {
        near = true;
        if (!_covered[i]) {
          _covered[i] = true;
          _coveredCount++;
        }
      }
    }
    if (near) _inside++;
  }

  double get coverage => _targets.isEmpty ? 0 : _coveredCount / _targets.length;
  double get accuracy => _total == 0 ? 1 : _inside / _total;

  /// Enough of the letter is drawn, mostly on the letter itself.
  bool get done => coverage >= 0.8 && accuracy >= 0.6;
}

/// Draw a letter with a finger over its big outline.
class TraceGame extends StatefulWidget {
  const TraceGame({
    super.key,
    required this.letterWord,
    required this.onDone,
    this.lowercase = false,
  });

  /// An alphabet word, e.g. `letter_a`.
  final Word letterWord;
  final bool lowercase;
  final GameDone onDone;

  @override
  State<TraceGame> createState() => _TraceGameState();
}

class _TraceGameState extends State<TraceGame> {
  LetterShapes? _shapes;
  final _strokes = <List<Offset>>[];
  TraceScorer? _scorer;
  double _size = 0;
  bool _done = false;
  Timer? _timer;

  String get _letter => widget.lowercase
      ? widget.letterWord.en.toLowerCase()
      : widget.letterWord.en.toUpperCase();

  @override
  void initState() {
    super.initState();
    LetterShapes.load().then((s) {
      if (mounted) setState(() => _shapes = s);
    });
    final audio = context.read<AudioService>();
    audio.playPrompt(Prompt.traceLetter);
    _timer = Timer(
      const Duration(milliseconds: 1300),
      () => audio.playWord(widget.letterWord.audioPath),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _clear() => setState(() {
    _strokes.clear();
    _scorer = TraceScorer(_shapes!.pathFor(_letter, _size), _size);
  });

  void _add(Offset p, {bool start = false}) {
    if (_done || _scorer == null) return;
    setState(() {
      if (start) _strokes.add([]);
      _strokes.last.add(p);
      _scorer!.add(p);
    });
    if (_scorer!.done) {
      _done = true;
      final audio = context.read<AudioService>();
      audio.playSfx(Sfx.correct);
      _timer?.cancel();
      _timer = Timer(
        const Duration(milliseconds: 500),
        () => audio.playWord(widget.letterWord.audioPath),
      );
      Timer(const Duration(milliseconds: 1700), () {
        if (mounted) widget.onDone(const GameResult());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MascotSays(
          text: Ar.traceLetter,
          pose: _done ? MascotPose.cheer : MascotPose.idle,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final size = math.min(
                math.min(
                  box.maxWidth,
                  box.maxHeight - 120 /* gap + start-over button */,
                ),
                460.0,
              );
              final shapes = _shapes;
              if (shapes == null) return const SizedBox.shrink();
              if (size != _size) {
                _size = size;
                _strokes.clear();
                _scorer = TraceScorer(shapes.pathFor(_letter, size), size);
              }
              return Column(
                children: [
                  GestureDetector(
                    key: const ValueKey('trace-pad'),
                    onPanStart: (d) => _add(d.localPosition, start: true),
                    onPanUpdate: (d) => _add(d.localPosition),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: _done ? AppColors.success : Colors.white,
                          width: 8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.outline,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _TracePainter(
                          shapes.pathFor(_letter, size),
                          _strokes,
                          done: _done,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  KidButton(
                    key: const ValueKey('trace-clear'),
                    icon: Icons.refresh_rounded,
                    label: Ar.startOver,
                    color: AppColors.sky,
                    width: 220,
                    height: 72,
                    onPressed: _done ? null : _clear,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter(this.letter, this.strokes, {required this.done});

  final Path letter;
  final List<List<Offset>> strokes;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      letter,
      Paint()
        ..color = done
            ? AppColors.success.withValues(alpha: 0.35)
            : AppColors.surfaceSoft,
    );
    canvas.drawPath(
      letter,
      Paint()
        ..color = AppColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final ink = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      if (s.length == 1) path.lineTo(s.first.dx + 0.1, s.first.dy);
      canvas.drawPath(path, ink);
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/shake.dart';
import 'game_common.dart';

/// Bubbles drift slowly upwards; the child pops the one with the word they hear.
/// Little children see pictures in the bubbles, readers see the written word.
class BubblePopGame extends StatefulWidget {
  const BubblePopGame({
    super.key,
    required this.target,
    required this.options,
    required this.onDone,
    this.showText = false,
  });

  final Word target;
  final List<Word> options;
  final bool showText;
  final GameDone onDone;

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    AppColors.sky,
    AppColors.mint,
    AppColors.grape,
    AppColors.coral,
    AppColors.sun,
  ];

  late final _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();
  late final List<double> _phase;
  final _shakes = <String, int>{};
  String? _popped;
  var _wrong = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(widget.target.id.hashCode);
    _phase = List.generate(
      widget.options.length,
      (i) => i / widget.options.length + rnd.nextDouble() * 0.08,
    );
    final audio = context.read<AudioService>();
    audio.playPrompt(Prompt.popBubbles);
    _timer = Timer(const Duration(milliseconds: 1600), _say);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _drift.dispose();
    super.dispose();
  }

  void _say() => context.read<AudioService>().playWord(widget.target.audioPath);

  void _tap(Word w) {
    if (_popped != null) return;
    final audio = context.read<AudioService>();
    if (w == widget.target) {
      audio.playSfx(Sfx.correct);
      setState(() => _popped = w.id);
      _drift.stop();
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 1100), () {
        widget.onDone(GameResult(mistakesByWord: {widget.target.id: _wrong}));
      });
    } else {
      audio.playSfx(Sfx.tryAgain);
      setState(() {
        _wrong++;
        _shakes[w.id] = (_shakes[w.id] ?? 0) + 1;
      });
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 600), _say);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MascotSays(
          text: Ar.popBubbles,
          pose: _popped != null ? MascotPose.cheer : MascotPose.idle,
        ),
        const SizedBox(height: AppSpacing.sm),
        KidButton(
          key: const ValueKey('replay'),
          icon: Icons.volume_up_rounded,
          color: AppColors.sky,
          width: 140,
          height: 80,
          onPressed: _say,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final n = widget.options.length;
              final size = math
                  .min(box.maxWidth / n * 0.95, 170.0)
                  .clamp(96.0, 170.0);
              return AnimatedBuilder(
                animation: _drift,
                builder: (context, _) => Stack(
                  children: [for (var i = 0; i < n; i++) _bubble(i, box, size)],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bubble(int i, BoxConstraints box, double size) {
    final w = widget.options[i];
    final n = widget.options.length;
    // Lanes across the width; each bubble rises bottom → top and wraps around.
    final laneWidth = box.maxWidth / n;
    final t = (_drift.value + _phase[i]) % 1.0;
    final travel = box.maxHeight - size;
    final y = travel * (1 - t);
    final x =
        laneWidth * i +
        (laneWidth - size) / 2 +
        math.sin((t + i) * math.pi * 2) * laneWidth * 0.08;
    final popped = _popped == w.id;
    final hint = _wrong > 0 && w == widget.target;
    final color = _colors[i % _colors.length];

    return Positioned(
      left: x.clamp(0.0, box.maxWidth - size),
      top: popped ? y : y,
      child: GestureDetector(
        key: ValueKey('bubble-${w.id}'),
        onTap: () => _tap(w),
        child: Shake(
          trigger: _shakes[w.id] ?? 0,
          child: AnimatedScale(
            scale: popped ? 1.6 : 1,
            duration: const Duration(milliseconds: 350),
            child: AnimatedOpacity(
              opacity: popped ? 0 : 1,
              duration: const Duration(milliseconds: 450),
              child: Pulse(
                active: hint,
                amount: 0.1,
                child: Container(
                  width: size,
                  height: size,
                  padding: EdgeInsets.all(size * 0.2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.18),
                    border: Border.all(
                      color: hint ? AppColors.hint : color,
                      width: hint ? 7 : 4,
                    ),
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.5),
                      radius: 0.9,
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        color.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: widget.showText
                      ? FittedBox(
                          child: EnglishText(w.en, style: AppText.wordSmall),
                        )
                      : SvgPicture.asset(
                          w.imagePath,
                          width: size * 0.6,
                          height: size * 0.6,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

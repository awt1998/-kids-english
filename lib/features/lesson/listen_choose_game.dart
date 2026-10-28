import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../games/game_common.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/shake.dart';

/// The child hears a word and taps the matching picture.
///
/// A wrong tap is never punished: the card wiggles, the word is said again
/// and the right picture starts to glow as a hint.
class ListenChooseGame extends StatefulWidget {
  const ListenChooseGame({
    super.key,
    this.introduce = true,
    required this.target,
    required this.options,
    required this.onDone,
  });

  final Word target;
  final List<Word> options;

  /// Called once the right picture is tapped, with the number of wrong taps before it.
  final ValueChanged<int> onDone;

  /// Say the game's instruction (the first time it appears in a lesson).
  final bool introduce;

  @override
  State<ListenChooseGame> createState() => _ListenChooseGameState();
}

class _ListenChooseGameState extends State<ListenChooseGame>
    with GameVoice<ListenChooseGame> {
  final _wrong = <String>{};
  final _shakes = <String, int>{};
  bool _solved = false;
  bool _hint = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    intro(Prompt.listenAndChoose, introduce: widget.introduce, then: _say);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _say() => context.read<AudioService>().playWord(widget.target.audioPath);

  void _onTap(Word word) {
    if (_solved) return;
    final audio = context.read<AudioService>();
    if (word == widget.target) {
      audio.playSfx(Sfx.correct);
      setState(() => _solved = true);
      _timer?.cancel();
      praiseIfRecovered();
      _timer = Timer(
        Duration(milliseconds: recovered ? 1900 : 1200),
        () => widget.onDone(_wrong.length),
      );
    } else {
      audio.playSfx(Sfx.tryAgain);
      setState(() {
        _wrong.add(word.id);
        _shakes[word.id] = (_shakes[word.id] ?? 0) + 1;
        _hint = true;
      });
      _timer?.cancel();
      encourage(then: _say);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MascotSays(
          text: _solved ? Ar.great : Ar.listenAndChoose,
          pose: _solved ? MascotPose.cheer : MascotPose.idle,
        ),
        const SizedBox(height: AppSpacing.md),
        KidButton(
          key: const ValueKey('replay'),
          icon: Icons.volume_up_rounded,
          color: AppColors.sky,
          width: 160,
          height: 96,
          onPressed: _say,
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final count = widget.options.length;
              final columns = count <= 3 && box.maxWidth > box.maxHeight
                  ? count
                  : 2;
              final rows = (count / columns).ceil();
              final size = math
                  .min(
                    (box.maxWidth - (columns - 1) * AppSpacing.lg) / columns,
                    (box.maxHeight - (rows - 1) * AppSpacing.lg) / rows,
                  )
                  .clamp(110.0, 260.0);
              return Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [for (final w in widget.options) _card(w, size)],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card(Word word, double size) {
    final isTarget = word == widget.target;
    final dimmed = _wrong.contains(word.id);
    final glow = isTarget && (_solved || _hint);
    final borderColor = isTarget && _solved
        ? AppColors.success
        : glow
        ? AppColors.hint
        : Colors.white;

    return GestureDetector(
      key: ValueKey('choice-${word.id}'),
      onTap: () => _onTap(word),
      child: Shake(
        trigger: _shakes[word.id] ?? 0,
        child: Pulse(
          active: glow,
          amount: _solved ? 0.1 : 0.05,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: dimmed ? 0.45 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: size,
              height: size,
              padding: EdgeInsets.all(size * 0.14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderColor, width: 8),
                boxShadow: const [
                  BoxShadow(color: AppColors.outline, offset: Offset(0, 8)),
                ],
              ),
              child: SvgPicture.asset(word.imagePath),
            ),
          ),
        ),
      ),
    );
  }
}

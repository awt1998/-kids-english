import 'dart:math';

import 'package:flutter/material.dart';

import '../../audio/audio_service.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/prompt_on_open.dart';
import '../../core/widgets/shake.dart';

/// A multiplication written in Arabic words (e.g. "سبعة × ثمانية"): easy for
/// an adult, out of reach for a child who cannot read or multiply yet. This is
/// the parental gate both stores require before settings and purchases.
class GateQuestion {
  GateQuestion(Random random)
    : a = 3 + random.nextInt(7),
      b = 3 + random.nextInt(7);

  static const _words = [
    '',
    '',
    'اثنان',
    'ثلاثة',
    'أربعة',
    'خمسة',
    'ستة',
    'سبعة',
    'ثمانية',
    'تسعة',
  ];

  final int a;
  final int b;

  int get answer => a * b;
  String get text => 'كم حاصل ضرب ${_words[a]} في ${_words[b]}؟';

  bool accepts(String typed) => int.tryParse(typed) == answer;
}

/// Opens the gate; completes with true only if an adult answered correctly.
Future<bool> passParentalGate(BuildContext context, {Random? random}) async {
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'gate'),
      builder: (_) => ParentalGateScreen(random: random),
    ),
  );
  return ok ?? false;
}

class ParentalGateScreen extends StatefulWidget {
  const ParentalGateScreen({super.key, this.random});

  final Random? random;

  @override
  State<ParentalGateScreen> createState() => _ParentalGateScreenState();
}

class _ParentalGateScreenState extends State<ParentalGateScreen> {
  late final Random _random = widget.random ?? Random();
  late GateQuestion _question = GateQuestion(_random);
  String _typed = '';
  int _shake = 0;
  bool _wasWrong = false;

  void _key(String k) => setState(() {
    if (_typed.length < 3) _typed += k;
  });

  void _submit() {
    if (_question.accepts(_typed)) {
      Navigator.of(context).pop(true);
      return;
    }
    // A wrong answer gets a new question, so guessing does not work.
    setState(() {
      _question = GateQuestion(_random);
      _typed = '';
      _shake++;
      _wasWrong = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget key(
      String label, {
      VoidCallback? onTap,
      IconData? icon,
      Color color = AppColors.sky,
    }) => KidButton(
      key: ValueKey('gate-$label'),
      label: icon == null ? label : null,
      icon: icon,
      color: color,
      width: 84,
      height: 72,
      onPressed: onTap ?? () => _key(label),
    );

    return PromptOnOpen(
      prompts: const [Prompt.askParent],
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: KidButton(
                        key: const ValueKey('gate-close'),
                        icon: Icons.close_rounded,
                        color: AppColors.coral,
                        width: 72,
                        height: 64,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const Icon(
                      Icons.lock_rounded,
                      size: 56,
                      color: AppColors.inkSoft,
                    ),
                    Text(Ar.gateTitle, style: AppText.title),
                    const SizedBox(height: AppSpacing.md),
                    Shake(
                      trigger: _shake,
                      child: Text(
                        _question.text,
                        style: AppText.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_wasWrong)
                      Text(
                        Ar.gateWrong,
                        style: AppText.caption,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      key: const ValueKey('gate-display'),
                      width: 200,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.outline, width: 3),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          _typed.isEmpty ? Ar.gateHint : _typed,
                          style: _typed.isEmpty
                              ? AppText.caption
                              : AppText.title,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Phone-style keypad, laid out left-to-right like every keypad.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final d in [
                            '1',
                            '2',
                            '3',
                            '4',
                            '5',
                            '6',
                            '7',
                            '8',
                            '9',
                          ])
                            key(d),
                          key(
                            'del',
                            icon: Icons.backspace_rounded,
                            color: AppColors.coral,
                            onTap: () {
                              setState(
                                () => _typed = _typed.isEmpty
                                    ? ''
                                    : _typed.substring(0, _typed.length - 1),
                              );
                            },
                          ),
                          key('0'),
                          key(
                            'ok',
                            icon: Icons.check_rounded,
                            color: AppColors.mint,
                            onTap: _submit,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

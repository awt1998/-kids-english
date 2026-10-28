import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';

/// Says [prompts] one after another when this screen first appears.
class PromptOnOpen extends StatefulWidget {
  const PromptOnOpen({super.key, required this.prompts, required this.child});

  final List<Prompt> prompts;
  final Widget child;

  @override
  State<PromptOnOpen> createState() => _PromptOnOpenState();
}

class _PromptOnOpenState extends State<PromptOnOpen> {
  @override
  void initState() {
    super.initState();
    _speak();
  }

  Future<void> _speak() async {
    final audio = context.read<AudioService>();
    // Let the page transition settle before talking.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    for (final p in widget.prompts) {
      if (!mounted) return;
      if (!await audio.playPromptAndWait(p)) return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

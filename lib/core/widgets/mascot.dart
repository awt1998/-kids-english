import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The mascot candidates. Only one survives once the owner picks.
enum MascotKind {
  fenno('fenno', 'فِنّو'),
  jamool('jamool', 'جمّول'),
  saqr('saqr', 'صقّور');

  const MascotKind(this.asset, this.arabicName);
  final String asset;
  final String arabicName;

  String get path => 'assets/images/mascot/$asset.svg';
}

/// The mascot, gently bobbing so the screen feels alive without distracting.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    required this.kind,
    this.size = 200,
    this.animate = true,
  });

  final MascotKind kind;
  final double size;
  final bool animate;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = SvgPicture.asset(
      widget.kind.path,
      width: widget.size,
      height: widget.size,
      semanticsLabel: widget.kind.arabicName,
    );
    if (!widget.animate) return art;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -widget.size * 0.04 * t),
          child: Transform.scale(scaleY: 1 - 0.02 * (1 - t), child: child),
        );
      },
      child: art,
    );
  }
}

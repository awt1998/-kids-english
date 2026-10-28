import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../strings_ar.dart';
import '../theme/app_spacing.dart';

enum MascotPose {
  idle('labeeb_idle'),
  cheer('labeeb_cheer'),
  sleep('labeeb_sleep');

  const MascotPose(this.asset);
  final String asset;
  String get path => 'assets/images/mascot/$asset.svg';
}

/// Labeeb the baby falcon. Gently bobs while idle and hops when cheering.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.pose = MascotPose.idle,
    this.size = 200,
    this.animate = true,
  });

  final MascotPose pose;
  final double size;
  final bool animate;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (old.pose != widget.pose || old.animate != widget.animate) _start();
  }

  void _start() {
    if (!widget.animate) {
      _controller.stop();
      return;
    }
    _controller.duration = widget.pose == MascotPose.cheer
        ? const Duration(milliseconds: 420)
        : const Duration(milliseconds: 1600);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = SvgPicture.asset(
      widget.pose.path,
      width: widget.size,
      height: widget.size,
      semanticsLabel: Ar.appName,
    );
    if (!widget.animate) return art;
    final hop = widget.pose == MascotPose.cheer ? 0.12 : 0.04;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -widget.size * hop * t),
          child: Transform.scale(
            scaleY: 1 - 0.03 * (1 - t),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: art,
    );
  }
}

/// Mascot with a speech bubble. The bubble text is for parents; kids hear the prompt.
class MascotSays extends StatelessWidget {
  const MascotSays({
    super.key,
    required this.text,
    this.pose = MascotPose.idle,
    this.size,
  });

  final String text;
  final MascotPose pose;

  /// Defaults to a bigger mascot on tablets.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= tabletBreakpoint;
    final size = this.size ?? (isWide ? 140.0 : 96.0);
    final style = Theme.of(context).textTheme.titleLarge!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Mascot(pose: pose, size: size),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(text, style: style),
          ),
        ),
      ],
    );
  }
}

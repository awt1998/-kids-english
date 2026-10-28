import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A one-shot burst of soft confetti falling over the screen.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 70});

  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..forward();
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(3);
    const colors = [
      AppColors.sun,
      AppColors.coral,
      AppColors.mint,
      AppColors.sky,
      AppColors.grape,
      AppColors.leaf,
    ];
    _pieces = List.generate(
      widget.pieces,
      (i) => _Piece(
        x: rnd.nextDouble(),
        delay: rnd.nextDouble() * 0.35,
        speed: 0.7 + rnd.nextDouble() * 0.6,
        sway: rnd.nextDouble() * math.pi * 2,
        size: 8 + rnd.nextDouble() * 8,
        color: colors[i % colors.length],
        round: rnd.nextBool(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_pieces, _controller),
        size: Size.infinite,
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.sway,
    required this.size,
    required this.color,
    required this.round,
  });

  final double x, delay, speed, sway, size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.animation) : super(repaint: animation);

  final List<_Piece> pieces;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final t = ((animation.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final y = -20 + (size.height + 40) * t * p.speed;
      final x = p.x * size.width + math.sin(t * 8 + p.sway) * 24;
      paint.color = p.color.withValues(alpha: t > 0.8 ? (1 - t) * 5 : 1);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 10 + p.sway);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.6,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

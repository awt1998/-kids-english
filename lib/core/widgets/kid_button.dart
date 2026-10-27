import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// The big, chunky "toy" button used everywhere in the child area.
///
/// It sits on a darker edge and sinks into it while pressed, so even a child
/// who cannot read gets clear feedback that the tap registered.
class KidButton extends StatefulWidget {
  const KidButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.color = AppColors.mint,
    this.height = AppTouch.button,
    this.width,
  }) : assert(label != null || icon != null);

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final Color color;
  final double height;
  final double? width;

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton> {
  static const _edge = 8.0;
  bool _down = false;

  void _setDown(bool v) {
    if (widget.onPressed != null) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = enabled ? widget.color : AppColors.outline;
    final edge = enabled ? AppColors.edgeFor(widget.color) : AppColors.inkSoft;
    final offset = _down ? _edge : 0.0;

    return Semantics(
      button: true,
      label: widget.label,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: widget.onPressed,
        child: SizedBox(
          height: widget.height + _edge,
          width: widget.width,
          child: Stack(
            children: [
              Positioned.fill(
                top: _edge,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: edge,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                left: 0,
                right: 0,
                top: offset,
                height: widget.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null)
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: widget.height * 0.45,
                          ),
                        if (widget.icon != null && widget.label != null)
                          const SizedBox(width: AppSpacing.sm),
                        if (widget.label != null)
                          Flexible(
                            child: Text(
                              widget.label!,
                              style: AppText.button,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

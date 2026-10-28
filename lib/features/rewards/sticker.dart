import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';

/// A word picture shown as a die-cut sticker (white edge, slight tilt).
class Sticker extends StatelessWidget {
  const Sticker({
    super.key,
    required this.imagePath,
    required this.size,
    this.collected = true,
    this.tilt = 0,
  });

  final String imagePath;
  final double size;
  final bool collected;

  /// Small rotation in radians so a page of stickers looks hand-placed.
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final picture = SvgPicture.asset(
      imagePath,
      width: size * 0.66,
      height: size * 0.66,
    );
    return Transform.rotate(
      angle: collected ? tilt : 0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: collected ? AppColors.surface : AppColors.surfaceSoft,
          shape: BoxShape.circle,
          border: Border.all(
            color: collected ? Colors.white : AppColors.outline,
            width: collected ? 5 : 3,
          ),
          boxShadow: collected
              ? const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: collected
            ? picture
            // Not collected yet: a faint silhouette as a teaser.
            : Opacity(
                opacity: 0.18,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.inkSoft,
                    BlendMode.srcIn,
                  ),
                  child: picture,
                ),
              ),
      ),
    );
  }
}

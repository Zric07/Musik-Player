import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';

class ColorTile extends StatelessWidget {
  final String seed;
  final IconData icon;
  final double size;
  final double radius;

  const ColorTile({
    super.key,
    required this.seed,
    required this.icon,
    this.size = 52,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forKey(seed);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: AppColors.tileGradient(color),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.88),
          size: size * 0.4,
        ),
      ),
    );
  }
}

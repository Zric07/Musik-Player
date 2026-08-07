import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'hoverable.dart';

class GradientPlayButton extends StatelessWidget {
  final bool enabled;
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;

  const GradientPlayButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.isPlaying = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: enabled ? onPressed : null,
      builder: (context, hovered) {
        return AnimatedScale(
          scale: hovered && enabled ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hovered ? AppColors.accentBright : AppColors.accent,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  size: size * 0.56,
                  color: AppColors.onAccent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SoftIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool active;
  final double size;

  const SoftIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.active = false,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final button = Hoverable(
      onTap: onPressed,
      builder: (context, hovered) {
        final color = onPressed == null
            ? AppColors.textFaint
            : active
            ? AppColors.accent
            : hovered
            ? AppColors.text
            : AppColors.textDim;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: hovered && onPressed != null ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 140),
                child: Icon(icon, size: size * 0.52, color: color),
              ),
              if (active)
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class LightPlayButton extends StatelessWidget {
  final bool enabled;
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;

  const LightPlayButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.isPlaying = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: enabled ? onPressed : null,
      builder: (context, hovered) {
        return AnimatedScale(
          scale: hovered && enabled ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.text,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  size: size * 0.56,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

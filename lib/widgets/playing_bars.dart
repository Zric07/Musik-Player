import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class PlayingBars extends StatefulWidget {
  final bool animate;
  final double size;
  final Color color;

  const PlayingBars({
    super.key,
    required this.animate,
    this.size = 16,
    this.color = AppColors.accent,
  });

  @override
  State<PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<PlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(PlayingBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) {
              final phase = _controller.value * 2 * math.pi + i * 1.3;
              final factor = widget.animate
                  ? 0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase))
                  : 0.35;

              return Container(
                width: widget.size * 0.16,
                height: widget.size * factor,
                color: widget.color,
              );
            }),
          );
        },
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import 'app_spacing.dart';

enum LayoutSize { compact, medium, expanded }

class Responsive {
  Responsive._();

  static LayoutSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.compact) return LayoutSize.compact;
    if (width < AppBreakpoints.expanded) return LayoutSize.medium;
    return LayoutSize.expanded;
  }

  static bool isCompact(BuildContext context) =>
      of(context) == LayoutSize.compact;

  static bool isDesktop(BuildContext context) =>
      of(context) != LayoutSize.compact;

  static double pagePadding(BuildContext context) {
    switch (of(context)) {
      case LayoutSize.compact:
        return 16;
      case LayoutSize.medium:
        return 28;
      case LayoutSize.expanded:
        return 40;
    }
  }

  static double centeredPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final base = pagePadding(context);
    final overflow = (width - AppSpacing.maxContentWidth) / 2;
    return overflow > base ? overflow : base;
  }

  static double coverSize(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (of(context) == LayoutSize.compact) {
      final byWidth = size.width * 0.52;
      final byHeight = size.height * 0.26;
      final value = byWidth < byHeight ? byWidth : byHeight;
      return value.clamp(120.0, 200.0);
    }
    return of(context) == LayoutSize.medium ? 168.0 : 192.0;
  }

  static int gridColumns(BuildContext context, double itemWidth) {
    final width = MediaQuery.sizeOf(context).width;
    final usable = width.clamp(0.0, AppSpacing.maxContentWidth);
    return (usable / itemWidth).floor().clamp(1, 4);
  }
}

class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

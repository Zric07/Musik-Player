import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import 'hoverable.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<NavItem> items;

  const AppBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bg.withValues(alpha: 0.0),
            AppColors.sidebar.withValues(alpha: 0.94),
            AppColors.sidebar,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _BottomButton(
                  item: items[i],
                  active: i == index,
                  onTap: () => onChanged(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _BottomButton({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.text : AppColors.textFaint;

    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? item.activeIcon : item.icon,
              size: 24,
              color: hovered && !active ? AppColors.textDim : color,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

class AppNavRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<NavItem> items;
  final Widget? footer;

  const AppNavRail({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.railWidth,
      color: AppColors.sidebar,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _RailBrand(),
            for (var i = 0; i < items.length; i++)
              _RailButton(
                item: items[i],
                active: i == index,
                onTap: () => onChanged(i),
              ),
            const Spacer(),
            if (footer != null) footer!,
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              size: 18,
              color: AppColors.onAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Text('Musik', style: AppText.section),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _RailButton({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) {
        final color = active
            ? AppColors.text
            : hovered
            ? AppColors.text
            : AppColors.textDim;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                active ? item.activeIcon : item.icon,
                size: 24,
                color: color,
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                item.label,
                style: AppText.itemTitle.copyWith(
                  color: color,
                  fontSize: 14.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

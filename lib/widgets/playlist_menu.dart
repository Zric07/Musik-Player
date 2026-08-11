import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../data/m3u.dart';

enum PlaylistAction { rename, changeCover, removeCover, export, delete }

class PlaylistMenu extends StatelessWidget {
  final bool hasCover;
  final ValueChanged<PlaylistAction> onSelected;
  final Color? color;
  final double size;

  const PlaylistMenu({
    super.key,
    required this.hasCover,
    required this.onSelected,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlaylistAction>(
      tooltip: 'Optionen',
      icon: Icon(Icons.more_horiz_rounded, size: size),
      color: AppColors.surfaceTop,
      position: PopupMenuPosition.under,
      iconColor: color ?? AppColors.textDim,
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: PlaylistAction.rename,
          child: _Entry(
            icon: Icons.drive_file_rename_outline_rounded,
            label: 'Umbenennen',
          ),
        ),
        const PopupMenuItem(
          value: PlaylistAction.changeCover,
          child: _Entry(
            icon: Icons.image_outlined,
            label: 'Cover aus Datei wählen',
          ),
        ),
        if (hasCover)
          const PopupMenuItem(
            value: PlaylistAction.removeCover,
            child: _Entry(
              icon: Icons.hide_image_outlined,
              label: 'Cover entfernen',
            ),
          ),
        const PopupMenuDivider(),
        if (M3u.supported)
          const PopupMenuItem(
            value: PlaylistAction.export,
            child: _Entry(
              icon: Icons.ios_share_rounded,
              label: 'Als M3U exportieren',
            ),
          ),
        const PopupMenuItem(
          value: PlaylistAction.delete,
          child: _Entry(
            icon: Icons.delete_outline_rounded,
            label: 'Playlist löschen',
            danger: true,
          ),
        ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const _Entry({
    super.key,
    required this.icon,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.text;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: AppText.itemTitle.copyWith(color: color)),
      ],
    );
  }
}

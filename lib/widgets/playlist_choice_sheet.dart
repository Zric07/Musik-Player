import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'empty_state.dart';
import 'loading_view.dart';
import 'playlist_tile.dart';

Future<Playlist?> choosePlaylist(BuildContext context) {
  return showModalBottomSheet<Playlist>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceHi,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _PlaylistChoiceSheet(),
  );
}

class _PlaylistChoiceSheet extends StatefulWidget {
  const _PlaylistChoiceSheet({super.key});

  @override
  State<_PlaylistChoiceSheet> createState() => _PlaylistChoiceSheetState();
}

class _PlaylistChoiceSheetState extends State<_PlaylistChoiceSheet> {
  late final Future<List<Playlist>> _playlists =
      PlaylistService().getPlaylists();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textFaint,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Zu Playlist hinzufügen', style: AppText.section),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Playlist>>(
              future: _playlists,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }

                final playlists = snapshot.data ?? const <Playlist>[];

                if (playlists.isEmpty) {
                  return const EmptyState(
                    icon: Icons.playlist_add_rounded,
                    title: 'Noch keine Playlist',
                    subtitle: 'Lege erst eine Playlist in der Bibliothek an.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (context, i) => PlaylistTile(
                    playlist: playlists[i],
                    onTap: () => Navigator.pop(context, playlists[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

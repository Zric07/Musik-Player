import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/formatting.dart';
import '../core/responsive.dart';
import '../models/collection.dart';
import '../services/song_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/playback_builder.dart';
import '../widgets/color_tile.dart';
import '../widgets/song_actions.dart';
import '../widgets/song_menu.dart';
import '../widgets/song_tile.dart';

class CollectionPage extends StatelessWidget {
  final Collection collection;
  final String kind;

  const CollectionPage({
    super.key,
    required this.collection,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.centeredPadding(context);
    final service = SongService();
    final songs = collection.songs;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            leadingWidth: 56,
            titleSpacing: 0,
            leading: Center(
              child: SoftIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
                size: 40,
              ),
            ),
            title: Text(
              collection.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.itemTitle.copyWith(fontSize: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ColorTile(
                    seed: collection.coverKey,
                    size: 96,
                    icon: kind == 'Album'
                        ? Icons.album_rounded
                        : Icons.person_rounded,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(kind.toUpperCase(), style: AppText.overline),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          collection.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${songCountLabel(songs.length)} · '
                          '${formatDuration(collection.total)}',
                          style: AppText.itemSubtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.md),
              child: Row(
                children: [
                  LightPlayButton(
                    enabled: songs.isNotEmpty,
                    onPressed: () => service.playList(songs, 0),
                    size: 52,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  SoftIconButton(
                    icon: Icons.shuffle_rounded,
                    tooltip: 'Zufällig abspielen',
                    onPressed: songs.isEmpty
                        ? null
                        : () async {
                            await service.setShuffle(true);
                            await service.playList(songs, 0);
                          },
                    size: 44,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.xxl),
            sliver: PlaybackBuilder(
              builder: (context, currentId, isPlaying) {
                return SliverList.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, i) => SongTile(
                    song: songs[i],
                    isCurrent: currentId == songs[i].id,
                    isPlaying: isPlaying,
                    onTap: () => service.toggle(songs[i], songs),
                    trailing: SongMenu(
                      song: songs[i],
                      onSelected: (action) =>
                          handleSongAction(context, action, songs[i]),
                    ),
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

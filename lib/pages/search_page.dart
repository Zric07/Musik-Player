import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/responsive.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import '../services/song_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_view.dart';
import '../widgets/playback_builder.dart';
import '../widgets/playlist_tile.dart';
import '../widgets/song_actions.dart';
import '../widgets/song_menu.dart';
import '../widgets/song_tile.dart';
import 'playlist_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _songService = SongService();
  final _playlistService = PlaylistService();

  late Future<List<Song>> _songsFuture;
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _songService.getSongs();
    _playlistsFuture = _playlistService.getPlaylists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  bool _matchesSong(Song song) {
    return song.title.toLowerCase().contains(_query) ||
        song.artist.toLowerCase().contains(_query) ||
        song.album.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    return SafeArea(
      bottom: false,
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                pad,
                AppSpacing.xxl,
                pad,
                AppSpacing.lg,
              ),
              child: const Text('Suchen', style: AppText.title),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: _buildField(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: _buildResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField() {
    final hasText = _searchController.text.isNotEmpty;

    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: AppText.itemTitle.copyWith(fontWeight: FontWeight.w500),
      cursorColor: AppColors.accent,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Titel, Interpret, Album oder Playlist',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Wonach suchst du?',
        subtitle: 'Finde deine Titel, Interpreten und Playlists.',
      );
    }

    return FutureBuilder<List<Song>>(
      future: _songsFuture,
      builder: (context, songSnapshot) {
        if (songSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        final songs = (songSnapshot.data ?? const <Song>[])
            .where(_matchesSong)
            .toList();

        return FutureBuilder<List<Playlist>>(
          future: _playlistsFuture,
          builder: (context, playlistSnapshot) {
            final playlists = (playlistSnapshot.data ?? const <Playlist>[])
                .where((p) => p.title.toLowerCase().contains(_query))
                .toList();

            if (songs.isEmpty && playlists.isEmpty) {
              return EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Keine Ergebnisse',
                subtitle:
                    'Zu "${_searchController.text}" haben wir nichts gefunden.',
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                if (playlists.isNotEmpty) ...[
                  const _ResultLabel('Playlists'),
                  for (final playlist in playlists)
                    PlaylistTile(
                      playlist: playlist,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PlaylistDetailPage(playlist: playlist),
                        ),
                      ),
                    ),
                ],
                if (songs.isNotEmpty) ...[
                  const _ResultLabel('Titel'),
                  PlaybackBuilder(
                    builder: (context, currentId, isPlaying) {
                      return Column(
                        children: [
                          for (final song in songs)
                            SongTile(
                              song: song,
                              isCurrent: currentId == song.id,
                              isPlaying: isPlaying,
                              onTap: () => _songService.toggle(song, songs),
                              trailing: SongMenu(
                                song: song,
                                onSelected: (action) =>
                                    handleSongAction(context, action, song),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _ResultLabel extends StatelessWidget {
  final String text;

  const _ResultLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(text.toUpperCase(), style: AppText.overline),
    );
  }
}

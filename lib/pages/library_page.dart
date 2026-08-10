import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/responsive.dart';
import '../models/collection.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/cover_picker.dart';
import '../services/playlist_service.dart';
import '../services/song_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_button.dart';
import '../widgets/loading_view.dart';
import '../widgets/playlist_menu.dart';
import '../widgets/playlist_name_dialog.dart';
import '../widgets/collection_tile.dart';
import '../widgets/playlist_tile.dart';
import '../widgets/segmented_tabs.dart';
import 'collection_page.dart';
import 'playlist_detail_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _playlistService = PlaylistService();
  final _songService = SongService();

  late Future<List<Playlist>> _playlistsFuture;
  late Future<List<Song>> _songsFuture;

  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = _playlistService.getPlaylists();
    _songsFuture = _songService.getSongs();
  }

  void _reload() {
    setState(() {
      _playlistsFuture = _playlistService.getPlaylists();
    });
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
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Deine Bibliothek', style: AppText.title),
                  ),
                  if (_tab == 0)
                    SoftIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Neue Playlist',
                      onPressed: _showCreateDialog,
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.md),
              child: SegmentedTabs(
                index: _tab,
                labels: const ['Playlists', 'Alben', 'Interpreten'],
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: switch (_tab) {
                  0 => _buildList(),
                  1 => _buildCollections(isAlbum: true),
                  _ => _buildCollections(isAlbum: false),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Playlist>>(
      future: _playlistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        if (snapshot.hasError) {
          return ErrorView(
            message: 'Playlists konnten nicht geladen werden.',
            onRetry: _reload,
          );
        }

        final playlists = snapshot.data ?? const <Playlist>[];

        if (playlists.isEmpty) {
          return EmptyState(
            icon: Icons.playlist_add_rounded,
            title: 'Noch keine Playlist',
            subtitle: 'Sammle deine Lieblingstitel an einem Ort.',
            action: ElevatedButton(
              onPressed: _showCreateDialog,
              child: const Text('Playlist erstellen'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          color: AppColors.accent,
          backgroundColor: AppColors.surfaceHi,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            itemCount: playlists.length,
            itemBuilder: (context, i) {
              final playlist = playlists[i];
              return PlaylistTile(
                playlist: playlist,
                onTap: () => _openDetail(playlist),
                trailing: PlaylistMenu(
                  hasCover: playlist.hasCover,
                  onSelected: (action) => _handleAction(action, playlist),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCollections({required bool isAlbum}) {
    return FutureBuilder<List<Song>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        final songs = snapshot.data ?? const <Song>[];
        final items = isAlbum
            ? CollectionBuilder.albums(songs)
            : CollectionBuilder.artists(songs);

        if (items.isEmpty) {
          return EmptyState(
            icon: isAlbum ? Icons.album_outlined : Icons.person_outline_rounded,
            title: isAlbum ? 'Keine Alben' : 'Keine Interpreten',
            subtitle: 'Sobald Titel da sind, sortieren sie sich hier ein.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          itemCount: items.length,
          itemBuilder: (context, i) => CollectionTile(
            collection: items[i],
            icon: isAlbum ? Icons.album_rounded : Icons.person_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CollectionPage(
                  collection: items[i],
                  kind: isAlbum ? 'Album' : 'Interpret',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDetail(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailPage(playlist: playlist),
      ),
    ).then((_) => _reload());
  }

  Future<void> _showCreateDialog() async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const PlaylistNameDialog(
        title: 'Neue Playlist',
        confirmLabel: 'Erstellen',
      ),
    );

    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) return;

    await _playlistService.createPlaylist(trimmed);
    if (!mounted) return;
    _reload();
  }

  Future<void> _rename(Playlist playlist) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => PlaylistNameDialog(
        title: 'Playlist umbenennen',
        confirmLabel: 'Speichern',
        initialValue: playlist.title,
      ),
    );

    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == playlist.title) return;

    try {
      await _playlistService.renamePlaylist(playlist.id, trimmed);
    } catch (_) {
      if (!mounted) return;
      _notify('Die Playlist konnte nicht umbenannt werden.');
      return;
    }

    if (!mounted) return;
    _reload();
  }

  void _handleAction(PlaylistAction action, Playlist playlist) {
    switch (action) {
      case PlaylistAction.rename:
        _rename(playlist);
      case PlaylistAction.changeCover:
        _changeCover(playlist);
      case PlaylistAction.removeCover:
        _removeCover(playlist);
      case PlaylistAction.delete:
        _confirmDelete(playlist);
    }
  }

  Future<void> _changeCover(Playlist playlist) async {
    try {
      final changed = await CoverPicker.pickAndUpload(playlist.id);
      if (!mounted || !changed) return;
      _reload();
    } catch (_) {
      if (!mounted) return;
      _notify('Das Bild konnte nicht gespeichert werden.');
    }
  }

  Future<void> _removeCover(Playlist playlist) async {
    await _playlistService.clearCover(playlist.id);
    if (!mounted) return;
    _reload();
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmDelete(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Playlist löschen?'),
        content: Text('"${playlist.title}" wird dauerhaft entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _playlistService.deletePlaylist(playlist.id);
    } catch (_) {
      if (!mounted) return;
      _notify('"${playlist.title}" konnte nicht gelöscht werden.');
      return;
    }

    if (!mounted) return;
    _notify('"${playlist.title}" gelöscht');
    _reload();
  }
}

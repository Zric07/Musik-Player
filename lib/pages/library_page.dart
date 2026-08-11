import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/responsive.dart';
import '../data/favorite_store.dart';
import '../data/m3u.dart';
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
import '../widgets/playback_builder.dart';
import '../widgets/playlist_tile.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/song_actions.dart';
import '../widgets/song_menu.dart';
import '../widgets/song_tile.dart';
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
    if (!mounted) return;
    setState(() {
      _playlistsFuture = _playlistService.getPlaylists();
      _songsFuture = _songService.getSongs();
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
                  if (_tab == 0 && M3u.supported)
                    SoftIconButton(
                      icon: Icons.file_download_outlined,
                      tooltip: 'M3U importieren',
                      onPressed: _importPlaylist,
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
                labels: const [
                  'Playlists',
                  'Favoriten',
                  'Alben',
                  'Interpreten',
                  'Ordner',
                ],
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: switch (_tab) {
                  0 => _buildList(),
                  1 => _buildFavorites(),
                  2 => _buildCollections(kind: 'Album'),
                  3 => _buildCollections(kind: 'Interpret'),
                  _ => _buildCollections(kind: 'Ordner'),
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

  Widget _buildCollections({required String kind}) {
    return FutureBuilder<List<Song>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        final songs = snapshot.data ?? const <Song>[];
        final items = switch (kind) {
          'Album' => CollectionBuilder.albums(songs),
          'Interpret' => CollectionBuilder.artists(songs),
          _ => CollectionBuilder.folders(songs),
        };

        final icon = switch (kind) {
          'Album' => Icons.album_rounded,
          'Interpret' => Icons.person_rounded,
          _ => Icons.folder_rounded,
        };

        if (items.isEmpty) {
          return EmptyState(
            icon: icon,
            title: 'Noch nichts da',
            subtitle: 'Sobald Titel da sind, sortieren sie sich hier ein.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          itemCount: items.length,
          itemBuilder: (context, i) => CollectionTile(
            collection: items[i],
            icon: icon,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CollectionPage(
                  collection: items[i],
                  kind: kind,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavorites() {
    return FutureBuilder<List<Song>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        final all = snapshot.data ?? const <Song>[];
        final songs = all
            .where((song) => FavoriteStore.contains(song.id))
            .toList();

        if (songs.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'Noch keine Favoriten',
            subtitle: 'Tippe im Titelmenü auf "Zu Favoriten".',
          );
        }

        return PlaybackBuilder(
          builder: (context, currentId, isPlaying) {
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              itemCount: songs.length,
              itemBuilder: (context, i) => SongTile(
                song: songs[i],
                isCurrent: currentId == songs[i].id,
                isPlaying: isPlaying,
                onTap: () => _songService.toggle(songs[i], songs),
                trailing: SongMenu(
                  song: songs[i],
                  onSelected: (action) => handleSongAction(
                    context,
                    action,
                    songs[i],
                    onChanged: _reload,
                  ),
                ),
              ),
            );
          },
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
      case PlaylistAction.export:
        _exportPlaylist(playlist);
      case PlaylistAction.delete:
        _confirmDelete(playlist);
    }
  }

  Future<void> _exportPlaylist(Playlist playlist) async {
    final full = await _playlistService.getPlaylist(playlist.id);
    final library = await _songService.getSongs();
    final byId = {for (final song in library) song.id: song};

    final songs = full.songs
        .map((path) => byId[path])
        .whereType<Song>()
        .toList();

    final done = await M3u.export(playlist.title, songs);
    if (!mounted) return;

    _notify(done ? 'Playlist exportiert' : 'Export abgebrochen');
  }

  Future<void> _importPlaylist() async {
    final paths = await M3u.importPaths();
    if (paths.isEmpty) {
      if (mounted) _notify('Keine Titel in der Datei gefunden.');
      return;
    }

    final library = await _songService.getSongs();
    final byId = {for (final song in library) song.id: song};

    final songs = paths.map((path) => byId[path]).whereType<Song>().toList();
    if (songs.isEmpty) {
      if (mounted) _notify('Keiner der Titel liegt auf diesem Gerät.');
      return;
    }

    final title = 'Import ${DateTime.now().day}.${DateTime.now().month}';
    await _playlistService.createPlaylist(title);

    final playlists = await _playlistService.getPlaylists();
    final created = playlists.firstWhere(
      (item) => item.title == title,
      orElse: () => playlists.last,
    );

    for (final song in songs) {
      await _playlistService.addToPlaylist(created.id, song);
    }

    if (!mounted) return;
    _notify('${songs.length} Titel importiert');
    _reload();
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

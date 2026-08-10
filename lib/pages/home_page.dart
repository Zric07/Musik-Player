import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/formatting.dart';
import '../core/responsive.dart';
import '../models/playback.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import '../services/song_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_button.dart';
import '../widgets/hoverable.dart';
import '../widgets/loading_view.dart';
import '../widgets/playback_builder.dart';
import '../widgets/playlist_cover.dart';
import '../widgets/section_header.dart';
import '../widgets/song_actions.dart';
import '../widgets/song_menu.dart';
import '../widgets/song_tile.dart';
import 'playlist_detail_page.dart';
import 'queue_page.dart';
import 'stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _songService = SongService();
  final _playlistService = PlaylistService();

  late Future<List<Song>> _songsFuture;
  SongOrder _order = SongOrder.title;
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _songService.getSongs();
    _playlistsFuture = _playlistService.getPlaylists();
  }

  void _load() {
    setState(() {
      _songsFuture = _songService.getSongs();
      _playlistsFuture = _playlistService.getPlaylists();
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Guten Morgen';
    if (hour < 18) return 'Guten Tag';
    return 'Guten Abend';
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: AppColors.accent,
      backgroundColor: AppColors.surfaceHi,
      child: ContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              sliver: SliverToBoxAdapter(child: _buildHeader()),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              sliver: SliverToBoxAdapter(child: _buildShortcuts()),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              sliver: const SliverToBoxAdapter(
                child: SectionHeader(title: 'Alle Titel'),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              sliver: _buildSongList(),
            ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: AppText.title),
              ],
            ),
          ),
          if (_songService.canImport)
            SoftIconButton(
              icon: Icons.library_add_outlined,
              tooltip: _songService.importLabel,
              onPressed: _import,
            ),
          SoftIconButton(
            icon: Icons.insights_outlined,
            tooltip: 'Deine Statistik',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const StatsPage()),
            ),
          ),
          SoftIconButton(
            icon: Icons.playlist_play_rounded,
            tooltip: 'Warteschlange',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const QueuePage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts() {
    return FutureBuilder<List<Playlist>>(
      future: _playlistsFuture,
      builder: (context, snapshot) {
        final playlists = snapshot.data ?? const <Playlist>[];
        if (playlists.isEmpty) return const SizedBox.shrink();

        final shown = playlists.take(6).toList();
        final columns = Responsive.isCompact(context) ? 1 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shown.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 64,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, i) =>
              _ShortcutCard(playlist: shown[i], onTap: () => _open(shown[i])),
        );
      },
    );
  }

  Widget _buildSongList() {
    return FutureBuilder<List<Song>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: LoadingView(),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: ErrorView(
                message: 'Verbindung zum Server fehlgeschlagen.',
                onRetry: _load,
              ),
            ),
          );
        }

        final songs = _sorted(snapshot.data ?? const <Song>[]);

        if (songs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: EmptyState(
                icon: Icons.library_music_outlined,
                title: 'Keine Titel gefunden',
                subtitle: _songService.canImport
                    ? 'Wähle Musikdateien von deinem Gerät aus.'
                    : 'Lege Musikdateien in deinen Musik- oder Download-Ordner.',
                action: _songService.canImport
                    ? ElevatedButton(
                        onPressed: _import,
                        child: Text(_songService.importLabel),
                      )
                    : null,
              ),
            ),
          );
        }

        return PlaybackBuilder(
          builder: (context, currentId, isPlaying) {
            return SliverList.builder(
              itemCount: songs.length,
              itemBuilder: (context, i) => SongTile(
                song: songs[i],
                isCurrent: currentId == songs[i].id,
                isPlaying: isPlaying,
                onTap: () => _songService.toggle(songs[i], songs),
                trailing: SongMenu(
                  onSelected: (action) =>
                      handleSongAction(context, action, songs[i]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Song> _sorted(List<Song> songs) {
    final list = List.of(songs);

    int byText(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

    switch (_order) {
      case SongOrder.title:
        list.sort((a, b) => byText(a.title, b.title));
      case SongOrder.artist:
        list.sort((a, b) {
          final result = byText(a.artist, b.artist);
          return result != 0 ? result : byText(a.title, b.title);
        });
      case SongOrder.album:
        list.sort((a, b) {
          final result = byText(a.album, b.album);
          return result != 0 ? result : byText(a.title, b.title);
        });
      case SongOrder.duration:
        list.sort((a, b) => b.duration.compareTo(a.duration));
    }

    return list;
  }

  Future<void> _import() async {
    final added = await _songService.importFromDevice();
    if (!mounted || added == 0) return;

    _load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(songCountLabel(added) + ' hinzugefügt')),
    );
  }

  Future<void> _chooseOrder() async {
    final chosen = await showModalBottomSheet<SongOrder>(
      context: context,
      backgroundColor: AppColors.surfaceHi,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.lg),
            const Text('Sortieren nach', style: AppText.section),
            const SizedBox(height: AppSpacing.md),
            for (final option in SongOrder.values)
              ListTile(
                title: Text(option.label, style: AppText.itemTitle),
                trailing: option == _order
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.accent,
                        size: 20,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );

    if (chosen == null || !mounted) return;
    setState(() => _order = chosen);
  }

  void _open(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailPage(playlist: playlist),
      ),
    ).then((_) => _load());
  }
}

class _ShortcutCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _ShortcutCard({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            color: hovered ? AppColors.surfaceTop : AppColors.surfaceHi,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              PlaylistCover(playlist: playlist, size: 64, radius: 0),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  playlist.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.itemTitle.copyWith(fontSize: 14),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

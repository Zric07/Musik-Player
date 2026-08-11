import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/formatting.dart';
import '../core/responsive.dart';
import '../data/m3u.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/cover_picker.dart';
import '../services/palette_service.dart';
import '../services/playlist_service.dart';
import '../services/song_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_button.dart';
import '../widgets/loading_view.dart';
import '../widgets/playback_builder.dart';
import '../widgets/playlist_cover.dart';
import '../widgets/playlist_menu.dart';
import '../widgets/playlist_name_dialog.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final _songService = SongService();
  final _playlistService = PlaylistService();
  final _scrollController = ScrollController();

  List<Song> _songs = [];
  late Playlist _playlist;

  bool _loading = true;
  bool _failed = false;
  bool _condensed = false;
  Color _headerColor = AppColors.coverEmpty;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final condensed = _scrollController.offset > 140;
    if (condensed != _condensed) {
      setState(() => _condensed = condensed);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final playlist = await _playlistService.getPlaylist(_playlist.id);
      final allSongs = await _songService.getSongs();

      final songs = playlist.songs.map((songId) {
        return allSongs.firstWhere(
          (song) => song.id == songId,
          orElse: () => Song(
            id: songId,
            title: songId.split(RegExp(r'[/\\]')).last,
            artist: 'Nicht gefunden',
          ),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _playlist = playlist;
        _songs = songs;
        _loading = false;
        _headerColor = PaletteService().peek(playlist) ?? _headerColor;
      });

      unawaited(_resolveHeaderColor());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _resolveHeaderColor() async {
    final color = await PaletteService().forPlaylist(_playlist);
    if (!mounted || color == _headerColor) return;
    setState(() => _headerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.centeredPadding(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(_headerColor),
          SliverToBoxAdapter(child: _buildHeader(pad, _headerColor)),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: _buildBody(),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.xxl),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Color color) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      toolbarHeight: 56,
      backgroundColor: Color.alphaBlend(
        color.withValues(alpha: 0.55),
        AppColors.bg,
      ),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leadingWidth: 56,
      leading: Center(
        child: SoftIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pop(context),
          size: 40,
        ),
      ),
      title: AnimatedOpacity(
        opacity: _condensed ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Text(
          _playlist.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.itemTitle.copyWith(fontSize: 16),
        ),
      ),
      actions: [
        SoftIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Titel hinzufügen',
          onPressed: _showAddSongSheet,
          size: 40,
        ),
        PlaylistMenu(
          hasCover: _playlist.hasCover,
          size: 22,
          onSelected: _handleAction,
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildHeader(double pad, Color color) {
    final compact = Responsive.isCompact(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      decoration: BoxDecoration(gradient: AppColors.headerGradient(color)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, AppSpacing.xl, pad, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            compact ? _compactInfo() : _wideInfo(),
            const SizedBox(height: AppSpacing.xl),
            _buildActions(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _compactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: PlaylistCover(
            playlist: _playlist,
            size: Responsive.coverSize(context),
            radius: AppRadius.sm,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _meta(titleSize: 28),
      ],
    );
  }

  Widget _wideInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PlaylistCover(
          playlist: _playlist,
          size: Responsive.coverSize(context),
          radius: AppRadius.sm,
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(child: _meta(titleSize: 40)),
      ],
    );
  }

  Widget _meta({required double titleSize}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('PLAYLIST', style: AppText.overline),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _playlist.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.display.copyWith(fontSize: titleSize),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          songCountLabel(_playlist.songCount),
          style: AppText.itemSubtitle,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        LightPlayButton(
          enabled: _songs.isNotEmpty,
          onPressed: () => _songService.playList(_songs, 0),
          size: 56,
        ),
        const SizedBox(width: AppSpacing.lg),
        SoftIconButton(
          icon: Icons.add_circle_outline_rounded,
          tooltip: 'Titel hinzufügen',
          onPressed: _showAddSongSheet,
          size: 44,
        ),
      ],
    );
  }

  void _handleAction(PlaylistAction action) {
    switch (action) {
      case PlaylistAction.rename:
        _rename();
      case PlaylistAction.changeCover:
        _changeCover();
      case PlaylistAction.removeCover:
        _removeCover();
      case PlaylistAction.export:
        _export();
      case PlaylistAction.delete:
        _confirmDelete();
    }
  }

  Future<void> _export() async {
    final done = await M3u.export(_playlist.title, _songs);
    if (!mounted) return;

    _notify(done ? 'Playlist exportiert' : 'Export abgebrochen');
  }

  Future<void> _rename() async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => PlaylistNameDialog(
        title: 'Playlist umbenennen',
        confirmLabel: 'Speichern',
        initialValue: _playlist.title,
      ),
    );

    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == _playlist.title || !mounted) return;

    try {
      await _playlistService.renamePlaylist(_playlist.id, trimmed);
    } catch (_) {
      if (!mounted) return;
      _notify('Die Playlist konnte nicht umbenannt werden.');
      return;
    }

    if (!mounted) return;
    await _load();
  }

  Future<void> _changeCover() async {
    try {
      final changed = await CoverPicker.pickAndUpload(_playlist.id);
      if (!mounted || !changed) return;
      PaletteService().forget(_playlist);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _notify('Das Bild konnte nicht gespeichert werden.');
    }
  }

  Future<void> _removeCover() async {
    PaletteService().forget(_playlist);
    await _playlistService.clearCover(_playlist.id);
    if (!mounted) return;
    setState(() => _headerColor = AppColors.coverEmpty);
    await _load();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Playlist löschen?'),
        content: Text('"${_playlist.title}" wird dauerhaft entfernt.'),
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

    if (confirmed != true || !mounted) return;

    try {
      await _playlistService.deletePlaylist(_playlist.id);
    } catch (_) {
      if (!mounted) return;
      _notify('Die Playlist konnte nicht gelöscht werden.');
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: LoadingView(),
        ),
      );
    }

    if (_failed) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: ErrorView(
            message: 'Playlist konnte nicht geladen werden.',
            onRetry: _retry,
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: EmptyState(
            icon: Icons.queue_music_rounded,
            title: 'Diese Playlist ist leer',
            subtitle: 'Füge Titel hinzu, um loszulegen.',
            action: ElevatedButton(
              onPressed: _showAddSongSheet,
              child: const Text('Titel hinzufügen'),
            ),
          ),
        ),
      );
    }

    return PlaybackBuilder(
      builder: (context, currentId, isPlaying) {
        return SliverList.builder(
          itemCount: _songs.length,
          itemBuilder: (context, i) {
            final song = _songs[i];

            return Dismissible(
              key: ValueKey('${_playlist.id}_${song.id}'),
              direction: DismissDirection.endToStart,
              background: const _RemoveBackground(),
              onDismissed: (_) => _removeSong(song),
              child: SongTile(
                song: song,
                isCurrent: currentId == song.id,
                isPlaying: isPlaying,
                onTap: () => _songService.toggle(song, _songs),
              ),
            );
          },
        );
      },
    );
  }

  void _removeSong(Song song) {
    setState(() {
      _songs.remove(song);
      _playlist.songs.remove(song.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${song.title}" entfernt')),
    );

    _playlistService.removeSong(_playlist.id, song);
  }

  Future<void> _showAddSongSheet() async {
    final all = await _songService.getSongs();
    if (!mounted) return;

    final selected = await showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceHi,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _AddSongSheet(songs: all),
    );

    if (selected == null || !mounted) return;

    await _playlistService.addToPlaylist(_playlist.id, selected);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${selected.title}" hinzugefügt')),
    );
    await _load();
  }
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
    );
  }
}

class _AddSongSheet extends StatefulWidget {
  final List<Song> songs;

  const _AddSongSheet({super.key, required this.songs});

  @override
  State<_AddSongSheet> createState() => _AddSongSheetState();
}

class _AddSongSheetState extends State<_AddSongSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final results = widget.songs
        .where((s) => s.title.toLowerCase().contains(query))
        .toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
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
              child: Text('Titel hinzufügen', style: AppText.section),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              style: AppText.itemTitle.copyWith(fontWeight: FontWeight.w500),
              cursorColor: AppColors.accent,
              decoration: const InputDecoration(
                hintText: 'Suchen',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Nichts gefunden',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, i) => SongTile(
                      song: results[i],
                      isCurrent: false,
                      isPlaying: false,
                      trailing: const Icon(
                        Icons.add_rounded,
                        color: AppColors.textDim,
                        size: 20,
                      ),
                      onTap: () => Navigator.pop(context, results[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

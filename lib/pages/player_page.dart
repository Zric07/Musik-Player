import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/formatting.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import '../widgets/cover_art.dart';
import '../widgets/gradient_button.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/hoverable.dart';
import 'queue_page.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final _service = SongService();

  double? _dragValue;
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Song>>(
      stream: _service.queueStream,
      initialData: _service.queue,
      builder: (context, _) {
        final song = _service.current;
        if (song == null) return const SizedBox.shrink();

        final color = AppColors.forKey(song.id);

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient(color),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  _buildTopBar(song),
                  const Spacer(flex: 2),
                  _buildCover(song),
                  const Spacer(flex: 2),
                  _buildTitle(song),
                  const SizedBox(height: AppSpacing.xl),
                  _buildProgress(),
                  const SizedBox(height: AppSpacing.md),
                  _buildControls(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFooter(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(Song song) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          SoftIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            tooltip: 'Schließen',
            onPressed: () => Navigator.pop(context),
            size: 38,
          ),
          const Expanded(
            child: Text(
              'WIRD ABGESPIELT',
              textAlign: TextAlign.center,
              style: AppText.overline,
            ),
          ),
          if (song.hasLyrics)
            SoftIconButton(
              icon: Icons.lyrics_outlined,
              tooltip: 'Liedtext',
              active: _showLyrics,
              onPressed: () => setState(() => _showLyrics = !_showLyrics),
              size: 38,
            ),
          SoftIconButton(
            icon: Icons.playlist_play_rounded,
            tooltip: 'Warteschlange',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const QueuePage()),
            ),
            size: 38,
          ),
        ],
      ),
    );
  }

  Widget _buildCover(Song song) {
    final width = MediaQuery.sizeOf(context).width - AppSpacing.xl * 2;
    final height = MediaQuery.sizeOf(context).height * 0.34;
    final size = width < height ? width : height;

    if (_showLyrics && song.hasLyrics) {
      return LyricsView(
        song: song,
        position: _service.positionStream,
        size: size,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 48,
            spreadRadius: -8,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: CoverArt(song: song, size: size, radius: AppRadius.md),
    );
  }

  Widget _buildTitle(Song song) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.display.copyWith(fontSize: 26),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                song.album.isEmpty ? song.artist : '${song.artist} · ${song.album}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
        SoftIconButton(
          icon: Icons.playlist_add_rounded,
          tooltip: 'Zur Warteschlange hinzufügen',
          onPressed: () {
            _service.addToQueue(song);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${song.title}" hinzugefügt')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return StreamBuilder<Duration>(
      stream: _service.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = _service.duration ?? Duration.zero;

        final maxMillis = total.inMilliseconds.toDouble();
        final sliderMax = maxMillis == 0 ? 1.0 : maxMillis;
        final raw = _dragValue ?? position.inMilliseconds.toDouble();
        final value = raw.clamp(0.0, sliderMax);

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value,
                max: sliderMax,
                onChanged: (v) => setState(() => _dragValue = v),
                onChangeEnd: (v) async {
                  await _service.seek(Duration(milliseconds: v.toInt()));
                  if (mounted) setState(() => _dragValue = null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(Duration(milliseconds: value.toInt())),
                    style: AppText.caption,
                  ),
                  Text(formatDuration(total), style: AppText.caption),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    final isLooping = _service.loopMode == LoopMode.one;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SoftIconButton(
          icon: isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          tooltip: 'Titel wiederholen',
          active: isLooping,
          onPressed: _toggleLoop,
        ),
        const SizedBox(width: AppSpacing.lg),
        SoftIconButton(
          icon: Icons.skip_previous_rounded,
          onPressed: _service.hasPrev ? _service.prev : null,
          size: 52,
        ),
        const SizedBox(width: AppSpacing.md),
        _buildPlayButton(),
        const SizedBox(width: AppSpacing.md),
        SoftIconButton(
          icon: Icons.skip_next_rounded,
          onPressed: _service.hasNext ? _service.next : null,
          size: 52,
        ),
        const SizedBox(width: AppSpacing.lg),
        const SizedBox(width: 42),
      ],
    );
  }

  Widget _buildPlayButton() {
    return StreamBuilder<bool>(
      stream: _service.playingStream,
      initialData: _service.isPlaying,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        return _WhitePlayButton(
          isPlaying: isPlaying,
          onPressed: () => isPlaying ? _service.pause() : _service.resume(),
        );
      },
    );
  }

  Widget _buildFooter() {
    final position = _service.currentIndex + 1;
    final total = _service.queue.length;

    return Text(
      total == 0 ? '' : 'TITEL $position VON $total',
      style: AppText.overline,
    );
  }

  Future<void> _toggleLoop() async {
    final next = _service.loopMode == LoopMode.one
        ? LoopMode.off
        : LoopMode.one;
    await _service.setLoopMode(next);
    if (mounted) setState(() {});
  }
}

class _WhitePlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _WhitePlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: onPressed,
      builder: (context, hovered) {
        return AnimatedScale(
          scale: hovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.text,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(isPlaying),
                size: 38,
                color: AppColors.bg,
              ),
            ),
          ),
        );
      },
    );
  }
}

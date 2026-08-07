import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../data/id3_parser.dart';
import '../models/song.dart';

class LyricsView extends StatefulWidget {
  final Song song;
  final Stream<Duration> position;
  final double size;

  const LyricsView({
    super.key,
    required this.song,
    required this.position,
    required this.size,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final _controller = ScrollController();
  final _keys = <int, GlobalKey>{};

  int _active = -1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _indexFor(Duration position, List<LyricLine> lines) {
    var index = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time <= position) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  void _follow(int index) {
    if (index == _active) return;
    _active = index;

    final key = _keys[index];
    final context = key?.currentContext;
    if (context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.4,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.song.timedLyrics;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: lines.isEmpty ? _buildPlain() : _buildTimed(lines),
    );
  }

  Widget _buildPlain() {
    return _Frame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          widget.song.lyrics,
          style: AppText.body.copyWith(
            color: AppColors.text,
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ),
    );
  }

  Widget _buildTimed(List<LyricLine> lines) {
    return StreamBuilder<Duration>(
      stream: widget.position,
      builder: (context, snapshot) {
        final index = _indexFor(snapshot.data ?? Duration.zero, lines);
        _follow(index);

        return _Frame(
          child: ListView.builder(
            controller: _controller,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xxl,
            ),
            itemCount: lines.length,
            itemBuilder: (context, i) {
              final key = _keys.putIfAbsent(i, GlobalKey.new);
              final active = i == index;

              return Padding(
                key: key,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: AppText.itemTitle.copyWith(
                    fontSize: active ? 19 : 16,
                    height: 1.4,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.text : AppColors.textFaint,
                  ),
                  child: Text(lines[i].text),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  final Widget child;

  const _Frame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.12, 0.88, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: child,
      ),
    );
  }
}

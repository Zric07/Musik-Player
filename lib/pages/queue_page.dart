import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/responsive.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_tile.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SongService();
    final pad = Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warteschlange', style: AppText.section),
        backgroundColor: AppColors.bg,
        titleSpacing: 0,
      ),
      body: ContentWidth(
        maxWidth: 760,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: StreamBuilder<List<Song>>(
            stream: service.queueStream,
            initialData: service.queue,
            builder: (context, snapshot) {
              final queue = snapshot.data ?? const <Song>[];

              if (queue.isEmpty) {
                return const EmptyState(
                  icon: Icons.queue_music_rounded,
                  title: 'Warteschlange ist leer',
                  subtitle: 'Starte einen Titel, um sie zu füllen.',
                );
              }

              return StreamBuilder<bool>(
                stream: service.playingStream,
                initialData: service.isPlaying,
                builder: (context, playingSnapshot) {
                  final isPlaying = playingSnapshot.data ?? false;

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    itemCount: queue.length,
                    onReorder: service.reorderQueue,
                    proxyDecorator: _dragDecorator,
                    itemBuilder: (context, i) {
                      final song = queue[i];

                      return Dismissible(
                        key: ValueKey('queue_${song.id}_$i'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => service.removeFromQueue(i),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.xl),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                          ),
                        ),
                        child: SongTile(
                          song: song,
                          index: i,
                          isCurrent: service.currentIndex == i,
                          isPlaying: isPlaying,
                          onTap: () => service.jumpTo(i),
                          trailing: const Icon(
                            Icons.drag_indicator_rounded,
                            color: AppColors.textFaint,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget _dragDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return Material(
      color: AppColors.surfaceTop,
      elevation: 8,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: child,
    );
  }
}

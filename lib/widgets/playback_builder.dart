import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/song_service.dart';

class PlaybackBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, String? currentId, bool isPlaying)
  builder;

  const PlaybackBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final service = SongService();

    return StreamBuilder<List<Song>>(
      stream: service.queueStream,
      initialData: service.queue,
      builder: (context, _) {
        return StreamBuilder<bool>(
          stream: service.playingStream,
          initialData: service.isPlaying,
          builder: (context, playingSnapshot) {
            return builder(
              context,
              service.current?.id,
              playingSnapshot.data ?? false,
            );
          },
        );
      },
    );
  }
}

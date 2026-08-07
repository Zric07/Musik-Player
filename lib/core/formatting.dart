String formatDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String songCountLabel(int count) => count == 1 ? '1 Titel' : '$count Titel';

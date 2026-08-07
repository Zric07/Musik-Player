class RankedEntry {
  final String label;
  final String detail;
  final int plays;
  final Duration listened;

  const RankedEntry({
    required this.label,
    required this.detail,
    required this.plays,
    required this.listened,
  });
}

class DayBar {
  final DateTime day;
  final Duration listened;

  const DayBar({required this.day, required this.listened});
}

class ListeningStats {
  final Duration total;
  final int plays;
  final int distinctSongs;
  final int distinctArtists;
  final int skipped;
  final List<RankedEntry> topSongs;
  final List<RankedEntry> topArtists;
  final List<DayBar> lastDays;

  const ListeningStats({
    required this.total,
    required this.plays,
    required this.distinctSongs,
    required this.distinctArtists,
    required this.skipped,
    required this.topSongs,
    required this.topArtists,
    required this.lastDays,
  });

  static const empty = ListeningStats(
    total: Duration.zero,
    plays: 0,
    distinctSongs: 0,
    distinctArtists: 0,
    skipped: 0,
    topSongs: [],
    topArtists: [],
    lastDays: [],
  );

  bool get isEmpty => plays == 0;

  double get skipRate => plays == 0 ? 0 : skipped / plays;
}

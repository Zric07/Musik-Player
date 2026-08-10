import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/responsive.dart';
import '../data/play_history.dart';
import '../models/stats.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_view.dart';
import '../widgets/section_header.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<ListeningStats> _stats;

  @override
  void initState() {
    super.initState();
    _stats = PlayHistory.load();
  }

  void _reload() {
    setState(() {
      _stats = PlayHistory.load();
    });
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verlauf löschen?'),
        content: const Text(
          'Alle aufgezeichneten Wiedergaben werden entfernt. '
          'Deine Titel und Playlists bleiben unberührt.',
        ),
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

    await PlayHistory.clear();
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.centeredPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deine Statistik', style: AppText.section),
        backgroundColor: AppColors.bg,
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: 'Verlauf löschen',
            onPressed: _confirmClear,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
          SizedBox(width: pad),
        ],
      ),
      body: FutureBuilder<ListeningStats>(
        future: _stats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: 'Die Statistik konnte nicht geladen werden.',
              onRetry: _reload,
            );
          }

          final stats = snapshot.data ?? ListeningStats.empty;

          if (stats.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_rounded,
              title: 'Noch nichts gehört',
              subtitle:
                  'Sobald du Musik abspielst, sammelt sich hier deine '
                  'Auswertung. Sie verlässt dein Gerät nie.',
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.xxl),
            children: [
              _Summary(stats: stats),
              const SectionHeader(title: 'Letzte sieben Tage'),
              _DayChart(days: stats.lastDays),
              const SectionHeader(title: 'Meistgehörte Titel'),
              ..._ranked(stats.topSongs),
              const SectionHeader(title: 'Meistgehörte Interpreten'),
              ..._ranked(stats.topArtists),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _ranked(List<RankedEntry> entries) {
    return List.generate(
      entries.length,
      (i) => _RankedTile(rank: i + 1, entry: entries[i]),
    );
  }
}

class _Summary extends StatelessWidget {
  final ListeningStats stats;

  const _Summary({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.isCompact(context) ? 2 : 4;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.6,
        children: [
          _Metric(value: _hours(stats.total), label: 'gehört'),
          _Metric(value: '${stats.plays}', label: 'Wiedergaben'),
          _Metric(value: '${stats.distinctSongs}', label: 'Titel'),
          _Metric(value: '${stats.distinctArtists}', label: 'Interpreten'),
        ],
      ),
    );
  }

  static String _hours(Duration total) {
    if (total.inHours >= 1) return '${total.inHours} h';
    if (total.inMinutes >= 1) return '${total.inMinutes} min';
    return '${total.inSeconds} s';
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.title.copyWith(fontSize: 26)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _DayChart extends StatelessWidget {
  final List<DayBar> days;

  const _DayChart({super.key, required this.days});

  static const _labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    var peak = 1;
    for (final day in days) {
      if (day.listened.inSeconds > peak) peak = day.listened.inSeconds;
    }

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final ratio = day.listened.inSeconds / peak;
          final active = day.listened.inSeconds > 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    active ? _short(day.listened) : '',
                    style: AppText.caption.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final height =
                            (constraints.maxHeight * ratio).clamp(3.0, 999.0);

                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            height: height,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.accent
                                  : AppColors.surfaceHi,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _labels[day.day.weekday - 1],
                    style: AppText.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _short(Duration value) {
    if (value.inHours >= 1) return '${value.inHours}h';
    if (value.inMinutes >= 1) return '${value.inMinutes}m';
    return '${value.inSeconds}s';
  }
}

class _RankedTile extends StatelessWidget {
  final int rank;
  final RankedEntry entry;

  const _RankedTile({super.key, required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                fontSize: 15,
                color: rank == 1 ? AppColors.accent : AppColors.textFaint,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.itemTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.itemSubtitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_duration(entry.listened), style: AppText.itemTitle),
              const SizedBox(height: 2),
              Text('${entry.plays}x', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }

  static String _duration(Duration value) {
    if (value.inHours >= 1) {
      final minutes = value.inMinutes % 60;
      return '${value.inHours} h $minutes min';
    }
    if (value.inMinutes >= 1) return '${value.inMinutes} min';
    return '${value.inSeconds} s';
  }
}

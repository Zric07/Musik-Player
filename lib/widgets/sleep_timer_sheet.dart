import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/formatting.dart';
import '../services/sleep_timer.dart';
import '../services/song_service.dart';

Future<void> showSleepTimerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceHi,
    constraints: const BoxConstraints(maxWidth: 480),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _SleepTimerSheet(),
  );
}

class _SleepTimerSheet extends StatefulWidget {
  const _SleepTimerSheet({super.key});

  @override
  State<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<_SleepTimerSheet> {
  static const _options = [5, 15, 30, 45, 60, 90];

  void _start(int minutes) {
    SleepTimer.start(
      Duration(minutes: minutes),
      () => SongService().pause(),
    );
    Navigator.pop(context);
  }

  void _afterSong() {
    SleepTimer.startAfterSong();
    Navigator.pop(context);
  }

  void _cancel() {
    SleepTimer.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sleep-Timer', style: AppText.section),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder<Duration?>(
              stream: SleepTimer.stream,
              builder: (context, snapshot) {
                if (SleepTimer.stopsAfterSong) {
                  return const Text(
                    'Stoppt am Ende des Titels',
                    style: AppText.itemSubtitle,
                  );
                }

                final left = SleepTimer.remaining;
                return Text(
                  left == null
                      ? 'Kein Timer aktiv'
                      : 'Noch ${formatDuration(left)}',
                  style: AppText.itemSubtitle,
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final minutes in _options)
                  ActionChip(
                    label: Text('$minutes Min'),
                    backgroundColor: AppColors.surfaceTop,
                    labelStyle: AppText.itemTitle.copyWith(fontSize: 13.5),
                    onPressed: () => _start(minutes),
                  ),
                ActionChip(
                  label: const Text('Ende des Titels'),
                  backgroundColor: AppColors.surfaceTop,
                  labelStyle: AppText.itemTitle.copyWith(fontSize: 13.5),
                  onPressed: _afterSong,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _cancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('Timer abbrechen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

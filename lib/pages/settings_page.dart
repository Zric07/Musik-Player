import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/responsive.dart';
import '../data/folder_picker.dart';
import '../data/settings_store.dart';
import '../services/audio_effects.dart';
import '../services/song_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/section_header.dart';
import '../widgets/sleep_timer_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _service = SongService();

  List<EqualizerBand> _bands = const [];
  bool _equalizerOn = false;
  double _boost = 0;

  @override
  void initState() {
    super.initState();
    _equalizerOn = AudioEffects.isEnabled;
    _boost = AudioEffects.boost;
    _loadBands();
  }

  Future<void> _loadBands() async {
    final bands = await AudioEffects.bands();
    if (!mounted) return;
    setState(() => _bands = bands);
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.centeredPadding(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leadingWidth: 56,
        titleSpacing: 0,
        leading: Center(
          child: SoftIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
            size: 40,
          ),
        ),
        title: const Text('Einstellungen', style: AppText.section),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.xxl),
        children: [
          const SectionHeader(title: 'Wiedergabe'),
          _buildSpeed(),
          const SizedBox(height: AppSpacing.md),
          _buildSleepRow(),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Klang'),
          _buildEqualizer(),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Musikordner'),
          _buildFolders(),
        ],
      ),
    );
  }

  Widget _buildSpeed() {
    const steps = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return StreamBuilder<void>(
      stream: _service.modeStream,
      builder: (context, _) {
        final current = _service.speed;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geschwindigkeit  ${current.toStringAsFixed(2)}x',
              style: AppText.itemTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final step in steps)
                  ChoiceChip(
                    label: Text('${step}x'),
                    selected: (current - step).abs() < 0.01,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surfaceHi,
                    labelStyle: AppText.itemSubtitle.copyWith(
                      color: AppColors.text,
                    ),
                    onSelected: (_) => _service.setSpeed(step),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSleepRow() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bedtime_outlined, color: AppColors.textDim),
      title: const Text('Sleep-Timer', style: AppText.itemTitle),
      subtitle: const Text(
        'Musik nach einer Zeit ausschalten',
        style: AppText.itemSubtitle,
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textFaint,
      ),
      onTap: () => showSleepTimerSheet(context),
    );
  }

  Widget _buildEqualizer() {
    if (!AudioEffects.supported) {
      return const Text(
        'Der Equalizer ist nur unter Android verfügbar.',
        style: AppText.itemSubtitle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: _equalizerOn,
          onChanged: _toggleEqualizer,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.accent,
          title: const Text('Equalizer', style: AppText.itemTitle),
        ),
        if (_equalizerOn) ...[
          for (var i = 0; i < _bands.length; i++) _buildBand(i),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Lautheit  +${_boost.toStringAsFixed(0)} dB',
            style: AppText.itemTitle,
          ),
          Slider(
            value: _boost,
            min: 0,
            max: 12,
            divisions: 12,
            onChanged: (value) => setState(() => _boost = value),
            onChangeEnd: AudioEffects.setBoost,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetEqualizer,
              child: const Text('Zurücksetzen'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBand(int index) {
    final band = _bands[index];
    final hertz = band.centerFrequency.round();
    final label = hertz >= 1000
        ? '${(hertz / 1000).toStringAsFixed(1)} kHz'
        : '$hertz Hz';

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: AppText.caption),
        ),
        Expanded(
          child: Slider(
            value: band.gain.clamp(
              AudioEffects.minDecibels,
              AudioEffects.maxDecibels,
            ),
            min: AudioEffects.minDecibels,
            max: AudioEffects.maxDecibels,
            onChanged: (value) => setState(() {
              _bands[index] = EqualizerBand(
                index: band.index,
                centerFrequency: band.centerFrequency,
                gain: value,
              );
            }),
            onChangeEnd: (value) => AudioEffects.setGain(index, value),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleEqualizer(bool value) async {
    await AudioEffects.setEnabled(value);
    if (!mounted) return;

    setState(() => _equalizerOn = value);
    if (value) await _loadBands();
  }

  Future<void> _resetEqualizer() async {
    await AudioEffects.reset();
    if (!mounted) return;

    setState(() => _boost = 0);
    await _loadBands();
  }

  Widget _buildFolders() {
    final chosen = SettingsStore.list(SettingsStore.scanRoots);
    final roots = chosen.isNotEmpty ? chosen : FolderPicker.defaults();
    final skipped = SettingsStore.list(SettingsStore.excluded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final root in roots)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              skipped.contains(root)
                  ? Icons.folder_off_outlined
                  : Icons.folder_rounded,
              color: skipped.contains(root)
                  ? AppColors.textFaint
                  : AppColors.accent,
            ),
            title: Text(
              root,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.itemSubtitle.copyWith(
                color: skipped.contains(root)
                    ? AppColors.textFaint
                    : AppColors.text,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                skipped.contains(root)
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.textDim,
              ),
              onPressed: () => _toggleFolder(root),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (FolderPicker.supported)
              OutlinedButton.icon(
                onPressed: _addFolder,
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: const Text('Ordner hinzufügen'),
              ),
            const SizedBox(width: AppSpacing.md),
            TextButton(
              onPressed: _rescan,
              child: const Text('Neu einlesen'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _toggleFolder(String root) async {
    final skipped = List.of(SettingsStore.list(SettingsStore.excluded));

    if (skipped.contains(root)) {
      skipped.remove(root);
    } else {
      skipped.add(root);
    }

    await SettingsStore.setList(SettingsStore.excluded, skipped);
    if (mounted) setState(() {});
  }

  Future<void> _addFolder() async {
    final path = await FolderPicker.pick();
    if (path == null || path.isEmpty) return;

    final chosen = List.of(SettingsStore.list(SettingsStore.scanRoots));
    if (chosen.isEmpty) chosen.addAll(FolderPicker.defaults());
    if (chosen.contains(path)) return;

    chosen.add(path);
    await SettingsStore.setList(SettingsStore.scanRoots, chosen);

    if (!mounted) return;
    setState(() {});
    await _rescan();
  }

  Future<void> _rescan() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Bibliothek wird neu eingelesen …')),
    );

    final songs = await _service.refresh();
    messenger.showSnackBar(
      SnackBar(content: Text('${songs.length} Titel gefunden')),
    );
  }
}

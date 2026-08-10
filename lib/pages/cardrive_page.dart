import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/responsive.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import '../services/voice_commands.dart';
import '../widgets/cover_art.dart';

class CarDrivePage extends StatefulWidget {
  final bool active;

  const CarDrivePage({super.key, this.active = false});

  @override
  State<CarDrivePage> createState() => _CarDrivePageState();
}

class _CarDrivePageState extends State<CarDrivePage> {
  final _speech = stt.SpeechToText();
  final _songService = SongService();

  bool _listening = false;
  bool _blocked = false;

  String _heard = '';
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(CarDrivePage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _start();
    if (!widget.active && old.active) _stop();
  }

  @override
  void dispose() {
    _listening = false;
    _speech.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_listening || _blocked) return;

    var available = false;
    try {
      available = await _speech.initialize(
        onStatus: _onStatus,
        onError: (_) => _resume(),
      );
    } catch (_) {
      available = false;
    }

    if (!mounted) return;

    if (!available) {
      setState(() {
        _blocked = true;
        _feedback = 'Spracherkennung ist auf diesem Gerät nicht verfügbar.';
      });
      return;
    }

    setState(() {
      _listening = true;
      _heard = '';
    });

    await _listen();
  }

  Future<void> _stop() async {
    if (!_listening) return;

    setState(() => _listening = false);
    await _speech.stop();
  }

  void _onStatus(String status) {
    if (status == 'listening') return;
    _resume();
  }

  void _resume() {
    if (!_listening || !mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 400), _listen);
  }

  Future<void> _listen() async {
    if (!_listening || !mounted || _speech.isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() => _heard = result.recognizedWords);
          if (result.finalResult) _handle(result.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'de_DE',
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 30),
        ),
      );
    } catch (_) {
      _say('Das Mikrofon ist gerade nicht erreichbar.');
    }

    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _stop();
      return;
    }

    _blocked = false;
    await _start();
  }

  Future<void> _handle(String spoken) async {
    final command = VoiceCommands.parse(spoken);

    switch (command.action) {
      case VoiceAction.play:
        await _playByName(command.query);

      case VoiceAction.resume:
        await _songService.resume();
        _say('Weiter');

      case VoiceAction.pause:
        await _songService.pause();
        _say('Pause');

      case VoiceAction.next:
        await _songService.next();
        _say('Nächster Titel');

      case VoiceAction.previous:
        await _songService.prev();
        _say('Vorheriger Titel');

      case VoiceAction.unknown:
        await _playByName(VoiceCommands.normalize(spoken));
    }
  }

  Future<void> _playByName(String query) async {
    final songs = await _songService.getSongs();
    final song = VoiceCommands.findSong(songs, query);

    if (song == null) {
      _say('Ich habe keine Musik auf dem Gerät gefunden.');
      return;
    }

    await _songService.playList(songs, songs.indexOf(song));
    _say('Spiele "${song.title}"');
  }

  void _say(String message) {
    if (!mounted) return;
    setState(() => _feedback = message);
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    return SafeArea(
      bottom: false,
      child: ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            pad,
            AppSpacing.xxl,
            pad,
            AppSpacing.xxl,
          ),
          children: [
            const Text('Cardrive', style: AppText.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Steuere die Musik mit deiner Stimme, ohne hinzusehen.',
              style: AppText.itemSubtitle,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(child: _buildMicButton()),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                _statusLabel,
                style: AppText.itemTitle.copyWith(
                  color: _listening ? AppColors.accent : AppColors.textDim,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildTranscript(),
            const SizedBox(height: AppSpacing.xl),
            _buildNowPlaying(),
            const SizedBox(height: AppSpacing.xl),
            const Text('Das versteht Cardrive', style: AppText.section),
            const SizedBox(height: AppSpacing.md),
            _buildHints(),
          ],
        ),
      ),
    );
  }

  String get _statusLabel {
    if (_blocked) return 'Mikrofon nicht verfügbar';
    return _listening ? 'Ich höre zu …' : 'Mikrofon pausiert';
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _listening ? AppColors.accent : AppColors.surfaceHi,
          boxShadow: _listening
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 36,
                    spreadRadius: 6,
                  ),
                ]
              : const [],
        ),
        child: Icon(
          _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
          size: 54,
          color: _listening ? AppColors.onAccent : AppColors.textDim,
        ),
      ),
    );
  }

  Widget _buildTranscript() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GEHÖRT', style: AppText.overline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _heard.isEmpty ? 'Sag etwas …' : _heard,
            style: AppText.itemTitle.copyWith(fontSize: 17),
          ),
          if (_feedback.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(_feedback, style: AppText.itemSubtitle),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    return StreamBuilder<List<Song>>(
      stream: _songService.queueStream,
      initialData: _songService.queue,
      builder: (context, _) {
        final song = _songService.current;
        if (song == null) return const SizedBox.shrink();

        return Row(
          children: [
            CoverArt(song: song, size: 56),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('LÄUFT GERADE', style: AppText.overline),
                  const SizedBox(height: 3),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.itemTitle,
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.itemSubtitle,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHints() {
    const hints = [
      'Spiele Bohemian Rhapsody ab',
      'Pause',
      'Weiter',
      'Zurück',
      'Weiterspielen',
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final hint in hints)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              hint,
              style: AppText.itemSubtitle.copyWith(color: AppColors.text),
            ),
          ),
      ],
    );
  }
}

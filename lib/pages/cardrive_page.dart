import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/responsive.dart';
import '../data/favorite_store.dart';
import '../models/playback.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
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
  static const _settleDelay = Duration(milliseconds: 550);
  static const _retryDelay = Duration(milliseconds: 250);

  final _speech = stt.SpeechToText();
  final _songService = SongService();

  Timer? _settle;
  Timer? _retry;

  bool _wanted = false;
  bool _blocked = false;
  bool _busy = false;

  String _locale = 'de_DE';
  String _heard = '';
  String _feedback = '';
  String _lastHandled = '';

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
    _wanted = false;
    _settle?.cancel();
    _retry?.cancel();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_wanted || _blocked) return;

    var available = false;
    try {
      available = await _speech.initialize(
        onStatus: (_) => _keepAlive(),
        onError: (error) {
          _say('Erkennung unterbrochen (${error.errorMsg}).');
          _keepAlive();
        },
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

    _locale = await _pickLocale();
    if (!mounted) return;

    setState(() {
      _wanted = true;
      _heard = '';
    });

    _retry = Timer.periodic(_retryDelay, (_) => _listen());
    await _listen();
  }

  Future<String> _pickLocale() async {
    try {
      final locales = await _speech.locales();
      for (final locale in locales) {
        if (locale.localeId.startsWith('de')) return locale.localeId;
      }

      final system = await _speech.systemLocale();
      if (system != null) return system.localeId;
    } catch (_) {}

    return 'de_DE';
  }

  Future<void> _stop() async {
    _wanted = false;
    _retry?.cancel();
    _settle?.cancel();

    await _speech.cancel();
    if (mounted) setState(() {});
  }

  void _keepAlive() {
    if (!_wanted || !mounted) return;
    if (!_speech.isListening) unawaited(_listen());
  }

  Future<void> _listen() async {
    if (!_wanted || !mounted) return;
    if (_speech.isListening || _busy) return;

    _busy = true;
    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: stt.SpeechListenOptions(
          localeId: _locale,
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          pauseFor: const Duration(seconds: 2),
          listenFor: const Duration(minutes: 2),
        ),
      );
    } catch (_) {
    } finally {
      _busy = false;
    }

    if (mounted) setState(() {});
  }

  void _onResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords;
    if (!mounted) return;

    setState(() => _heard = words);

    _settle?.cancel();

    if (result.finalResult) {
      _run(words);
      return;
    }

    _settle = Timer(_settleDelay, () => _run(words));
  }

  Future<void> _run(String spoken) async {
    final text = VoiceCommands.normalize(spoken);
    if (text.isEmpty || text == _lastHandled) return;

    _lastHandled = text;
    _settle?.cancel();

    final command = VoiceCommands.parse(spoken);

    switch (command.action) {
      case VoiceAction.play:
        await _playByName(command.query);

      case VoiceAction.playPlaylist:
        await _playPlaylist(command.query);

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

      case VoiceAction.restart:
        await _songService.restartSong();
        _say('Von vorne');

      case VoiceAction.louder:
        await _songService.nudgeVolume(0.15);
        _say('Lauter');

      case VoiceAction.quieter:
        await _songService.nudgeVolume(-0.15);
        _say('Leiser');

      case VoiceAction.shuffleOn:
        await _songService.setShuffle(true);
        _say('Zufall an');

      case VoiceAction.shuffleOff:
        await _songService.setShuffle(false);
        _say('Zufall aus');

      case VoiceAction.repeatOn:
        await _songService.setRepeat(RepeatMode.all);
        _say('Wiederholung an');

      case VoiceAction.repeatOff:
        await _songService.setRepeat(RepeatMode.off);
        _say('Wiederholung aus');

      case VoiceAction.favorite:
        await _markFavorite();

      case VoiceAction.unknown:
        await _playByName(text);
    }

    Future<void>.delayed(const Duration(seconds: 2), () {
      _lastHandled = '';
    });
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

  Future<void> _playPlaylist(String query) async {
    final playlists = await PlaylistService().getPlaylists();
    if (playlists.isEmpty) {
      _say('Du hast noch keine Playlist.');
      return;
    }

    final needle = VoiceCommands.normalize(query);
    var best = playlists.first;
    var bestScore = -1.0;

    for (final playlist in playlists) {
      final score = VoiceCommands.similarity(
        VoiceCommands.normalize(playlist.title),
        needle,
      );
      if (score > bestScore) {
        bestScore = score;
        best = playlist;
      }
    }

    final full = await PlaylistService().getPlaylist(best.id);
    final library = await _songService.getSongs();
    final byId = {for (final song in library) song.id: song};

    final songs = full.songs
        .map((path) => byId[path])
        .whereType<Song>()
        .toList();

    if (songs.isEmpty) {
      _say('"${best.title}" ist leer.');
      return;
    }

    await _songService.playList(songs, 0);
    _say('Spiele Playlist "${best.title}"');
  }

  Future<void> _markFavorite() async {
    final song = _songService.current;
    if (song == null) {
      _say('Gerade läuft nichts.');
      return;
    }

    final added = await FavoriteStore.toggle(song.id);
    _say(added ? 'Zu Favoriten' : 'Aus Favoriten entfernt');
  }

  void _say(String message) {
    if (!mounted) return;
    setState(() => _feedback = message);
  }

  Future<void> _toggle() async {
    if (_wanted) {
      await _stop();
      return;
    }

    _blocked = false;
    await _start();
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
                  color: _wanted ? AppColors.accent : AppColors.textDim,
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
    if (!_wanted) return 'Mikrofon pausiert';
    return _speech.isListening ? 'Ich höre zu …' : 'Starte Mikrofon …';
  }

  Widget _buildMicButton() {
    final live = _wanted && _speech.isListening;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _wanted ? AppColors.accent : AppColors.surfaceHi,
          boxShadow: live
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
          _wanted ? Icons.mic_rounded : Icons.mic_none_rounded,
          size: 54,
          color: _wanted ? AppColors.onAccent : AppColors.textDim,
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
      'Spiele Africa ab',
      'Spiele Playlist Autofahrt',
      'Pause',
      'Weiter',
      'Zurück',
      'Von vorne',
      'Lauter',
      'Leiser',
      'Zufall an',
      'Wiederholung aus',
      'Das gefällt mir',
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

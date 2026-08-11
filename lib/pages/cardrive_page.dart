import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:speech_to_text/speech_recognition_error.dart';
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
import '../services/sleep_timer.dart';
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
  static const _settleDelay = Duration(milliseconds: 750);
  static const _cooldown = Duration(milliseconds: 800);
  static const _minConfidence = 0.3;
  static const _watchdog = Duration(seconds: 3);

  final _speech = stt.SpeechToText();
  final _songService = SongService();

  Timer? _settle;
  Timer? _restart;
  Timer? _watch;

  AppLifecycleListener? _lifecycle;

  bool _wanted = false;
  bool _blocked = false;
  bool _starting = false;
  bool _running = false;
  bool _paused = false;
  bool _listenLocked = true;

  int _failures = 0;

  String _locale = 'de_DE';
  String _heard = '';
  String _feedback = '';
  String _lastHandled = '';

  @override
  void initState() {
    super.initState();

    _lifecycle = AppLifecycleListener(
      onHide: _sleep,
      onPause: _sleep,
      onShow: _wake,
      onRestart: _wake,
    );

    if (widget.active) _start();
  }

  void _sleep() {
    if (!_wanted) return;
    if (widget.active && _listenLocked) return;

    _paused = true;
    unawaited(_stop());
  }

  void _wake() {
    if (!_paused) return;
    _paused = false;
    if (widget.active) unawaited(_start());
  }

  void _setListenLocked(bool value) {
    setState(() => _listenLocked = value);
    if (!value && !widget.active) unawaited(_stop());
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
    _lifecycle?.dispose();
    _settle?.cancel();
    _restart?.cancel();
    _watch?.cancel();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_wanted || _blocked) return;

    var available = false;
    try {
      available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
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

    _watch = Timer.periodic(_watchdog, (_) => _schedule());
    _schedule(const Duration(milliseconds: 120));
  }

  void _onStatus(String status) {
    if (status == 'listening') return;
    _schedule();
  }

  void _onError(SpeechRecognitionError error) {
    final message = error.errorMsg;
    _failures++;

    if (message.contains('busy')) {
      unawaited(_speech.cancel());
    } else if (message.contains('permission')) {
      _say('Kein Zugriff auf das Mikrofon.');
    } else if (_isHarmless(message)) {
      _failures = 0;
    } else {
      _say('Erkennung unterbrochen ($message).');
    }

    _schedule(_backoff);
  }

  bool _isHarmless(String message) {
    const quiet = ['no_match', 'speech_timeout', 'client', 'canceled'];
    return quiet.any(message.contains);
  }

  Duration get _backoff {
    final steps = _failures.clamp(1, 6);
    return Duration(milliseconds: 500 * steps);
  }

  void _schedule([Duration? delay]) {
    if (!_wanted || !mounted) return;
    if (_speech.isListening || _starting) return;

    _restart?.cancel();
    _restart = Timer(delay ?? _cooldown, _listen);
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
    if (!_wanted) return;
    _wanted = false;
    _restart?.cancel();
    _watch?.cancel();
    _settle?.cancel();

    await _speech.cancel();
    if (mounted) setState(() {});
  }

  Future<void> _listen() async {
    if (!_wanted || !mounted) return;
    if (_speech.isListening || _starting) return;

    _starting = true;
    _lastHandled = '';

    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: stt.SpeechListenOptions(
          localeId: _locale,
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
          pauseFor: const Duration(seconds: 2),
          listenFor: const Duration(seconds: 30),
        ),
      );
      _failures = 0;
    } catch (_) {
      _failures++;
      await _speech.cancel();
      _schedule(_backoff);
    } finally {
      _starting = false;
    }

    if (mounted) setState(() {});
  }

  void _onResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords;
    if (!mounted) return;

    setState(() => _heard = words);
    _settle?.cancel();

    if (VoiceCommands.isIncomplete(words)) return;
    if (!_trustworthy(result)) return;

    if (result.finalResult) {
      _run(words);
      return;
    }

    _settle = Timer(_settleDelay, () => _run(words));
  }

  bool _trustworthy(SpeechRecognitionResult result) {
    if (!result.finalResult) return true;
    if (result.confidence <= 0) return true;
    return result.confidence >= _minConfidence;
  }

  Future<void> _run(String spoken) async {
    final text = VoiceCommands.normalize(spoken);
    if (text.isEmpty || text == _lastHandled || _running) return;

    final command = VoiceCommands.parse(spoken);
    if (command.action == VoiceAction.unknown) {
      _lastHandled = text;
      return;
    }

    _lastHandled = text;
    _running = true;
    _settle?.cancel();

    try {
      await _apply(command);
    } catch (_) {
      _say('Das hat nicht geklappt.');
    } finally {
      _running = false;
    }

    await _speech.cancel();
    _schedule(_cooldown);
  }

  Future<void> _apply(VoiceCommand command) async {
    switch (command.action) {
      case VoiceAction.play:
        _say('Suche "${command.query}" …');
        await _playByName(command.query, minScore: 0);

      case VoiceAction.playPlaylist:
        _say('Suche Playlist …');
        await _playPlaylist(command.query);

      case VoiceAction.resume:
        _say('Weiter');
        await _resumeOrStart();

      case VoiceAction.pause:
        _say('Pause');
        await _songService.pause();

      case VoiceAction.next:
        _say('Nächster Titel');
        await _songService.next();

      case VoiceAction.previous:
        _say('Vorheriger Titel');
        await _songService.prev();

      case VoiceAction.restart:
        _say('Von vorne');
        await _songService.restartSong();

      case VoiceAction.louder:
        _say('Lauter');
        await _songService.nudgeVolume(0.15);

      case VoiceAction.quieter:
        _say('Leiser');
        await _songService.nudgeVolume(-0.15);

      case VoiceAction.shuffleOn:
        _say('Zufall an');
        await _songService.setShuffle(true);

      case VoiceAction.shuffleOff:
        _say('Zufall aus');
        await _songService.setShuffle(false);

      case VoiceAction.repeatOn:
        _say('Wiederholung an');
        await _songService.setRepeat(RepeatMode.all);

      case VoiceAction.repeatOff:
        _say('Wiederholung aus');
        await _songService.setRepeat(RepeatMode.off);

      case VoiceAction.favorite:
        await _markFavorite();

      case VoiceAction.sleep:
        final minutes = VoiceCommands.minutesIn(command.query.isEmpty
            ? _heard
            : command.query);
        SleepTimer.start(
          Duration(minutes: minutes),
          () => _songService.pause(),
        );
        _say('Timer auf $minutes Minuten');

      case VoiceAction.faster:
        await _songService.setSpeed(_songService.speed + 0.25);
        _say('Tempo ${_songService.speed.toStringAsFixed(2)}x');

      case VoiceAction.slower:
        await _songService.setSpeed(_songService.speed - 0.25);
        _say('Tempo ${_songService.speed.toStringAsFixed(2)}x');

      case VoiceAction.normalSpeed:
        await _songService.setSpeed(1);
        _say('Normales Tempo');

      case VoiceAction.unknown:
        break;
    }
  }

  Future<void> _resumeOrStart() async {
    if (_songService.current != null) {
      await _songService.resume();
      return;
    }

    final songs = await _songService.getSongs();
    if (songs.isEmpty) {
      _say('Ich habe keine Musik auf dem Gerät gefunden.');
      return;
    }

    await _songService.playList(songs, 0);
    _say('Spiele "${songs.first.title}"');
  }

  Future<void> _playByName(String query, {required double minScore}) async {
    final songs = await _songService.getSongs();

    if (songs.isEmpty) {
      _say('Ich habe keine Musik auf dem Gerät gefunden.');
      return;
    }

    final song = VoiceCommands.findSong(songs, query, minScore: minScore);

    if (song == null) {
      _say('Das habe ich nicht verstanden.');
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
            const SizedBox(height: AppSpacing.lg),
            _buildLockSwitch(),
            const SizedBox(height: AppSpacing.md),
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
    if (_running) return 'Verstanden …';
    return _speech.isListening ? 'Ich höre zu …' : 'Einen Moment …';
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

  Widget _buildLockSwitch() {
    return SwitchListTile(
      value: _listenLocked,
      onChanged: _setListenLocked,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppColors.accent,
      title: const Text(
        'Bei gesperrtem Bildschirm weiterhören',
        style: AppText.itemTitle,
      ),
      subtitle: const Text(
        'Braucht mehr Akku. Gilt nur, solange Cardrive offen ist.',
        style: AppText.itemSubtitle,
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
      'Lautstärke erhöhen',
      'Lautstärke senken',
      'Zufall an',
      'Wiederholung aus',
      'Das gefällt mir',
      'Timer 30 Minuten',
      'Schneller',
      'Langsamer',
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

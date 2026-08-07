import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../data/library.dart';
import '../models/song.dart';

class SongService {
  static final SongService _instance = SongService._();
  factory SongService() => _instance;

  final AudioPlayer player = AudioPlayer();

  final List<Song> queue = [];

  final _queueController = StreamController<List<Song>>.broadcast();

  List<Song> _library = [];

  int _index = -1;

  bool _loading = false;

  SongService._() {
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !_loading) next();
    });
  }

  Song? get current =>
      _index >= 0 && _index < queue.length ? queue[_index] : null;

  int get currentIndex => _index;

  bool get hasNext => _index < queue.length - 1;
  bool get hasPrev => _index > 0;

  Stream<List<Song>> get queueStream => _queueController.stream;

  Stream<bool> get playingStream => player.playingStream;

  Stream<Duration> get positionStream => player.positionStream;

  Duration? get duration => player.duration;

  bool get isPlaying => player.playing;

  Future<void> playList(List<Song> songs, int start) async {
    queue
      ..clear()
      ..addAll(songs);
    _index = start;
    _notify();
    await _load();
  }

  void addToQueue(Song song) {
    queue.add(song);
    _notify();
  }

  void removeFromQueue(int i) {
    if (i < 0 || i >= queue.length) return;
    queue.removeAt(i);
    if (i < _index) _index--;
    _notify();
  }

  void reorderQueue(int from, int to) {
    if (from < 0 || from >= queue.length) return;
    if (to > from) to--;
    if (to < 0 || to >= queue.length) return;

    final song = queue.removeAt(from);
    queue.insert(to, song);

    if (_index == from) {
      _index = to;
    } else if (from < _index && to >= _index) {
      _index--;
    } else if (from > _index && to <= _index) {
      _index++;
    }
    _notify();
  }

  Future<void> next() async {
    if (!hasNext) return;
    _index++;
    _notify();
    await _load();
  }

  Future<void> prev() async {
    if (!hasPrev) return;
    _index--;
    _notify();
    await _load();
  }

  Future<void> jumpTo(int i) async {
    if (i < 0 || i >= queue.length) return;
    _index = i;
    _notify();
    await _load();
  }

  Future<void> resume() => player.play();
  Future<void> pause() => player.pause();
  Future<void> seek(Duration position) => player.seek(position);

  LoopMode get loopMode => player.loopMode;
  Future<void> setLoopMode(LoopMode mode) => player.setLoopMode(mode);

  Future<void> toggle(Song song, List<Song> list) async {
    if (current?.id != song.id) {
      await playList(list, list.indexOf(song));
    } else if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  bool get canImport => MusicLibrary.canImport;

  String get importLabel => MusicLibrary.importLabel;

  Future<List<Song>> getSongs() async {
    if (_library.isNotEmpty) return _library;
    return refresh();
  }

  Future<List<Song>> refresh() async {
    _library = await MusicLibrary.load();
    return _library;
  }

  Future<int> importFromDevice() async {
    final added = await MusicLibrary.import();
    if (added > 0) await refresh();
    return added;
  }

  void _notify() => _queueController.add(List.of(queue));

  Future<void> _load() async {
    final song = current;
    if (song == null) return;

    _loading = true;
    try {
      await MusicLibrary.setSource(player, song);
      await player.play();
    } catch (_) {
    } finally {
      _loading = false;
    }
  }
}

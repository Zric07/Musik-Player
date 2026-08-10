import '../models/song.dart';

enum VoiceAction {
  play,
  playPlaylist,
  resume,
  pause,
  next,
  previous,
  restart,
  louder,
  quieter,
  shuffleOn,
  shuffleOff,
  repeatOn,
  repeatOff,
  favorite,
  unknown,
}

class VoiceCommand {
  final VoiceAction action;
  final String query;

  const VoiceCommand(this.action, {this.query = ''});
}

class VoiceCommands {
  VoiceCommands._();

  static const List<String> _playlistPrefixes = [
    'spiele playlist',
    'spiel playlist',
    'starte playlist',
    'playlist',
  ];

  static const List<String> _playPrefixes = [
    'spiele',
    'spiel',
    'starte',
    'start',
    'play',
    'hoere',
    'leg auf',
  ];

  static const List<String> _fillers = [
    'das lied',
    'den song',
    'den titel',
    'die musik',
    'lied',
    'song',
    'titel',
    'musik',
    'mir',
    'bitte',
    'mal',
  ];

  static const List<String> _resumeAfterPrefix = [
    'weiter',
    'weiterspielen',
    'wieder',
    'los',
    'ab',
    'musik',
  ];

  static const List<List<String>> _vocabulary = [
    ['weiterspielen', 'weiter spielen', 'weitermachen', 'fortsetzen',
      'fortfahren', 'wiedergabe fortsetzen'],
    ['pause', 'pausier', 'stopp', 'stop', 'anhalten', 'halt an', 'ruhe',
      'sei still', 'aus machen'],
    ['von vorne', 'von vorn', 'neu starten', 'noch mal von vorne',
      'nochmal von vorne', 'zum anfang'],
    ['zufall aus', 'shuffle aus', 'zufallswiedergabe aus', 'der reihe nach'],
    ['zufall', 'zufaellig', 'shuffle', 'mischen', 'misch', 'durcheinander'],
    ['wiederholung aus', 'keine wiederholung', 'schleife aus', 'loop aus'],
    ['wiederhol', 'schleife', 'loop', 'endlos'],
    ['lauter', 'mach lauter', 'volle lautstaerke', 'voll aufdrehen'],
    ['leiser', 'mach leiser', 'leise'],
    ['gefaellt mir', 'favorit', 'merken', 'daumen hoch', 'zu favoriten'],
    ['zurueck', 'vorherig', 'davor', 'letztes lied', 'nochmal'],
    ['naechst', 'weiter', 'ueberspring', 'skip', 'vorwaerts', 'vor'],
  ];

  static const List<VoiceAction> _actions = [
    VoiceAction.resume,
    VoiceAction.pause,
    VoiceAction.restart,
    VoiceAction.shuffleOff,
    VoiceAction.shuffleOn,
    VoiceAction.repeatOff,
    VoiceAction.repeatOn,
    VoiceAction.louder,
    VoiceAction.quieter,
    VoiceAction.favorite,
    VoiceAction.previous,
    VoiceAction.next,
  ];

  static VoiceCommand parse(String spoken) {
    final text = normalize(spoken);
    if (text.isEmpty) return const VoiceCommand(VoiceAction.unknown);

    final playlist = _after(text, _playlistPrefixes);
    if (playlist != null && playlist.isNotEmpty) {
      return VoiceCommand(VoiceAction.playPlaylist, query: playlist);
    }

    final control = _controlOf(text);
    final query = _after(text, _playPrefixes);

    if (query != null) {
      if (query.isEmpty || _resumeAfterPrefix.contains(query)) {
        return const VoiceCommand(VoiceAction.resume);
      }

      final inner = _controlOf(query);
      if (inner != VoiceAction.unknown && query.split(' ').length <= 2) {
        return VoiceCommand(inner);
      }

      return VoiceCommand(VoiceAction.play, query: query);
    }

    if (control != VoiceAction.unknown) return VoiceCommand(control);

    return const VoiceCommand(VoiceAction.unknown);
  }

  static VoiceAction _controlOf(String text) {
    for (var i = 0; i < _vocabulary.length; i++) {
      if (_hasWord(text, _vocabulary[i])) return _actions[i];
    }
    return VoiceAction.unknown;
  }

  static bool _hasWord(String text, List<String> words) {
    for (final word in words) {
      if (text == word) return true;
      if (text.contains(' $word')) return true;
      if (text.startsWith(word)) return true;
    }
    return false;
  }

  static String? _after(String text, List<String> prefixes) {
    for (final prefix in prefixes) {
      if (text != prefix && !text.startsWith('$prefix ')) continue;

      var rest = text == prefix ? '' : text.substring(prefix.length + 1);
      rest = _stripEnd(rest, ' ab');
      rest = _stripEnd(rest, ' abspielen');
      rest = _stripEnd(rest, ' an');

      for (final filler in _fillers) {
        if (rest == filler) rest = '';
        if (rest.startsWith('$filler ')) {
          rest = rest.substring(filler.length + 1);
        }
      }

      return rest.trim();
    }
    return null;
  }

  static String _stripEnd(String text, String suffix) {
    if (!text.endsWith(suffix)) return text;
    return text.substring(0, text.length - suffix.length).trim();
  }

  static Song? findSong(List<Song> songs, String query) {
    if (songs.isEmpty) return null;

    final needle = normalize(query);
    if (needle.isEmpty) return songs.first;

    var best = songs.first;
    var bestScore = -1.0;

    for (final song in songs) {
      final score = _score(song, needle);
      if (score > bestScore) {
        bestScore = score;
        best = song;
      }
    }

    return best;
  }

  static double _score(Song song, String needle) {
    final title = normalize(song.title);
    final artist = normalize(song.artist);

    if (title == needle) return 1;
    if (title.startsWith(needle)) return 0.96;
    if (title.contains(needle)) return 0.92;
    if (title.isNotEmpty && needle.contains(title)) return 0.88;
    if (artist == needle) return 0.84;
    if (artist.isNotEmpty && artist.contains(needle)) return 0.80;

    final byTitle = similarity(title, needle);
    final byArtist = similarity(artist, needle) * 0.8;
    final byWords = _wordShare(needle, '$title $artist') * 0.75;

    var score = byTitle;
    if (byArtist > score) score = byArtist;
    if (byWords > score) score = byWords;

    return score;
  }

  static double _wordShare(String needle, String haystack) {
    final words = needle.split(' ').where((word) => word.length > 2).toList();
    if (words.isEmpty) return 0;

    var hits = 0;
    for (final word in words) {
      if (haystack.contains(word)) hits++;
    }

    return hits / words.length;
  }

  static double similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;

    final left = _bigrams(a);
    final right = _bigrams(b);
    if (left.isEmpty || right.isEmpty) return 0;

    final rest = List.of(right);
    var hits = 0;

    for (final pair in left) {
      final index = rest.indexOf(pair);
      if (index < 0) continue;
      rest.removeAt(index);
      hits++;
    }

    return 2 * hits / (left.length + right.length);
  }

  static List<String> _bigrams(String value) {
    final pairs = <String>[];
    for (var i = 0; i < value.length - 1; i++) {
      final pair = value.substring(i, i + 2);
      if (pair.trim().length == 2) pairs.add(pair);
    }
    return pairs;
  }

  static String normalize(String value) {
    final buffer = StringBuffer();

    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final replacement = _letters[char];

      if (replacement != null) {
        buffer.write(replacement);
      } else if (_isPlain(rune)) {
        buffer.write(char);
      } else {
        buffer.write(' ');
      }
    }

    return buffer.toString().split(' ').where((w) => w.isNotEmpty).join(' ');
  }

  static bool _isPlain(int rune) {
    final isDigit = rune >= 0x30 && rune <= 0x39;
    final isLetter = rune >= 0x61 && rune <= 0x7A;
    return isDigit || isLetter;
  }

  static const Map<String, String> _letters = {
    'ä': 'ae',
    'ö': 'oe',
    'ü': 'ue',
    'ß': 'ss',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'í': 'i',
    'ì': 'i',
    'ó': 'o',
    'ò': 'o',
    'ú': 'u',
    'ù': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
}
